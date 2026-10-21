--[[
  Playerbots BiS Butin - released under GNU GPL v2, matching mod-playerbots-bis.

  CE QUE CETTE FENETRE REPOND
  ---------------------------
  "Qu'est-ce qu'il reste a aller chercher, et ou ?"

  L'etat BiS des bots repond bot par bot : ce qui manque a Gorkozu. Utile quand
  on regarde un bot, inutile quand on choisit un raid. La meme information, lue
  par l'autre bout - par la PIECE et par le BOSS qui la lache - dit tout de
  suite ou le raid de ce soir rapportera quelque chose.

  Trois niveaux, qu'on deplie :

      + Temple d'Ahn'Qiraj                     18 objets    31 bots
          + Princesse Huhuran                   4 objets     7 bots
              Ailes de Huhuran                              3 bots
              Carapace du royaume des insectes              2 bots

  Lu : "il reste dix-huit objets rang 1 a faire tomber dans AQ40 ; quatre chez
  Huhuran ; et les Ailes doivent tomber encore trois fois."

  D'OU VIENNENT LES CHIFFRES
  --------------------------
  Du meme flux que l'etat BiS : .playerbotsbis report. Le serveur envoie, bot
  par bot, chaque ligne de sa liste avec son rang, son etat, et un drapeau
  marquant LA CIBLE du creneau. On ne retient que les cibles manquantes - ni
  portees, ni en sac.

  La cible plutot que le rang brut : les listes empilent les phases, donc une
  piece rang 1 au Coeur du Magma reste "rang 1" dans le flux alors qu'a la
  phase AQ40 le bot vise mieux. TargetsPerSlot tranche cote serveur - une
  piece par creneau, palier le plus haut d'abord, rang 1 a l'interieur - et
  c'est ce verdict qu'on affiche.

  L'addon ecoute CHAT_MSG_SYSTEM directement, et non le filtre de tchat : un
  filtre qui renvoie true interrompt la chaine, donc l'addon charge en second
  ne verrait jamais rien. L'evenement, lui, est remis a tout le monde.

  CE QUE L'ADDON NE PEUT PAS DEVINER
  ----------------------------------
  Le client 3.3.5 ne sait pas d'ou tombe un objet : ni boss, ni donjon. C'est
  la base MONDE qui le sait. ButinData.lua est genere depuis elle par
  tools/export_bis_butin.ps1 - sans lui, tout se range sous "source inconnue"
  et l'addon le dit en clair plutot que de faire semblant.
]]

local MARKER = "PBBISREP;"

-- Les trois etats que le serveur envoie. Seul le premier nous interesse : une
-- piece en sac n'a plus besoin de tomber.
local STATE_MISSING = 0

local ROW_HEIGHT   = 18
local VISIBLE_ROWS = 17
local LARGEUR      = 580

