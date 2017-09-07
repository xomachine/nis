local Session = require('nis.sessions')
local sessions = {} -- a table "filepath" - session

local function debugme(tab)
  for k, v in pairs(tab) do
    vis:message(k..": "..tostring(v))
  end
end

function on_open(file)
  if file.path:sub(-3, 3) == "nim" or true then
    if sessions[file.path] then
      local cur = sessions[file.path].refcounter
      sessions[file.path].refcounter = cur + 1
    else
      sessions[file.path] = Session.new(file.path)
      sessions[file.path].refcounter = 1
    end
  end
  debugme(sessions[file.path])
end

function on_close(file)
  if not sessions[file.path] then return end
  local cur = sessions[file.path].refcounter
  if cur - 1 == 0 then
    sessions[file.path]:close()
    sessions[file.path] = nil
    collectgarbage()
  else
    sessions[file.path].refcounter = cur - 1
  end
end

function cycle_all()
  for _, session in pairs(sessions) do
    session:cycle()
  end
end

function stop_all()
  for _, session in pairs(sessions) do
    session:close()
  end
end

