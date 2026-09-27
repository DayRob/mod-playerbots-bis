--[[
  Playerbots BiS Plan - released under GNU GPL v2, matching mod-playerbots-bis.

  Which instance to run, and with which bots.

  The roster window says what each bot is missing; this one says where to go and
  get it. The crossing happens server side - the client has never known which
  creature drops what, nor where that creature lives - and arrives here over the
  same marked system messages the roster already uses.

  Run .playerbotsbis donjons in game to fill this window.
]]

local MARKER = "PBBISPLN;"

local ROW_HEIGHT   = 20
local VISIBLE_ROWS = 16
local RETRY_PERIOD = 0.4

local ROLE_DPS, ROLE_TANK, ROLE_HEALER = 0, 1, 2

local ROLE_LABEL = { [0] = "dps", [1] = "tank", [2] = "soigneur" }
local ROLE_COLOR = {
    [0] = "|cffc41f3b",   -- rouge
    [1] = "|cff4a90d9",   -- bleu
    [2] = "|cff40c040",   -- vert
}

local CLASS_COLOR = {
    [1] = { 0.78, 0.61, 0.43 }, [2] = { 0.96, 0.55, 0.73 },
    [3] = { 0.67, 0.83, 0.45 }, [4] = { 1.00, 0.96, 0.41 },
    [5] = { 1.00, 1.00, 1.00 }, [6] = { 0.77, 0.12, 0.23 },
    [7] = { 0.00, 0.44, 0.87 }, [8] = { 0.41, 0.80, 0.94 },
    [9] = { 0.58, 0.51, 0.79 }, [11] = { 1.00, 0.49, 0.04 },
}

local VIEW_LABEL = { "Groupe conseille", "Tous les bots concernes" }
local view = 1

local plan = { scope = "", when = "", dungeons = {}, byMap = {} }
local dungeonOpen = {}   -- mapId -> false when folded
local botOpen = {}       -- "mapId:name" -> true when its pieces are listed
local display = {}
local pending = {}
local win

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BiS|r: " .. msg)
end

local function ClassName(cls)
    return (PlayerbotsBis_ClassName and PlayerbotsBis_ClassName(cls)) or ("classe " .. tostring(cls))
end

local function SpecName(cls, spec)
    return (PlayerbotsBis_SpecName and PlayerbotsBis_SpecName(cls, spec)) or ("spe " .. tostring(spec))
end

local function RequestItem(id)
    if PlayerbotsBis_RequestItem then PlayerbotsBis_RequestItem(id) end
end

--------------------------------------------------------------------------------
-- Stream
--------------------------------------------------------------------------------

local function ResetPlan(count, scope)
    plan = { scope = scope or "", when = date("%H:%M:%S"), dungeons = {}, byMap = {}, expected = count }
    pending = {}
end

local function AddDungeon(mapId, targets, pieces, botCount, name)
    local d = {
        mapId = mapId, targets = targets, pieces = pieces, botCount = botCount,
        name = name, bots = {}, byName = {},
    }
    table.insert(plan.dungeons, d)
    plan.byMap[mapId] = d
    if dungeonOpen[mapId] == nil then
        dungeonOpen[mapId] = true   -- the group is the point, so show it at once
    end
end

local function AddBot(mapId, cls, spec, level, targets, pieces, role, chosen, reinforcement, name)
    local d = plan.byMap[mapId]
    if not d then return end

    local bot = {
        name = name, cls = cls, spec = spec, level = level,
        targets = targets, pieces = pieces, role = role,
        chosen = chosen, reinforcement = reinforcement, items = {},
    }
    table.insert(d.bots, bot)
    d.byName[name] = bot
end

local function AddItems(mapId, botName, packed)
    local d = plan.byMap[mapId]
    if not d then return end
    local bot = d.byName[botName]
    if not bot then return end

    -- The source name is free text and may hold spaces, so it runs to the next
    -- comma rather than matching a restricted character class.
    for id, chance, target, source in string.gmatch(packed, "(%d+):(%d+):(%d+):([^,]*)") do
        table.insert(bot.items, {
            id = tonumber(id), chance = tonumber(chance) / 10,
            target = target == "1", source = source,
        })
    end
end

--------------------------------------------------------------------------------
-- Display list
--------------------------------------------------------------------------------

