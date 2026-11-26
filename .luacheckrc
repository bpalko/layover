std = "lua51"
max_line_length = 140
unused_args = false

files["src/core/data.lua"] = {
  max_line_length = false,
}

globals = {
  "Layover",
  "LayoverDB",
  "LoadLayoverCore",
}

files["src/wow"] = {
  read_globals = {
    "C_Map", "C_Spell", "C_SpellBook",
    "CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME",
    "UnitName", "UnitClass", "UnitFactionGroup", "UnitLevel",
    "UnitOnTaxi", "GetRealmName", "GetBindLocation", "GetZoneText",
    "GetSubZoneText", "GetItemCooldown", "GetSpellCooldown",
    "GetSpellInfo", "GetSpellBookItemName", "GetUnitSpeed",
    "GetTime", "IsMounted", "IsPlayerSpell", "NumTaxiNodes",
    "TaxiNodeGetType", "TaxiNodeName", "BOOKTYPE_SPELL",
    "pcall", "SlashCmdList", "TomTom",
  },
}

files["src/ui"] = {
  read_globals = {
    "CreateFrame", "UIParent", "SlashCmdList",
    "BackdropTemplateMixin", "GameFontNormalLarge",
    "GameFontHighlight", "GameFontHighlightSmall", "GameFontDisableSmall",
    "InputBoxTemplate", "UIPanelButtonTemplate", "UIPanelCloseButton",
    "pcall",
  },
}

files["Layover.lua"] = {
  read_globals = { "pcall" },
}

files["tests"] = {
  ignore = { "111", "112", "113" },
}
