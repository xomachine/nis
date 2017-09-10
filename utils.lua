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


function silent_print(text)
  local current_window = vis.win
  vis:message(tostring(text))
  if current_window ~= nil then  vis.win = current_window end
end

function debugme(tab)
  for k, v in pairs(tab) do
    silent_print(k..": "..tostring(v))
  end
end
