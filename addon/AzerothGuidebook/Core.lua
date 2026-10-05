local addonName, AGB = ...

AGB.defaults = {
    minimap = true,
    minimapAngle = 45,
    lastTab = "My Character",
    lastGuideTab = "Talents",
    lastTalentBuild = "raid",
    talentGuideVariants = {},
    bisGuideSets = {},
    talentDisplayMode = "visual",
    talentTreeSection = "Class",
    talentDifferencesOnly = false,
    guideSourceSelections = {},
    guideSourceContexts = {},
    multiSourceTalentBuilds = {},
    activityProfiles = {},
    activeActivityProfiles = {},
    sourceRefreshCounter = 0,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff36c7ffAzeroth Guidebook:|r " .. tostring(msg))
end
AGB.Print = Print

function AGB:GetPlayerContext()
    local _, classFile = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization()
    local specID, specName
    if specIndex and GetSpecializationInfo then
        specID, specName = GetSpecializationInfo(specIndex)
    end
    return classFile, specID, specName
end

function AGB:GetActiveData()
    local classFile, specID = self:GetPlayerContext()
    if self.previewSpecID then
        local meta = self.SpecIndex and self.SpecIndex[self.previewSpecID]
        if meta then
            classFile, specID = meta.classFile, self.previewSpecID
        end
    end
    return self.Data[classFile] and self.Data[classFile][specID], classFile, specID
end

function AGB:SetPreviewSpec(specID)
    if specID ~= nil then
        local meta = self.SpecIndex and self.SpecIndex[specID]
        if not meta or not (self.Data[meta.classFile] and self.Data[meta.classFile][specID]) then
            Print("No bundled guide data exists for specialization ID " .. tostring(specID) .. ".")
            return false
        end
        self.previewSpecID = specID
    else
        self.previewSpecID = nil
    end

    if self.ClearCustomTalentPreview then
        self:ClearCustomTalentPreview()
    end

    if self.UI and self.UI.guideMenu then
        self.UI.guideMenu:Hide()
    elseif self.UI and self.UI.specMenu then
        self.UI.specMenu:Hide()
    end
    if self.UI then
        self:RefreshUI()
    end
    return true
end

function AGB:IsItemEquipped(itemID)
    if not itemID then return false end
    return IsEquippedItem and IsEquippedItem(itemID) or false
end

function AGB:IsItemInBags(itemID)
    if not itemID or not C_Container then return false end
    local maxBag = NUM_BAG_SLOTS or 4
    for bag = 0, maxBag do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            if C_Container.GetContainerItemID(bag, slot) == itemID then
                return true
            end
        end
    end
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        local bag = Enum.BagIndex.ReagentBag
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            if C_Container.GetContainerItemID(bag, slot) == itemID then
                return true
            end
        end
    end
    return false
end

function AGB:GetItemStatus(itemID)
    if self:IsItemEquipped(itemID) then
        return "Equipped", "|cff33ff66Equipped|r"
    elseif self:IsItemInBags(itemID) then
        return "Owned", "|cff66ccffOwned|r"
    end
    return "Missing", "|cffaaaaaaMissing|r"
end

function AGB:Toggle()
    if not self.UI then self:CreateUI() end
    if self.UI:IsShown() then
        self.UI:Hide()
    else
        self.UI:Show()
        self:RefreshUI()
    end
end

local MINIMAP_BUTTON_OUTER_OFFSET = 8

local function Atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

function AGB:PositionMinimapButton()
    if not self.MinimapButton or not Minimap then return end
    local angle = tonumber(AzerothGuidebookDB and AzerothGuidebookDB.minimapAngle) or 45
    local radians = math.rad(angle)
    local minimapWidth = tonumber(Minimap:GetWidth()) or 140
    local minimapHeight = tonumber(Minimap:GetHeight()) or minimapWidth
    local radius = (math.max(minimapWidth, minimapHeight) / 2) + MINIMAP_BUTTON_OUTER_OFFSET
    self.MinimapButton:ClearAllPoints()
    self.MinimapButton:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * radius,
        math.sin(radians) * radius
    )
end

function AGB:UpdateMinimapButtonFromCursor()
    if not self.MinimapButton or not Minimap or not AzerothGuidebookDB then return end
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then return end

    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not scale or scale == 0 then return end
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local dx, dy = cursorX - centerX, cursorY - centerY
    if dx == 0 and dy == 0 then return end

    local angle = math.deg(Atan2(dy, dx))
    AzerothGuidebookDB.minimapAngle = angle
    self:PositionMinimapButton()
end

