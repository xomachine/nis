require("nis.parser")
require("nis.utils")

local Session = {
  file = nil,
  write_fd = nil,
  read_fd = nil,
  outfifo = nil,
}

function Session:close()
  -- Closes current nimsuggest session and removes all
  -- related temporary files
  --silent_print("Closing session for "..self.file)
  self:command("quit")
  self.write_fd:close()
  self.read_fd:close()
  os.remove(self.outfifo)
end

function Session:command(name, add_position)
  -- Sends command to nimsuggest. If add_position is true
  -- the position of the cursor will be added to the end
  -- of the command. The function returns immidiately after
  -- sending command.
  -- Result of the command will returned asyncroniusly
  -- via "NISGOTANSWER" event.
  if io.type(self.write_fd) ~= "file" then
    silent_print("Nimsuggest crashed somehow! Restarting...")
    local file = self.file
    self:close()
    self = Session.new(file)
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
  if dirty then os.remove(dirty) end
  self:cycle() -- read answers if any
end

local function mktmpfifo()
  -- Creates new temporary fifo queue and returns its path
  -- Queue should be removed explicitly after use via os.remove
  local name = os.tmpname()
  os.remove(name)
  local success, exitcode, signal = os.execute("mkfifo "..name)
  if success then
    return name
  else
    error("Failed to create fifo pipe!")
  end
end

function Session.new(filepath)
  -- Creates new nimsuggest session for given file.
  -- This constructor either launches nimsuggest and
  -- prepares all necessary async IO handlers.
  local newtable = Session
  newtable.file = filepath
  newtable.outfifo = mktmpfifo()
  -- setsid is necessary to prevent SIGINT forwarding from vis when Ctrl-C
  -- pressed
  newtable.write_fd = assert(io.popen(
    'setsid -w bash -p -c \'(nimsuggest --stdin --v2 '..newtable.file..
    ' 2>&1 || echo "Crash!") | while read n; do echo "$n" >'..
    newtable.outfifo..' ; done\'', 'w'))
  newtable.read_fd = assert(io.open(newtable.outfifo, "r"))
  return newtable
end

function Session:cycle()
  -- Checks if nimsuggest printed the text.
  -- If so, fires NISGOTANSWERFOR:<path to related file>
  -- event with filepath
  local result = {}
  local rawsuggestion
  local tries = 0
  repeat
    rawsuggestion = self.read_fd:read("*l")
    if rawsuggestion ~= nil then
      if rawsuggestion == "Crash!" then
        silent_print("Nimsuggest crashed!")
        local file = self.file
        local refcounter = self.refcounter
        self:close()
        self = Session.new(file)
        self.refcounter = refcounter
      end
      --silent_print("Got answer: "..rawsuggestion)
      tries = tries + 1
      local suggestion = parse_answer(rawsuggestion)
      if suggestion ~= nil then
        table.insert(result, suggestion)
      end
    else
      if tries > 10 then
        os.execute("sleep 0.1")
        tries = 10
      else
        tries = tries - 1
      end
    end
  until rawsuggestion == nil and tries <= 0
  if #result > 0 then
    vis.events.emit("NISGOTANSWER", self.file, self.request, result)
  end
end

return Session

