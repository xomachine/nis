require("nis.utils")
require("nis.dispatcher")

Session = {
  file = nil,
  write_fd = nil,
}

function Session:close()
  -- Closes current nimsuggest session and removes all
  -- related temporary files
  --silent_print("Closing session for "..self.file)
  self:command("quit")
  os.remove(self.dirty)
  self.write_fd:close()
  vis.events.unsubscribe(vis.events.PROCESS_RESPONCE, self.on_responce)
end

function Session:command(name, add_position)
  -- Sends command to nimsuggest. If add_position is true
  -- the position of the cursor will be added to the end
  -- of the command. The function returns immidiately after
  -- sending command.
  if io.type(self.write_fd) ~= "file" then
    vis:info("Nimsuggest crashed somehow! Restarting...")
    self:restart()
  end
  local filepos = ""
  local dirty = false
  if add_position then
    if vis.win.file.modified then
      --silent_print("Made dirtyfile: "..dirty)
      local dd = assert(io.open(self.dirty, "w"))
      for line in vis.win.file:lines_iterator() do
        dd:write(line.."\n")
      end
      dd:flush()
      dd:close()
    end
    local path = vis.win.file.path
    local sel = vis.win.selection
    filepos = " "..path..';'..(dirty and self.dirty or path)..':'..
              tostring(sel.line)..':'..tostring(sel.col-1)
  end
  local request = name..filepos.."\n"
  self.write_fd:write(request)
  self.write_fd:flush() -- needed to push request forward to nimsuggest
  --silent_print("Sent to nimsuggest: "..request)
  if dirty then os.remove(dirty) end
end

function Session:restart()
  -- Restarting died session with preserving refcounter and filename
  local file = self.file
  local refcounter = self.refcounter
  self:close()
  self:init(file)
  self.refcounter = refcounter
end

function Session.new(filepath)
  -- Creates new nimsuggest session for given file.
  -- This constructor either launches nimsuggest and
  -- prepares all necessary async IO handlers.
  local newtable = setmetatable({}, {__index = Session})
  newtable:init(filepath)
  return newtable
end

function Session:init(filepath)
  self.request = false
  self.file = filepath
  self.dirty = os.tmpname()
  self.name = "nis-"..self.dirty
  self.on_responce = genOnResponce(self.name)
  vis.events.subscribe(vis.events.PROCESS_RESPONCE, self.on_responce)
  -- setsid is necessary to prevent SIGINT forwarding from vis when Ctrl-C
  -- pressed
  --silent_print("Session created with name "..self.name.." for file "..self.file)
  self.write_fd = assert(vis:communicate(self.name,
    'setsid -w nimsuggest --tester '..self.file))
end

