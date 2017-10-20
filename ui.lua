require('nis.message_window')

function silent_print(text)
  local current_window = vis.win
  vis:message(tostring(text))
  if current_window ~= nil then  vis.win = current_window end
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

function stylized_print(notifier, text, append)
  local lastwin = vis.win
  notifier:show()
  -- the order matters! stylize needs to have window that it is stylizing in
  -- focus
  local curwin = notifier.win
  local cleantext, paints = stylize(curwin, text)
  if append then
    if not curwin.paints then curwin.paints = {} end
    local shift = #notifier.text
    for i, paint in pairs(paints) do
      table.insert(curwin.paints, {
        style = paint.style,
        start = paint.start + shift,
        finish = paint.finish + shift
      })
    end
  else
    curwin.paints = paints
  end
  notifier:setText("\n"..cleantext, append)
  curwin.error_highlighter = function(win)
    for _, task in pairs(win.paints) do
      win:style(task.style, task.start, task.finish)
    end
  end
  if lastwin and vis.win ~= lastwin then vis.win = lastwin end
end


local colors = require('nis.graphic').colors
function convertTermColors(line)
  local replacer = function(a)
    if a == "0" then return "\\e[reset]" end
    for i, v in pairs(colors) do
      if v.id == a then return "\\e["..v.description.."]" end
    end
    return ""
  end
  return line:gsub("{27}%[([0-9]+)m", replacer)
end

