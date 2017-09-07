
local function suggest(suggestions, window)
  local file = window.file
  local pattern = file:content(file:text_object_word(window.selection.pos-1))
  local variants = ""
  for _, suggestion in pairs(suggestions) do
    variants = variants..(#variants>0 and "," or "")..suggestion.name
  end
  vis:command("<echo '"..variants.."' | vis-complete --word '"..pattern.."'")
end

local function helper(suggestions, window)
  local suggestion = suggestions[1]
  vis:info(tostring(suggestion.comment))
  vis:message(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
end

local responces = {
  -- a table with functions which should be called on certain suggestion type
  -- encounter
  suggest = suggest,
  help = helper,
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
