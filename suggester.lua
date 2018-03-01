local graphic = require('nis.graphic')

function suggest(suggestions)
  local window = vis.win
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
