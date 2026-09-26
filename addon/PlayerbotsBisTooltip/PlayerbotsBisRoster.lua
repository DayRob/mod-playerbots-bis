--[[
  Playerbots BiS Roster - released under GNU GPL v2, matching mod-playerbots-bis.

  Shows, bot by bot, which of its best-in-slot pieces it actually wears.

  The data cannot be worked out client side: the spec a BiS list is keyed by is
  never stored anywhere, AiFactory recomputes it from the talents on demand. So
  the module works it out and streams the answer over the addon channel. Running
  .playerbotsbis report in game fills this window.

  Only rank-1 rows are sent: a slot is covered when the bot wears the piece the
  list picks for it, not one of its fallbacks.
]]

local PREFIX = "PBBISREP"

local ROW_HEIGHT   = 20
local VISIBLE_ROWS = 16
local RETRY_PERIOD = 0.4

local STATE_MISSING, STATE_CARRIED, STATE_EQUIPPED = 0, 1, 2

local CLASS_COLOR = {
    [1] = { 0.78, 0.61, 0.43 }, [2] = { 0.96, 0.55, 0.73 },
    [3] = { 0.67, 0.83, 0.45 }, [4] = { 1.00, 0.96, 0.41 },
    [5] = { 1.00, 1.00, 1.00 }, [6] = { 0.77, 0.12, 0.23 },
    [7] = { 0.00, 0.44, 0.87 }, [8] = { 0.41, 0.80, 0.94 },
    [9] = { 0.58, 0.51, 0.79 }, [11] = { 1.00, 0.49, 0.04 },
}

local roster = { scope = "", when = "", bots = {}, byName = {} }
local collapsed = {}       -- bot name -> true when its items are hidden
local missingOnly = true
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

local function TierName(tier)
    return (PlayerbotsBis_TierName and PlayerbotsBis_TierName(tier)) or ("palier " .. tostring(tier))
end

local function RequestItem(id)
    if PlayerbotsBis_RequestItem then PlayerbotsBis_RequestItem(id) end
end

--------------------------------------------------------------------------------
-- Stream
--------------------------------------------------------------------------------

local function ResetRoster(count, scope)
    roster = { scope = scope or "", when = date("%H:%M:%S"), bots = {}, byName = {}, expected = count }
    pending = {}
end

local function AddBot(name, cls, spec, level, equipped, total, carried, missing)
    local bot = {
        name = name, cls = cls, spec = spec, level = level,
        equipped = equipped, total = total, carried = carried, missing = missing,
        items = {},
    }
    table.insert(roster.bots, bot)
    roster.byName[name] = bot
    if collapsed[name] == nil then
        collapsed[name] = true   -- open on the overview, expand what interests you
    end
end

local function AddItems(name, packed)
    local bot = roster.byName[name]
    if not bot then return end

    for id, state, tier, slot in string.gmatch(packed, "(%d+):(%d+):(%d+):(%d+)") do
        table.insert(bot.items, {
            id = tonumber(id), state = tonumber(state),
            tier = tonumber(tier), slot = tonumber(slot),
        })
    end
end

--------------------------------------------------------------------------------
-- Display list
--------------------------------------------------------------------------------

local function Rebuild()
    display = {}
    pending = {}

    -- Worst covered first: the point of the window is to see who needs gear.
    table.sort(roster.bots, function(a, b)
        local ra = a.total > 0 and (a.equipped / a.total) or 1
        local rb = b.total > 0 and (b.equipped / b.total) or 1
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)

    for _, bot in ipairs(roster.bots) do
        table.insert(display, { header = true, bot = bot })
        if not collapsed[bot.name] then
            -- Slot order, then the worst state first inside a slot.
            local rows = {}
            for _, item in ipairs(bot.items) do
                if not missingOnly or item.state ~= STATE_EQUIPPED then
                    table.insert(rows, item)
                end
            end
            table.sort(rows, function(a, b)
                if a.state ~= b.state then return a.state < b.state end
                return a.slot < b.slot
            end)

            for _, item in ipairs(rows) do
                local name = GetItemInfo(item.id)
                if not name then
                    pending[item.id] = true
                    RequestItem(item.id)
                end
                table.insert(display, { item = item, bot = bot })
            end

            if #rows == 0 then
                table.insert(display, { note = true, bot = bot,
                                        text = missingOnly and "tout est equipe" or "aucune ligne" })
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
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

local function RowLeave() GameTooltip:Hide() end

local function RowClick(self)
    if self.botName then
        collapsed[self.botName] = not collapsed[self.botName]
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

