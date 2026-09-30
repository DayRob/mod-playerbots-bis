-- mod-playerbots-bis : palier 30 (Vanilla Phase 2 - Blackwing Lair), sets de simulateur.
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
--   balance_druid -> classe 11 spe 0, p3.bis.gear.json
--   elemental_shaman -> classe 7 spe 0, phase_3.gear.json
--   enhancement_shaman -> classe 7 spe 1, phase_3.gear.json
--   warrior -> classe 1 spe 0,1, phase_3.gear.json
--
-- Set trop partiel pour remplacer l'existant - c'est le set de raid de
-- la classe, pas une liste d'equipement. Laisse tel quel :
--   feral_druid : 9 creneaux seulement (p3.bis.gear.json)
--
-- Sans set a ce palier chez WoWSims (donc inchange ici) :
--   hunter
--   mage
--   shadow_priest
--   tank_warrior
--   warlock

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 30 AND `class` = 1 AND `spec` IN (0, 1);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 30 AND `class` = 7 AND `spec` IN (0, 1);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 30 AND `class` = 11 AND `spec` = 0;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;
CREATE TEMPORARY TABLE `bis_seed_wowsims` (
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowsims` (`class`, `spec`, `slot`, `item_id`, `rank`) VALUES
(11, 0, 0, 19375, 1),
(11, 0, 1, 18814, 1),
(11, 0, 2, 19370, 1),
(11, 0, 14, 22731, 1),
(11, 0, 4, 19145, 1),
(11, 0, 8, 19374, 1),
(11, 0, 9, 13253, 1),
(11, 0, 5, 19136, 1),
(11, 0, 6, 19683, 1),
(11, 0, 7, 19684, 1),
(11, 0, 10, 19147, 1),
(11, 0, 10, 19403, 2),
(11, 0, 12, 19379, 1),
(11, 0, 12, 18820, 2),
(11, 0, 16, 19308, 1),
(7, 0, 0, 19375, 1),
(7, 0, 1, 18814, 1),
(7, 0, 2, 18829, 1),
(7, 0, 14, 19378, 1),
(7, 0, 4, 19145, 1),
(7, 0, 8, 19374, 1),
(7, 0, 9, 13253, 1),
(7, 0, 5, 19400, 1),
(7, 0, 6, 16946, 1),
(7, 0, 7, 19131, 1),
(7, 0, 10, 19403, 1),
(7, 0, 10, 19147, 2),
(7, 0, 12, 19344, 1),
(7, 0, 12, 19379, 2),
(7, 0, 15, 19360, 1),
(7, 0, 16, 22329, 1),
(7, 1, 0, 18817, 1),
(7, 1, 1, 19377, 1),
(7, 1, 14, 19436, 1),
(7, 1, 4, 11726, 1),
(7, 1, 8, 19587, 1),
(7, 1, 9, 19157, 1),
(7, 1, 5, 19393, 1),
(7, 1, 6, 22750, 1),
(7, 1, 7, 19381, 1),
(7, 1, 10, 18821, 1),
(7, 1, 10, 19384, 2),
(7, 1, 12, 19406, 1),
(7, 1, 12, 11815, 2),
(7, 1, 15, 17182, 1),
(1, 0, 0, 12640, 1),
(1, 0, 1, 18404, 1),
(1, 0, 14, 19436, 1),
(1, 0, 4, 11726, 1),
(1, 0, 8, 19578, 1),
(1, 0, 9, 14551, 1),
(1, 0, 5, 19137, 1),
(1, 0, 7, 19387, 1),
(1, 0, 10, 19384, 1),
(1, 0, 10, 18821, 2),
(1, 0, 12, 19406, 1),
(1, 0, 12, 20130, 2),
(1, 0, 15, 17112, 1),
(1, 0, 16, 19352, 1),
(1, 0, 17, 17069, 1),
(1, 1, 0, 12640, 1),
(1, 1, 1, 18404, 1),
(1, 1, 14, 19436, 1),
(1, 1, 4, 11726, 1),
(1, 1, 8, 19578, 1),
(1, 1, 9, 14551, 1),
(1, 1, 5, 19137, 1),
(1, 1, 7, 19387, 1),
(1, 1, 10, 19384, 1),
(1, 1, 10, 18821, 2),
(1, 1, 12, 19406, 1),
(1, 1, 12, 20130, 2),
(1, 1, 15, 17112, 1),
(1, 1, 16, 19352, 1),
(1, 1, 17, 17069, 1);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT s.`class`, s.`spec`, s.`slot`, 0, 30, s.`item_id`, s.`rank`,
       CONCAT('Vanilla Phase 2 - Blackwing Lair (wowsims) - ', it.`name`)
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
FROM `playerbots_bis_item` WHERE `tier_id` = 30
GROUP BY `class`, `spec` ORDER BY `class`, `spec`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowsims`;
