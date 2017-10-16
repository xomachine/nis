ReadFifo = {}

function ReadFifo:close()
  self.readfd:close()
  os.remove(self.path)
end

function ReadFifo:truncate()
  self.readfd:close()
  local fd = assert(io.open(self.path, "w"))
  fd:flush()
  fd:close()
  self.readfd = assert(io.open(self.path, "r"))
end

function ReadFifo:read(mode)
  if not mode then mode = "a" end
  if io.type(self.readfd) ~= "file" then return nil end
  local result = self.readfd:read(mode)
  return result
end

function ReadFifo.new(name)
  local fifo = setmetatable({}, {__index=ReadFifo})
  fifo.path = name
  fifo.readfd = assert(io.open(fifo.path, "r"))
  return fifo
end

