--[[
  Playerbots BiS - compositions de raid.

  Enregistre la repartition en sous-groupes d'un raid, et la reapplique plus
  tard. Les invitations remplissent les groupes dans l'ordre d'arrivee, donc
  sans ca la composition change a chaque raid.

  Le client sait deplacer un membre (SetRaidSubgroup) et en echanger deux
  (SwapRaidSubgroup), mais rien dans l'interface 3.3.5 ne memorise une
  repartition. C'est tout ce que ce fichier ajoute.

  Un point de mecanique gouverne le reste : le serveur ne renvoie la nouvelle
  liste qu'apres un aller-retour. GetRaidRosterInfo ment donc juste apres un
  deplacement, et enchainer les ordres sur des donnees perimees produit des
  echanges qui se defont entre eux. On fait donc UN mouvement, on attend, on
  relit, on recommence.
]]

local ADDON_NAME = "PlayerbotsBisTooltip"

local MAX_GROUPS = 8
local GROUP_SIZE = 5
local STEP_DELAY = 0.4    -- laisse au serveur le temps de renvoyer la liste
local MAX_STEPS  = 160    -- garde-fou : 40 bots mal places tiennent largement dedans
local INVITES_PAR_TICK = 2     -- le serveur jette les invitations envoyees en rafale
local CALME_AVANT_RANGEMENT = 6  -- ticks sans nouvelle arrivee avant de ranger

local db
local worker

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99BiS|r: " .. msg)
end

--------------------------------------------------------------------------------
-- Lecture du raid
--------------------------------------------------------------------------------

-- index, sous-groupe et effectif par groupe, relus a chaque etape.
local function ReadRaid()
    local members, byName, count = {}, {}, {}
    for g = 1, MAX_GROUPS do count[g] = 0 end

    local n = GetNumRaidMembers()
    for i = 1, n do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name and subgroup then
            local m = { name = name, index = i, group = subgroup }
            table.insert(members, m)
            byName[name] = m
            count[subgroup] = (count[subgroup] or 0) + 1
        end
    end

    return members, byName, count
end

--------------------------------------------------------------------------------
-- Une etape de tri
--------------------------------------------------------------------------------

-- Renvoie true si un mouvement a ete demande, false si la composition est deja
-- celle voulue (ou si plus rien n'est faisable).
local function Step(layout)
    local members, _, count = ReadRaid()

    local misplaced = {}
    for _, m in ipairs(members) do
        local want = layout[m.name]
        if want and want ~= m.group then
            table.insert(misplaced, m)
        end
    end

    if #misplaced == 0 then
        return false
    end

    -- 1. Une place libre dans le groupe vise : un simple deplacement suffit.
    for _, m in ipairs(misplaced) do
        if count[layout[m.name]] < GROUP_SIZE then
            SetRaidSubgroup(m.index, layout[m.name])
            return true
        end
    end

    -- 2. Sinon il faut echanger. L'echange PARFAIT d'abord : deux membres qui
    --    veulent chacun la place de l'autre. Il regle deux cas d'un coup et ne
    --    peut jamais etre defait par une etape suivante.
    for _, a in ipairs(misplaced) do
        local want = layout[a.name]
        for _, b in ipairs(members) do
            if b.group == want and layout[b.name] == a.group then
                SwapRaidSubgroup(a.index, b.index)
                return true
            end
        end
    end

    -- 3. Faute de mieux, echanger avec quelqu'un que le groupe vise ne reclame
    --    pas. Sans cette porte de sortie, un raid plein ou aucun echange
    --    parfait n'existe resterait bloque pour toujours.
    for _, a in ipairs(misplaced) do
        local want = layout[a.name]
        for _, b in ipairs(members) do
            if b.group == want and layout[b.name] ~= want then
                SwapRaidSubgroup(a.index, b.index)
                return true
            end
        end
    end

    -- Les places restantes sont tenues par des membres qui y sont a leur place
    -- et qu'on ne peut donc pas deloger : la demande est contradictoire.
    return false
end

--------------------------------------------------------------------------------
-- Boucle
--------------------------------------------------------------------------------

local function StopWorker(msg)
    if worker then
        worker:SetScript("OnUpdate", nil)
    end
    if msg then Print(msg) end
end

local function StartWorker(layout)
    if not worker then
        worker = CreateFrame("Frame")
    end

    local elapsed, steps = 0, 0

    worker:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed < STEP_DELAY then
            return
        end
        elapsed = 0

        steps = steps + 1
        if steps > MAX_STEPS then
            StopWorker("composition : abandon apres " .. MAX_STEPS
                       .. " mouvements - il reste des places contestees.")
            return
        end

        if not Step(layout) then
            StopWorker("composition appliquee (" .. steps .. " etape(s)).")
        end
    end)
end

--------------------------------------------------------------------------------
-- Commandes
--------------------------------------------------------------------------------

local function Layouts()
    db.compo = db.compo or {}
    return db.compo
end

-- Qui est deja la, groupe normal comme raid. ReadRaid ne lit que le raid, et
-- au moment d'inviter on est encore seul ou a quatre.
local function Presents()
    local vus = {}
    local moi = UnitName("player")
    if moi then vus[moi] = true end

    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local n = GetRaidRosterInfo(i)
            if n then vus[n] = true end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local n = UnitName("party" .. i)
            if n then vus[n] = true end
        end
    end
    return vus
end