local CLASS_FILE = {
    [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE",
    [5] = "PRIEST",  [6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE",
    [9] = "WARLOCK", [11] = "DRUID",
}

local QUALITE = {
    [0] = { 0.62, 0.62, 0.62 }, [1] = { 1.00, 1.00, 1.00 },
    [2] = { 0.12, 1.00, 0.00 }, [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
}

--------------------------------------------------------------------------------
-- Etat
--------------------------------------------------------------------------------

-- itemId -> { bots = { {nom=, cls=}, ... }, vus = { [nom] = true } }
local besoins = {}
local releve  = { bots = 0, scope = "", when = "", recu = false }
local encours = nil      -- le bot dont on lit les objets

local arbre   = {}       -- la vue construite : raids -> boss -> objets
local lignes  = {}       -- l'arbre aplati, tel qu'affiche
local deplie  = {}       -- cle -> true
local win

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Butin BiS|r : " .. tostring(msg))
end

local function CouleurClasse(cls)
    local file = CLASS_FILE[cls or 0]
    local c = file and RAID_CLASS_COLORS and RAID_CLASS_COLORS[file]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

--------------------------------------------------------------------------------
-- Noms d'objets
--
-- GetItemInfo ne repond que si le client a deja vu l'objet. Le faire survoler
-- par une infobulle cachee le lui fait demander au serveur ; en attendant, le
-- nom de secours vient du fichier genere. Sans ce repli, la fenetre afficherait
-- des numeros au premier releve suivant une connexion.
--------------------------------------------------------------------------------

local scanner = CreateFrame("GameTooltip", "PlayerbotsBisButinScan", UIParent, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")

local attente = 0

local function NomObjet(id)
    local nom, lien, qualite = GetItemInfo(id)
    if nom then return nom, lien, qualite end

    attente = attente + 1
    pcall(scanner.SetHyperlink, scanner, "item:" .. id)

    local secours = PlayerbotsBisButinNoms and PlayerbotsBisButinNoms[id]
    return secours or ("objet " .. id), nil, nil
end

--------------------------------------------------------------------------------
-- Lecture du flux .playerbotsbis report
--------------------------------------------------------------------------------

local function Reset(count, scope)
    besoins = {}
    encours = nil
    releve.bots  = tonumber(count) or 0
    releve.scope = scope or ""
    releve.when  = date("%H:%M:%S")
    releve.recu  = true
end

local function AjouterBot(nom, cls)
    encours = { nom = nom, cls = tonumber(cls) or 0 }
end

local function AjouterObjets(nom, packed)
    if not encours or encours.nom ~= nom then return end

    for id, state, _, _, _, cible in string.gmatch(packed, "(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)") do
        id = tonumber(id)

        -- LA CIBLE, et non le rang brut.
        --
        -- Le serveur envoie toutes les lignes atteignables de la liste du bot,
        -- chacune avec son rang DANS SON PALIER. Filtrer sur "rang 1" compte
        -- donc le meme creneau une fois par phase : des gants rang 1 au Coeur
        -- du Magma restent rang 1 dans ce flux alors qu'a la phase AQ40 le bot
        -- vise tout autre chose. Le module le dit lui-meme (BisBotScan.h) :
        --
        --     Counting every rank-1 row instead counts the same slot once per
        --     phase [...] A warrior showed 35 "pieces" for seventeen slots.
        --
        -- Le drapeau de cible, lui, est pose par TargetsPerSlot : une seule
        -- piece par creneau, palier le plus haut d'abord, rang 1 a l'interieur,
        -- et portable. C'est exactement "le rang 1 que ce bot attend", donc
        -- c'est lui qu'on lit.
        --
        -- Manquant aussi : une piece deja en sac n'a plus besoin de tomber.
        if cible == "1" and tonumber(state) == STATE_MISSING then
            local e = besoins[id]
            if not e then
                e = { bots = {}, vus = {} }
                besoins[id] = e
            end

            -- La meme piece peut figurer sur plusieurs paliers de la liste d'un
            -- meme bot. Sans cette garde, il compterait deux fois.
            if not e.vus[encours.nom] then
                e.vus[encours.nom] = true
                table.insert(e.bots, { nom = encours.nom, cls = encours.cls })
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Construction de l'arbre
--------------------------------------------------------------------------------

local SANS_SOURCE = "|cff808080Source inconnue|r"

local function Construire()
    arbre = {}

    local parMap = {}

    for id, e in pairs(besoins) do
        local n = table.getn(e.bots)
        if n > 0 then
            local src = PlayerbotsBisButinSources and PlayerbotsBisButinSources[id]
            local map = (src and src.map) or -1
            local boss = (src and src.boss) or SANS_SOURCE

            local raid = parMap[map]
            if not raid then
                local info = PlayerbotsBisButinMaps and PlayerbotsBisButinMaps[map]
                raid = {
                    map    = map,
                    nom    = (info and info.nom) or (map >= 0 and ("Carte " .. map)) or "Hors instance",
                    ordre  = (info and info.ordre) or 999,
                    boss   = {},
                    parNom = {},
                    -- "Sans lieu connu" n'est pas un endroit ou l'on va : le
                    -- classer par taille le ferait remonter en tete alors
                    -- qu'il ne repond a aucune question. Il reste en bas.
                    inconnu = (map < 0),
                    nbObjets = 0,
                    nbBots   = 0,
                }
                parMap[map] = raid
                table.insert(arbre, raid)
            end

            local b = raid.parNom[boss]
            if not b then
                b = { nom = boss, objets = {}, total = 0, jeton = (src and src.jeton) or false }
                raid.parNom[boss] = b
                table.insert(raid.boss, b)
            end

            table.insert(b.objets, { id = id, n = n, bots = e.bots })
            b.total = b.total + n

            raid.nbObjets = raid.nbObjets + 1
            raid.nbBots   = raid.nbBots + n
        end
    end

    -- Du plus gros au plus petit, a tous les niveaux : chaque liste descend
    -- par son PREMIER chiffre, celui de la colonne "Objets". L'oeil n'a donc
    -- qu'une seule regle a retenir, et la premiere ligne est toujours celle
    -- qui rapporte le plus.
    --
    -- A egalite parfaite, l'ordre de progression tranche : entre deux raids qui
    -- rapportent autant, le plus accessible passe devant.
    table.sort(arbre, function(a, b)
        if a.inconnu ~= b.inconnu then return b.inconnu end
        if a.nbObjets ~= b.nbObjets then return a.nbObjets > b.nbObjets end
        if a.nbBots ~= b.nbBots then return a.nbBots > b.nbBots end
        if a.ordre ~= b.ordre then return a.ordre < b.ordre end
        return a.nom < b.nom
    end)

    for _, raid in ipairs(arbre) do
        -- Meme regle pour les boss : combien de pieces d'abord, combien de bots
        -- ensuite. Un classement alphabetique ne repondrait a aucune question ;
        -- celui-ci repond a "lequel d'abord".
        table.sort(raid.boss, function(a, b)
            local na, nb = table.getn(a.objets), table.getn(b.objets)
            if na ~= nb then return na > nb end
            if a.total ~= b.total then return a.total > b.total end
            return a.nom < b.nom
        end)

        for _, b in ipairs(raid.boss) do
            table.sort(b.objets, function(x, y)
                if x.n ~= y.n then return x.n > y.n end
                return (NomObjet(x.id)) < (NomObjet(y.id))
            end)
        end
    end
end

local function Aplatir()
    lignes = {}

    for _, raid in ipairs(arbre) do
        local cleRaid = "R" .. raid.map
        table.insert(lignes, { type = "raid", cle = cleRaid, data = raid })

        if deplie[cleRaid] then
            for _, b in ipairs(raid.boss) do
                local cleBoss = cleRaid .. "|" .. b.nom
                table.insert(lignes, { type = "boss", cle = cleBoss, data = b })

                if deplie[cleBoss] then
                    for _, o in ipairs(b.objets) do
                        table.insert(lignes, { type = "objet", data = o })
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- La fenetre, batie comme le cadre de guilde
--------------------------------------------------------------------------------

local function Colonne(parent, largeur, texte, justif)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(largeur)
    b:SetHeight(24)

    local g = b:CreateTexture(nil, "BACKGROUND")
    g:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
    g:SetWidth(5)
    g:SetHeight(24)
    g:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    g:SetTexCoord(0, 0.078125, 0, 0.609375)

    local d = b:CreateTexture(nil, "BACKGROUND")
    d:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
    d:SetWidth(4)
    d:SetHeight(24)
    d:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    d:SetTexCoord(0.796875, 0.859375, 0, 0.609375)

    local m = b:CreateTexture(nil, "BACKGROUND")
    m:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
    m:SetPoint("TOPLEFT", g, "TOPRIGHT", 0, 0)
    m:SetPoint("BOTTOMRIGHT", d, "BOTTOMLEFT", 0, 0)
    m:SetTexCoord(0.078125, 0.796875, 0, 0.609375)

    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    if justif == "RIGHT" then
        t:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    else
        t:SetPoint("LEFT", b, "LEFT", 10, 0)
    end
    t:SetText(texte)

    return b
end

local Refresh

local function LigneEnter(self)
    local ligne = lignes[self.index]
    if not ligne then return end

    if ligne.type == "objet" then
        local _, lien = NomObjet(ligne.data.id)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if lien then
            GameTooltip:SetHyperlink(lien)
        else
            GameTooltip:AddLine(NomObjet(ligne.data.id))
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Attendu par %d bot(s) :", ligne.data.n), 1, 0.82, 0)

        local bots = ligne.data.bots
        for i = 1, math.min(table.getn(bots), 12) do
            local r, v, b = CouleurClasse(bots[i].cls)
            GameTooltip:AddLine("   " .. bots[i].nom, r, v, b)
        end
        if table.getn(bots) > 12 then
            GameTooltip:AddLine(string.format("   ... et %d autre(s)", table.getn(bots) - 12), 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("ID " .. ligne.data.id, 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Maj+clic : coller le lien", 0.6, 0.6, 0.6)
        GameTooltip:Show()
        return
    end

    local d = ligne.data
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if ligne.type == "raid" then
        GameTooltip:AddLine(d.nom, 1, 0.82, 0)
        GameTooltip:AddLine(string.format("%d objet(s) rang 1 encore a prendre", d.nbObjets), 1, 1, 1)
        GameTooltip:AddLine(string.format("%d besoin(s) de bots en tout", d.nbBots), 1, 1, 1)
    else
        GameTooltip:AddLine(d.nom, 1, 0.82, 0)
        GameTooltip:AddLine(string.format("%d objet(s), %d besoin(s)", table.getn(d.objets), d.total), 1, 1, 1)
    end
    GameTooltip:AddLine("Clic : deplier", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function LigneLeave()
    GameTooltip:Hide()
end

local function LigneClick(self)
    local ligne = lignes[self.index]
    if not ligne then return end

    if ligne.type == "objet" then
        if IsShiftKeyDown() then
            local _, lien = NomObjet(ligne.data.id)
            if lien and ChatEdit_InsertLink then ChatEdit_InsertLink(lien) end
        end
        return
    end

    deplie[ligne.cle] = not deplie[ligne.cle] or nil
    Refresh()
end

local function Batir()
    local f = CreateFrame("Frame", "PlayerbotsBisButinFrame", UIParent)
    f:SetWidth(LARGEUR)
    f:SetHeight(460)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    tinsert(UISpecialFrames, "PlayerbotsBisButinFrame")

    -- Le bandeau dore du cadre de guilde : meme texture, meme place.
    local banniere = f:CreateTexture(nil, "ARTWORK")
    banniere:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    banniere:SetWidth(300)
    banniere:SetHeight(64)
    banniere:SetPoint("TOP", f, "TOP", 0, 12)

    local titre = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titre:SetPoint("TOP", banniere, "TOP", 0, -14)
    titre:SetText("Butin restant")

    -- Le medaillon rond, comme le parchemin de la guilde.
    local icone = f:CreateTexture(nil, "ARTWORK")
    icone:SetWidth(42)
    icone:SetHeight(42)
    icone:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)
    icone:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue")
    icone:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local anneau = f:CreateTexture(nil, "OVERLAY")
    anneau:SetWidth(112)
    anneau:SetHeight(112)
    anneau:SetPoint("CENTER", icone, "CENTER", 10, -11)
    anneau:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local fermer = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    fermer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    -- La ligne de contexte, a la place du "41 membres (40 En ligne)".
    local resume = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resume:SetPoint("TOPLEFT", f, "TOPLEFT", 66, -38)
    resume:SetPoint("TOPRIGHT", f, "TOPRIGHT", -22, -38)
    resume:SetJustifyH("LEFT")
    f.resume = resume

    -- Les en-tetes de colonnes du cadre "Qui" / guilde.
    local colNom = Colonne(f, LARGEUR - 200, "Raid, boss et objet")
    colNom:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -58)

    local colObjets = Colonne(f, 90, "Objets", "RIGHT")
    colObjets:SetPoint("TOPLEFT", colNom, "TOPRIGHT", 0, 0)

    local colBots = Colonne(f, 90, "Bots", "RIGHT")
    colBots:SetPoint("TOPLEFT", colObjets, "TOPRIGHT", 0, 0)

    -- Le creux sombre qui recoit la liste.
    local creux = CreateFrame("Frame", nil, f)
    creux:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -82)
    creux:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, 96)
    creux:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    creux:SetBackdropColor(0, 0, 0, 0.55)
    creux:SetBackdropBorderColor(0.5, 0.45, 0.35, 1)

    local scroll = CreateFrame("ScrollFrame", "PlayerbotsBisButinScroll", creux, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", creux, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", creux, "BOTTOMRIGHT", -26, 4)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, Refresh)
    end)
    f.scroll = scroll

    f.rows = {}
    for i = 1, VISIBLE_ROWS do
        local r = CreateFrame("Button", nil, creux)
        r:SetHeight(ROW_HEIGHT)
        r:SetPoint("TOPLEFT", creux, "TOPLEFT", 6, -4 - (i - 1) * ROW_HEIGHT)
        r:SetPoint("TOPRIGHT", creux, "TOPRIGHT", -28, -4 - (i - 1) * ROW_HEIGHT)
        r.index = 0

        local h = r:CreateTexture(nil, "HIGHLIGHT")
        h:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        h:SetBlendMode("ADD")
        h:SetAllPoints(r)

        -- La bande de fond, une ligne sur deux. C'est elle qui fait tenir l'oeil
        -- sur une ligne longue jusqu'au chiffre de droite.
        local z = r:CreateTexture(nil, "BACKGROUND")
        z:SetTexture(1, 1, 1, 0.04)
        z:SetAllPoints(r)
        r.zebre = z

        local plus = r:CreateTexture(nil, "ARTWORK")
        plus:SetWidth(14)
        plus:SetHeight(14)
        plus:SetPoint("LEFT", r, "LEFT", 2, 0)
        r.plus = plus

        local nom = r:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nom:SetPoint("LEFT", r, "LEFT", 20, 0)
        nom:SetJustifyH("LEFT")
        r.nom = nom

        local objets = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        objets:SetPoint("RIGHT", r, "RIGHT", -98, 0)
        objets:SetWidth(84)
        objets:SetJustifyH("RIGHT")
        r.objets = objets

        local bots = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        bots:SetPoint("RIGHT", r, "RIGHT", -6, 0)
        bots:SetWidth(84)
        bots:SetJustifyH("RIGHT")
        r.bots = bots

        -- Le nom doit s'arreter avant les chiffres, sinon une piece au nom long
        -- passe dessous et les deux deviennent illisibles.
        nom:SetPoint("RIGHT", objets, "LEFT", -6, 0)

        r:SetScript("OnEnter", LigneEnter)
        r:SetScript("OnLeave", LigneLeave)
        r:SetScript("OnClick", LigneClick)

        f.rows[i] = r
    end

    -- Le bandeau du bas, a la place du message du jour.
    local pied = CreateFrame("Frame", nil, f)
    pied:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 52)
    pied:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 52)
    pied:SetHeight(36)
    pied:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    pied:SetBackdropColor(0, 0, 0, 0.55)
    pied:SetBackdropBorderColor(0.5, 0.45, 0.35, 1)

    local aide = pied:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aide:SetPoint("TOPLEFT", pied, "TOPLEFT", 8, -6)
    aide:SetPoint("BOTTOMRIGHT", pied, "BOTTOMRIGHT", -8, 6)
    aide:SetJustifyH("LEFT")
    aide:SetJustifyV("TOP")
    f.aide = aide

    local actualiser = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    actualiser:SetWidth(120)
    actualiser:SetHeight(22)
    actualiser:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 22)
    actualiser:SetText("Actualiser")
    actualiser:SetScript("OnClick", function()
        if SendChatMessage then
            pcall(SendChatMessage, ".playerbotsbis report", "SAY")
            Print("releve demande au serveur...")
        end
    end)

    local tout = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    tout:SetWidth(120)
    tout:SetHeight(22)
    tout:SetPoint("LEFT", actualiser, "RIGHT", 8, 0)
    tout:SetText("Tout deplier")
    tout:SetScript("OnClick", function()
        for _, raid in ipairs(arbre) do
            deplie["R" .. raid.map] = true
            for _, b in ipairs(raid.boss) do
                deplie["R" .. raid.map .. "|" .. b.nom] = true
            end
        end
        Refresh()
    end)

    local rien = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rien:SetWidth(120)
    rien:SetHeight(22)
    rien:SetPoint("LEFT", tout, "RIGHT", 8, 0)
    rien:SetText("Tout replier")
    rien:SetScript("OnClick", function()
        deplie = {}
        Refresh()
    end)

    f:Hide()
    return f
