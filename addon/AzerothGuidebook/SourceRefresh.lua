local addonName, AGB = ...

local REQUEST_PREFIX = "AGBREFRESH1"
local REQUIRED_COMPANION_PROTOCOL = 1
local COMPANION_HEARTBEAT_MAX_AGE = 300
local TERMINAL_STATES = {
    applied = true,
    review_required = true,
    blocked = true,
    failed = true,
    no_change = true,
}

local VALID_SOURCE_TABS = {
    Talents = true,
    Rotation = true,
    BiS = true,
    Consumables = true,
    ["Enchants & Gems"] = true,
    Stats = true,
}

local function SafeField(value, fallback)
    value = tostring(value or fallback or "")
    value = value:gsub("|", "-")
    return value
end


function AGB:GetSourceRefreshCompanionStatus()
    return self.CompanionStatus or {
        schemaVersion = 1,
        protocolVersion = REQUIRED_COMPANION_PROTOCOL,
        state = "not_installed",
        heartbeatEpoch = 0,
    }
end

function AGB:GetSourceRefreshCompanionAvailability()
    if self._sourceRefreshCompanionAvailability then
        return self._sourceRefreshCompanionAvailability
    end

    local status = self:GetSourceRefreshCompanionStatus()
    local result = {
        ready = false,
        state = tostring(status.state or "not_installed"),
        version = status.companionVersion,
        protocolVersion = tonumber(status.protocolVersion) or 0,
        heartbeatAt = status.heartbeatAt,
        heartbeatEpoch = tonumber(status.heartbeatEpoch) or 0,
        feedMode = status.feedMode,
        remoteFeedConfigured = status.remoteFeedConfigured == true,
        lastError = status.lastError,
    }

    if result.protocolVersion ~= REQUIRED_COMPANION_PROTOCOL then
        result.reason = "incompatible"
    elseif result.state ~= "running" then
        result.reason = result.state == "not_installed" and "not_installed" or "not_running"
    else
        local now = (GetServerTime and GetServerTime()) or (time and time()) or 0
        local age = now > 0 and result.heartbeatEpoch > 0 and (now - result.heartbeatEpoch) or 999999
        if age < -60 or age > COMPANION_HEARTBEAT_MAX_AGE then
            result.reason = "stale"
            result.heartbeatAge = age
        else
            result.ready = true
            result.reason = "ready"
            result.heartbeatAge = age
        end
    end

    -- CompanionStatus.generated.lua is loaded only when WoW loads/reloads the addon.
    -- Cache the decision for this UI session so a healthy heartbeat does not become
    -- artificially stale while the player remains logged in.
    self._sourceRefreshCompanionAvailability = result
    return result
end

function AGB:IsSourceRefreshCompanionReady()
    local availability = self:GetSourceRefreshCompanionAvailability()
    return availability and availability.ready == true, availability
end

function AGB:GetSourceRefreshGuideTab()
    local tab = AzerothGuidebookDB and AzerothGuidebookDB.lastGuideTab or "Talents"
    if not VALID_SOURCE_TABS[tab] then tab = "Talents" end
    return tab
end

function AGB:GetSourceRefreshCurrentScope()
    local data, _, specID = self:GetActiveData()
    if not data or not specID then return nil end

    local tabName = self:GetSourceRefreshGuideTab()
    local sourceID = self.GetSelectedGuideSource and self:GetSelectedGuideSource(specID, tabName) or "wowhead"
    local sourceLabel = self.GetGuideSourceLabel and self:GetGuideSourceLabel(sourceID) or tostring(sourceID)
    local contextKey = sourceID == "ugg" and self.GetGuideSourceContext and self:GetGuideSourceContext(specID) or nil
    local contextLabel = contextKey == "mythicplus" and "Mythic+" or (contextKey == "raid" and "Raid" or nil)

    return {
        specID = specID,
        specName = data.specName,
        className = data.className,
        tabName = tabName,
        sourceID = sourceID,
        sourceLabel = sourceLabel,
        contextKey = contextKey,
        contextLabel = contextLabel,
    }
end

