ruleset io.picolabs.use_twilio_v2 {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
    with account_sid = keys:twilio{"account_sid"}
      auth_token = keys:twilio{"auth_token"}
    author "Christopher Bradshaw"
  }
 
  rule send_sms {
    select when twilio send_sms
    twilio:send_sms(
      event:attr("to"),
      event:attr("from"),
      event:attr("message")
    )
  }
  
  rule messages {
    select when twilio messages
    pre {
      to = event:attr("to").defaultsTo(null)
      from = event:attr("from").defaultsTo(null)
      messages = twilio:messages(to, from)
    }
    
    send_directive("response", messages)
  }
}
