--[[
  Playerbots Census - released under GNU GPL v2, matching mod-playerbots-bis.

  Counts who is online and breaks it down by class, race, level, zone and guild.

  There is exactly one channel a 3.3.5 client has for this, the /who query, so
  that is what this sweeps: one query per character level. Two numbers come back
  from each one. GetNumWhoResults() returns the rows the server was willing to
  send, capped by worldserver.conf MaxWhoListReturns (49 by default), and the
  total number of characters that matched, which is NOT capped - AzerothCore
  writes it in HandleWhoOpcode as matchCount, separate from displaycount. So the
  level histogram and the population total are exact even past the cap, and only
  the class/race/zone detail is limited to the rows we are handed.

  Written for the 3.3.5a client: SendWho / SetWhoToUI / GetNumWhoResults /
  GetWhoInfo as plain globals. The C_FriendList namespace those live in on
  retail and on WotLK Classic (Interface 30400) does not exist here, which is
  why CensusPlusWotlk cannot run on this client.

  A /who only ever returns your own faction unless your account carries the
  two-side who-list permission, so on a normal account the numbers below are
  your faction only.
]]

local ADDON = "PlayerbotsCensus"
local VERSION = "1.0"

local MAX_ROWS = 18          -- bar rows drawn in the list
local QUERY_TIMEOUT = 6.0    -- give up on a level if no WHO_LIST_UPDATE arrives

-- Class colours, keyed by the English token GetWhoInfo returns as its 7th value.
local CLASS_COLOR = {
    WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER  = { 0.67, 0.83, 0.45 }, ROGUE   = { 1.00, 0.96, 0.41 },
    PRIEST  = { 1.00, 1.00, 1.00 }, DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN  = { 0.00, 0.44, 0.87 }, MAGE    = { 0.41, 0.80, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 }, DRUID   = { 1.00, 0.49, 0.04 },
}

-- Fallback only. LOCALIZED_CLASS_NAMES_MALE is preferred when the client has it,
-- so the addon follows the client locale instead of hardcoding one.
local CLASS_FR = {
    WARRIOR = "Guerrier", PALADIN = "Paladin", HUNTER = "Chasseur",
    ROGUE = "Voleur", PRIEST = "Pretre", DEATHKNIGHT = "Chevalier de la mort",
    SHAMAN = "Chaman", MAGE = "Mage", WARLOCK = "Demoniste", DRUID = "Druide",
}

local defaults = {
    maxLevel = 80,   -- sweep 1..maxLevel. Drop it to your realm cap to halve the time.
    delay    = 1.5,  -- seconds between queries; the client throttles /who if pushed
    keep     = 8,    -- snapshots retained in SavedVariables
    rawRows  = true, -- store the per-character rows, not just the totals
}

local db
local ui
local lastResult    -- aggregates of the most recent completed sweep

local scan = {
    running  = false,
    phase    = nil,   -- "total" then "levels"
    level    = 0,
    waiting  = false,
    elapsed  = 0,
    rows     = {},
    seen     = {},
    byLevel  = {},    -- level -> exact server-side match count
    missed   = {},    -- level -> rows the cap withheld
    total    = 0,     -- exact population from the unfiltered query
    started  = 0,
    prevWhoToUI = nil,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99" .. ADDON .. "|r: " .. msg)
end

local function ClassLabel(token, localized)
    if token and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] then
        return LOCALIZED_CLASS_NAMES_MALE[token]
    end
    if localized and localized ~= "" then
        return localized
    end
    return token and (CLASS_FR[token] or token) or "?"
end

local function Timestamp()
    return date("%Y-%m-%d %H:%M:%S")
end

--------------------------------------------------------------------------------
-- Sweep
--------------------------------------------------------------------------------

local driver = CreateFrame("Frame")

local function SendQuery(text)
    scan.waiting = true
    scan.elapsed = 0
    SendWho(text)
end

