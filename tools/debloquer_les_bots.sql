-- Lever les interdictions de connexion posees sur les bots.
--
-- A LANCER SERVEUR ARRETE. Passe par tools\debloquer_les_bots.ps1, qui le
-- verifie et remet aussi les deux reglages fautifs.
--
--   Get-Content tools\debloquer_les_bots.sql -Raw |
--     & $m -uacore -padmin acore_playerbots --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_PLAYERBOTS.
--
-- POURQUOI
-- --------
-- Quand un randombot se deconnecte, le coeur lui pose un delai de carence :
--
--     SetEventValue(bot, "logout", 1,
--                   urand(minRandomBotInWorldTime, maxRandomBotInWorldTime));
--
-- Et tryLoginBot refuse tout bot qui en porte un :
--
--     if (GetEventValue(guid, "add") || GetEventValue(guid, "logout") || ...)
--         return false;
--
-- Cette ligne est INCONDITIONNELLE. Contrairement au "add" voisin, elle ne
-- regarde pas EnablePeriodicOnlineOffline. Min/MaxRandomBotInWorldTime ne sont
-- donc jamais inertes : meme a 0, ils fixent la duree de carence.
--
-- Les porter a 604800 revient a interdire une semaine de connexion a tout bot
-- qui se deconnecte - a l'arret du serveur, c'est-a-dire a tous. Ne restent
-- eligibles que les personnages qui ne se sont JAMAIS connectes : les comptes
-- neufs, niveau 1, dans les zones de depart.
--
-- Effacer ces lignes rend tout le monde eligible immediatement. Elles ne
-- portent aucune donnee de personnage : ni stuff, ni niveau, ni guilde. Le
-- coeur les repose de lui-meme a la prochaine deconnexion, avec la duree que
-- la configuration dira alors.

-- ------------------------------------------------------------------
-- 1. L'ampleur du blocage, et jusqu'a quand il courait.
-- ------------------------------------------------------------------
SELECT '--- 1. avant ---' AS '';

SELECT  COUNT(*)                                      AS bots_interdits,
        MIN(validIn)                                  AS carence_min_s,
        MAX(validIn)                                  AS carence_max_s,
        ROUND(MAX(validIn) / 86400, 1)                AS carence_max_jours,
        FROM_UNIXTIME(MAX(`time` + validIn))          AS libre_au_plus_tard_le
FROM    playerbots_random_bots
WHERE   event = 'logout';

-- ------------------------------------------------------------------
-- 2. La levee.
-- ------------------------------------------------------------------
DELETE FROM playerbots_random_bots WHERE event = 'logout';

-- ------------------------------------------------------------------
-- 3. Controle : plus aucune interdiction, et les bots de la guilde
--    gardent bien leur marque "add" reservee.
-- ------------------------------------------------------------------
SELECT '--- 3. apres ---' AS '';

SELECT  SUM(event = 'logout')                         AS interdictions_restantes,
        SUM(event = 'add')                            AS marques_add,
        SUM(event = 'add' AND gm.guildid IS NOT NULL) AS dont_la_guilde
FROM    playerbots_random_bots p
LEFT JOIN acore_characters.guild_member gm ON gm.guid = p.bot;
