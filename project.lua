require('nis.utils')
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
