local graphic = {
  colors = {
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
  },
  glyphs = {
    skUnknown = "{U}",
    skAlias = " A ",
    skConst = " C ",
    skConverter = "C()",
    skDynLib = "LIB",
    skEnumField = ".EF",
    skField = "FLD",
    skForVar = " I ",
    skGenericParam = "[G]",
    skIterator = "I()",
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
}
graphic.associations = {
    -- Other stuff
    skUnknown = graphic.colors.Purple,
    skAlias = graphic.colors.Purple,
    skDynLib = graphic.colors.Purple,
    skPackage = graphic.colors.Purple,
    skModule = graphic.colors.Purple,
    skLabel = graphic.colors.Purple,
    skType = graphic.colors.Purple,
    skStub = graphic.colors.Purple,
    skTemp = graphic.colors.Purple,
    -- Fields and vars
    skField = graphic.colors.Cyan,
    skEnumField = graphic.colors.Cyan,
    skForVar = graphic.colors.Cyan,
    skLet = graphic.colors.Cyan,
    skVar = graphic.colors.Cyan,
    skParam = graphic.colors.Cyan,
    skResult = graphic.colors.Cyan,
    -- executables
    skProc = graphic.colors.Green,
    skConverter = graphic.colors.Green,
    skMethod = graphic.colors.Green,
    skIterator = graphic.colors.Green,
    -- compile-time
    skTemplate = graphic.colors.Brown,
    skMacro = graphic.colors.Brown,
    skConst = graphic.colors.Brown,
    skGenericParam = graphic.colors.Brown,
  }
return graphic
