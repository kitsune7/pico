ruleset temperature_store {
  meta {
    provides temperatures, threshold_violations, inrange_temperatures
    shares temperatures, threshold_violations, inrange_temperatures
  }
  
  global {
    temperatures = function () {
      ent:temperature_readings
    }
    
    threshold_violations = function () {
      ent:threshold_violations
    }
    
    inrange_temperatures = function () {
      ent:temperature_readings.difference(ent:threshold_violations)
    }
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
