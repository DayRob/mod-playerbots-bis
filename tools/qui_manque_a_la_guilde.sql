-- Quels bots de la guilde ne se sont PAS connectes, et pourquoi.
--
--   Get-Content tools\qui_manque_a_la_guilde.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS. Les requetes vont chercher les comptes
-- dans acore_auth au passage, les deux bases vivant sur le meme serveur MySQL.
--
-- POURQUOI
-- --------
-- Un bot de guilde n'est PAS un bot privilegie. mod-playerbots ne connait que
-- deux populations :
--
--   - les RANDOMBOTS, tires au sort dans un vivier de comptes "rndbot", et
--     connectes jusqu'a concurrence de Playerbots.MaxRandomBots ;
--   - les ALTBOTS / bots addclass, qui ne se connectent JAMAIS tout seuls.
--
-- L'appartenance a une guilde n'entre dans aucun de ces deux calculs. Si les
-- bots de la guilde sont des randombots et que le vivier est plus grand que
-- MaxRandomBots, ceux qui ne passent pas la coupe restent hors ligne, et rien
-- ne dit lesquels a l'avance. S'ils sont des bots addclass, ils ne se
-- connecteront jamais d'eux-memes, quel que soit le reglage.
--
-- Les trois requetes repondent, dans l'ordre : QUI manque, de QUEL vivier ils
-- viennent, et si le vivier deborde la limite.

SET @guilde := 5;   -- Reborn

-- ------------------------------------------------------------------
-- 1. QUI manque. La liste nominative des absents.
-- ------------------------------------------------------------------
SELECT  '--- 1. absents ---' AS '';

SELECT  c.name                                   AS nom,
        c.level                                  AS niveau,
        CASE c.class
            WHEN 1 THEN 'Guerrier'  WHEN 2 THEN 'Paladin'   WHEN 3 THEN 'Chasseur'
            WHEN 4 THEN 'Voleur'    WHEN 5 THEN 'Pretre'    WHEN 6 THEN 'DK'
            WHEN 7 THEN 'Chaman'    WHEN 8 THEN 'Mage'      WHEN 9 THEN 'Demoniste'
            WHEN 11 THEN 'Druide'   ELSE CONCAT('classe ', c.class)
        END                                      AS classe,
        a.username                               AS compte,
        FROM_UNIXTIME(c.logout_time)             AS derniere_deconnexion
FROM    characters c
JOIN    guild_member gm ON gm.guid = c.guid
LEFT JOIN acore_auth.account a ON a.id = c.account
WHERE   gm.guildid = @guilde
  AND   c.online = 0
ORDER BY c.level, c.name;

-- ------------------------------------------------------------------
-- 2. De QUEL vivier viennent les bots de la guilde.
--
-- Deux comptes "rndbot*" differents n'ont pas le meme sens : les premiers
-- comptes crees servent aux randombots, les derniers sont reserves a addclass
-- (Playerbots.AddClassAccountPoolSize). Un bot sur un compte addclass ne se
-- connecte jamais seul : c'est une explication suffisante a lui seul.
-- ------------------------------------------------------------------
SELECT  '--- 2. comptes ---' AS '';

SELECT  a.username                               AS compte,
        COUNT(*)                                 AS bots_de_la_guilde,
        SUM(c.online)                            AS en_ligne,
        COUNT(*) - SUM(c.online)                 AS hors_ligne
FROM    characters c
JOIN    guild_member gm ON gm.guid = c.guid
LEFT JOIN acore_auth.account a ON a.id = c.account
WHERE   gm.guildid = @guilde
GROUP BY a.username
ORDER BY hors_ligne DESC, a.username;

-- ------------------------------------------------------------------
-- 3. Le vivier deborde-t-il la limite ?
--
-- Si "personnages_rndbot" depasse nettement MaxRandomBots, la coupe existe et
-- quelqu'un reste forcement dehors. Les bots de la guilde n'ont aucune raison
-- d'etre du bon cote.
-- ------------------------------------------------------------------
SELECT  '--- 3. vivier ---' AS '';

SELECT  COUNT(*)                                 AS personnages_rndbot,
        SUM(c.online)                            AS en_ligne,
        COUNT(DISTINCT c.account)                AS comptes_rndbot
FROM    characters c
JOIN    acore_auth.account a ON a.id = c.account
WHERE   a.username LIKE 'RNDBOT%';
