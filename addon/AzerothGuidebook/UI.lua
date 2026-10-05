local addonName, AGB = ...

local TABS = { "My Character", "Talents", "Rotation", "BiS", "Consumables", "Enchants & Gems", "Stats", "Sources" }
local PANEL_WIDTH = 720
local PANEL_HEIGHT = 620

local function NewText(parent, size, r, g, b, justify)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetFontObject(size and size >= 16 and GameFontNormalLarge or GameFontNormal)
    fs:SetTextColor(r or 1, g or 1, b or 1)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    return fs
end

local function AddElement(content, element)
    content._elements = content._elements or {}
    table.insert(content._elements, element)
    return element
end

local function ClearContent(content)
    if content._elements then
        for _, e in ipairs(content._elements) do
            if e.Hide then e:Hide() end
            if e.SetParent and e:GetObjectType() ~= "FontString" and e:GetObjectType() ~= "Texture" then
                e:SetParent(nil)
            end
        end
    end
    content._elements = {}
end

function AGB:CreateUI()
    if self.UI then return end

    local f = CreateFrame("Frame", "AzerothGuidebookFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    f.TitleText:SetText("Azeroth Guidebook")
    self.UI = f

    local subtitle = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 16, -34)
    subtitle:SetPoint("TOPRIGHT", -16, -34)
    subtitle:SetJustifyH("LEFT")
    f.subtitle = subtitle

    local badge = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    badge:SetPoint("TOPRIGHT", -42, -12)
    badge:SetText("v" .. self.VERSION)
    badge:SetTextColor(0.6, 0.8, 1)

    local preview = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    preview:SetSize(190, 22)
    preview:SetPoint("TOPRIGHT", -20, -50)
    preview:SetText("Browse Guides")
    f.preview = preview

    local guideMenu = CreateFrame("Frame", nil, f, "BasicFrameTemplateWithInset")
    guideMenu:SetSize(220, 140)
    guideMenu:SetPoint("TOPRIGHT", preview, "BOTTOMRIGHT", 0, -4)
    guideMenu:SetFrameStrata("FULLSCREEN_DIALOG")
    guideMenu:SetClampedToScreen(true)
    guideMenu:Hide()
    guideMenu.TitleText:SetText("Guide Browser")
    guideMenu.buttons = {}
    f.guideMenu = guideMenu
    -- Compatibility alias for v1.5-era callers.
    f.specMenu = guideMenu

    local function GetGuideMenuButton(index)
        local button = guideMenu.buttons[index]
        if not button then
            button = CreateFrame("Button", nil, guideMenu, "UIPanelButtonTemplate")
            button:SetSize(180, 22)
            guideMenu.buttons[index] = button
        end
        return button
    end

    local function ConfigureGuideMenu(title, choices)
        guideMenu.TitleText:SetText(title or "Guide Browser")
        local count = #choices
        guideMenu:SetHeight(math.max(90, 54 + count * 27))

        for i, choice in ipairs(choices) do
            local button = GetGuideMenuButton(i)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", 20, -34 - ((i - 1) * 27))
            button:SetText(choice.label)
            button:SetScript("OnClick", choice.onClick)
            button:Show()
        end
        for i = count + 1, #guideMenu.buttons do
            guideMenu.buttons[i]:Hide()
        end
    end

    local ShowClassMenu
    local ShowSpecMenu

    ShowSpecMenu = function(classInfo)
        local choices = {
            {
                label = "< Back to Classes",
                onClick = function()
                    ShowClassMenu()
                end,
            },
        }
        for _, specInfo in ipairs(classInfo.specs or {}) do
            local selectedSpecID = specInfo.id
            local selectedLabel = specInfo.name
            table.insert(choices, {
                label = selectedLabel,
                onClick = function()
                    AGB:SetPreviewSpec(selectedSpecID)
                end,
            })
        end
        ConfigureGuideMenu(classInfo.name .. " Guides", choices)
    end

    ShowClassMenu = function()
        local choices = {
            {
                label = "Use Current Spec",
                onClick = function()
                    AGB:SetPreviewSpec(nil)
                end,
            },
        }
        for _, classInfo in ipairs(AGB.GuideClasses or {}) do
            local selectedClass = classInfo
            table.insert(choices, {
                label = selectedClass.name .. " >",
                onClick = function()
                    ShowSpecMenu(selectedClass)
                end,
            })
        end
        ConfigureGuideMenu("Guide Browser", choices)
    end

    f.ShowGuideClassMenu = ShowClassMenu
    f.ShowGuideSpecMenu = ShowSpecMenu

    preview:SetScript("OnClick", function()
        if guideMenu:IsShown() then
            guideMenu:Hide()
        else
            ShowClassMenu()
            guideMenu:Show()
        end
    end)
    f:HookScript("OnHide", function() guideMenu:Hide() end)

    f.tabs = {}
    local x = 14
    for _, name in ipairs(TABS) do
        local tab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        local tabWidths = {
            ["My Character"] = 96,
            ["Talents"] = 70,
            ["Rotation"] = 72,
            ["BiS"] = 52,
            ["Consumables"] = 92,
            ["Enchants & Gems"] = 106,
            ["Stats"] = 58,
            ["Sources"] = 64,
        }
        local width = tabWidths[name] or 76
        tab:SetSize(width, 24)
        tab:SetPoint("TOPLEFT", x, -79)
        tab:SetText(name)
        tab.tabName = name
        tab:SetScript("OnClick", function(self)
            AzerothGuidebookDB.lastTab = self.tabName
            if self.tabName ~= "My Character" and self.tabName ~= "Sources" then
                AzerothGuidebookDB.lastGuideTab = self.tabName
            end
            if self.tabName == "My Character" then
                AGB.previewSpecID = nil
                AGB:RefreshUI()
            else
                AGB:RenderTab(self.tabName)
            end
        end)
        f.tabs[name] = tab
        x = x + width + 4
    end

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -112)
    scroll:SetPoint("BOTTOMRIGHT", -36, 20)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(PANEL_WIDTH - 70, 1)
    scroll:SetScrollChild(content)
    f.scroll = scroll
    f.content = content

    local copy = CreateFrame("Frame", nil, f, "BasicFrameTemplateWithInset")
    copy:SetSize(600, 135)
    copy:SetPoint("CENTER")
    copy:SetFrameStrata("FULLSCREEN_DIALOG")
    copy:Hide()
    copy.TitleText:SetText("Copy")

    local copyHelp = copy:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHelp:SetPoint("TOPLEFT", 16, -36)
    copyHelp:SetText("Press Ctrl+C to copy, then Escape or Close.")

    local edit = CreateFrame("EditBox", nil, copy, "InputBoxTemplate")
    edit:SetAutoFocus(false)
    edit:SetSize(555, 28)
    edit:SetPoint("TOPLEFT", 18, -62)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); copy:Hide() end)
    edit:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    copy.edit = edit

    local close = CreateFrame("Button", nil, copy, "UIPanelButtonTemplate")
    close:SetSize(90, 24)
    close:SetPoint("BOTTOMRIGHT", -16, 12)
    close:SetText("Close")
    close:SetScript("OnClick", function() copy:Hide() end)
    f.copyPopup = copy

    local talentInput = CreateFrame("Frame", nil, f, "BasicFrameTemplateWithInset")
    talentInput:SetSize(650, 190)
    talentInput:SetPoint("CENTER")
    talentInput:SetFrameStrata("FULLSCREEN_DIALOG")
    talentInput:Hide()
    talentInput.TitleText:SetText("Preview Talent Import String")

    local talentHelp = talentInput:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    talentHelp:SetPoint("TOPLEFT", 16, -36)
    talentHelp:SetPoint("TOPRIGHT", -16, -36)
    talentHelp:SetJustifyH("LEFT")
    talentHelp:SetText("Paste a compatible Retail talent import string below, then click Preview. The string is decoded locally by WoW.")

    local talentEdit = CreateFrame("EditBox", nil, talentInput, "InputBoxTemplate")
    talentEdit:SetAutoFocus(false)
    talentEdit:SetSize(600, 28)
    talentEdit:SetPoint("TOPLEFT", 18, -68)
    talentEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); talentInput:Hide() end)
    talentEdit:SetScript("OnEnterPressed", function(self)
        local ok, err = AGB:SetCustomTalentPreview(self:GetText())
        if ok then
            AGB.multiSourceTalentPreview = nil
            talentInput.errorText:SetText("")
            self:ClearFocus()
            talentInput:Hide()
            AGB:RenderTab("Talents")
        else
            talentInput.errorText:SetText(err or "Unable to preview this build.")
        end
    end)
    talentInput.edit = talentEdit

    local talentError = talentInput:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    talentError:SetPoint("TOPLEFT", 18, -103)
    talentError:SetPoint("TOPRIGHT", -18, -103)
    talentError:SetJustifyH("LEFT")
    talentError:SetTextColor(1, 0.35, 0.25)
    talentInput.errorText = talentError

    local previewButton = CreateFrame("Button", nil, talentInput, "UIPanelButtonTemplate")
    previewButton:SetSize(100, 24)
    previewButton:SetPoint("BOTTOMLEFT", 18, 14)
    previewButton:SetText("Preview")
    previewButton:SetScript("OnClick", function()
        local ok, err = AGB:SetCustomTalentPreview(talentEdit:GetText())
        if ok then
            AGB.multiSourceTalentPreview = nil
            talentError:SetText("")
            talentEdit:ClearFocus()
            talentInput:Hide()
            AGB:RenderTab("Talents")
        else
            talentError:SetText(err or "Unable to preview this build.")
        end
    end)

    local cancelTalent = CreateFrame("Button", nil, talentInput, "UIPanelButtonTemplate")
    cancelTalent:SetSize(90, 24)
    cancelTalent:SetPoint("BOTTOMRIGHT", -16, 14)
    cancelTalent:SetText("Cancel")
    cancelTalent:SetScript("OnClick", function() talentInput:Hide() end)
    f.talentInputPopup = talentInput

    local importTarget = CreateFrame("Frame", nil, f, "BasicFrameTemplateWithInset")
    importTarget:SetSize(520, 205)
    importTarget:SetPoint("CENTER")
    importTarget:SetFrameStrata("FULLSCREEN_DIALOG")
    importTarget:Hide()
    importTarget.TitleText:SetText("Import Target as Talent Loadout")

    local importHelp = importTarget:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    importHelp:SetPoint("TOPLEFT", 16, -36)
    importHelp:SetPoint("TOPRIGHT", -16, -36)
    importHelp:SetJustifyH("LEFT")
    importHelp:SetText("Creates a new Blizzard talent loadout from the reviewed target. Source choices are preserved; only starter ranks WoW explicitly marks as Granted may be restored. The target must match your active specialization.")

    local importLabel = importTarget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    importLabel:SetPoint("TOPLEFT", 18, -82)
    importLabel:SetText("Loadout name")

    local importEdit = CreateFrame("EditBox", nil, importTarget, "InputBoxTemplate")
    importEdit:SetAutoFocus(false)
    importEdit:SetSize(470, 28)
    importEdit:SetPoint("TOPLEFT", 18, -100)
    importEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); importTarget:Hide() end)
    importTarget.edit = importEdit

    local importError = importTarget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    importError:SetPoint("TOPLEFT", 18, -136)
    importError:SetPoint("TOPRIGHT", -18, -136)
    importError:SetJustifyH("LEFT")
    importError:SetTextColor(1, 0.35, 0.25)
    importTarget.errorText = importError

    local function SubmitTargetImport()
        local target = AGB.pendingTargetImport
        local name = strtrim(importEdit:GetText() or "")
        local ok, err = AGB:ImportTargetTalentBuild(target, name)
        if ok then
            importError:SetText("")
            importEdit:ClearFocus()
            importTarget:Hide()
            AGB.pendingTargetImport = nil
            AGB.Print("WoW accepted the target build as the talent loadout '" .. name .. "'.")
        else
            importError:SetText(err or "Unable to import this target build.")
        end
    end

    importEdit:SetScript("OnEnterPressed", SubmitTargetImport)

    local importButton = CreateFrame("Button", nil, importTarget, "UIPanelButtonTemplate")
    importButton:SetSize(110, 24)
    importButton:SetPoint("BOTTOMLEFT", 18, 14)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", SubmitTargetImport)

    local cancelImport = CreateFrame("Button", nil, importTarget, "UIPanelButtonTemplate")
    cancelImport:SetSize(90, 24)
    cancelImport:SetPoint("BOTTOMRIGHT", -16, 14)
    cancelImport:SetText("Cancel")
    cancelImport:SetScript("OnClick", function()
        importEdit:ClearFocus()
        importTarget:Hide()
        AGB.pendingTargetImport = nil
    end)
    f.targetImportPopup = importTarget
end

function AGB:ShowCopyText(text)
    if not self.UI then self:CreateUI() end
    self.UI.copyPopup:Show()
    self.UI.copyPopup.edit:SetText(text or "")
    self.UI.copyPopup.edit:SetFocus()
    self.UI.copyPopup.edit:HighlightText()
end

function AGB:ShowTalentInput()
    if not self.UI then self:CreateUI() end
    local popup = self.UI.talentInputPopup
    popup.errorText:SetText("")
    popup.edit:SetText("")
    popup:Show()
    popup.edit:SetFocus()
end

function AGB:ShowTargetImportPopup(targetDecoded)
    if not self.UI then self:CreateUI() end
    if not targetDecoded then
        self.Print("Paste a target build before importing a loadout.")
        return
    end

    self.pendingTargetImport = targetDecoded
    local popup = self.UI.targetImportPopup
    local _, _, specName = self:GetPlayerContext()
    popup.errorText:SetText("")
    popup.edit:SetText("AGB " .. tostring(specName or "Talent") .. " Target")
    popup:Show()
    popup.edit:SetFocus()
    popup.edit:HighlightText()
end

local function AddHeading(content, y, text)
    local fs = AddElement(content, NewText(content, 18, 1, 0.82, 0.25))
    fs:SetPoint("TOPLEFT", 4, -y)
    fs:SetText(text)
    return y + 28
end

local function AddParagraph(content, y, text, width, color)
    local fs = AddElement(content, NewText(content, 12, unpack(color or {0.9, 0.9, 0.9})))
    fs:SetPoint("TOPLEFT", 4, -y)
    fs:SetWidth(width or 610)
    fs:SetSpacing(3)
    fs:SetText(text)
    local h = math.max(20, fs:GetStringHeight() + 6)
    return y + h
end

local function AddDivider(content, y)
    local line = AddElement(content, content:CreateTexture(nil, "ARTWORK"))
    line:SetColorTexture(1, 1, 1, 0.08)
    line:SetPoint("TOPLEFT", 4, -y)
    line:SetSize(610, 1)
    return y + 12
end

local function AddCopyButton(content, y, label, text)
    local b = AddElement(content, CreateFrame("Button", nil, content, "UIPanelButtonTemplate"))
    b:SetSize(145, 24)
    b:SetPoint("TOPLEFT", 4, -y)
    b:SetText(label)
    b:SetScript("OnClick", function() AGB:ShowCopyText(text) end)
    return y + 34
end

local function AddActionButton(content, x, y, width, label, onClick, enabled)
    local b = AddElement(content, CreateFrame("Button", nil, content, "UIPanelButtonTemplate"))
    b:SetSize(width or 145, 24)
    b:SetPoint("TOPLEFT", x or 4, -y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    if enabled == false then b:Disable() end
    return b
end

local function AddIssueActionRow(content, y, textValue, buttonLabel, onClick, color)
    local row = AddElement(content, CreateFrame("Frame", nil, content))
    row:SetPoint("TOPLEFT", 4, -y)
    row:SetWidth(610)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, (math.floor(y / 38) % 2 == 0) and 0.035 or 0.06)

    local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 8, -7)
    text:SetWidth(430)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText(tostring(textValue or ""))
    if color then text:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1) end

    local height = math.max(34, math.ceil((text:GetStringHeight() or 18) + 14))
    row:SetHeight(height)

    local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetSize(150, 24)
    button:SetPoint("RIGHT", -8, 0)
    button:SetText(buttonLabel or "View in Guide")
    button:SetScript("OnClick", onClick)

    return y + height + 4
end

local function CompactGuideVariantLabel(label, variant)
    local compact = tostring(label or "")
    -- The source name remains available in the tooltip. Remove verbose recommendation
    -- parentheticals from the button itself so long multi-variant rows remain readable.
    compact = string.gsub(compact, "%s*%([Bb][Ee][Ss][Tt][^%)]*%)", "")
    compact = string.gsub(compact, "%s*%([Rr][Ee][Cc][Oo][Mm][Mm][Ee][Nn][Dd][Ee][Dd]%)", "")
    compact = string.gsub(compact, "%s*%[[Bb][Ee][Ss][Tt]%]", "")
    compact = string.gsub(compact, "%s*%[[Rr][Ee][Cc][Oo][Mm][Mm][Ee][Nn][Dd][Ee][Dd]%]", "")
    compact = string.gsub(compact, "%s+$", "")

    if variant and variant.recommended == true then
        local sourceText = string.lower(tostring(variant.name or "") .. " " .. tostring(variant.shortName or ""))
        if string.find(sourceText, "recommended", 1, true) then
            compact = compact .. " [Recommended]"
        else
            compact = compact .. " [Best]"
        end
    end
    return compact
end

local function FriendlyGuideBuildStatusMessage(message)
    local raw = tostring(message or "")
    local lower = string.lower(raw)
    if string.find(lower, "same blizzard export was attributed to multiple hero trees", 1, true) then
        return "Automated capture found a conflicting cross-Hero result, so this source row remains Pending."
    end
    if string.find(lower, "repeated source row yielded", 1, true) then
        return "Automated capture found conflicting Blizzard exports for this source row, so it remains Pending."
    end
    if string.find(lower, "candidate decodes as spec", 1, true) then
        return "Automated capture did not expose a valid Blizzard import string for this source row, so it remains Pending."
    end
    raw = string.gsub(raw, "^Automated Wowhead capture pending:%s*", "")
    return raw
end

local function FindTalentBuild(talents, key)
    if not talents or not talents.builds then return nil end
    for _, build in ipairs(talents.builds) do
        if build.key == key then return build end
    end
    return talents.builds[1]
end

local function AddTalentCard(content, x, y, width, talent)
    local card = AddElement(content, CreateFrame("Button", nil, content))
    card:SetSize(width, 48)
    card:SetPoint("TOPLEFT", x, -y)

    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.055)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexture(talent.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    local name = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -2)
    name:SetPoint("RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    name:SetJustifyV("TOP")
    name:SetText(talent.name or "Unknown talent")

    local rank = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rank:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 2)
    rank:SetTextColor(0.55, 0.82, 1)
    if talent.maxRank and talent.maxRank > 1 then
        rank:SetText("Rank " .. tostring(talent.rank or 1) .. "/" .. tostring(talent.maxRank))
    elseif talent.subTreeName and talent.subTreeName ~= "" then
        rank:SetText(talent.subTreeName)
    else
        rank:SetText("Selected")
    end

    card:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if talent.spellID then
            if GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(talent.spellID)
            else
                GameTooltip:SetHyperlink("spell:" .. talent.spellID)
            end
        else
            GameTooltip:AddLine(talent.name or "Talent")
            GameTooltip:AddLine("Selected talent node", 0.75, 0.75, 0.75)
        end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end

