local colors = require('nis.graphic').colors
require('nis.message_window')
local notifier = MessageWindow.new()
function splitpath(path)
  -- Splits path to parent dir and file name
  if type(path) ~= "string" then return end
  local head, tail = path:match("^(.+)/([^/]+)$")
  if tail == nil then return path end
  return head, tail
end

function fileexist(path)
  local testfd = io.open(path, 'r')
  if testfd ~= nil then
    testfd:close()
    return true
  end
  return false
end

function register_colors()
  local holes = {}
  local existant = {}
  local lexer = vis.lexers.load("nim", nil, true)
  for i = 0, 64, 1 do holes[i] = true end
  for name, id in pairs(lexer._TOKENSTYLES) do
    local style = vis.lexers['STYLE_'..name:upper()] or ""
    vis.win:style_define(id, style)
    existant[style] = id
    holes[id] = nil
  end
  return lexer, setmetatable(existant, {__index = function(t, k)
    local free
    for freeid in pairs(holes) do
      free = freeid
      break
    end
    if vis.win:style_define(free, k) then
      holes[free] = nil
      t[k] = free
      return free
    else return 65 -- UI_STYLE_DEFAULT
    end
  end})
end

local function stylize(data)
  local start, finish, capture, style
  local result = data
  local lexer, existent = register_colors()
  local styles = lexer._TOKENSTYLES
  local colorizepattern = "\\e%[([^%]]+)%](.-)\\e%[reset%]"
  local paints = {}
  repeat
    start, finish, style, capture =
      result:find(colorizepattern, start)
    if start == nil then break end
    result = result:sub(1, start-1)..capture..result:sub(finish+1)
    if style == "syntax" then
      --do syntax highlighting
      local tokens = lexer:lex(capture, 1)
      local tstart = start
      for i = 1, #tokens, 2 do
        local tend = start + tokens[i+1] - 1
        if tend >= tstart then
          local name = tokens[i]
          local tstyle = styles[name]
          if tstyle ~= nil then
            table.insert(paints, {start = tstart, len = tend, style = tstyle})
          end
        end
        tstart = tend
      end
    else
      --do colorizing according the style
      table.insert(paints, {start = start, len = start+#capture-1,
                            style = existent[style]})
    end
  until start == nil
  return result, paints
end

function silent_print(text)
  local current_window = vis.win
  vis:message(tostring(text))
  if current_window ~= nil then  vis.win = current_window end
end

function close_message_window()
  notifier:hide()
end
function popup_print(text)
  vis.ignore = true
  local lastwin = vis.win
  notifier:show()
  -- the order matters! stylize needs to have window that it is stylizing in
  -- focus
  local cleantext, paints = stylize(text)
  notifier:setText("\n"..cleantext)
  local curwin = notifier.win
  local painter = function(win)
    for _, task in pairs(paints) do
      win:style(task.style, task.start, task.len)
    end
  end
  curwin.error_highlighter = painter
  if lastwin and vis.win ~= lastwin then vis.win = lastwin end
  vis.ignore = false
end

function debugme(tab, lvl)
  if lvl == nil then lvl = 0 end
  local indent = string.rep("  ", lvl)
  for k, v in pairs(tab) do
    silent_print(indent..k..": "..tostring(v))
    if type(v) == "table" then
      debugme(v, lvl + 1)
    end
  end
end