local function BuildWindow()
    local f = CreateFrame("Frame", "PlayerbotsBisRosterFrame", UIParent)
    f:SetWidth(600)
    f:SetHeight(470)
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
    tinsert(UISpecialFrames, "PlayerbotsBisRosterFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Etat BiS des bots")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local head = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -46)
    head:SetJustifyH("LEFT")

    local filterBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    filterBtn:SetWidth(160)
    filterBtn:SetHeight(20)
    filterBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -66)
    filterBtn:SetScript("OnClick", function()
        missingOnly = not missingOnly
        f.Refresh(true)
    end)

    local expandBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    expandBtn:SetWidth(120)
    expandBtn:SetHeight(20)
    expandBtn:SetPoint("LEFT", filterBtn, "RIGHT", 8, 0)
    expandBtn:SetText("Tout deplier")
    expandBtn:SetScript("OnClick", function()
        local anyOpen = false
        for _, bot in ipairs(roster.bots) do
            if not collapsed[bot.name] then anyOpen = true break end
        end
        for _, bot in ipairs(roster.bots) do
            collapsed[bot.name] = anyOpen
        end
        expandBtn:SetText(anyOpen and "Tout deplier" or "Tout replier")
        f.Refresh(true)
    end)

    local scroll = CreateFrame("ScrollFrame", "PlayerbotsBisRosterScroll", f, "FauxScrollFrameTemplate")
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

        -- Coverage bar, drawn behind a bot's line.
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
        r.text:SetWidth(380)

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
    hint:SetText("Clic sur un bot : deplier  -  Maj+clic sur un objet : lien  -  "
                 .. "Actualiser avec .playerbotsbis report")

    function f.Refresh(rebuild)
        if rebuild then Rebuild() end

        filterBtn:SetText(missingOnly and "Manquants seulement" or "Toutes les pieces")

        local bots, eq, tot = 0, 0, 0
        for _, bot in ipairs(roster.bots) do
            bots = bots + 1
            eq = eq + bot.equipped
            tot = tot + bot.total
        end

        if bots == 0 then
            head:SetText("Aucune donnee. Tape |cffffd100.playerbotsbis report|r en jeu.")
        else
            head:SetText(string.format("%s  -  %d bots  -  %d/%d pieces equipees (%d%%)  -  releve de %s",
                roster.scope, bots, eq, tot,
                tot > 0 and math.floor(eq * 100 / tot) or 0, roster.when))
        end

        FauxScrollFrame_Update(scroll, #display, VISIBLE_ROWS, ROW_HEIGHT)
        local offset = FauxScrollFrame_GetOffset(scroll)

        for i = 1, VISIBLE_ROWS do
            local e = display[i + offset]
            local r = rows[i]
            r.botName, r.itemId = nil, nil

            if not e then
                r:Hide()
            else
                if e.header then
                    local bot = e.bot
                    local ratio = bot.total > 0 and (bot.equipped / bot.total) or 0
                    local c = CLASS_COLOR[bot.cls] or { 0.5, 0.5, 0.5 }
                    r.bar:SetWidth(math.max(1, 530 * ratio))
                    r.bar:SetVertexColor(c[1], c[2], c[3], 0.30)
                    r.bar:Show()

                    r.icon:SetTexture(nil)
                    r.text:SetText(string.format("|cff%02x%02x%02x%s%s|r  |cff999999%s %s niv %d|r",
                        c[1] * 255, c[2] * 255, c[3] * 255,
                        collapsed[bot.name] and "+ " or "- ", bot.name,
                        ClassName(bot.cls), SpecName(bot.cls, bot.spec), bot.level))

                    local colour = "|cff1eff00"
                    if ratio < 0.5 then colour = "|cffff2020"
                    elseif ratio < 0.85 then colour = "|cffffcc00" end
                    r.info:SetText(string.format("%s%d/%d|r", colour, bot.equipped, bot.total))
                    r.botName = bot.name
                elseif e.note then
                    r.bar:Hide()
                    r.icon:SetTexture(nil)
                    r.text:SetText("      |cff808080" .. e.text .. "|r")
                    r.info:SetText("")
                else
                    r.bar:Hide()
                    local item = e.item
                    local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(item.id)
                    r.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

                    if name then
                        local hex = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
                        hex = (hex and hex.hex) or "|cffffffff"
                        r.text:SetText("      " .. hex .. name .. "|r")
                    else
                        r.text:SetText("      |cff808080Chargement... (" .. item.id .. ")|r")
                    end

                    local tag
                    if item.state == STATE_EQUIPPED then
                        tag = "|cff1eff00equipe|r"
                    elseif item.state == STATE_CARRIED then
                        tag = "|cffffcc00dans ses sacs|r"
                    else
                        tag = "|cffff2020manquant|r"
                    end
                    r.info:SetText(tag .. " |cff808080" .. TierName(item.tier) .. "|r")
                    r.itemId = item.id
                end
                r:Show()
            end
        end
    end

    -- While item names are still missing from the client cache, recheck and redraw.
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

PlayerbotsBisRoster_Toggle = Toggle

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:SetScript("OnEvent", function(_, _, prefix, message)
    if prefix ~= PREFIX or not message then return end

    -- Fields are separated by ';'. Never '|': the client parses chat text for
    -- escape sequences before an addon sees it, and "B|Cruvmarl" looks like the
    -- start of a colour code, which kills the client with ERROR #134.
    local kind, rest = string.match(message, "^(%a);(.*)$")
    if not kind then return end

    if kind == "S" then
        local count, scope = string.match(rest, "^(%d+);(.*)$")
        ResetRoster(tonumber(count) or 0, scope)
    elseif kind == "B" then
        local name, cls, spec, level, eq, tot, car, mis =
            string.match(rest, "^(.-);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+)$")
        if name then
            AddBot(name, tonumber(cls), tonumber(spec), tonumber(level),
                   tonumber(eq), tonumber(tot), tonumber(car), tonumber(mis))
        end
    elseif kind == "I" then
        local name, packed = string.match(rest, "^(.-);(.*)$")
        if name then AddItems(name, packed) end
    elseif kind == "E" then
        if not win then win = BuildWindow() end
        win.Refresh(true)
        win:Show()
        Print(string.format("%d bots recus.", #roster.bots))
    end
end)
