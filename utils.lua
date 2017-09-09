
function silent_print(text)
  local current_window = vis.win
  vis:message(text)
  if current_window ~= nil then  vis.win = current_window end
end

function debugme(tab)
  for k, v in pairs(tab) do
    silent_print(k..": "..tostring(v))
  end
end
