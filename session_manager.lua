require('nis.sessions')
require('nis.utils')
require('nis.commands')
require('nis.project_lookup')
require('nis.project')
local sessions = {} -- a table "filepath" - session

local function current_session()
  if vis.win and vis.win.file and vis.win.file.project then
    return sessions[vis.win.file.project]
  end
end

local function on_brace(session)
  vis:insert("(")
  session:context()
  return true
end

local function suggest_dot(session)
  if vis.win.file:content(vis.win.selection.pos-1, 1):match("%w") then
    vis:insert(".")
    session:suggest()
    return true
  else return false end
end

function check_it()
  local session = current_session()
  if session == nil then return end
  session:check()
end

function goto_def()
  local session = current_session()
  if session == nil then return end
  session:goto_definition()
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
  ['.'] = suggest_dot,
}

function dispatch_input(key)
  local session = current_session()
  if session == nil then return end
  if keyactions[key] then return keyactions[key](session) end
end

function on_open(file)
  if file == nil or file.path == nil or #file.path < 5 then return end
  if file.path:sub(-3) == "nim" then
    file.project, file.nimblefile = find_projectfile(file.path)
    vis:info("'"..file.project.."' used as a projectfile.")
    if sessions[file.project] then
      local cur = sessions[file.project].refcounter
      sessions[file.project].refcounter = cur + 1
    else
      sessions[file.project] = Session.new(file.project)
      sessions[file.project].refcounter = 1
    end
    --debugme(sessions[file.project])
  end
end

function on_close(file)
  if not file.project or not sessions[file.project] then return end
  local cur = sessions[file.project].refcounter
  if cur - 1 == 0 then
    sessions[file.project]:close()
    sessions[file.project] = nil
    collectgarbage()
  else
    sessions[file.project].refcounter = cur - 1
  end
end

function cycle_all(window)
  if vis.ignore then return end -- The lock to prevent endless windows updates
  vis.ignore = true
  for _, session in pairs(sessions) do
    session:cycle()
  end
  if window.triggers then
    for tname, trigger in pairs(window.triggers) do
      trigger(window)
    end
  end
  vis.ignore = false
end

function stop_all()
  for _, session in pairs(sessions) do
    session:close()
  end
end