end

--------------------------------------------------------------------------------
-- Affichage
--------------------------------------------------------------------------------

Refresh = function(reconstruire)
    if not win then return end

    if reconstruire then
        Construire()
    end
    Aplatir()

    local total, objets = 0, 0
    for _, raid in ipairs(arbre) do
        total = total + raid.nbBots
        objets = objets + raid.nbObjets
    end

    if releve.recu then
        win.resume:SetText(string.format(
            "|cffffd100%s|r  -  %d bots  -  |cff20ff20%d|r objets rang 1 a prendre  -  %d besoins  -  releve %s",
            releve.scope ~= "" and releve.scope or "bots", releve.bots, objets, total, releve.when))
    else
        win.resume:SetText("|cffff8020Aucun releve.|r  Clique sur Actualiser, ou tape |cffffffff.playerbotsbis report|r.")
    end

    if PlayerbotsBisButinStamp then
        win.aide:SetText("Clic sur un raid ou un boss : deplier  -  Maj+clic sur un objet : coller le lien\n"
            .. "|cff808080Sources du " .. PlayerbotsBisButinStamp
            .. " - un objet deja porte par tous les bots qui le listent disparait de la fenetre.|r")
    else
        win.aide:SetText("Clic sur un raid ou un boss : deplier  -  Maj+clic sur un objet : coller le lien\n"
            .. "|cffff8020ButinData.lua n'est pas genere|r|cff808080 - lance tools/export_bis_butin.ps1,"
            .. " sinon tout reste sous \"source inconnue\".|r")
    end

    attente = 0

    local nb = table.getn(lignes)
    FauxScrollFrame_Update(win.scroll, nb, VISIBLE_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(win.scroll)

    for i = 1, VISIBLE_ROWS do
        local r = win.rows[i]
        local index = offset + i
        local ligne = lignes[index]

        r.index = index

        if not ligne then
            r:Hide()
        else
            r:Show()
            r.zebre:SetTexture(1, 1, 1, (index % 2 == 0) and 0.05 or 0)

            if ligne.type == "raid" then
                local d = ligne.data
                r.plus:Show()
                r.plus:SetTexture(deplie[ligne.cle] and "Interface\\Buttons\\UI-MinusButton-Up"
                                                     or "Interface\\Buttons\\UI-PlusButton-Up")
                r.plus:SetPoint("LEFT", r, "LEFT", 2, 0)
                r.nom:SetPoint("LEFT", r, "LEFT", 20, 0)
                r.nom:SetText(d.nom)
                r.nom:SetTextColor(1, 0.82, 0)
                r.objets:SetText(string.format("%d objets", d.nbObjets))
                r.objets:SetTextColor(1, 1, 1)
                r.bots:SetText(string.format("%d bots", d.nbBots))
                r.bots:SetTextColor(0.13, 1, 0.13)

            elseif ligne.type == "boss" then
                local d = ligne.data
                r.plus:Show()
                r.plus:SetTexture(deplie[ligne.cle] and "Interface\\Buttons\\UI-MinusButton-Up"
                                                     or "Interface\\Buttons\\UI-PlusButton-Up")
                r.plus:SetPoint("LEFT", r, "LEFT", 18, 0)
                r.nom:SetPoint("LEFT", r, "LEFT", 36, 0)
                r.nom:SetText(d.nom)
                r.nom:SetTextColor(0.9, 0.72, 0.4)
                r.objets:SetText(string.format("%d", table.getn(d.objets)))
                r.objets:SetTextColor(0.8, 0.8, 0.8)
                r.bots:SetText(string.format("%d", d.total))
                r.bots:SetTextColor(0.13, 1, 0.13)

            else
                local d = ligne.data
                local nom, _, qualite = NomObjet(d.id)
                r.plus:Hide()
                r.nom:SetPoint("LEFT", r, "LEFT", 52, 0)
                r.nom:SetText(nom)
                local c = QUALITE[qualite or 4] or QUALITE[4]
                r.nom:SetTextColor(c[1], c[2], c[3])
                r.objets:SetText("")
                r.bots:SetText(string.format("%d bot%s", d.n, d.n > 1 and "s" or ""))
                r.bots:SetTextColor(1, 0.82, 0)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Le flux
--------------------------------------------------------------------------------

local dernier

local function Dispatch(payload, raw)
    if raw == dernier then return end
    dernier = raw

    local kind, rest = string.match(payload, "^(%a);(.*)$")
    if not kind then return end

    if kind == "S" then
        local count, scope = string.match(rest, "^(%d+);(.*)$")
        Reset(count, scope)
    elseif kind == "B" then
        local nom, cls = string.match(rest, "^(.-);(%d+);")
        if nom then AjouterBot(nom, cls) end
    elseif kind == "I" then
        local nom, packed = string.match(rest, "^(.-);(.*)$")
        if nom then AjouterObjets(nom, packed) end
    elseif kind == "E" then
        if not win then win = Batir() end
        Refresh(true)
    end
end

local ecoute = CreateFrame("Frame")
ecoute:RegisterEvent("CHAT_MSG_SYSTEM")
ecoute:SetScript("OnEvent", function(_, _, msg)
    if type(msg) ~= "string" then return end
    if string.sub(msg, 1, string.len(MARKER)) ~= MARKER then return end
    Dispatch(string.sub(msg, string.len(MARKER) + 1), msg)
end)

-- Les noms d'objets arrivent du serveur avec un temps de retard. Tant qu'il en
-- manque, on repasse : sans cela la premiere ouverture apres une connexion
-- resterait pleine de "objet 19353".
local horloge = CreateFrame("Frame")
local depuis = 0
horloge:SetScript("OnUpdate", function(_, elapsed)
    if not win or not win:IsShown() or attente == 0 then return end
    depuis = depuis + elapsed
    if depuis < 1 then return end
    depuis = 0
    Refresh()
end)

--------------------------------------------------------------------------------
-- Commandes
--------------------------------------------------------------------------------

local function Toggle()
    if not win then win = Batir() end
    if win:IsShown() then
        win:Hide()
    else
        Refresh(true)
        win:Show()
        if not releve.recu and SendChatMessage then
            pcall(SendChatMessage, ".playerbotsbis report", "SAY")
            Print("aucun releve en memoire - j'en demande un.")
        end
    end
end

--------------------------------------------------------------------------------
-- Le bouton de minicarte
--
-- Meme mecanique que celui de l'etat BiS : on garde l'ANGLE, pas la position.
-- Une position absolue suit la minicarte de travers des que son echelle ou son
-- ancrage change ; un angle reste juste.
--------------------------------------------------------------------------------

local MINIMAP_RADIUS = 80
local ANGLE_DEFAUT   = 212   -- a gauche de celui de l'etat BiS, pour ne pas le recouvrir

local function PlacerSurLAnneau(btn, angle)
    local rad = math.rad(angle)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
                 MINIMAP_RADIUS * math.cos(rad),
                 MINIMAP_RADIUS * math.sin(rad))
