--[[---------------------------------------------------------------------------
Sabre Windfury - un bruit de sabre laser a chaque proc de Furie-des-vents.

POURQUOI UN ADDON ET NON UNE WEAKAURA. Une WeakAura s'importe par une chaine
compressee puis encodee ; la produire a la main sans pouvoir l'essayer donne
neuf fois sur dix un "chaine d'import invalide", et l'erreur ne dit pas ou.
Quarante lignes de Lua font exactement la meme chose, se lisent, et se
corrigent sur place. Si tu veux quand meme la WeakAura, le README explique
comment coller ce declencheur dans un evenement personnalise.

CE QU'ON ECOUTE. Un proc de Furie-des-vents n'est pas un sort lance : c'est
une ATTAQUE SUPPLEMENTAIRE accordee par l'enchantement d'arme. Dans le journal
de combat elle apparait comme SPELL_EXTRA_ATTACKS, et c'est le seul evenement
qui marque le proc lui-meme - les degats qui suivent sont deux lignes a part,
qui feraient sonner deux fois.

LE NOM PLUTOT QUE L'IDENTIFIANT. Furie-des-vents a sept rangs, et l'attaque
qu'elle accorde en a plusieurs aussi. Les comparer un par un obligerait a
tenir une liste qu'un serveur peut modifier ; le nom, lui, ne bouge pas - et
il est traduit par le client, donc la comparaison se fait sur le nom LOCAL.
-----------------------------------------------------------------------------]]

local CHEMIN_DEFAUT = "Interface\\AddOns\\SabreWindfury\\sabre.ogg"

-- Deux procs peuvent tomber a quelques centiemes l'un de l'autre. Sans ce
-- verrou, les deux sons se chevauchent et ne font plus qu'un grognement.
local DELAI_MINIMUM = 0.35

local dernier = 0

local function Reglages()
    if type(SabreWindfuryDB) ~= "table" then SabreWindfuryDB = {} end
    if SabreWindfuryDB.actif == nil then SabreWindfuryDB.actif = true end
    if not SabreWindfuryDB.chemin then SabreWindfuryDB.chemin = CHEMIN_DEFAUT end
    return SabreWindfuryDB
end

-- Le nom de l'attaque, tel que le client le dit. GetSpellInfo traduit, donc
-- "Windfury Attack" devient "Attaque de Furie-des-vents" sur un client
-- francais et la comparaison tient sans table de traduction.
--
-- 25504 est l'attaque supplementaire de Furie-des-vents en 3.3.5. Si le sort
-- est absent de ce serveur, on retombe sur un filtre par motif : tout nom qui
-- contient "windfury" ou "furie-des-vents", sans tenir compte de la casse.
local NOM_ATTAQUE = GetSpellInfo(25504)

local function EstUnProc(nomDuSort)
    if not nomDuSort then return false end
    if NOM_ATTAQUE and nomDuSort == NOM_ATTAQUE then return true end

    local bas = string.lower(nomDuSort)
    return string.find(bas, "windfury", 1, true) ~= nil
        or string.find(bas, "furie%-des%-vents") ~= nil
end

local function Jouer(chemin)
    -- PlaySoundFile accepte un canal a partir de Cataclysm seulement. Sur un
    -- client 3.3.5 l'argument est ignore au mieux, et leve au pire : le pcall
    -- evite qu'un son rate fasse une erreur Lua en plein combat.
    local ok = pcall(PlaySoundFile, chemin)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Sabre|r : fichier introuvable ou illisible - " .. chemin)
    end
    return ok
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Reglages()
        return
    end

    local r = Reglages()
    if not r.actif then return end

    -- 3.3.5 : timestamp, sous-evenement, source(GUID, nom, drapeaux),
    -- cible(GUID, nom, drapeaux), puis les arguments du sous-evenement. Les
    -- drapeaux de raid n'existent qu'a partir de Cataclysm, d'ou ces positions.
    local _, sousEvenement, sourceGUID = ...
    if sousEvenement ~= "SPELL_EXTRA_ATTACKS" then return end

    -- MOI SEULEMENT. Sans ce test, un chaman du raid ferait sonner mon casque
    -- a chacun de ses procs, et en Naxxramas ce serait continu.
    if sourceGUID ~= UnitGUID("player") then return end

    local nomDuSort = select(10, ...)
    if not EstUnProc(nomDuSort) then return end

    local maintenant = GetTime()
    if maintenant - dernier < DELAI_MINIMUM then return end
    dernier = maintenant

    Jouer(r.chemin)
end)

SLASH_SABREWINDFURY1 = "/sabre"
SlashCmdList["SABREWINDFURY"] = function(arg)
    local r = Reglages()
    arg = string.lower(string.gsub(arg or "", "^%s+", ""))

    if arg == "test" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Sabre|r : essai de " .. r.chemin)
        Jouer(r.chemin)
        return
    end

    if arg == "on" or arg == "off" then
        r.actif = (arg == "on")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Sabre|r : " .. (r.actif and "actif" or "eteint"))
        return
    end

    if string.sub(arg, 1, 7) == "chemin " then
        r.chemin = string.sub(arg, 8)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Sabre|r : chemin -> " .. r.chemin)
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Sabre Windfury|r")
    DEFAULT_CHAT_FRAME:AddMessage("  /sabre test            - joue le son maintenant")
    DEFAULT_CHAT_FRAME:AddMessage("  /sabre on | off        - allume ou eteint")
    DEFAULT_CHAT_FRAME:AddMessage("  /sabre chemin <chemin> - change le fichier")
    DEFAULT_CHAT_FRAME:AddMessage("  etat : " .. (r.actif and "actif" or "eteint") .. ", " .. r.chemin)
end
