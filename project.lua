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
  local command = "cd "..projdir.."; "..nimc.." "..args
  if window.subwindows.buildlog then
    if window.subwindows.buildlog.win then
      window.subwindows.buildlog.win.paints = {}
    end
  else
    window.subwindows.buildlog = MessageWindow.new()
  end
  window.subwindows.buildlog:setText("")
  window.subwindows.buildlog.responce_printer = function(n, d, e)
    if n == "nisbuild-"..args then
      local blog = window.subwindows.buildlog
      if e == "EXIT" or e == "SIGNAL" then
        if e == "EXIT" and d == 0 then
          result = "\n\\e[bold,back:green,fore:white]### Build finished ###\\e[reset]\n"
        else
          result = "\n\\e[bold,back:red,fore:white]### Build failed with "..
                    e..": "..tostring(d).." ###\\e[reset]\n"
        end
        vis.events.unsubscribe(vis.events.PROCESS_RESPONCE, blog.responce_printer)
      else
        result = d:gsub("%[(%w+)%]$", "\\e[fore:cyan][%1]\\e[reset]")
        result = result:gsub("^([%l/.]+%([%d,%s]+%))",
                         "\\e[fore:blue]%1\\e[reset]")
        result = result:gsub("Hint:", "\\e[fore:green]Hint\\e[reset]:")
        result = result:gsub("Error:", "\\e[fore:red]Error\\e[reset]:")
        result = result:gsub("Warning:", "\\e[fore:yellow]Error\\e[reset]:")
        result = result:gsub("got %((.-)%) (but expected) '(.+)'",
                 "got (\\e[syntax]%1\\e[reset] %2 '\\e[syntax]%3\\e[reset]'")
      end
      result = convertTermColors(result)
      stylized_print(blog, result, true, true)
      blog.win.selection.pos = #blog.text-1
    end
  end
  vis.events.subscribe(vis.events.PROCESS_RESPONCE, window.subwindows.buildlog.responce_printer)
  window.subwindows.buildlog.handle = vis:communicate("nisbuild-"..args, command)
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

