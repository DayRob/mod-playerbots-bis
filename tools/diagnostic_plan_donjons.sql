-- ---------------------------------------------------------------------------
-- Pourquoi le plan de donjons ne trouve-t-il aucune cible ?
--
-- A lancer sur la base MONDE (acore_world par defaut) :
--     mysql -u acore -p acore_world < tools/diagnostic_plan_donjons.sql
--
-- Le script refait, en SQL pur, exactement ce que le module fait en memoire, et
-- repond a trois questions dans l'ordre ou elles comptent.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;

-- L'index du module, reconstruit a l'identique.
DROP TEMPORARY TABLE IF EXISTS `diag_index`;
CREATE TEMPORARY TABLE `diag_index` (
    `item` INT UNSIGNED NOT NULL,
    `map`  SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`item`, `map`)
) ENGINE=MEMORY;

INSERT IGNORE INTO `diag_index` (`item`, `map`)
SELECT DISTINCT l.`item`, sp.`map`
FROM (
      SELECT clt.`Item` AS `item`, clt.`Entry` AS `entry`
        FROM `creature_loot_template` clt
       WHERE clt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`)
      UNION ALL
      SELECT rlt.`Item`, clt.`Entry`
        FROM `reference_loot_template` rlt
        JOIN `creature_loot_template` clt ON clt.`Reference` = rlt.`Entry`
       WHERE rlt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`)
     ) l
JOIN `creature` sp ON sp.`id1` = l.`entry`
JOIN `instance_template` i ON i.`map` = sp.`map`;

-- ---------------------------------------------------------------------
-- 1 - Les deux branches de la requete rapportent-elles quelque chose ?
--
-- Si "direct" vaut 0 et "par_reference" non, le probleme est la : seul le
-- butin herite d'une table de reference remonte, donc uniquement la pietaille,
-- jamais les boss.
-- ---------------------------------------------------------------------
SELECT 'direct' AS branche, COUNT(*) AS lignes
FROM `creature_loot_template` clt
JOIN `creature` sp ON sp.`id1` = clt.`Entry`
JOIN `instance_template` i ON i.`map` = sp.`map`
WHERE clt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`)
UNION ALL
SELECT 'par_reference', COUNT(*)
FROM `reference_loot_template` rlt
JOIN `creature_loot_template` clt ON clt.`Reference` = rlt.`Entry`
JOIN `creature` sp ON sp.`id1` = clt.`Entry`
JOIN `instance_template` i ON i.`map` = sp.`map`
WHERE rlt.`Item` IN (SELECT DISTINCT `item_id` FROM `playerbots_bis_item`);

-- ---------------------------------------------------------------------
-- 2 - Couverture par palier : combien de pieces de rang 1 sont localisables ?
--
-- C'est la ligne du palier que tes bots visent reellement qui compte. Si
-- "localisables" y est nul ou tres bas, on tient la cause.
-- ---------------------------------------------------------------------
SELECT b.`tier_id`,
       t.`name` AS palier,
       COUNT(DISTINCT b.`item_id`) AS pieces_rang1,
       COUNT(DISTINCT CASE WHEN d.`item` IS NOT NULL THEN b.`item_id` END) AS localisables
FROM `playerbots_bis_item` b
LEFT JOIN `playerbots_bis_tier` t ON t.`tier_id` = b.`tier_id`
LEFT JOIN `diag_index` d ON d.`item` = b.`item_id`
WHERE b.`rank` = 1
GROUP BY b.`tier_id`, t.`name`
ORDER BY b.`tier_id`;

-- ---------------------------------------------------------------------
-- 3 - Trente pieces de rang 1 du pre-raid que le module ne sait pas placer.
--
-- Regarde la colonne "verdict" : si elle dit "tombe d'une creature hors
-- instance", ces creatures existent mais leur carte n'est pas dans
-- instance_template - c'est la que se joue le filtre.
-- ---------------------------------------------------------------------
SELECT it.`name` AS piece,
       CASE
         WHEN EXISTS (SELECT 1 FROM `creature_loot_template` c WHERE c.`Item` = b.`item_id`)
           OR EXISTS (SELECT 1 FROM `reference_loot_template` r
                      JOIN `creature_loot_template` c2 ON c2.`Reference` = r.`Entry`
                      WHERE r.`Item` = b.`item_id`)
           THEN 'tombe d''une creature hors instance'
         WHEN EXISTS (SELECT 1 FROM `npc_vendor` v WHERE v.`item` = b.`item_id`)
           THEN 'vendeur'
         WHEN EXISTS (SELECT 1 FROM `gameobject_loot_template` g WHERE g.`Item` = b.`item_id`)
           THEN 'objet du decor hors instance'
         ELSE 'aucun butin connu (quete, artisanat, ou rien)'
       END AS verdict
FROM `playerbots_bis_item` b
JOIN `item_template` it ON it.`entry` = b.`item_id`
LEFT JOIN `diag_index` d ON d.`item` = b.`item_id`
WHERE b.`rank` = 1 AND b.`tier_id` = 10 AND d.`item` IS NULL
GROUP BY b.`item_id`, it.`name`
LIMIT 30;

DROP TEMPORARY TABLE IF EXISTS `diag_index`;