local function Rebuild()
    display = {}
    pending = {}

    for _, d in ipairs(plan.dungeons) do
        table.insert(display, { dungeon = true, d = d })

        if dungeonOpen[d.mapId] then
            local listed = 0

            for _, bot in ipairs(d.bots) do
                if bot.chosen or view == 2 then
                    listed = listed + 1
                    local key = d.mapId .. ":" .. bot.name
                    table.insert(display, { bot = true, d = d, b = bot, key = key, open = botOpen[key] })

                    if botOpen[key] then
                        table.sort(bot.items, function(a, b)
                            if a.target ~= b.target then return a.target end
                            if a.chance ~= b.chance then return a.chance > b.chance end
                            return (a.id or 0) < (b.id or 0)
                        end)

                        for _, item in ipairs(bot.items) do
                            if not GetItemInfo(item.id) then
                                pending[item.id] = true
                                RequestItem(item.id)
                            end
                            table.insert(display, { item = true, b = bot, it = item })
                        end
                    end
                end
            end

            if listed == 0 then
                table.insert(display, { note = true, text = "aucun bot retenu pour cette instance" })
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local function RowEnter(self)
    if not self.itemId then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.itemId .. ":0:0:0:0:0:0:0") then
        -- The one thing the client cannot tell you about an item: where it comes
        -- from. A 3.3.5 tooltip has never carried a source.
        if self.source and self.source ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.source, 1, 0.82, 0)
            if self.chance and self.chance > 0 then
                GameTooltip:AddLine(string.format("%.1f%% de chance", self.chance), 0.6, 0.6, 0.6)
            end
        end
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

local function RowLeave() GameTooltip:Hide() end

local function RowClick(self)
    if self.mapId then
        dungeonOpen[self.mapId] = not dungeonOpen[self.mapId]
        win.Refresh(true)
        return
    end

    if self.botKey then
        botOpen[self.botKey] = not botOpen[self.botKey]
        win.Refresh(true)
        return
    end

    if self.itemId then
        local _, link = GetItemInfo(self.itemId)
        if IsShiftKeyDown() and link and ChatEdit_InsertLink then
            ChatEdit_InsertLink(link)
        elseif IsControlKeyDown() and link and DressUpItemLink then
            DressUpItemLink(link)
        end
    end
end

-- Typing the command in the chat box is exactly what SendChatMessage does, and
-- the server intercepts a line starting with '.' as a command before it is ever
-- broadcast, so nothing is said out loud.
local function RequestPlan()
    if not SendChatMessage then return false end
    return (pcall(SendChatMessage, ".playerbotsbis donjons", "SAY"))
end

PlayerbotsBisPlan_Request = RequestPlan

