--[[
    Playerbots BiS - la vue par raid.

    Le releve des bots repond a "ce bot, que lui manque-t-il". Choisir le raid
    de la soiree demande l'inverse : "ce raid, a qui sert-il, et pour quoi".

    Rien de nouveau n'est demande au serveur. Le flux de ".playerbotsbis report"
    porte deja le palier de chaque ligne ; cette fenetre relit ce meme releve et
    le regroupe autrement.

    Ne comptent que les pieces MANQUANTES qui sont la CIBLE de leur creneau.
      - une piece deja portee ne justifie pas un raid ;
      - une piece dans les sacs non plus : elle demande ".playerbotsbis equipe",
        pas une soiree de raid ;
      - un repli n'en justifie pas un : si la cible d'un creneau est a Blackwing
        Lair, la piece de Molten Core pour ce meme creneau n'est plus l'objectif.

    Cette derniere regle est ce qui rend le classement utile. Chaque creneau de
    chaque bot compte pour UN raid et un seul, celui qui porte sa meilleure
    piece atteignable - donc le nombre affiche en face d'un raid est bien le
    nombre de pieces que cette soiree-la ferait gagner.
]]

local ROW_HEIGHT   = 20
local VISIBLE_ROWS = 16
local ROW_WIDTH    = 530
local RETRY_PERIOD = 0.4

local STATE_MISSING = 0

local CLASS_COLOR = {
    [1] = { 0.78, 0.61, 0.43 }, [2] = { 0.96, 0.55, 0.73 }, [3] = { 0.67, 0.83, 0.45 },
    [4] = { 1.00, 0.96, 0.41 }, [5] = { 1.00, 1.00, 1.00 }, [6] = { 0.77, 0.12, 0.23 },
    [7] = { 0.00, 0.44, 0.87 }, [8] = { 0.41, 0.80, 0.94 }, [9] = { 0.58, 0.51, 0.79 },
    [11] = { 1.00, 0.49, 0.04 },
}

local open = {}      -- palier -> true quand ses pieces sont depliees
local display = {}
local pending = {}
local win

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PlayerbotsBis|r: " .. msg)
end

local function TierName(tier)
    return (PlayerbotsBis_TierName and PlayerbotsBis_TierName(tier)) or ("palier " .. tostring(tier))
end

local function RequestItem(id)
    if PlayerbotsBis_RequestItem then PlayerbotsBis_RequestItem(id) end
end

--------------------------------------------------------------------------------
-- Regroupement
--------------------------------------------------------------------------------

-- Renvoie une liste de paliers, du plus recent au plus ancien, chacun portant
-- ses pieces et, pour chaque piece, les bots qui l'attendent.
local function Group()
    local roster = PlayerbotsBisRoster_Data and PlayerbotsBisRoster_Data()
    if not roster or not roster.bots then return {}, 0 end

    local parTier = {}

    for _, bot in ipairs(roster.bots) do
        for _, item in ipairs(bot.items or {}) do
            if item.target and item.state == STATE_MISSING then
                local tier = parTier[item.tier]
                if not tier then
                    tier = { tier = item.tier, items = {}, byId = {}, bots = {}, botCount = 0 }
                    parTier[item.tier] = tier
                end

                local entry = tier.byId[item.id]
                if not entry then
                    entry = { id = item.id, slot = item.slot, bots = {} }
                    tier.byId[item.id] = entry
                    table.insert(tier.items, entry)
                end

                table.insert(entry.bots, { name = bot.name, cls = bot.cls })

                -- Compte de bots DISTINCTS : un bot qui attend six pieces du
                -- meme raid ne vaut pas six bots.
                if not tier.bots[bot.name] then
                    tier.bots[bot.name] = true
                    tier.botCount = tier.botCount + 1
                end
            end
        end
    end

    local liste = {}
    for _, tier in pairs(parTier) do
        -- La piece que le plus de bots attendent en premier : c'est elle qui
        -- decide si la soiree vaut le deplacement.
        table.sort(tier.items, function(a, b)
            if #a.bots ~= #b.bots then return #a.bots > #b.bots end
            return a.id < b.id
        end)
        table.insert(liste, tier)
    end

    -- Le palier le plus haut d'abord : c'est le contenu courant, et celui dont
    -- les pieces ne seront pas remplacees la semaine prochaine.
    table.sort(liste, function(a, b) return a.tier > b.tier end)

    local total = 0
    for _, tier in ipairs(liste) do total = total + #tier.items end

    return liste, total
end

local function Rebuild()
    display = {}
    pending = {}

    local liste, total = Group()

    if total == 0 then
        table.insert(display, { note = true, text =
            "Aucune piece manquante. Lance |cffffd100.playerbotsbis report|r en jeu "
            .. "pour remplir le releve." })
        return
    end

    for _, tier in ipairs(liste) do
        table.insert(display, { groupe = tier })

        if open[tier.tier] then
            for _, entry in ipairs(tier.items) do
                table.insert(display, { entry = entry })
                if not GetItemInfo(entry.id) then
                    pending[entry.id] = true
                    RequestItem(entry.id)
                end
            end
        end
    end
end

