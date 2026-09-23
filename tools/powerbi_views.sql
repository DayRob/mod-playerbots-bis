-- Vues de suivi des bots, destinees a Power BI.
--
-- A executer UNE FOIS sur acore_world. Les vues traversent les trois bases
-- (acore_world, acore_characters, acore_auth, acore_playerbots), donc le compte
-- utilise par Power BI doit avoir le SELECT sur les quatre.
--
--   mysql -u acore -p acore_world < tools/powerbi_views.sql
--
-- Une vue ne stocke rien : elle rejoue sa requete a chaque lecture, donc les
-- chiffres suivent le serveur sans aucune synchronisation a gerer.
--
-- LIMITE CONNUE : la spe d'un bot n'existe nulle part en base. Elle est calculee
-- en memoire depuis les talents. Les vues raisonnent donc par CLASSE, et
-- exposent la colonne spec des tables BiS pour que tu filtres toi-meme dans
-- Power BI. Pour un rattachement exact, il faudrait que le module ecrive un
-- instantane - voir le README.

-- ---------------------------------------------------------------------------
-- 1. L'effectif : une ligne par personnage bot.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_bot_roster AS
SELECT
    c.guid,
    c.name                                             AS bot,
    c.class,
    c.race,
    c.level,
    CASE WHEN c.race IN (1, 3, 4, 7, 11) THEN 'Alliance' ELSE 'Horde' END AS faction,
    ROUND(c.money / 10000, 2)                          AS po,
    ROUND(c.totaltime / 3600, 1)                       AS heures_jouees,
    c.online,
    a.username                                         AS compte,
    CASE pat.account_type WHEN 1 THEN 'RNDbot' WHEN 2 THEN 'AddClass' ELSE 'non assigne' END AS type_compte,
    g.name                                             AS guilde
FROM acore_characters.characters c
JOIN acore_auth.account a               ON a.id = c.account
LEFT JOIN acore_playerbots.playerbots_account_type pat ON pat.account_id = c.account
LEFT JOIN acore_characters.guild_member gm ON gm.guid = c.guid
LEFT JOIN acore_characters.guild g         ON g.guildid = gm.guildid
WHERE a.username LIKE 'RNDBOT%';

-- ---------------------------------------------------------------------------
-- 2. L'equipement porte, emplacement par emplacement, confronte aux listes BiS.
--
--    rang_bis vaut NULL quand la piece portee n'est dans aucune liste de sa
--    classe : c'est exactement ce que le module appelle une priorite nulle.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_bot_gear AS
SELECT
    c.name          AS bot,
    c.class,
    c.level,
    ci.slot         AS emplacement,
    t.entry         AS item_id,
    t.name          AS objet,
    t.Quality       AS qualite,
    t.ItemLevel     AS ilvl,
    MIN(b.`rank`)   AS rang_bis,
    MAX(b.tier_id)  AS palier_max
FROM acore_characters.characters c
JOIN acore_auth.account a                  ON a.id = c.account
JOIN acore_characters.character_inventory ci ON ci.guid = c.guid AND ci.bag = 0 AND ci.slot <= 18
JOIN acore_characters.item_instance ii     ON ii.guid = ci.item
JOIN item_template t                       ON t.entry = ii.itemEntry
LEFT JOIN playerbots_bis_item b            ON b.item_id = t.entry
                                          AND b.class   = c.class
                                          AND b.slot    = ci.slot
WHERE a.username LIKE 'RNDBOT%'
GROUP BY c.name, c.class, c.level, ci.slot, t.entry, t.name, t.Quality, t.ItemLevel;

-- ---------------------------------------------------------------------------
-- 3. Le taux de couverture BiS, une ligne par bot.
--
--    Le denominateur est le nombre d'emplacements equipes, pas le nombre
--    d'emplacements existants : un bot sans arme de jet n'est pas penalise.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_bot_bis_coverage AS
SELECT
    bot,
    class,
    level,
    COUNT(*)                                              AS emplacements_equipes,
    SUM(CASE WHEN rang_bis = 1 THEN 1 ELSE 0 END)         AS rang_1,
    SUM(CASE WHEN rang_bis = 2 THEN 1 ELSE 0 END)         AS rang_2,
    SUM(CASE WHEN rang_bis = 3 THEN 1 ELSE 0 END)         AS rang_3,
    SUM(CASE WHEN rang_bis IS NULL THEN 1 ELSE 0 END)     AS hors_liste,
    ROUND(100 * SUM(CASE WHEN rang_bis IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_dans_liste,
    ROUND(100 * SUM(CASE WHEN rang_bis = 1 THEN 1 ELSE 0 END) / COUNT(*), 1)         AS pct_rang_1
FROM vw_bot_gear
GROUP BY bot, class, level;

-- ---------------------------------------------------------------------------
-- 4. Ce qui manque : les pieces de rang 1 qu'un bot ne porte pas encore.
--
--    Une ligne par bot, spe et emplacement. Filtre sur la spe dans Power BI
--    pour ne garder que celle qui t'interesse.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_bot_bis_missing AS
SELECT
    c.name      AS bot,
    c.class,
    c.level,
    b.spec,
    b.tier_id   AS palier,
    b.slot      AS emplacement,
    t.name      AS objet_vise,
    t.entry     AS item_id,
    t.RequiredLevel AS niveau_requis
FROM acore_characters.characters c
JOIN acore_auth.account a  ON a.id = c.account
JOIN playerbots_bis_item b ON b.class = c.class AND b.`rank` = 1
JOIN item_template t       ON t.entry = b.item_id
WHERE a.username LIKE 'RNDBOT%'
  AND NOT EXISTS (
        SELECT 1
        FROM acore_characters.character_inventory ci2
        JOIN acore_characters.item_instance ii2 ON ii2.guid = ci2.item
        WHERE ci2.guid = c.guid AND ii2.itemEntry = b.item_id
  );

-- ---------------------------------------------------------------------------
-- 5. La repartition, pour les graphiques d'ensemble.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_bot_distribution AS
SELECT
    class,
    faction,
    level,
    COUNT(*)      AS effectif,
    SUM(online)   AS connectes,
    ROUND(AVG(po), 1) AS po_moyen
FROM vw_bot_roster
GROUP BY class, faction, level;
