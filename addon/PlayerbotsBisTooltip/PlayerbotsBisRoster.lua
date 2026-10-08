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

-- Equipment slot indices as the server sends them. The labels come from the
-- client's own global strings so the window follows the game locale; the table
-- below is only a fallback.
local SLOT_GLOBAL = {
    [0] = "HEADSLOT", [1] = "NECKSLOT", [2] = "SHOULDERSLOT", [3] = "SHIRTSLOT",
    [4] = "CHESTSLOT", [5] = "WAISTSLOT", [6] = "LEGSSLOT", [7] = "FEETSLOT",
    [8] = "WRISTSLOT", [9] = "HANDSSLOT", [10] = "FINGER0SLOT", [11] = "FINGER1SLOT",
    [12] = "TRINKET0SLOT", [13] = "TRINKET1SLOT", [14] = "BACKSLOT",
    [15] = "MAINHANDSLOT", [16] = "SECONDARYHANDSLOT", [17] = "RANGEDSLOT",
    [18] = "TABARDSLOT",
}

local SLOT_FR = {
    [0] = "Tete", [1] = "Cou", [2] = "Epaules", [3] = "Chemise", [4] = "Torse",
    [5] = "Taille", [6] = "Jambes", [7] = "Pieds", [8] = "Poignets", [9] = "Mains",
    [10] = "Doigt 1", [11] = "Doigt 2", [12] = "Bijou 1", [13] = "Bijou 2",
    [14] = "Dos", [15] = "Main droite", [16] = "Main gauche", [17] = "Distance",
    [18] = "Tabard",
}

local function SlotName(index)
    local key = SLOT_GLOBAL[index]
    return (key and _G[key]) or SLOT_FR[index] or ("creneau " .. tostring(index))
end

-- Three views, cycled by the button, which always reads the view it is in.
-- "Equipes seulement" answers the question the other two cannot: what has this
-- bot actually secured so far.
-- Nombre de pieces montrees quand un creneau est deplie. La cible et la piece
-- portee s'ajoutent par-dessus si elles tombent au-dela.
local OPEN_MAX = 4

local VIEW_MISSING, VIEW_DONE, VIEW_ALL = 1, 2, 3
local VIEW_LABEL = { "Manquants seulement", "Equipes seulement", "Tout afficher" }
local VIEW_SHORT = { "Manquants", "Equipes", "Tout" }
local VIEW_WIDTH = { 92, 82, 58 }
local view = VIEW_MISSING

-- Per slot, per bot: a slot shows only its target until you open it. Keyed by
-- "bot:slot" so two bots can have different slots open at once.
local slotOpen = {}

local roster = { scope = "", when = "", bots = {}, byName = {} }

-- itemId -> { {name=, cls=}, ... } : qui porte quoi, listes ou non. Rempli par
-- les lignes "G" du releve, et lu par l'infobulle.
-- Ne couvre que les pieces des listes : ce sont les seules que le releve
-- transporte. Une piece hors liste ne peut donc pas etre tracee, et c'est
-- assumee - c'est aussi la seule que personne ne convoite.
-- Declarees ici, remplies plus bas : Dispatch tient les promesses a la fin du
-- releve, et il est ecrit AVANT le code qui les pose. Un "local function" plus
-- loin ne serait pas visible depuis Dispatch - l'appel y deviendrait une
-- globale nil, et chaque releve se terminerait par une erreur.
local promesses = {}
local chrono
local TenirPromesses
local OuvrirMenuBilan   -- le menu, utilisable depuis la fenetre comme depuis la minicarte

