--[[
  PlayerbotsBisInspect - le compte de BiS dans la fenetre d'inspection.

  POURQUOI CE FICHIER EXISTE. La fenetre d'etat des bots repond a "ou en est
  tout le monde". Celle-ci repond a "ou en est CELUI-LA", au moment ou on le
  regarde deja - et c'est le reflexe naturel : on clique droit sur un bot, on
  inspecte, et le chiffre devrait etre la.

  D'OU VIENT LE CHIFFRE. Du dernier releve, pas d'un calcul client. Le client ne
  connait ni les listes ni la spe resolue du bot ; le serveur, lui, les envoie
  deja dans le flux de ".playerbotsbis report". On relit donc ce releve, et on
  affiche SA date : un chiffre sans date laisserait croire qu'il est frais.

  CE QUI EST DEFENSIF, ET POURQUOI. Blizzard_InspectUI est charge a la demande,
  et ses elements changent de nom d'un client a l'autre. Chaque acces est donc
  garde : au pire la ligne ne s'affiche pas, jamais une erreur Lua par-dessus la
  fenetre d'inspection.
]]

local ADDON_NAME = "PlayerbotsBisTooltip"

local ligne          -- la FontString, creee une seule fois
local dernierNom     -- evite de refaire le texte a chaque evenement

local function Roster()
    if not PlayerbotsBisRoster_Data then return nil end
    return PlayerbotsBisRoster_Data()
end

-- Vert quand tout est en place, orange quand il reste du chemin, rouge au
-- debut. Les memes seuils que la barre de la fenetre d'etat, pour que les deux
-- vues ne racontent pas deux histoires.
local function Couleur(equipes, total)
    if total <= 0 then return 0.6, 0.6, 0.6 end
    local part = equipes / total
    if part >= 1 then return 0.1, 1.0, 0.1 end
    if part >= 0.5 then return 1.0, 0.82, 0.0 end
    return 1.0, 0.5, 0.2
end

local function Texte(nom)
    local roster = Roster()
    if not roster or not roster.byName then
        return "BiS : aucun releve", 0.6, 0.6, 0.6
    end

    local bot = roster.byName[nom]
    if not bot then
        -- Un vrai joueur, ou un bot absent du dernier releve parce qu'il etait
        -- deconnecte. Dans les deux cas le chiffre serait invente.
        return "BiS : absent du releve de " .. (roster.when or "?"), 0.6, 0.6, 0.6
    end

    local r, g, b = Couleur(bot.equipped or 0, bot.total or 0)
    local txt = string.format("BiS : %d/%d equipes", bot.equipped or 0, bot.total or 0)

    -- "En sac" merite sa place : c'est la seule part du retard qui se rattrape
    -- toute seule au prochain passage d'equipement.
    if (bot.carried or 0) > 0 then
        txt = txt .. string.format(", %d en sac", bot.carried)
    end
    if (bot.missing or 0) > 0 then
        txt = txt .. string.format(", %d manquants", bot.missing)
    end

    return txt .. "  |cff808080(" .. (roster.when or "?") .. ")|r", r, g, b
end

local function Cible()
    local frame = _G.InspectFrame
    if not frame then return nil end

    local unit = frame.unit or "target"
    if not UnitExists or not UnitExists(unit) then return nil end
    return UnitName(unit)
end

local function Rafraichir(force)
    local frame = _G.InspectFrame
    if not frame or not frame:IsShown() or not ligne then return end

    local nom = Cible()
    if not nom then
        ligne:SetText("")
        dernierNom = nil
        return
    end

    if nom == dernierNom and not force then return end
    dernierNom = nom

    local txt, r, g, b = Texte(nom)
    ligne:SetText(txt)
    ligne:SetTextColor(r, g, b)
end

local function Installer()
    local frame = _G.InspectFrame
    if not frame or ligne then return end

    ligne = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

    -- Sous le niveau et la classe, dans la bande vide au-dessus du modele. A
    -- defaut, un repli sur le cadre lui-meme : une ancre absente ferait une
    -- erreur a l'ouverture de l'inspection, ce qui serait pire que pas de ligne.
    local ancre = _G.InspectLevelText or _G.InspectNameText
    if ancre then
        ligne:SetPoint("TOP", ancre, "BOTTOM", 0, -3)
    else
        ligne:SetPoint("TOP", frame, "TOP", 0, -60)
    end

    frame:HookScript("OnShow", function() Rafraichir(true) end)
    frame:HookScript("OnHide", function() dernierNom = nil end)
    Rafraichir(true)
end

local ecoute = CreateFrame("Frame")
ecoute:RegisterEvent("ADDON_LOADED")
ecoute:RegisterEvent("INSPECT_READY")
ecoute:RegisterEvent("PLAYER_TARGET_CHANGED")
ecoute:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            Installer()
        elseif arg1 == ADDON_NAME and _G.InspectFrame then
            -- L'interface d'inspection etait deja chargee avant nous.
            Installer()
        end
        return
    end

    -- INSPECT_READY arrive APRES l'ouverture : c'est lui qui porte les donnees,
    -- donc le premier affichage serait vide sans ce second passage.
    Rafraichir(true)
end)

-- Appelable depuis le repartiteur /pbbis, et apres un nouveau releve.
function PlayerbotsBisInspect_Refresh()
    Rafraichir(true)
end
