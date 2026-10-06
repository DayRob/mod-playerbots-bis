-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 11, spe 10, palier 40.
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
( 0, 1, 'Blooddrenched Mask', NULL),
( 0, 2, 'Mask of the Unforgiven', NULL),
( 0, 3, 'Circlet of Restless Dreams', NULL),
( 0, 3, 'Eye of Rend', NULL),
( 1, 1, 'Onyxia Tooth Pendant', NULL),
( 1, 2, 'Prestor''s Talisman of Connivery', NULL),
( 1, 3, 'Master Dragonslayer''s Medallion', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 3, 'Eskhandar''s Collar', NULL),
( 1, 3, 'Beads of Ogre Might', NULL),
( 2, 1, 'Taut Dragonhide Shoulderpads', NULL),
( 2, 2, 'Truestrike Shoulders', NULL),
( 2, 3, 'Fireguard Shoulders', NULL),
( 2, 3, 'Flamescarred Shoulders', NULL),
(14, 1, 'Dragon''s Blood Cape', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Cloak of Firemaw', NULL),
(14, 3, 'Eskhandar''s Pelt', NULL),
(14, 3, 'Phantasmal Cloak', NULL),
(14, 3, 'Zulian Tigerhide Cloak', NULL),
( 4, 1, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 2, 'Breastplate of Bloodthirst', NULL),
( 4, 3, 'Tombstone Breastplate', NULL),
( 4, 3, 'Interlaced Shadow Jerkin', NULL),
( 4, 3, 'Cadaverous Armor', NULL),
( 8, 1, 'Wristguards of Stability', NULL),
( 8, 2, 'Dragonspur Wraps', NULL),
( 8, 3, 'Blackmist Armguards', NULL),
( 8, 3, 'Bracers of the Eclipse', NULL),
( 9, 1, 'Devilsaur Gauntlets', NULL),
( 9, 2, 'Blooddrenched Grips', NULL),
( 9, 3, 'Shadow Panther Hide Gloves', NULL),
( 9, 3, 'Aged Core Leather Gloves', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Gargoyle Slashers', NULL),
( 5, 1, 'Taut Dragonhide Belt', NULL),
( 5, 2, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Molten Belt', NULL),
( 5, 3, 'Cloudrunner Girdle', NULL),
( 5, 3, 'Mugger''s Belt', NULL),
( 6, 1, 'Devilsaur Leggings', NULL),
( 6, 2, 'Dark Heart Pants', NULL),
( 6, 3, 'Blooddrenched Leggings', NULL),
( 6, 3, 'Cadaverous Leggings', NULL),
( 7, 1, 'Boots of the Shadow Flame', NULL),
( 7, 2, 'Blooddrenched Footpads', NULL),
( 7, 3, 'Pads of the Dread Wolf', NULL),
( 7, 3, 'Cadaverous Walkers', NULL),
(10, 1, 'Quick Strike Ring', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Band of Accuria', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Heavy Dark Iron Ring', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Blackhand''s Breadth', NULL),
(12, 3, 'Mark of the Chosen', NULL),
(12, 3, 'Mark of Tyranny', NULL),
(12, 3, 'Rune of the Guard Captain', NULL),
(12, 3, 'Smoking Heart of the Mountain', NULL),
(15, 1, 'Manual Crowd Pummeler', NULL),
(15, 2, 'Hammer of Bestial Fury', NULL),
(15, 3, 'Draconic Maul', NULL),
(15, 3, 'Herald of Woe', NULL),
(15, 3, 'Warden Staff', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 10 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 10, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 11 AND `spec` IN (10) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