local wearers = {}
local collapsed = {}       -- bot name -> true when its items are hidden
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
-- Bilan : ce que les bots ont gagne entre deux releves
--------------------------------------------------------------------------------
--
-- POURQUOI DEUX INSTANTANES ET PAS UN JOURNAL. Une piece peut etre equipee par
-- trois chemins : la passe de ce module, l'action d'equipement de playerbots
-- apres un jet gagne, et la refonte d'equipement d'un bot qui monte de niveau.
-- Un journal ne verrait que le premier. Comparer deux etats les voit tous, quel
-- que soit le chemin, parce qu'il ne regarde que le resultat.
--
-- UN REPERE, PAS "LES DEUX DERNIERS". La premiere version comparait le dernier
-- releve a l'avant-dernier, et un ".playerbotsbis report" lance au milieu du
-- raid - pour voir ou on en est, ce qui est l'usage normal de cette commande -
-- ramenait la fenetre a ce qui suivait ce releve-la. Le bilan compare donc a un
-- REPERE que tu poses, et que rien d'autre ne deplace. Entre les deux, relance
-- le releve autant de fois que tu veux : seul le cote "maintenant" bouge.

local function Snapshot()
    local etat = { quand = date("%d/%m %H:%M"), bots = {} }

    for _, bot in ipairs(roster.bots) do
        local porte = {}
        for _, item in ipairs(bot.items) do
            if item.state == STATE_EQUIPPED then
                -- La valeur porte la cible : une piece de repli qui devient la
                -- cible du creneau est un progres, meme sans changement d'objet.
                porte[item.id] = item.target and 2 or 1
            end
        end
        etat.bots[bot.name] = { cls = bot.cls, porte = porte }
    end

    return etat
end

-- Appelee a la fin de chaque releve. Silencieuse : le bilan se lit sur demande,
-- sinon chaque releve en recracherait un.
local function StoreSnapshot()
    local db = PlayerbotsBisTooltipDB
    if not db then return end

    db.bilan = db.bilan or {}
    db.bilan.courant = Snapshot()

    -- Reprise des sauvegardes de la version precedente, qui ne connaissait que
    -- "precedent" / "courant" : son avant-dernier releve devient le repere.
    db.bilan.depart = db.bilan.depart or db.bilan.precedent
    db.bilan.precedent = nil

    -- Tout premier releve : le repere se pose tout seul, sinon le premier bilan
    -- n'aurait rien a quoi se comparer.
    if not db.bilan.depart then
        db.bilan.depart = db.bilan.courant
    end
end

local function ItemText(id)
    local name, link, quality = GetItemInfo(id)
    if link then return link end
    RequestItem(id)
    return "objet " .. tostring(id)
end

function PlayerbotsBisRoster_Bilan(arg)
    local db = PlayerbotsBisTooltipDB
    local bilan = db and db.bilan

    if arg == "raz" then
        if db then db.bilan = nil end
        Print("bilan remis a zero : le prochain releve repart d'une page blanche.")
        return
    end

    if not bilan or not bilan.courant then
        Print("aucun releve en memoire. Lance |cffffd100.playerbotsbis report|r"
              .. " une premiere fois.")
        return
    end

    if arg == "depart" or arg == "debut" then
        bilan.depart = bilan.courant
        Print("repere pose sur le releve du " .. bilan.courant.quand
              .. ". Relance |cffffd100.playerbotsbis report|r apres le raid, puis"
              .. " |cffffd100/pbbis bilan|r.")
        return
    end

    if bilan.depart == bilan.courant then
        Print("le repere est sur le dernier releve (" .. bilan.courant.quand
              .. ") : il n'y a rien a comparer. Relance"
              .. " |cffffd100.playerbotsbis report|r apres le raid.")
        return
    end

    Print("nouveautes entre le " .. bilan.depart.quand .. " et le "
          .. bilan.courant.quand .. " :")

    local lignes, nouveauxBots = 0, 0

    -- Ordre stable : les bots par nom, pour que deux appels se ressemblent.
    local noms = {}
    for nom in pairs(bilan.courant.bots) do table.insert(noms, nom) end
    table.sort(noms)

    for _, nom in ipairs(noms) do
        local apres = bilan.courant.bots[nom]
        local avant = bilan.depart.bots[nom]

        if not avant then
            -- Un bot absent du releve-repere n'a rien "gagne" : il etait
            -- deconnecte, et tout son equipement passerait pour du neuf.
            nouveauxBots = nouveauxBots + 1
        else
            local gains = {}
            for id, cible in pairs(apres.porte) do
                if not avant.porte[id] then
                    table.insert(gains, { id = id, cible = cible == 2 })
                end
            end

            if #gains > 0 then
                table.sort(gains, function(a, b)
                    if a.cible ~= b.cible then return a.cible end
                    return a.id < b.id
                end)

                local c = CLASS_COLOR[apres.cls] or { 0.8, 0.8, 0.8 }
                local entete = string.format("|cff%02x%02x%02x%s|r",
                    c[1] * 255, c[2] * 255, c[3] * 255, nom)

                for _, g in ipairs(gains) do
                    Print("  " .. entete .. " : " .. ItemText(g.id)
                          .. (g.cible and " |cff1eff00(rang 1)|r" or " |cff808080(repli)|r"))
                    lignes = lignes + 1
                end
            end
        end
    end

    if lignes == 0 then
        Print("  rien de neuf.")
    end

    if nouveauxBots > 0 then
        Print(string.format("  (%d bot(s) absent(s) du releve-repere, ignore(s) :"
                            .. " tout leur equipement aurait compte pour du neuf.)",
                            nouveauxBots))
    end