function AGB:BuildSourceRefreshRequest(scope)
    scope = tostring(scope or "source")
    local current = self:GetSourceRefreshCurrentScope()
    if not current then return nil, "No bundled guide data is active." end

    if scope ~= "source" and scope ~= "spec" and scope ~= "all" then
        return nil, "Unknown source-refresh scope."
    end

    AzerothGuidebookDB = AzerothGuidebookDB or {}
    AzerothGuidebookDB.sourceRefreshCounter = (tonumber(AzerothGuidebookDB.sourceRefreshCounter) or 0) + 1
    local now = (GetServerTime and GetServerTime()) or (time and time()) or 0
    local requestID = tostring(now) .. "-" .. tostring(AzerothGuidebookDB.sourceRefreshCounter)

    local specID = scope == "all" and 0 or current.specID
    local sourceID = scope == "source" and current.sourceID or "all"
    local contextKey = scope == "source" and current.contextKey or ""
    local guideTab = scope == "source" and current.tabName or ""
    local payload = table.concat({
        REQUEST_PREFIX,
        SafeField(requestID),
        SafeField(scope),
        SafeField(specID),
        SafeField(sourceID),
        SafeField(contextKey),
        SafeField(guideTab),
        SafeField(self.VERSION or "unknown"),
    }, "|")

    local label
    if scope == "source" then
        label = tostring(current.specName) .. " " .. tostring(current.className) .. " | " .. tostring(current.sourceLabel)
    elseif scope == "spec" then
        label = tostring(current.specName) .. " " .. tostring(current.className) .. " | all sources"
    else
        label = "all 40 specs | all sources"
    end

    return {
        requestID = requestID,
        scope = scope,
        specID = specID,
        sourceID = sourceID,
        contextKey = contextKey,
        guideTab = guideTab,
        addonVersion = self.VERSION,
        payload = payload,
        label = label,
        current = current,
    }
end

function AGB:QueueSourceRefresh(scope)
    local companionReady, availability = self:IsSourceRefreshCompanionReady()
    if not companionReady then
        local reason = availability and availability.reason or "not_installed"
        local err = "Automatic source refresh is unavailable because the Azeroth Guidebook Companion is " .. tostring(reason):gsub("_", " ") .. "."
        if self.Print then self.Print(err) end
        return false, err
    end

    local request, err = self:BuildSourceRefreshRequest(scope)
    if not request then
        if self.Print then self.Print(err or "Unable to queue source refresh.") end
        return false, err
    end

    AzerothGuidebookDB.sourceRefreshRequest = request.payload
    AzerothGuidebookDB.sourceRefreshRequestLabel = request.label
    AzerothGuidebookDB.sourceRefreshRequestedAt = request.requestID
    if self.Print then
        self.Print("Submitting source refresh: " .. request.label .. ". The UI will reload now; the background companion will process it automatically.")
    end
    return true, request
end

function AGB:ClearSourceRefreshRequest()
    if not AzerothGuidebookDB then return end
    AzerothGuidebookDB.sourceRefreshRequest = nil
    AzerothGuidebookDB.sourceRefreshRequestLabel = nil
    AzerothGuidebookDB.sourceRefreshRequestedAt = nil
end

function AGB:GetQueuedSourceRefreshRequest()
    if not AzerothGuidebookDB then return nil end
    local payload = AzerothGuidebookDB.sourceRefreshRequest
    if not payload or payload == "" then return nil end

    local prefix, requestID, scope, specID, sourceID, contextKey, guideTab, version = strsplit("|", payload)
    if prefix ~= REQUEST_PREFIX or not requestID or not scope then return nil end
    return {
        payload = payload,
        requestID = requestID,
        scope = scope,
        specID = tonumber(specID) or 0,
        sourceID = sourceID or "all",
        contextKey = contextKey ~= "" and contextKey or nil,
        guideTab = guideTab ~= "" and guideTab or nil,
        addonVersion = version,
        label = AzerothGuidebookDB.sourceRefreshRequestLabel,
    }
end

function AGB:GetSourceRefreshState()
    return self.SourceRefreshState or { schemaVersion = 2, history = {}, entries = {} }
end

