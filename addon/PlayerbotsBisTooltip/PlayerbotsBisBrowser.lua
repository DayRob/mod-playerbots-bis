--[[
  Playerbots BiS Browser - released under GNU GPL v2, matching mod-playerbots-bis.

  Browses the BiS tables in game instead of on a website: pick a class, a spec
  and a phase, and read the list slot by slot, with real item tooltips.

  It reads the same BisData.lua the tooltip does, so there is still exactly one
  copy of the lists and a reexport moves both at once.

  Items the client has never seen are not in its cache, and GetItemInfo returns
  nil for them. On 3.3.5 there is no GET_ITEM_INFO_RECEIVED event to wait on, so
  the browser asks for each missing item by pointing a hidden tooltip at it -
  that makes the client query the server - and rechecks on a ticker until the
  names arrive.
]]

local ADDON = "PlayerbotsBisTooltip"

local ROW_HEIGHT   = 20
local VISIBLE_ROWS = 16
local RETRY_PERIOD = 0.4

-- Slot grouping. The labels come from the client's own global strings so the
-- window follows the game locale; the table below is only a fallback.
local SLOT_ORDER = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3,
    INVTYPE_CLOAK = 4, INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
    INVTYPE_BODY = 6, INVTYPE_TABARD = 7, INVTYPE_WRIST = 8,
    INVTYPE_HAND = 9, INVTYPE_WAIST = 10, INVTYPE_LEGS = 11,
    INVTYPE_FEET = 12, INVTYPE_FINGER = 13, INVTYPE_TRINKET = 14,
    INVTYPE_WEAPON = 15, INVTYPE_WEAPONMAINHAND = 15, INVTYPE_2HWEAPON = 15,
    INVTYPE_WEAPONOFFHAND = 16, INVTYPE_SHIELD = 16, INVTYPE_HOLDABLE = 16,
    INVTYPE_RANGED = 17, INVTYPE_RANGEDRIGHT = 17, INVTYPE_THROWN = 17,
    INVTYPE_RELIC = 17,
}

local SLOT_FALLBACK = {
    INVTYPE_HEAD = "Tete", INVTYPE_NECK = "Cou", INVTYPE_SHOULDER = "Epaules",
    INVTYPE_CLOAK = "Dos", INVTYPE_CHEST = "Torse", INVTYPE_ROBE = "Torse",
    INVTYPE_BODY = "Chemise", INVTYPE_TABARD = "Tabard", INVTYPE_WRIST = "Poignets",
    INVTYPE_HAND = "Mains", INVTYPE_WAIST = "Taille", INVTYPE_LEGS = "Jambes",
    INVTYPE_FEET = "Pieds", INVTYPE_FINGER = "Doigt", INVTYPE_TRINKET = "Bijou",
    INVTYPE_WEAPON = "Arme", INVTYPE_WEAPONMAINHAND = "Main droite",
    INVTYPE_2HWEAPON = "Arme a deux mains", INVTYPE_WEAPONOFFHAND = "Main gauche",
    INVTYPE_SHIELD = "Bouclier", INVTYPE_HOLDABLE = "Tenu en main gauche",
    INVTYPE_RANGED = "Distance", INVTYPE_RANGEDRIGHT = "Distance",
    INVTYPE_THROWN = "Jete", INVTYPE_RELIC = "Relique",
}

local RANK_COLOR = {
    [1] = "|cff1eff00", [2] = "|cffffe650", [3] = "|cff999999",
}

local CLASS_NAME = {
    [1] = "Guerrier", [2] = "Paladin", [3] = "Chasseur", [4] = "Voleur",
    [5] = "Pretre", [6] = "Chevalier de la mort", [7] = "Chaman",
    [8] = "Mage", [9] = "Demoniste", [11] = "Druide",
}

local SPEC_NAME = {
    [1] = { [0] = "Armes", [1] = "Fureur", [2] = "Protection" },
    [2] = { [0] = "Sacre", [1] = "Protection", [2] = "Vindicte" },
    [3] = { [0] = "Maitrise des betes", [1] = "Precision", [2] = "Survie" },
    [4] = { [0] = "Assassinat", [1] = "Combat", [2] = "Finesse" },
    [5] = { [0] = "Discipline", [1] = "Sacre", [2] = "Ombre" },
    [6] = { [0] = "Sang", [1] = "Givre", [2] = "Impie" },
    [7] = { [0] = "Elementaire", [1] = "Amelioration", [2] = "Restauration" },
    [8] = { [0] = "Arcanes", [1] = "Feu", [2] = "Givre" },
    [9] = { [0] = "Affliction", [1] = "Demonologie", [2] = "Destruction" },
    [11] = { [0] = "Equilibre", [1] = "Farouche", [2] = "Restauration", [10] = "Farouche (ours)" },
}

