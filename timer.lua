
Timer = {}

local function getpid()
  local handle = io.popen("echo $PPID", "r")
  local vispid = handle:read("l")
  handle:close()
  return vispid
end
local vispid = getpid()

Kicker = {
  active = false,
  references = 0,
  handle = false,
  timers = {},
  pid = 0,
}

local function on_kick(w)
  local time = os.time()
  for i, timer in pairs(Kicker.timers) do
    timer(time)
  end
end

function Kicker:ref()
  self.references = self.references + 1
  if not self.active then
    self.handle = io.popen("echo $$ && watch -n 1 -t 'kill -28 "..vispid..
                           "'", "r")
    self.pid = self.handle:read("l")
    self.active = true
    local e = vis.events
    e.subscribe(e.WIN_HIGHLIGHT, on_kick)
  end
end

function Kicker:unref()
  self.references = self.references - 1
  if self.references < 1 and self.active then
    local e = vis.events
    e.unsubscribe(e.WIN_HIGHLIGHT, on_kick)
    self.active = false
    os.execute('kill -2 '..self.pid)
    self.handle:close()
  end
end

function Timer:periodic(action, interval)
  if self.active then return "Timer is already active!" end
  if not interval then interval = 1 end
  local nexttime = os.time() + interval
  self.active = true
  Kicker.timers[self.id] = function (time)
    if time >= nexttime then
      nexttime = time + interval
      action()
    end
  end
  Kicker:ref()
end

function Timer:touchafter(action, interval)
  if self.active then return "Timer is already active!" end
  self.active = true
  if not interval then interval = 1 end
  local nexttime = os.time() + interval
  Kicker.timers[self.id] = function (time)
    if time >= nexttime then
      Kicker:unref()
      self.active = false
      action()
      Kicker.timers[self.id] = nil
    end
  end
  Kicker:ref()
end

function Timer:cancel()
  Kicker.timers[self.id] = nil
  self.active = false
  Kicker:unref()
  collectgarbage()
end

Timer.new = function ()
  local t = setmetatable({}, {__index=Timer})
  t.id = tostring(os.time())..tostring(math.random())
  t.active = false
  return t
end

