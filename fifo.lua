ReadFifo = {}

function ReadFifo:close()
  os.remove(self.path)
end

function ReadFifo:truncate()
  local fd = io.open(self.path, "w")
  fd:flush()
  fd:close()
end

function ReadFifo:peek()
  local fd = io.open(self.path, "r")
  local result = fd:read("*a")
  fd:close()
  return result
end
function ReadFifo:read()
  local result = self:peek()
  self:truncate()
  return result
end

function ReadFifo.new(name)
  local fifo = setmetatable({}, {__index=ReadFifo})
  fifo.path = name
  return fifo
end

