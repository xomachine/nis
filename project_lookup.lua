local lfs
require('nis.project')
require('nis.utils')
if vis:module_exist("lfs") then
  lfs = require("lfs")
else
  silent_print("lfs module does not exist, so project autodetection "..
               "support is disabled!")
end

local function findindir(path)
  -- Scans files in path and takes nim sources and nimble files into
  -- a tables. Sources will be first returned table an contains filenames as
  -- keys and tables of extensions as values. The tables of extensions contain
  -- extensions as keys to fast access. The nimbles table will be second return
  -- value and it contains just a nimble file names without extensions
  local sources = {}
  local nimbles = {}
  local nimhandler = function(n, e)
      if sources[n] == nil then sources[n] = {} end
      sources[n][e] = true
    end
  local dispatcher = {
    nimble = function(n, e) table.insert(nimbles, n) end,
    nim = nimhandler,
    nims = nimhandler,
    cfg = nimhandler,
  }
  for filename in lfs.dir(path) do
    local name, ext = filename:match("^(.+)%.([^%.]+)$")
    if type(ext) == "string" and type(name) == "string" then
      local todo = (dispatcher[ext] or function() end)
      todo(name, ext)
    end
  end
  return sources, nimbles
end

function find_projectfile(basefile)
  -- Searches for project files across the parent directories.
  if lfs == nil then return basefile end
  local path = basefile.."s"
  repeat
    local curdir, child = splitpath(path)
    if child == nil then break end
    local sources, nimbles = findindir(curdir)
    if #nimbles > 0 then
      if #nimbles > 1 then
        silent_print("WARNING: There are to many nimble files found in "..
                     "one directory! Taking first file...")
      end
      local nimble = nimbles[1]
      -- check if executable is explicitly set inside the nimble file
      local candidate = parse_nimble(curdir.."/"..nimble..".nimble")
      if type(candidate) == "string" then
        return candidate
      end
      if type(sources[nimble]) == "table" and sources[nimble].nim then
        return curdir.."/"..nimble..".nim"
      end
    end
    for source, exts in pairs(sources) do
      if #exts > 1 and exts.nim then
        return curdir.."/"..source..".nim"
      end
    end
    path = curdir
  until child == nil
  return basefile
end
