local colors = require('nis.graphic').colors
require('nis.message_window')
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

function register_colors(window)
  local holes = {}
  local existant = {}
  local lexer = vis.lexers.load("nim", nil, true)
  for i = 0, 64, 1 do holes[i] = true end
  for name, id in pairs(lexer._TOKENSTYLES) do
    local style = vis.lexers['STYLE_'..name:upper()] or ""
    window:style_define(id, style)
    existant[style] = id
    holes[id] = nil
  end
  return lexer, setmetatable(existant, {__index = function(t, k)
    local free
    for freeid in pairs(holes) do
      free = freeid
      break
    end
    if window:style_define(free, k) then
      holes[free] = nil
      t[k] = free
      return free
    else return 65 -- UI_STYLE_DEFAULT
    end
  end})
end

local function stylize(window, data)
  local start, finish, style, lexer, existent
  local result = data
  if not window.existent then
    lexer, existent = register_colors(window)
  else
    existent = window.existent
    lexer = vis.lexers.load("nim", nil, true)
  end
  local styles = lexer._TOKENSTYLES
  local paints = {}
  local tokenstart = 0
  local currenttoken = "reset"
  repeat
    start, finish, style = result:find("\\e%[([^%]]+)%]", start)
    if start == nil then
      start = #result
      style = "reset"
    else
      result = result:sub(1, start-1)..result:sub(finish+1)
    end
    if currenttoken ~= "reset" then
      if currenttoken == "syntax" then
        --do syntax highlighting
        local tokens = lexer:lex(result:sub(tokenstart,start), 1)
        local tstart = tokenstart
        for i = 1, #tokens, 2 do
          local tend = tokenstart + tokens[i+1] - 1
          if tend >= tstart then
            local name = tokens[i]
            local tstyle = styles[name]
            if tstyle ~= nil then
              table.insert(paints, {start = tstart, finish = tend,
                           style = tstyle})
            end
          end
          tstart = tend
        end
      elseif tokenstart == start and style ~= "syntax" then
        currenttoken = currenttoken..","..style
      else
        --do colorizing according the style
        table.insert(paints, {start = tokenstart, finish = start,
                              style = existent[currenttoken]})
      end
    end
    tokenstart = start
    currenttoken = style
  until start == #result
  window.existent = existent
  return result, paints
end

function matchBrace(line, pos)
  -- Matches closing brace taking into account internal braces
  -- pos should be a position before opening brace
  local start = pos
  if not start then
    start = line:find("(", 1, true)
    if not start then return
    else start = start + 1 end
  end
  pos = start
  local unmatched = 1
  while unmatched > 0 do
    start = line:find("[()]", start+1)
    if not start then return end
    local matched = line:sub(start, start)
    if matched == "(" then unmatched = unmatched + 1
    else unmatched = unmatched - 1 end
  end
  return pos, start
end

function silent_print(text)
  local current_window = vis.win
  vis:message(tostring(text))
  if current_window ~= nil then  vis.win = current_window end
end

function stylized_print(notifier, text)
  vis.ignore = true
  local lastwin = vis.win
  notifier:show()
  -- the order matters! stylize needs to have window that it is stylizing in
  -- focus
  local cleantext, paints = stylize(notifier.win, text)
  notifier:setText("\n"..cleantext)
  local curwin = notifier.win
  local painter = function(win)
    for _, task in pairs(paints) do
      win:style(task.style, task.start, task.finish)
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
