-- Reserver les premieres places aux bots de la guilde.
--
-- A LANCER SERVEUR ARRETE. Le gestionnaire de randombots reecrit ces lignes
-- en permanence ; tant qu'il tourne, ce qu'on ecrit ici ne tient pas.
-- Passe par tools\bots_de_guilde_en_premier.ps1, qui le verifie avant.
--
--   Get-Content tools\bots_de_guilde_en_premier.sql -Raw |
--     & $m -uacore -padmin acore_playerbots --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_PLAYERBOTS, pas acore_characters.
--
-- POURQUOI
-- --------
-- mod-playerbots tire au sort les bots qui se connectent, et c'est ecrit noir
-- sur blanc dans RandomPlayerbotMgr::AddRandomBots :
--
--     // Shuffle for class balance
--     std::shuffle(allCharacters.begin(), allCharacters.end(), rng);
--
-- Aucun reglage ne donne la priorite a une guilde. Mais le tirage ne concerne
-- que les places RESTANTES, car GetBots() remplit d'abord la liste avec les
-- bots qui ont deja un evenement "add" valide en base :
--
--     void RandomPlayerbotMgr::GetBots() {
--         if (!currentBots.empty()) return;       // une seule fois, au demarrage
--         SELECT bot FROM playerbots_random_bots WHERE owner = 0 AND event = 'add'
--         ... if (currentBots.size() >= maxAllowedBotCount) break;
--     }
--
-- D'ou la manoeuvre : retirer la marque "add" a tout le monde, puis la rendre
-- aux seuls bots de la guilde. Au demarrage suivant ils sont les seuls
-- candidats deja inscrits, donc retenus d'office, et le tirage au sort ne fait
-- que completer derriere eux.
--
-- Effet de bord utile : le plafond MaxRandomBots peut redescendre sans risquer
-- de les perdre. Moins de bots, demarrage plus court, guilde intacte.
--
-- Les marques "logout" des memes bots partent aussi : ProcessBot refuse de
-- connecter un bot tant qu'un logout en cours le concerne.
--
-- RIEN N'EST PERDU. Ces lignes sont des evenements de planification, pas des
-- donnees de personnage : ni stuff, ni niveau, ni appartenance a la guilde.
-- Le gestionnaire les reecrit de lui-meme au premier tick.
--
-- UN PERSONNAGE DE JOUEUR N'EST PAS UN BOT. La requete ne retient que les
-- personnages portes par un compte rndbot. Inscrire un perso joueur ici
-- amenerait le serveur a le connecter comme bot - c'est le seul vrai danger
-- de ce script, et c'est pour ca que le filtre est en dur.

SET @guilde := 5;   -- Reborn

-- ------------------------------------------------------------------
-- 1. Qui va etre inscrit. A lire AVANT de laisser faire la suite.
-- ------------------------------------------------------------------
SELECT '--- 1. seront prioritaires ---' AS '';

SELECT  c.name AS nom, c.level AS niveau, a.username AS compte
FROM    acore_characters.characters c
JOIN    acore_characters.guild_member gm ON gm.guid = c.guid
JOIN    acore_auth.account a ON a.id = c.account
WHERE   gm.guildid = @guilde
  AND   a.username LIKE 'RNDBOT%'
ORDER BY c.name;

SELECT '--- 2. ecartes (pas des bots) ---' AS '';

SELECT  c.name AS nom, a.username AS compte,
        'compte joueur - jamais connecte comme bot' AS raison
FROM    acore_characters.characters c
JOIN    acore_characters.guild_member gm ON gm.guid = c.guid
LEFT JOIN acore_auth.account a ON a.id = c.account
WHERE   gm.guildid = @guilde
  AND   (a.username IS NULL OR a.username NOT LIKE 'RNDBOT%');

-- ------------------------------------------------------------------
-- 3. La manoeuvre, en une transaction.
-- ------------------------------------------------------------------
START TRANSACTION;

-- La marque "add" est retiree a tous : sans ca, GetBots() se remplirait avec
-- les anciens avant d'arriver aux notres, et s'arreterait au plafond.
DELETE FROM playerbots_random_bots WHERE owner = 0 AND event = 'add';

-- Les "logout" en cours des bots de la guilde aussi : ils bloqueraient la
-- connexion meme avec un "add" valide.
DELETE p FROM playerbots_random_bots p
JOIN   acore_characters.guild_member gm ON gm.guid = p.bot
JOIN   acore_characters.characters c ON c.guid = p.bot
JOIN   acore_auth.account a ON a.id = c.account
WHERE  gm.guildid = @guilde
  AND  a.username LIKE 'RNDBOT%'
  AND  p.event = 'logout';

-- validIn = 31104000 : la valeur de Playerbots.PermanentlyInWorldTime, celle
-- que le coeur ecrit lui-meme quand EnablePeriodicOnlineOffline vaut 0. On ne
-- choisit pas un chiffre, on reprend le sien.
INSERT INTO playerbots_random_bots (owner, bot, `time`, validIn, event, `value`, `data`)
SELECT  0, c.guid, UNIX_TIMESTAMP(), 31104000, 'add', 1, NULL
FROM    acore_characters.characters c
JOIN    acore_characters.guild_member gm ON gm.guid = c.guid
JOIN    acore_auth.account a ON a.id = c.account
WHERE   gm.guildid = @guilde
  AND   a.username LIKE 'RNDBOT%';

COMMIT;

-- ------------------------------------------------------------------
-- 4. Verification : il ne doit rester QUE les bots de la guilde.
-- ------------------------------------------------------------------
SELECT '--- 4. verification ---' AS '';

SELECT  COUNT(*) AS lignes_add_restantes,
        SUM(CASE WHEN gm.guildid = @guilde THEN 1 ELSE 0 END) AS dont_la_guilde
FROM    playerbots_random_bots p
LEFT JOIN acore_characters.guild_member gm ON gm.guid = p.bot
WHERE   p.owner = 0 AND p.event = 'add';