end

--------------------------------------------------------------------------------
-- Stream
--------------------------------------------------------------------------------

local function ResetRoster(count, scope)
    roster = { scope = scope or "", when = date("%H:%M:%S"), bots = {}, byName = {}, expected = count }
    pending = {}

    -- Vide aussi : sans ca un bot qui a change de piece resterait indique comme
    -- porteur de l'ancienne, pour toujours.
    wearers = {}
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

-- Lue par l'infobulle. Renvoie la liste des porteurs et l'heure du releve, pour
-- que l'appelant puisse dire de quand date l'information.
function PlayerbotsBisRoster_Wearers(itemId)
    return wearers[itemId], roster.when
end

local function AddItems(name, packed)
    local bot = roster.byName[name]
    if not bot then return end

    for id, state, tier, slot, rank, target in
            string.gmatch(packed, "(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)") do
        id, state = tonumber(id), tonumber(state)

        table.insert(bot.items, {
            id = id, state = state, tier = tonumber(tier),
            slot = tonumber(slot), rank = tonumber(rank), target = target == "1",
        })

        -- La meme piece peut figurer sur plusieurs paliers de la liste d'un bot,
        -- donc une garde sur le nom, sinon il apparait deux fois.
        if state == STATE_EQUIPPED then
            local list = wearers[id]
            if not list then
                list = {}
                wearers[id] = list
            end

            local already = false
            for _, w in ipairs(list) do
                if w.name == name then already = true break end
            end

            if not already then
                table.insert(list, { name = name, cls = bot.cls })
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Display list
--------------------------------------------------------------------------------