-- Les noms de bots, colores par classe, coupes au-dela de ce qui tient sur une
-- ligne : une piece attendue par vingt bots donnerait sinon une ligne illisible.
local function BotList(bots, maxNames)
    local out = {}
    for i, b in ipairs(bots) do
        if i > maxNames then
            table.insert(out, string.format("|cff808080+%d|r", #bots - maxNames))
            break
        end
        local c = CLASS_COLOR[b.cls] or { 0.6, 0.6, 0.6 }
        table.insert(out, string.format("|cff%02x%02x%02x%s|r",
            c[1] * 255, c[2] * 255, c[3] * 255, b.name))
    end
    return table.concat(out, ", ")
end

--------------------------------------------------------------------------------
-- Fenetre
--------------------------------------------------------------------------------

local function BuildWindow()
    local f = CreateFrame("Frame", "PlayerbotsBisRaidsFrame", UIParent)
    f:SetWidth(600)
    f:SetHeight(440)
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
    tinsert(UISpecialFrames, "PlayerbotsBisRaidsFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Quel raid faire")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local head = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -46)
    head:SetJustifyH("LEFT")

    local expandBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    expandBtn:SetWidth(120)
    expandBtn:SetHeight(20)
    expandBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -64)
    expandBtn:SetText("Tout deplier")
    expandBtn:SetScript("OnClick", function()
        local liste = Group()
        local anyOpen = false
        for _, tier in ipairs(liste) do
            if open[tier.tier] then anyOpen = true break end
        end
        for _, tier in ipairs(liste) do
            open[tier.tier] = not anyOpen
        end
        expandBtn:SetText(anyOpen and "Tout deplier" or "Tout replier")
        f.Refresh(true)
    end)

    local scroll = CreateFrame("ScrollFrame", "PlayerbotsBisRaidsScroll", f, "FauxScrollFrameTemplate")
    scroll:SetWidth(ROW_WIDTH)
    scroll:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -92)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() f.Refresh() end)
    end)

    local rows = {}
    for i = 1, VISIBLE_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(ROW_WIDTH)
        r:SetHeight(ROW_HEIGHT)
        r:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(16)
        r.icon:SetHeight(16)
        r.icon:SetPoint("LEFT", r, "LEFT", 6, 0)

        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetJustifyH("LEFT")
        r.text:SetWidth(300)

        r.info = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.info:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r.info:SetJustifyH("RIGHT")
        r.info:SetWidth(190)

        r:SetScript("OnClick", function(self)
            if self.tierKey then
                open[self.tierKey] = not open[self.tierKey]
                f.Refresh(true)
            elseif self.itemId and IsShiftKeyDown() and ChatEdit_InsertLink then
                local link = select(2, GetItemInfo(self.itemId))
                if link then ChatEdit_InsertLink(link) end
            end
        end)

        r:SetScript("OnEnter", function(self)
            if self.itemId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. self.itemId)
                GameTooltip:Show()
            elseif self.botsFull then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.botsFull, nil, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)

        r:Hide()
        rows[i] = r
    end

    f.Refresh = function(rebuild)
        if rebuild then Rebuild() end

        local roster = PlayerbotsBisRoster_Data and PlayerbotsBisRoster_Data()
        head:SetText(string.format("|cffffd100%s|r  releve de %s",
            (roster and roster.scope ~= "" and roster.scope) or "aucun releve",
            (roster and roster.when) or "-"))

        FauxScrollFrame_Update(scroll, #display, VISIBLE_ROWS, ROW_HEIGHT)
        local offset = FauxScrollFrame_GetOffset(scroll)

        for i = 1, VISIBLE_ROWS do
            local r = rows[i]
            local e = display[i + offset]
            r.tierKey, r.itemId, r.botsFull = nil, nil, nil

            if not e then
                r:Hide()
            else
                if e.note then
                    r.icon:SetTexture(nil)
                    r.text:SetWidth(490)
                    r.text:SetText("|cff808080" .. e.text .. "|r")
                    r.info:SetText("")
                elseif e.groupe then
                    local g = e.groupe
                    r.icon:SetTexture(nil)
                    r.text:SetWidth(300)
                    r.text:SetText(string.format("%s|cffffd100%s|r",
                        open[g.tier] and "- " or "+ ", TierName(g.tier)))
                    r.info:SetText(string.format("|cffff2020%d piece(s)|r |cff999999pour %d bot(s)|r",
                        #g.items, g.botCount))
                    r.tierKey = g.tier
                else
                    local entry = e.entry
                    local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(entry.id)
                    r.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                    r.text:SetWidth(300)

                    if name then
                        local hex = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
                        hex = (hex and hex.hex) or "|cffffffff"
                        r.text:SetText("   " .. hex .. name .. "|r")
                    else
                        r.text:SetText("   |cff808080Chargement... (" .. entry.id .. ")|r")
                    end

                    r.info:SetText(BotList(entry.bots, 3))
                    r.itemId = entry.id

                    -- La ligne est tronquee a trois noms ; l'infobulle donne la
                    -- liste entiere, un nom par ligne.
                    local noms = {}
                    for _, b in ipairs(entry.bots) do table.insert(noms, b.name) end
                    r.botsFull = table.concat(noms, "\n")
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

PlayerbotsBisRaids_Toggle = Toggle

SLASH_PLAYERBOTSBISRAIDS1 = "/pbbisraids"
SlashCmdList["PLAYERBOTSBISRAIDS"] = Toggle