local function Save(name)
    if GetNumRaidMembers() == 0 then
        Print("tu n'es pas en raid - rien a enregistrer.")
        return
    end

    local members = ReadRaid()
    local layout, n = {}, 0
    for _, m in ipairs(members) do
        layout[m.name] = m.group
        n = n + 1
    end

    Layouts()[name] = layout
    Print(string.format("composition |cffffd100%s|r enregistree : %d membres.", name, n))
end

local function Apply(name)
    local layout = Layouts()[name]
    if not layout then
        Print("aucune composition nommee |cffffd100" .. name .. "|r.")
        return
    end

    if GetNumRaidMembers() == 0 then
        Print("tu n'es pas en raid.")
        return
    end

    -- Deplacer quelqu'un demande le chef ou un assistant. Sans ce controle, les
    -- ordres partent, le serveur les refuse en silence, et la boucle tourne
    -- jusqu'au garde-fou sans rien dire d'utile.
    if not (IsRaidLeader() or IsRaidOfficer()) then
        Print("il faut etre chef de raid ou assistant pour deplacer les membres.")
        return
    end

    local _, byName = ReadRaid()
    local present, absent = 0, 0
    for botName in pairs(layout) do
        if byName[botName] then present = present + 1 else absent = absent + 1 end
    end

    if present == 0 then
        Print("aucun membre de cette composition n'est dans le raid.")
        return
    end

    Print(string.format("application de |cffffd100%s|r : %d presents%s.",
        name, present, absent > 0 and (", " .. absent .. " absents ignores") or ""))
    StartWorker(layout)
end

local function List()
    local names = {}
    for name in pairs(Layouts()) do table.insert(names, name) end
    table.sort(names)

    if #names == 0 then
        Print("aucune composition enregistree. En raid : /pbbis compo save")
        return
    end

    for _, name in ipairs(names) do
        local n = 0
        for _ in pairs(Layouts()[name]) do n = n + 1 end
        Print("  |cffffd100" .. name .. "|r - " .. n .. " membres")
    end
end

-- Inviter puis ranger, en une commande.
--
-- La composition enregistre deja QUI etait la : chaque membre avec son
-- sous-groupe. Il n'y a donc pas de liste d'invitation a tenir a part, c'est la
-- meme donnee lue dans l'autre sens.
local function Invite(name)
    local layout = Layouts()[name]
    if not layout then
        Print("aucune composition nommee |cffffd100" .. name .. "|r.")
        return
    end

    local presents = Presents()
    local aInviter = {}
    for membre in pairs(layout) do
        if not presents[membre] then table.insert(aInviter, membre) end
    end
    table.sort(aInviter)

    if #aInviter == 0 then
        Apply(name)
        return
    end

    Print(string.format("|cffffd100%s|r : %d invitation(s) a envoyer.", name, #aInviter))

    if not worker then
        worker = CreateFrame("Frame")
    end

    local elapsed, i, calme, dernier, steps = 0, 1, 0, -1, 0

    worker:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed < STEP_DELAY then
            return
        end
        elapsed = 0

        steps = steps + 1
        if steps > MAX_STEPS then
            StopWorker("composition : abandon, le raid ne se remplit pas.")
            return
        end

        -- Au-dela de cinq, une invitation en groupe normal est refusee. On
        -- convertit des que le groupe existe, pas une fois qu'il deborde.
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 then
            ConvertToRaid()
        end

        if i <= #aInviter then
            for _ = 1, INVITES_PAR_TICK do
                if i > #aInviter then break end
                InviteUnit(aInviter[i])
                i = i + 1
            end
            return
        end

        -- Toutes les invitations sont parties. Un bot hors ligne n'en refuse
        -- aucune, il ne repond simplement jamais : on attend que l'effectif
        -- cesse de monter plutot qu'un compte exact, sinon un seul absent
        -- bloquerait la mise en place.
        local n = GetNumRaidMembers()
        if n ~= dernier then
            dernier, calme = n, 0
            return
        end

        calme = calme + 1
        if calme < CALME_AVANT_RANGEMENT then
            return
        end

        StopWorker(nil)
        Apply(name)
    end)
end

-- Appelee par le repartiteur de /pbbis.
function PlayerbotsBisCompo_Command(arg)
    local cmd, name = string.match(arg or "", "^(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")
    if name == "" then name = "defaut" end

    if cmd == "save" then
        Save(name)
    elseif cmd == "apply" or cmd == "load" then
        Apply(name)
    elseif cmd == "invite" then
        Invite(name)
    elseif cmd == "stop" then
        StopWorker("composition : arret demande.")
    elseif cmd == "clear" or cmd == "delete" then
        if Layouts()[name] then
            Layouts()[name] = nil
            Print("composition |cffffd100" .. name .. "|r supprimee.")
        else
            Print("aucune composition nommee |cffffd100" .. name .. "|r.")
        end
    else
        List()
        Print("/pbbis compo save <nom> - enregistre la repartition actuelle")
        Print("/pbbis compo apply <nom> - la reapplique au raid")
        Print("/pbbis compo invite <nom> - invite les absents puis range")
        Print("/pbbis compo clear <nom> - l'oublie")
        Print("(sans nom : |cffffd100defaut|r)")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then
        return
    end
    PlayerbotsBisTooltipDB = PlayerbotsBisTooltipDB or {}
    db = PlayerbotsBisTooltipDB
    db.compo = db.compo or {}
end)