function AGB:CreateMinimapButton()
    if self.MinimapButton then return end
    local b = CreateFrame("Button", "AzerothGuidebookMinimapButton", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:RegisterForClicks("LeftButtonUp")
    b:RegisterForDrag("LeftButton")

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\AzerothGuidebook\\Media\\AzerothGuidebookIcon_128")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    b.icon = icon

    b:SetScript("OnClick", function() AGB:Toggle() end)
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function() AGB:UpdateMinimapButtonFromCursor() end)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        AGB:UpdateMinimapButtonFromCursor()
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Azeroth Guidebook")
        GameTooltip:AddLine("Click to open the in-game guide.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the outside of the minimap.", 1, 1, 1)
        GameTooltip:AddLine("/agb", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    self.MinimapButton = b
    self:PositionMinimapButton()
end

function AGB:ApplyMinimapSetting()
    self:CreateMinimapButton()
    self:PositionMinimapButton()
    if AzerothGuidebookDB.minimap then
        self.MinimapButton:Show()
    else
        self.MinimapButton:Hide()
    end
end

local function InitializeSavedVariables()
    AzerothGuidebookDB = AzerothGuidebookDB or {}
    for k, v in pairs(AGB.defaults) do
        if AzerothGuidebookDB[k] == nil then AzerothGuidebookDB[k] = v end
    end
end

local function HandleSlashCommand(msg)
    InitializeSavedVariables()
    msg = strtrim((msg or "")):lower()
    if msg == "minimap" then
        AzerothGuidebookDB.minimap = not AzerothGuidebookDB.minimap
        AGB:ApplyMinimapSetting()
        Print("Minimap button " .. (AzerothGuidebookDB.minimap and "shown." or "hidden."))
        return
    elseif msg == "elemental" or msg == "ele" then
        AGB:SetPreviewSpec(262)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "enhancement" or msg == "enh" then
        AGB:SetPreviewSpec(263)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "restoration" or msg == "resto" then
        AGB:SetPreviewSpec(264)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "havoc" then
        AGB:SetPreviewSpec(577)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "vengeance" or msg == "veng" then
        AGB:SetPreviewSpec(581)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "devourer" or msg == "dev" then
        AGB:SetPreviewSpec(1480)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "current" or msg == "auto" then
        AGB:SetPreviewSpec(nil)
        if not AGB.UI or not AGB.UI:IsShown() then AGB:Toggle() end
        return
    elseif msg == "help" then
        Print("/agb - toggle guide | Browse Guides includes all 40 Retail specs | /agb current | /agb minimap")
        return
    end
    AGB:Toggle()
end

function AGB:RegisterSlashCommands()
    SLASH_AZEROTHGUIDEBOOK1 = "/agb"
    SLASH_AZEROTHGUIDEBOOK2 = "/azerothguidebook"
    if SlashCmdList then
        SlashCmdList.AZEROTHGUIDEBOOK = HandleSlashCommand
    end

    -- Retail keeps a hashed lookup of slash aliases. Rebuild it when available
    -- so /agb works immediately even if this addon registered after the chat
    -- command table was initially imported (for example after a late addon load).
    if ChatFrame_ImportAllListsToHash then
        pcall(ChatFrame_ImportAllListsToHash)
    end
end

-- Register immediately, then register again at addon/login initialization as a
-- defensive fallback for clients whose chat command tables finish later.
AGB:RegisterSlashCommands()

function AzerothGuidebook_OnAddonCompartmentClick(addonNameArg, buttonName)
    AGB:Toggle()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("TRAIT_CONFIG_UPDATED")
events:RegisterEvent("COMBAT_RATING_UPDATE")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitializeSavedVariables()
        AGB:RegisterSlashCommands()
        if AGB.ReconcileSourceRefreshState then AGB:ReconcileSourceRefreshState() end
        AGB:ApplyMinimapSetting()
    elseif event == "PLAYER_LOGIN" then
        InitializeSavedVariables()
        AGB:RegisterSlashCommands()
        AGB:ApplyMinimapSetting()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-register after the world/chat UI is fully established. This is a
        -- harmless no-op on normal loads and fixes late slash-table imports.
        AGB:RegisterSlashCommands()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() AGB:RegisterSlashCommands() end)
            C_Timer.After(1, function() AGB:RegisterSlashCommands() end)
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and (arg1 == "player" or arg1 == nil) then
        AGB.previewSpecID = nil
        if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
        if AGB.UI and AGB.UI:IsShown() then AGB:RefreshUI() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" or event == "COMBAT_RATING_UPDATE" then
        if AGB.UI and AGB.UI:IsShown() and AzerothGuidebookDB and AzerothGuidebookDB.lastTab == "My Character" then
            AGB:RefreshUI()
        end
    end
end)