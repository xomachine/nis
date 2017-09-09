
function silent_print(text)
  local current_window = vis.win
  vis:message(text)
  vis.win = current_window
end
