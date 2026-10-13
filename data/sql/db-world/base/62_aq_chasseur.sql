-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 3, spe 0,1,2, palier 60.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `entry`     INT UNSIGNED NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`, `entry`) VALUES
( 0, 1, 'Striker''s Diadem', NULL),
( 0, 2, 'Blooddrenched Mask', NULL),
( 0, 3, 'Dragonstalker''s Helm', NULL),
( 0, 3, 'Crown of Destruction', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Barbed Choker', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 3, 'Pendant of Celerity', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Dragonstalker''s Spaulders', NULL),
( 2, 3, 'Giantstalker''s Epaulets', NULL),
( 2, 3, 'Barrage Shoulders', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Cloak of the Unseen Path', NULL),
(14, 3, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Earthweave Cloak', NULL),
(14, 3, 'Puissant Cape', NULL),
(14, 3, 'Cape of the Black Baron', NULL),
( 4, 1, 'Striker''s Hauberk', NULL),
( 4, 2, 'Dragonstalker''s Breastplate', NULL),
( 4, 3, 'Vest of Swift Execution', NULL),
( 4, 3, 'Primal Batskin Jerkin', NULL),
( 4, 3, 'Obsidian Mail Tunic', NULL),
( 8, 1, 'Dragonstalker''s Bracers', NULL),
( 8, 2, 'Wristguards of True Flight', NULL),
( 8, 3, 'Qiraji Execution Bracers', NULL),
( 8, 3, 'Primal Batskin Bracers', NULL),
( 8, 3, 'Giantstalker''s Bracers', NULL),
( 9, 1, 'Vek''lor''s Gloves of Devastation', NULL),
( 9, 2, 'Dragonstalker''s Gauntlets', NULL),
( 9, 3, 'Giantstalker''s Gloves', NULL),
( 9, 3, 'Gloves of the Tormented', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Gloves of Enforcement', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Ossirian''s Binding', NULL),
( 5, 3, 'Dragonstalker''s Belt', NULL),
( 5, 3, 'Marksman''s Girdle', NULL),
( 5, 3, 'Giantstalker''s Belt', NULL),
( 6, 1, 'Dragonstalker''s Legguards', NULL),
( 6, 2, 'Striker''s Leggings', NULL),
( 6, 3, 'Scaled Sand Reaver Leggings', NULL),
( 6, 3, 'Giantstalker''s Leggings', NULL),
( 6, 3, 'Plaguehound Leggings', NULL),
( 7, 1, 'Dragonstalker''s Greaves', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Striker''s Footguards', NULL),
( 7, 3, 'Blooddrenched Footpads', NULL),
( 7, 3, 'Windreaver Greaves', NULL),
( 7, 3, 'Giantstalker''s Boots', NULL),
(10, 1, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 2, 'Band of Accuria', NULL),
(10, 3, 'Ring of the Godslayer', NULL),
(10, 3, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Ring of the Qiraji Fury', NULL),
(12, 1, 'Jom Gabbar', NULL),
(12, 2, 'Drake Fang Talisman', NULL),
(12, 3, 'Renataki''s Charm of Beasts', NULL),
(12, 3, 'Earthstrike', NULL),
(12, 3, 'Badge of the Swarmguard', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(15, 1, 'Silithid Claw', NULL),
(15, 2, 'Blessed Qiraji Pugio', NULL),
(15, 3, 'Warblade of the Hakkari', 19865),
(15, 3, 'Brutality Blade', NULL),
(15, 3, 'Ancient Qiraji Ripper', NULL),
(15, 3, 'Core Hound Tooth', NULL),
(16, 1, 'Fang of the Faceless', NULL),
(16, 2, 'Blessed Qiraji Pugio', NULL),
(16, 3, 'Brutality Blade', NULL),
(16, 3, 'Ancient Qiraji Ripper', NULL),
(16, 3, 'Core Hound Tooth', NULL),
(16, 3, 'Doom''s Edge', NULL),
(17, 1, 'Ashjre''thul, Crossbow of Smiting', NULL),
(17, 2, 'Larvae of the Great Worm', NULL),
(17, 3, 'Huhuran''s Stinger', NULL),
(17, 3, 'Blessed Qiraji Musket', NULL),
(17, 3, 'Rhok''delar, Longbow of the Ancient Keepers', NULL),
(17, 3, 'Dragonbreath Hand Cannon', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 0 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 0, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 1 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 1, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 2 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 2, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` IN (0,1,2) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
