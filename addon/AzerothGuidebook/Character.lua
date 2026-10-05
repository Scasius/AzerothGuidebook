local addonName, AGB = ...

local SLOT_IDS = {
    Head = {1}, Helm = {1}, Neck = {2}, Shoulders = {3}, Shoulder = {3}, Chest = {5}, Waist = {6}, Legs = {7}, Feet = {8}, Boots = {8},
    Wrist = {9}, Bracers = {9}, Hands = {10}, ["Ring 1"] = {11, 12}, ["Ring 2"] = {11, 12}, Ring = {11, 12}, Rings = {11, 12},
    ["Ring ( Prismatic Focusing Iris )"] = {11, 12}, ["Trinket 1"] = {13, 14}, ["Trinket 2"] = {13, 14}, Trinket = {13, 14}, Trinkets = {13, 14},
    ["Trinket (Damage)"] = {13, 14}, ["Trinket (Defense)"] = {13, 14}, ["Trinket (Situationally)"] = {13, 14},
    Cloak = {15}, Back = {15}, Weapon = {16, 17}, ["Weapon (1h)"] = {16, 17}, ["Weapon (2h)"] = {16}, ["Main Hand"] = {16}, ["Off Hand"] = {17},
}

local ENCHANT_SLOTS = {
    Weapon = {16}, ["Weapon (1h)"] = {16}, ["Weapon (2h)"] = {16},
    ["Weapon (Defense)"] = {16}, ["Weapon (Offense)"] = {16},
    ["Main Hand"] = {16}, ["Off Hand"] = {17}, ["Both Weapons"] = {16, 17},
    Head = {1}, Helm = {1}, Helmet = {1}, Shoulders = {3}, Shoulder = {3}, Chest = {5},
    Wrist = {9}, Bracers = {9}, Back = {15}, Cloak = {15}, Legs = {7}, Feet = {8}, Boots = {8}, Ring = {11, 12}, Rings = {11, 12},
}


function AGB:GetCharacterLevelContext()
    local playerLevel = UnitLevel and UnitLevel("player") or nil
    local guideTargetLevel = tonumber(self.GUIDE_TARGET_LEVEL) or 90
    return {
        playerLevel = playerLevel,
        guideTargetLevel = guideTargetLevel,
        belowGuideTarget = playerLevel ~= nil and playerLevel > 0 and playerLevel < guideTargetLevel or false,
    }
end

local ENCHANT_SLOT_NAMES = {
    [1] = "Head", [3] = "Shoulders", [5] = "Chest", [7] = "Legs", [8] = "Boots", [9] = "Wrist",
    [11] = "Ring 1", [12] = "Ring 2", [15] = "Back", [16] = "Main Hand", [17] = "Off Hand",
}

-- Source-verified permanent enchant effect mappings.
-- These are added only when a specific guide consumable/item ID can be tied to a
-- specific equipped enchant effect ID without ambiguity. Unknown effects remain
-- fail-closed and fall back to tooltip-name comparison.
local ENCHANT_EFFECT_MAP = {
    [7935] = { itemID = 240133, name = "Sunfire Silk Spellthread", exact = true, sourceSpellID = 1229442 },
}

local function SplitItemLink(itemLink)
    if type(itemLink) ~= "string" then return nil end
    local payload = itemLink:match("|H(item:[^|]+)|h") or itemLink:match("^(item:[^|]+)$")
    if not payload then return nil end
    local values = {}
    for field in (payload .. ":"):gmatch("(.-):") do table.insert(values, field) end
    if values[1] ~= "item" then return nil end
    return {
        itemID = tonumber(values[2]) or 0,
        enchantID = tonumber(values[3]) or 0,
        gemIDs = {
            tonumber(values[4]) or 0,
            tonumber(values[5]) or 0,
            tonumber(values[6]) or 0,
            tonumber(values[7]) or 0,
        },
    }
end

function AGB:GetEquippedItemRecord(slotID)
    local itemID = GetInventoryItemID and GetInventoryItemID("player", slotID) or nil
    local itemLink = GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
    local parsed = SplitItemLink(itemLink)
    return {
        slotID = slotID,
        itemID = itemID or (parsed and parsed.itemID) or nil,
        itemLink = itemLink,
        enchantID = parsed and parsed.enchantID or 0,
        gemIDs = parsed and parsed.gemIDs or {},
    }
end

function AGB:GetGuideBiSItems(data, specID)
    local bis = data and data.bis
    if not bis then return {}, nil end
    local items = bis.items or {}
    local setName
    if bis.sets and next(bis.sets) then
        AzerothGuidebookDB.bisGuideSets = AzerothGuidebookDB.bisGuideSets or {}
        local requestedKey = AzerothGuidebookDB.bisGuideSets[specID] or bis.defaultSet
        local selectedSet = requestedKey and bis.sets[requestedKey] or nil
        if not selectedSet then
            local fallbackKey = bis.order and bis.order[1]
            requestedKey = fallbackKey
            selectedSet = fallbackKey and bis.sets[fallbackKey] or nil
        end
        if selectedSet then
            items = selectedSet.items or items
            setName = selectedSet.name or selectedSet.shortName or requestedKey
        end
    end
    return items, setName
end

local function IsGuideItemEquippedInSlots(itemID, slotLabel)
    local slots = SLOT_IDS[slotLabel]
    if not slots then
        return AGB:IsItemEquipped(itemID)
    end
    for _, slotID in ipairs(slots) do
        if GetInventoryItemID and GetInventoryItemID("player", slotID) == itemID then return true end
    end
    return false
end