end

local function GlisserSurLAnneau(btn)
    local cx, cy = Minimap:GetCenter()
    if not cx then return end
    local scale = Minimap:GetEffectiveScale()
    local px, py = GetCursorPosition()
    px, py = px / scale, py / scale

    local angle = math.deg(math.atan2(py - cy, px - cx))
    PlayerbotsBisButinDB.angle = angle
    PlacerSurLAnneau(btn, angle)
end

local function BatirBoutonMinicarte()
    if _G.PlayerbotsBisButinMinimapButton then return _G.PlayerbotsBisButinMinimapButton end

    local btn = CreateFrame("Button", "PlayerbotsBisButinMinimapButton", Minimap)
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
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", GlisserSurLAnneau) end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnClick", function(self, bouton)
        if bouton == "RightButton" then
            -- Clic droit : on redemande un releve. C'est le geste le plus
            -- frequent apres un boss, et il evite d'ouvrir la fenetre pour
            -- cliquer un bouton qu'on refermera aussitot.
            if SendChatMessage then
                pcall(SendChatMessage, ".playerbotsbis report", "SAY")
                Print("releve demande au serveur...")
            end
        else
            Toggle()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Butin restant")
        GameTooltip:AddLine("Clic gauche : ouvrir la fenetre", 1, 1, 1)
        GameTooltip:AddLine("Clic droit : demander un releve", 1, 1, 1)

        if releve.recu then
            local total, objets = 0, 0
            for _, raid in ipairs(arbre) do
                total = total + raid.nbBots
                objets = objets + raid.nbObjets
            end
            GameTooltip:AddLine(string.format("%d objets rang 1 a prendre, %d besoins (%s)",
                objets, total, releve.when), 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine("Aucun releve encore", 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine("Glisser : deplacer autour de la minicarte", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    PlacerSurLAnneau(btn, PlayerbotsBisButinDB.angle or ANGLE_DEFAUT)
    return btn
end

-- Les variables sauvegardees ne sont lues qu'apres le chargement de l'addon :
-- batir le bouton plus tot le poserait toujours a l'angle par defaut, et le
-- premier glissement ecrirait dans une table qui n'existe pas encore.
local demarrage = CreateFrame("Frame")
demarrage:RegisterEvent("VARIABLES_LOADED")
demarrage:RegisterEvent("PLAYER_LOGIN")
demarrage:SetScript("OnEvent", function(self)
    if type(PlayerbotsBisButinDB) ~= "table" then PlayerbotsBisButinDB = {} end
    if PlayerbotsBisButinDB.minicarte == false then return end
    BatirBoutonMinicarte()
end)

SLASH_PBBUTIN1 = "/pbbutin"
SLASH_PBBUTIN2 = "/butin"
SlashCmdList["PBBUTIN"] = function(arg)
    arg = string.lower(arg or "")
    if arg == "report" or arg == "actualiser" then
        if SendChatMessage then pcall(SendChatMessage, ".playerbotsbis report", "SAY") end
        return
    end

    if arg == "minicarte" then
        if type(PlayerbotsBisButinDB) ~= "table" then PlayerbotsBisButinDB = {} end
        local btn = BatirBoutonMinicarte()
        if btn:IsShown() then
            btn:Hide()
            PlayerbotsBisButinDB.minicarte = false
            Print("bouton de minicarte cache. |cff808080/pbbutin minicarte|r pour le revoir.")
        else
            btn:Show()
            PlayerbotsBisButinDB.minicarte = true
            Print("bouton de minicarte affiche.")
        end
        return
    end
    Toggle()
end
