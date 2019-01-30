ruleset io.picolabs.twilio_v2 {
  meta {
    provides send_sms, get_all_messages, get_messages
  }
 
  global {
    send_sms = defaction(to, from, message) {
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
      http:post(base_url + "Messages.json",
        form = {
          "From": from,
          "To": to,
          "Body": message
        })
    }
    
    get_all_messages = function () {
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>;
      http:get(base_url + "Messages.json")["content"].decode()
    }
    
    get_messages = function (to, from) {
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>;
      http:get(base_url + "Messages.json",
        qs = {
          "From": from,
          "To": to
        }
      )["content"].decode()
    }
  }
}
