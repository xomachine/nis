require('nis.utils')
require('nis.message_window')
local graphic = require('nis.graphic')

local function redraw_errors(win)
  if not win.errors then return end
  if win.file.modified then return end
  local content = win.viewport
  local selection = win.selection.pos
  local message
  for _, err in pairs(win.errors) do
    if (err.finish > content.start and err.finish < content.finish) or
       (err.start > content.start and err.start < content.finish) then
      win:style(err.style, err.start, err.finish)
      if selection < err.finish and selection > err.start then
        message = err.comment
      end
    end
  end
  local multiline = message and (message:find("\n") or #message >= win.width)
  if multiline then
    stylized_print(win.subwindows.errormessage, message)
  elseif message then
    win.subwindows.errormessage:hide()
    vis:info(message)
  else
    win.subwindows.errormessage:hide()
  end
end

local todo = function () end

function on_error(suggestion)
  local window = vis.win
  if not suggestion then window.incomplete = false return end
  local lexer, existent = register_colors(window)
  local error_style = graphic.error_style
  if not window.incomplete then
    window.errors = {}
    window.incomplete = true
    window.file.converter = {}
    if not window.subwindows.errormessage then
      window.subwindows.errormessage = MessageWindow.new()
    end
    window.triggers.error_highlighter = redraw_errors
    local i = 1
    local pos = 0
    for line in window.file:lines_iterator() do
      local length = #line
      window.file.converter[i] = { start = pos, length = length }
      i = i + 1
      pos = pos + length + 1
    end
  end
  todo(suggestion)
  if suggestion.file == window.file.path then
    local style = existent[error_style[suggestion.type].description]
    if not (suggestion.line and window.file.converter[suggestion.line]) then
      return
    end
    local pos = window.file.converter[suggestion.line].start +
      suggestion.column
    local selection = window.file:text_object_word(pos)
    table.insert(window.errors, {style = style, comment = suggestion.comment,
                          start = selection.start, finish = selection.finish})
    if suggestion.comment == "template/generic instantiation from here" then
      local last = #window.errors
      local lasttodo = todo
      todo = function(sug)
        if lasttodo then lasttodo(sug) end
        window.errors[last].comment = window.errors[last].comment.."\n"..
                                      sug.file.."("..tostring(sug.line)..","..
                                      tostring(sug.column)..") "..sug.comment
      end
    else
      todo = function () end
    end
  else
    todo = function () end
  end
end