local function Rebuild()
    display = {}
    pending = {}

    -- Best equipped first, counted in PIECES and not as a ratio.
    --
    -- The ratio is the fairer measure - lists run from 14 to 17 slots, so 5/14
    -- really is better coverage than 6/17 - but it reads as a broken sort, and
    -- a window nobody trusts is worse than one that ranks approximately. The
    -- count is what the eye checks, so the count is what decides.
    table.sort(roster.bots, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped > b.equipped end

        -- A egalite de pieces, le ratio departage : 6/14 est une meilleure
        -- couverture que 6/15, et c'est la seule chose qui distingue encore
        -- deux bots dont les listes n'ont pas la meme taille.
        local ra = a.total > 0 and (a.equipped / a.total) or 0
        local rb = b.total > 0 and (b.equipped / b.total) or 0
        if ra ~= rb then return ra > rb end

        return a.name < b.name
    end)

    for _, bot in ipairs(roster.bots) do
        table.insert(display, { header = true, bot = bot })

        if not collapsed[bot.name] then
            -- Grouped by slot, because a slot is the unit that matters: its
            -- target, then the fallbacks that explain what the bot wears instead.
            local bySlot, order = {}, {}
            for _, item in ipairs(bot.items) do
                if not bySlot[item.slot] then
                    bySlot[item.slot] = {}
                    table.insert(order, item.slot)
                end
                table.insert(bySlot[item.slot], item)
            end
            table.sort(order)

            local shown = 0
            for _, slot in ipairs(order) do
                local entries = bySlot[slot]

                -- Ordre de l'ECHELLE, pas du rang brut. Le module calcule
                -- priorite = palier * 1000 + (255 - rang), donc le palier
                -- l'emporte toujours : un rang 2 de Molten Core passe devant un
                -- rang 1 pre-raid, et c'est ce que le bot fait vraiment.
                -- Trier par rang d'abord, comme avant, montrait l'inverse.
                table.sort(entries, function(a, b)
                    if a.tier ~= b.tier then return a.tier > b.tier end
                    if a.rank ~= b.rank then return a.rank < b.rank end
                    return a.id < b.id
                end)

                -- Un rang unique par CRENEAU, renumerote apres ce tri. Les rangs
                -- bruts viennent chacun de leur palier, donc un creneau couvert
                -- par deux paliers affichait deux "rang 1" - et celui du palier
                -- inferieur n'est plus un premier choix depuis que l'autre est
                -- atteignable, c'est un repli.
                for i, item in ipairs(entries) do
                    item.pos = i
                end

                -- A slot counts as settled when the piece the list picks for
                -- it is the one worn. A rank 2 on the back is not "equipe" for
                -- this purpose: the slot still has something to gain.
                --
                -- La cible reste celle que le SERVEUR a marquee : le tri
                -- ci-dessus la ramene en tete, mais s'y fier serait rederiver
                -- une decision qu'on recoit deja.
                local target
                for _, item in ipairs(entries) do
                    if item.target then target = item break end
                end
                target = target or entries[1]

                local done = target and target.state == STATE_EQUIPPED
                if view == VIEW_MISSING and done then
                    entries = nil   -- slot settled, nothing to say about it
                elseif view == VIEW_DONE and not done then
                    entries = nil   -- slot still open, not what this view shows
                end

                if entries then
                    local key = bot.name .. ":" .. slot
                    local open = slotOpen[key]

                    -- A fallback the bot wears explains why the slot is not
                    -- empty, so the closed header says so without unfolding.
                    local wornRank
                    for _, item in ipairs(entries) do
                        if not item.target and item.state == STATE_EQUIPPED then
                            wornRank = item.pos
                            break
                        end
                    end

                    table.insert(display, {
                        slot = true, bot = bot, label = SlotName(slot),
                        key = key, open = open, count = #entries, wornRank = wornRank,
                    })

                    -- Replie : la piece que la liste retient. Deplie : les
                    -- premieres, pas les dix.
                    --
                    -- Un creneau de guerrier en compte dix, dont huit replis
                    -- pre-raid de rang 2 - des pieces qu'il ne prendra jamais
                    -- maintenant que la phase 1 est ouverte. Les faire defiler
                    -- pousse hors de l'ecran les creneaux qui, eux, ont quelque
                    -- chose a dire.
                    --
                    -- Deux lignes passent OUTRE le plafond, parce que ce sont
                    -- celles qui repondent a la question posee : la cible, et ce
                    -- que le bot porte en ce moment.
                    --
                    -- Le reste disparait sans un mot. Le compte total figure
                    -- deja sur l'en-tete du creneau quand il est replie, et une
                    -- ligne pour dire qu'on a cache des replis coute exactement
                    -- ce que le plafond fait economiser.
                    if open then
                        local shown = 0
                        for _, item in ipairs(entries) do
                            local keep = item == target or item.state == STATE_EQUIPPED
                            if shown < OPEN_MAX or keep then
                                if not GetItemInfo(item.id) then
                                    pending[item.id] = true
                                    RequestItem(item.id)
                                end
                                table.insert(display, { item = item, bot = bot })
                                shown = shown + 1
                            end
                        end
                    elseif target then
                        if not GetItemInfo(target.id) then
                            pending[target.id] = true
                            RequestItem(target.id)
                        end
                        table.insert(display, { item = target, bot = bot })
                    end
                    shown = shown + 1
                end
            end

            if shown == 0 then
                local text
                if #bot.items == 0 then
                    text = "aucune piece recue pour ce bot"
                elseif view == VIEW_DONE then
                    text = "aucun creneau termine pour l'instant"
                else
                    text = "tous les creneaux sont equipes"
                end
                table.insert(display, { note = true, bot = bot, text = text })
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
    if self.slotKey then
        slotOpen[self.slotKey] = not slotOpen[self.slotKey]
        win.Refresh(true)
        return
    end

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

    -- Trois boutons plutot qu'un seul qui tourne entre trois etats : un bouton
    -- qui affiche "Manquants seulement" ne dit pas qu'une autre vue existe, et
    -- encore moins qu'il y en a deux. Celui de la vue courante est desactive -
    -- c'est la facon dont le client marque "tu es ici".
    local viewBtns = {}
    for i = 1, 3 do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetWidth(VIEW_WIDTH[i])
        b:SetHeight(20)
        if i == 1 then
            b:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -66)
        else
            b:SetPoint("LEFT", viewBtns[i - 1], "RIGHT", 4, 0)
        end
        b:SetText(VIEW_SHORT[i])
        b:SetScript("OnClick", function()
            view = i
            f.Refresh(true)
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(VIEW_LABEL[i])
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        viewBtns[i] = b
    end

    local expandBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    expandBtn:SetWidth(120)
    expandBtn:SetHeight(20)
    expandBtn:SetPoint("LEFT", viewBtns[3], "RIGHT", 8, 0)
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

    -- Le bilan a sa place ICI aussi, et pas seulement sur la minicarte : cette
    -- fenetre est deja ouverte quand on se demande ce que le raid a rapporte,
    -- et beaucoup de joueurs rangent leurs boutons de minicarte dans un sac a
    -- boutons qui ne transmet pas toujours le clic droit.
    local bilanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    bilanBtn:SetWidth(70)
    bilanBtn:SetHeight(20)
    bilanBtn:SetPoint("LEFT", expandBtn, "RIGHT", 8, 0)
    bilanBtn:SetText("Bilan")
    bilanBtn:SetScript("OnClick", function(self)
        if OuvrirMenuBilan then OuvrirMenuBilan(self) end
    end)
    bilanBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Debut de raid, fin de raid, compositions")
        GameTooltip:Show()
    end)
    bilanBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
    hint:SetText("Clic sur un bot ou un creneau : deplier  -  Maj+clic sur un objet : lien"
                 .. "  -  Actualiser avec .playerbotsbis report")

    function f.Refresh(rebuild)
        if rebuild then Rebuild() end

        for i = 1, 3 do
            if i == view then viewBtns[i]:Disable() else viewBtns[i]:Enable() end
        end

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
            r.botName, r.itemId, r.slotKey = nil, nil, nil

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
                    -- The count decides the order, but the percentage stays on
                    -- screen: it is the only thing that compares two bots whose
                    -- lists do not have the same number of slots.
                    r.info:SetText(string.format("%s%d/%d|r |cff999999%d%%|r",
                        colour, bot.equipped, bot.total, math.floor(ratio * 100 + 0.5)))
                    r.botName = bot.name
                elseif e.slot then
                    r.bar:Hide()
                    r.icon:SetTexture(nil)
                    local mark = ""
                    if e.count > 1 then
                        mark = e.open and "- " or "+ "
                    end
                    r.text:SetText("   " .. mark .. "|cffffd100" .. e.label .. "|r")
                    if e.wornRank then
                        r.info:SetText("|cff1eff00rang " .. e.wornRank .. " porte|r")
                    elseif e.count > 1 and not e.open then
                        r.info:SetText("|cff707070" .. e.count .. " rangs|r")
                    else
                        r.info:SetText("")
                    end
                    r.slotKey = e.key
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

                    -- The target carries the slot; a fallback is dimmed so the
                    -- eye lands on the piece the list actually picks.
                    local rank = string.format("%srang %d|r ",
                        item.target and "|cffffffff" or "|cff707070", item.pos or item.rank or 1)

                    if name then
                        local hex = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
                        hex = (hex and hex.hex) or "|cffffffff"
                        r.text:SetText("      " .. rank .. hex .. name .. "|r")
                    else
                        r.text:SetText("      " .. rank .. "|cff808080Chargement... ("
                                       .. item.id .. ")|r")
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

