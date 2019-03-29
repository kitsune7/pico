ruleset manage_sensors {
  meta {
    use module io.picolabs.subscription alias Subscriptions
  }
  
  global {
    nameFromId = function (id) {
      id + " sensor pico"
    }
    
    sensors = function () {
      Subscriptions:established("Rx_role", "temperature_sensor").defaultsTo([])
    }
    
    sections = function () {
      ent:sections.defaultsTo([])
    }
    
    reports = function () {
      ent:reports.defaultsTo({})
    }
    
    get_new_report_id = function () {
      random:uuid()
    }
    
    get_latest_reports = function () {
      eids = ent:reports.keys().slice(4);
      ent:reports.defaultsTo({}).keys().length() < 5 =>
        ent:reports.defaultsTo({}) |
        ent:reports.defaultsTo({}).filter(function (v, k) { eids.has(k) })
    }
  }
  
  rule test_data {
    select when manage view_test_data
    send_directive("test values", {
      "sensors": sensors(),
      "sections": sections(),
      "reports": reports()
    })
  }
  
  rule clear_data {
    select when manage clear_data
    always {
      clear ent:sensors;
      clear ent:sections;
      clear ent:reports
    }
  }
  
  rule clear_reports {
    select when manage clear_reports
    always {
      clear ent:reports
    }
  }
  
  rule full_test {
    select when manage full_test
    always {
      raise sensor event "new_sensor" attributes { "section_id": "SWKT306" };
      raise sensor event "new_sensor" attributes { "section_id": "MB105" };
      raise sensor event "new_sensor" attributes { "section_id": "CB304" };
      raise sensor event "unneeded_sensor" attributes {
        "section_id": "MB105"
      }
    }
  }
  
  rule get_latest_reports {
    select when manage get_latest_reports
    send_directive("reports", get_latest_reports())
  }
  
  rule request_temperature_report {
    select when sensor request_temperature_report
    pre {
      new_report_id = get_new_report_id()
    }
    always {
      raise sensor event "send_temperature_report_requests" attributes {
        "report_id": new_report_id
      }
    }
  }
  
  rule send_temperature_report_requests {
    select when sensor send_temperature_report_requests
    foreach sensors() setting (sensor)
    pre {
      report_id = event:attr("report_id")
      num_of_sensors = sensors().length()
    }
    event:send({
      "eci": sensor{"Tx"},
      "eid": report_id,
      "domain": "sensor",
      "type": "report_request",
      "attrs": {
        "sender_eci": meta:eci,
        "report_id": report_id
      }
    })
    fired {
      ent:reports := ent:reports.defaultsTo({}).put(
        [report_id, "temperature_sensors"],
        num_of_sensors
      )
    }
  }
  
  rule create_temperature_report {
    select when sensor report
    pre {
      temperatures = event:attr("temperatures")
      sender_eci = event:attr("sender_eci")
      report_id = event:attr("report_id")
    }
    always {
      ent:reports := ent:reports.defaultsTo({}).put(
        [report_id, "temperatures"],
        ent:reports.defaultsTo({}).get([report_id, "temperatures"])
          .defaultsTo([]).union([temperatures])
      );
      ent:reports := ent:reports.defaultsTo({}).put(
        [report_id, "responded"],
        ent:reports.defaultsTo({}).get([report_id, "responded"]).defaultsTo(0) + 1
      )
    }
  }
  
  rule new_sensor {
    select when sensor new_sensor
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      eci = meta:eci
    }
    if exists then
      send_directive("duplicate_name", {
        "section_id": section_id,
        "sections": ent:sections
      });
    notfired {
      ent:sections := ent:sections.defaultsTo([]).union([section_id]);
      raise wrangler event "child_creation" attributes {
        "name": nameFromId(section_id),
        "section_id": section_id,
        "color": "rgb(46, 204, 113)",
        "rids": [
          "io.picolabs.subscription",
          "temperature_store",
          "wovyn_base",
          "sensor_profile"
        ]
      }
    }
  }
  
  rule store_new_sensor {
    select when wrangler child_initialized
    pre {
      the_sensor = {
        "id": event:attr("id"),
        "eci": event:attr("eci"),
        "name": event:attr("name")
      }
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    always {
      ent:sensors := ent:sensors.defaultsTo([]).union([the_sensor])
    }
  }
  
  rule update_and_subscribe {
    select when wrangler new_child_created
    pre {
      eci = event:attr("eci")
      section_id = event:attr("name")
    }
    event:send({
      "eci": eci,
      "eid": "foxes",
      "domain": "sensor",
      "type": "profile_updated",
      "attrs": {
        "current_name": section_id
      }
    })
    always {
      raise wrangler event "subscription" attributes {
        "name": section_id,
        "Rx_role": "temperature_sensor",
        "Tx_role": "controller",
        "channel_type": "subscription",
        "wellKnown_Tx": eci
      }
    }
  }
  
  rule introduce_sensor {
    select when sensor introduce
    pre {
      parent = meta:eci
      eci = event:attr("eci")
      name = event:attr("name")
    }
    event:send({
      "eci": parent,
      "eid": "subcription",
      "domain": "wrangler",
      "type": "subscription",
      "attrs": {
        "name": name,
        "Rx_role": "temperature_sensor",
        "Tx_role": "controller",
        "channel_type": "subcription",
        "wellKnown_Tx": eci
      }
    })
  }
  
  rule unneeded_sensor {
    select when sensor unneeded_sensor
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      section_name = nameFromId(section_id)
    }
    if exists then
      send_directive("deleting_section", { "section_id": section_id })
    fired {
      ent:sections := ent:sections.filter(function (id) { id != section_id });
      ent:sensors := ent:sensors.filter(function (sensor) { sensor["name"] != section_name });
      raise wrangler event "child_deletion" attributes {
        "name": section_name
      }
    }
  }
}
