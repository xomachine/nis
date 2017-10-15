
MessageWindow = {}

function MessageWindow:storeWin()
  if vis.win ~= self.win then self.wintostore = vis.win end
end
function MessageWindow:restoreWin()
  if self.wintostore and self.wintostrore ~= self.win then
    vis.win = self.wintostore
  end
  self.wintostore = nil
end

function MessageWindow:destroy()
  self:hide()
  os.remove(self.file)
  self.file = nil
end

function MessageWindow:isVisible()
  if self.win then
    for win in vis:windows() do
      if win == self.win then return true end
    end
    self.win = nil
  end
  return false
end

function MessageWindow:setText(text, append)
  if text ~= self.text or append then
    local fd = io.open(self.file, append and "a" or "w")
    fd:write(text.."\n")
    fd:flush()
    fd:close()
    if self:isVisible() then
      self:storeWin()
      vis.win = self.win
      vis:command("e!")
      self:restoreWin()
    end
    self.text = (append and self.text or "")..text
  end
end

function MessageWindow:showOnBg()
  self:storeWin()
  self:show()
  self:restoreWin()
end

function MessageWindow:show()
  if not self:isVisible() then
    vis:command("o "..self.file)
    self.win = vis.win
  else
    vis.win = self.win
  end
end

function MessageWindow:hide()
  if self:isVisible() then
    self:storeWin()
    vis.win = self.win
    vis:command("q!")
    self:restoreWin()
    self.win = nil
  end
end

MessageWindow.new = function ()
  local win = setmetatable({}, {
    __index=MessageWindow,
    __gc=function(o) os.remove(o.file) o.file = nil end})
  win.file = os.tmpname()
  win.text = ""
  win.win = nil
  vis.events.subscribe(vis.events.QUIT, function() win:destroy() end)
  return win
end