-- Lue par la fenetre des raids, qui regroupe les memes pieces par palier au
-- lieu de les regrouper par bot. Le flux du serveur porte deja le palier de
-- chaque ligne, donc la vue par raid ne demande rien de plus au serveur - elle
-- relit ce releve-ci.
function PlayerbotsBisRoster_Data()
    return roster
end

--------------------------------------------------------------------------------
-- Reception
--------------------------------------------------------------------------------

-- The stream arrives as ordinary system messages carrying a marker, and this
-- filter hides them from the chat frame. Server-built CHAT_MSG_ADDON packets
-- killed the 3.3.5 client (ERROR #134); a system message is the same path the
-- command's own summary lines already travel, so it is known to be safe here.
--
-- A filter runs once per chat frame, so the same line arrives once per frame
-- showing system messages. Those copies are back to back - the filter chain for
-- one message finishes before the next is handled - so comparing against the
-- previous line is enough, and unlike a set of everything seen it cannot swallow
-- a later report whose header happens to be identical.
local lastRaw

local function Dispatch(payload, raw)
    if raw == lastRaw then return end
    lastRaw = raw

    local kind, rest = string.match(payload, "^(%a);(.*)$")
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
        StoreSnapshot()
        TenirPromesses()

        -- La fenetre d'inspection peut etre ouverte pendant le releve : sans ce
        -- rappel elle garderait le chiffre d'avant jusqu'a sa reouverture.
        if PlayerbotsBisInspect_Refresh then PlayerbotsBisInspect_Refresh() end
        Print(string.format("%d bots recus. |cff808080/pbbis bilan|r pour les nouveautes.", #roster.bots))
    end
end

local MARKER = "PBBISREP;"

local function Filter(_, _, msg)
    if type(msg) ~= "string" then return false end
    if string.sub(msg, 1, string.len(MARKER)) ~= MARKER then return false end

    -- Ours: parse it, and hide it either way rather than spilling the raw
    -- stream into the chat frame.
    Dispatch(string.sub(msg, string.len(MARKER) + 1), msg)
    return true
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Filter)
else
    Print("|cffff2020ce client n'a pas ChatFrame_AddMessageEventFilter|r - "
          .. "le releve restera visible dans le tchat.")
end

--------------------------------------------------------------------------------
-- Minimap button
--------------------------------------------------------------------------------

local MINIMAP_RADIUS = 80
local DEFAULT_ANGLE  = 236

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

    local angle = math.deg(math.atan2(py - cy, px - cx))
    PlayerbotsBisTooltipDB.rosterAngle = angle
    PlaceOnRing(btn, angle)
end

-- Typing the command in the chat box is exactly what SendChatMessage does, and
-- the server intercepts a line starting with '.' as a command before it is ever
-- broadcast, so nothing is said out loud.
local function RequestReport()
    if not SendChatMessage then return false end
    local ok = pcall(SendChatMessage, ".playerbotsbis report", "SAY")
    return ok
end

-- "Demande un releve, PUIS fais ceci."
--
-- Un releve n'est pas instantane : la commande part, le serveur repond en
-- plusieurs messages, et le dernier porte le "E". Enchainer a l'aveugle - poser
-- le repere juste apres avoir tape la commande - le poserait sur l'etat
-- PRECEDENT, et le bilan serait decale d'un raid entier.
--
-- Le delai d'abandon existe parce que le silence est un resultat possible :
-- module desactive, aucun bot connecte, droits insuffisants. Sans lui, un clic
-- resterait en attente pour toujours sans rien dire.
local ATTENTE_MAX = 20

TenirPromesses = function()
    if #promesses == 0 then return end
    local aFaire = promesses
    promesses = {}
    if chrono then chrono:SetScript("OnUpdate", nil) end
    for _, fn in ipairs(aFaire) do pcall(fn) end
end

local function ReleveEtPuis(fn, libelle)
    if not RequestReport() then
        Print("impossible d'envoyer la commande - tape |cffffd100.playerbotsbis report|r"
              .. " toi-meme, puis recommence.")
        return
    end

    table.insert(promesses, fn)
    Print(libelle .. " - releve demande, patiente...")

    if not chrono then chrono = CreateFrame("Frame") end
    local ecoule = 0
    chrono:SetScript("OnUpdate", function(self, delta)
        ecoule = ecoule + delta
        if ecoule < ATTENTE_MAX then return end
        self:SetScript("OnUpdate", nil)
        promesses = {}
        Print("|cffff2020aucun releve recu en " .. ATTENTE_MAX .. " s.|r Le module est-il"
              .. " actif, et des bots connectes ?")
    end)
end

-- Le menu du bouton de minicarte.
--
-- CE QU'IL APPORTE QUE LES COMMANDES N'APPORTENT PAS : l'enchainement. Un soir
-- de raid se joue en deux gestes - "on part" et "on rentre" - et chacun demande
-- un releve suivi d'une action qui ne vaut que sur ce releve-la. Les taper a la
-- main veut dire attendre, voir passer le flux, puis se souvenir de la seconde
-- commande. Ici c'est un clic, et le reste suit tout seul.
--
-- UIDropDownMenu_Initialize et UIDropDownMenu_AddButton existent depuis
-- longtemps et sont presents en 3.3.5 ; EasyMenu, lui, ne l'est pas partout,
-- d'ou la construction a la main.
local menu

local function EntreesMenu()
    local e = {}

    local function ajoute(texte, fn, desactive)
        table.insert(e, { texte = texte, fn = fn, desactive = desactive })
    end

    ajoute("Debut de raid : poser le repere", function()
        ReleveEtPuis(function()
            if PlayerbotsBisRoster_Bilan then PlayerbotsBisRoster_Bilan("depart") end
        end, "Debut de raid")
    end)

    ajoute("Fin de raid : voir le bilan", function()
        ReleveEtPuis(function()
            if PlayerbotsBisRoster_Bilan then PlayerbotsBisRoster_Bilan("") end
        end, "Fin de raid")
    end)

    ajoute("Actualiser le releve", function()
        if not RequestReport() then
            Print("tape |cffffd100.playerbotsbis report|r pour actualiser.")
        end
    end)

    ajoute(nil)   -- separateur

    ajoute("Etat des bots", Toggle)

    if PlayerbotsBisRaids_Toggle then
        ajoute("Quel raid rapporte quoi", PlayerbotsBisRaids_Toggle)
    end
    if PlayerbotsBisBrowser_Toggle then
        ajoute("Navigateur des listes", PlayerbotsBisBrowser_Toggle)
    end

    -- Les compositions enregistrees, s'il y en a : inviter un raid complet
    -- depuis la minicarte est exactement le geste d'un debut de soiree.
    local compos = PlayerbotsBisTooltipDB and PlayerbotsBisTooltipDB.compo
    if compos then
        local noms = {}
        for nom in pairs(compos) do table.insert(noms, nom) end
        table.sort(noms)
        if #noms > 0 then
            ajoute(nil)
            for _, nom in ipairs(noms) do
                ajoute("Inviter la compo " .. nom, function()
                    if PlayerbotsBisCompo_Command then
                        PlayerbotsBisCompo_Command("invite " .. nom)
                    end
                end)
            end
        end
    end

    return e
end

OuvrirMenuBilan = function(ancre)
    if not CreateFrame or not UIDropDownMenu_Initialize or not ToggleDropDownMenu then
        Print("menu indisponible sur ce client - utilise |cffffd100/pbbis bilan|r.")
        return
    end

    if not menu then
        menu = CreateFrame("Frame", "PlayerbotsBisRosterMenu", UIParent, "UIDropDownMenuTemplate")
    end

    UIDropDownMenu_Initialize(menu, function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Playerbots BiS"
        info.isTitle = 1
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info)

        for _, entree in ipairs(EntreesMenu()) do
            info = UIDropDownMenu_CreateInfo()
            if not entree.texte then
                -- Un separateur est un bouton desactive sans texte : c'est la
                -- seule facon d'en obtenir un avec ce menu.
                info.disabled = 1
                info.notCheckable = 1
                info.text = " "
            else
                info.text = entree.texte
                info.notCheckable = 1
                info.func = entree.fn
                info.disabled = entree.desactive
            end
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")

    ToggleDropDownMenu(1, nil, menu, ancre, 0, 0)
end

local function BuildMinimapButton()
    if _G.PlayerbotsBisRosterMinimapButton then return _G.PlayerbotsBisRosterMinimapButton end

    local btn = CreateFrame("Button", "PlayerbotsBisRosterMinimapButton", Minimap)
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
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", DragToRing) end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            OuvrirMenuBilan(self)
        else
            Toggle()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Etat BiS des bots")
        GameTooltip:AddLine("Clic gauche : ouvrir la fenetre", 1, 1, 1)
        GameTooltip:AddLine("Clic droit : menu (debut de raid, bilan, compos)", 1, 1, 1)
        if roster.bots and #roster.bots > 0 then
            local eq, tot = 0, 0
            for _, bot in ipairs(roster.bots) do
                eq = eq + bot.equipped
                tot = tot + bot.total
            end
            GameTooltip:AddLine(string.format("Dernier releve : %d bots, %d/%d pieces (%s)",
                #roster.bots, eq, tot, roster.when), 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine("Aucun releve encore", 0.6, 0.6, 0.6)
        end
        GameTooltip:AddLine("Glisser : deplacer autour de la minicarte", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    PlaceOnRing(btn, PlayerbotsBisTooltipDB.rosterAngle or DEFAULT_ANGLE)
    return btn
end

-- Appelee par "/pbbis menu". Un sac a boutons de minicarte ne transmet pas
-- toujours le clic droit, et dans ce cas le menu serait inatteignable.
function PlayerbotsBisRoster_Menu()
    OuvrirMenuBilan(_G.PlayerbotsBisRosterMinimapButton or UIParent)
end

function PlayerbotsBisRoster_ToggleMinimap()
    local btn = _G.PlayerbotsBisRosterMinimapButton
    if not btn then return end
    PlayerbotsBisTooltipDB.rosterHide = not PlayerbotsBisTooltipDB.rosterHide
    if PlayerbotsBisTooltipDB.rosterHide then btn:Hide() else btn:Show() end
    return not PlayerbotsBisTooltipDB.rosterHide
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
    if name ~= "PlayerbotsBisTooltip" then return end
    PlayerbotsBisTooltipDB = PlayerbotsBisTooltipDB or {}
    local btn = BuildMinimapButton()
    if PlayerbotsBisTooltipDB.rosterHide then btn:Hide() end
    self:UnregisterEvent("ADDON_LOADED")
end)