local function StartScan()
    if scan.running then
        Print("Balayage deja en cours.")
        return
    end
    if type(SendWho) ~= "function" or type(GetNumWhoResults) ~= "function" then
        Print("|cffff2020Ce client n'expose pas SendWho/GetNumWhoResults.|r")
        return
    end

    scan.running = true
    scan.phase   = "total"
    scan.level   = 0
    scan.rows    = {}
    scan.seen    = {}
    scan.byLevel = {}
    scan.missed  = {}
    scan.total   = 0
    scan.started = GetTime()

    -- Route results to the UI rather than the chat frame, and put the setting
    -- back the way we found it when the sweep ends.
    scan.prevWhoToUI = 1
    if type(SetWhoToUI) == "function" then
        SetWhoToUI(1)
    end

    driver:Show()
    SendQuery("")        -- unfiltered: gives the exact population in one shot
    if ui then ui.Refresh() end
end

local function StopScan(silent)
    if not scan.running then return end
    scan.running = false
    scan.waiting = false
    driver:Hide()
    if type(SetWhoToUI) == "function" then
        SetWhoToUI(0)
    end
    if not silent then
        Print("Balayage interrompu.")
    end
    if ui then ui.Refresh() end
end

local function Aggregate()
    local res = {
        ts        = Timestamp(),
        realm     = GetRealmName(),
        faction   = UnitFactionGroup("player") or "?",
        total     = scan.total,
        collected = 0,
        withheld  = 0,
        byClass   = {},
        byRace    = {},
        byLevel   = {},
        byZone    = {},
        byGuild   = {},
        rows      = {},
    }

    for _, r in ipairs(scan.rows) do
        res.collected = res.collected + 1
        local cls = ClassLabel(r.token, r.class)
        res.byClass[cls] = (res.byClass[cls] or 0) + 1
        res.byRace[r.race] = (res.byRace[r.race] or 0) + 1
        res.byZone[r.zone] = (res.byZone[r.zone] or 0) + 1
        local g = (r.guild ~= "" and r.guild) or "(sans guilde)"
        res.byGuild[g] = (res.byGuild[g] or 0) + 1
        if db.rawRows then
            -- Each row repeats the snapshot header. It costs a few bytes and it
            -- makes every line in SavedVariables self-contained, so the export
            -- script never has to track which snapshot a row belongs to, and the
            -- CSV drops straight into a reporting tool as one flat fact table.
            table.insert(res.rows, table.concat({
                res.ts, res.realm, res.faction,
                r.name, r.guild, tostring(r.level), r.race,
                r.token or "", r.zone,
            }, "\t"))
        end
    end

    -- The level histogram uses the uncapped server counts, not the rows.
    for lvl, n in pairs(scan.byLevel) do
        if n > 0 then res.byLevel[lvl] = n end
    end
    for _, n in pairs(scan.missed) do
        res.withheld = res.withheld + n
    end

    -- Colour key for the class chart.
    res.classToken = {}
    for _, r in ipairs(scan.rows) do
        res.classToken[ClassLabel(r.token, r.class)] = r.token
    end

    return res
end

local function FinishScan()
    scan.running = false
    scan.waiting = false
    driver:Hide()
    if type(SetWhoToUI) == "function" then
        SetWhoToUI(0)
    end

    lastResult = Aggregate()

    table.insert(db.snapshots, {
        ts        = lastResult.ts,
        realm     = lastResult.realm,
        faction   = lastResult.faction,
        total     = lastResult.total,
        collected = lastResult.collected,
        withheld  = lastResult.withheld,
        rows      = lastResult.rows,
    })
    while table.getn(db.snapshots) > db.keep do
        table.remove(db.snapshots, 1)
    end

    local secs = math.floor(GetTime() - scan.started)
    Print(string.format("Termine en %ds : %d en ligne, %d details collectes.",
        secs, lastResult.total, lastResult.collected))
    if lastResult.withheld > 0 then
        Print(string.format("|cffffcc00%d lignes retenues par MaxWhoListReturns|r "
            .. "- les totaux restent exacts, seul le detail classe/race est partiel.",
            lastResult.withheld))
    end
    if lastResult.total > 0 and lastResult.collected == 0 then
        Print("|cffff2020Aucun detail recupere.|r Le client n'a peut-etre pas "
            .. "interprete le filtre de niveau. Voir /pbcensus aide.")
    end

    if ui then ui.Refresh() end
end

local function AdvanceScan()
    if scan.phase == "total" then
        scan.phase = "levels"
        scan.level = 0
    end

    scan.level = scan.level + 1
    if scan.level > db.maxLevel then
        FinishScan()
        return
    end
    SendQuery(scan.level .. "-" .. scan.level)
