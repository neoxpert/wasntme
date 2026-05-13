local _, playerClass = UnitClass("player")

if playerClass ~= "HUNTER" and playerClass ~= "ROGUE" then
    return
end

local MACRO_NAME = "WasntMe"
local lastTank = ""

local classConfigs = {
    HUNTER = { spellID = 34477, icon = "ability_hunter_misdirection", fallback = "pet" },
    ROGUE  = { spellID = 57934, icon = "ability_rogue_tricksofthetrade", fallback = "target" }
}

local dict = {
    enUS = {
        msg = "Target for %s set to: |cff00ff00%s|r",
        created = "Macro '%s' created for %s.",
        full = "|cffff0000Error:|r No character macro slots available for %s."
    },
    deDE = {
        msg = "Ziel für %s auf |cff00ff00%s|r gesetzt",
        created = "Makro '%s' für %s erstellt.",
        full = "|cffff0000Fehler:|r Keine charakter-spezifischen Makro-Slots frei für %s."
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

    local units = {"player", "party1", "party2", "party3", "party4", "raid1", "raid2"}
    local currentTank = nil

    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            currentTank = GetUnitName(unit, true)
            break
        end
    end

    local target = currentTank or config.fallback

    if target == lastTank then
        return
    end

    local macroIndex = GetMacroIndexByName(MACRO_NAME)
    local macroBody = string.format("#showtooltip %s\n/cast [@%s] %s", spellName, target, spellName)

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
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function()
    C_Timer.After(1.5, UpdateWasntMe)
end)
