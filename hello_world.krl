ruleset hello_world {
  meta {
    name "Hello World"
    description << A first ruleset for the Quickstart >>
    author "Christopher Bradshaw"
    logging on
    shares hello, monkey
  }
  
  global {
    hello = function (obj) {
      msg = "Hello " + obj;
      msg
    }
  }
  
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }
  
  rule hello_monkey {
    select when echo monkey
    pre {
      name = event:attr("name")
    }
    send_directive("say", {"something": "Hello " + (name => name | "Monkey")})
  } 
}
