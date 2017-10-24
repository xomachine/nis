require('nis.utils')
require('nis.ui')
require('nis.timer')

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
  if not file or (not file.project and not file.nimblefile) then
    return
  end
  local args = ""
  local is_compile = {c = true, cc = true, js = true, check = true}
  local withcompile = false
  for i, arg in ipairs(argv) do
    withcompile = withcompile or is_compile[arg]
    args = args .. " " .. arg
  end
  local projfile = withcompile and file.path or file.nimblefile or file.path
  local projdir, _ = splitpath(projfile)
  if args == "" then
    args = file.nimblefile and "build" or "c"
    withcompile = not file.nimblefile
  end
  args = args .. " "..(withcompile and projfile or "")
  local nimc = withcompile and "nim" or "nimble"
  local logfile = os.tmpname()
  local command = "cd "..projdir.."; "..nimc.." "..args.." &>"..logfile..
                  "; echo 'Build finished' >>"..logfile
  local handle = io.popen(command, "w")
  local readhandle = io.open(logfile, "r")
  local timer = Timer.new()
  if not window.subwindows.buildlog then
    window.subwindows.buildlog = MessageWindow.new()
  end
  window.subwindows.buildlog:setText("")
  local obtainlog = function(w)
    local summary, line
    repeat
      line = readhandle:read("l")
      if line then
        if line:find("Build finished") then
          readhandle:close()
          handle:close()
          os.remove(logfile)
          timer:cancel()
          timer:touchafter(function()end) -- just to redraw window one more time
          line = nil
        else
          summary = summary and summary.."\n"..line or line
        end
      end
    until line == nil
    if summary then
      summary = convertTermColors(summary)
      local logwin = window.subwindows.buildlog
      stylized_print(logwin, summary, true)
      logwin.win.selection.pos = #logwin.text-1
    end
  end
  timer:periodic(obtainlog)
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

