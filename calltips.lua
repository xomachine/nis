local function extractArgs(line)
  local start, finish = matchBrace(line)
  if not start then return end
  return line:sub(start, finish-1)
end

function arghelper(suggestion)
  if not suggestion then return end
  local window = vis.win
  local oldselection = window.selection.pos
  local curline = window.selection.line
  local backwarding = window.selection.col - 1
  local calltip = extractArgs(suggestion.type)
  if not calltip then return  end
  vis:info(calltip)
  vis:insert(")")
  window.selection.pos = oldselection
  if calltip then
    local roi = {start=oldselection-backwarding, finish=oldselection}
    local func = window.file:content(roi)
    window.triggers.calltip = function(win)
      local curpos = win.selection.pos
      if win.selection.line == curline and curpos >= oldselection and
         win.file:content(roi) == func then
        local line = win.file.lines[curline]
        local astart, aend = matchBrace(line, backwarding)
        if aend and oldselection + aend - backwarding > curpos then
          vis:info(calltip)
        end
      end
    end
  end
end

