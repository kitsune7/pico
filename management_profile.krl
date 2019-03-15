ruleset management_profile {
  global {
    to = "+13852190238"
    from = "+16122686674"
  }
  
  rule threshold_violation {
    select when sensor threshold_violation
    pre {
      message = event:attr("message")
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