local function AuditCharacterGearItems(items, setName)
    local results, counts = {}, { equipped = 0, owned = 0, missing = 0 }
    for _, item in ipairs(items or {}) do
        local status
        local auditSlot = item.auditSlot or item.slot
        if IsGuideItemEquippedInSlots(item.id, auditSlot) then
            status = "Equipped"
            counts.equipped = counts.equipped + 1
        elseif AGB:IsItemInBags(item.id) then
            status = "Owned"
            counts.owned = counts.owned + 1
        else
            status = "Missing"
            counts.missing = counts.missing + 1
        end
        table.insert(results, {
            slot = item.slot,
            auditSlot = auditSlot,
            id = item.id,
            name = item.name,
            source = item.source,
            popularity = item.popularity,
            sample = item.sample,
            status = status,
        })
    end
    return { items = results, counts = counts, setName = setName }
end

function AGB:GetCharacterBiSAudit(data, specID)
    local items, setName = self:GetGuideBiSItems(data, specID)
    return AuditCharacterGearItems(items, setName)
end

local function GetBagItemCount(itemID)
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false)
        if ok and count then return count end
    end
    if GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, false, false, false)
        if ok and count then return count end
    end
    return AGB:IsItemInBags(itemID) and 1 or 0
end

function AGB:GetCharacterConsumablesAudit(data)
    local results = {}
    for _, item in ipairs((data and data.consumables and data.consumables.items) or {}) do
        local count = GetBagItemCount(item.id)
        table.insert(results, { type = item.type, id = item.id, name = item.name, count = count, status = count > 0 and "Owned" or "Missing" })
    end
    return results
end

function AGB:GetEquippedGemIDs()
    local results = {}
    for slotID = 1, 17 do
        if slotID ~= 4 then
            local record = self:GetEquippedItemRecord(slotID)
            for _, gemID in ipairs(record.gemIDs or {}) do
                if gemID and gemID > 0 then table.insert(results, { slotID = slotID, gemID = gemID, itemID = record.itemID }) end
            end
        end
    end
    return results
end

local function ResolveCharacterItemName(itemID, fallback)
    if fallback and fallback ~= "" then return fallback end
    if C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, itemID)
        if ok and name and name ~= "" then return name end
    end
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemID)
        if ok and name and name ~= "" then return name end
    end
    return itemID and ("Item " .. tostring(itemID)) or "Unknown item"
end

function AGB:GetCharacterGemAudit(data)
    local recommended = (data and data.enchants and data.enchants.gems) or {}
    local equipped = self:GetEquippedGemIDs()
    local equippedSet = {}
    for _, gem in ipairs(equipped) do equippedSet[gem.gemID] = (equippedSet[gem.gemID] or 0) + 1 end
    local results = {}
    for _, gem in ipairs(recommended) do
        table.insert(results, {
            type = gem.type,
            id = gem.id,
            name = ResolveCharacterItemName(gem.id, gem.name),
            count = equippedSet[gem.id] or 0,
            status = (equippedSet[gem.id] or 0) > 0 and "Equipped" or "Not detected",
        })
    end
    return results, equipped
end

