--[[
  Playerbots BiS - jets automatiques sur une LISTE NOMMEE d'objets.

  Pourquoi pas un auto-roll general : parce qu'un addon qui jette sur tout
  fait "besoin" sur la cuirasse de plaques du guerrier quand on est mage, et
  qu'un raid de bots ne proteste pas - il encaisse. Ce fichier ne jette donc
  QUE sur des identifiants inscrits dans une liste, et la liste par defaut ne
  contient que les neuf bijoux hakkari de Zul'Gurub : des objets de quete que
  tout le monde ramasse, qui ne privent personne, et qui ouvrent vingt fenetres
  de jet par soiree.

  Les identifiants viennent de la base monde du serveur, pas de ma memoire.

  Mecanique 3.3.5 : le serveur annonce un jet par START_LOOT_ROLL avec un
  numero de jet, GetLootRollItemLink en donne le lien, et RollOnLoot(numero,
  type) repond - 0 passer, 1 besoin, 2 cupidite, 3 desenchanter. Un objet lie
  quand ramasse ouvre en plus une demande de confirmation, CONFIRM_LOOT_ROLL,
  qu'il faut valider par ConfirmLootRoll, sinon le jet reste en suspens jusqu'a
  la fin du compte a rebours.
]]

local ADDON_NAME = "PlayerbotsBisTooltip"

local BESOIN, CUPIDITE = 1, 2

-- Les neuf bijoux, releves dans item_template du serveur.
local BIJOUX_ZG = {
    [19707] = "Bijou hakkari rouge",
    [19708] = "Bijou hakkari bleu",
    [19709] = "Bijou hakkari jaune",
    [19710] = "Bijou hakkari orange",
    [19711] = "Bijou hakkari vert",
    [19712] = "Bijou hakkari violet",
    [19713] = "Bijou hakkari bronze",
    [19714] = "Bijou hakkari bronze fonce",
    [19715] = "Bijou hakkari dore",
}

local db
local enAttente = {}   -- numero de jet -> type choisi, pour la confirmation

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BiS|r: " .. msg)
end

local function Reglages()
    db.jets = db.jets or {}
    local j = db.jets
    if j.actif == nil then j.actif = false end
    j.mode = j.mode or "besoin"
    if not j.objets then
        j.objets = {}
        for id in pairs(BIJOUX_ZG) do j.objets[id] = true end
    end
    return j
end

local function IdDepuisLien(lien)
    if not lien then return nil end
    local id = string.match(lien, "item:(%d+)")
    return id and tonumber(id) or nil
end

-- Le mode voulu, rabattu sur ce que le serveur autorise reellement pour cet
-- objet. Demander "besoin" sur un objet ou le serveur l'interdit ne produit
-- rien du tout : la fenetre reste ouverte et on a l'air d'avoir rien fait.
local function TypeDeJet(numero)
    local _, _, _, _, _, peutBesoin, peutCupidite = GetLootRollItemInfo(numero)
    local voulu = Reglages().mode

    if voulu == "besoin" and peutBesoin then return BESOIN end
    if peutCupidite then return CUPIDITE end
    if peutBesoin then return BESOIN end
    return nil
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("ADDON_LOADED")
cadre:RegisterEvent("START_LOOT_ROLL")
cadre:RegisterEvent("CONFIRM_LOOT_ROLL")

cadre:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        PlayerbotsBisTooltipDB = PlayerbotsBisTooltipDB or {}
        db = PlayerbotsBisTooltipDB
        Reglages()
        return
    end

    if not db then return end
    local reglages = Reglages()
    if not reglages.actif then return end

    if event == "START_LOOT_ROLL" then
        local numero = arg1
        local id = IdDepuisLien(GetLootRollItemLink(numero))
        if not id or not reglages.objets[id] then return end

        local type_ = TypeDeJet(numero)
        if not type_ then return end

        enAttente[numero] = type_
        RollOnLoot(numero, type_)
        return
    end

    if event == "CONFIRM_LOOT_ROLL" then
        -- arg1 = numero de jet, arg2 = type. On ne confirme que NOS jets :
        -- confirmer aveuglement validerait aussi un besoin que le joueur vient
        -- de cliquer par erreur sur un objet lie.
        local numero, type_ = arg1, arg2
        if enAttente[numero] == nil then return end
        enAttente[numero] = nil
        ConfirmLootRoll(numero, type_ or BESOIN)
        StaticPopup_Hide("CONFIRM_LOOT_ROLL")
    end
end)

local function Liste()
    local reglages = Reglages()
    local ids = {}
    for id, ok in pairs(reglages.objets) do
        if ok then table.insert(ids, id) end
    end
    table.sort(ids)

    if #ids == 0 then
        Print("aucun objet dans la liste.")
        return
    end
    Print(#ids .. " objet(s) suivis :")
    for _, id in ipairs(ids) do
        local nom = BIJOUX_ZG[id] or (GetItemInfo(id)) or "objet inconnu"
        Print("  " .. id .. " - " .. nom)
    end
end

-- Appelee par le repartiteur de /pbbis.
function PlayerbotsBisRolls_Command(arg)
    local cmd, reste = string.match(arg or "", "^(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")
    local reglages = Reglages()

    if cmd == "" or cmd == "on" or cmd == "off" then
        if cmd == "on" then reglages.actif = true
        elseif cmd == "off" then reglages.actif = false
        else reglages.actif = not reglages.actif end
        Print(reglages.actif
              and ("jets automatiques |cff1eff00actives|r en " .. reglages.mode .. ".")
              or "jets automatiques |cffff2020desactives|r.")

    elseif cmd == "besoin" or cmd == "need" then
        reglages.mode = "besoin"
        Print("mode : besoin (repli sur cupidite si le serveur refuse).")

    elseif cmd == "cupidite" or cmd == "greed" then
        reglages.mode = "cupidite"
        Print("mode : cupidite.")

    elseif cmd == "liste" then
        Liste()

    elseif cmd == "ajoute" then
        local id = tonumber(reste)
        if not id then Print("usage : /pbbis jets ajoute <identifiant>") return end
        reglages.objets[id] = true
        Print("objet " .. id .. " ajoute.")

    elseif cmd == "oublie" then
        local id = tonumber(reste)
        if not id then Print("usage : /pbbis jets oublie <identifiant>") return end
        reglages.objets[id] = nil
        Print("objet " .. id .. " retire.")

    elseif cmd == "defaut" then
        reglages.objets = {}
        for id in pairs(BIJOUX_ZG) do reglages.objets[id] = true end
        Print("liste remise aux neuf bijoux hakkari.")

    else
        Print("/pbbis jets - active ou desactive (actuel : "
              .. (reglages.actif and "actif" or "inactif") .. ")")
        Print("/pbbis jets besoin | cupidite - quoi jeter")
        Print("/pbbis jets liste - les objets suivis")
        Print("/pbbis jets ajoute <id> | oublie <id> | defaut")
    end
end
