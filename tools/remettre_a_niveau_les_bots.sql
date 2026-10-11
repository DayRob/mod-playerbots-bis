-- Forcer la remise a niveau des bots restes en dessous du plancher.
--
-- A LANCER SERVEUR ARRETE. GetEventValue lit un cache memoire, pas la base :
-- a chaud, effacer ces lignes ne changerait rien jusqu'au prochain demarrage.
--
--   Get-Content tools\remettre_a_niveau_les_bots.sql -Raw |
--     & $m -uacore -padmin acore_playerbots --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_PLAYERBOTS.
--
-- POURQUOI
-- --------
-- Changer Playerbots.RandomBotMinLevel ne touche PAS les bots existants. Le
-- niveau n'est tire qu'a la randomisation :
--
--     void RandomPlayerbotMgr::Randomize(Player* bot) {
--         if (bot->GetLevel() < 3 || ...) RandomizeFirst(bot);
--
--     // dans RandomizeFirst :
--     uint32 minLevel = sPlayerbotAIConfig.randomBotMinLevel;
--     ... level = urand(minLevel, maxLevel);
--
-- et la randomisation suivante d'un bot est programmee entre
-- MinRandomBotRandomizeTime (7200 s, 2 heures) et MaxRandomBotRandomizeTime
-- (1209600 s, QUATORZE JOURS). Un bot tire au niveau 1 sous l'ancien reglage
-- peut donc y rester deux semaines, quel que soit le nouveau plancher.
--
-- Le coeur reprogramme une randomisation des qu'il n'en trouve plus :
--
--     if (!GetEventValue(botId, "randomize"))
--         ScheduleRandomize(bot, randomTime);     // randomTime = quelques secondes
--
-- Effacer la ligne "randomize" d'un bot revient donc a lui dire : refais-toi
-- maintenant. Il sera retire au prochain passage, avec le plancher actuel.
--
-- Rien d'autre n'est touche : ni stuff, ni guilde, ni les marques "add"
-- reservees aux bots de la guilde.

-- En dessous de ce niveau, un bot est considere comme a remettre a niveau.
-- Mets-y ton Playerbots.RandomBotMinLevel.
SET @plancher := 60;

-- ------------------------------------------------------------------
-- 1. Qui est en dessous du plancher, et quand il se serait refait tout seul.
-- ------------------------------------------------------------------
SELECT '--- 1. bots sous le plancher ---' AS '';

SELECT  CASE WHEN c.level = 1 THEN 'niveau 1' ELSE CONCAT('niveau 2 a ', @plancher - 1) END AS tranche,
        COUNT(*)                                                 AS bots,
        SUM(p.id IS NOT NULL)                                    AS avec_randomize_programme,
        FROM_UNIXTIME(MAX(p.`time` + p.validIn))                 AS le_plus_tardif
FROM    acore_characters.characters c
JOIN    acore_auth.account a ON a.id = c.account
LEFT JOIN playerbots_random_bots p ON p.bot = c.guid AND p.event = 'randomize'
WHERE   a.username LIKE 'RNDBOT%'
  AND   c.level < @plancher
GROUP BY tranche;

-- ------------------------------------------------------------------
-- 2. La remise a zero de leur minuterie.
-- ------------------------------------------------------------------
DELETE p FROM playerbots_random_bots p
JOIN   acore_characters.characters c ON c.guid = p.bot
JOIN   acore_auth.account a ON a.id = c.account
WHERE  p.event = 'randomize'
  AND  a.username LIKE 'RNDBOT%'
  AND  c.level < @plancher;

-- ------------------------------------------------------------------
-- 3. Controle.
-- ------------------------------------------------------------------
SELECT '--- 3. apres ---' AS '';

SELECT  (SELECT COUNT(*)
         FROM   acore_characters.characters c
         JOIN   acore_auth.account a ON a.id = c.account
         JOIN   playerbots_random_bots p ON p.bot = c.guid AND p.event = 'randomize'
         WHERE  a.username LIKE 'RNDBOT%' AND c.level < @plancher)   AS minuteries_restantes,
        (SELECT COUNT(*) FROM playerbots_random_bots WHERE event = 'add') AS marques_add_intactes;
