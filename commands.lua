require("nis.sessions")

function Session:check()
  self.request = "check"
  local win = vis.win
  if win and win.triggers and win.triggers.error_highlighter then
    win.triggers.error_highlighter = nil
  end
  self:command("chk", true)
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
