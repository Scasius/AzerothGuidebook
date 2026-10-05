local addonName, AGB = ...

local TAB_TO_DOMAIN = {
    ["Talents"] = "talents",
    ["Rotation"] = "rotation",
    ["BiS"] = "bis",
    ["Consumables"] = "consumables",
    ["Enchants & Gems"] = "enchants",
    ["Stats"] = "stats",
}

local SOURCE_ORDER = { "wowhead", "icy-veins", "ugg" }
local SOURCE_LABELS = {
    wowhead = "Wowhead",
    ["icy-veins"] = "Icy Veins",
    ugg = "U.GG",
}


local ACTIVITY_PROFILE_DEFINITIONS = {
    { key = "raid", label = "Raid" },
    { key = "mythicplus", label = "Mythic+" },
    { key = "delves", label = "Delves" },
}

local ACTIVITY_PROFILE_TABS = {
    "Talents",
    "Rotation",
    "BiS",
    "Consumables",
    "Enchants & Gems",
    "Stats",
}

local function CopyProfileTable(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do
        out[key] = CopyProfileTable(item)
    end
    return out
end

local function ProfileTablesEqual(left, right)
    if left == right then return true end
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not ProfileTablesEqual(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function IsActivityProfileKey(profileKey)
    for _, definition in ipairs(ACTIVITY_PROFILE_DEFINITIONS) do
        if definition.key == profileKey then return true end
    end
    return false
end

local function ActivityProfileSpecKey(specID)
    return tostring(specID or 0)
end

function AGB:GetActivityProfileDefinitions()
    return ACTIVITY_PROFILE_DEFINITIONS
end

function AGB:GetActivityProfileLabel(profileKey)
    for _, definition in ipairs(ACTIVITY_PROFILE_DEFINITIONS) do
        if definition.key == profileKey then return definition.label end
    end
    return tostring(profileKey or "Profile")
end

function AGB:GetActivityProfile(specID, profileKey)
    if not AzerothGuidebookDB or not AzerothGuidebookDB.activityProfiles then return nil end
    local bySpec = AzerothGuidebookDB.activityProfiles[ActivityProfileSpecKey(specID)]
    return bySpec and bySpec[profileKey] or nil
end

function AGB:GetActiveActivityProfileKey(specID)
    if not AzerothGuidebookDB or not AzerothGuidebookDB.activeActivityProfiles then return nil end
    local key = AzerothGuidebookDB.activeActivityProfiles[ActivityProfileSpecKey(specID)]
    if key and IsActivityProfileKey(key) then return key end
    return nil
end

function AGB:CaptureActivityProfileSnapshot(specID)
    AzerothGuidebookDB = AzerothGuidebookDB or {}
    local sources = {}
    for _, tabName in ipairs(ACTIVITY_PROFILE_TABS) do
        sources[tabName] = self:GetSelectedGuideSource(specID, tabName)
    end

    local specKey = ActivityProfileSpecKey(specID)
    local talentVariants = {}
    if AzerothGuidebookDB.talentGuideVariants and AzerothGuidebookDB.talentGuideVariants[specKey] then
        talentVariants = CopyProfileTable(AzerothGuidebookDB.talentGuideVariants[specKey])
    end

    local multiSourceBuilds = {}
    local multiPrefix = specKey .. ":"
    for selectionKey, selectedIndex in pairs(AzerothGuidebookDB.multiSourceTalentBuilds or {}) do
        if string.sub(tostring(selectionKey), 1, #multiPrefix) == multiPrefix then
            multiSourceBuilds[selectionKey] = selectedIndex
        end
    end

    local icyRotationPreset = AzerothGuidebookDB.icyRotationPresets and AzerothGuidebookDB.icyRotationPresets[specID] or nil
    local icyRotation = self:GetRichIcyRotationSpec(specID)
    if icyRotation and icyRotation.presets and #icyRotation.presets > 0 then
        local validPreset = nil
        if icyRotationPreset then
            for _, preset in ipairs(icyRotation.presets) do
                if preset.key == icyRotationPreset then validPreset = icyRotationPreset break end
            end
        end
        if not validPreset then
            icyRotationPreset = icyRotation.defaultPresetKey or icyRotation.presets[1].key
        end
    end

    return {
        schema = 1,
        sources = sources,
        guideSourceContext = self:GetGuideSourceContext(specID),
        talentCategory = AzerothGuidebookDB.lastTalentBuild or "raid",
        talentGuideVariants = talentVariants,
        multiSourceTalentBuilds = multiSourceBuilds,
        bisGuideSet = AzerothGuidebookDB.bisGuideSets and AzerothGuidebookDB.bisGuideSets[specID] or nil,
        icyRotationPreset = icyRotationPreset,
        rotationContext = AzerothGuidebookDB.rotationContexts and AzerothGuidebookDB.rotationContexts[specID] or nil,
    }
end

function AGB:SaveActivityProfile(specID, profileKey)
    if not specID or not IsActivityProfileKey(profileKey) then return false end
    AzerothGuidebookDB = AzerothGuidebookDB or {}
    AzerothGuidebookDB.activityProfiles = AzerothGuidebookDB.activityProfiles or {}
    AzerothGuidebookDB.activeActivityProfiles = AzerothGuidebookDB.activeActivityProfiles or {}
    local specKey = ActivityProfileSpecKey(specID)
    AzerothGuidebookDB.activityProfiles[specKey] = AzerothGuidebookDB.activityProfiles[specKey] or {}
    AzerothGuidebookDB.activityProfiles[specKey][profileKey] = {
        schema = 1,
        savedAt = time and time() or nil,
        snapshot = self:CaptureActivityProfileSnapshot(specID),
    }
    AzerothGuidebookDB.activeActivityProfiles[specKey] = profileKey
    return true
end

function AGB:IsActivityProfileCurrent(specID, profileKey)
    local record = self:GetActivityProfile(specID, profileKey)
    if not record or type(record.snapshot) ~= "table" then return false end
    return ProfileTablesEqual(record.snapshot, self:CaptureActivityProfileSnapshot(specID))
end

function AGB:ApplyActivityProfile(specID, profileKey)
    if not specID or not IsActivityProfileKey(profileKey) then return false, { "Invalid activity profile." } end
    local record = self:GetActivityProfile(specID, profileKey)
    local snapshot = record and record.snapshot
    if type(snapshot) ~= "table" then return false, { "That activity profile has not been saved yet." } end

    AzerothGuidebookDB = AzerothGuidebookDB or {}
    local warnings = {}

    -- Apply U.GG context before source selections because U.GG domain availability
    -- is context-sensitive. This prevents a saved Mythic+ source from being
    -- rejected merely because the currently active context is Raid (or vice versa).
    if snapshot.guideSourceContext == "raid" or snapshot.guideSourceContext == "mythicplus" then
        self:SetGuideSourceContext(specID, snapshot.guideSourceContext)
    end

    for _, tabName in ipairs(ACTIVITY_PROFILE_TABS) do
        local sourceID = snapshot.sources and snapshot.sources[tabName]
        if sourceID and not self:SetSelectedGuideSource(specID, tabName, sourceID) then
            table.insert(warnings, tostring(tabName) .. ": " .. tostring(self:GetGuideSourceLabel(sourceID)) .. " is no longer available; current selection was kept.")
        end
    end

    if snapshot.talentCategory == "raid" or snapshot.talentCategory == "mythicplus" or snapshot.talentCategory == "delves" then
        AzerothGuidebookDB.lastTalentBuild = snapshot.talentCategory
    end

    AzerothGuidebookDB.talentGuideVariants = AzerothGuidebookDB.talentGuideVariants or {}
    AzerothGuidebookDB.talentGuideVariants[ActivityProfileSpecKey(specID)] = CopyProfileTable(snapshot.talentGuideVariants or {})

    AzerothGuidebookDB.multiSourceTalentBuilds = AzerothGuidebookDB.multiSourceTalentBuilds or {}
    local prefix = ActivityProfileSpecKey(specID) .. ":"
    local removeKeys = {}
    for selectionKey in pairs(AzerothGuidebookDB.multiSourceTalentBuilds) do
        if string.sub(tostring(selectionKey), 1, #prefix) == prefix then
            table.insert(removeKeys, selectionKey)
        end
    end
    for _, selectionKey in ipairs(removeKeys) do
        AzerothGuidebookDB.multiSourceTalentBuilds[selectionKey] = nil
    end
    for selectionKey, selectedIndex in pairs(snapshot.multiSourceTalentBuilds or {}) do
        AzerothGuidebookDB.multiSourceTalentBuilds[selectionKey] = selectedIndex
    end

    AzerothGuidebookDB.bisGuideSets = AzerothGuidebookDB.bisGuideSets or {}
    AzerothGuidebookDB.bisGuideSets[specID] = snapshot.bisGuideSet
    AzerothGuidebookDB.icyRotationPresets = AzerothGuidebookDB.icyRotationPresets or {}
    AzerothGuidebookDB.icyRotationPresets[specID] = snapshot.icyRotationPreset
    AzerothGuidebookDB.rotationContexts = AzerothGuidebookDB.rotationContexts or {}
    AzerothGuidebookDB.rotationContexts[specID] = snapshot.rotationContext

    AzerothGuidebookDB.activeActivityProfiles = AzerothGuidebookDB.activeActivityProfiles or {}
    AzerothGuidebookDB.activeActivityProfiles[ActivityProfileSpecKey(specID)] = profileKey

    self.multiSourceTalentPreview = nil
    self._pendingGuideFocus = nil
    if self.ClearCustomTalentPreview then self:ClearCustomTalentPreview() end
    return true, warnings
end

function AGB:GetGuideDomainForTab(tabName)
    return TAB_TO_DOMAIN[tabName]
end

function AGB:GetMultiSourceSpec(specID)
    local pack = self.MultiSourceData
    return pack and pack.specs and pack.specs[specID] or nil
end

function AGB:GetGuideSourceLabel(sourceID)
    return SOURCE_LABELS[sourceID] or tostring(sourceID or "Source")
end

function AGB:GetRichIcyRotationSpec(specID)
    local pack = self.GuideIcyRotationsData
    return pack and pack.specs and pack.specs[specID] or nil
end

function AGB:IsGuideSourceAvailable(specID, tabName, sourceID, context)
    if sourceID == "wowhead" then return true end
    local domain = TAB_TO_DOMAIN[tabName]
    if not domain then return false end
    local spec = self:GetMultiSourceSpec(specID)
    local source = spec and spec.sources and spec.sources[sourceID] or nil
    if not source then return false end
    if sourceID == "ugg" then
        context = context or self:GetGuideSourceContext(specID)
        local ctx = source.contexts and source.contexts[context] or nil
        return ctx and ctx.domains and ctx.domains[domain] ~= nil or false
    end
    return source.domains and source.domains[domain] ~= nil or false
end

function AGB:GetAvailableGuideSources(specID, tabName)
    local out = {}
    for _, sourceID in ipairs(SOURCE_ORDER) do
        local available
        if sourceID == "wowhead" then
            available = true
        else
            available = self:IsGuideSourceAvailable(specID, tabName, sourceID)
        end
        if available then
            table.insert(out, {
                id = sourceID,
                label = SOURCE_LABELS[sourceID] or sourceID,
            })
        end
    end
    return out
end

local function SelectionKey(specID, tabName)
    return tostring(specID or 0) .. ":" .. tostring(tabName or "")
end

function AGB:GetSelectedGuideSource(specID, tabName)
    local sourceID = "wowhead"
    if AzerothGuidebookDB and AzerothGuidebookDB.guideSourceSelections then
        sourceID = AzerothGuidebookDB.guideSourceSelections[SelectionKey(specID, tabName)] or "wowhead"
    end
    if not self:IsGuideSourceAvailable(specID, tabName, sourceID) then
        sourceID = "wowhead"
    end
    return sourceID
end

function AGB:SetSelectedGuideSource(specID, tabName, sourceID)
    if sourceID ~= "wowhead" and not self:IsGuideSourceAvailable(specID, tabName, sourceID) then
        return false
    end
    AzerothGuidebookDB.guideSourceSelections = AzerothGuidebookDB.guideSourceSelections or {}
    AzerothGuidebookDB.guideSourceSelections[SelectionKey(specID, tabName)] = sourceID
    return true
end

function AGB:GetGuideSourceContext(specID)
    local context = "raid"
    if AzerothGuidebookDB and AzerothGuidebookDB.guideSourceContexts then
        context = AzerothGuidebookDB.guideSourceContexts[specID] or context
    end
    if context ~= "raid" and context ~= "mythicplus" then context = "raid" end
    return context
end

function AGB:SetGuideSourceContext(specID, context)
    if context ~= "raid" and context ~= "mythicplus" then return false end
    AzerothGuidebookDB.guideSourceContexts = AzerothGuidebookDB.guideSourceContexts or {}
    AzerothGuidebookDB.guideSourceContexts[specID] = context
    return true
end

function AGB:GetMultiSourceDomain(specID, sourceID, tabName, context)
    if sourceID == "wowhead" then return nil end
    local domain = TAB_TO_DOMAIN[tabName]
    if not domain then return nil end
    local spec = self:GetMultiSourceSpec(specID)
    local source = spec and spec.sources and spec.sources[sourceID] or nil
    if not source then return nil end
    if sourceID == "ugg" then
        context = context or self:GetGuideSourceContext(specID)
        local ctx = source.contexts and source.contexts[context] or nil
        return ctx and ctx.domains and ctx.domains[domain] or nil, source, ctx
    end
    if sourceID == "icy-veins" and domain == "rotation" then
        local richRotation = self:GetRichIcyRotationSpec(specID)
        if richRotation then
            return richRotation, source, nil
        end
    end
    return source.domains and source.domains[domain] or nil, source, nil
end