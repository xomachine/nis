function parse_answer(answer)
  -- Parses nimsuggest answer and returns it as a structure.
  if answer == nil then return nil, "no input data" end
  local suggestion = {}
  local tail = ""
  suggestion.request, suggestion.skind, tail =
    answer:match("^(%l+)\t(sk%u%a+)\t(.*)$")
  if suggestion.request == "highlight"
  then
    suggestion.line, suggestion.column, suggestion.length =
      tail:match("^(%d+)\t(%d+)\t(%d+)%s*$")
  elseif suggestion.request
  then
    suggestion.fullname, suggestion.type, suggestion.file, suggestion.line,
      suggestion.column, suggestion.comment, suggestion.length =
      tail:match("^([^\t]*)\t([^\t]*)\t([^\t]+)\t(%d+)\t(%d+)\t\"(.*)\"\t(%d+)")
    if suggestion.fullname == nil then return nil, "not matching tail"  end
    suggestion.modulename, suggestion.functionname, suggestion.name =
      suggestion.fullname:match("^([^%.]+)%.*([^%.]-)%.([^%.]+)$")
    suggestion.name = suggestion.name or suggestion.fullname
    suggestion.comment = suggestion.comment:gsub("x0A", "\n")
    suggestion.comment = suggestion.comment:gsub("\\", "")
    suggestion.comment = suggestion.comment:gsub("``([^`]+)``",
      "\\e[syntax]%1\\e[reset]")
    suggestion.comment = suggestion.comment:gsub("`([^`]+)`",
      "\\e[fore:green]%1\\e[reset]")
    suggestion.comment = suggestion.comment:gsub(
      "\n..%scode%-?b?l?o?c?k?::%s[Nn][iI][mM]\n(.-)\n\n",
      "\n\n\\e[syntax]%1\\e[reset]\n\n")
  else
    return nil, "not matching request"
  end
  suggestion.line = tonumber(suggestion.line)
  suggestion.column = tonumber(suggestion.column) + 1
  return suggestion
end
