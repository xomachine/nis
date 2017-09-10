require('nis.utils')
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
               (graphic.glyphs[suggestion.skind] or "U").."|"..
               graphic.colors.LightGray.." "..suggestion.name..": "..
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
  local suggestion = suggestions[1]
  --vis:info(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
  popup_print(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
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

local responces = {
  -- a table with functions which should be called on certain suggestion type
  -- encounter
  suggest = suggest,
  help = helper,
  context = arghelper,
  gotodef = deffinder,
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
