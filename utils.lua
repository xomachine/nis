
function silent_print(text)
  local current_window = vis.win
  vis:message(text)
  if current_window ~= nil then  vis.win = current_window end
end
