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
  }
  
  rule test_data {
    select when manage view_test_data
    send_directive("test values", {
      "sensors": sensors(),
      "sections": sections()
    })
  }
  
  rule clear_data {
    select when manage clear_data
    always {
      clear ent:sensors;
      clear ent:sections
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