function AGB:ReconcileSourceRefreshState()
    local queued = self:GetQueuedSourceRefreshRequest()
    local state = self:GetSourceRefreshState()
    local lastRun = state and state.lastRun or nil
    if queued and lastRun and tostring(lastRun.requestID or "") == tostring(queued.requestID) and TERMINAL_STATES[tostring(lastRun.state or "")] then
        self:ClearSourceRefreshRequest()
    end
end

function AGB:GetSourceRefreshEntry(specID, sourceID)
    local state = self:GetSourceRefreshState()
    local entries = state and state.entries or nil
    if not entries then return nil end
    return entries[tostring(specID) .. ":" .. tostring(sourceID)]
end

function AGB:GetSourceRefreshStateLabel(state)
    state = tostring(state or "")
    if state == "applied" then return "Applied", {0.35, 1, 0.65} end
    if state == "no_change" then return "No change", {0.55, 0.85, 1} end
    if state == "review_required" then return "Review required", {1, 0.75, 0.35} end
    if state == "blocked" then return "Blocked", {1, 0.55, 0.25} end
    if state == "failed" then return "Failed", {1, 0.4, 0.3} end
    if state == "checking" then return "Checking", {0.55, 0.85, 1} end
    if state == "queued" then return "Queued", {0.75, 0.88, 1} end
    return "Not refreshed locally", {0.7, 0.7, 0.7}
end

local REFRESH_CHANGE_DOMAIN_LABELS = {
    talents = "Talents",
    bis = "Gear / BiS",
    consumables = "Consumables",
    enchants = "Enchants & Gems",
    stats = "Stats",
    rotation = "Rotation",
}

local REFRESH_CHANGE_DOMAIN_TABS = {
    talents = "Talents",
    bis = "BiS",
    consumables = "Consumables",
    enchants = "Enchants & Gems",
    stats = "Stats",
    rotation = "Rotation",
}

function AGB:GetSourceRefreshHistory()
    local state = self:GetSourceRefreshState()
    return state and state.history or {}
end

function AGB:GetSourceRefreshChangeDomainLabel(domain)
    return REFRESH_CHANGE_DOMAIN_LABELS[tostring(domain or "")] or tostring(domain or "Guide")
end

function AGB:GetSourceRefreshChangeStateLabel(state)
    state = tostring(state or "")
    if state == "changed" then return "Changed", {1, 0.82, 0.3} end
    if state == "date_only" then return "Source date advanced", {0.55, 0.9, 1} end
    if state == "unchanged" then return "No change", {0.35, 1, 0.65} end
    if state == "unavailable" then return "Detail unavailable", {0.75, 0.75, 0.75} end
    return state ~= "" and state or "Unknown", {0.75, 0.75, 0.75}
end

function AGB:GetSourceRefreshSpecLabel(specID)
    local meta = self.SpecIndex and self.SpecIndex[tonumber(specID)] or nil
    if not meta then return "Spec " .. tostring(specID or "?") end
    return tostring(meta.specName or "Spec") .. " " .. tostring(meta.className or "")
end

function AGB:OpenSourceRefreshChangedDomain(pack, domain)
    if not pack then return false end
    local specID = tonumber(pack.specID)
    local sourceID = tostring(pack.sourceID or "")
    local tabName = REFRESH_CHANGE_DOMAIN_TABS[tostring(domain or "")]
    if not specID or not tabName or sourceID == "" then return false end

    local meta = self.SpecIndex and self.SpecIndex[specID] or nil
    if not meta or not (self.Data[meta.classFile] and self.Data[meta.classFile][specID]) then
        if self.Print then self.Print("That refreshed specialization is not available in the current guide data.") end
        return false
    end

    self.previewSpecID = specID
    if self.ClearCustomTalentPreview then self:ClearCustomTalentPreview() end
    if self.SetSelectedGuideSource and not self:SetSelectedGuideSource(specID, tabName, sourceID) then
        if self.Print then self.Print("The refreshed source is not available for that guide domain.") end
        return false
    end

    AzerothGuidebookDB.lastTab = tabName
    AzerothGuidebookDB.lastGuideTab = tabName
    self._pendingGuideFocus = nil
    if self.UI and self.UI.guideMenu then self.UI.guideMenu:Hide() end
    self:RefreshUI()
    return true
end
