ruleset temperature_store {
  meta {
    provides temperatures, current_temperature, threshold_violations, inrange_temperatures
    shares temperatures, current_temperature, threshold_violations, inrange_temperatures
  }
  
  global {
    temperatures = function () {
      ent:temperature_readings.defaultsTo([]).reverse()
    }
    
    current_temperature = function () {
      ent:temperature_readings.reverse().head()
    }
    
    threshold_violations = function () {
      ent:threshold_violations.reverse()
    }
    
    inrange_temperatures = function () {
      ent:temperature_readings.difference(ent:threshold_violations).reverse()
    }
  }
  
  rule temperature_report {
    select when sensor report_request
    pre {
      temperature_list = temperatures()
      sender_eci = event:attr("sender_eci")
      report_id = event:attr("report_id")
    }
    event:send({
      "eci": sender_eci,
      "eid": report_id,
      "domain": "sensor",
      "type": "report",
      "attrs": {
        "temperatures": temperature_list,
        "sender_eci": meta:eci,
        "report_id": report_id
      }
    })
  }
  
  rule collect_temperatures {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attr("temperature")
      timestamp = event:attr("timestamp")
      temperature_reading = {
        "temperature": temperature,
        "timestamp": timestamp
      }
    }
    always {
      ent:temperature_readings := ent:temperature_readings.defaultsTo([]).append(temperature_reading)
    }
  }
  
  rule collect_threshold_violations {
    select when wovyn threshold_violation
    pre {
      temperature = event:attr("temperature")
      timestamp = event:attr("timestamp")
      temperature_reading = {
        "temperature": temperature,
        "timestamp": timestamp
      }
    }
    always {
      ent:threshold_violations := ent:threshold_violations.defaultsTo([]).append(temperature_reading)
    }
  }
  
  rule clear_temperatures {
    select when sensor reading_reset
    always {
      clear ent:temperature_readings;
      clear ent:threshold_violations
    }
  }
}
