ruleset sensor_profile {
  meta {
    provides get_threshold, get_sms_number
    shares get_threshold, get_sms_number
  }
  
  global {
    profile_info = function () {
      {
        "location": ent:location,
        "current_name": ent:current_name,
        "threshold": ent:threshold,
        "sms_number": ent:sms_number
      }
    }
    get_threshold = function () {
      ent:threshold
    }
    get_sms_number = function () {
      ent:sms_number
    }
  }
  
  rule update_profile {
    select when sensor profile_updated
    pre {
      location = event:attr("location").defaultsTo("Wyview")
      current_name = event:attr("current_name").defaultsTo("Spiffy")
      threshold = event:attr("threshold").defaultsTo(75)
      sms_number = event:attr("sms_number").defaultsTo("+13852190238")
    }
    always {
      ent:location := location;
      ent:current_name := current_name;
      ent:threshold := threshold;
      ent:sms_number := sms_number;
    }
  }
  
  rule get_profile_info {
    select when sensor profile_info
    send_directive("api", profile_info())
  }
}
