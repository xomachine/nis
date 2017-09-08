require("nis.parser")

local Session = {
  file = nil,
  write_fd = nil,
  read_fd = nil,
  fifo_path = nil,
}

function Session:close()
  -- Closes current nimsuggest session and removes all
  -- related temporary files
  vis:message("Closing session for "..self.file)
  self:command("quit")
  self.read_fd:close()
  self.write_fd:close()
  os.remove(self.fifo_path)
end

function Session:command(name, add_position)
  -- Sends command to nimsuggest. If add_position is true
  -- the position of the cursor will be added to the end
  -- of the command. The function returns immidiately after
  -- sending command.
  -- Result of the command will returned asyncroniusly
  -- via "NISGOTANSWER" event.
  local filepos = ""
  local dirty = false
  if add_position then
    if vis.win.file.modified then
      --save file as temporary
      dirty = os.tmpname()
      --vis:message("Made dirtyfile: "..dirty)
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
  --vis:message("Sent to nimsuggest: "..request)
  os.execute("sleep 0.2") -- give nimsuggest a time to handle request
  if dirty then os.remove(dirty) end
  self:cycle() -- read answers if any
end

function Session.new(filepath)
  -- Creates new nimsuggest session for given file.
  -- This constructor either launches nimsuggest and
  -- prepares all necessary async IO handlers.
  local newtable = Session
  newtable.file = filepath
  newtable.fifo_path = os.tmpname()
  os.execute("rm "..newtable.fifo_path) -- os automaticaly creates file,
  -- so we need to remove it first to make fifo
  local success, exitcode, signal = os.execute("mkfifo "..newtable.fifo_path)
  assert(success)
  newtable.write_fd = assert(io.popen('bash -c \'nimsuggest '..
    newtable.file..' 2>&1 | while read n; do echo "$n" > '..
    newtable.fifo_path..'; done\'', 'w'))
  newtable.read_fd = assert(io.open(newtable.fifo_path, "r"))
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
      --vis:message("Got answer: "..rawsuggestion)
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

