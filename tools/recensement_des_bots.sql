-- Qui est reellement connecte, et a quel niveau.
--
-- A LANCER SERVEUR ALLUME, quelques minutes apres le demarrage. C'est le seul
-- moment ou characters.online veut dire quelque chose.
--
--   Get-Content tools\recensement_des_bots.sql -Raw |
--     & $m -uacore -padmin acore_characters --table --default-character-set=utf8mb4
--
-- ATTENTION : base acore_CHARACTERS.
--
-- POURQUOI
-- --------
-- Un /who ne repond pas a la question. Il plafonne a 50 lignes affichees, il
-- se trie sur la colonne choisie, et il ne montre qu'une faction. Trois
-- raisons de voir "que des niveau 1" dans une population qui n'en est pas
-- faite.
--
-- Ces trois requetes comptent, au lieu de regarder. Elles disent la
-- repartition reelle par niveau, combien de bots de la guilde sont la, et
-- d'ou viennent les connectes - comptes anciens ou comptes neufs.

SET @guilde := 5;   -- Reborn

-- ------------------------------------------------------------------
-- 1. Repartition par niveau de TOUS les connectes.
--
-- Si la population est saine, le gros doit etre au niveau 60. Une majorite
-- au niveau 1 signifie que ce sont les personnages neufs qui occupent les
-- places, et que les anciens n'y arrivent pas.
-- ------------------------------------------------------------------
SELECT '--- 1. connectes par niveau ---' AS '';

SELECT  CASE WHEN c.level = 1  THEN 'niveau 1 (jamais joue)'
             WHEN c.level < 60 THEN 'niveau 2 a 59'
             WHEN c.level = 60 THEN 'niveau 60'
             ELSE                   'au-dessus de 60'
        END                                           AS tranche,
        COUNT(*)                                      AS connectes
FROM    characters c
WHERE   c.online = 1
GROUP BY tranche
ORDER BY MIN(c.level);

-- ------------------------------------------------------------------
-- 2. La guilde.
-- ------------------------------------------------------------------
SELECT '--- 2. la guilde ---' AS '';

SELECT  COUNT(*)                                      AS membres,
        SUM(c.online)                                 AS en_ligne,
        COUNT(*) - SUM(c.online)                      AS hors_ligne
FROM    characters c
JOIN    guild_member gm ON gm.guid = c.guid
WHERE   gm.guildid = @guilde;

-- ------------------------------------------------------------------
-- 3. D'ou viennent les connectes : comptes anciens ou comptes neufs.
--
-- Un compte est dit NEUF quand aucun de ses personnages n'a depasse le
-- niveau 1 - donc jamais joue. Si les connectes en viennent, c'est que les
-- comptes anciens sont ecartes du vivier ou empeches de se connecter.
-- ------------------------------------------------------------------
SELECT '--- 3. origine des connectes ---' AS '';

SELECT  CASE WHEN x.niveau_max <= 1 THEN 'compte neuf (jamais joue)'
             ELSE 'compte ancien' END                 AS origine,
        COUNT(*)                                      AS comptes,
        SUM(x.en_ligne)                               AS personnages_en_ligne
FROM (
    SELECT  c.account, MAX(c.level) AS niveau_max, SUM(c.online) AS en_ligne
    FROM    characters c
    JOIN    acore_auth.account a ON a.id = c.account
    WHERE   a.username LIKE 'RNDBOT%'
    GROUP BY c.account
) x
WHERE   x.en_ligne > 0
GROUP BY origine;