end

driver:SetScript("OnUpdate", function(self, elapsed)
    if not scan.running then return end
    scan.elapsed = scan.elapsed + (elapsed or 0)

    if scan.waiting then
        -- The server always answers a CMSG_WHO, but never hang the sweep on it.
        if scan.elapsed > QUERY_TIMEOUT then
            scan.waiting = false
            scan.elapsed = 0
            AdvanceScan()
        end
        return
    end

    if scan.elapsed >= db.delay then
        scan.elapsed = 0
        AdvanceScan()
    end
end)

local function OnWhoResults()
    if not scan.running or not scan.waiting then return end

    local shown, total = GetNumWhoResults()
    shown = shown or 0
    total = total or shown

    if scan.phase == "total" then
        scan.total = total
    else
        scan.byLevel[scan.level] = total
        if total > shown then
            scan.missed[scan.level] = total - shown
        end
        for i = 1, shown do
            local name, guild, level, race, class, zone, token = GetWhoInfo(i)
            if name and not scan.seen[name] then
                scan.seen[name] = true
                table.insert(scan.rows, {
                    name  = name,
                    guild = guild or "",
                    level = level or scan.level,
                    race  = race or "?",
                    class = class or "",
                    token = token,
                    zone  = zone or "?",
                })
            end
        end
    end

    scan.waiting = false
    scan.elapsed = 0
    if ui then ui.Refresh() end
end

--------------------------------------------------------------------------------
-- Interface
--------------------------------------------------------------------------------

local TABS = {
    { key = "byClass", label = "Classe" },
    { key = "byRace",  label = "Race" },
    { key = "byLevel", label = "Niveau" },
    { key = "byZone",  label = "Zone" },
    { key = "byGuild", label = "Guilde" },
}

