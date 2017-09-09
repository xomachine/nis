local Session = require('nis.sessions')
require('nis.commands')
local sessions = {} -- a table "filepath" - session

local function debugme(tab)
  for k, v in pairs(tab) do
    vis:message(k..": "..tostring(v))
  end
end
local function current_session()
  if vis.win and vis.win.file then
    return sessions[vis.win.file.path]
  end
end

local function on_brace(session)
  vis:insert("()")
  vis.win.selection.pos = vis.win.selection.pos - 1
  session:context()
  return true
end

function get_help()
  local session = current_session()
  if session == nil then return end
  session:help()
end

function suggest_key()
  local session = current_session()
  if session == nil then return end
  session:suggest()
end

local keyactions = {
  ['('] = on_brace,
}

function dispatch_input(key)
  local session = current_session()
  if session == nil then return end
  if keyactions[key] then return keyactions[key](session) end
end

function on_open(file)
  if file == nil or file.path == nil then return end
  if file.path:sub(-3) == "nim" then
    if sessions[file.path] then
      local cur = sessions[file.path].refcounter
      sessions[file.path].refcounter = cur + 1
    else
      sessions[file.path] = Session.new(file.path)
      sessions[file.path].refcounter = 1
    end
    debugme(sessions[file.path])
  end
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

