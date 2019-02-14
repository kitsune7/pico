ruleset wovyn_base {
  meta {
    use module temperature_store alias TS
  }
  
  global {
    temperature_threshold = 75.0
    to = "+13852190238"
    from = "+16122686674"
  }
  
  rule test_ent_vars {
    select when wovyn test
    send_directive("test", {
      "temperatures": TS:temperatures(),
      "threshold_violations": TS:threshold_violations(),
      "inrange_temperatures": TS:inrange_temperatures()
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
      violation = temperature[0]["temperatureF"] > temperature_threshold
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