local function StripWoWTextMarkup(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("^%s*[Ee]nchanted:%s*", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("%s+", " ")
    return text ~= "" and text or nil
end

local function NormalizeEnchantText(text)
    text = StripWoWTextMarkup(text)
    if not text then return nil end
    text = text:gsub("’", "'"):gsub("‘", "'"):gsub("–", "-"):gsub("—", "-")
    text = text:gsub("^[Ff]ormula:%s*", "")
    text = text:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return text ~= "" and text or nil
end

local function GetEnchantAliases(name)
    local normalized = NormalizeEnchantText(name)
    if not normalized then return {} end
    local aliases = { normalized }
    local tail = normalized:match("^enchant%s+.-%s+%-%s+(.+)$")
    if tail and tail ~= normalized then table.insert(aliases, tail) end
    return aliases
end

local function TextMatchesEnchantName(detectedText, recommendationName)
    local detected = NormalizeEnchantText(detectedText)
    if not detected then return false end
    for _, alias in ipairs(GetEnchantAliases(recommendationName)) do
        if detected == alias or detected:find(alias, 1, true) then return true end
    end
    return false
end

local function GetPermanentEnchantText(slotID)
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then return nil end
    local ok, tooltipData = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID, false)
    if not ok or not tooltipData or not tooltipData.lines then return nil end
    local permanentType = (Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent) or 15
    for _, line in ipairs(tooltipData.lines) do
        if line and line.type == permanentType then
            local text = StripWoWTextMarkup(line.leftText) or StripWoWTextMarkup(line.rightText)
            if text then return text end
        end
    end
    return nil
end

local function GetKnownEnchantNameMatches(detectedText)
    local matches = {}
    local seen = {}
    if not detectedText then return matches end
    for _, classSpecs in pairs(AGB.Data or {}) do
        if type(classSpecs) == "table" then
            for _, specData in pairs(classSpecs) do
                if type(specData) == "table" and specData.enchants and specData.enchants.items then
                    for _, recommendation in ipairs(specData.enchants.items) do
                        local key = tostring(recommendation.name or "") .. ":" .. tostring(recommendation.id or recommendation.spellID or "")
                        if not seen[key] and TextMatchesEnchantName(detectedText, recommendation.name) then
                            seen[key] = true
                            table.insert(matches, recommendation)
                        end
                    end
                end
            end
        end
    end
    return matches
end

local function AddEnchantRecommendation(group, recommendation, sourceLabel)
    local key = table.concat({
        tostring(recommendation.id or ""), tostring(recommendation.spellID or ""),
        tostring(recommendation.name or ""), tostring(recommendation.context or ""), tostring(sourceLabel or "")
    }, "|")
    group._seen = group._seen or {}
    if group._seen[key] then return end
    group._seen[key] = true
    table.insert(group.recommendations, {
        id = recommendation.id,
        spellID = recommendation.spellID,
        name = recommendation.name,
        context = recommendation.context,
        sourceSlot = sourceLabel,
    })
end

function AGB:GetCharacterEnchantAudit(data)
    local groups = {}
    for _, enchant in ipairs((data and data.enchants and data.enchants.items) or {}) do
        local sourceLabel = enchant.slot or ""
        local slots = ENCHANT_SLOTS[sourceLabel]
        if slots then
            for _, slotID in ipairs(slots) do
                groups[slotID] = groups[slotID] or {
                    slot = ENCHANT_SLOT_NAMES[slotID] or sourceLabel,
                    slotID = slotID,
                    recommendations = {},
                    sourceSlots = {},
                }
                local group = groups[slotID]
                group.sourceSlots[sourceLabel] = true
                AddEnchantRecommendation(group, enchant, sourceLabel)
            end
        end
    end

    local orderedSlotIDs = {}
    for slotID in pairs(groups) do table.insert(orderedSlotIDs, slotID) end
    table.sort(orderedSlotIDs)

    local results = {}
    for _, slotID in ipairs(orderedSlotIDs) do
        local group = groups[slotID]
        group._seen = nil
        local record = self:GetEquippedItemRecord(slotID)
        local tooltipText = nil
        local matched = {}
        local status, matchLevel, rankVerified

        if not record.itemID then
            status = "No item equipped"
        elseif not record.enchantID or record.enchantID <= 0 then
            status = "No enchant detected"
        else
            local effectMapping = ENCHANT_EFFECT_MAP[record.enchantID or 0]
            local effectMappedToCurrentSlot = false
            if effectMapping then
                for _, recommendation in ipairs(group.recommendations) do
                    if (effectMapping.itemID and recommendation.id == effectMapping.itemID)
                        or (effectMapping.spellID and recommendation.spellID == effectMapping.spellID) then
                        table.insert(matched, recommendation)
                        effectMappedToCurrentSlot = true
                    end
                end
            end

            tooltipText = GetPermanentEnchantText(slotID)
            if not effectMappedToCurrentSlot and tooltipText then
                for _, recommendation in ipairs(group.recommendations) do
                    if TextMatchesEnchantName(tooltipText, recommendation.name) then
                        table.insert(matched, recommendation)
                    end
                end
            end

            if effectMappedToCurrentSlot then
                rankVerified = effectMapping.exact == true
                status = "Recommended enchant equipped"
                matchLevel = "effect-id"
            elseif effectMapping then
                status = "Different enchant detected"
                matchLevel = "known-effect-id"
            elseif #matched > 0 then
                -- Runeforges/source spell recommendations do not have crafted-item rank ambiguity.
                rankVerified = false
                for _, recommendation in ipairs(matched) do
                    if recommendation.spellID ~= nil and recommendation.id == nil then
                        rankVerified = true
                        break
                    end
                end
                status = rankVerified and "Recommended enchant equipped" or "Recommended enchant detected"
                matchLevel = rankVerified and "exact-name" or "name"
            elseif tooltipText then
                local knownMatches = GetKnownEnchantNameMatches(tooltipText)
                if #knownMatches > 0 then
                    status = "Different enchant detected"
                    matchLevel = "known-name"
                else
                    status = "Enchant present - exact comparison unavailable"
                end
            else
                status = "Enchant present - exact comparison unavailable"
            end
        end

        table.insert(results, {
            slot = group.slot,
            slotID = slotID,
            sourceSlots = group.sourceSlots,
            itemID = record.itemID,
            enchantID = record.enchantID or 0,
            enchantText = tooltipText,
            recommendations = group.recommendations,
            matchedRecommendations = matched,
            status = status,
            matchLevel = matchLevel,
            rankVerified = rankVerified == true,
            effectVerified = matchLevel == "effect-id",
        })
    end
    return results
end

function AGB:GetCharacterStatsSnapshot()
    local versatility = nil
    if GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
        versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
    end
    return {
        crit = GetCritChance and GetCritChance() or nil,
        haste = GetHaste and GetHaste() or nil,
        mastery = GetMasteryEffect and GetMasteryEffect() or nil,
        versatility = versatility,
    }
end

local function ApplyCharacterSourceMeta(target, sourceInfo)
    target = target or {}
    sourceInfo = sourceInfo or {}
    target.sourceID = sourceInfo.sourceID
    target.sourceLabel = sourceInfo.sourceLabel
    target.sourceType = sourceInfo.sourceType
    target.contextKey = sourceInfo.contextKey
    target.contextLabel = sourceInfo.contextLabel
    target.semantics = sourceInfo.semantics
    return target
end

function AGB:GetCharacterDomainSource(specID, tabName)
    local sourceID = self.GetSelectedGuideSource and self:GetSelectedGuideSource(specID, tabName) or "wowhead"
    if sourceID == "wowhead" or not self.GetMultiSourceDomain then
        return {
            sourceID = "wowhead",
            sourceLabel = "Wowhead",
            sourceType = "editorial",
            contextKey = "general",
            contextLabel = nil,
            domain = nil,
            source = nil,
            context = nil,
            semantics = "Editorial guide recommendations.",
        }
    end

    local contextKey = sourceID == "ugg" and self:GetGuideSourceContext(specID) or "general"
    local domain, source, context = self:GetMultiSourceDomain(specID, sourceID, tabName, contextKey)
    return {
        sourceID = sourceID,
        sourceLabel = source and source.label or self:GetGuideSourceLabel(sourceID),
        sourceType = sourceID == "ugg" and "observed" or (source and source.sourceType or "editorial"),
        contextKey = contextKey,
        contextLabel = context and context.label or nil,
        domain = domain,
        source = source,
        context = context,
        semantics = source and source.semantics or nil,
    }
end

local function BuildObservedGearAuditItems(domain)
    local items = {}
    for _, group in ipairs((domain and domain.groups) or {}) do
        local entries = group.entries or {}
        local groupSlot = tostring(group.slot or "Observed Gear")
        local limit = (groupSlot == "Trinkets" or groupSlot == "Crafted Items") and math.min(3, #entries) or math.min(1, #entries)
        for index = 1, limit do
            local entry = entries[index]
            local rowLabel = groupSlot
            if limit > 1 then rowLabel = rowLabel .. " #" .. tostring(index) end
            local sourceText = tostring(entry.popularity or "")
            if entry.sample and entry.sample ~= "" then
                sourceText = sourceText .. (sourceText ~= "" and " | " or "") .. tostring(entry.sample)
            end
            table.insert(items, {
                slot = rowLabel,
                auditSlot = groupSlot,
                id = entry.id,
                name = entry.name,
                source = sourceText,
                popularity = entry.popularity,
                sample = entry.sample,
            })
        end
    end
    return items
end

function AGB:GetCharacterBiSAuditForSelectedSource(data, specID)
    local info = self:GetCharacterDomainSource(specID, "BiS")
    local audit
    if info.sourceID == "icy-veins" and info.domain then
        audit = AuditCharacterGearItems(info.domain.items or {}, nil)
        audit.sectionLabel = "Best in Slot"
    elseif info.sourceID == "ugg" and info.domain then
        audit = AuditCharacterGearItems(BuildObservedGearAuditItems(info.domain), nil)
        audit.sectionLabel = "Observed Gear"
        audit.observed = true
    else
        audit = self:GetCharacterBiSAudit(data, specID)
        audit.sectionLabel = "Best in Slot"
    end
    return ApplyCharacterSourceMeta(audit, info)
end

local function InferCharacterConsumableLabel(item)
    local name = string.lower(tostring(item and item.name or ""))
    if string.find(name, "flask", 1, true) then return "Flask" end
    if string.find(name, "health potion", 1, true) then return "Health Potion" end
    if string.find(name, "potion", 1, true) or string.find(name, "draught", 1, true) then return "Combat Potion" end
    if string.find(name, "augment rune", 1, true) then return "Augment Rune" end
    if string.find(name, "vantus rune", 1, true) then return "Vantus Rune" end
    if string.find(name, "oil", 1, true) or string.find(name, "whetstone", 1, true) or string.find(name, "weightstone", 1, true) then return "Weapon Buff" end
    if string.find(name, "feast", 1, true) or string.find(name, "celebration", 1, true) or string.find(name, "parade", 1, true) then return "Feast" end
    if string.find(name, "food", 1, true) or string.find(name, "roast", 1, true) or string.find(name, "bento", 1, true) then return "Food" end
    return "Consumable"
end

function AGB:GetCharacterConsumablesAuditForSelectedSource(data, specID)
    local info = self:GetCharacterDomainSource(specID, "Consumables")
    local results
    if info.sourceID == "icy-veins" and info.domain then
        results = {}
        local skippedReferences = 0
        for _, item in ipairs(info.domain.items or {}) do
            if item.kind == "item" or item.kind == nil then
                local count = GetBagItemCount(item.id)
                table.insert(results, {
                    type = InferCharacterConsumableLabel(item),
                    id = item.id,
                    name = ResolveCharacterItemName(item.id, item.name),
                    count = count,
                    status = count > 0 and "Owned" or "Missing",
                })
            else
                skippedReferences = skippedReferences + 1
            end
        end
        results.skippedReferences = skippedReferences
    else
        results = self:GetCharacterConsumablesAudit(data)
    end
    return ApplyCharacterSourceMeta(results, info)
end

local function BuildCharacterEnchantAdapter(sourceID, domain)
    local items, gems = {}, {}
    if sourceID == "icy-veins" then
        for _, row in ipairs((domain and domain.rows) or {}) do
            for _, item in ipairs(row.items or {}) do
                table.insert(items, {
                    slot = row.slot,
                    id = item.id,
                    name = ResolveCharacterItemName(item.id, item.name),
                    context = item.tier,
                })
            end
        end
        for _, gem in ipairs((domain and domain.gems) or {}) do
            table.insert(gems, {
                type = "Gem",
                id = gem.id,
                name = ResolveCharacterItemName(gem.id, gem.name),
            })
        end
    elseif sourceID == "ugg" then
        for _, item in ipairs((domain and domain.bestEnchants) or {}) do
            table.insert(items, {
                slot = item.slot,
                id = item.id,
                name = ResolveCharacterItemName(item.id, item.name),
                context = "Observed U.GG selection",
            })
        end
        for _, gem in ipairs((domain and domain.gems) or {}) do
            table.insert(gems, {
                type = "Observed Gem",
                id = gem.id,
                name = ResolveCharacterItemName(gem.id, gem.name),
            })
        end
    end
    return { enchants = { items = items, gems = gems } }
end

function AGB:GetCharacterEnchantsAndGemsAuditForSelectedSource(data, specID)
    local info = self:GetCharacterDomainSource(specID, "Enchants & Gems")
    local auditData = data
    if info.sourceID ~= "wowhead" and info.domain then
        auditData = BuildCharacterEnchantAdapter(info.sourceID, info.domain)
    end
    local enchants = self:GetCharacterEnchantAudit(auditData)
    local gems, equippedGems = self:GetCharacterGemAudit(auditData)
    ApplyCharacterSourceMeta(enchants, info)
    ApplyCharacterSourceMeta(gems, info)
    enchants.observed = info.sourceType == "observed"
    gems.observed = info.sourceType == "observed"
    return enchants, gems, equippedGems
end

local function FormatCharacterSourcePriority(stats, relations)
    if not stats or #stats == 0 then return nil end
    local parts = { tostring(stats[1]) }
    for index = 2, #stats do
        local relation = relations and relations[index - 1] or ">"
        table.insert(parts, tostring(relation or ">"))
        table.insert(parts, tostring(stats[index]))
    end
    return table.concat(parts, " ")
end

function AGB:GetCharacterStatsGuideForSelectedSource(data, specID)
    local info = self:GetCharacterDomainSource(specID, "Stats")
    local guide = { variants = {} }
    if info.sourceID == "icy-veins" and info.domain then
        for index, variant in ipairs(info.domain.variants or {}) do
            table.insert(guide.variants, {
                label = variant.label or ("Variant " .. tostring(index)),
                priority = FormatCharacterSourcePriority(variant.stats, variant.relations),
            })
        end
    elseif info.sourceID == "ugg" and info.domain then
        table.insert(guide.variants, {
            label = (info.contextLabel or "U.GG") .. " observed stat priority",
            priority = table.concat(info.domain.priority or {}, " > "),
        })
        guide.observed = true
    else
        local statsData = data and data.stats or nil
        for index, variant in ipairs((statsData and statsData.variants) or {}) do
            table.insert(guide.variants, {
                label = variant.label or ("Variant " .. tostring(index)),
                priority = table.concat(variant.priority or {}, " > "),
            })
        end
        if #guide.variants == 0 and data and data.statPriority then
            table.insert(guide.variants, { label = "Stat Priority", priority = tostring(data.statPriority) })
        end
    end
    return ApplyCharacterSourceMeta(guide, info)
end

local function CharacterMultiSourceSelectionKey(specID, sourceID, contextKey)
    return tostring(specID or 0) .. ":" .. tostring(sourceID or "source") .. ":" .. tostring(contextKey or "general")
end

function AGB:GetCharacterMultiSourceTalentAudit(specID, sourceID)
    local contextKey = sourceID == "ugg" and self:GetGuideSourceContext(specID) or "general"
    local domain, source, context = self:GetMultiSourceDomain(specID, sourceID, "Talents", contextKey)
    local sourceLabel = source and source.label or self:GetGuideSourceLabel(sourceID)
    local contextLabel = context and context.label or nil
    local builds = domain and domain.builds or nil
    if not builds or #builds == 0 then
        return {
            status = "No exact guide build",
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end

    local selectedIndex = 1
    if AzerothGuidebookDB and AzerothGuidebookDB.multiSourceTalentBuilds then
        selectedIndex = tonumber(AzerothGuidebookDB.multiSourceTalentBuilds[CharacterMultiSourceSelectionKey(specID, sourceID, contextKey)]) or 1
    end
    if selectedIndex < 1 or selectedIndex > #builds then selectedIndex = 1 end
    local record = builds[selectedIndex]
    if not record or record.exact ~= true or not record.importString or record.importString == "" then
        return {
            status = "No exact guide build",
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end

    local target, targetErr = self:DecodeReviewedSourceTalentBuild(record.importString, specID, sourceID, 90)
    if not target then
        return {
            status = "Guide build unavailable",
            detail = targetErr,
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end
    if target.specID ~= specID then
        return {
            status = "Guide build unavailable",
            detail = "Selected source build decodes to specialization " .. tostring(target.specID) .. ", not " .. tostring(specID) .. ".",
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end

    local current, currentErr = self:GetCurrentTalentPreview()
    if not current then
        return {
            status = "Current build unavailable",
            detail = currentErr,
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end
    local comparison, compareErr = self:BuildTalentComparison(target, current)
    if not comparison then
        return {
            status = "Comparison unavailable",
            detail = compareErr,
            sourceID = sourceID,
            sourceLabel = sourceLabel,
            contextKey = contextKey,
            contextLabel = contextLabel,
        }
    end

    local label = record.label or record.name or ("Source Build " .. tostring(selectedIndex))
    return {
        status = comparison.summary.totalDifferences == 0 and "Exact match" or "Different",
        differences = comparison.summary.totalDifferences,
        compared = comparison.summary.selectedCompared,
        comparison = comparison,
        sourceID = sourceID,
        sourceLabel = sourceLabel,
        contextKey = contextKey,
        contextLabel = contextLabel,
        variantKey = tostring(selectedIndex),
        targetLabel = label,
    }
end

function AGB:GetCharacterTalentAudit(data, specID)
    if not data or not data.talents then return { status = "Unavailable" } end

    local sourceID = self.GetSelectedGuideSource and self:GetSelectedGuideSource(specID, "Talents") or "wowhead"
    if sourceID ~= "wowhead" and self.GetMultiSourceDomain then
        return self:GetCharacterMultiSourceTalentAudit(specID, sourceID)
    end

    local categoryKey = (AzerothGuidebookDB and AzerothGuidebookDB.lastTalentBuild) or "raid"
    local variants = self:GetGuideBuildVariants(specID, categoryKey)
    if not variants or #variants == 0 then return { status = "No exact guide build", categoryKey = categoryKey, sourceID = "wowhead", sourceLabel = "Wowhead" } end
    local record, variantKey = self:GetSelectedGuideVariant(specID, categoryKey)
    if not record then record = variants[1]; variantKey = record and record.key end
    if not record then return { status = "No exact guide build", categoryKey = categoryKey, sourceID = "wowhead", sourceLabel = "Wowhead" } end
    local target, targetErr = self:DecodeBundledGuideBuild(record)
    if not target then return { status = "Guide build unavailable", detail = targetErr, categoryKey = categoryKey, variantKey = variantKey, sourceID = "wowhead", sourceLabel = "Wowhead" } end
    local current, currentErr = self:GetCurrentTalentPreview()
    if not current then return { status = "Current build unavailable", detail = currentErr, categoryKey = categoryKey, variantKey = variantKey, sourceID = "wowhead", sourceLabel = "Wowhead" } end
    local comparison, compareErr = self:BuildTalentComparison(target, current)
    if not comparison then return { status = "Comparison unavailable", detail = compareErr, categoryKey = categoryKey, variantKey = variantKey, sourceID = "wowhead", sourceLabel = "Wowhead" } end
    return {
        status = comparison.summary.totalDifferences == 0 and "Exact match" or "Different",
        differences = comparison.summary.totalDifferences,
        compared = comparison.summary.selectedCompared,
        comparison = comparison,
        categoryKey = categoryKey,
        variantKey = variantKey,
        sourceID = "wowhead",
        sourceLabel = "Wowhead",
        targetLabel = record.label or record.name or variantKey,
    }
end

function AGB:GetCharacterAudit()
    local classFile, specID, specName = self:GetPlayerContext()
    local data = classFile and specID and self.Data[classFile] and self.Data[classFile][specID] or nil
    if not data then return nil end
    local levelContext = self:GetCharacterLevelContext()
    local talents = self:GetCharacterTalentAudit(data, specID)
    if levelContext.belowGuideTarget and (talents.status == "Exact match" or talents.status == "Different") then
        talents.maxLevelStatus = talents.status
        talents.status = "Partial comparison"
        talents.levelLimited = true
        talents.playerLevel = levelContext.playerLevel
        talents.guideTargetLevel = levelContext.guideTargetLevel
    end
    local enchants, gems, equippedGems = self:GetCharacterEnchantsAndGemsAuditForSelectedSource(data, specID)
    return {
        classFile = classFile,
        specID = specID,
        specName = specName or data.specName,
        data = data,
        playerLevel = levelContext.playerLevel,
        guideTargetLevel = levelContext.guideTargetLevel,
        belowGuideTarget = levelContext.belowGuideTarget,
        talents = talents,
        bis = self:GetCharacterBiSAuditForSelectedSource(data, specID),
        consumables = self:GetCharacterConsumablesAuditForSelectedSource(data, specID),
        gems = gems,
        equippedGems = equippedGems,
        enchants = enchants,
        stats = self:GetCharacterStatsSnapshot(),
        statsGuide = self:GetCharacterStatsGuideForSelectedSource(data, specID),
        rotationGuide = self:GetCharacterDomainSource(specID, "Rotation"),
    }
end

local function ActionPlanSourceSuffix(row)
    local parts = {}
    if row and row.sourceLabel and row.sourceLabel ~= "" then
        table.insert(parts, "Source: " .. tostring(row.sourceLabel))
    end
    if row and row.contextLabel and row.contextLabel ~= "" then
        table.insert(parts, "Context: " .. tostring(row.contextLabel))
    end
    if #parts == 0 then return "" end
    return " | " .. table.concat(parts, " | ")
end

local function AddActionPlanRow(plan, bucketName, row, weight)
    row = row or {}
    weight = tonumber(weight) or 1
    local bucket = plan[bucketName]
    table.insert(bucket, row)
    if bucketName == "remainingRows" then
        plan.remaining = plan.remaining + weight
        plan.domainRemaining[row.domain] = (plan.domainRemaining[row.domain] or 0) + weight
    elseif bucketName == "completedRows" then
        plan.completed = plan.completed + weight
        plan.domainCompleted[row.domain] = (plan.domainCompleted[row.domain] or 0) + weight
    else
        plan.informational = plan.informational + 1
    end
end

function AGB:GetCharacterActionPlan(audit)
    local plan = {
        remaining = 0,
        completed = 0,
        informational = 0,
        remainingRows = {},
        completedRows = {},
        referenceRows = {},
        domainRemaining = {},
        domainCompleted = {},
        deferred = audit and audit.belowGuideTarget == true or false,
    }
    if not audit then return plan end

    local talentAudit = audit.talents or {}
    local talentSuffix = ActionPlanSourceSuffix(talentAudit)
    if plan.deferred then
        AddActionPlanRow(plan, "referenceRows", {
            domain = "Talents",
            tabName = "Talents",
            action = "talent",
            text = "Talents: endgame adjustments deferred until level " .. tostring(audit.guideTargetLevel or "?") .. talentSuffix,
        })
    elseif talentAudit.status == "Different" and tonumber(talentAudit.differences or 0) > 0 then
        local differences = tonumber(talentAudit.differences or 0) or 0
        local text = "Talents: " .. tostring(differences) .. " difference(s) from the selected guide"
        if talentAudit.targetLabel then text = text .. " | " .. tostring(talentAudit.targetLabel) end
        AddActionPlanRow(plan, "remainingRows", {
            domain = "Talents",
            tabName = "Talents",
            action = "talentCompare",
            text = text .. talentSuffix,
        }, differences)
    elseif talentAudit.status == "Exact match" then
        local text = "Talents: exact match"
        if talentAudit.targetLabel then text = text .. " | " .. tostring(talentAudit.targetLabel) end
        AddActionPlanRow(plan, "completedRows", {
            domain = "Talents",
            tabName = "Talents",
            action = "talent",
            text = text .. talentSuffix,
        })
    else
        AddActionPlanRow(plan, "referenceRows", {
            domain = "Talents",
            tabName = "Talents",
            action = "talent",
            text = "Talents: " .. tostring(talentAudit.status or "comparison unavailable") .. talentSuffix,
        })
    end

    local gearAudit = audit.bis or {}
    if plan.deferred then
        AddActionPlanRow(plan, "referenceRows", {
            domain = "Gear",
            tabName = "BiS",
            text = (gearAudit.sectionLabel or "Gear") .. ": endgame adjustment plan deferred until level " .. tostring(audit.guideTargetLevel or "?") .. ActionPlanSourceSuffix(gearAudit),
        })
    else
        local function AddSingleGearItem(item)
            local focus = { itemID = item.id, name = item.name, slot = item.slot }
            local prefix = tostring(item.slot or "Slot") .. ": " .. tostring(item.name or item.id)
            if item.status == "Equipped" then
                AddActionPlanRow(plan, "completedRows", {
                    domain = "Gear", tabName = "BiS", focus = focus,
                    text = prefix .. " - equipped" .. ActionPlanSourceSuffix(gearAudit),
                })
            elseif item.status == "Owned" then
                AddActionPlanRow(plan, "remainingRows", {
                    domain = "Gear", tabName = "BiS", focus = focus,
                    text = prefix .. " - owned in bags; not equipped" .. ActionPlanSourceSuffix(gearAudit),
                })
            elseif item.status == "Missing" then
                local missingText = gearAudit.observed and "not owned (observed gear)" or "missing"
                AddActionPlanRow(plan, "remainingRows", {
                    domain = "Gear", tabName = "BiS", focus = focus,
                    text = prefix .. " - " .. missingText .. ActionPlanSourceSuffix(gearAudit),
                })
            else
                AddActionPlanRow(plan, "referenceRows", {
                    domain = "Gear", tabName = "BiS", focus = focus,
                    text = prefix .. " - " .. tostring(item.status or "not verifiable") .. ActionPlanSourceSuffix(gearAudit),
                })
            end
        end

        if gearAudit.observed then
            local craftedItems, trinketItems = {}, {}
            for _, item in ipairs(gearAudit.items or {}) do
                local auditSlot = tostring(item.auditSlot or item.slot or "")
                if auditSlot == "Crafted Items" then
                    table.insert(craftedItems, item)
                elseif auditSlot == "Trinkets" then
                    table.insert(trinketItems, item)
                else
                    AddSingleGearItem(item)
                end
            end

            -- U.GG's Crafted Items group is an observed popularity list rather than
            -- an additional equipment slot. Do not double-count those items when
            -- they also appear under Wrist/Feet/Belt or another real gear slot.
            if #craftedItems > 0 then
                local names = {}
                for index = 1, math.min(3, #craftedItems) do
                    local item = craftedItems[index]
                    table.insert(names, tostring(item.name or item.id))
                end
                local first = craftedItems[1]
                AddActionPlanRow(plan, "referenceRows", {
                    domain = "Gear",
                    tabName = "BiS",
                    focus = first and { itemID = first.id, name = first.name, slot = first.slot } or nil,
                    text = "Crafted Items: observed popular crafted choices are reference-only and are not counted separately from equipment-slot adjustments"
                        .. (#names > 0 and (" | " .. table.concat(names, ", ")) or "")
                        .. ActionPlanSourceSuffix(gearAudit),
                })
            end

            -- U.GG exposes several popular trinkets as alternatives. A character has
            -- only two trinket slots, so the action plan needs at most two matching
            -- source-listed options rather than requiring every observed alternative.
            if #trinketItems > 0 then
                local targetCount = math.min(2, #trinketItems)
                local equippedCount, ownedCount = 0, 0
                local firstOwned, firstMissing = nil, nil
                local exampleNames = {}
                for index, item in ipairs(trinketItems) do
                    if item.status == "Equipped" then
                        equippedCount = equippedCount + 1
                    elseif item.status == "Owned" then
                        ownedCount = ownedCount + 1
                        if not firstOwned then firstOwned = item end
                    elseif item.status == "Missing" and not firstMissing then
                        firstMissing = item
                    end
                    if index <= 3 then table.insert(exampleNames, tostring(item.name or item.id)) end
                end
                equippedCount = math.min(equippedCount, targetCount)
                local remainingCount = math.max(0, targetCount - equippedCount)

                if equippedCount > 0 then
                    AddActionPlanRow(plan, "completedRows", {
                        domain = "Gear",
                        tabName = "BiS",
                        focus = trinketItems[1] and { itemID = trinketItems[1].id, name = trinketItems[1].name, slot = trinketItems[1].slot } or nil,
                        text = "Trinkets: " .. tostring(equippedCount) .. "/" .. tostring(targetCount) .. " source-listed observed option(s) equipped" .. ActionPlanSourceSuffix(gearAudit),
                    }, equippedCount)
                end

                if remainingCount > 0 then
                    local focusItem = firstOwned or firstMissing or trinketItems[1]
                    local availableOwned = math.min(ownedCount, remainingCount)
                    local text = "Trinkets: " .. tostring(remainingCount) .. " adjustment(s) remaining | "
                        .. tostring(equippedCount) .. "/" .. tostring(targetCount) .. " source-listed observed option(s) equipped"
                    if availableOwned > 0 then
                        text = text .. " | " .. tostring(availableOwned) .. " source-listed option(s) owned in bags"
                    end
                    if #exampleNames > 0 then
                        text = text .. " | Options: " .. table.concat(exampleNames, ", ")
                    end
                    AddActionPlanRow(plan, "remainingRows", {
                        domain = "Gear",
                        tabName = "BiS",
                        focus = focusItem and { itemID = focusItem.id, name = focusItem.name, slot = focusItem.slot } or nil,
                        text = text .. ActionPlanSourceSuffix(gearAudit),
                    }, remainingCount)
                end
            end
        else
            for _, item in ipairs(gearAudit.items or {}) do
                AddSingleGearItem(item)
            end
        end
    end

    local enchantAudit = audit.enchants or {}
    if plan.deferred then
        AddActionPlanRow(plan, "referenceRows", {
            domain = "Enchants",
            tabName = "Enchants & Gems",
            text = "Enchants: endgame adjustment plan deferred until level " .. tostring(audit.guideTargetLevel or "?") .. ActionPlanSourceSuffix(enchantAudit),
        })
    else
        for _, entry in ipairs(enchantAudit) do
            local recommendation = (entry.recommendations and entry.recommendations[1]) or nil
            local focus = {
                itemID = recommendation and recommendation.id or nil,
                spellID = recommendation and recommendation.spellID or nil,
                name = recommendation and recommendation.name or nil,
                slot = (recommendation and recommendation.sourceSlot) or entry.slot,
            }
            local text = tostring(entry.slot or "Slot") .. ": " .. tostring(entry.status or "Unknown") .. ActionPlanSourceSuffix(enchantAudit)
            if entry.status == "Recommended enchant equipped" or entry.status == "Recommended enchant detected" then
                AddActionPlanRow(plan, "completedRows", {
                    domain = "Enchants", tabName = "Enchants & Gems", focus = focus, text = text,
                })
            elseif entry.status == "Different enchant detected" or entry.status == "No enchant detected" or entry.status == "No item equipped" then
                AddActionPlanRow(plan, "remainingRows", {
                    domain = "Enchants", tabName = "Enchants & Gems", focus = focus, text = text,
                })
            else
                AddActionPlanRow(plan, "referenceRows", {
                    domain = "Enchants", tabName = "Enchants & Gems", focus = focus, text = text,
                })
            end
        end
    end

    local consumables = audit.consumables or {}
    if plan.deferred then
        AddActionPlanRow(plan, "referenceRows", {
            domain = "Consumables",
            tabName = "Consumables",
            text = "Consumables: endgame adjustment plan deferred until level " .. tostring(audit.guideTargetLevel or "?") .. ActionPlanSourceSuffix(consumables),
        })
    else
        local function NormalizeActionPlanConsumableType(displayType)
            local normalizedType = tostring(displayType or "Consumable")
            normalizedType = normalizedType:gsub("^%s*[Aa]lt%.?%s+", "")
            normalizedType = normalizedType:gsub("^%s*[Aa]lternative%s+", "")

            -- Source guides frequently list a primary and an explicitly alternate
            -- flask/food row. Those rows are choices inside one consumable need,
            -- not separate purchases. Food/feast aliases are likewise one use slot.
            if normalizedType == "Feast"
                or normalizedType == "Personal Food"
                or normalizedType == "Secondary Feast"
                or normalizedType == "Agility Feast" then
                normalizedType = "Food"
            end

            return normalizedType
        end

        local groups, order = {}, {}
        for _, item in ipairs(consumables) do
            local displayType = tostring(item.type or "Consumable")
            local normalizedType = NormalizeActionPlanConsumableType(displayType)
            local key = normalizedType
            if normalizedType == "Consumable" then key = normalizedType .. ":" .. tostring(item.id or item.name or #order + 1) end
            if not groups[key] then
                local groupLabel = normalizedType
                if normalizedType == "Consumable" then
                    groupLabel = tostring(item.name or "Other Consumable")
                end
                groups[key] = { label = groupLabel, items = {}, owned = false }
                table.insert(order, key)
            end
            table.insert(groups[key].items, item)
            if (item.count or 0) > 0 then groups[key].owned = true end
        end
        for _, key in ipairs(order) do
            local group = groups[key]
            local first = group.items[1] or {}
            local focus = { itemID = first.id, name = first.name, slot = first.type }
            if group.owned then
                local ownedName = nil
                local ownedCount = 0
                for _, item in ipairs(group.items) do
                    if (item.count or 0) > 0 then
                        ownedName = item.name or item.id
                        ownedCount = item.count or 0
                        focus = { itemID = item.id, name = item.name, slot = item.type }
                        break
                    end
                end
                AddActionPlanRow(plan, "completedRows", {
                    domain = "Consumables", tabName = "Consumables", focus = focus,
                    text = tostring(group.label) .. ": source-listed option owned" .. (ownedName and (" - " .. tostring(ownedName) .. " x" .. tostring(ownedCount)) or "") .. ActionPlanSourceSuffix(consumables),
                })
            else
                local examples = {}
                for index = 1, math.min(3, #group.items) do
                    local option = group.items[index]
                    table.insert(examples, tostring(option.name or option.id))
                end
                local optionText = ""
                if #examples > 1 then
                    optionText = " | Options: " .. table.concat(examples, ", ")
                elseif #examples == 1 then
                    optionText = " | Example: " .. examples[1]
                end
                AddActionPlanRow(plan, "remainingRows", {
                    domain = "Consumables", tabName = "Consumables", focus = focus,
                    text = tostring(group.label) .. ": no source-listed option currently in bags" .. optionText .. ActionPlanSourceSuffix(consumables),
                })
            end
        end
    end

    local gemAudit = audit.gems or {}
    local gemMatches = 0
    for _, gem in ipairs(gemAudit) do
        if (gem.count or 0) > 0 then gemMatches = gemMatches + 1 end
    end
    AddActionPlanRow(plan, "referenceRows", {
        domain = "Gems",
        tabName = "Enchants & Gems",
        text = "Gems: " .. tostring(gemMatches) .. "/" .. tostring(#gemAudit) .. " source option(s) detected; alternatives remain informational" .. ActionPlanSourceSuffix(gemAudit),
    })

    local statsGuide = audit.statsGuide or {}
    local statsText = "Stats: selected guide priority is informational"
    for _, variant in ipairs(statsGuide.variants or {}) do
        if variant.priority and variant.priority ~= "" then
            statsText = "Stats: " .. tostring(variant.label or "Priority") .. " - " .. tostring(variant.priority)
            break
        end
    end
    AddActionPlanRow(plan, "referenceRows", {
        domain = "Stats",
        tabName = "Stats",
        text = statsText .. ActionPlanSourceSuffix(statsGuide),
    })

    local rotationGuide = audit.rotationGuide or {}
    AddActionPlanRow(plan, "referenceRows", {
        domain = "Rotation",
        tabName = "Rotation",
        text = "Rotation: open the selected source guidance" .. ActionPlanSourceSuffix(rotationGuide),
    })

    local domains = 0
    for _ in pairs(plan.domainRemaining) do domains = domains + 1 end
    plan.remainingDomains = domains
    return plan
end