require("sessions")

function Session:check()
  self:command("chk")
  -- to disable debug mode, which enabled automaticaly
  --after chk command
  self:command("debug")
end

function Session:suggest()
  self:command("sug", true)
end

function Session:context()
  self:command("con", true)
end

function Session:definition()
  self:command("def", true)
end

function Session:definition_and_usage()
  self:command("dus", true)
end
