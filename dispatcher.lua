require('nis.utils')
require('nis.message_window')
local graphic = require('nis.graphic')
local function suggest(suggestions, window)
  local file = window.file
  local pos = window.selection.pos
  local wordobject = file:text_object_word(pos-1 < 1 and 1 or pos-1)
  local pattern = file:content(wordobject) or ""
  if type(pattern) ~= "string" then pattern = ""
  elseif pattern:match("([a-zA-Z0-9])") == nil then pattern = "" end
  local dotpattern = pattern:match("^.*%.([^%.]*)$")
  if type(dotpattern) == "string" then pattern = dotpattern end
  local variants = ""
  for _, suggestion in pairs(suggestions) do
    variants = variants..(#variants>0 and "\n" or "")..
               (graphic.associations[suggestion.skind] or "").."|"..
               (graphic.glyphs[suggestion.skind] or " U ").."|"..
               graphic.colors.White:encode().." "..suggestion.name..": "..
               suggestion.type
  end
  local empty = {start = 0, finish = 0}
  local state, result, _ = vis:pipe(file, empty, "echo -e '"..variants..
                                    "' | vis-menu -l 10 '"..pattern.."'")
  if state == 0 then
    local stripped = result:match("^.*%|[^|]+%|[^(]*m%s([^:]+):.*")
    if stripped == nil then stripped = result:match("^%s*([^%s]+)%s*$") end
    if stripped:match("[%$%%%=%<%>%[%]%!%^]") then
      stripped = '`'..stripped..'`' end
    local head = stripped:sub(1, #pattern)
    if head ~= pattern then
      silent_print(head.." ~= "..pattern)
      window.selection.pos = wordobject.start
      vis:replace(head)
      local todel = #pattern - #head
      if todel > 0 then
        local after = vis.win.selection.pos
        file:delete({start = after, finish = after + todel})
      end
    end
    local residue = stripped:sub(#pattern+1)
    if type(residue) == "string" and #residue > 0 then vis:insert(residue) end
    vis.events.emit(vis.events.WIN_HIGHLIGHT, window)
  end
end

local function helper(suggestions, window)
  local toshow = ""
  for _, suggestion in pairs(suggestions) do
    toshow = toshow.."\\e[syntax]"..suggestion.fullname..": "..suggestion.type..
             "\\e[reset]\n\n"..tostring(suggestion.comment)
  end
  popup_print(toshow)
end

local function arghelper(suggestions, window)
  if #suggestions == 1 then
    vis:info(suggestions[1].type:match("%((.*)%)"))
  else
    for suggestion in pairs(suggestions) do
      silent_print(suggestion.type)
    end
  end
end

local function deffinder(suggestions, window)
  local suggestion = suggestions[1]
  if suggestion.file ~= window.file.path then
    --open the file
    vis:command("open "..suggestion.file)
  end
  vis.win.selection:to(suggestion.line, suggestion.column)
end

local function highlight_errors(suggestions, window)
  local errors = {}
  local error_style = graphic.error_style
  local lexer, existent = register_colors()
  local errormessage = MessageWindow.new()
  window.file.converter = {}
  local i = 1
  local pos = 0
  for line in window.file:lines_iterator() do
    local length = #line
    window.file.converter[i] = { start = pos, length = length }
    i = i + 1
    pos = pos + length + 1
  end
  for _, suggestion in pairs(suggestions) do
    if suggestion.file == window.file.path then
      local style = existent[error_style[suggestion.type].description]
      local pos = window.file.converter[suggestion.line].start +
        suggestion.column
      local selection = window.file:text_object_word(pos)
      table.insert(errors, {style = style, comment = suggestion.comment,
                            start = selection.start, finish = selection.finish})
    end
  end
  window.error_highlighter = function(win)
    if win.file.modified then return end
    local content = win.viewport
    local selection = win.selection.pos
    local message
    for _, err in pairs(errors) do
      if (err.finish > content.start and err.finish < content.finish) or
         (err.start > content.start and err.start < content.finish) then
        win:style(err.style, err.start, err.finish)
        --silent_print("Got you!"..tostring(err.start))
        if selection < err.finish and selection > err.start then
          message = err.comment
        end
      end
    end
    local multiline = message and (message:find("\n") or #message >= win.width)
    if multiline then
      vis.ignore = true
      errormessage:setText(message)
      errormessage:showOnBg()
      vis.ignore = false
    elseif message then
      errormessage:hide()
      vis:info(message)
    else
      errormessage:hide()
    end
  end
end

local responces = {
  -- a table with functions which should be called on certain suggestion type
  -- encounter
  suggest = suggest,
  help = helper,
  context = arghelper,
  gotodef = deffinder,
  check = highlight_errors,
}

function dispatch(filepath, request, suggestions)
  -- Generic NISGOTANSWER event handler, which searches for the window related
  -- to the suggestion and calls particular suggestion handler
  if suggestions == nil then return end
  local window = vis.win
  if window.file.path ~= filepath then
    -- Search for related windows
  end
  local handler = responces[request]
  if handler then handler(suggestions, window) end
end
