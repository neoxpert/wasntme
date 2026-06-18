local _, _, classId = UnitClass("player")

if classId ~= 3 and classId ~= 4 then
    return
end

local MACRO_NAME = "WasntMe"
local LOG_PREFIX = "|cff00ffff[WasntMe]:|r "
local lastTank = ""
local wasKnown = nil

local configs = {
    [3] = { spellID = 34477, icon = "ability_hunter_misdirection", fallback = "pet" },
    [4] = { spellID = 57934, icon = "ability_rogue_tricksofthetrade", fallback = "target" }
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
local config = configs[classId]
local spellInfo = C_Spell.GetSpellInfo(config.spellID)

if not spellInfo then
    return
end

local spellName = spellInfo.name

local function FindGroupTank()
    local prefix = IsInRaid() and "raid" or "party"
    local maxMembers = IsInRaid() and GetNumGroupMembers() or 4

    for i = 1, maxMembers do
        local unit = prefix .. i
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            return GetUnitName(unit, true)
        end
    end

    return nil
end

local pendingUpdate = false;

local function UpdateWasntMe()
    pendingUpdate = false

    if InCombatLockdown() then return end

    local isSpellKnown = C_Spell.IsSpellUsable(spellName)

    local currentTank = FindGroupTank()
    local target = currentTank or config.fallback

    if target == lastTank and wasKnown == isSpellKnown then
        return
    end

    local macroIndex = GetMacroIndexByName(MACRO_NAME)
    local macroBody = ""

    if isSpellKnown then
        macroBody = string.format("#showtooltip %s\n/cast [@%s] %s", spellName, target, spellName)
    else
        local warnText = string.format(messages.warn, string.upper(spellName))
        macroBody = string.format("#showtooltip %s\n/run UIErrorsFrame:AddMessage('%s', 1, 0.1, 0.1, 1.0, 5)", spellName,
            warnText)
    end

    if macroIndex == 0 then
        local _, numCharMacros = GetNumMacros()

        if numCharMacros >= 18 then
            print(string.format(LOG_PREFIX .. messages.full, MACRO_NAME))

            return
        end

        CreateMacro(MACRO_NAME, config.icon, macroBody, true)
        print(string.format(LOG_PREFIX .. messages.created, MACRO_NAME, spellName))
    else
        EditMacro(macroIndex, MACRO_NAME, config.icon, macroBody)
        print(string.format(LOG_PREFIX .. messages.msg, spellName, target))
    end

    lastTank = target
    wasKnown = isSpellKnown
end

local frame = CreateFrame("Frame")

local events = {
    "GROUP_ROSTER_UPDATE",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_TALENT_UPDATE",
    "TRAIT_CONFIG_UPDATED"
}

for _, event in ipairs(events) do
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function()
    if pendingUpdate then return end

    pendingUpdate = true
    C_Timer.After(1.5, UpdateWasntMe)
end)
