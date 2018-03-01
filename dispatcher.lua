require("nis.utils")
require("nis.parser")
require("nis.checker")
require("nis.suggester")
require("nis.calltips")
require("nis.message_window")


local function gotodef (s)
  if s.file ~= vis.win.file.path then
    vis:command("open "..s.file)
  end
  vis.win.selection:to(s.line, s.colomn)
end

local function help(s, ctx)
  if not s then ctx.incomplete = false return end
  local window = vis.win
  if not window.subwindows.notifier then
    window.subwindows.notifier = MessageWindow.new()
  end
  toshow = "\\e[syntax]"..s.fullname..": "..s.type..
           "\\e[reset]\n\n"..tostring(s.comment)
  stylized_print(window.subwindows.notifier, toshow, ctx.incomplete)
  ctx.incomplete = true
end


local function defdispatcher(s, ctx)
  local defmeanings = {
    help = help,
    gotodef = gotodef,
  }
  if not vis.win.pendingrequest then return end
  defmeanings[vis.win.pendingrequest](s, ctx)
end

local function suggesthandler(s, ctx)
  if s then table.insert(ctx.accumulator, s)
  elseif #ctx.accumulator > 0 then
    suggest(ctx.accumulator, vis.win)
    ctx.accumulator = {}
  end
end

local function stdouthandler(a, ctx)
  local dispatcher = {
    sug = suggesthandler,
    chk = on_error,
    def = defdispatcher,
    dus = function () end, -- Smart replace to be implemented
    con = arghelper,
  }
  local answer = ctx.residue..a
  ctx.residue = ""
  for ln in answer:gmatch("[^\n]+\n?") do
    local line = ln:match("[^\n]+")
    if not ln:match(".*\n") then
      ctx.residue = ln
      --silent_print("Residue: "..ctx.residue)
      break
    end
    local suggestion = parse_answer(line)
    if suggestion then
      local handler = dispatcher[suggestion.request]
      if handler then handler(suggestion, ctx)
      else
        silent_print("[!!!]No handler for "..suggestion.request)
        silent_print("LINE: "..line)
      end
    elseif line == "!EOF!" then
      for k, v in pairs(dispatcher) do
        v(nil, ctx)
      end
    end
  end
end

function genOnResponce(name)
  local context = {
    residue = "", -- string residue from previous incomplete string
    incomplete = false, -- next help message can be applied to previous
    accumulator = {}, -- accumulator of suggestions
  }
  local variants = {
    STDOUT = stdouthandler,
    STDERR = function (a) end,
    SIGNAL = function (a) end,
    EXIT = function (a) end,
  }
  return function (n, d, e)
    if n == name then
      -- silent_print("Answer: "..tostring(d).." from "..e)
      variants[e](d, context)
    end
  end
end