local function BuildWindow()
    local f = CreateFrame("Frame", "PlayerbotsBisPlanFrame", UIParent)
    f:SetWidth(600)
    f:SetHeight(470)
    f:SetPoint("CENTER", UIParent, "CENTER", 40, -20)
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
    tinsert(UISpecialFrames, "PlayerbotsBisPlanFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Plan de donjons")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local head = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -46)
    head:SetJustifyH("LEFT")

    local viewBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    viewBtn:SetWidth(190)
    viewBtn:SetHeight(20)
    viewBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -66)
    viewBtn:SetScript("OnClick", function()
        view = view == 1 and 2 or 1
        f.Refresh(true)
    end)

    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetWidth(120)
    refreshBtn:SetHeight(20)
    refreshBtn:SetPoint("LEFT", viewBtn, "RIGHT", 8, 0)
    refreshBtn:SetText("Actualiser")
    refreshBtn:SetScript("OnClick", function()
        if not RequestPlan() then
            Print("tape |cffffd100.playerbotsbis donjons|r pour actualiser.")
        end
    end)

    local scroll = CreateFrame("ScrollFrame", "PlayerbotsBisPlanScroll", f, "FauxScrollFrameTemplate")
    scroll:SetWidth(530)
    scroll:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -94)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() f.Refresh() end)
    end)

    local rows = {}
    for i = 1, VISIBLE_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(530)
        r:SetHeight(ROW_HEIGHT)
        r:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        r.bar = r:CreateTexture(nil, "BACKGROUND")
        r.bar:SetPoint("TOPLEFT")
        r.bar:SetPoint("BOTTOMLEFT")
        r.bar:SetTexture("Interface\\Buttons\\WHITE8X8")

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(16)
        r.icon:SetHeight(16)
        r.icon:SetPoint("LEFT", r, "LEFT", 6, 0)

        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetJustifyH("LEFT")
        r.text:SetWidth(360)

        r.info = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.info:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r.info:SetJustifyH("RIGHT")

        r:SetScript("OnEnter", RowEnter)
        r:SetScript("OnLeave", RowLeave)
        r:SetScript("OnClick", RowClick)
        r:RegisterForClicks("LeftButtonUp")
        rows[i] = r
    end

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 28, 20)
    hint:SetJustifyH("LEFT")
    hint:SetText("Clic sur un donjon ou un bot : deplier  -  Survol d'une piece : sa source"
                 .. "  -  Maj+clic : lien")

    function f.Refresh(rebuild)
        if rebuild then Rebuild() end

        viewBtn:SetText(VIEW_LABEL[view])

        if #plan.dungeons == 0 then
            head:SetText("Aucun plan. Tape |cffffd100.playerbotsbis donjons|r en jeu.")
        else
            local targets = 0
            for _, d in ipairs(plan.dungeons) do targets = targets + d.targets end
            head:SetText(string.format("%s  -  %d instance(s)  -  %d cible(s) a recuperer  -  releve de %s",
                plan.scope, #plan.dungeons, targets, plan.when))
        end

        FauxScrollFrame_Update(scroll, #display, VISIBLE_ROWS, ROW_HEIGHT)
        local offset = FauxScrollFrame_GetOffset(scroll)

        -- The busiest instance sets the scale of the bars, so the first line is
        -- always full and the rest read as a share of it.
        local top = 0
        for _, d in ipairs(plan.dungeons) do
            if d.targets > top then top = d.targets end
        end

        for i = 1, VISIBLE_ROWS do
            local e = display[i + offset]
            local r = rows[i]
            r.mapId, r.botKey, r.itemId, r.source, r.chance = nil, nil, nil, nil, nil

            if not e then
                r:Hide()
            else
                if e.dungeon then
                    local d = e.d
                    local ratio = top > 0 and (d.targets / top) or 0
                    r.bar:SetWidth(math.max(1, 530 * ratio))
                    r.bar:SetVertexColor(1.0, 0.82, 0.0, 0.22)
                    r.bar:Show()

                    r.icon:SetTexture(nil)
                    r.text:SetText(string.format("|cffffd100%s%s|r",
                        dungeonOpen[d.mapId] and "- " or "+ ", d.name))
                    r.info:SetText(string.format("|cffffffff%d cible(s)|r |cff808080/ %d piece(s) / %d bot(s)|r",
                        d.targets, d.pieces, d.botCount))
                    r.mapId = d.mapId
                elseif e.bot then
                    local bot = e.b
                    r.bar:Hide()
                    r.icon:SetTexture(nil)

                    local c = CLASS_COLOR[bot.cls] or { 0.5, 0.5, 0.5 }
                    local mark = (#bot.items > 0) and (e.open and "- " or "+ ") or "  "
                    local role = (ROLE_COLOR[bot.role] or "|cffffffff") .. (ROLE_LABEL[bot.role] or "?") .. "|r"

                    r.text:SetText(string.format("   %s|cff%02x%02x%02x%s|r  |cff999999%s %s niv %d|r  %s",
                        mark, c[1] * 255, c[2] * 255, c[3] * 255, bot.name,
                        ClassName(bot.cls), SpecName(bot.cls, bot.spec), bot.level, role))

                    if bot.reinforcement then
                        -- It gains nothing here; it is along so the run can
                        -- happen at all. Saying so stops the zero looking wrong.
                        r.info:SetText("|cff808080renfort|r")
                    else
                        r.info:SetText(string.format("|cffffffff%d cible(s)|r |cff808080/ %d|r",
                            bot.targets, bot.pieces))
                    end
                    r.botKey = e.key
                elseif e.note then
                    r.bar:Hide()
                    r.icon:SetTexture(nil)
                    r.text:SetText("      |cff808080" .. e.text .. "|r")
                    r.info:SetText("")
                else
                    local item = e.it
                    r.bar:Hide()

                    local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(item.id)
                    r.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

                    local prefix = item.target and "|cffffffff> |r" or "|cff707070  |r"
                    if name then
                        local hex = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
                        hex = (hex and hex.hex) or "|cffffffff"
                        r.text:SetText("      " .. prefix .. hex .. name .. "|r")
                    else
                        r.text:SetText("      " .. prefix .. "|cff808080Chargement... ("
                                       .. item.id .. ")|r")
                    end

                    -- A target at 0.9% is not a reason to go, and you have to be
                    -- able to see that without opening a database. The cuts sit
                    -- where Classic loot tables actually sit: a boss piece runs
                    -- 10-20%, anything under 3% is a grind rather than a plan.
                    local colour = "|cff1eff00"
                    if item.chance < 3 then colour = "|cffff2020"
                    elseif item.chance < 10 then colour = "|cffffcc00" end
                    r.info:SetText(string.format("|cff808080%s|r %s%.1f%%|r",
                        item.source or "", colour, item.chance or 0))

                    r.itemId = item.id
                    r.source = item.source
                    r.chance = item.chance
                end
                r:Show()
            end
        end
    end

    local since = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        if not next(pending) then return end
        since = since + (elapsed or 0)
        if since < RETRY_PERIOD then return end
        since = 0

        for id in pairs(pending) do
            if GetItemInfo(id) then
                self.Refresh(true)
                return
            end
        end
    end)

    return f
end

local function Toggle()
    if not win then win = BuildWindow() end
    if win:IsShown() then
        win:Hide()
    else
        win.Refresh(true)
        win:Show()
    end
end

PlayerbotsBisPlan_Toggle = Toggle

--------------------------------------------------------------------------------
-- Reception
--------------------------------------------------------------------------------

-- Same transport as the roster: marked system messages, hidden by a filter.
-- A filter runs once per chat frame, so the same line arrives once per frame
-- showing system messages. Those copies are back to back, so comparing against
-- the previous line is enough - and unlike a set of everything seen, it cannot
-- swallow a later plan whose header happens to be identical.
local lastRaw

local function Dispatch(payload, raw)
    if raw == lastRaw then return end
    lastRaw = raw

    local kind, rest = string.match(payload, "^(%a);(.*)$")
    if not kind then return end

    if kind == "S" then
        local count, scope = string.match(rest, "^(%d+);(.*)$")
        ResetPlan(tonumber(count) or 0, scope)
    elseif kind == "D" then
        local mapId, targets, pieces, botCount, name =
            string.match(rest, "^(%d+);(%d+);(%d+);(%d+);(.+)$")
        if mapId then
            AddDungeon(tonumber(mapId), tonumber(targets), tonumber(pieces),
                       tonumber(botCount), name)
        end
    elseif kind == "R" then
        local mapId, cls, spec, level, targets, pieces, role, chosen, reinforcement, name =
            string.match(rest, "^(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(%d);(%d);(.+)$")
        if mapId then
            AddBot(tonumber(mapId), tonumber(cls), tonumber(spec), tonumber(level),
                   tonumber(targets), tonumber(pieces), tonumber(role),
                   chosen == "1", reinforcement == "1", name)
        end
    elseif kind == "J" then
        local mapId, botName, packed = string.match(rest, "^(%d+);(.-);(.*)$")
        if mapId then AddItems(tonumber(mapId), botName, packed) end
    elseif kind == "E" then
        if not win then win = BuildWindow() end
        win.Refresh(true)
        win:Show()
        Print(string.format("%d instance(s) utiles.", #plan.dungeons))
    end
end

local function Filter(_, _, msg)
    if type(msg) ~= "string" then return false end
    if string.sub(msg, 1, string.len(MARKER)) ~= MARKER then return false end

    Dispatch(string.sub(msg, string.len(MARKER) + 1), msg)
    return true
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Filter)
else
    Print("|cffff2020ce client n'a pas ChatFrame_AddMessageEventFilter|r - "
          .. "le plan restera visible dans le tchat.")
end

SLASH_PBISPLAN1 = "/pbisplan"
SlashCmdList["PBISPLAN"] = function(msg)
    if msg and string.find(msg, "maj") then
        RequestPlan()
    else
        Toggle()
    end
end
