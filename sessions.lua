require("nis.parser")
require("nis.utils")
require("nis.fifo")

Session = {
  file = nil,
  write_fd = nil,
  outfifo = nil, -- it is not a fifo actually, just a file
  errfifo = nil,
}

function Session:close()
  -- Closes current nimsuggest session and removes all
  -- related temporary files
  --silent_print("Closing session for "..self.file)
  self:command("quit")
  self.write_fd:close()
  self.outfifo:close()
  self.errfifo:close()
end

function Session:command(name, add_position)
  -- Sends command to nimsuggest. If add_position is true
  -- the position of the cursor will be added to the end
  -- of the command. The function returns immidiately after
  -- sending command.
  -- Result of the command will returned asyncroniusly
  -- via "NISGOTANSWER" event.
  if io.type(self.write_fd) ~= "file" then
    vis:info("Nimsuggest crashed somehow! Restarting...")
    self:restart()
  end
  local filepos = ""
  local dirty = false
  if add_position then
    if vis.win.file.modified then
      --save file as temporary
      dirty = os.tmpname()
      --silent_print("Made dirtyfile: "..dirty)
      local dd = assert(io.open(dirty, "w"))
      for line in vis.win.file:lines_iterator() do
        dd:write(line.."\n")
      end
      dd:flush()
      dd:close()
    end
    local path = vis.win.file.path
    local sel = vis.win.selection
    filepos = " "..path..';'..(dirty or path)..':'..
              tostring(sel.line)..':'..tostring(sel.col-1)
  end
  local request = name..filepos.."\n"
  self.write_fd:write(request)
  self.write_fd:flush() -- needed to push request forward to nimsuggest
  --silent_print("Sent to nimsuggest: "..request)
  os.execute("sleep 0.2") -- give nimsuggest time to handle request
  self:cycle() -- read answers if any
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
  self.outfifo = ReadFifo.new(os.tmpname())
  self.errfifo = ReadFifo.new(os.tmpname())
  -- setsid is necessary to prevent SIGINT forwarding from vis when Ctrl-C
  -- pressed
  self.write_fd = assert(io.popen(
    'setsid -w nimsuggest --tester '..self.file..' 2>>'..self.errfifo.path..
    ' >>'.. self.outfifo.path, 'w'))
end

function Session:cycle()
  -- Checks if nimsuggest printed the text.
  -- If so, fires NISGOTANSWERFOR:<path to related file>
  -- event with filepath
  local result = {}
  local wait_counter = 20 -- ~1 second
  local request = self.request
  -- request should be marked as handled before emiting
  -- the NISGOTANSWER event to avoid deadlock when cycle will be called
  -- again during the event handling
  self.request = false
  --local logger = io.open("/tmp/logger.log", "a")
  repeat
    local rawline = self.outfifo:read("*l")
    if rawline then
      --logger:write("Got answer: "..rawline.."\n")
      local suggestion, errmsg = parse_answer(rawline)
      if suggestion then
        --logger:write("Suggestion added\n")
        table.insert(result, suggestion)
        -- If nimsuggest still printing we will give it more time
        if wait_counter < 10 then wait_counter = 10 end
      --else
        --logger:write(errmsg.."\n")
      end
    elseif request then
      wait_counter = wait_counter - 1
      os.execute("sleep 0.05")
    else break
    end
  until wait_counter == 0 or rawline == "!EOF!"
  if wait_counter == 0 then
    local possibleerror = self.errfifo:read("*a")
    local allcontent = self.outfifo:read("*a")
    local fd = assert(io.open("nimsuggest.log", "a"))
    fd:write("Timeout:"..tostring(request).." at "..self.file.."\n")
    fd:write("Last log messages:".."\n")
    fd:write(possibleerror.."\n")
    fd:write("Output buffer content:".."\n")
    fd:write(allcontent.."\n")
    fd:close()
    vis:info("Probably nimsuggest crashed... restarting")
    self:restart()
  end
  --self.errfifo:truncate()
  self.outfifo:truncate()
  if #result > 0 then
    vis.events.emit("NISGOTANSWER", self.file, request, result)
  end
  --logger:flush()
  --logger:close()
end


