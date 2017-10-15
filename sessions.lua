require("nis.parser")
require("nis.utils")
require("nis.fifo")

local Session = {
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
    silent_print("Nimsuggest crashed somehow! Restarting...")
    self = Session.restart(self)
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

function Session.restart(prev)
  -- Restarting died session with preserving refcounter and filename
  local file = prev.file
  local refcounter = prev.refcounter
  prev:close()
  local result = Session.new(file)
  result.refcounter = refcounter
  return result
end

function Session.new(filepath)
  -- Creates new nimsuggest session for given file.
  -- This constructor either launches nimsuggest and
  -- prepares all necessary async IO handlers.
  local newtable = setmetatable({}, {__index = Session})
  newtable.request = false
  newtable.file = filepath
  newtable.outfifo = ReadFifo.new(os.tmpname())
  newtable.errfifo = ReadFifo.new(os.tmpname())
  -- setsid is necessary to prevent SIGINT forwarding from vis when Ctrl-C
  -- pressed
  newtable.write_fd = assert(io.popen(
    'nimsuggest --tester '..newtable.file..' 2>'..newtable.errfifo.path..
    ' >'.. newtable.outfifo.path, 'w'))
  return newtable
end

function Session:cycle()
  -- Checks if nimsuggest printed the text.
  -- If so, fires NISGOTANSWERFOR:<path to related file>
  -- event with filepath
  local result = {}
  local wait_counter = 25
  local request = self.request
  -- request should be marked as handled before emiting
  -- the NISGOTANSWER event to avoid deadlock when cycle will be called
  -- again during the event handling
  self.request = false
  --local logger = io.open("/tmp/logger.log", "a")
  repeat
    local rawsuggestion = self.outfifo:peek()
    --logger:write("Got answer: "..rawsuggestion.."\n")
    if rawsuggestion ~= nil and rawsuggestion:sub(-10):find("!EOF!") then
      self.outfifo:truncate()
      for line in rawsuggestion:gmatch("[a-z][^\n]+") do
        --logger:write("Found line: " .. line .. "\n")
        local suggestion = parse_answer(line)
        if suggestion ~= nil then
          --logger:write("Suggestion added\n")
          table.insert(result, suggestion)
        end
      end
      break
    elseif request then
      if io.type(self.write_fd) ~= "file" then
        local possibleerror = self.errfifo:read()
        silent_print("Nimsuggest crashed while handling request "..request..
                     " for file "..self.file..", and will be restarted!")
        if #possibleerror > 0 then
          silent_print("Last error messages:")
          silent_print(possibleerror)
        end
        self = Session.restart(self)
        break
      end
      wait_counter = wait_counter - 1
      os.execute("sleep 0.05")
    else break
    end
  until wait_counter == 0 or rawsuggestion == "!EOF!"
  local possibleerror = self.errfifo:read()
  if wait_counter == 0 then
    silent_print("Timeout:"..tostring(request).." at "..self.file)
    if #possibleerror > 0 then
      silent_print(possibleerror)
    end
  end
  --logger:flush()
  --logger:close()
  if #result > 0 then
    vis.events.emit("NISGOTANSWER", self.file, request, result)
  end
end

return Session

