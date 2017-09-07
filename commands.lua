local Session = require("nis.sessions")

function Session:check()
  self.request = "check"
  self:command("chk")
  -- to disable debug mode, which enabled automaticaly
  --after chk command
  self:command("debug")
end

function Session:suggest()
  self.request = "suggest"
  self:command("sug", true)
end

function Session:context()
  self.request = "context"
  self:command("con", true)
end

function Session:goto_definition()
  self.request = "gotodef"
  self:command("def", true)
end

function Session:help()
  self.request = "help"
  self:command("def", true)
end

function Session:replace()
  self.request = "replace"
  self:command("dus", true)
end
