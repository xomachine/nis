require('nis.utils')
require('nis.message_window')
local graphic = require('nis.graphic')
local function helper(suggestions, window)
  local toshow = ""
  if not window.subwindows.notifier then
    window.subwindows.notifier = MessageWindow.new()
  end
  for _, suggestion in pairs(suggestions) do
    toshow = toshow.."\\e[syntax]"..suggestion.fullname..": "..suggestion.type..
             "\\e[reset]\n\n"..tostring(suggestion.comment)
  end
  stylized_print(window.subwindows.notifier, toshow)
end

local function extractArgs(line)
  local start, finish = matchBrace(line)
  if not start then return end
  return line:sub(start, finish-1)
end

local function arghelper(suggestions, window)
  local oldselection = window.selection.pos
  local curline = window.selection.line
  local backwarding = window.selection.col - 1
  local calltip = ""
  if #suggestions == 1 then
    calltip = extractArgs(suggestions[1].type)
    if calltip then
      vis:info(calltip)
    end
  else
    local variants = ""
    local empty = {start = 0, finish = 0}
    for i, suggestion in pairs(suggestions) do
      local arg = extractArgs(suggestion.type)
      if arg then
        variants = arg.."\n"..variants
      end
    end
    local state, result, _ = vis:pipe(window.file, empty, "echo -e '"..
                                      variants.."' | vis-menu -l 10")
    if state == 0 then
      if not variants:find(result) then
        vis:insert(result:match("^[^\n]+"))
        return
      else calltip = result
      end
    end
  end
  vis:insert(")")
  window.selection.pos = oldselection
  if calltip then
    local roi = {start=oldselection-backwarding, finish=oldselection}
    local func = window.file:content(roi)
    window.triggers.calltip = function(win)
      local curpos = win.selection.pos
      if win.selection.line == curline and curpos >= oldselection and
         win.file:content(roi) == func then
        local line = win.file.lines[curline]
        local astart, aend = matchBrace(line, backwarding)
        if aend and oldselection + aend - backwarding > curpos then
          vis:info(calltip)
        end
      end
    end
  end
end

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
    local stripped, forhelper = result:match("^.*%|[^|]+%|[^(]*m%s([^:]+):(.*)")
    if stripped == nil then stripped = result:match("^%s*([^%s]+)%s*$") end
    if stripped == nil then return end
    if stripped:match("[%$%%%=%<%>%[%]%!%^]") then
      stripped = '`'..stripped..'`' end
    local head = stripped:sub(1, #pattern)
    if head ~= pattern then
      vis:info(head.." ~= "..pattern)
      window.selection.pos = wordobject.start
      vis:replace(head)
      local todel = #pattern - #head
      if todel > 0 then
        local after = vis.win.selection.pos
        file:delete({start = after, finish = after + todel})
      end
    end
    window.selection.pos = wordobject.finish
    local residue = stripped:sub(#pattern+1)
    if type(residue) == "string" and #residue > 0 then vis:insert(residue) end
    if forhelper and forhelper:match("%(") then
      vis:insert("(")
      arghelper({[1] = {type = forhelper}}, window)
    end
    vis.events.emit(vis.events.WIN_HIGHLIGHT, window)
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
  local lexer, existent = register_colors(window)
  if not window.subwindows.errormessage then window.subwindows.errormessage = MessageWindow.new() end
  window.file.converter = {}
  local i = 1
  local pos = 0
  for line in window.file:lines_iterator() do
    local length = #line
    window.file.converter[i] = { start = pos, length = length }
    i = i + 1
    pos = pos + length + 1
  end
  local todo = function () end
  for i = 1, #suggestions do
    local suggestion = suggestions[i]
    todo(suggestion)
    if suggestion.file == window.file.path then
      local style = existent[error_style[suggestion.type].description]
      if not (suggestion.line and window.file.converter[suggestion.line]) then
        return
      end
      local pos = window.file.converter[suggestion.line].start +
        suggestion.column
      local selection = window.file:text_object_word(pos)
      table.insert(errors, {style = style, comment = suggestion.comment,
                            start = selection.start, finish = selection.finish})
      if suggestion.comment == "template/generic instantiation from here" then
        local last = #errors
        local lasttodo = todo
        todo = function(sug)
          if lasttodo then lasttodo(sug) end
          errors[last].comment = errors[last].comment.."\n"..sug.file.."("..
                                 tostring(sug.line)..","..
                                 tostring(sug.column)..") "..sug.comment
        end
      else
        todo = function () end
      end
    else
      todo = function () end
    end
  end
  window.triggers.error_highlighter = function(win)
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
      stylized_print(window.subwindows.errormessage, message)
    elseif message then
      window.subwindows.errormessage:hide()
      vis:info(message)
    else
      window.subwindows.errormessage:hide()
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