local CLASS_TOKEN_ID = {
    WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
    DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, DRUID = 11,
}

local index          -- class -> spec -> tier -> { {id, rank}, ... }, built lazily
local classes = {}   -- sorted class ids present in the data
local sel = { class = nil, spec = nil, tier = nil, allRanks = true }
local display = {}   -- flat list of headers and items, what the rows render
local pending = {}   -- itemId -> true, waiting on the client cache
local win

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BiS|r: " .. msg)
end

local function SlotLabel(loc)
    if not loc or loc == "" then return "Divers" end
    return _G[loc] or SLOT_FALLBACK[loc] or loc
end

local function TierName(tier)
    return (PlayerbotsBisTooltipTiers and PlayerbotsBisTooltipTiers[tier])
        or ("palier " .. tostring(tier))
end

local function ClassName(c) return CLASS_NAME[c] or ("classe " .. tostring(c)) end

local function SpecName(c, s)
    local t = SPEC_NAME[c]
    return (t and t[s]) or ("spe " .. tostring(s))
end

--------------------------------------------------------------------------------
-- Index
--------------------------------------------------------------------------------

local function BuildIndex()
    if index then return end
    index = {}
    if not PlayerbotsBisTooltipItems then return end

    for itemId, rows in pairs(PlayerbotsBisTooltipItems) do
        for i = 1, #rows, 4 do
            local c, s, t, r = rows[i], rows[i + 1], rows[i + 2], rows[i + 3]
            index[c] = index[c] or {}
            index[c][s] = index[c][s] or {}
            index[c][s][t] = index[c][s][t] or {}
            table.insert(index[c][s][t], { id = itemId, rank = r })
        end
    end

    for c in pairs(index) do table.insert(classes, c) end
    table.sort(classes)
end

local function SpecsOf(class)
    local out = {}
    if index and index[class] then
        for s in pairs(index[class]) do table.insert(out, s) end
    end
    table.sort(out)
    return out
end

local function TiersOf(class, spec)
    local out = {}
    if index and index[class] and index[class][spec] then
        for t in pairs(index[class][spec]) do table.insert(out, t) end
    end
    table.sort(out)
    return out
end

