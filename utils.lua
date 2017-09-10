local colors = require('nis.graphic').colors
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

local function register_colors(additional_styles)
  for name, id in pairs(additional_styles) do
    local style = vis.lexers['STYLE_'..name:upper()] or ""
    vis.win:style_define(id, style)
  end
  for color, code in pairs(colors) do
    local num1, num2 = code:match("^\\e%[(%d+);(%d+)m$")
    if num1 == num2 and num1 ~= nil then
      local s = vis.win:style_define(tonumber(num1),
        "visible,bold,fore:"..color:lower())
    end
  end
end

local function stylize(data)
  local start, finish, capture, style
  local starth, finishh, captureh
  local result = data
  local lexer = vis.lexers.load("nim", nil, true)
  if lexer == nil then starth = -1 lexer = {} end
  local styles = lexer._TOKENSTYLES
  register_colors(styles)
  local paints = {}
  start, finish, style, capture =
    result:find("\\e%[(%d+);%d+m([^\\]+)\\e%[0m", start)
  starth, finishh, captureh =
    result:find("%.%.%scode%-block::%sNim\n(.-\n\n)", starth)
  repeat
    if start == nil and starth == nil then break
    elseif type(start) ~= "number" or (type(starth) == "number" and starth < start) then
      --do for starth
      local lendiff = #result
      result = result:sub(1, starth-1)..captureh..result:sub(finishh+1)
      lendiff = lendiff - #result
      local tokens = lexer:lex(captureh, 1)
      local tstart = starth
      for i = 1, #tokens, 2 do
        local tend = starth + tokens[i+1] - 1
        if tend >= tstart then
          local name = tokens[i]
          local tstyle = styles[name]
          if tstyle ~= nil then
            table.insert(paints, {start = tstart, len = tend, style = tstyle})
          end
        end
        tstart = tend
      end
      if start then
        start = start - lendiff
        finish = finish - lendiff
      end
      starth, finishh, captureh =
        result:find("%.%.%scode%-block::%sNim\n(.-\n\n)", starth)
    elseif starth == nil or start < starth then
      --do for start
      local lendiff = #result
      result = result:sub(1, start-1)..capture..result:sub(finish+1)
      lendiff = lendiff - #result
      table.insert(paints, {start = start, len = start+#capture-1,
                            style = tonumber(style)})
      if starth then
        starth = starth - lendiff
        finishh = finishh - lendiff
      end
      start, finish, style, capture =
        result:find("\\e%[(%d+);%d+m([^\\]+)\\e%[0m", start)
    else
      error("Should never happened! "..tostring(start)..":"..tostring(starth))
    end
  until start == nil
  return result, paints
end

function silent_print(text)
  local current_window = vis.win
  vis:message(tostring(text))
  if current_window ~= nil then  vis.win = current_window end
end

function popup_print(text)
  local current_window = vis.win
  vis:message("tofocustmpwindow")
  local file = vis.win.file
  file:delete({start = 0, finish = file.size-1})
  local cleantext, paints = stylize(text)
  vis:message(cleantext)
  local curwin = vis.win
  local paint = function(win)
    for _, task in pairs(paints) do
      curwin:style(task.style, task.start, task.len)
    end
  end
  local remover = function (win)
    if win == curwin then
      vis.events.unsubscribe(vis.events.WIN_HIGHLIGHT, paint)
      vis.events.unsubscribe(vis.events.WIN_CLOSE, remover)
    end
  end
  vis.events.subscribe(vis.events.WIN_HIGHLIGHT, paint)
  vis.events.subscribe(vis.events.WIN_CLOSE, remover)
  if current_window ~= nil then  vis.win = current_window end
end

function debugme(tab)
  for k, v in pairs(tab) do
    silent_print(k..": "..tostring(v))
  end
end
