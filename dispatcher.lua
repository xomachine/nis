local colors = {
  Black = "\\e[30;30m",
  Blue = "\\e[34;34m",
  Green = "\\e[32;32m",
  Cyan = "\\e[36;36m",
  Red = "\\e[31;31m",
  Purple = "\\e[35;35m",
  Brown = "\\e[33;33m",
  LightGray = "\\e[37;37m", -- светло-серый
  DarkGray = "\\e[1;30m", -- тёмно-серый
  LightBlue = "\\e[1;34m", -- светло-синий
  LightGreen = "\\e[1;32m", -- светло-зелёный
  LightCyan = "\\e[1;36m", -- светло-голубой
  LightRed = "\\e[1;31m", -- светло-красный
  LightPurple = "\\e[1;35m", -- светло-сиреневый (пурпурный)
  Yellow = "\\e[1;33m", -- жёлтый
  White = "\\e[1;37m", -- белый
  NoColor = "\\e[0m", -- бесцветный
}

local suggest_glyphs = {
  skUnknown = "{U}",
  skAlias = " A ",
  skConst = " C ",
  skConverter = "C()",
  skDynLib = "LIB",
  skEnumField = ".EF",
  skField = "FLD",
  skForVar = "FOR",
  skGenericParam = "[G]",
  skIterator = " I ",
  skLabel = "LBL",
  skLet = " L ",
  skMacro = "M[]",
  skModule = "MOD",
  skMethod = "M()",
  skPackage = "PKG",
  skParam = "(P)",
  skProc = "P()",
  skResult = " R ",
  skStub = "{S}",
  skTemp = "Tmp",
  skTemplate = "T[]",
  skType = " T ",
  skVar = " V ",
}

local suggest_colors = {
  -- Other stuff
  skUnknown = colors.Purple,
  skAlias = colors.Purple,
  skDynLib = colors.Purple,
  skPackage = colors.Purple,
  skModule = colors.Purple,
  skLabel = colors.Purple,
  skType = colors.Purple,
  skStub = colors.Purple,
  skTemp = colors.Purple,
  -- Fields and vars
  skField = colors.Cyan,
  skEnumField = colors.Cyan,
  skForVar = colors.Cyan,
  skLet = colors.Cyan,
  skVar = colors.Cyan,
  skIterator = colors.Cyan,
  skParam = colors.Cyan,
  skResult = colors.Cyan,
  -- executables
  skProc = colors.Green,
  skConverter = colors.Green,
  skMethod = colors.Green,
  -- compile-time
  skTemplate = colors.Brown,
  skMacro = colors.Brown,
  skConst = colors.Brown,
  skGenericParam = colors.Brown,
}

local function suggest(suggestions, window)
  local file = window.file
  local pattern = file:content(file:text_object_word(window.selection.pos-1))
  local variants = ""
  for _, suggestion in pairs(suggestions) do
    variants = variants..(#variants>0 and "," or "")..suggestion.name
  end
  vis:command("<echo '"..variants.."' | vis-complete --word '"..pattern.."'")
end

local function helper(suggestions, window)
  local suggestion = suggestions[1]
  vis:info(tostring(suggestion.comment))
  vis:message(suggestion.fullname.."\n\n"..tostring(suggestion.comment))
end

local responces = {
  -- a table with functions which should be called on certain suggestion type
  -- encounter
  suggest = suggest,
  help = helper,
}

function dispatch(filepath, request, suggestions)
  -- Generic NISGOTANSWER event handler, which searches for the window related
  -- to the suggestion and calls particular suggestion handler
  if suggestions == nil then return end
  local window = vis.win
  if window.file.path ~= filepath then
    -- Search for related windows
  end
  local handler = responces[request]
  if handler then handler(suggestions, window) end
end
