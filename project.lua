require('nis.utils')
require('nis.ui')

function openInProject(argv, force, window)
  -- Suggest to open a file from the project
  local file = window.file
  if not file or not file.project then return end
  local dir = file.project:match("^(.*/)[^/]+$")
  local empty = {start = 0, finish = 0}
  local state, result = vis:pipe(file, empty, 'cd '..dir..
                                 '; find . -name "*.nim*" | vis-menu -l 10')
  if state == 0 then
    vis:command("o "..dir..result)
  end
end

function build(argv, force, window)
  local file = window.file
  if not file or not file.project or not file.nimblefile then
    return
  end
  local args = ""
  for i, arg in ipairs(argv) do
    args = args .. " " .. arg
  end
  local projdir, _ = splitpath(file.nimblefile)
  if args == "" then args = "build" end
  local logfile = os.tmpname()
  local handle = io.popen("cd "..projdir.."; nimble "..args..
                          " &>"..logfile.."; echo Finish >>"..logfile, "w")
  local readhandle = io.open(logfile, "r")
  window.subwindows.buildlog = MessageWindow.new()
  window.triggers.obtain_build_log = function(w)
    local summary, line
    repeat
      line = readhandle:read("l")
      if line == "Finish" then
        readhandle:close()
        handle:close()
        os.remove(logfile)
        w.triggers.obtain_build_log = nil
        line = nil
      elseif line ~= nil then
        summary = summary and summary.."\n"..line or line
      end
    until line == nil
    if summary then
      summary = convertTermColors(summary)
      local logwin = w.subwindows.buildlog
      stylized_print(logwin, summary, true)
      logwin.win.selection.pos = #logwin.text-1
    end
  end
end

function parse_nimble(path)
  -- Parses given nimble file and searches for "bin = <smth>" line.
  -- The first existent source path for bin directives found will be returned.
  -- In case of no bin directive the function returns nil
  local fd = io.open(path, 'r')
  if fd == nil then return end
  local result
  local srcDir
  local binaries = {}
  for line in fd:lines() do
    local k, v = line:match("^%s*(%S+)%s*=%s*(.+)%s*$")
    if v == nil then
    elseif k == "srcDir" then
      srcDir = v:match('^%"([^%"]+)%"$')
    elseif k == "bin" then
      for actual_binary in v:gmatch('%"([^%"%,]+)%"') do
        table.insert(binaries, actual_binary)
      end
    end
  end
  fd:close()
  local curdir, _ = splitpath(path)
  for _, binary in pairs(binaries) do
    result = curdir.."/"..binary..".nim"
    if fileexist(result) then return result
    elseif srcDir then
      result = curdir.."/"..srcDir.."/"..binary..".nim"
      if fileexist(result) then return result end
    end
  end
end

