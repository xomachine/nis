require('nis.utils')
local graphic = require('nis.graphic')
local function suggest(suggestions, window)
  local file = window.file
  local pattern =
    file:content(file:text_object_word(window.selection.pos-1)) or ""
  if type(pattern) ~= "string" then pattern = ""
  elseif pattern:match("([a-zA-Z0-9])") == nil then pattern = "" end
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
    if stripped == nil then stripped = result:match("%s*([^%s])%s*") end
    local head = stripped:sub(1, #pattern)
    if head ~= pattern then
      --vis:message(head.." ~= "..pattern)
      silent_print(head.." ~= "..pattern)
      vis.win.selection.pos = vis.win.selection.pos - #pattern
      vis:replace(head)
      local todel = #pattern - #head
      local pos = vis.win.selection.pos
      vis.win.file:delete({start = pos, finish = pos + todel})
    end
    local residue = stripped:sub(#pattern+1)
    if type(residue) == "string" and #residue > 0 then vis:insert(residue) end
  end
end

local function helper(suggestions, window)
  local suggestion = suggestions[1]
  --vis:info(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
  vis:message(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
end

local function arghelper(suggestions, window)
  if #suggestions == 1 then
    vis:info(suggestions[1].type:match("%((.*)%)"))
  else
    for suggestion in pairs(suggestions) do
      vis:message(suggestion.type)
    end
  end
end

local responces = {
  -- a table with functions which should be called on certain suggestion type
  -- encounter
  suggest = suggest,
  help = helper,
  context = arghelper,
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
