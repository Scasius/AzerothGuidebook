local addonName, AGB = ...

-- Talent import strings are Blizzard's compact Class Talent serialization format.
-- This module intentionally uses the same public APIs / file layout documented by
-- Blizzard's own ClassTalentImportExportMixin rather than maintaining a separate
-- hard-coded talent-node database.

local HEADER_VERSION_BITS = 8
local HEADER_SPEC_BITS = 16
local HEADER_HASH_BYTES = 16
local RANK_BITS = 6

local function TalentError(message)
    return nil, message or "Unable to read this talent build."
end

local function GetSpellInfoSafe(spellID)
    if not spellID then return nil end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, info.iconID, info.originalIconID
        end
    end

    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon, icon
    end
end

local function GetEntryDisplay(configID, entryID)
    if not entryID or not C_Traits then return nil end

    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo then return nil end

    local definitionInfo
    if entryInfo.definitionID and C_Traits.GetDefinitionInfo then
        definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    end

    local spellID = definitionInfo and (definitionInfo.spellID or definitionInfo.overrideSpellID)
    local spellName, icon = GetSpellInfoSafe(spellID)

    local name = spellName
        or (definitionInfo and (definitionInfo.overrideName or definitionInfo.name))
        or (entryInfo and entryInfo.name)
        or (spellID and ("Spell " .. spellID))
        or ("Talent " .. tostring(entryID))

    if not icon and definitionInfo then
        icon = definitionInfo.overrideIcon or definitionInfo.icon
    end

    return {
        entryID = entryID,
        spellID = spellID,
        name = name,
        icon = icon,
        subTreeID = entryInfo.subTreeID,
        definitionID = entryInfo.definitionID,
    }
end

local function ReadHeader(importStream)
    if not importStream or not importStream.GetNumberOfBits then
        return false, nil, nil
    end

    local minimumBits = HEADER_VERSION_BITS + HEADER_SPEC_BITS + (HEADER_HASH_BYTES * 8)
    if (importStream:GetNumberOfBits() or 0) < minimumBits then
        return false, nil, nil
    end

    local version = importStream:ExtractValue(HEADER_VERSION_BITS)
    local specID = importStream:ExtractValue(HEADER_SPEC_BITS)

    local treeHash = {}
    for index = 1, HEADER_HASH_BYTES do
        treeHash[index] = importStream:ExtractValue(8)
    end

    return true, version, specID, treeHash
end

local function IsHashEmpty(treeHash)
    if not treeHash or #treeHash ~= HEADER_HASH_BYTES then return true end
    for _, value in ipairs(treeHash) do
        if value ~= 0 then return false end
    end
    return true
end

local function HashEquals(a, b)
    if not a or not b or #a ~= #b then return false end
    for index = 1, #a do
        if a[index] ~= b[index] then return false end
    end
    return true
end

local function HasFlag(value, flag)
    if not value then return false end
    return (value % (flag * 2)) >= flag
end

local function GetTalentSection(configID, nodeID, nodeInfo)
    if nodeInfo and nodeInfo.subTreeID then
        return "Hero"
    end

    if C_Traits.GetNodeCost and C_Traits.GetTraitCurrencyInfo then
        local costs = C_Traits.GetNodeCost(configID, nodeID) or {}
        for _, cost in ipairs(costs) do
            local flags = C_Traits.GetTraitCurrencyInfo(cost.ID)
            if HasFlag(flags, 0x4) then return "Class" end
            if HasFlag(flags, 0x8) then return "Spec" end
        end
    end

    return "Class / Spec"
end

local function ReadLoadoutContent(importStream, treeID)
    local results = {}
    local treeNodes = C_Traits.GetTreeNodes(treeID) or {}

    for index = 1, #treeNodes do
        local isNodeSelected = importStream:ExtractValue(1) == 1
        local isNodePurchased = false
        local isPartiallyRanked = false
        local partialRanksPurchased = 0
        local isChoiceNode = false
        local choiceNodeSelection = 1

        if isNodeSelected then
            isNodePurchased = importStream:ExtractValue(1) == 1

            if isNodePurchased then
                isPartiallyRanked = importStream:ExtractValue(1) == 1
                if isPartiallyRanked then
                    partialRanksPurchased = importStream:ExtractValue(RANK_BITS)
                end

                isChoiceNode = importStream:ExtractValue(1) == 1
                if isChoiceNode then
                    -- Serialized choice index is zero-based; Lua's array index is one-based.
                    choiceNodeSelection = importStream:ExtractValue(2) + 1
                end
            end
        end

        results[index] = {
            isNodeSelected = isNodeSelected,
            isNodeGranted = isNodeSelected and not isNodePurchased,
            isPartiallyRanked = isPartiallyRanked,
            partialRanksPurchased = partialRanksPurchased,
            isChoiceNode = isChoiceNode,
            choiceNodeSelection = choiceNodeSelection,
        }
    end

    return results
end

local function AddSingleNodeEntry(results, treeNodeInfo, indexInfo)
    if not treeNodeInfo or not indexInfo or not indexInfo.isNodeSelected then return end

    local ranksGranted = indexInfo.isNodeGranted and 1 or 0
    local ranksPurchased = 0

    if not indexInfo.isNodeGranted then
        ranksPurchased = indexInfo.isPartiallyRanked and indexInfo.partialRanksPurchased or (treeNodeInfo.maxRanks or 1)
    end

    local selectionEntryID
    if indexInfo.isChoiceNode and indexInfo.choiceNodeSelection then
        selectionEntryID = treeNodeInfo.entryIDs and treeNodeInfo.entryIDs[indexInfo.choiceNodeSelection]
    elseif treeNodeInfo.activeEntry then
        selectionEntryID = treeNodeInfo.activeEntry.entryID
    end

    if not selectionEntryID and treeNodeInfo.entryIDs then
        selectionEntryID = treeNodeInfo.entryIDs[1]
    end

    if selectionEntryID then
        table.insert(results, {
            nodeID = treeNodeInfo.ID,
            ranksGranted = ranksGranted,
            ranksPurchased = ranksPurchased,
            selectionEntryID = selectionEntryID,
        })
    end
end

