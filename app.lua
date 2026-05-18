local _, playerClass = UnitClass("player")

if playerClass ~= "HUNTER" and playerClass ~= "ROGUE" then
    return
end

local MACRO_NAME = "WasntMe"
local lastTank = ""
local wasKnown = nil

local classConfigs = {
    HUNTER = { spellID = 34477, icon = "ability_hunter_misdirection", fallback = "pet" },
    ROGUE  = { spellID = 1224098, icon = "ability_rogue_tricksofthetrade", fallback = "target" }
}

local dict = {
    enUS = {
        msg = "Target for %s set to: |cff00ff00%s|r",
        created = "Macro '%s' created for %s.",
        full = "|cffff0000Error:|r No character macro slots available for %s.",
        warn = "TALENT NOT LEARNED: %s!"
    },
    deDE = {
        msg = "Ziel für %s auf |cff00ff00%s|r gesetzt",
        created = "Makro '%s' für %s erstellt.",
        full = "|cffff0000Fehler:|r Keine charakter-spezifischen Makro-Slots frei für %s.",
        warn = "TALENT NICHT GELERNT: %s!"
    }
}

local messages = dict[GetLocale()] or dict["enUS"]

local config = classConfigs[playerClass]

local function UpdateWasntMe()
    if InCombatLockdown() then return end

    local spellInfo = C_Spell.GetSpellInfo(config.spellID)

    if not spellInfo then
        return
    end

    local spellName = spellInfo.name
    local isSpellKnown = C_Spell.IsSpellUsable(spellName)

    local units = {"player", "party1", "party2", "party3", "party4", "raid1", "raid2"}
    local currentTank = nil

    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            currentTank = GetUnitName(unit, true)
            break
        end
    end

    local target = currentTank or config.fallback

    if target == lastTank and wasKnown == isSpellKnown then
        return
    end

    local macroIndex = GetMacroIndexByName(MACRO_NAME)

    local macroBody = ""

    if isSpellKnown then
        -- Normales Makro, wenn das Talent aktiv ist
        macroBody = string.format("#showtooltip %s\n/cast [@%s] %s", spellName, target, spellName)
    else
        -- Warn-Makro, das Text rot auf den Bildschirm wirft (Rote Farbe: 1, 0.1, 0.1)
        local warnText = string.format(messages.warn, string.upper(spellName))
        macroBody = string.format("#showtooltip %s\n/run UIErrorsFrame:AddMessage('%s', 1, 0.1, 0.1, 1.0, 5)", spellName, warnText)
    end

    if macroIndex == 0 then
        local _, numCharMacros = GetNumMacros()

        if numCharMacros >= 18 then
            print(string.format("|cff00ffff[WasntMe]:|r " .. messages.full, MACRO_NAME))

            return
        end

        CreateMacro(MACRO_NAME, config.icon, macroBody, true)
        print(string.format("|cff00ffff[WasntMe]:|r " .. messages.created, MACRO_NAME, spellName))
    else
        EditMacro(macroIndex, MACRO_NAME, config.icon, macroBody)
        print(string.format("|cff00ffff[WasntMe]:|r " .. messages.msg, spellName, target))
    end

    lastTank = target
    wasKnown = isSpellKnown
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

frame:SetScript("OnEvent", function()
    C_Timer.After(1.5, UpdateWasntMe)
end)