local function BuildUI()
    local f = CreateFrame("Frame", "PlayerbotsCensusFrame", UIParent)
    f:SetWidth(440)
    f:SetHeight(500)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "PlayerbotsCensusFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Playerbots Census")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local head = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -44)
    head:SetJustifyH("LEFT")

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -3)
    note:SetJustifyH("LEFT")
    note:SetWidth(390)

    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetWidth(110)
    scanBtn:SetHeight(22)
    scanBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 18)
    scanBtn:SetText("Scanner")
    scanBtn:SetScript("OnClick", function()
        if scan.running then StopScan() else StartScan() end
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 24)
    hint:SetJustifyH("RIGHT")

    -- Tabs
    local tabButtons = {}
    local current = 1
    for i, tab in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetWidth(78)
        b:SetHeight(20)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 18 + (i - 1) * 80, -86)
        b:SetText(tab.label)
        b:SetScript("OnClick", function()
            current = i
            f.Refresh()
        end)
        tabButtons[i] = b
    end

    -- Bar rows
    local rows = {}
    for i = 1, MAX_ROWS do
        local r = CreateFrame("Frame", nil, f)
        r:SetWidth(396)
        r:SetHeight(18)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -112 - (i - 1) * 19)

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        r.bg:SetVertexColor(0, 0, 0, 0.25)

        r.fill = r:CreateTexture(nil, "ARTWORK")
        r.fill:SetPoint("TOPLEFT")
        r.fill:SetPoint("BOTTOMLEFT")
        r.fill:SetTexture("Interface\\Buttons\\WHITE8X8")

        r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.label:SetPoint("LEFT", r, "LEFT", 5, 0)
        r.label:SetJustifyH("LEFT")

        r.value = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.value:SetPoint("RIGHT", r, "RIGHT", -5, 0)
        r.value:SetJustifyH("RIGHT")

        r:Hide()
        rows[i] = r
    end

    local more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    more:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -112 - MAX_ROWS * 19 - 4)

    function f.Refresh()
        for i, b in ipairs(tabButtons) do
            if i == current then
                b:LockHighlight()
            else
                b:UnlockHighlight()
            end
        end

        scanBtn:SetText(scan.running and "Arreter" or "Scanner")

        if scan.running then
            local done = (scan.phase == "levels") and scan.level or 0
            head:SetText(string.format(
                "|cffffff00Balayage...|r  niveau %d / %d   -   %d en ligne, %d collectes",
                done, db.maxLevel, scan.total, table.getn(scan.rows)))
            note:SetText("")
        elseif lastResult then
            head:SetText(string.format(
                "|cff00ff00%d en ligne|r (%s, %s)   -   %d details   -   %s",
                lastResult.total, lastResult.realm, lastResult.faction,
                lastResult.collected, lastResult.ts))
            if lastResult.withheld > 0 then
                note:SetText(string.format(
                    "|cffffcc00%d lignes retenues par MaxWhoListReturns.|r Les totaux et "
                    .. "l'onglet Niveau restent exacts ; Classe/Race/Zone sont un echantillon.",
                    lastResult.withheld))
            else
                note:SetText("Detail complet : aucune ligne retenue par le serveur.")
            end
        else
            head:SetText("Aucun releve. Clique sur Scanner.")
            note:SetText(string.format(
                "Un /who par niveau, 1 a %d, %.1fs d'intervalle. Compte environ %d secondes.",
                db.maxLevel, db.delay, math.floor(db.maxLevel * db.delay) + 5))
        end

        hint:SetText(string.format("%d releve(s) archive(s)", db.snapshots and table.getn(db.snapshots) or 0))

        local data = lastResult and lastResult[TABS[current].key] or nil
        local list = {}
        if data then
            for k, v in pairs(data) do
                table.insert(list, { key = k, count = v })
            end
        end

        if TABS[current].key == "byLevel" then
            table.sort(list, function(a, b) return a.key > b.key end)
        else
            table.sort(list, function(a, b)
                if a.count == b.count then return tostring(a.key) < tostring(b.key) end
                return a.count > b.count
            end)
        end

        local max = 0
        for _, e in ipairs(list) do
            if e.count > max then max = e.count end
        end
        if max < 1 then max = 1 end

        for i = 1, MAX_ROWS do
            local e = list[i]
            local r = rows[i]
            if e then
                local label = tostring(e.key)
                if TABS[current].key == "byLevel" then
                    label = "Niveau " .. label
                end
                r.label:SetText(label)
                r.value:SetText(e.count)
                r.fill:SetWidth(math.max(1, 396 * e.count / max))
                local c = lastResult.classToken and CLASS_COLOR[lastResult.classToken[e.key] or ""]
                if c then
                    r.fill:SetVertexColor(c[1], c[2], c[3], 0.55)
                else
                    r.fill:SetVertexColor(0.25, 0.5, 0.85, 0.5)
                end
                r:Show()
            else
                r:Hide()
            end
        end

        local extra = table.getn(list) - MAX_ROWS
        more:SetText(extra > 0 and ("... et " .. extra .. " autres") or "")
    end

    return f
end

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------

local function Usage()
    Print("commandes :")
    Print("  /pbcensus            ouvre la fenetre")
    Print("  /pbcensus scan       lance un balayage")
    Print("  /pbcensus stop       l'interrompt")
    Print("  /pbcensus max <n>    dernier niveau balaye (actuel " .. db.maxLevel .. ")")
    Print("  /pbcensus delay <s>  intervalle entre requetes (actuel " .. db.delay .. ")")
    Print("  /pbcensus keep <n>   releves archives (actuel " .. db.keep .. ")")
    Print("  /pbcensus raw        stocke ou non le detail par personnage (actuel "
        .. (db.rawRows and "oui" or "non") .. ")")
    Print("  /pbcensus minimap    affiche ou masque le bouton")
    Print("  /pbcensus clear      vide l'archive")
end