-- Pick the first selection that actually has rows, so the window never opens empty.
local function EnsureSelection()
    BuildIndex()
    if #classes == 0 then return false end

    if not sel.class or not index[sel.class] then
        local _, token = UnitClass("player")
        local mine = CLASS_TOKEN_ID[token or ""]
        sel.class = (mine and index[mine]) and mine or classes[1]
        sel.spec, sel.tier = nil, nil
    end

    local specs = SpecsOf(sel.class)
    if #specs == 0 then return false end
    if not sel.spec or not index[sel.class][sel.spec] then
        sel.spec = specs[1]
        sel.tier = nil
    end

    local tiers = TiersOf(sel.class, sel.spec)
    if #tiers == 0 then return false end
    if not sel.tier or not index[sel.class][sel.spec][sel.tier] then
        sel.tier = tiers[#tiers]   -- newest phase by default
    end
    return true
end

--------------------------------------------------------------------------------
-- Item cache
--------------------------------------------------------------------------------

-- nil = not tried yet, false = this client cannot give us one.
local scanner

-- Built on first use, never at load. A client missing GameTooltipTemplate would
-- otherwise throw here and take the whole file down with it, leaving the addon
-- with no browser and no error to show for it.
local function EnsureScanner()
    if scanner ~= nil then return scanner end
    local ok, frame = pcall(CreateFrame, "GameTooltip", "PlayerbotsBisScanTooltip",
                            UIParent, "GameTooltipTemplate")
    scanner = (ok and frame) or false
    return scanner
end

-- Touching an uncached item with a tooltip makes the client ask the server for
-- it. Nothing is read from the tooltip; the point is the query it triggers.
-- Without one we lose nothing that matters: GetItemInfo on an uncached item
-- asks the server too, it just answers on a later call, and the ticker is
-- already waiting for exactly that.
local function RequestItem(itemId)
    local tip = EnsureScanner()
    if not tip then return end
    pcall(function()
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
        tip:Hide()
    end)
end

--------------------------------------------------------------------------------
-- Display list
--------------------------------------------------------------------------------

local function Rebuild()
    display = {}
    pending = {}
    if not EnsureSelection() then return end

    local entries = index[sel.class][sel.spec][sel.tier] or {}
    local groups, unknown = {}, {}

    for _, e in ipairs(entries) do
        if sel.allRanks or e.rank == 1 then
            local name, link, quality, _, _, _, _, _, loc, texture = GetItemInfo(e.id)
            if name then
                local key = SLOT_ORDER[loc or ""] or 99
                groups[key] = groups[key] or { label = SlotLabel(loc), rows = {} }
                table.insert(groups[key].rows, {
                    id = e.id, rank = e.rank, name = name, link = link,
                    quality = quality or 1, texture = texture,
                })
            else
                pending[e.id] = true
                RequestItem(e.id)
                table.insert(unknown, { id = e.id, rank = e.rank })
            end
        end
    end

    local keys = {}
    for k in pairs(groups) do table.insert(keys, k) end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local g = groups[k]
        table.sort(g.rows, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return a.name < b.name
        end)
        table.insert(display, { header = true, label = g.label, count = #g.rows })
        for _, row in ipairs(g.rows) do table.insert(display, row) end
    end

    if #unknown > 0 then
        table.insert(display, { header = true, label = "En attente du serveur", count = #unknown })
        for _, e in ipairs(unknown) do
            table.insert(display, { id = e.id, rank = e.rank, loading = true })
        end
    end
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local function RowEnter(self)
    if not self.itemId then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if pcall(GameTooltip.SetHyperlink, GameTooltip,
             "item:" .. self.itemId .. ":0:0:0:0:0:0:0") then
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

local function RowLeave() GameTooltip:Hide() end

local function RowClick(self)
    if not self.itemId then return end
    local _, link = GetItemInfo(self.itemId)
    if IsShiftKeyDown() and link then
        if ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif IsControlKeyDown() and link then
        if DressUpItemLink then DressUpItemLink(link) end
    end
end

local function BuildWindow()
    local f = CreateFrame("Frame", "PlayerbotsBisBrowserFrame", UIParent)
    f:SetWidth(520)
    f:SetHeight(460)
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
    tinsert(UISpecialFrames, "PlayerbotsBisBrowserFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Listes BiS")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    -- Selectors. Clicking cycles to the next value: three dropdowns would need
    -- three menu frames for a list that never exceeds a handful of entries.
    local function MakeSelector(label, x, width)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetWidth(width)
        b:SetHeight(22)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -46)
        local cap = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cap:SetPoint("BOTTOMLEFT", b, "TOPLEFT", 3, 1)
        cap:SetText(label)
        return b
    end

    local classBtn = MakeSelector("Classe", 20, 150)
    local specBtn  = MakeSelector("Spe", 176, 150)
    local tierBtn  = MakeSelector("Phase", 332, 166)

    local function Cycle(list, cur, step)
        if #list == 0 then return cur end
        local at = 1
        for i, v in ipairs(list) do
            if v == cur then at = i break end
        end
        at = at + step
        if at > #list then at = 1 elseif at < 1 then at = #list end
        return list[at]
    end

    classBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    classBtn:SetScript("OnClick", function(_, button)
        sel.class = Cycle(classes, sel.class, button == "RightButton" and -1 or 1)
        sel.spec, sel.tier = nil, nil
        f.Refresh(true)
    end)

    specBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    specBtn:SetScript("OnClick", function(_, button)
        sel.spec = Cycle(SpecsOf(sel.class), sel.spec, button == "RightButton" and -1 or 1)
        sel.tier = nil
        f.Refresh(true)
    end)

    tierBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tierBtn:SetScript("OnClick", function(_, button)
        sel.tier = Cycle(TiersOf(sel.class, sel.spec), sel.tier, button == "RightButton" and -1 or 1)
        f.Refresh(true)
    end)

    local rankBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rankBtn:SetWidth(120)
    rankBtn:SetHeight(20)
    rankBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -76)
    rankBtn:SetScript("OnClick", function()
        sel.allRanks = not sel.allRanks
        f.Refresh(true)
    end)

    local summary = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("LEFT", rankBtn, "RIGHT", 10, 0)
    summary:SetJustifyH("LEFT")

    local scroll = CreateFrame("ScrollFrame", "PlayerbotsBisBrowserScroll", f, "FauxScrollFrameTemplate")
    scroll:SetWidth(452)
    scroll:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -104)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() f.Refresh() end)
    end)

    local rows = {}
    for i = 1, VISIBLE_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(452)
        r:SetHeight(ROW_HEIGHT)
        r:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(16)
        r.icon:SetHeight(16)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)

        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetJustifyH("LEFT")
        r.text:SetWidth(330)

        r.info = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        r.info:SetPoint("RIGHT", r, "RIGHT", -6, 0)
        r.info:SetJustifyH("RIGHT")

        r:SetScript("OnEnter", RowEnter)
        r:SetScript("OnLeave", RowLeave)
        r:SetScript("OnClick", RowClick)
        r:RegisterForClicks("LeftButtonUp")
        rows[i] = r
    end

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 20)
    hint:SetJustifyH("LEFT")
    hint:SetText("Clic gauche/droit sur un selecteur pour changer  -  Maj+clic : lien dans le chat  -  Ctrl+clic : essayage")

    function f.Refresh(rebuild)
        if rebuild then Rebuild() end

        classBtn:SetText(ClassName(sel.class or 0))
        specBtn:SetText(SpecName(sel.class or 0, sel.spec or 0))
        tierBtn:SetText(TierName(sel.tier or 0))
        rankBtn:SetText(sel.allRanks and "Tous les rangs" or "Rang 1 seul")

        local items = 0
        for _, e in ipairs(display) do
            if not e.header then items = items + 1 end
        end
        summary:SetText(items .. " objets")

        FauxScrollFrame_Update(scroll, #display, VISIBLE_ROWS, ROW_HEIGHT)
        local offset = FauxScrollFrame_GetOffset(scroll)

        for i = 1, VISIBLE_ROWS do
            local e = display[i + offset]
            local r = rows[i]
            if not e then
                r:Hide()
            else
                if e.header then
                    r.icon:SetTexture(nil)
                    r.text:SetText("|cffffd100" .. e.label .. "|r")
                    r.info:SetText("|cff808080" .. e.count .. "|r")
                    r.itemId = nil
                elseif e.loading then
                    r.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    r.text:SetText("|cff808080Chargement... (" .. e.id .. ")|r")
                    r.info:SetText((RANK_COLOR[e.rank] or RANK_COLOR[3]) .. "rang " .. e.rank .. "|r")
                    r.itemId = e.id
                else
                    r.icon:SetTexture(e.texture)
                    local hex = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality]
                    hex = (hex and hex.hex) or "|cffffffff"
                    r.text:SetText(hex .. e.name .. "|r")
                    r.info:SetText((RANK_COLOR[e.rank] or RANK_COLOR[3]) .. "rang " .. e.rank .. "|r")
                    r.itemId = e.id
                end
                r:Show()
            end
        end
    end

    -- While items are still missing from the client cache, recheck and redraw.
    local since = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        if not next(pending) then return end
        since = since + (elapsed or 0)
        if since < RETRY_PERIOD then return end
        since = 0

        local resolved = false
        for id in pairs(pending) do
            if GetItemInfo(id) then resolved = true break end
        end
        if resolved then self.Refresh(true) end
    end)

    return f
end

local function Toggle()
    if not PlayerbotsBisTooltipItems then
        Print("BisData.lua est absent ou vide - relance tools/export_bis_tooltip.ps1.")
        return
    end
    BuildIndex()
    if #classes == 0 then
        Print("aucune liste chargee.")
        return
    end
    if not win then win = BuildWindow() end
    if win:IsShown() then
        win:Hide()
    else
        win.Refresh(true)
        win:Show()
    end
end

PlayerbotsBisBrowser_Toggle = Toggle

SLASH_PLAYERBOTSBISBROWSER1 = "/pbbislist"
SlashCmdList["PLAYERBOTSBISBROWSER"] = Toggle