local function AddTieredNodeEntries(results, configID, treeNodeInfo, indexInfo)
    if not treeNodeInfo or not indexInfo or not indexInfo.isNodeSelected then return end

    local totalRanksPurchased = 0
    if not indexInfo.isNodeGranted then
        totalRanksPurchased = indexInfo.isPartiallyRanked and indexInfo.partialRanksPurchased or (treeNodeInfo.maxRanks or 1)
    end

    local remainingRanks = totalRanksPurchased
    for index, entryID in ipairs(treeNodeInfo.entryIDs or {}) do
        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
        if entryInfo then
            local ranksForEntry = math.min(remainingRanks, entryInfo.maxRanks or 1)
            local isGranted = indexInfo.isNodeGranted and index == 1
            if ranksForEntry > 0 or isGranted then
                table.insert(results, {
                    nodeID = treeNodeInfo.ID,
                    ranksGranted = isGranted and 1 or 0,
                    ranksPurchased = ranksForEntry,
                    selectionEntryID = entryID,
                })
            end
            remainingRanks = math.max(0, remainingRanks - ranksForEntry)
        end
    end
end

local function ConvertToImportEntries(configID, treeID, loadoutContent)
    local entries = {}
    local treeNodes = C_Traits.GetTreeNodes(treeID) or {}

    for index, treeNodeID in ipairs(treeNodes) do
        local treeNodeInfo = C_Traits.GetNodeInfo(configID, treeNodeID)
        local indexInfo = loadoutContent[index]

        if treeNodeInfo and indexInfo then
            if Enum and Enum.TraitNodeType and treeNodeInfo.type == Enum.TraitNodeType.Tiered then
                AddTieredNodeEntries(entries, configID, treeNodeInfo, indexInfo)
            else
                AddSingleNodeEntry(entries, treeNodeInfo, indexInfo)
            end
        end
    end

    return entries
end

local function GetSubTreeName(configID, subTreeID)
    if not subTreeID or not C_Traits.GetSubTreeInfo then return nil end
    local info = C_Traits.GetSubTreeInfo(configID, subTreeID)
    if not info then return nil end
    return info.name or info.displayName
end

local function IsSubTreeSelectionNode(nodeInfo)
    return nodeInfo
        and Enum
        and Enum.TraitNodeType
        and Enum.TraitNodeType.SubTreeSelection
        and nodeInfo.type == Enum.TraitNodeType.SubTreeSelection
end

local function IsActiveSubTreeNode(configID, nodeInfo)
    if not nodeInfo or not nodeInfo.subTreeID then
        return true
    end

    -- Hero talent choices retain purchased ranks in both subtrees so the player can
    -- switch hero trees without rebuilding them. Only one subtree is active, though.
    -- ViewLoadout therefore reports activeRank for talents in both saved subtrees.
    -- Filter on the live subtree-active state so the viewer mirrors the Blizzard UI.
    if nodeInfo.subTreeActive ~= nil then
        return nodeInfo.subTreeActive == true
    end

    if C_Traits.GetSubTreeInfo then
        local subTreeInfo = C_Traits.GetSubTreeInfo(configID, nodeInfo.subTreeID)
        if subTreeInfo and subTreeInfo.isActive ~= nil then
            return subTreeInfo.isActive == true
        end
    end

    -- Older clients/API edge cases may omit the active flag. Do not hide the node
    -- unless WoW explicitly tells us the subtree is inactive.
    return true
end

