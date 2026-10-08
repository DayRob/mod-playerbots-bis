--[[
  PlayerbotsBisBilan - la fenetre du bilan de raid.

  POURQUOI UNE FENETRE PLUTOT QUE DU TCHAT. Un bilan de fin de raid se lit, se
  parcourt, se garde a l'oeil pendant qu'on distribue. Dans le tchat il part
  vers le haut des la premiere phrase d'un bot, et vingt gains sur un bon soir
  chassent tout le reste de l'ecran.

  D'OU VIENNENT LES DONNEES. De PlayerbotsBisRoster, qui tient les deux
  instantanes - le repere et l'etat courant - dans les variables sauvegardees.
  Ce fichier ne calcule rien de neuf : il AFFICHE la meme comparaison que
  "/pbbis bilan" ecrivait dans le tchat. Les deux ne peuvent donc pas diverger.
]]

local LIGNES_VISIBLES = 14
local HAUTEUR_LIGNE   = 20

local fenetre
local lignes = {}
local donnees = {}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BiS|r: " .. msg)
end

local CLASS_COLOR = {
    [1] = { 0.78, 0.61, 0.43 }, [2] = { 0.96, 0.55, 0.73 }, [3] = { 0.67, 0.83, 0.45 },
    [4] = { 1.00, 0.96, 0.41 }, [5] = { 1.00, 1.00, 1.00 }, [6] = { 0.77, 0.12, 0.23 },
    [7] = { 0.00, 0.44, 0.87 }, [8] = { 0.41, 0.80, 0.94 }, [9] = { 0.58, 0.51, 0.79 },
    [11] = { 1.00, 0.49, 0.04 },
}

-- La comparaison est celle de PlayerbotsBisRoster, pas une copie : deux
-- calculs separes finiraient par ne plus dire la meme chose, et c'est
-- exactement ce qui commencait a arriver.
local function Comparer()
    if not PlayerbotsBisRoster_Gains then return nil, 0 end
    return PlayerbotsBisRoster_Gains()
end

local function Rafraichir()
    if not fenetre then return end

    local db = PlayerbotsBisTooltipDB
    local bilan = db and db.bilan
    local gains, absents = Comparer()
    donnees = gains or {}

    if not bilan or not bilan.courant then
        fenetre.entete:SetText("|cffff8020Aucun releve en memoire.|r Lance"
            .. " |cffffd100.playerbotsbis report|r.")
    elseif not gains then
        fenetre.entete:SetText("|cffff8020Aucun repere pose.|r")
    elseif bilan.depart == bilan.courant then
        fenetre.entete:SetText("Repere pose sur le releve du " .. bilan.courant.quand
            .. " - rien a comparer encore.")
    else
        local cibles = 0
        for _, g in ipairs(donnees) do if g.cible then cibles = cibles + 1 end end
        fenetre.entete:SetText(string.format(
            "Du %s au %s  -  |cff1eff00%d|r piece(s) de rang 1, %d repli(s)%s",
            bilan.depart.quand, bilan.courant.quand, cibles, #donnees - cibles,
            absents > 0 and string.format("  |cff808080(%d bot(s) absent(s) du repere)|r", absents) or ""))
    end

    local total = #donnees
    FauxScrollFrame_Update(fenetre.scroll, total, LIGNES_VISIBLES, HAUTEUR_LIGNE)
    local offset = FauxScrollFrame_GetOffset(fenetre.scroll)

    for i = 1, LIGNES_VISIBLES do
        local ligne = lignes[i]
        local g = donnees[i + offset]
        if g then
            local c = CLASS_COLOR[g.cls] or { 0.8, 0.8, 0.8 }
            local _, lien = GetItemInfo(g.id)
            if not lien and PlayerbotsBis_RequestItem then
                PlayerbotsBis_RequestItem(g.id)
            end
            -- Ce que la piece a chasse. Sans ca le bilan dit ce qui est
            -- arrive mais pas ce que ca valait : remplacer du vide et
            -- remplacer un rang 2 ne sont pas le meme soir.
            local sortie = ""
            if g.remplace and #g.remplace > 0 then
                local noms = {}
                for _, ancien in ipairs(g.remplace) do
                    local _, l = GetItemInfo(ancien)
                    if not l and PlayerbotsBis_RequestItem then
                        PlayerbotsBis_RequestItem(ancien)
                    end
                    table.insert(noms, l or ("objet " .. ancien))
                end
                sortie = "  |cff808080<-|r " .. table.concat(noms, " |cff808080et|r ")
            elseif g.slot then
                sortie = "  |cff808080<- creneau vide|r"
            end

            ligne.itemId = g.id
            ligne.texte:SetText(string.format("|cff%02x%02x%02x%s|r   %s   %s%s",
                c[1] * 255, c[2] * 255, c[3] * 255, g.nom,
                lien or ("|cff808080objet " .. g.id .. "|r"),
                g.cible and "|cff1eff00(rang 1)|r" or "|cff808080(repli)|r",
                sortie))
            ligne:Show()
        else
            ligne.itemId = nil
            ligne.texte:SetText("")
            ligne:Hide()
        end
    end

    if total == 0 and bilan and bilan.depart and bilan.depart ~= bilan.courant then
        lignes[1].texte:SetText("|cff808080Rien de neuf depuis le repere.|r")
        lignes[1].itemId = nil
        lignes[1]:Show()
    end
