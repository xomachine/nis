require('nis.ui')
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


function matchBrace(line, pos)
  -- Matches closing brace taking into account internal braces
  -- pos should be a position before opening brace
  local start = pos
  if not start then
    start = line:find("(", 1, true)
    if not start then return
    else start = start + 1 end
  end
  pos = start
  local unmatched = 1
  while unmatched > 0 do
    start = line:find("[()]", start+1)
    if not start then return end
    local matched = line:sub(start, start)
    if matched == "(" then unmatched = unmatched + 1
    else unmatched = unmatched - 1 end
  end
  return pos, start
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