local function GatherSelectedTalents(configID, treeID)
    local talents = {}
    local seen = {}
    local treeNodes = C_Traits.GetTreeNodes(treeID) or {}

    for _, nodeID in ipairs(treeNodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        local shouldDisplay = nodeInfo
            and nodeInfo.isVisible ~= false
            and (nodeInfo.activeRank or 0) > 0
            and not IsSubTreeSelectionNode(nodeInfo)
            and IsActiveSubTreeNode(configID, nodeInfo)

        if shouldDisplay then
            local activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
            if not activeEntryID and nodeInfo.entryIDsWithCommittedRanks and #nodeInfo.entryIDsWithCommittedRanks > 0 then
                activeEntryID = nodeInfo.entryIDsWithCommittedRanks[1]
            end
            if not activeEntryID and nodeInfo.entryIDs then
                activeEntryID = nodeInfo.entryIDs[1]
            end

            local display = GetEntryDisplay(configID, activeEntryID)
            if display then
                local dedupeKey = tostring(nodeID) .. ":" .. tostring(activeEntryID)
                if not seen[dedupeKey] then
                    seen[dedupeKey] = true
                    table.insert(talents, {
                        nodeID = nodeID,
                        entryID = activeEntryID,
                        spellID = display.spellID,
                        name = display.name,
                        icon = display.icon,
                        rank = nodeInfo.activeRank or nodeInfo.currentRank or 1,
                        maxRank = nodeInfo.maxRanks or 1,
                        posX = nodeInfo.posX or 0,
                        posY = nodeInfo.posY or 0,
                        subTreeID = nodeInfo.subTreeID or display.subTreeID,
                        subTreeName = GetSubTreeName(configID, nodeInfo.subTreeID or display.subTreeID),
                        section = GetTalentSection(configID, nodeID, nodeInfo),
                    })
                end
            end
        end
    end

    table.sort(talents, function(a, b)
        if (a.posY or 0) == (b.posY or 0) then
            if (a.posX or 0) == (b.posX or 0) then
                return (a.name or "") < (b.name or "")
            end
            return (a.posX or 0) < (b.posX or 0)
        end
        return (a.posY or 0) < (b.posY or 0)
    end)

    return talents
end


local function IsSelectionNode(nodeInfo)
    return nodeInfo
        and Enum
        and Enum.TraitNodeType
        and (nodeInfo.type == Enum.TraitNodeType.Selection or nodeInfo.type == Enum.TraitNodeType.SubTreeSelection)
end

local function GetNodeDisplayEntryID(nodeInfo)
    if not nodeInfo then return nil end

    if nodeInfo.activeEntry and nodeInfo.activeEntry.entryID then
        return nodeInfo.activeEntry.entryID
    end

    if nodeInfo.entryIDsWithCommittedRanks and #nodeInfo.entryIDsWithCommittedRanks > 0 then
        return nodeInfo.entryIDsWithCommittedRanks[1]
    end

    if nodeInfo.nextEntry and nodeInfo.nextEntry.entryID then
        return nodeInfo.nextEntry.entryID
    end

    if nodeInfo.entryIDs and #nodeInfo.entryIDs > 0 then
        return nodeInfo.entryIDs[1]
    end
end

local function CopyVisibleEdges(nodeInfo)
    local edges = {}
    for _, edge in ipairs((nodeInfo and nodeInfo.visibleEdges) or {}) do
        table.insert(edges, {
            targetNode = edge.targetNode,
            type = edge.type,
            visualStyle = edge.visualStyle,
        })
    end
    return edges
end

local function GatherTalentTreeNodes(configID, treeID)
    local nodes = {}
    local subTrees = {}
    local treeNodes = C_Traits.GetTreeNodes(treeID) or {}

    for _, nodeID in ipairs(treeNodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        local shouldDisplay = nodeInfo
            and nodeInfo.isVisible ~= false
            and not IsSubTreeSelectionNode(nodeInfo)
            and IsActiveSubTreeNode(configID, nodeInfo)

        if shouldDisplay then
            local displayEntryID = GetNodeDisplayEntryID(nodeInfo)
            local display = GetEntryDisplay(configID, displayEntryID)

            if display then
                local subTreeID = nodeInfo.subTreeID or display.subTreeID
                local subTreeName = GetSubTreeName(configID, subTreeID)

                if subTreeID and C_Traits.GetSubTreeInfo and not subTrees[subTreeID] then
                    local info = C_Traits.GetSubTreeInfo(configID, subTreeID)
                    if info then
                        subTrees[subTreeID] = {
                            ID = info.ID or subTreeID,
                            name = info.name or info.displayName,
                            description = info.description,
                            isActive = info.isActive,
                            posX = info.posX,
                            posY = info.posY,
                        }
                    end
                end

                table.insert(nodes, {
                    nodeID = nodeID,
                    entryID = displayEntryID,
                    spellID = display.spellID,
                    name = display.name,
                    icon = display.icon,
                    rank = nodeInfo.activeRank or nodeInfo.currentRank or 0,
                    maxRank = nodeInfo.maxRanks or 1,
                    totalMaxRank = nodeInfo.totalMaxRanks or nodeInfo.maxRanks or 1,
                    selected = (nodeInfo.activeRank or 0) > 0,
                    posX = nodeInfo.posX or 0,
                    posY = nodeInfo.posY or 0,
                    subTreeID = subTreeID,
                    subTreeName = subTreeName,
                    subTreeActive = nodeInfo.subTreeActive,
                    section = GetTalentSection(configID, nodeID, nodeInfo),
                    nodeType = nodeInfo.type,
                    isChoice = IsSelectionNode(nodeInfo),
                    isTiered = Enum and Enum.TraitNodeType and nodeInfo.type == Enum.TraitNodeType.Tiered or false,
                    isAvailable = nodeInfo.isAvailable,
                    edges = CopyVisibleEdges(nodeInfo),
                })
            end
        end
    end

    table.sort(nodes, function(a, b)
        if (a.posY or 0) == (b.posY or 0) then
            if (a.posX or 0) == (b.posX or 0) then
                return (a.name or "") < (b.name or "")
            end
            return (a.posX or 0) < (b.posX or 0)
        end
        return (a.posY or 0) < (b.posY or 0)
    end)

    return nodes, subTrees
end

local function ApplyPreviewMetadata(decoded, previewLevel)
    if not decoded then return decoded end

    decoded.previewLevel = previewLevel
    local heroVisible = 0
    local heroSelected = 0
    for _, node in ipairs(decoded.treeNodes or {}) do
        if node.section == "Hero" then
            heroVisible = heroVisible + 1
            if node.selected then
                heroSelected = heroSelected + 1
            end
        end
    end

    decoded.heroVisible = heroVisible
    decoded.heroSelected = heroSelected
    decoded.heroIncomplete = previewLevel and previewLevel >= 90 and heroVisible > 0 and heroSelected < heroVisible
    return decoded
end

local function GetCurrentSpecID()
    if PlayerUtil and PlayerUtil.GetCurrentSpecID then
        local specID = PlayerUtil.GetCurrentSpecID()
        if specID then return specID end
    end

    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local specID = GetSpecializationInfo(specIndex)
        return specID
    end
end

function AGB:GetCurrentTalentPreview()
    if not C_ClassTalents or not C_Traits then
        return TalentError("The Retail class-talent APIs are not available.")
    end

    local specID = GetCurrentSpecID()
    if not specID then
        return TalentError("The current specialization could not be determined.")
    end

    local configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if not configID then
        return TalentError("WoW has not exposed an active talent configuration yet.")
    end

    local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    if not treeID then
        return TalentError("No talent tree is available for specialization " .. tostring(specID) .. ".")
    end

    local importString = ""
    if C_Traits.GenerateImportString then
        local okExport, generated = pcall(C_Traits.GenerateImportString, configID)
        if okExport and generated then
            importString = generated
        end
    end

    local talents = GatherSelectedTalents(configID, treeID)
    local visualNodes, subTrees = GatherTalentTreeNodes(configID, treeID)
    local level = UnitLevel and UnitLevel("player") or 90
    local decoded = {
        specID = specID,
        serializationVersion = C_Traits.GetLoadoutSerializationVersion and C_Traits.GetLoadoutSerializationVersion() or nil,
        configID = configID,
        treeID = treeID,
        entries = {},
        talents = talents,
        treeNodes = visualNodes,
        subTrees = subTrees,
        importString = importString,
        hashEmbedded = importString ~= "",
        hashValidated = importString ~= "",
        liveCharacter = true,
        label = "My Current Build",
    }

    return ApplyPreviewMetadata(decoded, level)
end

function AGB:GetTalentImportTransportStatus(importString)
    importString = strtrim(importString or "")
    if importString == "" then
        return nil, "No talent import string was supplied."
    end
    if not ExportUtil or not ExportUtil.MakeImportDataStream then
        return nil, "Blizzard's ExportUtil is not available in this client session."
    end
    if not C_ClassTalents or not C_Traits then
        return nil, "The Retail class-talent APIs are not available."
    end

    local okStream, importStream = pcall(ExportUtil.MakeImportDataStream, importString)
    if not okStream or not importStream then
        return nil, "The talent import string could not be decoded."
    end

    local okHeader, headerValid, serializationVersion, specID, treeHash = pcall(ReadHeader, importStream)
    if not okHeader or not headerValid or not specID then
        return nil, "The talent import string has an invalid header."
    end

    local currentVersion = C_Traits.GetLoadoutSerializationVersion and C_Traits.GetLoadoutSerializationVersion()
    local serializationCurrent = not currentVersion or serializationVersion == currentVersion
    local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    local hashEmbedded = treeHash and not IsHashEmpty(treeHash) or false
    local hashValidated = false
    if hashEmbedded and treeID and C_Traits.GetTreeHash then
        local currentHash = C_Traits.GetTreeHash(treeID)
        if currentHash then
            hashValidated = HashEquals(treeHash, currentHash)
        end
    end

    return {
        specID = specID,
        serializationVersion = serializationVersion,
        serializationCurrent = serializationCurrent,
        treeID = treeID,
        hashEmbedded = hashEmbedded,
        hashValidated = hashValidated,
        importSafe = serializationCurrent and hashEmbedded and hashValidated,
    }
end


local function GetGrantedConditionType()
    return Enum and Enum.TraitConditionType and Enum.TraitConditionType.Granted or 2
end

local function GetGrantedRanksFromConditions(configID, conditionIDs)
    if not C_Traits or not C_Traits.GetConditionInfo then return 0 end

    local grantedType = GetGrantedConditionType()
    local grantedRanks = 0
    for _, conditionID in ipairs(conditionIDs or {}) do
        local conditionInfo = C_Traits.GetConditionInfo(configID, conditionID)
        if conditionInfo
            and conditionInfo.type == grantedType
            and conditionInfo.isMet == true
            and (conditionInfo.ranksGranted or 0) > 0 then
            grantedRanks = math.max(grantedRanks, conditionInfo.ranksGranted or 0)
        end
    end
    return grantedRanks
end

local function GetDeterministicGrantedSelection(configID, nodeInfo)
    if not nodeInfo or IsSubTreeSelectionNode(nodeInfo) then return nil end
    if nodeInfo.subTreeID and not IsActiveSubTreeNode(configID, nodeInfo) then return nil end
    if (nodeInfo.activeRank or 0) > 0 then return nil end

    local nodeGrantedRanks = GetGrantedRanksFromConditions(configID, nodeInfo.conditionIDs)
    local grantedEntryID
    local grantedRanks = nodeGrantedRanks

    local entryIDs = nodeInfo.entryIDs or {}
    if #entryIDs == 1 then
        grantedEntryID = entryIDs[1]
        local entryInfo = C_Traits.GetEntryInfo(configID, grantedEntryID)
        if entryInfo then
            grantedRanks = math.max(grantedRanks, GetGrantedRanksFromConditions(configID, entryInfo.conditionIDs))
        end
    else
        -- Never guess a choice. Only accept a multi-entry node if Blizzard marks
        -- exactly one entry as granted in the live level/spec context.
        local matchedEntryID
        local matchedRanks = 0
        for _, entryID in ipairs(entryIDs) do
            local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
            local entryGrantedRanks = entryInfo and GetGrantedRanksFromConditions(configID, entryInfo.conditionIDs) or 0
            if entryGrantedRanks > 0 then
                if matchedEntryID then
                    return nil
                end
                matchedEntryID = entryID
                matchedRanks = entryGrantedRanks
            end
        end
        grantedEntryID = matchedEntryID
        grantedRanks = math.max(grantedRanks, matchedRanks)
    end

    if not grantedEntryID or grantedRanks <= 0 then return nil end
    local maxRanks = nodeInfo.maxRanks or 1
    return grantedEntryID, math.min(grantedRanks, maxRanks)
end

local function CopyImportEntries(entries)
    local copied = {}
    for _, entry in ipairs(entries or {}) do
        table.insert(copied, {
            nodeID = entry.nodeID,
            ranksGranted = entry.ranksGranted or 0,
            ranksPurchased = entry.ranksPurchased or 0,
            selectionEntryID = entry.selectionEntryID,
        })
    end
    return copied
end

function AGB:RepairMissingGrantedTalentRanks(decoded)
    if not decoded or decoded.liveCharacter then
        return decoded, false
    end
    if not decoded.configID or not decoded.treeID or not C_Traits or not C_ClassTalents then
        return decoded, false
    end

    local configID = decoded.configID
    local treeID = decoded.treeID
    local mergedEntries = CopyImportEntries(decoded.entries)
    local existingNodes = {}
    for _, entry in ipairs(mergedEntries) do
        if entry.nodeID then existingNodes[entry.nodeID] = true end
    end

    local repairs = {}
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        if not existingNodes[nodeID] then
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            local entryID, grantedRanks = GetDeterministicGrantedSelection(configID, nodeInfo)
            if entryID and grantedRanks and grantedRanks > 0 then
                table.insert(mergedEntries, {
                    nodeID = nodeID,
                    ranksGranted = grantedRanks,
                    ranksPurchased = 0,
                    selectionEntryID = entryID,
                })
                table.insert(repairs, {
                    nodeID = nodeID,
                    entryID = entryID,
                    ranksGranted = grantedRanks,
                })
                existingNodes[nodeID] = true
            end
        end
    end

    if #repairs == 0 then
        return decoded, false
    end

    -- The source transport omitted ranks that the live client itself declares as
    -- granted. Re-preview from the normalized entry list without reusing the stale
    -- source transport, so the live tree is authoritative for those free ranks.
    local okView, viewSuccess = pcall(C_ClassTalents.ViewLoadout, mergedEntries)
    if not okView or not viewSuccess then
        return decoded, false, "The live client could not apply deterministic granted-rank normalization."
    end

    decoded.sourceImportString = decoded.sourceImportString or decoded.importString
    decoded.entries = mergedEntries
    decoded.talents = GatherSelectedTalents(configID, treeID)
    decoded.treeNodes, decoded.subTrees = GatherTalentTreeNodes(configID, treeID)
    decoded.grantedRepairApplied = true
    decoded.grantedRepairCount = #repairs
    decoded.grantedRepairRanks = 0
    decoded.grantedRepairs = repairs
    for _, repair in ipairs(repairs) do
        decoded.grantedRepairRanks = decoded.grantedRepairRanks + (repair.ranksGranted or 0)
    end
    decoded.nativeImportUsesEntries = true
    ApplyPreviewMetadata(decoded, decoded.previewLevel or 90)

    -- Generate a current client transport when the view config supports it. The
    -- importer can still use the normalized entries directly if this is unavailable.
    if C_Traits.GenerateImportString then
        local okGenerate, generated = pcall(C_Traits.GenerateImportString, configID)
        if okGenerate and generated and generated ~= "" then
            local status = self:GetTalentImportTransportStatus(generated)
            if status and status.specID == decoded.specID and status.serializationCurrent then
                decoded.normalizedImportString = generated
            end
        end
    end

    return decoded, true
end

function AGB:DecodeReviewedSourceTalentBuild(importString, expectedSpecID, sourceID, previewLevel)
    local decoded, errorText = self:DecodeTalentImportString(importString, previewLevel or 90)
    if not decoded then return nil, errorText end

    if expectedSpecID and decoded.specID ~= expectedSpecID then
        return TalentError("Source build validation failed: the import string decodes to specialization " .. tostring(decoded.specID) .. ", not " .. tostring(expectedSpecID) .. ".")
    end

    if sourceID == "ugg" then
        local repaired, _, repairError = self:RepairMissingGrantedTalentRanks(decoded)
        if repaired then decoded = repaired end
        if repairError then decoded.grantedRepairError = repairError end
    end

    return decoded
end

function AGB:DecodeTalentImportString(importString, previewLevel)
    importString = strtrim(importString or "")
    if importString == "" then
        return TalentError("No talent import string was supplied.")
    end

    if not ExportUtil or not ExportUtil.MakeImportDataStream then
        return TalentError("Blizzard's ExportUtil is not available in this client session.")
    end
    if not C_ClassTalents or not C_Traits then
        return TalentError("The Retail class-talent APIs are not available.")
    end

    local okStream, importStream = pcall(ExportUtil.MakeImportDataStream, importString)
    if not okStream or not importStream then
        return TalentError("The talent import string could not be decoded.")
    end

    local okHeader, headerValid, serializationVersion, specID, treeHash = pcall(ReadHeader, importStream)
    if not okHeader or not headerValid or not specID then
        return TalentError("The talent import string has an invalid header.")
    end

    local currentVersion = C_Traits.GetLoadoutSerializationVersion and C_Traits.GetLoadoutSerializationVersion()
    if currentVersion and serializationVersion ~= currentVersion then
        return TalentError("This build uses talent serialization version " .. tostring(serializationVersion) .. ", but your client expects version " .. tostring(currentVersion) .. ".")
    end

    local level = previewLevel or 90
    local okInit, initError = pcall(C_ClassTalents.InitializeViewLoadout, specID, level)
    if not okInit then
        return TalentError("The client could not initialize a preview talent tree: " .. tostring(initError))
    end

    local configID = Constants and Constants.TraitConsts and Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    if not configID then
        return TalentError("The client did not expose VIEW_TRAIT_CONFIG_ID.")
    end

    local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    if not treeID then
        return TalentError("No talent tree is available for specialization " .. tostring(specID) .. ".")
    end

    local hashValidated = false
    local hashEmbedded = treeHash and not IsHashEmpty(treeHash)
    if hashEmbedded and C_Traits.GetTreeHash then
        local currentHash = C_Traits.GetTreeHash(treeID)
        if currentHash and not HashEquals(treeHash, currentHash) then
            return TalentError("This talent string was exported for an older/different version of this talent tree.")
        end
        hashValidated = currentHash and true or false
    end

    local okContent, loadoutContent = pcall(ReadLoadoutContent, importStream, treeID)
    if not okContent or not loadoutContent then
        return TalentError("The build ended before all current talent nodes could be read.")
    end

    local okEntries, entries = pcall(ConvertToImportEntries, configID, treeID, loadoutContent)
    if not okEntries or not entries then
        return TalentError("The build could not be converted to the current talent tree.")
    end

    local okView, viewSuccess = pcall(C_ClassTalents.ViewLoadout, entries, importString)
    if not okView or not viewSuccess then
        return TalentError("World of Warcraft rejected this build for preview. The talent tree may have changed.")
    end

    local talents = GatherSelectedTalents(configID, treeID)
    local visualNodes, subTrees = GatherTalentTreeNodes(configID, treeID)
    local decoded = {
        specID = specID,
        serializationVersion = serializationVersion,
        configID = configID,
        treeID = treeID,
        entries = entries,
        talents = talents,
        treeNodes = visualNodes,
        subTrees = subTrees,
        importString = importString,
        hashEmbedded = hashEmbedded,
        hashValidated = hashValidated,
        liveCharacter = false,
    }

    return ApplyPreviewMetadata(decoded, level)
end


local function BuildTalentNodeMap(decoded)
    local nodes = {}
    for _, node in ipairs((decoded and decoded.treeNodes) or {}) do
        if node.nodeID then
            nodes[node.nodeID] = node
        end
    end
    return nodes
end

local function GetComparisonState(targetNode, currentNode)
    local targetSelected = targetNode and targetNode.selected == true
    local currentSelected = currentNode and currentNode.selected == true

    if targetSelected and currentSelected then
        if targetNode.entryID and currentNode.entryID and targetNode.entryID ~= currentNode.entryID then
            return "choiceDiff"
        end

        local targetRank = targetNode.rank or 0
        local currentRank = currentNode.rank or 0
        if targetRank ~= currentRank then
            return "rankDiff"
        end
        return "match"
    elseif targetSelected then
        return "targetOnly"
    elseif currentSelected then
        return "currentOnly"
    end

    return "none"
end

local function GetDecodedHeroName(decoded)
    for _, node in ipairs((decoded and decoded.treeNodes) or {}) do
        if node.section == "Hero" and node.subTreeName and node.subTreeName ~= "" then
            return node.subTreeName
        end
    end
end

local function IsExactBundledGuideRecord(record)
    return record
        and record.exact == true
        and record.sourceValidated == true
        and record.importString
        and strtrim(record.importString) ~= ""
end

function AGB:GetGuideBuildCategory(specID, categoryKey)
    local root = self.GuideBuildData
    local specBuilds = root and root.builds and root.builds[specID]
    return specBuilds and specBuilds[categoryKey] or nil
end

function AGB:GetGuideBuildVariants(specID, categoryKey)
    local category = self:GetGuideBuildCategory(specID, categoryKey)
    local variants = {}
    if not category then return variants end

    -- Schema v2: each content category owns an ordered set of guide variants.
    if category.builds then
        local seen = {}
        local function AddVariant(variantKey)
            local record = category.builds[variantKey]
            if record and not seen[variantKey] then
                seen[variantKey] = true
                table.insert(variants, {
                    key = variantKey,
                    record = record,
                    exact = IsExactBundledGuideRecord(record),
                })
            end
        end

        for _, variantKey in ipairs(category.order or {}) do
            AddVariant(variantKey)
        end

        local extras = {}
        for variantKey, record in pairs(category.builds) do
            if not seen[variantKey] then
                table.insert(extras, {
                    key = variantKey,
                    record = record,
                })
            end
        end
        table.sort(extras, function(a, b)
            local aOrder = (a.record and a.record.sortOrder) or 9999
            local bOrder = (b.record and b.record.sortOrder) or 9999
            if aOrder ~= bOrder then return aOrder < bOrder end
            local aName = (a.record and (a.record.shortName or a.record.name)) or a.key
            local bName = (b.record and (b.record.shortName or b.record.name)) or b.key
            return tostring(aName) < tostring(bName)
        end)
        for _, item in ipairs(extras) do
            AddVariant(item.key)
        end
        return variants
    end

    -- Schema v1 compatibility: the category itself is the exact build record.
    table.insert(variants, {
        key = category.variantKey or category.key or categoryKey,
        record = category,
        exact = IsExactBundledGuideRecord(category),
    })
    return variants
end

function AGB:GetSelectedGuideVariantKey(specID, categoryKey)
    local variants = self:GetGuideBuildVariants(specID, categoryKey)
    if #variants == 0 then return nil end

    local saved
    if AzerothGuidebookDB and AzerothGuidebookDB.talentGuideVariants then
        local bySpec = AzerothGuidebookDB.talentGuideVariants[tostring(specID)]
        saved = bySpec and bySpec[categoryKey]
    end
    if saved then
        for _, option in ipairs(variants) do
            if option.key == saved then return saved end
        end
    end

    local category = self:GetGuideBuildCategory(specID, categoryKey)
    local defaultKey = category and category.defaultBuild
    if defaultKey then
        for _, option in ipairs(variants) do
            if option.key == defaultKey then return defaultKey end
        end
    end

    for _, option in ipairs(variants) do
        if option.record and option.record.recommended == true and option.exact then
            return option.key
        end
    end
    for _, option in ipairs(variants) do
        if option.exact then return option.key end
    end
    return variants[1].key
end

function AGB:SetSelectedGuideVariant(specID, categoryKey, variantKey)
    if not specID or not categoryKey or not variantKey then return false end
    local variants = self:GetGuideBuildVariants(specID, categoryKey)
    local valid = false
    for _, option in ipairs(variants) do
        if option.key == variantKey then
            valid = true
            break
        end
    end
    if not valid then return false end

    AzerothGuidebookDB = AzerothGuidebookDB or {}
    AzerothGuidebookDB.talentGuideVariants = AzerothGuidebookDB.talentGuideVariants or {}
    local specKey = tostring(specID)
    AzerothGuidebookDB.talentGuideVariants[specKey] = AzerothGuidebookDB.talentGuideVariants[specKey] or {}
    AzerothGuidebookDB.talentGuideVariants[specKey][categoryKey] = variantKey
    return true
end

function AGB:GetSelectedGuideVariant(specID, categoryKey)
    local variantKey = self:GetSelectedGuideVariantKey(specID, categoryKey)
    if not variantKey then return nil, nil end
    for _, option in ipairs(self:GetGuideBuildVariants(specID, categoryKey)) do
        if option.key == variantKey then
            return option.record, variantKey
        end
    end
    return nil, nil
end

function AGB:GetBundledGuideBuild(specID, categoryKey, variantKey)
    local category = self:GetGuideBuildCategory(specID, categoryKey)
    if not category then return nil end

    local record
    if category.builds then
        variantKey = variantKey or self:GetSelectedGuideVariantKey(specID, categoryKey)
        record = variantKey and category.builds[variantKey] or nil
    else
        record = category
    end

    if not IsExactBundledGuideRecord(record) then return nil end
    return record
end

function AGB:GetBundledGuideBuildStatus(specID, categoryKey, variantKey)
    local root = self.GuideBuildData
    local category = self:GetGuideBuildCategory(specID, categoryKey)

    if category and category.builds then
        variantKey = variantKey or self:GetSelectedGuideVariantKey(specID, categoryKey)
        local record = variantKey and category.builds[variantKey] or nil
        if record and (record.message or record.state) and not IsExactBundledGuideRecord(record) then
            return record
        end
    end

    local specStatus = root and root.status and root.status[specID]
    local categoryStatus = specStatus and specStatus[categoryKey] or nil
    if categoryStatus and categoryStatus.variants and variantKey and categoryStatus.variants[variantKey] then
        return categoryStatus.variants[variantKey]
    end
    return categoryStatus
end

function AGB:DecodeBundledGuideBuild(record)
    if not record then
        return TalentError("No exact bundled guide build is available for this selection.")
    end
    if record.exact ~= true or record.sourceValidated ~= true then
        return TalentError("This bundled guide record is not marked as an exact, source-validated transport.")
    end

    local importString = strtrim(record.importString or "")
    if importString == "" then
        return TalentError("This bundled guide record does not contain an import string.")
    end

    local decoded, errorText = self:DecodeTalentImportString(importString, record.previewLevel or 90)
    if not decoded then
        return nil, errorText
    end

    if record.specID and decoded.specID ~= record.specID then
        return TalentError("Bundled guide validation failed: the import string decodes to specialization " .. tostring(decoded.specID) .. ", not " .. tostring(record.specID) .. ".")
    end
    if decoded.heroIncomplete then
        return TalentError("Bundled guide validation failed: the level-90 build does not fully select its active Hero Talent tree.")
    end

    local expectedHero = strtrim(record.heroTree or "")
    if expectedHero ~= "" then
        local actualHero = GetDecodedHeroName(decoded)
        if not actualHero or string.lower(actualHero) ~= string.lower(expectedHero) then
            return TalentError("Bundled guide validation failed: expected Hero tree " .. expectedHero .. ", but the decoded build uses " .. tostring(actualHero or "none") .. ".")
        end
    end

    decoded.guideRuntimeRoundTrip = nil
    if C_Traits and C_Traits.GenerateImportString and decoded.configID then
        local okRoundTrip, generated = pcall(C_Traits.GenerateImportString, decoded.configID)
        if okRoundTrip and generated and generated ~= "" then
            decoded.guideRuntimeRoundTrip = generated == importString
            if not decoded.guideRuntimeRoundTrip then
                return TalentError("Bundled guide validation failed: WoW did not round-trip the exact import string after previewing it.")
            end
        end
    end

    decoded.label = (record.name or "Guide Build") .. " (Wowhead)"
    decoded.guideBuild = record
    decoded.guideBuildExact = true
    decoded.guideBuildValidated = true
    decoded.guideSourceURL = record.sourceURL
    decoded.guideSourceUpdated = record.sourceUpdated
    return decoded
end

function AGB:ActivateBundledGuideBuild(record, mode)
    mode = mode or "target"
    local decoded, errorText = self:DecodeBundledGuideBuild(record)
    if not decoded then
        return false, errorText
    end

    local _, _, displayedSpecID = self:GetActiveData()
    if displayedSpecID and decoded.specID ~= displayedSpecID then
        return false, "The bundled guide build does not match the specialization currently displayed in Azeroth Guidebook."
    end

    local current
    local comparison
    if mode == "compare" then
        current, errorText = self:GetCurrentTalentPreview()
        if not current then
            return false, errorText
        end
        if current.specID ~= decoded.specID then
            return false, "The bundled guide build is for a different specialization than your active character build."
        end
        comparison, errorText = self:BuildTalentComparison(decoded, current)
        if not comparison then
            return false, errorText
        end
    end

    self.customTalentPreview = decoded
    self.talentComparisonTarget = decoded
    self.talentComparisonLive = current
    self.talentComparison = comparison
    self.talentCompareMode = mode == "compare" and "compare" or "target"
    self.talentDifferenceFocusIndex = nil
    self.talentDifferenceFocusNodeID = nil
    self.talentDifferenceFocusSection = nil
    return true, decoded
end

function AGB:BuildTalentComparison(targetDecoded, currentDecoded)
    if not targetDecoded or not currentDecoded then
        return TalentError("Both a target build and the current character build are required for comparison.")
    end
    if targetDecoded.specID ~= currentDecoded.specID then
        return TalentError("The target build is for specialization " .. tostring(targetDecoded.specID) .. ", but your current specialization is " .. tostring(currentDecoded.specID) .. ".")
    end

    local targetMap = BuildTalentNodeMap(targetDecoded)
    local currentMap = BuildTalentNodeMap(currentDecoded)
    local nodeIDs = {}
    local seen = {}

    for nodeID in pairs(targetMap) do
        seen[nodeID] = true
        table.insert(nodeIDs, nodeID)
    end
    for nodeID in pairs(currentMap) do
        if not seen[nodeID] then
            table.insert(nodeIDs, nodeID)
        end
    end

    local summary = {
        match = 0,
        targetOnly = 0,
        currentOnly = 0,
        rankDiff = 0,
        choiceDiff = 0,
        totalDifferences = 0,
        selectedCompared = 0,
    }
    local sections = {}
    local nodes = {}

    local function GetSectionSummary(section)
        section = section or "Class / Spec"
        sections[section] = sections[section] or {
            match = 0,
            targetOnly = 0,
            currentOnly = 0,
            rankDiff = 0,
            choiceDiff = 0,
            totalDifferences = 0,
        }
        return sections[section]
    end

    for _, nodeID in ipairs(nodeIDs) do
        local targetNode = targetMap[nodeID]
        local currentNode = currentMap[nodeID]
        local baseNode = targetNode or currentNode
        local state = GetComparisonState(targetNode, currentNode)
        local section = baseNode and baseNode.section or "Class / Spec"
        local sectionSummary = GetSectionSummary(section)

        if state == "match" then
            summary.match = summary.match + 1
            summary.selectedCompared = summary.selectedCompared + 1
            sectionSummary.match = sectionSummary.match + 1
        elseif state == "targetOnly" then
            summary.targetOnly = summary.targetOnly + 1
            summary.selectedCompared = summary.selectedCompared + 1
            summary.totalDifferences = summary.totalDifferences + 1
            sectionSummary.targetOnly = sectionSummary.targetOnly + 1
            sectionSummary.totalDifferences = sectionSummary.totalDifferences + 1
        elseif state == "currentOnly" then
            summary.currentOnly = summary.currentOnly + 1
            summary.selectedCompared = summary.selectedCompared + 1
            summary.totalDifferences = summary.totalDifferences + 1
            sectionSummary.currentOnly = sectionSummary.currentOnly + 1
            sectionSummary.totalDifferences = sectionSummary.totalDifferences + 1
        elseif state == "rankDiff" then
            summary.rankDiff = summary.rankDiff + 1
            summary.selectedCompared = summary.selectedCompared + 1
            summary.totalDifferences = summary.totalDifferences + 1
            sectionSummary.rankDiff = sectionSummary.rankDiff + 1
            sectionSummary.totalDifferences = sectionSummary.totalDifferences + 1
        elseif state == "choiceDiff" then
            summary.choiceDiff = summary.choiceDiff + 1
            summary.selectedCompared = summary.selectedCompared + 1
            summary.totalDifferences = summary.totalDifferences + 1
            sectionSummary.choiceDiff = sectionSummary.choiceDiff + 1
            sectionSummary.totalDifferences = sectionSummary.totalDifferences + 1
        end

        table.insert(nodes, {
            nodeID = nodeID,
            section = section,
            state = state,
            target = targetNode,
            current = currentNode,
            posX = baseNode and baseNode.posX or 0,
            posY = baseNode and baseNode.posY or 0,
            name = (targetNode and targetNode.name) or (currentNode and currentNode.name) or ("Talent " .. tostring(nodeID)),
        })
    end

    table.sort(nodes, function(a, b)
        if (a.section or "") ~= (b.section or "") then
            return (a.section or "") < (b.section or "")
        end
        if (a.posY or 0) == (b.posY or 0) then
            if (a.posX or 0) == (b.posX or 0) then
                return (a.name or "") < (b.name or "")
            end
            return (a.posX or 0) < (b.posX or 0)
        end
        return (a.posY or 0) < (b.posY or 0)
    end)

    return {
        specID = targetDecoded.specID,
        target = targetDecoded,
        current = currentDecoded,
        nodes = nodes,
        summary = summary,
        sections = sections,
        targetHeroName = GetDecodedHeroName(targetDecoded),
        currentHeroName = GetDecodedHeroName(currentDecoded),
    }
end

local COMPARISON_SECTION_ORDER = {
    Class = 1,
    Spec = 2,
    Hero = 3,
    ["Class / Spec"] = 4,
}

function AGB:GetTalentComparisonDifferences(comparison)
    local differences = {}
    for _, record in ipairs((comparison and comparison.nodes) or {}) do
        if record.state ~= "match" and record.state ~= "none" then
            table.insert(differences, record)
        end
    end

    table.sort(differences, function(a, b)
        local aOrder = COMPARISON_SECTION_ORDER[a.section] or 99
        local bOrder = COMPARISON_SECTION_ORDER[b.section] or 99
        if aOrder ~= bOrder then return aOrder < bOrder end
        if (a.posY or 0) ~= (b.posY or 0) then return (a.posY or 0) < (b.posY or 0) end
        if (a.posX or 0) ~= (b.posX or 0) then return (a.posX or 0) < (b.posX or 0) end
        return (a.name or "") < (b.name or "")
    end)

    return differences
end

function AGB:ImportTargetTalentBuild(targetDecoded, loadoutName)
    if not targetDecoded or targetDecoded.liveCharacter then
        return false, "A pasted target build is required before it can be imported as a loadout."
    end
    if not targetDecoded.importString or targetDecoded.importString == "" then
        return false, "This target build does not contain an import string."
    end
    if targetDecoded.heroIncomplete then
        return false, "Import blocked because this level-90 target has an incomplete active Hero Talent tree. Paste a current build string and try again."
    end
    if not C_ClassTalents or not C_ClassTalents.ImportLoadout then
        return false, "The Blizzard talent-loadout import API is not available in this client session."
    end

    local currentSpecID = GetCurrentSpecID()
    if not currentSpecID or currentSpecID ~= targetDecoded.specID then
        return false, "The target build is for a different specialization than your currently active specialization."
    end

    loadoutName = strtrim(loadoutName or "")
    if loadoutName == "" then
        return false, "Enter a name for the new talent loadout."
    end

    if C_ClassTalents.CanCreateNewConfig then
        local okCanCreate, canCreate = pcall(C_ClassTalents.CanCreateNewConfig)
        if okCanCreate and canCreate == false then
            return false, "WoW cannot create another saved talent loadout right now. You may need to delete an existing loadout first."
        end
    end


    local configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if not configID then
        return false, "WoW has not exposed an active talent configuration yet."
    end

    local entries = targetDecoded.entries or {}
    if #entries == 0 then
        return false, "The target build did not contain any importable talent entries."
    end

    local okImport, success, importError
    if targetDecoded.nativeImportUsesEntries then
        -- A reviewed source may omit ranks that Blizzard grants automatically.
        -- In that case the normalized entry list is authoritative and the stale
        -- source transport is intentionally omitted from the native API call.
        okImport, success, importError = pcall(
            C_ClassTalents.ImportLoadout,
            configID,
            entries,
            loadoutName
        )
    else
        okImport, success, importError = pcall(
            C_ClassTalents.ImportLoadout,
            configID,
            entries,
            loadoutName,
            targetDecoded.importString
        )
    end
    if not okImport then
        return false, "WoW rejected the loadout import call: " .. tostring(success)
    end
    if not success then
        return false, importError and tostring(importError) or "WoW could not import this target build."
    end

    return true
end

function AGB:SetCustomTalentPreview(importString)
    local decoded, errorText = self:DecodeTalentImportString(importString, 90)
    if not decoded then
        self.customTalentPreview = nil
        self.talentComparisonTarget = nil
        self.talentComparisonLive = nil
        self.talentComparison = nil
        self.talentCompareMode = nil
        self.talentDifferenceFocusIndex = nil
        self.talentDifferenceFocusNodeID = nil
        self.talentDifferenceFocusSection = nil
        return false, errorText
    end

    local _, _, displayedSpecID = self:GetActiveData()
    if displayedSpecID and decoded.specID ~= displayedSpecID then
        local meta = self.SpecIndex and self.SpecIndex[decoded.specID]
        local targetData = meta and self.Data and self.Data[meta.classFile] and self.Data[meta.classFile][decoded.specID]
        local targetName
        if targetData then
            targetName = targetData.specName .. " " .. targetData.className
        elseif meta then
            targetName = meta.specName .. " " .. meta.className
        else
            targetName = "specialization ID " .. tostring(decoded.specID)
        end
        return false, "This import string is for " .. targetName .. ". Switch the guide browser to that specialization before previewing it."
    end

    self.customTalentPreview = decoded
    self.customTalentPreview.label = "Pasted Import String"
    self.talentComparisonTarget = decoded
    self.talentComparisonLive = nil
    self.talentComparison = nil
    self.talentCompareMode = "target"
    self.talentDifferenceFocusIndex = nil
    self.talentDifferenceFocusNodeID = nil
    self.talentDifferenceFocusSection = nil
    return true
end

function AGB:ClearCustomTalentPreview()
    self.customTalentPreview = nil
    self.talentComparisonTarget = nil
    self.talentComparisonLive = nil
    self.talentComparison = nil
    self.talentCompareMode = nil
    self.talentDifferenceFocusIndex = nil
    self.talentDifferenceFocusNodeID = nil
    self.talentDifferenceFocusSection = nil
end