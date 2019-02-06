ruleset wovyn_base {
  global {
    temperature_threshold = 65.0
    to = "+13852190238"
    from = "+16122686674"
  }
  
  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      genericThing = event:attr("genericThing")
      never_used = event:attrs.klog("attrs")
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
      never_used = event:attrs.klog("attrs")
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
