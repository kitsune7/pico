ruleset wovyn_base {
  meta {
    use module temperature_store alias TS
    use module sensor_profile alias Profile
  }
  
  global {
    to = Profile:get_sms_number()
    from = "+16122686674"
  }
  
  rule current_temperature {
    select when wovyn current_temperature
    pre {
      temperature_threshold = Profile:get_threshold()
    }
    send_directive("api", {
      "current_temperature": TS:current_temperature(),
      "temperature_threshold": temperature_threshold
    })
  }
  
  rule temperature_readings {
    select when wovyn temperature_readings
    pre {
      temperature_threshold = Profile:get_threshold()
    }
    send_directive("api", {
      "temperatures": TS:temperatures(),
      "temperature_threshold": temperature_threshold
    })
  }
  
  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      genericThing = event:attr("genericThing")
    }
    if genericThing then
      send_directive("beat", {})
    fired {
      raise wovyn event "new_temperature_reading" attributes {
        "temperature": genericThing["data"]["temperature"],
        "timestamp": time:now()
      }
    }
  }
  
  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attr("temperature")
      violation = temperature[0]["temperatureF"] > Profile:get_threshold()
    }
    send_directive("temp", {"temperature_violation": violation})
    always {
      raise wovyn event "threshold_violation" attributes event:attrs
        if violation
    }
  }
  
  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      temperature = event:attr("temperature")
      message = "Temperature threshold passed! Current temp: " + temperature[0]["temperatureF"]
    }
    always {
      raise twilio event "send_sms" attributes {
        "to": to,
        "from": from,
        "message": message
      }
    }
  }
}