local function AddTalentListPreview(content, y, decoded)
    local talents = decoded.talents or {}
    if #talents == 0 then
        y = AddParagraph(content, y, "The build decoded successfully, but the client did not return any selected talent definitions for display.", 610, {1, 0.55, 0.35})
        return y
    end

    local grouped = {
        Class = {},
        Spec = {},
        Hero = {},
        ["Class / Spec"] = {},
    }
    for _, talent in ipairs(talents) do
        local section = talent.section or "Class / Spec"
        grouped[section] = grouped[section] or {}
        table.insert(grouped[section], talent)
    end

    local function AddGroup(groupName, groupTalents)
        if not groupTalents or #groupTalents == 0 then return end

        local groupTitle = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
        groupTitle:SetPoint("TOPLEFT", 4, -y)
        groupTitle:SetText(groupName .. " Talents  (" .. tostring(#groupTalents) .. ")")
        y = y + 24

        local columns = 3
        local gap = 7
        local width = math.floor((610 - (gap * (columns - 1))) / columns)
        local rowHeight = 54
        for index, talent in ipairs(groupTalents) do
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            AddTalentCard(content, 4 + col * (width + gap), y + row * rowHeight, width, talent)
        end

        local rows = math.ceil(#groupTalents / columns)
        y = y + rows * rowHeight + 8
    end

    AddGroup("Class", grouped.Class)
    AddGroup("Specialization", grouped.Spec)

    local heroGroupName = "Hero"
    if grouped.Hero and grouped.Hero[1] and grouped.Hero[1].subTreeName and grouped.Hero[1].subTreeName ~= "" then
        heroGroupName = "Hero - " .. grouped.Hero[1].subTreeName
    end
    AddGroup(heroGroupName, grouped.Hero)
    AddGroup("Class / Spec", grouped["Class / Spec"])

    local sourceLabel = decoded.liveCharacter and "current build" or "imported build"
    y = AddParagraph(content, y, tostring(#talents) .. " selected talent nodes shown from the " .. sourceLabel .. ".", 610, {0.65, 0.8, 1})
    return y
end

local function GetTalentTreeSectionNodes(decoded, section)
    local nodes = {}
    for _, node in ipairs(decoded.treeNodes or {}) do
        if node.section == section then
            table.insert(nodes, node)
        end
    end
    return nodes
end

local function GetHeroTreeName(decoded)
    for _, node in ipairs(decoded.treeNodes or {}) do
        if node.section == "Hero" and node.subTreeName and node.subTreeName ~= "" then
            return node.subTreeName
        end
    end
    return "Hero"
end

local function GetVisualNodePosition(decoded, node, section)
    local x = (node.posX or 0) / 10
    local y = (node.posY or 0) / 10

    -- Blizzard normalizes Hero Talent positions around the active SubTree's top-center
    -- before drawing them. Doing the same here keeps Hero layouts compact and centered.
    if section == "Hero" and node.subTreeID and decoded.subTrees then
        local info = decoded.subTrees[node.subTreeID]
        if info then
            if info.posX then x = ((node.posX or 0) - info.posX) / 10 end
            if info.posY then y = ((node.posY or 0) - info.posY) / 10 end
        end
    end

    return x, y
end

local function CountSelectedNodes(nodes)
    local count = 0
    for _, node in ipairs(nodes or {}) do
        if node.selected then count = count + 1 end
    end
    return count
end

local function AddTalentTreeCanvas(content, y, decoded, section)
    local nodes = GetTalentTreeSectionNodes(decoded, section)
    if #nodes == 0 then
        return AddParagraph(content, y, "No visible " .. (section == "Spec" and "specialization" or string.lower(section)) .. " talent nodes were returned for this build.", 610, {1, 0.55, 0.35})
    end

    local CANVAS_WIDTH = 610
    local PADDING_X = 18
    local PADDING_Y = section == "Hero" and 24 or 22
    local NODE_SIZE = section == "Hero" and 44 or 40
    local MAX_SCALE = section == "Hero" and 1.80 or (section == "Spec" and 1.25 or 1.18)

    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local rawPositions = {}

    for _, node in ipairs(nodes) do
        local x, py = GetVisualNodePosition(decoded, node, section)
        rawPositions[node.nodeID] = {x = x, y = py}
        minX = math.min(minX, x)
        maxX = math.max(maxX, x)
        minY = math.min(minY, py)
        maxY = math.max(maxY, py)
    end

    local rawWidth = math.max(1, maxX - minX)
    local rawHeight = math.max(1, maxY - minY)
    local availableWidth = CANVAS_WIDTH - (PADDING_X * 2) - NODE_SIZE
    local scale = math.min(MAX_SCALE, availableWidth / rawWidth)

    local renderedWidth = (rawWidth * scale) + NODE_SIZE
    local renderedHeight = (rawHeight * scale) + NODE_SIZE
    local minimumHeight = section == "Hero" and 340 or 360
    local canvasHeight = math.max(minimumHeight, math.ceil(renderedHeight + (PADDING_Y * 2)))
    local leftOffset = math.max(PADDING_X, (CANVAS_WIDTH - renderedWidth) / 2)
    local topOffset = math.max(PADDING_Y, (canvasHeight - renderedHeight) / 2)

    local canvas = AddElement(content, CreateFrame("Frame", nil, content))
    canvas:SetSize(CANVAS_WIDTH, canvasHeight)
    canvas:SetPoint("TOPLEFT", 4, -y)

    local bg = canvas:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.20)

    local topShade = canvas:CreateTexture(nil, "BORDER")
    topShade:SetPoint("TOPLEFT", 1, -1)
    topShade:SetPoint("TOPRIGHT", -1, -1)
    topShade:SetHeight(24)
    topShade:SetColorTexture(0.15, 0.15, 0.15, 0.13)

    local nodeButtons = {}
    local nodeByID = {}
    for _, node in ipairs(nodes) do
        nodeByID[node.nodeID] = node
    end

    for _, node in ipairs(nodes) do
        local raw = rawPositions[node.nodeID]
        local x = leftOffset + (NODE_SIZE / 2) + ((raw.x - minX) * scale)
        local py = topOffset + (NODE_SIZE / 2) + ((raw.y - minY) * scale)

        local button = CreateFrame("Button", nil, canvas)
        button:SetSize(NODE_SIZE, NODE_SIZE)
        button:SetPoint("CENTER", canvas, "TOPLEFT", x, -py)
        button.nodeData = node
        nodeButtons[node.nodeID] = button

        local border = button:CreateTexture(nil, "BACKGROUND", nil, 1)
        border:SetAllPoints()
        if node.selected then
            border:SetColorTexture(1, 0.72, 0.16, 1)
        elseif node.isChoice then
            border:SetColorTexture(0.25, 0.65, 0.9, 0.72)
        else
            border:SetColorTexture(0.34, 0.34, 0.34, 0.75)
        end

        local inner = button:CreateTexture(nil, "BACKGROUND", nil, 2)
        inner:SetPoint("TOPLEFT", 2, -2)
        inner:SetPoint("BOTTOMRIGHT", -2, 2)
        inner:SetColorTexture(0.025, 0.025, 0.025, 0.96)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexture(node.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon:SetAlpha(node.selected and 1 or 0.42)
        if icon.SetDesaturated then
            icon:SetDesaturated(not node.selected)
        end

        if node.selected and node.maxRank and node.maxRank > 1 then
            local rankBG = button:CreateTexture(nil, "OVERLAY")
            rankBG:SetSize(22, 14)
            rankBG:SetPoint("BOTTOMRIGHT", 3, -3)
            rankBG:SetColorTexture(0, 0, 0, 0.9)

            local rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rankText:SetPoint("CENTER", rankBG, "CENTER", 0, 0)
            rankText:SetText(tostring(node.rank or 0) .. "/" .. tostring(node.maxRank))
            rankText:SetTextColor(1, 0.85, 0.25)
        end

        if node.isChoice then
            local badge = button:CreateTexture(nil, "OVERLAY")
            badge:SetSize(13, 13)
            badge:SetPoint("TOPRIGHT", 4, 4)
            badge:SetColorTexture(0.08, 0.32, 0.45, 0.96)

            local choice = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            choice:SetPoint("CENTER", badge, "CENTER", 0, 0)
            choice:SetText("C")
            choice:SetTextColor(0.55, 0.95, 1)
        end

        button:SetScript("OnEnter", function(self)
            local talent = self.nodeData
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if talent.spellID then
                if GameTooltip.SetSpellByID then
                    GameTooltip:SetSpellByID(talent.spellID)
                else
                    GameTooltip:SetHyperlink("spell:" .. talent.spellID)
                end
            else
                GameTooltip:AddLine(talent.name or "Talent")
            end

            if talent.isChoice then
                GameTooltip:AddLine("Choice node", 0.45, 0.9, 1)
            end
            if talent.maxRank and talent.maxRank > 1 then
                GameTooltip:AddLine("Build rank: " .. tostring(talent.rank or 0) .. "/" .. tostring(talent.maxRank), 1, 0.82, 0.3)
            elseif talent.selected then
                GameTooltip:AddLine("Selected in this build", 0.35, 1, 0.55)
            else
                GameTooltip:AddLine("Not selected in this build", 0.65, 0.65, 0.65)
            end
            if talent.subTreeName and talent.subTreeName ~= "" then
                GameTooltip:AddLine(talent.subTreeName, 0.7, 0.6, 1)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
    end

    -- Draw WoW's own visible trait edges behind the nodes. Selected paths are
    -- deliberately heavier than v1.2.0 so they remain readable at a glance.
    for _, node in ipairs(nodes) do
        local startButton = nodeButtons[node.nodeID]
        if startButton then
            for _, edge in ipairs(node.edges or {}) do
                local targetButton = nodeButtons[edge.targetNode]
                local targetNode = nodeByID[edge.targetNode]
                if targetButton and targetNode then
                    local line = canvas:CreateLine(nil, "BACKGROUND", nil, 0)
                    line:SetStartPoint("CENTER", startButton, 0, 0)
                    line:SetEndPoint("CENTER", targetButton, 0, 0)
                    if node.selected and targetNode.selected then
                        line:SetColorTexture(1, 0.72, 0.16, 0.90)
                        line:SetThickness(3.4)
                    else
                        line:SetColorTexture(0.42, 0.42, 0.42, 0.38)
                        line:SetThickness(1.25)
                    end
                end
            end
        end
    end

    local selectedCount = CountSelectedNodes(nodes)
    y = y + canvasHeight + 8
    local selectedSource = decoded.liveCharacter and "current build" or "imported build"
    y = AddParagraph(content, y, "Selected " .. tostring(selectedCount) .. "/" .. tostring(#nodes) .. " nodes. Gold = " .. selectedSource .. "; gray = other live-tree options; C = choice node.", 610, {0.65, 0.8, 1})
    return y
end


local function GetComparisonRecordMap(comparison)
    if comparison._recordMap then return comparison._recordMap end
    local map = {}
    for _, record in ipairs(comparison.nodes or {}) do
        map[record.nodeID] = record
    end
    comparison._recordMap = map
    return map
end

local function GetComparisonSectionRecords(comparison, section)
    local records = {}
    for _, record in ipairs(comparison.nodes or {}) do
        if record.section == section then
            table.insert(records, record)
        end
    end
    return records
end

local function GetComparisonSectionDifferenceCount(comparison, section)
    local info = comparison.sections and comparison.sections[section]
    return info and info.totalDifferences or 0
end

local function FormatComparisonSelection(node)
    if not node or not node.selected then return "not selected" end
    local text = node.name or "Selected talent"
    if node.maxRank and node.maxRank > 1 then
        text = text .. " (" .. tostring(node.rank or 0) .. "/" .. tostring(node.maxRank) .. ")"
    end
    return text
end

local function GetComparisonStatusLabel(state)
    if state == "match" then return "Matches" end
    if state == "targetOnly" then return "Target only" end
    if state == "currentOnly" then return "My Build only" end
    if state == "rankDiff" then return "Rank differs" end
    if state == "choiceDiff" then return "Choice differs" end
    return "Not selected"
end

local function GetComparisonBorderColor(state, isChoice)
    if state == "match" then return 1, 0.72, 0.16, 1 end
    if state == "targetOnly" then return 1, 0.25, 0.20, 1 end
    if state == "currentOnly" then return 0.20, 0.62, 1, 1 end
    if state == "rankDiff" or state == "choiceDiff" then return 0.72, 0.35, 1, 1 end
    if isChoice then return 0.25, 0.65, 0.9, 0.72 end
    return 0.34, 0.34, 0.34, 0.75
end

local function AddTalentComparisonDifferenceList(content, y, comparison, section)
    local differences = {}
    for _, record in ipairs(GetComparisonSectionRecords(comparison, section)) do
        if record.state ~= "match" and record.state ~= "none" then
            table.insert(differences, record)
        end
    end

    local heading = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
    heading:SetPoint("TOPLEFT", 4, -y)
    heading:SetText("Differences in this tree")
    y = y + 23

    if #differences == 0 then
        return AddParagraph(content, y, "This tree matches the target build exactly.", 610, {0.35, 1, 0.55})
    end

    for _, record in ipairs(differences) do
        local line
        if record.state == "targetOnly" then
            line = "Target selects " .. FormatComparisonSelection(record.target) .. "; your current build does not."
        elseif record.state == "currentOnly" then
            line = "Your current build selects " .. FormatComparisonSelection(record.current) .. "; the target does not."
        elseif record.state == "rankDiff" then
            line = "Rank differs: target = " .. FormatComparisonSelection(record.target) .. "; my build = " .. FormatComparisonSelection(record.current) .. "."
        elseif record.state == "choiceDiff" then
            line = "Choice differs: target = " .. FormatComparisonSelection(record.target) .. "; my build = " .. FormatComparisonSelection(record.current) .. "."
        end
        if line then
            y = AddParagraph(content, y, "- " .. line, 610, {0.9, 0.9, 0.9})
        end
    end
    return y
end

local function AddTalentComparisonCanvas(content, y, comparison, section)
    local targetDecoded = comparison.target
    local currentDecoded = comparison.current
    local targetNodes = GetTalentTreeSectionNodes(targetDecoded, section)
    local currentNodes = GetTalentTreeSectionNodes(currentDecoded, section)
    local useTargetHeroOnly = section == "Hero"
        and comparison.targetHeroName
        and comparison.currentHeroName
        and comparison.targetHeroName ~= comparison.currentHeroName
    local differencesOnly = AzerothGuidebookDB and AzerothGuidebookDB.talentDifferencesOnly == true
    local recordMap = GetComparisonRecordMap(comparison)

    local function ShouldInclude(nodeID)
        if not differencesOnly then return true end
        local record = recordMap[nodeID]
        return record and record.state ~= "match" and record.state ~= "none"
    end

    local nodes = {}
    local seen = {}
    for _, node in ipairs(targetNodes) do
        if ShouldInclude(node.nodeID) then
            seen[node.nodeID] = true
            table.insert(nodes, node)
        end
    end
    if not useTargetHeroOnly then
        for _, node in ipairs(currentNodes) do
            if not seen[node.nodeID] and ShouldInclude(node.nodeID) then
                seen[node.nodeID] = true
                table.insert(nodes, node)
            end
        end
    end

    if #nodes == 0 then
        if differencesOnly then
            return AddParagraph(content, y, "No differences in this tree. Switch to another tree or choose Show All Nodes.", 610, {0.35, 1, 0.55})
        end
        return AddParagraph(content, y, "No visible talent nodes were returned for this comparison.", 610, {1, 0.55, 0.35})
    end

    local CANVAS_WIDTH = 610
    local PADDING_X = 18
    local PADDING_Y = section == "Hero" and 24 or 22
    local NODE_SIZE = section == "Hero" and 44 or 40
    local MAX_SCALE = section == "Hero" and 1.80 or (section == "Spec" and 1.25 or 1.18)

    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local rawPositions = {}
    local sourceByNode = {}
    local targetMap = {}
    for _, node in ipairs(targetNodes) do targetMap[node.nodeID] = true end

    for _, node in ipairs(nodes) do
        local positionSource = targetMap[node.nodeID] and targetDecoded or currentDecoded
        sourceByNode[node.nodeID] = positionSource
        local x, py = GetVisualNodePosition(positionSource, node, section)
        rawPositions[node.nodeID] = {x = x, y = py}
        minX = math.min(minX, x)
        maxX = math.max(maxX, x)
        minY = math.min(minY, py)
        maxY = math.max(maxY, py)
    end

    local rawWidth = math.max(1, maxX - minX)
    local rawHeight = math.max(1, maxY - minY)
    local availableWidth = CANVAS_WIDTH - (PADDING_X * 2) - NODE_SIZE
    local scale = math.min(MAX_SCALE, availableWidth / rawWidth)
    local renderedWidth = (rawWidth * scale) + NODE_SIZE
    local renderedHeight = (rawHeight * scale) + NODE_SIZE
    local minimumHeight = differencesOnly and (section == "Hero" and 260 or 280) or (section == "Hero" and 340 or 360)
    local canvasHeight = math.max(minimumHeight, math.ceil(renderedHeight + (PADDING_Y * 2)))
    local leftOffset = math.max(PADDING_X, (CANVAS_WIDTH - renderedWidth) / 2)
    local topOffset = math.max(PADDING_Y, (canvasHeight - renderedHeight) / 2)
    local canvasStartY = y

    local canvas = AddElement(content, CreateFrame("Frame", nil, content))
    canvas:SetSize(CANVAS_WIDTH, canvasHeight)
    canvas:SetPoint("TOPLEFT", 4, -y)

    local bg = canvas:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.20)

    local nodeButtons = {}
    local nodeByID = {}
    for _, node in ipairs(nodes) do nodeByID[node.nodeID] = node end

    local focusNodeID = AGB.talentDifferenceFocusNodeID
    local focusSection = AGB.talentDifferenceFocusSection

    for _, node in ipairs(nodes) do
        local raw = rawPositions[node.nodeID]
        local x = leftOffset + (NODE_SIZE / 2) + ((raw.x - minX) * scale)
        local py = topOffset + (NODE_SIZE / 2) + ((raw.y - minY) * scale)
        local record = recordMap[node.nodeID] or {state = "none", target = nil, current = nil}
        local displayNode = (record.target and record.target.selected and record.target) or (record.current and record.current.selected and record.current) or record.target or record.current or node

        local button = CreateFrame("Button", nil, canvas)
        button:SetSize(NODE_SIZE, NODE_SIZE)
        button:SetPoint("CENTER", canvas, "TOPLEFT", x, -py)
        button.compareRecord = record
        button.displayNode = displayNode
        nodeButtons[node.nodeID] = button

        if focusNodeID == node.nodeID and focusSection == section then
            local focus = button:CreateTexture(nil, "BACKGROUND", nil, 0)
            focus:SetPoint("TOPLEFT", -5, 5)
            focus:SetPoint("BOTTOMRIGHT", 5, -5)
            focus:SetColorTexture(1, 1, 0.82, 0.95)
            AGB._comparisonFocusScrollY = math.max(0, canvasStartY + py - 210)
        end

        local border = button:CreateTexture(nil, "BACKGROUND", nil, 1)
        border:SetAllPoints()
        border:SetColorTexture(GetComparisonBorderColor(record.state, displayNode.isChoice))

        local inner = button:CreateTexture(nil, "BACKGROUND", nil, 2)
        inner:SetPoint("TOPLEFT", 2, -2)
        inner:SetPoint("BOTTOMRIGHT", -2, 2)
        inner:SetColorTexture(0.025, 0.025, 0.025, 0.96)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexture(displayNode.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local selectedEither = (record.target and record.target.selected) or (record.current and record.current.selected)
        icon:SetAlpha(selectedEither and 1 or 0.38)
        if icon.SetDesaturated then icon:SetDesaturated(not selectedEither) end

        local rankNode = (record.target and record.target.selected and record.target) or (record.current and record.current.selected and record.current)
        if rankNode and rankNode.maxRank and rankNode.maxRank > 1 then
            local rankBG = button:CreateTexture(nil, "OVERLAY")
            rankBG:SetSize(record.state == "rankDiff" and 42 or 30, 14)
            rankBG:SetPoint("BOTTOMRIGHT", 3, -3)
            rankBG:SetColorTexture(0, 0, 0, 0.9)
            local rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rankText:SetPoint("CENTER", rankBG, "CENTER", 0, 0)
            if record.state == "rankDiff" then
                rankText:SetText("T" .. tostring(record.target and record.target.rank or 0) .. "/M" .. tostring(record.current and record.current.rank or 0))
            else
                rankText:SetText(tostring(rankNode.rank or 0) .. "/" .. tostring(rankNode.maxRank))
            end
            rankText:SetTextColor(1, 0.85, 0.25)
        end

        if displayNode.isChoice then
            local badge = button:CreateTexture(nil, "OVERLAY")
            badge:SetSize(13, 13)
            badge:SetPoint("TOPRIGHT", 4, 4)
            badge:SetColorTexture(0.08, 0.32, 0.45, 0.96)
            local choice = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            choice:SetPoint("CENTER", badge, "CENTER", 0, 0)
            choice:SetText("C")
            choice:SetTextColor(0.55, 0.95, 1)
        end

        button:SetScript("OnEnter", function(self)
            local record = self.compareRecord
            local talent = self.displayNode
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if talent and talent.spellID then
                if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(talent.spellID) else GameTooltip:SetHyperlink("spell:" .. talent.spellID) end
            else
                GameTooltip:AddLine(talent and talent.name or "Talent")
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Comparison: " .. GetComparisonStatusLabel(record.state), 1, 0.82, 0.3)
            GameTooltip:AddLine("Target: " .. FormatComparisonSelection(record.target), 1, 0.42, 0.36)
            GameTooltip:AddLine("My Build: " .. FormatComparisonSelection(record.current), 0.35, 0.72, 1)
            if record.state ~= "match" and record.state ~= "none" then
                GameTooltip:AddLine("Target -> My Build: " .. FormatComparisonSelection(record.target) .. " -> " .. FormatComparisonSelection(record.current), 0.9, 0.75, 1)
            else
                GameTooltip:AddLine("No change required.", 0.35, 1, 0.55)
            end
            if talent and talent.isChoice then GameTooltip:AddLine("Choice node", 0.45, 0.9, 1) end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
    end

    for _, node in ipairs(nodes) do
        local startButton = nodeButtons[node.nodeID]
        local startRecord = recordMap[node.nodeID]
        if startButton and startRecord then
            for _, edge in ipairs(node.edges or {}) do
                local targetButton = nodeButtons[edge.targetNode]
                local endRecord = recordMap[edge.targetNode]
                if targetButton and endRecord then
                    local targetPath = startRecord.target and startRecord.target.selected and endRecord.target and endRecord.target.selected
                    local currentPath = startRecord.current and startRecord.current.selected and endRecord.current and endRecord.current.selected
                    local line = canvas:CreateLine(nil, "BACKGROUND", nil, 0)
                    line:SetStartPoint("CENTER", startButton, 0, 0)
                    line:SetEndPoint("CENTER", targetButton, 0, 0)
                    if targetPath and currentPath then
                        line:SetColorTexture(1, 0.72, 0.16, 0.92)
                        line:SetThickness(3.4)
                    elseif targetPath then
                        line:SetColorTexture(1, 0.25, 0.20, 0.88)
                        line:SetThickness(3.2)
                    elseif currentPath then
                        line:SetColorTexture(0.20, 0.62, 1, 0.88)
                        line:SetThickness(3.2)
                    else
                        line:SetColorTexture(0.42, 0.42, 0.42, 0.34)
                        line:SetThickness(1.15)
                    end
                end
            end
        end
    end

    y = y + canvasHeight + 8
    if differencesOnly then
        y = AddParagraph(content, y, "Differences Only is ON. Red = target only; blue = My Build only; purple = rank/choice differs; C = choice node. Matching and unselected nodes are hidden.", 610, {0.65, 0.8, 1})
    else
        y = AddParagraph(content, y, "Gold = same selection/path; red = target only; blue = My Build only; purple = rank/choice differs; gray = unselected by both; C = choice node.", 610, {0.65, 0.8, 1})
    end
    return y
end

local function AddTalentComparisonPreview(content, y, comparison)
    local title = AddElement(content, NewText(content, 16, 1, 0.82, 0.25))
    title:SetPoint("TOPLEFT", 4, -y)
    title:SetText("Guide / Target vs My Build")
    y = y + 24

    local s = comparison.summary or {}
    if (s.totalDifferences or 0) == 0 then
        y = AddParagraph(content, y, "Exact match: every selected talent, choice, and rank matches the target build.", 610, {0.35, 1, 0.55})
    else
        y = AddParagraph(content, y, tostring(s.match or 0) .. " matching selections | " .. tostring(s.targetOnly or 0) .. " target-only | " .. tostring(s.currentOnly or 0) .. " My Build-only | " .. tostring((s.rankDiff or 0) + (s.choiceDiff or 0)) .. " rank/choice differences", 610, {0.75, 0.88, 1})
    end

    if comparison.target and comparison.target.heroIncomplete then
        y = AddParagraph(content, y, "WARNING: the target import does not fully fill its active level-90 Hero tree. Comparison results are still shown, but this target string may be old or incomplete and cannot be imported as a saved loadout from Azeroth Guidebook.", 610, {1, 0.45, 0.25})
    end

    if comparison.targetHeroName and comparison.currentHeroName and comparison.targetHeroName ~= comparison.currentHeroName then
        y = AddParagraph(content, y, "Hero tree differs: target uses " .. comparison.targetHeroName .. "; your current build uses " .. comparison.currentHeroName .. ". The Hero canvas shows the target tree, while the difference list still reports your current Hero selections.", 610, {1, 0.55, 0.3})
    end

    local differences = AGB:GetTalentComparisonDifferences(comparison)
    local differenceCount = #differences
    local differencesOnly = AzerothGuidebookDB and AzerothGuidebookDB.talentDifferencesOnly == true

    AddActionButton(content, 4, y, 145, differencesOnly and "Show All Nodes" or "Differences Only", function()
        AzerothGuidebookDB.talentDifferencesOnly = not (AzerothGuidebookDB.talentDifferencesOnly == true)
        AGB:RenderTab("Talents")
    end, true)

    local function FocusDifference(delta)
        if differenceCount == 0 then return end
        local index = AGB.talentDifferenceFocusIndex
        if not index or index < 1 or index > differenceCount then
            index = delta > 0 and 0 or 1
        end
        index = ((index - 1 + delta) % differenceCount) + 1
        local record = differences[index]
        AGB.talentDifferenceFocusIndex = index
        AGB.talentDifferenceFocusNodeID = record.nodeID
        AGB.talentDifferenceFocusSection = record.section
        AzerothGuidebookDB.talentTreeSection = record.section
        AGB:RenderTab("Talents")
    end

    AddActionButton(content, 155, y, 145, "Previous Difference", function() FocusDifference(-1) end, differenceCount > 0)
    AddActionButton(content, 306, y, 145, "Next Difference", function() FocusDifference(1) end, differenceCount > 0)
    AddActionButton(content, 457, y, 153, "Clear Focus", function()
        AGB.talentDifferenceFocusIndex = nil
        AGB.talentDifferenceFocusNodeID = nil
        AGB.talentDifferenceFocusSection = nil
        AGB:RenderTab("Talents")
    end, AGB.talentDifferenceFocusNodeID ~= nil)
    y = y + 34

    local focusedRecord
    if AGB.talentDifferenceFocusIndex and differenceCount > 0 then
        if AGB.talentDifferenceFocusIndex > differenceCount then
            AGB.talentDifferenceFocusIndex = differenceCount
        end
        focusedRecord = differences[AGB.talentDifferenceFocusIndex]
        if focusedRecord then
            AGB.talentDifferenceFocusNodeID = focusedRecord.nodeID
            AGB.talentDifferenceFocusSection = focusedRecord.section
            y = AddParagraph(content, y, "Focused difference " .. tostring(AGB.talentDifferenceFocusIndex) .. "/" .. tostring(differenceCount) .. ": " .. tostring(focusedRecord.name or "Talent") .. " - " .. GetComparisonStatusLabel(focusedRecord.state) .. ".", 610, {1, 0.88, 0.45})
        end
    end

    local section = (AzerothGuidebookDB and AzerothGuidebookDB.talentTreeSection) or "Class"
    if focusedRecord and focusedRecord.section then section = focusedRecord.section end
    local targetClass = GetTalentTreeSectionNodes(comparison.target, "Class")
    local targetSpec = GetTalentTreeSectionNodes(comparison.target, "Spec")
    local targetHero = GetTalentTreeSectionNodes(comparison.target, "Hero")
    if section == "Class" and #targetClass == 0 then section = #targetSpec > 0 and "Spec" or "Hero" end
    if section == "Spec" and #targetSpec == 0 then section = #targetClass > 0 and "Class" or "Hero" end
    if section == "Hero" and #targetHero == 0 then section = #targetClass > 0 and "Class" or "Spec" end
    AzerothGuidebookDB.talentTreeSection = section

    local function SelectSection(newSection)
        AGB.talentDifferenceFocusIndex = nil
        AGB.talentDifferenceFocusNodeID = nil
        AGB.talentDifferenceFocusSection = nil
        AzerothGuidebookDB.talentTreeSection = newSection
        AGB:RenderTab("Talents")
    end

    local heroName = comparison.targetHeroName or "Hero"
    AddActionButton(content, 4, y, 176, "Class " .. tostring(GetComparisonSectionDifferenceCount(comparison, "Class")) .. " diff", function()
        SelectSection("Class")
    end, section ~= "Class" and #targetClass > 0)
    AddActionButton(content, 186, y, 176, "Spec " .. tostring(GetComparisonSectionDifferenceCount(comparison, "Spec")) .. " diff", function()
        SelectSection("Spec")
    end, section ~= "Spec" and #targetSpec > 0)
    AddActionButton(content, 368, y, 242, heroName .. " " .. tostring(GetComparisonSectionDifferenceCount(comparison, "Hero")) .. " diff", function()
        SelectSection("Hero")
    end, section ~= "Hero" and #targetHero > 0)
    y = y + 34

    local sectionTitle = section == "Spec" and "Specialization Comparison" or (section == "Hero" and (heroName .. " Hero Comparison") or "Class Talent Comparison")
    local treeTitle = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
    treeTitle:SetPoint("TOPLEFT", 4, -y)
    treeTitle:SetText(sectionTitle)
    y = y + 23

    y = AddTalentComparisonCanvas(content, y, comparison, section)
    y = AddTalentComparisonDifferenceList(content, y + 4, comparison, section)
    return y
end

local function AddTalentPreview(content, y, decoded, label)
    local previewTitle = AddElement(content, NewText(content, 16, 1, 0.82, 0.25))
    previewTitle:SetPoint("TOPLEFT", 4, -y)
    previewTitle:SetText(label or "Selected Talents")
    y = y + 24

    local hashText
    if decoded.liveCharacter then
        hashText = "live character config"
    elseif decoded.hashEmbedded then
        hashText = decoded.hashValidated and "hash validated" or "hash embedded"
    else
        hashText = "third-party/zero hash"
    end

    local previewLabel = decoded.liveCharacter and ("Character level " .. tostring(decoded.previewLevel or "?")) or ("Import preview level " .. tostring(decoded.previewLevel or "?"))
    y = AddParagraph(content, y, previewLabel .. " | Hover nodes for tooltips | Spec " .. tostring(decoded.specID or "?") .. " | Serialization " .. tostring(decoded.serializationVersion or "?") .. " | " .. hashText, 610, {0.65, 0.8, 1})

    if decoded.heroIncomplete then
        y = AddParagraph(content, y, "WARNING: This level-90 preview only selects " .. tostring(decoded.heroSelected or 0) .. "/" .. tostring(decoded.heroVisible or 0) .. " nodes in the active Hero tree. At level 90 in Midnight, the active Hero Talent tree should be fully filled. Treat this import string as old or incomplete rather than as a current max-level guide build.", 610, {1, 0.45, 0.25})
    elseif decoded.grantedRepairApplied then
        y = AddParagraph(content, y, "U.GG omitted " .. tostring(decoded.grantedRepairRanks or decoded.grantedRepairCount or 0) .. " Blizzard-granted starter rank(s). Azeroth Guidebook restored only ranks the live client marks as Granted; no optional talent choice was inferred.", 610, {0.35, 1, 0.65})
    end

    local mode = (AzerothGuidebookDB and AzerothGuidebookDB.talentDisplayMode) or "visual"
    local classNodes = GetTalentTreeSectionNodes(decoded, "Class")
    local specNodes = GetTalentTreeSectionNodes(decoded, "Spec")
    local heroNodes = GetTalentTreeSectionNodes(decoded, "Hero")
    local heroName = GetHeroTreeName(decoded)

    if mode == "list" then
        AddActionButton(content, 4, y, 100, "Visual Tree", function()
            AzerothGuidebookDB.talentDisplayMode = "visual"
            AGB:RenderTab("Talents")
        end, true)
        AddActionButton(content, 110, y, 110, "Selected List", function()
            AzerothGuidebookDB.talentDisplayMode = "list"
            AGB:RenderTab("Talents")
        end, false)
        y = y + 32
        return AddTalentListPreview(content, y, decoded)
    end

    local section = (AzerothGuidebookDB and AzerothGuidebookDB.talentTreeSection) or "Class"
    if section == "Class" and #classNodes == 0 then
        section = #specNodes > 0 and "Spec" or "Hero"
    elseif section == "Spec" and #specNodes == 0 then
        section = #classNodes > 0 and "Class" or "Hero"
    elseif section == "Hero" and #heroNodes == 0 then
        section = #classNodes > 0 and "Class" or "Spec"
    end
    AzerothGuidebookDB.talentTreeSection = section

    local classSelected = CountSelectedNodes(classNodes)
    local specSelected = CountSelectedNodes(specNodes)
    local heroSelected = CountSelectedNodes(heroNodes)

    -- Keep display-mode and tree-section controls on one row to preserve vertical space.
    AddActionButton(content, 4, y, 96, "Visual Tree", function()
        AzerothGuidebookDB.talentDisplayMode = "visual"
        AGB:RenderTab("Talents")
    end, false)
    AddActionButton(content, 106, y, 108, "Selected List", function()
        AzerothGuidebookDB.talentDisplayMode = "list"
        AGB:RenderTab("Talents")
    end, true)
    AddActionButton(content, 224, y, 108, "Class " .. tostring(classSelected) .. "/" .. tostring(#classNodes), function()
        AzerothGuidebookDB.talentTreeSection = "Class"
        AGB:RenderTab("Talents")
    end, section ~= "Class" and #classNodes > 0)
    AddActionButton(content, 338, y, 120, "Spec " .. tostring(specSelected) .. "/" .. tostring(#specNodes), function()
        AzerothGuidebookDB.talentTreeSection = "Spec"
        AGB:RenderTab("Talents")
    end, section ~= "Spec" and #specNodes > 0)
    AddActionButton(content, 464, y, 146, heroName .. " " .. tostring(heroSelected) .. "/" .. tostring(#heroNodes), function()
        AzerothGuidebookDB.talentTreeSection = "Hero"
        AGB:RenderTab("Talents")
    end, section ~= "Hero" and #heroNodes > 0)
    y = y + 34

    local sectionTitle = section == "Spec" and "Specialization Talent Tree" or (section == "Hero" and (heroName .. " Hero Talent Tree") or "Class Talent Tree")
    local treeTitle = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
    treeTitle:SetPoint("TOPLEFT", 4, -y)
    treeTitle:SetText(sectionTitle)
    y = y + 23

    y = AddTalentTreeCanvas(content, y, decoded, section)
    return y
end

local function NormalizeGuideFocusText(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("%s*%([^%)]*%)", "")
    text = text:gsub("%s*#%d+%s*$", "")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function GuideFocusMatches(tabName, leftLabel, item)
    local focus = AGB._pendingGuideFocus
    if not focus or focus.tabName ~= tabName then return false end
    item = item or {}

    local slotMatches = true
    if focus.slot then
        local wantedSlot = NormalizeGuideFocusText(focus.slot)
        local rowSlot = NormalizeGuideFocusText(leftLabel)
        slotMatches = wantedSlot ~= "" and rowSlot ~= "" and (
            wantedSlot == rowSlot
            or string.find(rowSlot, wantedSlot, 1, true) == 1
            or string.find(wantedSlot, rowSlot, 1, true) == 1
        )
    end

    if focus.itemID and item.id and tonumber(focus.itemID) == tonumber(item.id) and slotMatches then return true end
    if focus.spellID and item.spellID and tonumber(focus.spellID) == tonumber(item.spellID) and slotMatches then return true end

    if focus.name and item.name then
        local wantedName = NormalizeGuideFocusText(focus.name)
        local rowName = NormalizeGuideFocusText(item.name)
        if wantedName ~= "" and wantedName == rowName and slotMatches then return true end
    end

    -- If the issue carries an exact entity/name target, do not let another row
    -- in the same slot steal focus just because its slot label also matches.
    if focus.itemID or focus.spellID or focus.name then return false end
    return focus.slot ~= nil and slotMatches
end

local function ApplyPendingGuideFocusScroll(tabName)
    local focus = AGB._pendingGuideFocus
    if not focus or focus.tabName ~= tabName then return end

    local targetScroll = AGB._guideFocusScrollY
    AGB._pendingGuideFocus = nil
    AGB._guideFocusScrollY = nil

    if targetScroll == nil then return end
    local function ApplyFocusScroll()
        if not AGB.UI or not AGB.UI.scroll then return end
        local maxScroll = AGB.UI.scroll:GetVerticalScrollRange() or 0
        AGB.UI.scroll:SetVerticalScroll(math.min(math.max(0, targetScroll - 18), maxScroll))
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyFocusScroll)
    else
        ApplyFocusScroll()
    end
end

local function AddItemRow(content, y, leftLabel, item, sourceText, showStatus)
    local row = AddElement(content, CreateFrame("Button", nil, content))
    row:SetSize(610, 38)
    row:SetPoint("TOPLEFT", 4, -y)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, (math.floor(y / 38) % 2 == 0) and 0.035 or 0.06)

    local currentTab = AzerothGuidebookDB and AzerothGuidebookDB.lastTab or nil
    if GuideFocusMatches(currentTab, leftLabel, item) then
        bg:SetColorTexture(0.12, 0.48, 0.9, 0.22)
        AGB._guideFocusScrollY = y

        local focusBar = row:CreateTexture(nil, "OVERLAY")
        focusBar:SetPoint("TOPLEFT", 0, 0)
        focusBar:SetPoint("BOTTOMLEFT", 0, 0)
        focusBar:SetWidth(3)
        focusBar:SetColorTexture(0.25, 0.75, 1, 0.95)
    end

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    if item.id and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(item.id)
        local _, _, _, _, iconFileID = C_Item.GetItemInfoInstant(item.id)
        if iconFileID then icon:SetTexture(iconFileID) end
    elseif item.spellID then
        local spellTexture
        if C_Spell and C_Spell.GetSpellTexture then
            spellTexture = C_Spell.GetSpellTexture(item.spellID)
        elseif GetSpellTexture then
            spellTexture = GetSpellTexture(item.spellID)
        end
        if spellTexture then icon:SetTexture(spellTexture) end
    end

    local slot = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    slot:SetPoint("LEFT", icon, "RIGHT", 8, 8)
    slot:SetWidth(104)
    slot:SetJustifyH("LEFT")
    slot:SetText(leftLabel or "")
    slot:SetTextColor(0.65, 0.8, 1)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("LEFT", icon, "RIGHT", 116, 8)
    name:SetWidth(265)
    name:SetJustifyH("LEFT")
    name:SetText(item.name or (item.id and ("Item " .. tostring(item.id))) or (item.spellID and ("Spell " .. tostring(item.spellID))) or "Recommendation")

    local source = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    source:SetPoint("LEFT", icon, "RIGHT", 116, -9)
    source:SetWidth(300)
    source:SetJustifyH("LEFT")
    source:SetText(sourceText or "")
    source:SetTextColor(0.65, 0.65, 0.65)

    if showStatus and item.id then
        local _, statusText = AGB:GetItemStatus(item.id)
        local status = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        status:SetPoint("RIGHT", -8, 0)
        status:SetWidth(85)
        status:SetJustifyH("RIGHT")
        status:SetText(statusText)
    end

    if item.id then
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. item.id)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function()
            local itemName, itemLink
            if C_Item and C_Item.GetItemInfo then
                itemName, itemLink = C_Item.GetItemInfo(item.id)
            elseif GetItemInfo then
                itemName, itemLink = GetItemInfo(item.id)
            end
            if IsModifiedClick("CHATLINK") and itemLink then
                ChatEdit_InsertLink(itemLink)
            end
        end)
    elseif item.spellID then
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(item.spellID)
            else
                GameTooltip:SetHyperlink("spell:" .. item.spellID)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function()
            local spellLink
            if C_Spell and C_Spell.GetSpellLink then
                spellLink = C_Spell.GetSpellLink(item.spellID)
            elseif GetSpellLink then
                spellLink = GetSpellLink(item.spellID)
            end
            if IsModifiedClick("CHATLINK") and spellLink then
                ChatEdit_InsertLink(spellLink)
            end
        end)
    end
    return y + 42
end


-- Some source-authored rotation steps are intentionally generic actions rather
-- than exact spell/item references (for example, "Eat Food"). Give those rows
-- a category-appropriate visual without pretending that the rotation source
-- named a specific consumable for that step.
local function GetRotationFallbackItemIcon(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, iconFileID = C_Item.GetItemInfoInstant(itemID)
        return iconFileID
    elseif GetItemInfoInstant then
        local _, _, _, _, iconFileID = GetItemInfoInstant(itemID)
        return iconFileID
    end
    return nil
end

local function GetRotationFallbackIcon(actionText)
    local textValue = string.lower(tostring(actionText or ""))
    local itemID
    if string.find(textValue, "weapon oil", 1, true) or string.find(textValue, "weapon buff", 1, true) then
        itemID = 243734 -- Thalassian Phoenix Oil; used only as a category icon source.
    elseif string.find(textValue, "flask", 1, true) then
        itemID = 241322 -- Flask of the Magisters; used only as a category icon source.
    elseif string.find(textValue, "food", 1, true) then
        itemID = 255846 -- Harandar Celebration; used only as a category icon source.
    elseif string.find(textValue, "potion", 1, true) then
        itemID = 241308 -- Light's Potential; used only as a category icon source.
    end

    local categoryTexture = GetRotationFallbackItemIcon(itemID)
    if categoryTexture then return categoryTexture end

    -- A source-authored guidance row is still valid evidence even when it does
    -- not name one exact spell or item. Use a neutral note icon rather than the
    -- red missing-asset question mark; this does not imply any extra ability.
    return "Interface\\Icons\\INV_Misc_Note_01"
end

local function AddRotationActionRow(content, y, index, action, marker)
    local row = AddElement(content, CreateFrame("Button", nil, content))
    row:SetPoint("TOPLEFT", 4, -y)
    row:SetWidth(610)

    local entity = action and action.entities and action.entities[1] or nil
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", 4, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    if entity and entity.kind == "item" and entity.id then
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(entity.id)
            local _, _, _, _, iconFileID = C_Item.GetItemInfoInstant(entity.id)
            if iconFileID then icon:SetTexture(iconFileID) end
        end
    elseif entity and entity.kind == "spell" and entity.id then
        local spellTexture
        if C_Spell and C_Spell.GetSpellTexture then
            spellTexture = C_Spell.GetSpellTexture(entity.id)
        elseif GetSpellTexture then
            spellTexture = GetSpellTexture(entity.id)
        end
        if spellTexture then icon:SetTexture(spellTexture) end
    else
        local fallbackTexture = GetRotationFallbackIcon(action and action.text)
        if fallbackTexture then icon:SetTexture(fallbackTexture) end
    end

    local number = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    number:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -3)
    number:SetWidth(28)
    number:SetJustifyH("RIGHT")
    number:SetText(marker or (tostring(index or "") .. "."))
    number:SetTextColor(0.35, 0.85, 1)

    local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", number, "TOPRIGHT", 8, 0)
    text:SetWidth(530)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText((action and action.text) or "")

    local height = math.max(40, math.ceil((text:GetStringHeight() or 18) + 14))
    row:SetHeight(height)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, (index or 1) % 2 == 0 and 0.035 or 0.06)

    if entity and entity.id then
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if entity.kind == "item" then
                GameTooltip:SetHyperlink("item:" .. entity.id)
            elseif entity.kind == "spell" then
                if GameTooltip.SetSpellByID then
                    GameTooltip:SetSpellByID(entity.id)
                else
                    GameTooltip:SetHyperlink("spell:" .. entity.id)
                end
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function()
            if not IsModifiedClick("CHATLINK") then return end
            local link
            if entity.kind == "item" then
                if C_Item and C_Item.GetItemInfo then
                    local _, itemLink = C_Item.GetItemInfo(entity.id)
                    link = itemLink
                elseif GetItemInfo then
                    local _, itemLink = GetItemInfo(entity.id)
                    link = itemLink
                end
            elseif entity.kind == "spell" then
                if C_Spell and C_Spell.GetSpellLink then
                    link = C_Spell.GetSpellLink(entity.id)
                elseif GetSpellLink then
                    link = GetSpellLink(entity.id)
                end
            end
            if link then ChatEdit_InsertLink(link) end
        end)
    end

    return y + height + 4
end

local function FormatSourcePriority(stats, relations)
    local parts = {}
    for index, stat in ipairs(stats or {}) do
        table.insert(parts, tostring(stat))
        if index < #(stats or {}) then
            table.insert(parts, " " .. tostring((relations or {})[index] or ">") .. " ")
        end
    end
    return table.concat(parts, "")
end


local function AddActivityProfileSelector(content, y, specID, tabName)
    if not specID or not AGB.GetActivityProfileDefinitions then return y end

    local definitions = AGB:GetActivityProfileDefinitions() or {}
    if #definitions == 0 then return y end

    local activeKey = AGB:GetActiveActivityProfileKey(specID)
    local activeRecord = activeKey and AGB:GetActivityProfile(specID, activeKey) or nil
    local activeIsCurrent = activeKey and activeRecord and AGB:IsActivityProfileCurrent(specID, activeKey) or false

    y = AddParagraph(content, y, "Activity Profile", 610, {1, 0.82, 0.35})
    if activeKey and activeRecord then
        local label = AGB:GetActivityProfileLabel(activeKey)
        if activeIsCurrent then
            y = AddParagraph(content, y, "Current profile: " .. tostring(label) .. " | Saved selections active", 610, {0.35, 1, 0.65})
        else
            y = AddParagraph(content, y, "Current profile: " .. tostring(label) .. " | Modified - save changes or reselect the profile to restore its saved selections.", 610, {1, 0.72, 0.35})
        end
    else
        y = AddParagraph(content, y, "No activity profile selected. Save the current guide setup as Raid, Mythic+, or Delves; profiles are stored separately for each specialization.", 610, {0.65, 0.8, 1})
    end

    local buttonWidth, gap = 190, 8
    for index, definition in ipairs(definitions) do
        local profile = AGB:GetActivityProfile(specID, definition.key)
        local isActive = activeKey == definition.key
        local isCurrent = profile and AGB:IsActivityProfileCurrent(specID, definition.key) or false
        local label
        if isActive and isCurrent then
            label = definition.label .. " [Selected]"
        elseif isActive then
            label = definition.label .. " [Modified]"
        elseif profile then
            label = definition.label .. " [Saved]"
        else
            label = "Save as " .. definition.label
        end
        AddActionButton(content, 4 + (index - 1) * (buttonWidth + gap), y, buttonWidth, label, function()
            local existing = AGB:GetActivityProfile(specID, definition.key)
            if existing then
                local ok, warnings = AGB:ApplyActivityProfile(specID, definition.key)
                if ok and warnings and #warnings > 0 and AGB.Print then
                    AGB.Print("Activity profile applied with " .. tostring(#warnings) .. " unavailable selection(s); see current guide selections.")
                elseif not ok and AGB.Print then
                    AGB.Print("Could not apply the " .. tostring(definition.label) .. " activity profile.")
                end
            else
                AGB:SaveActivityProfile(specID, definition.key)
                if AGB.Print then AGB.Print(tostring(definition.label) .. " activity profile saved from the current guide selections.") end
            end
            AGB:RenderTab(tabName)
        end, not (isActive and isCurrent))
    end
    y = y + 32

    if activeKey and activeRecord then
        local activeLabel = AGB:GetActivityProfileLabel(activeKey)
        AddActionButton(content, 4, y, 260, activeIsCurrent and (activeLabel .. " profile saved") or ("Save Changes to " .. activeLabel), function()
            if AGB:SaveActivityProfile(specID, activeKey) then
                if AGB.Print then AGB.Print(tostring(activeLabel) .. " activity profile updated.") end
                AGB:RenderTab(tabName)
            end
        end, not activeIsCurrent)
        y = y + 32
    end

    y = AddParagraph(content, y, "Profiles remember the current sources for all guide domains, U.GG context, talent category/build choices, Wowhead gear set, and Rotation context/preset. Saving a profile captures the current setup exactly; Azeroth Guidebook does not choose sources for you.", 610, {0.72, 0.8, 0.9})
    y = AddDivider(content, y + 2)
    return y
end

local function AddSourceSelector(content, y, specID, tabName)
    if not AGB.GetAvailableGuideSources then return y, "wowhead" end
    local sources = AGB:GetAvailableGuideSources(specID, tabName)
    local selected = AGB:GetSelectedGuideSource(specID, tabName)
    if #sources <= 1 then return y, selected end

    y = AddParagraph(content, y, "Guide Source", 610, {1, 0.82, 0.35})
    local selectedLabel = AGB.GetGuideSourceLabel and AGB:GetGuideSourceLabel(selected) or tostring(selected or "Source")
    y = AddParagraph(content, y, "Current source: " .. tostring(selectedLabel), 610, {0.55, 0.9, 1})

    -- UIPanelButtonTemplate renders disabled buttons gray. Selected source buttons
    -- are intentionally disabled so re-clicking them is a no-op, but that visual
    -- can make the other (clickable) red button look selected. Keep the established
    -- disabled-selected behavior while making the active source explicit in text.
    local buttonWidth = 172
    local gap = 8
    for index, source in ipairs(sources) do
        local bx = 4 + (index - 1) * (buttonWidth + gap)
        local isSelected = selected == source.id
        local buttonLabel = isSelected and (source.label .. " [Selected]") or source.label
        AddActionButton(content, bx, y, buttonWidth, buttonLabel, function()
            AGB.multiSourceTalentPreview = nil
            if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
            AGB:SetSelectedGuideSource(specID, tabName, source.id)
            AGB:RenderTab(tabName)
        end, not isSelected)
    end
    y = y + 32

    if selected == "ugg" then
        local context = AGB:GetGuideSourceContext(specID)
        local contextLabel = context == "mythicplus" and "Mythic+" or "Raid"
        y = AddParagraph(content, y, "U.GG Content Context", 610, {0.55, 0.9, 1})
        y = AddParagraph(content, y, "Current context: " .. contextLabel, 610, {0.55, 0.9, 1})

        local contextButtonWidth = 172
        local contextGap = 8
        local raidSelected = context == "raid"
        local mythicSelected = context == "mythicplus"
        AddActionButton(content, 4, y, contextButtonWidth, raidSelected and "Raid [Selected]" or "Raid", function()
            AGB.multiSourceTalentPreview = nil
            if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
            AGB:SetGuideSourceContext(specID, "raid")
            AGB:RenderTab(tabName)
        end, not raidSelected)
        AddActionButton(content, 4 + contextButtonWidth + contextGap, y, contextButtonWidth, mythicSelected and "Mythic+ [Selected]" or "Mythic+", function()
            AGB.multiSourceTalentPreview = nil
            if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
            AGB:SetGuideSourceContext(specID, "mythicplus")
            AGB:RenderTab(tabName)
        end, not mythicSelected)
        y = y + 32
    end

    y = AddDivider(content, y + 2)
    return y, selected
end

local function AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    local label = source and source.label or AGB:GetGuideSourceLabel(sourceID)
    patch = patch or "12.1.0"
    if sourceID == "icy-veins" then
        y = AddParagraph(content, y, "Patch " .. tostring(patch) .. " | " .. tostring(label) .. " source updated " .. tostring(domain.sourceUpdated or "unknown"), 610, {0.75, 0.88, 1})
        y = AddParagraph(content, y, source.semantics or "Editorial guide recommendations are shown separately and are not blended with other sources.", 610, {0.75, 0.82, 0.9})
    elseif sourceID == "ugg" then
        local ctxLabel = context and context.label or "Observed data"
        local updated = domain.sourceUpdatedRaw or (domain.metrics and domain.metrics.lastUpdatedRaw)
        local capturedDate = tostring(domain.capturedAt or ""):match("^(%d%d%d%d%-%d%d%-%d%d)")
        local freshnessText
        if updated and tostring(updated) ~= "" and string.lower(tostring(updated)) ~= "unknown" then
            freshnessText = "Source reported " .. tostring(updated) .. " at capture"
        elseif capturedDate then
            freshnessText = "Captured " .. capturedDate
        else
            freshnessText = "Captured source snapshot"
        end
        y = AddParagraph(content, y, "Patch " .. tostring(patch) .. " | " .. tostring(label) .. " observed player data | " .. tostring(ctxLabel) .. " | " .. freshnessText, 610, {0.75, 0.88, 1})
        y = AddParagraph(content, y, source.semantics or "Observed usage/popularity is descriptive player data, not an editorial Best-in-Slot verdict.", 610, {0.75, 0.82, 0.9})
    end
    return y
end

local function AddUggMetrics(content, y, metrics)
    metrics = metrics or {}
    local pieces = {}
    if metrics.totalParses then table.insert(pieces, "Parses: " .. tostring(metrics.totalParses)) end
    if metrics.keyRange then table.insert(pieces, "Key range: " .. tostring(metrics.keyRange)) end
    if metrics.maxKey then table.insert(pieces, "Max key: " .. tostring(metrics.maxKey)) end
    if metrics.talentPopularity then table.insert(pieces, "Talent popularity: " .. tostring(metrics.talentPopularity) .. "%") end
    if #pieces > 0 then
        y = AddParagraph(content, y, table.concat(pieces, " | "), 610, {0.75, 0.88, 1})
    end
    return y
end

local function MultiSourceTalentSelectionKey(specID, sourceID, contextKey)
    return tostring(specID or 0) .. ":" .. tostring(sourceID or "source") .. ":" .. tostring(contextKey or "general")
end

local function MultiSourceTalentBuildLabel(build, sourceID, context)
    local label = tostring((build and build.name) or "Guide Build")
    if sourceID == "ugg" and string.lower(label) == "copy" then
        local contextLabel = context and context.label or "Observed"
        label = tostring(contextLabel) .. " observed build"
    end
    return label
end

local function DecodeMultiSourceTalentBuild(build, specID, sourceID, source, context)
    if not build or build.exact ~= true or not build.importString or build.importString == "" then
        return nil, "No exact source build is available for this selection."
    end
    local decoded, err = AGB:DecodeReviewedSourceTalentBuild(build.importString, specID, sourceID, 90)
    if not decoded then return nil, err end
    decoded.label = MultiSourceTalentBuildLabel(build, sourceID, context) .. " (" .. tostring(source and source.label or "Source") .. ")"
    decoded.guideBuildExact = true
    decoded.guideBuildValidated = true
    return decoded
end

local function RenderMultiSourceTalentPreview(content, y, specID, sourceID, contextKey, buildIndex)
    local preview = AGB.multiSourceTalentPreview
    if not preview
        or preview.specID ~= specID
        or preview.sourceID ~= sourceID
        or preview.contextKey ~= contextKey
        or preview.buildIndex ~= buildIndex then
        return y
    end

    y = AddDivider(content, y + 4)
    if preview.mode == "compare" and preview.comparison then
        y = AddTalentComparisonPreview(content, y, preview.comparison)
    elseif preview.mode == "current" and preview.current then
        y = AddTalentPreview(content, y, preview.current, "My Current Build")
    elseif preview.target then
        y = AddTalentPreview(content, y, preview.target, preview.target.label or "Guide / Target Build")
    end
    return y
end

local function RenderMultiSourceTalentUtilityControls(content, y, specID, domain)
    local _, playerSpecID = AGB:GetPlayerContext()
    local canPreviewCurrent = playerSpecID == specID

    AddActionButton(content, 4, y, 155, "Paste / Preview Build", function()
        AGB:ShowTalentInput()
    end, true)

    AddActionButton(content, 165, y, 155, "Preview My Build", function()
        local decoded, err = AGB:GetCurrentTalentPreview()
        if not decoded then
            AGB.Print(err or "Unable to read the current talent build.")
            return
        end
        if decoded.specID ~= specID then
            AGB.Print("Your active specialization does not match the displayed guide.")
            return
        end
        AGB.customTalentPreview = decoded
        AGB.customTalentPreview.label = "My Current Build"
        AGB.multiSourceTalentPreview = nil
        AGB.talentComparisonTarget = nil
        AGB.talentComparisonLive = decoded
        AGB.talentComparison = nil
        AGB.talentCompareMode = "current"
        AGB.talentDifferenceFocusIndex = nil
        AGB.talentDifferenceFocusNodeID = nil
        AGB.talentDifferenceFocusSection = nil
        AGB:RenderTab("Talents")
    end, canPreviewCurrent)

    AddActionButton(content, 326, y, 145, "Copy Source URL", function()
        AGB:ShowCopyText(domain.sourceURL)
    end, domain.sourceURL ~= nil and domain.sourceURL ~= "")

    if AGB.customTalentPreview then
        AddActionButton(content, 477, y, 133, "Clear Preview", function()
            AGB:ClearCustomTalentPreview()
            AGB:RenderTab("Talents")
        end, true)
    end
    y = y + 36

    if AGB.customTalentPreview then
        y = AddDivider(content, y + 2)
        y = AddTalentPreview(content, y, AGB.customTalentPreview, AGB.customTalentPreview.label or "Preview Build")
    end
    return y
end

local function RenderMultiSourceTalents(content, y, specID, sourceID, domain, source, context, contextKey, patch)
    y = AddHeading(content, y, "Talent Builds")
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    if sourceID == "ugg" then y = AddUggMetrics(content, y, domain.metrics) end

    local builds = domain.builds or {}
    if #builds == 0 then
        y = AddParagraph(content, y + 4, domain.note or "No exact Blizzard import string is available for this source/context. The source remains fail-closed rather than borrowing another build.", 610, {1, 0.55, 0.35})
        y = RenderMultiSourceTalentUtilityControls(content, y + 6, specID, domain)
        return y
    end

    AzerothGuidebookDB.multiSourceTalentBuilds = AzerothGuidebookDB.multiSourceTalentBuilds or {}
    local selectionKey = MultiSourceTalentSelectionKey(specID, sourceID, contextKey)
    local selectedIndex = tonumber(AzerothGuidebookDB.multiSourceTalentBuilds[selectionKey]) or 1
    if selectedIndex < 1 or selectedIndex > #builds then selectedIndex = 1 end
    local selectedBuild = builds[selectedIndex]

    if #builds > 1 then
        y = AddParagraph(content, y + 4, "Guide Builds", 610, {1, 0.82, 0.25})
        local columns = 2
        local buttonWidth = 298
        local buttonGap = 8
        local rowHeight = 30
        local rowCount = math.ceil(#builds / columns)
        local baseY = y
        for index, build in ipairs(builds) do
            local capturedIndex = index
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local isSelected = selectedIndex == index
            local label = MultiSourceTalentBuildLabel(build, sourceID, context)
            if isSelected then label = label .. " [Selected]" end
            AddActionButton(content, 4 + column * (buttonWidth + buttonGap), baseY + row * rowHeight, buttonWidth, label, function()
                AzerothGuidebookDB.multiSourceTalentBuilds[selectionKey] = capturedIndex
                AGB.multiSourceTalentPreview = nil
                if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
                AGB:RenderTab("Talents")
            end, not isSelected)
        end
        y = y + rowCount * rowHeight + 4
    end

    local selectedLabel = MultiSourceTalentBuildLabel(selectedBuild, sourceID, context)
    y = AddParagraph(content, y + 2, selectedLabel, 610, {1, 0.82, 0.35})

    local actionDecoded, actionDecodeErr = DecodeMultiSourceTalentBuild(selectedBuild, specID, sourceID, source, context)
    local sourceBuildComplete = actionDecoded ~= nil and actionDecoded.heroIncomplete ~= true
    if actionDecoded and actionDecoded.heroIncomplete then
        y = AddParagraph(content, y, "Exact source build string captured for spec " .. tostring(selectedBuild.decodedSpecID or specID) .. ", but the level-90 Hero tree remains incomplete after deterministic granted-rank normalization. Preview, compare, and copy remain available; native loadout import is blocked.", 610, {1, 0.72, 0.35})
    elseif actionDecoded and actionDecoded.grantedRepairApplied then
        y = AddParagraph(content, y, "Exact U.GG build captured for spec " .. tostring(selectedBuild.decodedSpecID or specID) .. ". The source omitted " .. tostring(actionDecoded.grantedRepairRanks or actionDecoded.grantedRepairCount or 0) .. " Blizzard-granted starter rank(s); the live client restored only those granted ranks for preview/import.", 610, {0.35, 1, 0.65})
    elseif actionDecoded then
        y = AddParagraph(content, y, "Exact Blizzard import captured and validated for spec " .. tostring(selectedBuild.decodedSpecID or specID) .. ".", 610, {0.35, 1, 0.65})
    else
        y = AddParagraph(content, y, actionDecodeErr or "The selected source build could not be decoded safely.", 610, {1, 0.55, 0.35})
    end

    local _, playerSpecID = AGB:GetPlayerContext()
    local canCompareCurrent = playerSpecID == specID and actionDecoded ~= nil
    local canImportCurrent = canCompareCurrent and sourceBuildComplete

    AddActionButton(content, 4, y + 2, 145, "View Guide Build", function()
        local decoded, err = DecodeMultiSourceTalentBuild(selectedBuild, specID, sourceID, source, context)
        if not decoded then AGB.Print(err or "Unable to decode the source build."); return end
        if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
        AGB.multiSourceTalentPreview = {
            specID = specID, sourceID = sourceID, contextKey = contextKey, buildIndex = selectedIndex,
            mode = "target", target = decoded,
        }
        AGB:RenderTab("Talents")
    end, true)
    AddActionButton(content, 155, y + 2, 145, "Compare to Mine", function()
        local decoded, err = DecodeMultiSourceTalentBuild(selectedBuild, specID, sourceID, source, context)
        if not decoded then AGB.Print(err or "Unable to decode the source build."); return end
        local current, currentErr = AGB:GetCurrentTalentPreview()
        if not current then AGB.Print(currentErr or "Unable to read the current talent build."); return end
        if current.specID ~= specID then AGB.Print("Your active specialization does not match the displayed guide."); return end
        local comparison, compareErr = AGB:BuildTalentComparison(decoded, current)
        if not comparison then AGB.Print(compareErr or "Unable to compare these talent builds."); return end
        if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
        AGB.multiSourceTalentPreview = {
            specID = specID, sourceID = sourceID, contextKey = contextKey, buildIndex = selectedIndex,
            mode = "compare", target = decoded, current = current, comparison = comparison,
        }
        AGB:RenderTab("Talents")
    end, canCompareCurrent)
    AddActionButton(content, 306, y + 2, 155, "Import as Loadout", function()
        local decoded, err = DecodeMultiSourceTalentBuild(selectedBuild, specID, sourceID, source, context)
        if not decoded then AGB.Print(err or "Unable to decode the source build."); return end
        if decoded.heroIncomplete then AGB.Print("This source build is incomplete at level 90 and cannot be handed to the loadout importer."); return end
        AGB:ShowTargetImportPopup(decoded)
    end, canImportCurrent)
    AddActionButton(content, 467, y + 2, 143, "Copy Build String", function()
        AGB:ShowCopyText(selectedBuild.importString)
    end, true)
    y = y + 38

    if not canCompareCurrent then
        y = AddParagraph(content, y, "Compare unavailable: activate this specialization on your character to compare the source build against your current talent selections.", 610, {1, 0.72, 0.35})
    end
    if playerSpecID ~= specID then
        y = AddParagraph(content, y, "Import unavailable: activate this specialization before importing a source build as a loadout.", 610, {1, 0.72, 0.35})
    elseif actionDecoded and actionDecoded.heroIncomplete then
        y = AddParagraph(content, y, "Import unavailable: this captured source build remains incomplete after restoring every deterministic Blizzard-granted starter rank exposed by the live tree. No optional talent will be guessed.", 610, {1, 0.72, 0.35})
    elseif not actionDecoded then
        y = AddParagraph(content, y, "Import unavailable: the selected source build could not be decoded safely.", 610, {1, 0.72, 0.35})
    elseif actionDecoded.grantedRepairApplied then
        y = AddParagraph(content, y, "Import uses the captured U.GG talent choices plus only the starter ranks that the live client explicitly marks as Granted. No optional talent choice is inferred.", 610, {0.65, 0.8, 1})
    else
        y = AddParagraph(content, y, "Import submits the exact captured source string unchanged; WoW performs the final loadout validation.", 610, {0.65, 0.8, 1})
    end

    y = RenderMultiSourceTalentUtilityControls(content, y + 4, specID, domain)
    y = RenderMultiSourceTalentPreview(content, y, specID, sourceID, contextKey, selectedIndex)
    return y
end

local function RenderMultiSourceBiS(content, y, sourceID, domain, source, context, patch)
    local title = sourceID == "ugg" and "Observed Gear" or "Best in Slot"
    y = AddHeading(content, y, title)
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)

    if sourceID == "icy-veins" then
        y = AddParagraph(content, y, "Hover any item for the normal WoW tooltip. Shift-click can link it to chat.", 610, {0.65, 0.8, 1})
        for _, item in ipairs(domain.items or {}) do
            y = AddItemRow(content, y, item.slot, item, item.source or "", true)
        end
    else
        y = AddUggMetrics(content, y, domain.metrics)
        y = AddParagraph(content, y, "Rows below are observed most-popular items for the selected U.GG population. They are not labeled editorial Best in Slot.", 610, {1, 0.75, 0.35})
        for _, group in ipairs(domain.groups or {}) do
            local entries = group.entries or {}
            local limit = (group.slot == "Trinkets" or group.slot == "Crafted Items") and math.min(3, #entries) or math.min(1, #entries)
            for index = 1, limit do
                local item = entries[index]
                local rowLabel = tostring(group.slot or "Slot")
                if limit > 1 then rowLabel = rowLabel .. " #" .. tostring(index) end
                local detail = tostring(item.popularity or "")
                if item.sample then detail = detail .. (detail ~= "" and " | " or "") .. tostring(item.sample) end
                y = AddItemRow(content, y, rowLabel, item, detail, true)
            end
        end
    end
    y = AddCopyButton(content, y + 4, "Copy Source URL", domain.sourceURL)
    return y
end

local function InferConsumableLabel(item)
    local name = string.lower(tostring(item and item.name or ""))
    if string.find(name, "flask", 1, true) then return "Flask" end
    if string.find(name, "health potion", 1, true) then return "Health Potion" end
    if string.find(name, "potion", 1, true) then return "Combat Potion" end
    if string.find(name, "augment rune", 1, true) then return "Augment Rune" end
    if string.find(name, "oil", 1, true) or string.find(name, "whetstone", 1, true) or string.find(name, "weightstone", 1, true) then return "Weapon Buff" end
    if string.find(name, "feast", 1, true) or string.find(name, "celebration", 1, true) or string.find(name, "parade", 1, true) then return "Feast" end
    if string.find(name, "food", 1, true) or string.find(name, "roast", 1, true) or string.find(name, "bento", 1, true) then return "Food" end
    return "Consumable"
end

local function RenderMultiSourceConsumables(content, y, sourceID, domain, source, context, patch)
    y = AddHeading(content, y, "Consumables")
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    for _, item in ipairs(domain.items or {}) do
        local label = InferConsumableLabel(item)
        if item.kind == "item" then
            y = AddItemRow(content, y, label, item, "Source-listed recommendation", false)
        elseif item.kind == "spell" then
            y = AddItemRow(content, y, label, { spellID = item.id, name = item.name }, "Source-listed recommendation", false)
        end
    end
    y = AddCopyButton(content, y + 4, "Copy Source URL", domain.sourceURL)
    return y
end

local function RenderMultiSourceEnchants(content, y, sourceID, domain, source, context, patch)
    y = AddHeading(content, y, "Enchants & Gems")
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    if sourceID == "icy-veins" then
        y = AddHeading(content, y + 3, "Enchants")
        for _, row in ipairs(domain.rows or {}) do
            for _, item in ipairs(row.items or {}) do
                local rowLabel = row.slot or "Enchant"
                local detail = "Editorial recommendation"
                if item.tier and item.tier ~= "" then
                    rowLabel = rowLabel .. " (" .. tostring(item.tier) .. ")"
                    detail = tostring(item.tier) .. " editorial recommendation"
                end
                y = AddItemRow(content, y, rowLabel, item, detail, false)
            end
        end
        y = AddHeading(content, y + 3, "Gems")
        for _, item in ipairs(domain.gems or {}) do
            y = AddItemRow(content, y, "Gem", item, "Editorial recommendation", false)
        end
    else
        y = AddUggMetrics(content, y, domain.metrics)
        y = AddHeading(content, y + 3, "Most Popular Enchants")
        for _, item in ipairs(domain.bestEnchants or {}) do
            y = AddItemRow(content, y, item.slot or "Enchant", item, "Observed U.GG selection", false)
        end
        y = AddHeading(content, y + 3, "Most Popular Gems")
        for index, item in ipairs(domain.gems or {}) do
            local detail = tostring(item.popularity or "")
            if item.sample then detail = detail .. (detail ~= "" and " | " or "") .. tostring(item.sample) end
            y = AddItemRow(content, y, "Gem #" .. tostring(index), item, detail, false)
        end
    end
    y = AddCopyButton(content, y + 4, "Copy Source URL", domain.sourceURL)
    return y
end

local function RenderMultiSourceStats(content, y, sourceID, domain, source, context, patch)
    y = AddHeading(content, y, "Stat Priority")
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    if sourceID == "icy-veins" then
        for index, variant in ipairs(domain.variants or {}) do
            local label = variant.label or ("Variant " .. index)
            if #((domain.variants or {})) > 1 or string.lower(label) ~= "stat priority" then
                y = AddParagraph(content, y + 2, label, 610, {1, 0.82, 0.35})
            end
            y = AddParagraph(content, y, FormatSourcePriority(variant.stats, variant.relations), 610, {0.35, 1, 0.65})
        end
    else
        y = AddUggMetrics(content, y, domain.metrics)
        y = AddParagraph(content, y + 2, table.concat(domain.priority or {}, "  >  "), 610, {0.35, 1, 0.65})
        y = AddParagraph(content, y + 2, "Observed U.GG top-player stat priority for the selected content context. This is descriptive player data, not an editorial item-weight recommendation.", 610, {0.75, 0.82, 0.9})
    end
    y = AddCopyButton(content, y + 4, "Copy Source URL", domain.sourceURL)
    return y
end

local function AddRotationSectionSummaryRow(content, y, index, section)
    local row = AddElement(content, CreateFrame("Frame", nil, content))
    row:SetSize(610, 42)
    row:SetPoint("TOPLEFT", 4, -y)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, (index or 1) % 2 == 0 and 0.035 or 0.06)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

    local number = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    number:SetPoint("LEFT", icon, "RIGHT", 8, 7)
    number:SetWidth(28)
    number:SetJustifyH("RIGHT")
    number:SetText(tostring(index or "") .. ".")
    number:SetTextColor(0.35, 0.85, 1)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("LEFT", number, "RIGHT", 8, 7)
    name:SetWidth(500)
    name:SetJustifyH("LEFT")
    name:SetText(tostring(section.label or "Rotation section"))

    local detail = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    detail:SetPoint("LEFT", number, "RIGHT", 8, -10)
    detail:SetWidth(500)
    detail:SetJustifyH("LEFT")
    local count = tonumber(section.stepCount or 0) or 0
    detail:SetText(count > 0 and (tostring(count) .. " structured priority step(s) captured") or "Source section captured")
    detail:SetTextColor(0.65, 0.65, 0.65)

    return y + 46
end

local function FindIcyRotationPreset(domain, key)
    for _, preset in ipairs(domain.presets or {}) do
        if preset.key == key then return preset end
    end
    return nil
end

local function GetSelectedIcyRotationPreset(specID, domain)
    local presets = domain.presets or {}
    if #presets == 0 then return nil end
    AzerothGuidebookDB.icyRotationPresets = AzerothGuidebookDB.icyRotationPresets or {}
    local key = AzerothGuidebookDB.icyRotationPresets[specID] or domain.defaultPresetKey or presets[1].key
    local selected = FindIcyRotationPreset(domain, key)
    if not selected then
        selected = FindIcyRotationPreset(domain, domain.defaultPresetKey) or presets[1]
        key = selected and selected.key or nil
    end
    if key then AzerothGuidebookDB.icyRotationPresets[specID] = key end
    return selected
end

local function IcyRotationPresetButtonLabel(preset, selected)
    local label = tostring(preset.label or "Context")
    if preset.recommended == true and not string.find(string.lower(label), "best", 1, true) then
        label = label .. " [Best]"
    end
    if selected then label = label .. " [Selected]" end
    return label
end

local function SelectIcyRotationHero(specID, domain, hero)
    local fallback
    for _, preset in ipairs(domain.presets or {}) do
        if preset.hero == hero then
            fallback = fallback or preset
            if preset.recommended == true then
                AzerothGuidebookDB.icyRotationPresets[specID] = preset.key
                return
            end
        end
    end
    if fallback then AzerothGuidebookDB.icyRotationPresets[specID] = fallback.key end
end

local function RenderRichIcyRotation(content, y, specID, domain, source, context, patch)
    y = AddHeading(content, y, "Rotation & Cooldowns")
    y = AddMultiSourceHeader(content, y, "icy-veins", source, domain, context, patch)
    y = AddParagraph(content, y, "Reviewed Icy Veins priority steps are shown directly from the source's structured rotation lists. Hero/build switches preserve the source-declared preset visibility rules; hidden optional steps are not blended into another preset.", 610, {0.65, 0.8, 1})

    local selected = GetSelectedIcyRotationPreset(specID, domain)
    if not selected then
        y = AddParagraph(content, y + 4, "No reviewed structured Icy Veins rotation preset is available.", 610, {1, 0.55, 0.35})
        y = AddCopyButton(content, y + 4, "Copy Rotation Guide URL", domain.sourceURL)
        return y
    end

    local heroes = {}
    local seenHeroes = {}
    for _, preset in ipairs(domain.presets or {}) do
        local hero = tostring(preset.hero or "Source Context")
        if not seenHeroes[hero] then
            seenHeroes[hero] = true
            table.insert(heroes, hero)
        end
    end

    if #heroes > 1 then
        y = AddParagraph(content, y + 2, "Hero / source context", 610, {1, 0.82, 0.35})
        y = AddParagraph(content, y, "Current hero/source: " .. tostring(selected.hero or "Source Context"), 610, {0.55, 0.9, 1})
        local columns, buttonWidth, gap, rowHeight = 2, 298, 8, 30
        local rowCount = math.ceil(#heroes / columns)
        local baseY = y
        for index, hero in ipairs(heroes) do
            local capturedHero = hero
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local isSelected = tostring(selected.hero or "") == capturedHero
            AddActionButton(content, 4 + column * (buttonWidth + gap), baseY + row * rowHeight, buttonWidth, isSelected and (capturedHero .. " [Selected]") or capturedHero, function()
                AzerothGuidebookDB.icyRotationPresets = AzerothGuidebookDB.icyRotationPresets or {}
                SelectIcyRotationHero(specID, domain, capturedHero)
                AGB:RenderTab("Rotation")
            end, not isSelected)
        end
        y = y + rowCount * rowHeight + 4
    end

    local heroPresets = {}
    local longestLabel = 0
    for _, preset in ipairs(domain.presets or {}) do
        if tostring(preset.hero or "") == tostring(selected.hero or "") then
            table.insert(heroPresets, preset)
            longestLabel = math.max(longestLabel, string.len(tostring(preset.label or "")))
        end
    end
    if #heroPresets > 1 then
        y = AddParagraph(content, y + 2, "Build context", 610, {1, 0.82, 0.35})
        y = AddParagraph(content, y, "Current build: " .. tostring(selected.label or "Default"), 610, {0.55, 0.9, 1})
        local columns = longestLabel > 30 and 1 or 2
        local buttonWidth = columns == 1 and 604 or 298
        local gap, rowHeight = 8, 30
        local rowCount = math.ceil(#heroPresets / columns)
        local baseY = y
        for index, preset in ipairs(heroPresets) do
            local capturedKey = preset.key
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local isSelected = selected.key == capturedKey
            AddActionButton(content, 4 + column * (buttonWidth + gap), baseY + row * rowHeight, buttonWidth, IcyRotationPresetButtonLabel(preset, isSelected), function()
                AzerothGuidebookDB.icyRotationPresets = AzerothGuidebookDB.icyRotationPresets or {}
                AzerothGuidebookDB.icyRotationPresets[specID] = capturedKey
                AGB:RenderTab("Rotation")
            end, not isSelected)
        end
        y = y + rowCount * rowHeight + 4
    elseif #heroPresets == 1 then
        y = AddParagraph(content, y + 2, "Build context: " .. tostring(selected.label or "Default"), 610, {0.55, 0.9, 1})
    end

    local lastBlockLabel
    local rendered = false
    for _, block in ipairs(selected.blocks or {}) do
        local blockLabel = tostring(block.blockLabel or "Rotation")
        if blockLabel ~= lastBlockLabel then
            y = AddHeading(content, y + (rendered and 6 or 2), blockLabel)
            lastBlockLabel = blockLabel
            rendered = true
        end
        local listLabel = tostring(block.label or "")
        if listLabel ~= "" and string.lower(listLabel) ~= string.lower(blockLabel) then
            y = AddParagraph(content, y, listLabel, 610, {1, 0.82, 0.35})
        end
        if block.note and tostring(block.note) ~= "" then
            y = AddParagraph(content, y, tostring(block.note), 610, {0.72, 0.82, 0.95})
        end
        for actionIndex, action in ipairs(block.actions or {}) do
            y = AddRotationActionRow(content, y, actionIndex, action, block.ordered == false and "•" or nil)
        end
    end
    if not rendered then
        y = AddParagraph(content, y + 4, "No structured source actions were captured for this Icy Veins preset.", 610, {1, 0.55, 0.35})
    end
    y = AddCopyButton(content, y + 4, "Copy Rotation Guide URL", domain.sourceURL)
    return y
end

local function RenderMultiSourceRotation(content, y, specID, sourceID, domain, source, context, patch)
    if sourceID == "icy-veins" and domain.presets and #domain.presets > 0 then
        return RenderRichIcyRotation(content, y, specID, domain, source, context, patch)
    end
    y = AddHeading(content, y, "Rotation & Cooldowns")
    y = AddMultiSourceHeader(content, y, sourceID, source, domain, context, patch)
    y = AddParagraph(content, y, "Concise source-listed rotation sections are presented in the same guide layout as Wowhead. The reviewed capture currently stores section names and structured step counts; open the source guide for the full prose and priority details.", 610, {0.65, 0.8, 1})
    for index, section in ipairs(domain.sections or {}) do
        y = AddRotationSectionSummaryRow(content, y, index, section)
    end
    y = AddCopyButton(content, y + 4, "Copy Rotation Guide URL", domain.sourceURL)
    return y
end

local function RenderMultiSourceTab(content, y, tabName, specID, sourceID, data)
    local contextKey = sourceID == "ugg" and AGB:GetGuideSourceContext(specID) or "general"
    local domain, source, context = AGB:GetMultiSourceDomain(specID, sourceID, tabName, sourceID == "ugg" and contextKey or nil)
    if not domain or not source then
        y = AddHeading(content, y, "Source data unavailable")
        y = AddParagraph(content, y, "This source does not have a reviewed " .. tostring(tabName) .. " dataset for the selected specialization/context. Nothing is borrowed from another source.", 610, {1, 0.55, 0.35})
        return y
    end
    local patch = data and data.patch or "12.1.0"
    if tabName == "Talents" then return RenderMultiSourceTalents(content, y, specID, sourceID, domain, source, context, contextKey, patch) end
    if tabName == "BiS" then return RenderMultiSourceBiS(content, y, sourceID, domain, source, context, patch) end
    if tabName == "Consumables" then return RenderMultiSourceConsumables(content, y, sourceID, domain, source, context, patch) end
    if tabName == "Enchants & Gems" then return RenderMultiSourceEnchants(content, y, sourceID, domain, source, context, patch) end
    if tabName == "Stats" then return RenderMultiSourceStats(content, y, sourceID, domain, source, context, patch) end
    if tabName == "Rotation" then return RenderMultiSourceRotation(content, y, specID, sourceID, domain, source, context, patch) end
    return y
end

function AGB:RenderNoData(data, classFile, specID)
    local content = self.UI.content
    ClearContent(content)
    local y = 8
    y = AddHeading(content, y, "No bundled guide data for this spec yet")
    local _, _, specName = self:GetPlayerContext()
    y = AddParagraph(content, y, "My Character provides the live audit while retaining the validated Talent, Best-in-Slot, Consumables, Enchants & Gems, and Stats datasets. Rotation is now enabled for all 40 Retail specializations. Your current specialization is " .. (specName or "unknown") .. ". Use Browse Guides above to open any bundled class/spec guide.")
    y = AddParagraph(content, y, "All current Retail specializations are available in Browse Guides. Talents, BiS, Consumables, and Enchants/Gems are complete across all 40 Retail specializations. Stats are complete across all 40 Retail specializations, and reviewed Rotation & Cooldowns are now complete across all 40 Retail specializations.", 610, {0.65, 0.8, 1})
    content:SetHeight(y + 20)
end

local function IsTabAvailableForData(tabName, data)
    if tabName == "My Character" then
        local playerClassFile, playerSpecID = AGB:GetPlayerContext()
        return playerClassFile ~= nil and playerSpecID ~= nil and AGB.Data[playerClassFile] ~= nil and AGB.Data[playerClassFile][playerSpecID] ~= nil
    end
    if not data then return false end
    if tabName == "Talents" then return data.talents ~= nil end
    if tabName == "Rotation" then return data.rotation ~= nil end
    if tabName == "BiS" then return data.bis ~= nil end
    if tabName == "Consumables" then return data.consumables ~= nil end
    if tabName == "Enchants & Gems" then return data.enchants ~= nil end
    if tabName == "Stats" then return data.stats ~= nil or data.statPriority ~= nil or data.statNote ~= nil end
    if tabName == "Sources" then return data.sources ~= nil and #data.sources > 0 end
    return false
end

function AGB:RenderTab(tabName)
    local pendingMyCharacterScrollY = nil
    if tabName == "My Character" and self._pendingMyCharacterScrollY ~= nil then
        pendingMyCharacterScrollY = self._pendingMyCharacterScrollY
        self._pendingMyCharacterScrollY = nil
    end

    local data, classFile, specID = self:GetActiveData()
    self._guideFocusScrollY = nil
    if not data then
        self:RenderNoData(data, classFile, specID)
        return
    end

    if not IsTabAvailableForData(tabName, data) then
        tabName = "Talents"
        if AzerothGuidebookDB then AzerothGuidebookDB.lastTab = tabName end
    end

    for name, b in pairs(self.UI.tabs) do
        b:SetEnabled(IsTabAvailableForData(name, data) and name ~= tabName)
    end

    local content = self.UI.content
    ClearContent(content)
    self.UI.scroll:SetVerticalScroll(0)
    local y = 8

    local profileSpecID = specID
    if tabName == "My Character" then
        local _, playerSpecID = self:GetPlayerContext()
        profileSpecID = playerSpecID or specID
    end
    y = AddActivityProfileSelector(content, y, profileSpecID, tabName)

    if tabName ~= "My Character" and tabName ~= "Sources" then
        local selectedSource
        y, selectedSource = AddSourceSelector(content, y, specID, tabName)
        if selectedSource ~= "wowhead" then
            y = RenderMultiSourceTab(content, y, tabName, specID, selectedSource, data)
            content:SetHeight(math.max(y + 24, 460))
            ApplyPendingGuideFocusScroll(tabName)
            return
        end
    end

    if tabName == "My Character" then
        local playerClassFile, playerSpecID = self:GetPlayerContext()
        local playerData = playerClassFile and playerSpecID and self.Data[playerClassFile] and self.Data[playerClassFile][playerSpecID] or nil
        if playerData and self.UI.subtitle then
            self.UI.subtitle:SetText(playerData.className .. " - " .. playerData.specName .. " | My Character | Data refreshed " .. self.DATA_REFRESHED)
        end
        local audit = AGB:GetCharacterAudit()
        if not audit then
            y = AddHeading(content, y, "My Character")
            y = AddParagraph(content, y, "No bundled guide data is available for your active specialization.", 610, {1, 0.55, 0.35})
        else
            local characterData = audit.data
            y = AddHeading(content, y, "My Character - " .. tostring(characterData.specName) .. " " .. tostring(characterData.className))
            y = AddParagraph(content, y, "Live read-only audit of this character against the currently selected reviewed source for each guide domain. No score is assigned; each result is shown as a factual match, owned item, missing/not-owned item, or not-yet-verifiable state.", 610, {0.75, 0.88, 1})
            if audit.playerLevel and audit.guideTargetLevel then
                y = AddParagraph(content, y + 2, "Character level: " .. tostring(audit.playerLevel) .. " | Guide target level: " .. tostring(audit.guideTargetLevel), 610, {0.65, 0.8, 1})
            end
            if audit.belowGuideTarget then
                y = AddParagraph(content, y + 2, "This character is below the guide's target level. Endgame talent, gear, enchant, and stat references are informational until level " .. tostring(audit.guideTargetLevel) .. "; inventory ownership, bag counts, equipped enchant detection, and gem detection remain factual.", 610, {1, 0.65, 0.3})
            end

            local validMyCharacterViews = {
                ["Action Plan"] = true,
                Overview = true,
                Talents = true,
                Gear = true,
                ["Enchants & Gems"] = true,
                Consumables = true,
                Stats = true,
                ["All Details"] = true,
                ["Issues: Talents"] = true,
                ["Issues: Gear"] = true,
                ["Issues: Enchants & Gems"] = true,
                ["Issues: Consumables"] = true,
            }
            local myCharacterView = self.myCharacterView or "Action Plan"
            if not validMyCharacterViews[myCharacterView] then
                myCharacterView = "Action Plan"
                self.myCharacterView = myCharacterView
            end

            local talentOverview = audit.talents or {}
            local talentOverviewText = tostring(talentOverview.status or "Unavailable")
            if talentOverview.targetLabel then talentOverviewText = talentOverviewText .. " | " .. tostring(talentOverview.targetLabel) end
            if talentOverview.sourceLabel then talentOverviewText = talentOverviewText .. " | Source: " .. tostring(talentOverview.sourceLabel) end
            if talentOverview.contextLabel then talentOverviewText = talentOverviewText .. " | Context: " .. tostring(talentOverview.contextLabel) end

            local gearOverview = audit.bis or {}
            local gearCounts = gearOverview.counts or { equipped = 0, owned = 0, missing = 0 }
            local gearMissingLabel = gearOverview.observed and " not owned" or " missing"
            local gearOverviewText = tostring(gearCounts.equipped or 0) .. " equipped | " .. tostring(gearCounts.owned or 0) .. " owned | " .. tostring(gearCounts.missing or 0) .. gearMissingLabel
            if gearOverview.sourceLabel then gearOverviewText = gearOverviewText .. " | Source: " .. tostring(gearOverview.sourceLabel) end
            if gearOverview.contextLabel then gearOverviewText = gearOverviewText .. " | Context: " .. tostring(gearOverview.contextLabel) end

            local enchantOverview = audit.enchants or {}
            local enchantMatched, enchantDifferent, enchantMissing, enchantNoItem, enchantOther = 0, 0, 0, 0, 0
            for _, entry in ipairs(enchantOverview) do
                if entry.status == "Recommended enchant equipped" or entry.status == "Recommended enchant detected" then
                    enchantMatched = enchantMatched + 1
                elseif entry.status == "Different enchant detected" then
                    enchantDifferent = enchantDifferent + 1
                elseif entry.status == "No enchant detected" then
                    enchantMissing = enchantMissing + 1
                elseif entry.status == "No item equipped" then
                    enchantNoItem = enchantNoItem + 1
                else
                    enchantOther = enchantOther + 1
                end
            end
            local gemOverview = audit.gems or {}
            local gemMatched = 0
            for _, gem in ipairs(gemOverview) do
                if (gem.count or 0) > 0 then gemMatched = gemMatched + 1 end
            end
            local enchantOverviewText = tostring(enchantMatched) .. " enchant match(es) | " .. tostring(enchantDifferent) .. " different | " .. tostring(enchantMissing) .. " no enchant"
            if enchantOther > 0 then enchantOverviewText = enchantOverviewText .. " | " .. tostring(enchantOther) .. " other" end
            enchantOverviewText = enchantOverviewText .. " | Gems: " .. tostring(gemMatched) .. "/" .. tostring(#gemOverview) .. " source option(s) present"
            if enchantOverview.sourceLabel then enchantOverviewText = enchantOverviewText .. " | Source: " .. tostring(enchantOverview.sourceLabel) end
            if enchantOverview.contextLabel then enchantOverviewText = enchantOverviewText .. " | Context: " .. tostring(enchantOverview.contextLabel) end

            local consumableOverview = audit.consumables or {}
            local consumableOwned, consumableMissing = 0, 0
            for _, item in ipairs(consumableOverview) do
                if (item.count or 0) > 0 then consumableOwned = consumableOwned + 1 else consumableMissing = consumableMissing + 1 end
            end
            local consumableOverviewText = tostring(consumableOwned) .. " source item(s) owned | " .. tostring(consumableMissing) .. " absent"
            if consumableOverview.sourceLabel then consumableOverviewText = consumableOverviewText .. " | Source: " .. tostring(consumableOverview.sourceLabel) end
            if consumableOverview.contextLabel then consumableOverviewText = consumableOverviewText .. " | Context: " .. tostring(consumableOverview.contextLabel) end

            local statsOverview = audit.stats or {}
            local statsGuideOverview = audit.statsGuide or {}
            local rotationGuideOverview = audit.rotationGuide or {}
            local function OverviewPercent(value) return value and string.format("%.1f%%", value) or "?" end
            local statsOverviewText = "Crit " .. OverviewPercent(statsOverview.crit) .. " | Haste " .. OverviewPercent(statsOverview.haste) .. " | Mastery " .. OverviewPercent(statsOverview.mastery) .. " | Vers " .. OverviewPercent(statsOverview.versatility)
            if statsGuideOverview.sourceLabel then statsOverviewText = statsOverviewText .. " | Source: " .. tostring(statsGuideOverview.sourceLabel) end
            if statsGuideOverview.contextLabel then statsOverviewText = statsOverviewText .. " | Context: " .. tostring(statsGuideOverview.contextLabel) end

            y = AddHeading(content, y + 6, "Audit Overview")
            y = AddParagraph(content, y, "Talents: " .. talentOverviewText, 610, talentOverview.status == "Exact match" and {0.35, 1, 0.65} or {0.75, 0.88, 1})
            y = AddParagraph(content, y, (gearOverview.sectionLabel or "Gear") .. ": " .. gearOverviewText, 610, {0.75, 0.88, 1})
            y = AddParagraph(content, y, "Enchants & Gems: " .. enchantOverviewText, 610, {0.75, 0.88, 1})
            y = AddParagraph(content, y, "Consumables: " .. consumableOverviewText, 610, {0.75, 0.88, 1})
            y = AddParagraph(content, y, "Stats: " .. statsOverviewText, 610, {0.75, 0.88, 1})

            local function SelectMyCharacterView(nextView)
                local preservedScrollY = 0
                if AGB.UI and AGB.UI.scroll and AGB.UI.scroll.GetVerticalScroll then
                    preservedScrollY = AGB.UI.scroll:GetVerticalScroll() or 0
                end
                AGB.myCharacterView = nextView
                AGB._pendingMyCharacterScrollY = math.max(0, preservedScrollY)
                AGB:RenderTab("My Character")
            end

            local talentIssueCount = (talentOverview.status == "Different") and tonumber(talentOverview.differences or 0) or 0
            local gearIssueCount = tonumber(gearCounts.missing or 0) or 0
            local enchantIssueCount = enchantDifferent + enchantMissing + enchantNoItem
            local attentionIssueCount = talentIssueCount + gearIssueCount + enchantIssueCount + consumableMissing
            local actionPlan = AGB:GetCharacterActionPlan(audit)

            local function OpenMyCharacterGuide(tabName, focusTarget)
                AzerothGuidebookDB.lastTab = tabName
                AzerothGuidebookDB.lastGuideTab = tabName
                AGB.previewSpecID = nil
                if focusTarget then
                    focusTarget.tabName = tabName
                    AGB._pendingGuideFocus = focusTarget
                else
                    AGB._pendingGuideFocus = nil
                end
                AGB:RefreshUI()
            end

            local function OpenMyCharacterTalentComparison(talentAudit)
                local comparison = talentAudit and talentAudit.comparison
                if not comparison then
                    OpenMyCharacterGuide("Talents")
                    return
                end

                AzerothGuidebookDB.lastTab = "Talents"
                AzerothGuidebookDB.lastGuideTab = "Talents"
                AGB.previewSpecID = nil
                AGB._pendingGuideFocus = nil
                AGB.talentDifferenceFocusIndex = nil
                AGB.talentDifferenceFocusNodeID = nil
                AGB.talentDifferenceFocusSection = nil

                if talentAudit.sourceID and talentAudit.sourceID ~= "wowhead" then
                    AGB.customTalentPreview = nil
                    AGB.talentComparisonTarget = nil
                    AGB.talentComparisonLive = nil
                    AGB.talentComparison = nil
                    AGB.multiSourceTalentPreview = {
                        specID = audit.specID,
                        sourceID = talentAudit.sourceID,
                        contextKey = talentAudit.contextKey or "general",
                        buildIndex = tonumber(talentAudit.variantKey) or 1,
                        mode = "compare",
                        target = comparison.target,
                        current = comparison.current,
                        comparison = comparison,
                    }
                else
                    AGB.multiSourceTalentPreview = nil
                    AGB.customTalentPreview = comparison.target
                    AGB.talentComparisonTarget = comparison.target
                    AGB.talentComparisonLive = comparison.current
                    AGB.talentComparison = comparison
                    AGB.talentCompareMode = "compare"
                end
                AGB:RefreshUI()
            end
            local function GuideJumpLabel(domainLabel, domainAudit)
                local sourceLabel = domainAudit and domainAudit.sourceLabel
                if sourceLabel and sourceLabel ~= "" then
                    return domainLabel .. ": " .. tostring(sourceLabel)
                end
                return domainLabel
            end

            y = AddHeading(content, y + 4, "Open Selected Guide")
            local guideJumpY = y
            AddActionButton(content, 4, guideJumpY, 190, GuideJumpLabel("Talents", talentOverview), function() OpenMyCharacterGuide("Talents") end, true)
            AddActionButton(content, 198, guideJumpY, 190, GuideJumpLabel("Gear", gearOverview), function() OpenMyCharacterGuide("BiS") end, true)
            AddActionButton(content, 392, guideJumpY, 190, GuideJumpLabel("Enchants", enchantOverview), function() OpenMyCharacterGuide("Enchants & Gems") end, true)
            AddActionButton(content, 4, guideJumpY + 28, 190, GuideJumpLabel("Consumables", consumableOverview), function() OpenMyCharacterGuide("Consumables") end, true)
            AddActionButton(content, 198, guideJumpY + 28, 190, GuideJumpLabel("Stats", statsGuideOverview), function() OpenMyCharacterGuide("Stats") end, true)
            AddActionButton(content, 392, guideJumpY + 28, 190, GuideJumpLabel("Rotation", rotationGuideOverview), function() OpenMyCharacterGuide("Rotation") end, true)
            y = y + 62

            y = AddHeading(content, y + 4, "View Details")
            local function AddMyCharacterViewButton(x, rowY, width, key, label)
                local selected = myCharacterView == key
                AddActionButton(content, x, rowY, width, selected and (label .. " [Selected]") or label, function()
                    SelectMyCharacterView(key)
                end, not selected)
            end
            local viewRowY = y
            AddMyCharacterViewButton(4, viewRowY, 145, "Action Plan", "Action Plan")
            AddMyCharacterViewButton(153, viewRowY, 145, "Overview", "Overview")
            AddMyCharacterViewButton(302, viewRowY, 110, "Talents", "Talents")
            AddMyCharacterViewButton(416, viewRowY, 115, "Gear", "Gear")
            AddMyCharacterViewButton(4, viewRowY + 28, 190, "Enchants & Gems", "Enchants & Gems")
            AddMyCharacterViewButton(198, viewRowY + 28, 145, "Consumables", "Consumables")
            AddMyCharacterViewButton(347, viewRowY + 28, 110, "Stats", "Stats")
            AddMyCharacterViewButton(461, viewRowY + 28, 145, "All Details", "All Details")
            y = y + 62

            if myCharacterView ~= "Action Plan" then
            y = AddHeading(content, y + 4, "Needs Attention")
            if audit.belowGuideTarget then
                y = AddParagraph(content, y, "Endgame issue focus is deferred until level " .. tostring(audit.guideTargetLevel) .. ". Talent, gear, enchant, and consumable guide gaps remain informational while this character is below the guide target; factual audit details remain available below.", 610, {0.65, 0.8, 1})
            elseif attentionIssueCount == 0 then
                y = AddParagraph(content, y, "No actionable issues detected in the auditable guide domains. Stats remain informational and are not scored.", 610, {0.35, 1, 0.65})
            else
                local attentionButtons = {}
                if talentIssueCount > 0 then
                    table.insert(attentionButtons, { key = "Issues: Talents", label = "Talents: " .. tostring(talentIssueCount) .. " difference(s)" })
                end
                if gearIssueCount > 0 then
                    local issueWord = gearOverview.observed and " not owned (observed)" or " missing"
                    table.insert(attentionButtons, { key = "Issues: Gear", label = "Gear: " .. tostring(gearIssueCount) .. issueWord })
                end
                if enchantIssueCount > 0 then
                    local label = "Enchants: " .. tostring(enchantDifferent) .. " different | " .. tostring(enchantMissing + enchantNoItem) .. " missing"
                    table.insert(attentionButtons, { key = "Issues: Enchants & Gems", label = label })
                end
                if consumableMissing > 0 then
                    table.insert(attentionButtons, { key = "Issues: Consumables", label = "Consumables: " .. tostring(consumableMissing) .. " absent" })
                end
                local attentionY = y
                for index, issue in ipairs(attentionButtons) do
                    local column = (index - 1) % 2
                    local row = math.floor((index - 1) / 2)
                    local issueKey = issue.key
                    local issueLabel = issue.label
                    local selected = myCharacterView == issueKey
                    AddActionButton(content, 4 + (column * 289), attentionY + (row * 28), 285, selected and (issueLabel .. " [Selected]") or issueLabel, function()
                        SelectMyCharacterView(issueKey)
                    end, not selected)
                end
                y = y + (math.ceil(#attentionButtons / 2) * 28)
                y = AddParagraph(content, y + 2, "Issue views hide successful rows only; U.GG observed gear gaps remain descriptive rather than editorial recommendations, and Stats are never classified as issues.", 610, {0.65, 0.8, 1})
            end
            end

            if myCharacterView == "Action Plan" then
                y = AddHeading(content, y + 6, "Character Action Plan")
                y = AddParagraph(content, y, "A consolidated to-do list built only from the guide source and context currently selected for each domain. Completed rows are hidden by default; the plan updates automatically when talents, equipment, enchants, bags, or character stats change.", 610, {0.75, 0.88, 1})

                if actionPlan.deferred then
                    y = AddParagraph(content, y + 2, "Endgame adjustment actions are deferred until level " .. tostring(audit.guideTargetLevel or "?") .. ". Factual ownership/detection details remain available in the normal audit views.", 610, {1, 0.65, 0.3})
                elseif (actionPlan.remaining or 0) == 0 then
                    y = AddParagraph(content, y + 2, "No remaining character adjustments were detected in the auditable guide domains.", 610, {0.35, 1, 0.65})
                else
                    local domainParts = {}
                    for _, domainName in ipairs({"Talents", "Gear", "Enchants", "Consumables"}) do
                        local count = actionPlan.domainRemaining and actionPlan.domainRemaining[domainName] or 0
                        if count and count > 0 then table.insert(domainParts, domainName .. " " .. tostring(count)) end
                    end
                    local domainSummary = #domainParts > 0 and (" | " .. table.concat(domainParts, " | ")) or ""
                    y = AddParagraph(content, y + 2, tostring(actionPlan.remaining or 0) .. " adjustment(s) remaining across " .. tostring(actionPlan.remainingDomains or 0) .. " domain(s)" .. domainSummary, 610, {1, 0.75, 0.35})
                end

                local showCompleted = AzerothGuidebookDB and AzerothGuidebookDB.myCharacterActionPlanShowCompleted == true
                local toggleLabel = showCompleted and ("Hide Completed (" .. tostring(actionPlan.completed or 0) .. ")") or ("Show Completed (" .. tostring(actionPlan.completed or 0) .. ")")
                AddActionButton(content, 4, y + 2, 190, toggleLabel, function()
                    local preservedScrollY = 0
                    if AGB.UI and AGB.UI.scroll and AGB.UI.scroll.GetVerticalScroll then
                        preservedScrollY = AGB.UI.scroll:GetVerticalScroll() or 0
                    end
                    AzerothGuidebookDB.myCharacterActionPlanShowCompleted = not showCompleted
                    AGB._pendingMyCharacterScrollY = math.max(0, preservedScrollY)
                    AGB:RenderTab("My Character")
                end, true)
                y = y + 32

                local function OpenActionPlanRow(row)
                    if not row then return end
                    if row.action == "talentCompare" then
                        OpenMyCharacterTalentComparison(talentOverview)
                    elseif row.action == "talent" then
                        OpenMyCharacterGuide("Talents")
                    elseif row.tabName then
                        OpenMyCharacterGuide(row.tabName, row.focus)
                    end
                end

                local function ActionPlanButtonLabel(row)
                    if not row then return "View in Guide" end
                    if row.action == "talentCompare" then return "Open Comparison" end
                    if row.tabName == "Rotation" then return "Open Rotation" end
                    if row.tabName == "Stats" then return "Open Stats" end
                    if row.tabName == "Talents" then return "Open Talents" end
                    return "View in Guide"
                end

                if not actionPlan.deferred then
                    y = AddHeading(content, y + 2, "Remaining")
                    if #(actionPlan.remainingRows or {}) == 0 then
                        y = AddParagraph(content, y, "Nothing remains in the auditable action categories.", 610, {0.35, 1, 0.65})
                    else
                        for _, row in ipairs(actionPlan.remainingRows or {}) do
                            local planRow = row
                            y = AddIssueActionRow(content, y, planRow.text, ActionPlanButtonLabel(planRow), function() OpenActionPlanRow(planRow) end, {1, 0.75, 0.35})
                        end
                    end
                end

                if showCompleted and #(actionPlan.completedRows or {}) > 0 then
                    y = AddHeading(content, y + 4, "Completed")
                    for _, row in ipairs(actionPlan.completedRows or {}) do
                        local planRow = row
                        y = AddIssueActionRow(content, y, planRow.text, ActionPlanButtonLabel(planRow), function() OpenActionPlanRow(planRow) end, {0.35, 1, 0.65})
                    end
                end

                y = AddHeading(content, y + 4, "Guide References")
                y = AddParagraph(content, y, "Stats and Rotation are reference guidance rather than pass/fail checks. Gem alternatives and any fail-closed/unverifiable rows are also kept informational instead of being counted as required adjustments.", 610, {0.65, 0.8, 1})
                for _, row in ipairs(actionPlan.referenceRows or {}) do
                    local planRow = row
                    y = AddIssueActionRow(content, y, planRow.text, ActionPlanButtonLabel(planRow), function() OpenActionPlanRow(planRow) end, {0.65, 0.8, 1})
                end
                y = AddParagraph(content, y + 2, "Consumables are grouped by recognizable type: owning any source-listed option completes that category, so alternatives are not incorrectly treated as separate required purchases. Source items with no reliable category are shown individually by name.", 610, {0.65, 0.8, 1})
            end

            if myCharacterView == "Issues: Talents" then
                y = AddHeading(content, y + 6, "Talent Differences")
                local talentAudit = audit.talents or {}
                if audit.belowGuideTarget then
                    y = AddParagraph(content, y, "Talent differences are informational until level " .. tostring(audit.guideTargetLevel) .. ". Use the normal Talents detail view for the partial comparison.", 610, {0.65, 0.8, 1})
                elseif talentAudit.status == "Different" and (talentAudit.differences or 0) > 0 then
                    local issueText = tostring(talentAudit.differences or 0) .. " difference(s) across " .. tostring(talentAudit.compared or 0) .. " compared selections"
                    if talentAudit.targetLabel then issueText = issueText .. " | Guide: " .. tostring(talentAudit.targetLabel) end
                    if talentAudit.sourceLabel then issueText = issueText .. " | Source: " .. tostring(talentAudit.sourceLabel) end
                    if talentAudit.contextLabel then issueText = issueText .. " | Context: " .. tostring(talentAudit.contextLabel) end
                    y = AddParagraph(content, y, issueText, 610, {1, 0.75, 0.35})
                    y = AddParagraph(content, y + 2, "Open the selected source directly in its node-level comparison view.", 610, {0.75, 0.88, 1})
                else
                    y = AddParagraph(content, y, "No current talent differences require attention.", 610, {0.35, 1, 0.65})
                end
                local talentActionLabel = (talentAudit.comparison and not audit.belowGuideTarget) and "Open Comparison" or "Open Talents Guide"
                AddActionButton(content, 4, y + 2, 170, talentActionLabel, function() OpenMyCharacterTalentComparison(talentAudit) end, true)
                y = y + 30
            end

            if myCharacterView == "Issues: Gear" then
                local bisAudit = audit.bis or {}
                y = AddHeading(content, y + 6, bisAudit.observed and "Gear Reference Gaps" or "Missing Gear")
                local issueRows = 0
                if audit.belowGuideTarget then
                    y = AddParagraph(content, y, "Gear gaps are informational until level " .. tostring(audit.guideTargetLevel) .. ".", 610, {0.65, 0.8, 1})
                elseif bisAudit.observed then
                    y = AddParagraph(content, y, "U.GG rows are observed popular gear, not editorial Best in Slot. These rows show only observed items this character does not own.", 610, {1, 0.75, 0.35})
                end
                for _, item in ipairs(bisAudit.items or {}) do
                    if item.status == "Missing" then
                        issueRows = issueRows + 1
                        local displayStatus = bisAudit.observed and "Not owned" or "Missing"
                        local focusItem = item
                        local issueText = tostring(item.slot or "Slot") .. ": " .. tostring(item.name or item.id) .. " - " .. displayStatus
                        y = AddIssueActionRow(content, y, issueText, "View in Guide", function()
                            OpenMyCharacterGuide("BiS", {
                                itemID = focusItem.id,
                                name = focusItem.name,
                                slot = focusItem.slot,
                            })
                        end, {0.68, 0.68, 0.68})
                    end
                end
                if issueRows == 0 then
                    y = AddParagraph(content, y, "No current gear gaps require attention.", 610, {0.35, 1, 0.65})
                end
                AddActionButton(content, 4, y + 2, 165, "Open Gear Guide", function() OpenMyCharacterGuide("BiS") end, true)
                y = y + 30
            end

            if myCharacterView == "Issues: Enchants & Gems" then
                y = AddHeading(content, y + 6, "Enchant Issues")
                local enchantAudit = audit.enchants or {}
                local issueRows = 0
                if audit.belowGuideTarget then
                    y = AddParagraph(content, y, "Enchant guide gaps are informational until level " .. tostring(audit.guideTargetLevel) .. "; detected equipped enchant states remain factual.", 610, {0.65, 0.8, 1})
                end
                for _, entry in ipairs(enchantAudit) do
                    if entry.status == "Different enchant detected" or entry.status == "No enchant detected" or entry.status == "No item equipped" then
                        issueRows = issueRows + 1
                        local effect = (entry.enchantID and entry.enchantID > 0) and (" | effect " .. tostring(entry.enchantID)) or ""
                        local detail = (entry.enchantText and entry.enchantText ~= "") and (" | " .. tostring(entry.enchantText)) or ""
                        local issueEntry = entry
                        local recommendation = (entry.recommendations and entry.recommendations[1]) or nil
                        local issueText = tostring(entry.slot) .. " (slot " .. tostring(entry.slotID) .. "): " .. tostring(entry.status) .. effect .. detail
                        y = AddIssueActionRow(content, y, issueText, "View in Guide", function()
                            OpenMyCharacterGuide("Enchants & Gems", {
                                itemID = recommendation and recommendation.id or nil,
                                spellID = recommendation and recommendation.spellID or nil,
                                name = recommendation and recommendation.name or nil,
                                slot = (recommendation and recommendation.sourceSlot) or issueEntry.slot,
                            })
                        end, {1, 0.55, 0.35})
                    end
                end
                if issueRows == 0 then
                    y = AddParagraph(content, y, "No current enchant issues require attention.", 610, {0.35, 1, 0.65})
                end
                y = AddParagraph(content, y + 2, "Gem source rows are intentionally not classified as missing issues because reviewed gem lists can contain alternatives rather than requirements.", 610, {0.65, 0.8, 1})
                AddActionButton(content, 4, y + 2, 205, "Open Enchants & Gems Guide", function() OpenMyCharacterGuide("Enchants & Gems") end, true)
                y = y + 30
            end

            if myCharacterView == "Issues: Consumables" then
                y = AddHeading(content, y + 6, "Absent Consumables")
                local consumableAudit = audit.consumables or {}
                local issueRows = 0
                if audit.belowGuideTarget then
                    y = AddParagraph(content, y, "Consumable guide gaps are informational until level " .. tostring(audit.guideTargetLevel) .. ".", 610, {0.65, 0.8, 1})
                end
                for _, item in ipairs(consumableAudit) do
                    if (item.count or 0) <= 0 then
                        issueRows = issueRows + 1
                        local focusItem = item
                        local issueText = tostring(item.type or "Consumable") .. ": " .. tostring(item.name or item.id) .. " - missing"
                        y = AddIssueActionRow(content, y, issueText, "View in Guide", function()
                            OpenMyCharacterGuide("Consumables", {
                                itemID = focusItem.id,
                                name = focusItem.name,
                                slot = focusItem.type,
                            })
                        end, {0.68, 0.68, 0.68})
                    end
                end
                if issueRows == 0 then
                    y = AddParagraph(content, y, "No source-listed consumable items are currently absent.", 610, {0.35, 1, 0.65})
                end
                y = AddParagraph(content, y + 2, "Source consumable lists can include alternatives or situational choices; absence is a factual bag check, not a requirement to own every listed item.", 610, {0.65, 0.8, 1})
                AddActionButton(content, 4, y + 2, 190, "Open Consumables Guide", function() OpenMyCharacterGuide("Consumables") end, true)
                y = y + 30
            end

            if myCharacterView == "Talents" or myCharacterView == "All Details" then
            y = AddHeading(content, y + 6, "Talents")
            local talentAudit = audit.talents or {}
            local talentColor = talentAudit.status == "Exact match" and {0.35, 1, 0.65} or ((talentAudit.status == "Different" or talentAudit.status == "Partial comparison") and {1, 0.75, 0.35} or {0.7, 0.7, 0.7})
            local talentText = talentAudit.status or "Unavailable"
            if talentAudit.status == "Partial comparison" then
                talentText = talentText .. " - level " .. tostring(talentAudit.playerLevel or audit.playerLevel or "?") .. " character vs level " .. tostring(talentAudit.guideTargetLevel or audit.guideTargetLevel or "?") .. " guide"
                if talentAudit.differences ~= nil then
                    talentText = talentText .. " | " .. tostring(talentAudit.differences or 0) .. " source-selection difference(s) across " .. tostring(talentAudit.compared or 0) .. " compared selections"
                end
            elseif talentAudit.status == "Different" then
                talentText = talentText .. " - " .. tostring(talentAudit.differences or 0) .. " difference(s) across " .. tostring(talentAudit.compared or 0) .. " compared selections"
            elseif talentAudit.status == "Exact match" then
                talentText = talentText .. " - " .. tostring(talentAudit.compared or 0) .. " compared selections"
            end
            if talentAudit.targetLabel then talentText = talentText .. " | Guide: " .. tostring(talentAudit.targetLabel) end
            if talentAudit.sourceLabel then talentText = talentText .. " | Source: " .. tostring(talentAudit.sourceLabel) end
            if talentAudit.contextLabel then talentText = talentText .. " | Context: " .. tostring(talentAudit.contextLabel) end
            y = AddParagraph(content, y, talentText, 610, talentColor)
            AddActionButton(content, 4, y + 2, 150, "Open Talents Guide", function() OpenMyCharacterGuide("Talents") end, true)
            y = y + 30
            end

            if myCharacterView == "Gear" or myCharacterView == "All Details" then
            local bisAudit = audit.bis or {}
            y = AddHeading(content, y + 4, bisAudit.sectionLabel or "Best in Slot")
            local bc = bisAudit.counts or { equipped = 0, owned = 0, missing = 0 }
            local missingLabel = bisAudit.observed and " not owned" or " missing"
            local gearSummary = tostring(bc.equipped or 0) .. " equipped | " .. tostring(bc.owned or 0) .. " owned in bags | " .. tostring(bc.missing or 0) .. missingLabel
            if bisAudit.setName then gearSummary = gearSummary .. " | Set: " .. tostring(bisAudit.setName) end
            if bisAudit.sourceLabel then gearSummary = gearSummary .. " | Source: " .. tostring(bisAudit.sourceLabel) end
            if bisAudit.contextLabel then gearSummary = gearSummary .. " | Context: " .. tostring(bisAudit.contextLabel) end
            y = AddParagraph(content, y, gearSummary, 610, {0.75, 0.88, 1})
            AddActionButton(content, 4, y + 2, 165, "Open Gear Guide", function() OpenMyCharacterGuide("BiS") end, true)
            y = y + 30
            if bisAudit.observed then
                y = AddParagraph(content, y, "U.GG rows are observed popular gear for the selected population, not editorial Best in Slot. Ownership states below are factual inventory checks only.", 610, {1, 0.75, 0.35})
            end
            if audit.belowGuideTarget then
                y = AddParagraph(content, y, "Level-" .. tostring(audit.guideTargetLevel) .. " gear reference; Equipped / Owned / Not owned states remain factual for this character.", 610, {0.65, 0.8, 1})
            end
            for _, item in ipairs(bisAudit.items or {}) do
                local color = item.status == "Equipped" and {0.35, 1, 0.65} or (item.status == "Owned" and {0.4, 0.8, 1} or {0.68, 0.68, 0.68})
                local displayStatus = (bisAudit.observed and item.status == "Missing") and "Not owned" or item.status
                y = AddParagraph(content, y, tostring(item.slot or "Slot") .. ": " .. tostring(item.name or item.id) .. " - " .. tostring(displayStatus), 610, color)
            end
            end

            if myCharacterView == "Enchants & Gems" or myCharacterView == "All Details" then
            y = AddHeading(content, y + 6, "Enchants")
            local enchantAudit = audit.enchants or {}
            local enchantSourceText = enchantAudit.sourceLabel and ("Source: " .. tostring(enchantAudit.sourceLabel)) or "Source: unavailable"
            if enchantAudit.contextLabel then enchantSourceText = enchantSourceText .. " | Context: " .. tostring(enchantAudit.contextLabel) end
            if enchantAudit.observed then enchantSourceText = enchantSourceText .. " | Observed player data" end
            y = AddParagraph(content, y, enchantSourceText, 610, {0.65, 0.8, 1})
            AddActionButton(content, 4, y + 2, 205, "Open Enchants & Gems Guide", function() OpenMyCharacterGuide("Enchants & Gems") end, true)
            y = y + 30
            if audit.belowGuideTarget then
                y = AddParagraph(content, y, "Level-" .. tostring(audit.guideTargetLevel) .. " enchant reference; detected equipped enchant states remain factual for this character.", 610, {0.65, 0.8, 1})
            end
            y = AddParagraph(content, y, "My Character reads WoW's permanent-enchantment tooltip line and compares its detected enchant name against every source-listed option for that slot. Source-verified effect-ID mappings can prove an exact applied enchant; crafted quality/rank otherwise stays fail-closed when the client text does not uniquely distinguish it.", 610, {1, 0.75, 0.35})
            for _, entry in ipairs(enchantAudit) do
                local color
                if entry.status == "Recommended enchant equipped" or entry.status == "Recommended enchant detected" then
                    color = {0.35, 1, 0.65}
                elseif entry.status == "Different enchant detected" or entry.status == "No enchant detected" then
                    color = {1, 0.55, 0.35}
                else
                    color = {0.68, 0.68, 0.68}
                end
                local effect = (entry.enchantID and entry.enchantID > 0) and (" | effect " .. tostring(entry.enchantID)) or ""
                local detail = ""
                if entry.effectVerified then
                    detail = " | source effect mapping verified"
                elseif entry.status == "Recommended enchant detected" then
                    detail = " | source name matched; quality/rank unverified"
                elseif entry.enchantText and entry.enchantText ~= "" then
                    detail = " | " .. tostring(entry.enchantText)
                end
                local displayStatus = entry.status
                if enchantAudit.observed and entry.status == "Recommended enchant equipped" then
                    displayStatus = "Observed enchant equipped"
                elseif enchantAudit.observed and entry.status == "Recommended enchant detected" then
                    displayStatus = "Observed enchant detected"
                end
                y = AddParagraph(content, y, tostring(entry.slot) .. " (slot " .. tostring(entry.slotID) .. "): " .. tostring(displayStatus) .. effect .. detail, 610, color)
            end

            y = AddHeading(content, y + 6, "Gems")
            local gemAudit = audit.gems or {}
            local gemMatches = 0
            for _, gem in ipairs(gemAudit) do
                if (gem.count or 0) > 0 then gemMatches = gemMatches + 1 end
                local color = (gem.count or 0) > 0 and {0.35, 1, 0.65} or {0.68, 0.68, 0.68}
                local suffix = (gem.count or 0) > 0 and (" - equipped x" .. tostring(gem.count)) or " - not detected"
                y = AddParagraph(content, y, tostring(gem.type or "Gem") .. ": " .. tostring(gem.name or gem.id) .. suffix, 610, color)
            end
            local gemOptionLabel = gemAudit.observed and "observed gem option(s)" or "source-listed gem option(s)"
            y = AddParagraph(content, y + 2, tostring(#(audit.equippedGems or {})) .. " total socketed gem(s) detected; " .. tostring(gemMatches) .. " " .. gemOptionLabel .. " currently present.", 610, {0.75, 0.88, 1})
            end

            if myCharacterView == "Consumables" or myCharacterView == "All Details" then
            y = AddHeading(content, y + 6, "Consumables")
            local consumableAudit = audit.consumables or {}
            local consumableSourceText = consumableAudit.sourceLabel and ("Source: " .. tostring(consumableAudit.sourceLabel)) or "Source: unavailable"
            if consumableAudit.contextLabel then consumableSourceText = consumableSourceText .. " | Context: " .. tostring(consumableAudit.contextLabel) end
            y = AddParagraph(content, y, consumableSourceText, 610, {0.65, 0.8, 1})
            AddActionButton(content, 4, y + 2, 190, "Open Consumables Guide", function() OpenMyCharacterGuide("Consumables") end, true)
            y = y + 30
            for _, item in ipairs(consumableAudit) do
                local color = (item.count or 0) > 0 and {0.35, 1, 0.65} or {0.68, 0.68, 0.68}
                y = AddParagraph(content, y, tostring(item.type or "Consumable") .. ": " .. tostring(item.name or item.id) .. " - " .. ((item.count or 0) > 0 and ("owned x" .. tostring(item.count)) or "missing"), 610, color)
            end
            if (consumableAudit.skippedReferences or 0) > 0 then
                y = AddParagraph(content, y + 2, tostring(consumableAudit.skippedReferences) .. " non-item source reference(s) are intentionally omitted from bag ownership auditing.", 610, {0.65, 0.8, 1})
            end
            end

            if myCharacterView == "Stats" or myCharacterView == "All Details" then
            y = AddHeading(content, y + 6, "Current Stats")
            local stats = audit.stats or {}
            local function FormatPercent(value) return value and string.format("%.1f%%", value) or "Unavailable" end
            y = AddParagraph(content, y, "Critical Strike " .. FormatPercent(stats.crit) .. " | Haste " .. FormatPercent(stats.haste) .. " | Mastery " .. FormatPercent(stats.mastery) .. " | Versatility " .. FormatPercent(stats.versatility), 610, {0.75, 0.88, 1})
            local statsGuide = audit.statsGuide or {}
            local statsSourceText = statsGuide.sourceLabel and ("Reference source: " .. tostring(statsGuide.sourceLabel)) or "Reference source: unavailable"
            if statsGuide.contextLabel then statsSourceText = statsSourceText .. " | Context: " .. tostring(statsGuide.contextLabel) end
            if statsGuide.observed then statsSourceText = statsSourceText .. " | Observed player data" end
            if audit.belowGuideTarget then statsSourceText = statsSourceText .. " | Level-" .. tostring(audit.guideTargetLevel) .. " guidance" end
            y = AddParagraph(content, y + 2, statsSourceText, 610, {0.65, 0.8, 1})
            AddActionButton(content, 4, y + 2, 160, "Open Stats Guide", function() OpenMyCharacterGuide("Stats") end, true)
            y = y + 30
            for _, variant in ipairs(statsGuide.variants or {}) do
                if variant.priority and variant.priority ~= "" then
                    local prefix = statsGuide.observed and "Observed reference" or "Guide reference"
                    if audit.belowGuideTarget then prefix = prefix .. " (level-" .. tostring(audit.guideTargetLevel) .. " guidance)" end
                    y = AddParagraph(content, y + 2, prefix .. " - " .. tostring(variant.label or "Stat Priority") .. ": " .. tostring(variant.priority), 610, {0.35, 1, 0.65})
                end
            end
            y = AddParagraph(content, y + 2, "Current percentages are a snapshot only; the addon does not convert a generic guide/observed priority into a character score or fixed stat weights.", 610, {0.65, 0.8, 1})
            end
        end

    elseif tabName == "Talents" then
        local selectedKey = (AzerothGuidebookDB and AzerothGuidebookDB.lastTalentBuild) or "raid"
        local selectedBuild = FindTalentBuild(data.talents, selectedKey)
        if not selectedBuild then
            selectedBuild = data.talents.builds and data.talents.builds[1]
        end

        local guideVariants = selectedBuild and AGB:GetGuideBuildVariants(specID, selectedBuild.key) or {}
        local selectedGuideVariant, selectedVariantKey
        if selectedBuild then
            selectedGuideVariant, selectedVariantKey = AGB:GetSelectedGuideVariant(specID, selectedBuild.key)
        end
        local bundledBuild = selectedBuild and AGB:GetBundledGuideBuild(specID, selectedBuild.key, selectedVariantKey) or nil
        local bundledStatus = selectedBuild and AGB:GetBundledGuideBuildStatus(specID, selectedBuild.key, selectedVariantKey) or nil

        y = AddHeading(content, y, "Talent Builds")
        local talentSourceStatus = (selectedGuideVariant and selectedGuideVariant.sourceUpdated) or data.talents.sourceUpdated or "live source"
        if talentSourceStatus == "live source" then
            y = AddParagraph(content, y, "Patch " .. data.patch .. " | Wowhead live talent guide")
        else
            y = AddParagraph(content, y, "Patch " .. data.patch .. " | Wowhead guide updated " .. talentSourceStatus)
        end

        local bx = 4
        for _, build in ipairs(data.talents.builds or {}) do
            local width = 150
            local categoryKey = build.key
            AddActionButton(content, bx, y, width, build.name, function()
                AzerothGuidebookDB.lastTalentBuild = categoryKey
                if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
                AGB:RenderTab("Talents")
            end, not selectedBuild or selectedBuild.key ~= build.key)
            bx = bx + width + 6
        end
        y = y + 36

        if selectedBuild and not AGB.customTalentPreview then
            local title = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
            title:SetPoint("TOPLEFT", 4, -y)
            title:SetText(selectedBuild.name)
            y = y + 24
            y = AddParagraph(content, y, selectedBuild.note)

            if selectedBuild.highlights and #selectedBuild.highlights > 0
                and (not selectedGuideVariant or selectedGuideVariant.recommended == true) then
                y = AddParagraph(content, y + 2, "Guide highlights: " .. table.concat(selectedBuild.highlights, "  -  "), 610, {0.75, 0.88, 1})
            end

            if #guideVariants > 0 then
                y = AddParagraph(content, y + 4, "Guide Builds", 610, {1, 0.82, 0.25})

                -- Build names can be substantially longer than Hero-tree names (for example,
                -- Single Target / Raid Cleave / Raid Council).  A fixed three-across row caused
                -- labels to visually collide once the automated collector surfaced the full
                -- guide variant set.  Use a compact two-column grid.  A single variant keeps the
                -- same normal button width instead of stretching across the full content pane.
                local columnCount = (#guideVariants > 1) and 2 or 1
                local buttonWidth = 298
                local buttonGap = 8
                local rowHeight = 30
                local rowCount = math.ceil(#guideVariants / columnCount)
                local baseY = y

                for index, option in ipairs(guideVariants) do
                    local variantKey = option.key
                    local variant = option.record
                    local optionExact = option.exact
                    local label = (variant and (variant.shortName or variant.name)) or variantKey
                    label = CompactGuideVariantLabel(label, variant)
                    if not optionExact and not string.find(string.lower(label), "%[pending%]") then
                        label = label .. " [Pending]"
                    end

                    local column = (index - 1) % columnCount
                    local row = math.floor((index - 1) / columnCount)
                    local vx = 4 + column * (buttonWidth + buttonGap)
                    local vy = baseY + row * rowHeight
                    local variantButton = AddActionButton(content, vx, vy, buttonWidth, label, function()
                        if AGB:SetSelectedGuideVariant(specID, selectedBuild.key, variantKey) then
                            if AGB.ClearCustomTalentPreview then AGB:ClearCustomTalentPreview() end
                            AGB:RenderTab("Talents")
                        end
                    end, selectedVariantKey ~= variantKey)

                    -- Keep the full source label discoverable even when the button text is long.
                    variantButton:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText((variant and (variant.name or variant.shortName)) or label, 1, 0.82, 0.25)
                        if variant and variant.heroTree and variant.heroTree ~= "" then
                            GameTooltip:AddLine("Hero: " .. variant.heroTree, 0.75, 0.88, 1)
                        end
                        if variant and variant.recommended == true then
                            GameTooltip:AddLine("Current guide recommendation", 0.35, 1, 0.65)
                        else
                            GameTooltip:AddLine("Guide-listed alternate", 0.85, 0.85, 0.85)
                        end
                        if optionExact then
                            GameTooltip:AddLine("Exact source build captured", 0.35, 1, 0.65)
                        else
                            GameTooltip:AddLine("Exact source build pending", 1, 0.75, 0.35)
                        end
                        GameTooltip:Show()
                    end)
                    variantButton:SetScript("OnLeave", GameTooltip_Hide)
                end
                y = y + (rowCount * rowHeight) + 4

                if selectedGuideVariant then
                    local selectedLabel = selectedGuideVariant.name or selectedGuideVariant.shortName or selectedVariantKey or "Guide Build"
                    local detail = "Selected: " .. selectedLabel
                    if selectedGuideVariant.heroTree and selectedGuideVariant.heroTree ~= "" then
                        detail = detail .. "  |  Hero: " .. selectedGuideVariant.heroTree
                    end
                    if selectedGuideVariant.recommended == true then
                        detail = detail .. "  |  Current recommendation"
                    else
                        detail = detail .. "  |  Alternate"
                    end
                    y = AddParagraph(content, y, detail, 610, bundledBuild and {0.55, 0.9, 1} or {1, 0.75, 0.35})
                end
            end

            if bundledBuild then
                y = AddParagraph(content, y + 2, "Exact guide build: the selected Wowhead Copy import string is bundled and will be revalidated against the live Retail talent tree before use.", 610, {0.35, 1, 0.65})
            elseif bundledStatus and bundledStatus.message then
                y = AddParagraph(content, y + 2, "Exact guide build: not bundled yet. " .. FriendlyGuideBuildStatusMessage(bundledStatus.message), 610, {1, 0.75, 0.35})
            end
        end

        y = AddDivider(content, y + 2)
        if not AGB.customTalentPreview then
            if bundledBuild then
                y = AddParagraph(content, y, "This selection has an exact bundled guide transport. Use the direct actions below, or keep Paste / Preview Build as a secondary path for any other compatible Blizzard/Wowhead string.", 610, {0.35, 1, 0.65})
            else
                y = AddParagraph(content, y, "Visual talent trees use WoW's live node positions and edges. Preview your active character build directly or paste any compatible Blizzard/Wowhead import string.", 610, {0.35, 1, 0.65})
            end
        end

        local playerClassFile, playerSpecID = AGB:GetPlayerContext()
        local canPreviewCurrent = playerClassFile == classFile and playerSpecID and playerSpecID == specID

        if bundledBuild and not AGB.customTalentPreview then
            AddActionButton(content, 4, y, 145, "View Guide Build", function()
                local ok, err = AGB:ActivateBundledGuideBuild(bundledBuild, "target")
                if not ok then
                    AGB.Print(err or "The bundled guide build failed runtime validation.")
                    return
                end
                AGB:RenderTab("Talents")
            end, true)
            AddActionButton(content, 155, y, 145, "Compare to Mine", function()
                local ok, err = AGB:ActivateBundledGuideBuild(bundledBuild, "compare")
                if not ok then
                    AGB.Print(err or "The bundled guide build could not be compared to your active build.")
                    return
                end
                AGB:RenderTab("Talents")
            end, canPreviewCurrent)
            AddActionButton(content, 306, y, 155, "Import as Loadout", function()
                local decoded, err = AGB:DecodeBundledGuideBuild(bundledBuild)
                if not decoded then
                    AGB.Print(err or "The bundled guide build failed runtime validation.")
                    return
                end
                AGB:ShowTargetImportPopup(decoded)
            end, canPreviewCurrent)
            AddActionButton(content, 467, y, 143, "Copy Build String", function()
                AGB:ShowCopyText(bundledBuild.importString)
            end, true)
            y = y + 36
        end

        AddActionButton(content, 4, y, 155, "Paste / Preview Build", function()
            AGB:ShowTalentInput()
        end, true)

        AddActionButton(content, 165, y, 155, "Preview My Build", function()
            local decoded, err = AGB:GetCurrentTalentPreview()
            if not decoded then
                AGB.Print(err or "Unable to read the current talent build.")
                return
            end
            if decoded.specID ~= specID then
                AGB.Print("Your active specialization does not match the displayed " .. data.specName .. " " .. data.className .. " guide.")
                return
            end
            AGB.customTalentPreview = decoded
            AGB.talentComparisonTarget = nil
            AGB.talentComparisonLive = decoded
            AGB.talentComparison = nil
            AGB.talentCompareMode = "current"
            AGB.talentDifferenceFocusIndex = nil
            AGB.talentDifferenceFocusNodeID = nil
            AGB.talentDifferenceFocusSection = nil
            AGB:RenderTab("Talents")
        end, canPreviewCurrent)

        AddActionButton(content, 326, y, 145, "Copy Wowhead URL", function()
            AGB:ShowCopyText(data.talents.sourceURL)
        end, true)

        if AGB.customTalentPreview then
            AddActionButton(content, 477, y, 133, "Clear Preview", function()
                AGB:ClearCustomTalentPreview()
                AGB:RenderTab("Talents")
            end, true)
        end
        y = y + 36

        if AGB.customTalentPreview then
            local target = AGB.talentComparisonTarget
            local decoded = AGB.customTalentPreview

            local function LoadCurrentComparison(mode)
                local current, err = AGB:GetCurrentTalentPreview()
                if not current then
                    AGB.Print(err or "Unable to read the current talent build.")
                    return false
                end
                if target and current.specID ~= target.specID then
                    AGB.Print("The target build is for a different specialization than your active character build.")
                    return false
                end

                AGB.talentComparisonLive = current
                if target then
                    local comparison, compareErr = AGB:BuildTalentComparison(target, current)
                    if not comparison then
                        AGB.Print(compareErr or "Unable to compare these talent builds.")
                        return false
                    end
                    AGB.talentComparison = comparison
                end
                AGB.talentCompareMode = mode
                return true
            end

            if target and not target.liveCharacter then
                local mode = AGB.talentCompareMode or "target"
                AddActionButton(content, 4, y, 190, "Target Build", function()
                    AGB.talentCompareMode = "target"
                    AGB:RenderTab("Talents")
                end, mode ~= "target")
                AddActionButton(content, 200, y, 190, "My Build", function()
                    if LoadCurrentComparison("current") then AGB:RenderTab("Talents") end
                end, canPreviewCurrent and mode ~= "current")
                AddActionButton(content, 396, y, 214, "Compare", function()
                    if LoadCurrentComparison("compare") then AGB:RenderTab("Talents") end
                end, canPreviewCurrent and mode ~= "compare")
                y = y + 34

                if mode == "compare" then
                    if not AGB.talentComparison then
                        if not LoadCurrentComparison("compare") then
                            mode = "target"
                        end
                    end
                    if AGB.talentComparison then
                        y = AddTalentComparisonPreview(content, y, AGB.talentComparison)
                        if target.importString and target.importString ~= "" then
                            AddActionButton(content, 4, y + 2, 185, "Copy Target String", function()
                                AGB:ShowCopyText(target.importString)
                            end, true)
                        end
                        if AGB.talentComparisonLive and AGB.talentComparisonLive.importString and AGB.talentComparisonLive.importString ~= "" then
                            AddActionButton(content, 195, y + 2, 185, "Copy My Build String", function()
                                AGB:ShowCopyText(AGB.talentComparisonLive.importString)
                            end, true)
                        end
                        AddActionButton(content, 386, y + 2, 224, "Import Target as Loadout", function()
                            AGB:ShowTargetImportPopup(target)
                        end, target.importString and target.importString ~= "" and not target.heroIncomplete)
                        y = y + 36
                    end
                elseif mode == "current" then
                    local current = AGB.talentComparisonLive
                    if not current then
                        if LoadCurrentComparison("current") then current = AGB.talentComparisonLive end
                    end
                    if current then
                        y = AddTalentPreview(content, y, current, "My Current Build")
                        if current.importString and current.importString ~= "" then
                            y = AddCopyButton(content, y + 2, "Copy My Build String", current.importString)
                        end
                    end
                else
                    y = AddTalentPreview(content, y, target, "Guide / Target Build")
                    if target.importString and target.importString ~= "" then
                        AddActionButton(content, 4, y + 2, 185, "Copy Target String", function()
                            AGB:ShowCopyText(target.importString)
                        end, true)
                        AddActionButton(content, 195, y + 2, 224, "Import Target as Loadout", function()
                            AGB:ShowTargetImportPopup(target)
                        end, not target.heroIncomplete)
                        y = y + 36
                    end
                end
            else
                y = AddTalentPreview(content, y, decoded, decoded.label or "Selected Talents")
                if decoded.importString and decoded.importString ~= "" then
                    y = AddCopyButton(content, y + 2, "Copy Import String", decoded.importString)
                else
                    y = AddParagraph(content, y + 2, "WoW returned the live talent configuration, but an export string was not available yet. The visual build above is still read directly from the active config.", 610, {0.75, 0.75, 0.75})
                end
            end
        else
            if bundledBuild then
                y = AddParagraph(content, y, "Use View Guide Build for the exact bundled target, Compare to Mine for an immediate diff against your active " .. data.specName .. " build, or Import as Loadout to hand the validated target to WoW's native loadout importer.", 610, {0.75, 0.75, 0.75})
            else
                y = AddParagraph(content, y, "Use Preview My Build to visualize your active " .. data.specName .. " " .. data.className .. " talents. This guide selection does not yet have an exact bundled transport, so Paste / Preview Build remains the safe comparison path.", 610, {0.75, 0.75, 0.75})
            end
        end

        y = AddDivider(content, y + 2)
        y = AddParagraph(content, y, data.talents.limitation, 610, {1, 0.75, 0.35})

    elseif tabName == "Rotation" then
        local rotation = data.rotation
        y = AddHeading(content, y, "Rotation & Cooldowns")
        y = AddParagraph(content, y, "Patch " .. data.patch .. " | Source updated " .. (rotation.sourceUpdated or "unknown"))
        y = AddParagraph(content, y, "Concise source-listed priorities and opener sequences. Hover linked rows for WoW tooltips; Shift-click a linked row to insert its first linked spell/item in chat.", 610, {0.65, 0.8, 1})

        local selectedContext = rotation.defaultContext or ((rotation.contexts or {})[1]) or ""
        AzerothGuidebookDB.rotationContexts = AzerothGuidebookDB.rotationContexts or {}
        local savedContext = AzerothGuidebookDB.rotationContexts[specID]
        if savedContext then
            for _, contextName in ipairs(rotation.contexts or {}) do
                if contextName == savedContext then
                    selectedContext = savedContext
                    break
                end
            end
        end

        if rotation.contexts and #rotation.contexts > 1 then
            y = AddParagraph(content, y + 2, "Hero / source context", 610, {1, 0.82, 0.35})
            y = AddParagraph(content, y, "Current hero/source: " .. selectedContext, 610, {0.55, 0.9, 1})
            local columns = 2
            local buttonWidth = 298
            local buttonGap = 8
            local rowHeight = 30
            local rowCount = math.ceil(#rotation.contexts / columns)
            local baseY = y
            for index, contextName in ipairs(rotation.contexts) do
                local capturedContext = contextName
                local column = (index - 1) % columns
                local row = math.floor((index - 1) / columns)
                local isSelected = selectedContext == capturedContext
                local buttonLabel = isSelected and (capturedContext .. " [Selected]") or capturedContext
                AddActionButton(content, 4 + column * (buttonWidth + buttonGap), baseY + row * rowHeight, buttonWidth, buttonLabel, function()
                    AzerothGuidebookDB.rotationContexts = AzerothGuidebookDB.rotationContexts or {}
                    AzerothGuidebookDB.rotationContexts[specID] = capturedContext
                    AGB:RenderTab("Rotation")
                end, not isSelected)
            end
            y = y + rowCount * rowHeight + 4
        elseif selectedContext ~= "" then
            y = AddParagraph(content, y + 2, "Context: " .. selectedContext, 610, {0.55, 0.9, 1})
        end

        local sectionOrder = { "precombat", "opener", "healing", "general", "single_target", "aoe", "damage", "cooldowns" }
        local sectionNames = {
            precombat = "Pre-Combat",
            opener = "Opener",
            healing = "Healing Priority",
            general = "General Priority",
            single_target = "Single Target",
            aoe = "AoE / Cleave",
            damage = "Damage Priority",
            cooldowns = "Major Cooldowns",
        }
        local renderedBlocks = {}
        local renderedAny = false
        for _, sectionKey in ipairs(sectionOrder) do
            local sectionStarted = false
            for blockIndex, block in ipairs(rotation.blocks or {}) do
                local contextMatches = (not block.context or block.context == "" or block.context == selectedContext)
                if block.section == sectionKey and contextMatches then
                    if not sectionStarted then
                        y = AddHeading(content, y + (renderedAny and 6 or 2), sectionNames[sectionKey] or block.sectionLabel or sectionKey)
                        sectionStarted = true
                        renderedAny = true
                    end
                    local blockLabel = block.label or block.sectionLabel or "Priority"
                    if blockLabel ~= "" and string.lower(blockLabel) ~= "priority" then
                        y = AddParagraph(content, y, blockLabel, 610, {1, 0.82, 0.35})
                    end
                    for actionIndex, action in ipairs(block.actions or {}) do
                        y = AddRotationActionRow(content, y, actionIndex, action)
                    end
                    renderedBlocks[blockIndex] = true
                end
            end
        end

        -- Preserve any future source section the collector understands before the UI does.
        for blockIndex, block in ipairs(rotation.blocks or {}) do
            local contextMatches = (not block.context or block.context == "" or block.context == selectedContext)
            if not renderedBlocks[blockIndex] and contextMatches then
                y = AddHeading(content, y + (renderedAny and 6 or 2), block.sectionLabel or block.section or "Rotation")
                renderedAny = true
                local blockLabel = block.label or "Priority"
                if blockLabel ~= "" and string.lower(blockLabel) ~= "priority" then
                    y = AddParagraph(content, y, blockLabel, 610, {1, 0.82, 0.35})
                end
                for actionIndex, action in ipairs(block.actions or {}) do
                    y = AddRotationActionRow(content, y, actionIndex, action)
                end
            end
        end

        if not renderedAny then
            y = AddParagraph(content, y + 4, "No reviewed rotation blocks are available for the selected context.", 610, {1, 0.55, 0.35})
        end
        y = AddParagraph(content, y + 6, rotation.note or "Source-listed rotation priorities captured from Wowhead.", 610, {0.9, 0.9, 0.9})
        y = AddCopyButton(content, y + 4, "Copy Rotation Guide URL", rotation.sourceURL)

    elseif tabName == "BiS" then
        local bis = data.bis
        local activeItems = bis.items or {}
        local activeCrafted = bis.crafted or {}

        y = AddHeading(content, y, "Best in Slot")
        y = AddParagraph(content, y, "Patch " .. data.patch .. " | Source updated " .. tostring(bis.sourceUpdated or "unknown") .. " | Hover any item for the normal WoW tooltip. Shift-click can link it to chat.")

        if bis.sets and next(bis.sets) then
            AzerothGuidebookDB.bisGuideSets = AzerothGuidebookDB.bisGuideSets or {}
            local requestedKey = AzerothGuidebookDB.bisGuideSets[specID] or bis.defaultSet
            local selectedSet = requestedKey and bis.sets[requestedKey] or nil
            if not selectedSet then
                local fallbackKey = bis.order and bis.order[1]
                requestedKey = fallbackKey
                selectedSet = fallbackKey and bis.sets[fallbackKey] or nil
            end

            local setOptions = {}
            for _, setKey in ipairs(bis.order or {}) do
                local setRecord = bis.sets[setKey]
                if setRecord then
                    table.insert(setOptions, { key = setKey, record = setRecord })
                end
            end
            if #setOptions == 0 then
                for setKey, setRecord in pairs(bis.sets) do
                    table.insert(setOptions, { key = setKey, record = setRecord })
                end
                table.sort(setOptions, function(a, b) return tostring(a.key) < tostring(b.key) end)
            end

            if #setOptions > 1 then
                y = AddParagraph(content, y + 4, "Gear Sets", 610, {1, 0.82, 0.25})
                local columnCount = (#setOptions > 1) and 2 or 1
                local buttonWidth = (columnCount == 2) and 298 or 610
                local buttonGap = 8
                local rowHeight = 30
                local rowCount = math.ceil(#setOptions / columnCount)
                local baseY = y
                for index, option in ipairs(setOptions) do
                    local setKey = option.key
                    local setRecord = option.record
                    local column = (index - 1) % columnCount
                    local row = math.floor((index - 1) / columnCount)
                    local bx = 4 + column * (buttonWidth + buttonGap)
                    local by = baseY + row * rowHeight
                    AddActionButton(content, bx, by, buttonWidth, setRecord.shortName or setRecord.name or setKey, function()
                        AzerothGuidebookDB.bisGuideSets[specID] = setKey
                        AGB:RenderTab("BiS")
                    end, requestedKey ~= setKey)
                end
                y = y + (rowCount * rowHeight) + 4
            end

            if selectedSet then
                activeItems = selectedSet.items or activeItems
                if selectedSet.crafted and #selectedSet.crafted > 0 then
                    activeCrafted = selectedSet.crafted
                end
                if #setOptions > 1 then
                    y = AddParagraph(content, y, "Selected gear set: " .. tostring(selectedSet.name or selectedSet.shortName or requestedKey), 610, {0.55, 0.9, 1})
                end
            end
        end

        for _, item in ipairs(activeItems) do
            y = AddItemRow(content, y, item.slot, item, item.source, true)
        end

        if activeCrafted and #activeCrafted > 0 then
            y = AddHeading(content, y + 6, "Crafted Priorities")
            for i, line in ipairs(activeCrafted) do
                y = AddParagraph(content, y, i .. ". " .. line)
            end
        end
        y = AddCopyButton(content, y + 4, "Copy Wowhead URL", bis.sourceURL)

    elseif tabName == "Consumables" then
        y = AddHeading(content, y, "Consumables")
        y = AddParagraph(content, y, "Patch " .. data.patch .. " | Source updated " .. data.consumables.sourceUpdated)
        for _, item in ipairs(data.consumables.items) do
            y = AddItemRow(content, y, item.type, item, item.context or "", false)
        end
        y = AddParagraph(content, y + 6, data.consumables.note, 610, {1, 0.82, 0.35})
        y = AddCopyButton(content, y + 4, "Copy Wowhead URL", data.consumables.sourceURL)

    elseif tabName == "Enchants & Gems" then
        y = AddHeading(content, y, "Enchants")
        y = AddParagraph(content, y, "Patch " .. data.patch .. " | Source updated " .. data.enchants.sourceUpdated)
        for _, item in ipairs(data.enchants.items) do
            y = AddItemRow(content, y, item.slot, item, item.context or "", false)
        end
        y = AddHeading(content, y + 6, "Gems")
        for _, item in ipairs(data.enchants.gems) do
            y = AddItemRow(content, y, item.type, item, item.context or "", false)
        end
        y = AddParagraph(content, y + 6, data.enchants.note, 610, {1, 0.82, 0.35})
        y = AddCopyButton(content, y + 4, "Copy Wowhead URL", data.enchants.sourceURL)

    elseif tabName == "Stats" then
        y = AddHeading(content, y, "Stat Priority")
        if data.stats and data.stats.variants and #data.stats.variants > 0 then
            y = AddParagraph(content, y, "Patch " .. data.patch .. " | Source updated " .. (data.stats.sourceUpdated or "unknown"))
            for index, variant in ipairs(data.stats.variants) do
                y = AddParagraph(content, y + 2, variant.label or ("Variant " .. index), 610, {1, 0.82, 0.35})
                local pri = AddElement(content, NewText(content, 16, 0.35, 1, 0.65))
                pri:SetPoint("TOPLEFT", 4, -y)
                pri:SetWidth(610)
                pri:SetText(table.concat(variant.priority or {}, "  >  "))
                y = y + math.max(30, pri:GetStringHeight() + 10)
                if index < #data.stats.variants then
                    y = AddDivider(content, y + 2)
                end
            end
            y = AddParagraph(content, y + 4, data.stats.note or "Source-listed general stat priorities captured from Wowhead.", 610, {0.9, 0.9, 0.9})
            y = AddParagraph(content, y + 8, "Stat priorities are general gearing guidance, not fixed item weights. Use a character-specific simulator or healer analysis tool when deciding between actual items.", 610, {0.65, 0.8, 1})
            y = AddCopyButton(content, y + 4, "Copy Stats Guide URL", data.stats.sourceURL)
        else
            local pri = AddElement(content, NewText(content, 18, 0.35, 1, 0.65))
            pri:SetPoint("TOPLEFT", 4, -y)
            pri:SetWidth(610)
            pri:SetText(data.statPriority or "")
            y = y + math.max(34, pri:GetStringHeight() + 10)
            if data.statNote then
                y = AddParagraph(content, y, data.statNote)
            end
            y = AddParagraph(content, y + 8, data.statToolNote or "This reference mirrors the rough priority stated in the current Wowhead gearing guidance. Use a character-specific simulation or healer analysis tool when making final gearing decisions.", 610, {0.65, 0.8, 1})
            local statsURL
            for _, source in ipairs(data.sources or {}) do
                if source.label == "Stats" and source.url then
                    statsURL = source.url
                    break
                end
            end
            if statsURL then
                y = AddCopyButton(content, y + 4, "Copy Stats Guide URL", statsURL)
            end
        end

    elseif tabName == "Sources" then
        y = AddHeading(content, y, "Source & Freshness")
        y = AddParagraph(content, y, "Bundled data pack refreshed: " .. self.DATA_REFRESHED .. " | Target client: Retail " .. data.patch .. " | Addon v" .. self.VERSION)
        y = AddParagraph(content, y, "Azeroth Guidebook does not make web requests from WoW. Automatic refresh is handled by the separately installed Azeroth Guidebook Companion, which accepts only project-validated source packs and writes fail-closed local overrides.")

        y = AddHeading(content, y + 8, "Source Refresh")
        local companionReady = false
        local companion = nil
        if self.IsSourceRefreshCompanionReady then
            companionReady, companion = self:IsSourceRefreshCompanionReady()
        elseif self.GetSourceRefreshCompanionAvailability then
            companion = self:GetSourceRefreshCompanionAvailability()
        end
        if companionReady then
            local companionText = "Companion: Ready"
            if companion and companion.version then companionText = companionText .. " | v" .. tostring(companion.version) end
            if companion and companion.feedMode then companionText = companionText .. " | Feed: " .. tostring(companion.feedMode) end
            y = AddParagraph(content, y, companionText, 610, {0.35, 1, 0.65})
        else
            local reason = companion and companion.reason or "not_installed"
            local statusText
            if reason == "incompatible" then
                statusText = "Companion: Update required. The installed companion uses an incompatible refresh protocol."
            elseif reason == "stale" then
                statusText = "Companion: Not detected as running. Restart the Azeroth Guidebook Companion or sign out/in to Windows, then /reload."
            elseif reason == "not_running" then
                statusText = "Companion: Installed status found, but it is not running. Start the Azeroth Guidebook Companion, then /reload."
            else
                statusText = "Companion: Not installed. Azeroth Guidebook still works with bundled guide data; install the optional Companion from the CurseForge project page to enable automatic refresh."
            end
            y = AddParagraph(content, y, statusText, 610, {1, 0.75, 0.35})
        end

        local refreshScope = self.GetSourceRefreshCurrentScope and self:GetSourceRefreshCurrentScope() or nil
        if refreshScope then
            local contextSuffix = refreshScope.contextLabel and (" | " .. tostring(refreshScope.contextLabel)) or ""
            y = AddParagraph(content, y, "Current source scope: " .. tostring(refreshScope.specName) .. " " .. tostring(refreshScope.className) .. " | " .. tostring(refreshScope.tabName) .. " | " .. tostring(refreshScope.sourceLabel) .. contextSuffix, 610, {0.55, 0.9, 1})
        end
        y = AddParagraph(content, y, "Refresh Current Source checks the validated pack feed for the selected source and specialization. Refresh Current Spec checks Wowhead, Icy Veins, and U.GG for this specialization. Refresh All Sources checks all supported sources across all 40 specs. No browser, PowerShell, Python, or source-site interaction is required during normal use.", 610, {0.82, 0.86, 0.92})

        local function QueueAndSubmitRefresh(scope)
            if AGB.QueueSourceRefresh and AGB:QueueSourceRefresh(scope) then
                if ReloadUI then
                    ReloadUI()
                elseif AGB.Print then
                    AGB.Print("Run /reload to submit the queued refresh request.")
                end
            end
        end

        local refreshButtonY = y + 2
        local refreshEnabled = refreshScope ~= nil and companionReady == true
        AddActionButton(content, 4, refreshButtonY, 190, "Refresh Current Source", function()
            QueueAndSubmitRefresh("source")
        end, refreshEnabled)
        AddActionButton(content, 198, refreshButtonY, 190, "Refresh Current Spec", function()
            QueueAndSubmitRefresh("spec")
        end, refreshEnabled)
        AddActionButton(content, 392, refreshButtonY, 190, "Refresh All Sources", function()
            QueueAndSubmitRefresh("all")
        end, refreshEnabled)
        y = refreshButtonY + 32

        local queuedRefresh = self.GetQueuedSourceRefreshRequest and self:GetQueuedSourceRefreshRequest() or nil
        if queuedRefresh then
            y = AddParagraph(content, y, "Submitted: " .. tostring(queuedRefresh.label or queuedRefresh.scope or "source refresh") .. ". The background companion will process it automatically. When the refresh-complete notification appears, /reload once to load the new validated pack/status.", 610, {1, 0.82, 0.3})
        end

        local refreshState = self.GetSourceRefreshState and self:GetSourceRefreshState() or nil
        local lastRun = refreshState and refreshState.lastRun or nil
        if lastRun then
            local stateLabel, stateColor = self:GetSourceRefreshStateLabel(lastRun.state)
            local summaryText = "Companion last run: " .. tostring(stateLabel)
            if lastRun.completedAt then summaryText = summaryText .. " | " .. tostring(lastRun.completedAt) end
            if lastRun.summary and lastRun.summary ~= "" then summaryText = summaryText .. " | " .. tostring(lastRun.summary) end
            y = AddParagraph(content, y, summaryText, 610, stateColor)
        else
            y = AddParagraph(content, y, "Companion status: no local refresh has been applied yet.", 610, {0.7, 0.7, 0.7})
        end

        if refreshScope and self.GetSourceRefreshEntry then
            local entry = self:GetSourceRefreshEntry(refreshScope.specID, refreshScope.sourceID)
            if entry then
                local entryLabel, entryColor = self:GetSourceRefreshStateLabel(entry.state)
                local entryText = tostring(refreshScope.sourceLabel) .. " local refresh: " .. tostring(entryLabel)
                if entry.updatedAt then entryText = entryText .. " | " .. tostring(entry.updatedAt) end
                if entry.details and entry.details ~= "" then entryText = entryText .. " | " .. tostring(entry.details) end
                y = AddParagraph(content, y, entryText, 610, entryColor)
            end
        end

        y = AddHeading(content, y + 8, "What's New Since Last Refresh?")
        local refreshHistory = self.GetSourceRefreshHistory and self:GetSourceRefreshHistory() or {}
        local latestHistory = refreshHistory and refreshHistory[1] or nil
        if not latestHistory then
            local schemaVersion = refreshState and tonumber(refreshState.schemaVersion) or 1
            if schemaVersion < 2 then
                y = AddParagraph(content, y, "Detailed change history is not available from the installed companion yet. Update to Companion v1.1.0 or newer, then run a refresh; existing guide data remains unchanged.", 610, {1, 0.75, 0.35})
            else
                y = AddParagraph(content, y, "No refresh change history yet. The next completed refresh will record recommendation changes and source-date advances here.", 610, {0.7, 0.78, 0.88})
            end
        else
            local packs = latestHistory.packs or {}
            local checkedPacks = #packs
            local notablePacks = 0
            local changedDomains = 0
            local dateOnlyDomains = 0
            local unchangedDomains = 0
            for _, pack in ipairs(packs) do
                local packNotable = pack.state == "failed" or pack.state == "review_required" or pack.state == "blocked"
                for _, domainChange in ipairs(pack.domains or {}) do
                    if domainChange.state == "changed" then
                        changedDomains = changedDomains + 1
                        packNotable = true
                    elseif domainChange.state == "date_only" then
                        dateOnlyDomains = dateOnlyDomains + 1
                        packNotable = true
                    elseif domainChange.state == "unchanged" then
                        unchangedDomains = unchangedDomains + 1
                    end
                end
                if packNotable then notablePacks = notablePacks + 1 end
            end

            local runScopeLabel = latestHistory.scope == "all" and "All Sources" or (latestHistory.scope == "spec" and "Current Spec" or "Current Source")
            local runText = tostring(runScopeLabel)
            if latestHistory.completedAt and latestHistory.completedAt ~= "" then runText = runText .. " | " .. tostring(latestHistory.completedAt) end
            runText = runText .. " | " .. tostring(checkedPacks) .. " source pack(s) checked"
            y = AddParagraph(content, y, runText, 610, {0.55, 0.9, 1})

            if changedDomains == 0 and dateOnlyDomains == 0 and notablePacks == 0 then
                y = AddParagraph(content, y, "No recommendation changes detected in this refresh.", 610, {0.35, 1, 0.65})
            else
                local changeSummary = tostring(changedDomains) .. " guide domain(s) changed"
                if dateOnlyDomains > 0 then changeSummary = changeSummary .. " | " .. tostring(dateOnlyDomains) .. " source date(s) advanced without recommendation changes" end
                if notablePacks > 0 then changeSummary = changeSummary .. " | " .. tostring(notablePacks) .. " source pack(s) need attention or contain changes" end
                y = AddParagraph(content, y, changeSummary, 610, {1, 0.82, 0.3})
            end

            local showAllPackDetails = latestHistory.scope ~= "all"
            local omittedUnchangedPacks = 0
            for _, pack in ipairs(packs) do
                local packNotable = pack.state == "failed" or pack.state == "review_required" or pack.state == "blocked"
                for _, domainChange in ipairs(pack.domains or {}) do
                    if domainChange.state == "changed" or domainChange.state == "date_only" then
                        packNotable = true
                    end
                end
                if showAllPackDetails or packNotable then
                    local sourceLabel = self.GetGuideSourceLabel and self:GetGuideSourceLabel(pack.sourceID) or tostring(pack.sourceID or "Source")
                    local specLabel = self.GetSourceRefreshSpecLabel and self:GetSourceRefreshSpecLabel(pack.specID) or ("Spec " .. tostring(pack.specID or "?"))
                    local packLabel, packColor = self:GetSourceRefreshStateLabel(pack.state)
                    y = AddParagraph(content, y + 3, tostring(specLabel) .. " | " .. tostring(sourceLabel) .. " | " .. tostring(packLabel), 610, packColor)

                    if pack.domains and #pack.domains > 0 then
                        for _, domainChange in ipairs(pack.domains) do
                            local domainLabel = self.GetSourceRefreshChangeDomainLabel and self:GetSourceRefreshChangeDomainLabel(domainChange.domain) or tostring(domainChange.domain or "Guide")
                            local changeLabel, changeColor = self:GetSourceRefreshChangeStateLabel(domainChange.state)
                            local domainText = tostring(domainLabel) .. ": " .. tostring(changeLabel)
                            if domainChange.summary and domainChange.summary ~= "" then domainText = domainText .. " | " .. tostring(domainChange.summary) end
                            if domainChange.beforeUpdated and domainChange.afterUpdated and domainChange.beforeUpdated ~= domainChange.afterUpdated then
                                domainText = domainText .. " | source date " .. tostring(domainChange.beforeUpdated) .. " -> " .. tostring(domainChange.afterUpdated)
                            end
                            if domainChange.state == "changed" or domainChange.state == "date_only" then
                                local packRef = pack
                                local domainRef = domainChange.domain
                                y = AddIssueActionRow(content, y, domainText, "View Updated Guide", function()
                                    if AGB.OpenSourceRefreshChangedDomain then AGB:OpenSourceRefreshChangedDomain(packRef, domainRef) end
                                end, changeColor)
                            else
                                y = AddParagraph(content, y, domainText, 610, changeColor)
                            end
                        end
                    elseif pack.summary and pack.summary ~= "" then
                        y = AddParagraph(content, y, tostring(pack.summary), 610, packColor)
                    end
                else
                    omittedUnchangedPacks = omittedUnchangedPacks + 1
                end
            end
            if omittedUnchangedPacks > 0 then
                y = AddParagraph(content, y + 2, tostring(omittedUnchangedPacks) .. " unchanged source pack(s) omitted from the all-sources detail view.", 610, {0.65, 0.72, 0.8})
            end

            if #refreshHistory > 1 then
                y = AddHeading(content, y + 6, "Recent Refresh History")
                for index, run in ipairs(refreshHistory) do
                    if index > 5 then break end
                    local historyState, historyColor = self:GetSourceRefreshStateLabel(run.state)
                    local historyScope = run.scope == "all" and "All Sources" or (run.scope == "spec" and "Current Spec" or "Current Source")
                    local historyText = tostring(run.completedAt or "Unknown time") .. " | " .. tostring(historyScope) .. " | " .. tostring(historyState)
                    if run.summary and run.summary ~= "" then historyText = historyText .. " | " .. tostring(run.summary) end
                    y = AddParagraph(content, y, historyText, 610, historyColor)
                end
            end
        end

        y = AddParagraph(content, y + 2, "Refresh processing is automatic for all supported sources. Source capture and review happen outside the player's PC; the Companion downloads only Azeroth Guidebook-validated packs. Partial, ambiguous, invalid, mismatched, or corrupted data never replaces accepted data. If refreshed Lua data is installed, use /reload after the completion notification so WoW can load it.", 610, {0.65, 0.8, 1})

        for _, src in ipairs(data.sources) do
            y = AddDivider(content, y)
            local fs = AddElement(content, NewText(content, 16, 0.35, 0.85, 1))
            fs:SetPoint("TOPLEFT", 4, -y)
            if src.updated == "live source" then
                fs:SetText(src.label .. "  |  live Wowhead source")
            else
                fs:SetText(src.label .. "  |  updated " .. src.updated)
            end
            y = y + 24
            y = AddCopyButton(content, y, "Copy Source URL", src.url)
        end
        local multiSpec = AGB.GetMultiSourceSpec and AGB:GetMultiSourceSpec(specID) or nil
        if multiSpec and multiSpec.sources then
            y = AddHeading(content, y + 8, "Additional Reviewed Sources")
            local icy = multiSpec.sources["icy-veins"]
            if icy then
                y = AddParagraph(content, y, "Icy Veins | Editorial | Talents, BiS, Consumables, Enchants/Gems, Stats, Rotation", 610, {0.55, 0.9, 1})
                y = AddParagraph(content, y, icy.semantics or "Editorial guidance is kept source-specific.", 610, {0.75, 0.82, 0.9})
                local url = icy.domains and icy.domains.talents and icy.domains.talents.sourceURL
                if url then y = AddCopyButton(content, y + 2, "Copy Icy Veins URL", url) end
            end
            local ugg = multiSpec.sources.ugg
            if ugg then
                y = AddParagraph(content, y + 4, "U.GG | Player data | Raid/Mythic+ Talents, observed Gear, Enchants/Gems, Stats", 610, {0.55, 0.9, 1})
                y = AddParagraph(content, y, ugg.semantics or "Observed player data is kept separate from editorial recommendations.", 610, {0.75, 0.82, 0.9})
                for _, contextKey in ipairs({ "raid", "mythicplus" }) do
                    local sourceContext = ugg.contexts and ugg.contexts[contextKey]
                    local talentDomain = sourceContext and sourceContext.domains and sourceContext.domains.talents
                    if talentDomain and talentDomain.builds and #talentDomain.builds == 0 and talentDomain.note then
                        y = AddParagraph(content, y, tostring(sourceContext.label or contextKey) .. " Talents: " .. tostring(talentDomain.note), 610, {1, 0.75, 0.35})
                    end
                end
                local raid = ugg.contexts and ugg.contexts.raid
                local url = raid and raid.domains and raid.domains.talents and raid.domains.talents.sourceURL
                if url then y = AddCopyButton(content, y + 2, "Copy U.GG URL", url) end
            end
        end
        y = AddParagraph(content, y + 8, "Wowhead, Icy Veins, and U.GG are third-party sources. World of Warcraft and related game data are trademarks/properties of Blizzard Entertainment. Recommendations remain source-specific; editorial guidance and observed player data are never silently blended.", 610, {0.7, 0.7, 0.7})
    end

    content:SetHeight(math.max(y + 24, 460))
    ApplyPendingGuideFocusScroll(tabName)

    if tabName == "My Character" and pendingMyCharacterScrollY ~= nil then
        local targetScroll = pendingMyCharacterScrollY
        local function RestoreMyCharacterScroll()
            if not AGB.UI or not AGB.UI.scroll then return end
            local maxScroll = AGB.UI.scroll:GetVerticalScrollRange() or 0
            AGB.UI.scroll:SetVerticalScroll(math.min(math.max(0, targetScroll), maxScroll))
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, RestoreMyCharacterScroll)
        else
            RestoreMyCharacterScroll()
        end
    end

    if tabName == "Talents" and self._comparisonFocusScrollY then
        local targetScroll = self._comparisonFocusScrollY
        self._comparisonFocusScrollY = nil
        local function ApplyComparisonScroll()
            if not AGB.UI or not AGB.UI.scroll then return end
            local maxScroll = AGB.UI.scroll:GetVerticalScrollRange() or 0
            AGB.UI.scroll:SetVerticalScroll(math.min(math.max(0, targetScroll), maxScroll))
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ApplyComparisonScroll)
        else
            ApplyComparisonScroll()
        end
    end
end

function AGB:RefreshUI()
    if not self.UI then self:CreateUI() end
    local data, classFile, specID = self:GetActiveData()
    local playerClassFile, playerSpecID, playerSpecName = self:GetPlayerContext()

    if data then
        self.UI.subtitle:SetText(data.className .. " - " .. data.specName .. " | Patch " .. data.patch .. " | Data refreshed " .. self.DATA_REFRESHED)
    else
        local localizedClass = UnitClass("player")
        self.UI.subtitle:SetText((localizedClass or playerClassFile or "Unknown") .. " - " .. (playerSpecName or "Unknown") .. " | No bundled data yet")
    end

    if self.UI.preview then
        if data then
            self.UI.preview:SetText(data.className .. ": " .. data.specName)
        else
            self.UI.preview:SetText("Browse Guides")
        end
    end

    local tab = AzerothGuidebookDB and AzerothGuidebookDB.lastTab or "Talents"
    if not self.UI.tabs[tab] or (data and not IsTabAvailableForData(tab, data)) then tab = "Talents" end
    self:RenderTab(tab)
end