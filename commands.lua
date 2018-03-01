require("nis.sessions")

function Session:check()
  local win = vis.win
  if win and win.triggers and win.triggers.error_highlighter then
    win.triggers.error_highlighter = nil
  end
  self:command("chk", true)
end

function Session:suggest()
  self:command("sug", true)
end

function Session:context()
  self:command("con", true)
end

function Session:goto_definition()
  vis.win.pendingrequest = "gotodef"
  self:command("def", true)
end

function Session:help()
  vis.win.pendingrequest = "help"
  self:command("def", true)
end

function Session:replace()
  self:command("dus", true)
end
