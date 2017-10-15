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

function get_error_file()
  if (not vis.error_file) or not vis.message_window then
    vis:message("tofocusmsgwindow")
    vis.error_file = vis.win.file
    vis.message_window = vis.win
    vis.win.selection.pos = 0
    vis.error_file:delete(0, vis.error_file.size)
  end
  return vis.error_file
end
--function open_message_window()
--  if not vis.message_window then
--    local file = get_error_file()
--    vis:command("new")
--    vis.win.file = file
--    vis.message_window = vis.win
--  end
--  return vis.message_window
--end
--function open_message_window_in_bg()
--  local curwin = vis.win
--  local msgwin = open_message_window()
--  if curwin then vis.win = curwin end
--  return msgwin
--end
function close_message_window()
  if vis.message_window then
    if vis.ignore then return end
    vis.ignore = true
    vis.win = vis.message_window
    vis:command("q!")
    vis.message_window = nil
    vis.ignore = false
  end
end
function popup_print(text)
  if vis.ignore then return end
  vis.ignore = true
  local lastwin = vis.win
  local file = get_error_file()
  local curwin = vis.message_window
  curwin.selection.pos = 0
  file:delete(0, file.size)
  local cleantext, paints = stylize(text)
  --vis:message(cleantext)
  file:insert(0, "\n"..cleantext)
  if curwin.remover then curwin.remover() end
  local painter = function(win)
    for _, task in pairs(paints) do
      curwin:style(task.style, task.start, task.len)
    end
  end
  local remover
  remover = function(win)
    vis.events.unsubscribe(vis.events.WIN_HIGHLIGHT, painter)
    vis.events.unsubscribe(vis.events.WIN_CLOSE, remover)
    curwin.painter = nil
    curwin.remover = nil
  end
  curwin.remover = remover
  vis.events.subscribe(vis.events.WIN_HIGHLIGHT, painter)
  vis.events.subscribe(vis.events.WIN_CLOSE, remover)
  if lastwin then vis.win = lastwin end
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
