-- mod-playerbots-bis : palier 20 (Vanilla Phase 1 - Molten Core / Onyxia), sets de simulateur.
--
-- GENERE par tools/convert_wowsims_gear.py - ne pas editer a la main.
--
-- SOURCE : WoWSims Classic, https://github.com/wowsims/classic
--          (licence MIT ; le projet demande ce lien visible).
--
-- Un set de simulateur donne UN objet par emplacement, pas une liste
-- classee : tout sort en rang 1, sans repli. Les anneaux et les bijoux
-- font exception - le second de la paire prend le rang 2, puisque le
-- module apparie lui-meme les deux emplacements.
--
-- Le PvP des sets d'origine est ecarte a la generation. La reputation
-- demande la base monde : rejoue le fichier 17 apres celui-ci.
--
-- Couvert par ce fichier :
--   balance_druid -> classe 11 spe 0, p2.bis.gear.json
--   elemental_shaman -> classe 7 spe 0, phase_2.gear.json
--   enhancement_shaman -> classe 7 spe 1, phase_1.gear.json
--   hunter -> classe 3 spe 0,1,2, p1.bis.gear.json
--   warlock -> classe 9 spe 0,1,2, mc.gear.json
--
-- Laisse aux fichiers ecrits a la main, qui classent des alternatives
-- la ou un set de simulateur n'offre qu'un objet par emplacement :
--   classe 8 spe 0,1,2 (mage)
--   classe 1 spe 0,1 (warrior)
--
-- Set trop partiel pour remplacer l'existant - c'est le set de raid de
-- la classe, pas une liste d'equipement. Laisse tel quel :
--   feral_druid : 11 creneaux seulement (p2.bis.gear.json)
--   shadow_priest : 8 creneaux seulement (p1.bis.gear.json)
--   tank_warrior : 8 creneaux seulement (p1.bis.gear.json)

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 3 AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 7 AND `spec` IN (0, 1);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 9 AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 11 AND `spec` = 0;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;
CREATE TEMPORARY TABLE `bis_seed_wowsims` (
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowsims` (`class`, `spec`, `slot`, `item_id`, `rank`) VALUES
(11, 0, 0, 18727, 1),
(11, 0, 1, 18814, 1),
(11, 0, 2, 18681, 1),
(11, 0, 14, 17078, 1),
(11, 0, 4, 19145, 1),
(11, 0, 8, 10248, 1),
(11, 0, 9, 13253, 1),
(11, 0, 5, 19136, 1),
(11, 0, 6, 19165, 1),
(11, 0, 7, 10247, 1),
(11, 0, 10, 19147, 1),
(11, 0, 12, 13968, 1),
(11, 0, 12, 18820, 2),
(11, 0, 15, 17105, 1),
(11, 0, 16, 19308, 1),
(7, 0, 0, 15684, 1),
(7, 0, 1, 18814, 1),
(7, 0, 2, 18829, 1),
(7, 0, 14, 10267, 1),
(7, 0, 4, 19145, 1),
(7, 0, 8, 19595, 1),
(7, 0, 9, 13253, 1),
(7, 0, 5, 19136, 1),
(7, 0, 6, 16946, 1),
(7, 0, 7, 19131, 1),
(7, 0, 10, 19147, 1),
(7, 0, 12, 18820, 1),
(7, 0, 12, 12930, 2),
(7, 0, 15, 17070, 1),
(7, 0, 16, 19315, 1),
(7, 1, 0, 18817, 1),
(7, 1, 1, 18404, 1),
(7, 1, 2, 12927, 1),
(7, 1, 14, 13340, 1),
(7, 1, 4, 11726, 1),
(7, 1, 8, 18812, 1),
(7, 1, 9, 15063, 1),
(7, 1, 5, 11686, 1),
(7, 1, 6, 15062, 1),
(7, 1, 7, 13210, 1),
(7, 1, 10, 18821, 1),
(7, 1, 10, 17063, 2),
(7, 1, 12, 11815, 1),
(7, 1, 12, 13965, 2),
(7, 1, 15, 17182, 1),
(3, 0, 0, 16846, 1),
(3, 0, 1, 18404, 1),
(3, 0, 2, 16848, 1),
(3, 0, 14, 17102, 1),
(3, 0, 4, 16845, 1),
(3, 0, 8, 16850, 1),
(3, 0, 9, 16852, 1),
(3, 0, 5, 16851, 1),
(3, 0, 6, 16847, 1),
(3, 0, 7, 16849, 1),
(3, 0, 10, 17063, 1),
(3, 0, 10, 18821, 2),
(3, 0, 12, 13965, 1),
(3, 0, 12, 11815, 2),
(3, 0, 15, 18725, 1),
(3, 0, 17, 18713, 1),
(3, 1, 0, 16846, 1),
(3, 1, 1, 18404, 1),
(3, 1, 2, 16848, 1),
(3, 1, 14, 17102, 1),
(3, 1, 4, 16845, 1),
(3, 1, 8, 16850, 1),
(3, 1, 9, 16852, 1),
(3, 1, 5, 16851, 1),
(3, 1, 6, 16847, 1),
(3, 1, 7, 16849, 1),
(3, 1, 10, 17063, 1),
(3, 1, 10, 18821, 2),
(3, 1, 12, 13965, 1),
(3, 1, 12, 11815, 2),
(3, 1, 15, 18725, 1),
(3, 1, 17, 18713, 1),
(3, 2, 0, 16846, 1),
(3, 2, 1, 18404, 1),
(3, 2, 2, 16848, 1),
(3, 2, 14, 17102, 1),
(3, 2, 4, 16845, 1),
(3, 2, 8, 16850, 1),
(3, 2, 9, 16852, 1),
(3, 2, 5, 16851, 1),
(3, 2, 6, 16847, 1),
(3, 2, 7, 16849, 1),
(3, 2, 10, 17063, 1),
(3, 2, 10, 18821, 2),
(3, 2, 12, 13965, 1),
(3, 2, 12, 11815, 2),
(3, 2, 15, 18725, 1),
(3, 2, 17, 18713, 1),
(9, 0, 0, 16929, 1),
(9, 0, 1, 18814, 1),
(9, 0, 2, 14112, 1),
(9, 0, 14, 17078, 1),
(9, 0, 4, 19145, 1),
(9, 0, 8, 16804, 1),
(9, 0, 9, 18407, 1),
(9, 0, 5, 19136, 1),
(9, 0, 6, 16930, 1),
(9, 0, 7, 18735, 1),
(9, 0, 10, 19147, 1),
(9, 0, 12, 18820, 1),
(9, 0, 12, 12930, 2),
(9, 0, 15, 17103, 1),
(9, 0, 16, 10796, 1),
(9, 0, 17, 13396, 1),
(9, 1, 0, 16929, 1),
(9, 1, 1, 18814, 1),
(9, 1, 2, 14112, 1),
(9, 1, 14, 17078, 1),
(9, 1, 4, 19145, 1),
(9, 1, 8, 16804, 1),
(9, 1, 9, 18407, 1),
(9, 1, 5, 19136, 1),
(9, 1, 6, 16930, 1),
(9, 1, 7, 18735, 1),
(9, 1, 10, 19147, 1),
(9, 1, 12, 18820, 1),
(9, 1, 12, 12930, 2),
(9, 1, 15, 17103, 1),
(9, 1, 16, 10796, 1),
(9, 1, 17, 13396, 1),
(9, 2, 0, 16929, 1),
(9, 2, 1, 18814, 1),
(9, 2, 2, 14112, 1),
(9, 2, 14, 17078, 1),
(9, 2, 4, 19145, 1),
(9, 2, 8, 16804, 1),
(9, 2, 9, 18407, 1),
(9, 2, 5, 19136, 1),
(9, 2, 6, 16930, 1),
(9, 2, 7, 18735, 1),
(9, 2, 10, 19147, 1),
(9, 2, 12, 18820, 1),
(9, 2, 12, 12930, 2),
(9, 2, 15, 17103, 1),
(9, 2, 16, 10796, 1),
(9, 2, 17, 13396, 1);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT s.`class`, s.`spec`, s.`slot`, 0, 20, s.`item_id`, s.`rank`,
       CONCAT('Vanilla Phase 1 - Molten Core / Onyxia (wowsims) - ', it.`name`)
FROM `bis_seed_wowsims` s
JOIN `item_template` it ON it.`entry` = s.`item_id`;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - identifiants absents de ta base (aucune ligne = bon).
-- ---------------------------------------------------------------------
SELECT s.`class`, s.`spec`, s.`slot`, s.`item_id` AS id_introuvable
FROM `bis_seed_wowsims` s
LEFT JOIN `item_template` it ON it.`entry` = s.`item_id`
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - creneaux couverts par spe a ce palier.
-- ---------------------------------------------------------------------
SELECT `class`, `spec`, COUNT(DISTINCT `slot`) AS creneaux, COUNT(*) AS lignes
FROM `playerbots_bis_item` WHERE `tier_id` = 20
GROUP BY `class`, `spec` ORDER BY `class`, `spec`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;