local function HandleSlash(msg)
    msg = string.lower(msg or "")
    local cmd, arg = string.match(msg, "^(%S*)%s*(.-)$")

    if cmd == "" then
        if not ui then ui = BuildUI() end
        ui.Refresh()
        if ui:IsShown() then ui:Hide() else ui:Show() end
    elseif cmd == "scan" then
        if not ui then ui = BuildUI() end
        ui:Show()
        StartScan()
    elseif cmd == "stop" then
        StopScan()
    elseif cmd == "max" then
        local n = tonumber(arg)
        if n and n >= 1 and n <= 255 then
            db.maxLevel = math.floor(n)
            Print("dernier niveau balaye : " .. db.maxLevel)
        else
            Print("usage : /pbcensus max 60")
        end
    elseif cmd == "delay" then
        local n = tonumber(arg)
        if n and n >= 0.2 and n <= 10 then
            db.delay = n
            Print("intervalle : " .. db.delay .. "s")
        else
            Print("usage : /pbcensus delay 1.5")
        end
    elseif cmd == "keep" then
        local n = tonumber(arg)
        if n and n >= 1 and n <= 200 then
            db.keep = math.floor(n)
            Print("releves archives : " .. db.keep)
        else
            Print("usage : /pbcensus keep 8")
        end
    elseif cmd == "raw" then
        db.rawRows = not db.rawRows
        Print("detail par personnage : " .. (db.rawRows and "stocke" or "non stocke"))
    elseif cmd == "minimap" then
        local btn = _G.PlayerbotsCensusMinimapButton
        db.minimapHide = not db.minimapHide
        if btn then
            if db.minimapHide then btn:Hide() else btn:Show() end
        end
        Print(db.minimapHide and "bouton de minicarte masque." or "bouton de minicarte affiche.")
    elseif cmd == "clear" then
        db.snapshots = {}
        Print("archive videe.")
        if ui then ui.Refresh() end
    else
        Usage()
    end
end

--------------------------------------------------------------------------------
-- Minimap button
--------------------------------------------------------------------------------

-- Placed on a circle around the minimap and dragged along it, which is what a
-- button collector expects to find: a named Button parented to Minimap.
local MINIMAP_RADIUS = 80
local DEFAULT_ANGLE  = 190

local function PlaceOnRing(btn, angle)
    local rad = math.rad(angle)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
                 MINIMAP_RADIUS * math.cos(rad),
                 MINIMAP_RADIUS * math.sin(rad))
end

local function DragToRing(btn)
    local cx, cy = Minimap:GetCenter()
    if not cx then return end
    local scale = Minimap:GetEffectiveScale()
    local px, py = GetCursorPosition()
    px, py = px / scale, py / scale

    -- Same convention both ways: x = r*cos, y = r*sin, so atan2(dy, dx) is the
    -- angle PlaceOnRing wants back.
    local angle = math.deg(math.atan2(py - cy, px - cx))
    db.minimapAngle = angle
    PlaceOnRing(btn, angle)
end

local function BuildMinimapButton()
    if _G.PlayerbotsCensusMinimapButton then return _G.PlayerbotsCensusMinimapButton end

    local btn = CreateFrame("Button", "PlayerbotsCensusMinimapButton", Minimap)
    btn:SetWidth(31)
    btn:SetHeight(31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", DragToRing)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if scan.running then StopScan() else HandleSlash("scan") end
        else
            HandleSlash("")
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Playerbots Census")
        GameTooltip:AddLine("Clic gauche : ouvrir la fenetre", 1, 1, 1)
        GameTooltip:AddLine(scan.running and "Clic droit : arreter le balayage"
                                          or "Clic droit : lancer un balayage", 1, 1, 1)
        if lastResult then
            GameTooltip:AddLine(string.format("Dernier releve : %d en ligne (%s)",
                lastResult.total, lastResult.ts), 0.6, 0.6, 0.6)
        end
        GameTooltip:AddLine("Glisser : deplacer autour de la minicarte", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    PlaceOnRing(btn, db.minimapAngle or DEFAULT_ANGLE)
    return btn
end

--------------------------------------------------------------------------------
-- Bootstrap
--------------------------------------------------------------------------------

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("WHO_LIST_UPDATE")
boot:SetScript("OnEvent", function(self, event, arg1)
    if event == "WHO_LIST_UPDATE" then
        OnWhoResults()
        return
    end

    if event ~= "ADDON_LOADED" or arg1 ~= ADDON then return end

    PlayerbotsCensusDB = PlayerbotsCensusDB or {}
    db = PlayerbotsCensusDB
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    db.snapshots = db.snapshots or {}

    SLASH_PLAYERBOTSCENSUS1 = "/pbcensus"
    SLASH_PLAYERBOTSCENSUS2 = "/pbc"
    SlashCmdList["PLAYERBOTSCENSUS"] = HandleSlash

    local btn = BuildMinimapButton()
    if db.minimapHide then btn:Hide() end

    Print("v" .. VERSION .. " charge. /pbcensus pour ouvrir.")
end)

driver:Hide()