end

local function Construire()
    local f = CreateFrame("Frame", "PlayerbotsBisBilanFrame", UIParent)
    f:SetWidth(680)
    f:SetHeight(400)
    f:SetPoint("CENTER", UIParent, "CENTER", 120, 0)
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
    tinsert(UISpecialFrames, "PlayerbotsBisBilanFrame")

    local titre = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titre:SetPoint("TOP", f, "TOP", 0, -16)
    titre:SetText("Bilan du raid")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    f.entete = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.entete:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -46)
    f.entete:SetWidth(620)
    f.entete:SetJustifyH("LEFT")

    local poser = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    poser:SetWidth(150)
    poser:SetHeight(20)
    poser:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -68)
    poser:SetText("Debut de raid")
    poser:SetScript("OnClick", function()
        if PlayerbotsBisRoster_ReleveEtPuis then
            PlayerbotsBisRoster_ReleveEtPuis(function()
                if PlayerbotsBisRoster_Bilan then PlayerbotsBisRoster_Bilan("depart", true) end
                Rafraichir()
            end, "Debut de raid")
        end
    end)
    poser:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Releve, puis repere pose ici")
        GameTooltip:Show()
    end)
    poser:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local maj = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    maj:SetWidth(150)
    maj:SetHeight(20)
    maj:SetPoint("LEFT", poser, "RIGHT", 8, 0)
    maj:SetText("Fin de raid")
    maj:SetScript("OnClick", function()
        if PlayerbotsBisRoster_ReleveEtPuis then
            PlayerbotsBisRoster_ReleveEtPuis(Rafraichir, "Fin de raid")
        end
    end)
    maj:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Releve, puis comparaison avec le repere")
        GameTooltip:Show()
    end)
    maj:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.scroll = CreateFrame("ScrollFrame", "PlayerbotsBisBilanScroll", f, "FauxScrollFrameTemplate")
    f.scroll:SetWidth(620)
    f.scroll:SetHeight(LIGNES_VISIBLES * HAUTEUR_LIGNE)
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -96)
    f.scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, HAUTEUR_LIGNE, Rafraichir)
    end)

    for i = 1, LIGNES_VISIBLES do
        local l = CreateFrame("Button", nil, f)
        l:SetWidth(620)
        l:SetHeight(HAUTEUR_LIGNE)
        l:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", 0, -(i - 1) * HAUTEUR_LIGNE)
        l.texte = l:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        l.texte:SetPoint("LEFT", l, "LEFT", 4, 0)
        l.texte:SetJustifyH("LEFT")

        -- Maj+clic insere le lien, comme dans la fenetre d'etat : c'est le
        -- geste qu'on fait pour annoncer un objet en canal de raid.
        l:SetScript("OnClick", function(self)
            if not self.itemId then return end
            local _, lien = GetItemInfo(self.itemId)
            if IsShiftKeyDown() and lien and ChatEdit_InsertLink then
                ChatEdit_InsertLink(lien)
            end
        end)
        l:SetScript("OnEnter", function(self)
            if not self.itemId then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemId)
            GameTooltip:Show()
        end)
        l:SetScript("OnLeave", function() GameTooltip:Hide() end)
        l:Hide()
        lignes[i] = l
    end

    local pied = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pied:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 26, 20)
    pied:SetText("Maj+clic sur une ligne : inserer le lien  -  |cff808080<-|r : la piece remplacee  -  /pbbis bilan texte : dans le tchat")

    return f
end

function PlayerbotsBisBilan_Toggle()
    if not fenetre then fenetre = Construire() end
    if fenetre:IsShown() then
        fenetre:Hide()
    else
        Rafraichir()
        fenetre:Show()
    end
end

-- Appelee apres chaque releve : si la fenetre est ouverte, elle suit.
function PlayerbotsBisBilan_Refresh()
    if fenetre and fenetre:IsShown() then Rafraichir() end
end
