-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 11, spe 10, palier 60.
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
( 0, 1, 'Guise of the Devourer', NULL),
( 0, 2, 'Southwind Helm', NULL),
( 0, 3, 'Genesis Helm', NULL),
( 0, 4, 'Blooddrenched Mask', NULL),
( 0, 5, 'Mask of the Unforgiven', NULL),
( 1, 1, 'Onyxia Tooth Pendant', NULL),
( 1, 2, 'Barbed Choker', NULL),
( 1, 3, 'Pendant of the Qiraji Guardian', NULL),
( 1, 4, 'Prestor''s Talisman of Connivery', NULL),
( 1, 5, 'Mark of C''Thun', NULL),
( 1, 6, 'Master Dragonslayer''s Medallion', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Taut Dragonhide Shoulderpads', NULL),
( 2, 3, 'Genesis Shoulderpads', NULL),
( 2, 4, 'Chitinous Shoulderguards', NULL),
( 2, 5, 'Truestrike Shoulders', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Puissant Cape', NULL),
(14, 4, 'Dragon''s Blood Cape', NULL),
(14, 5, 'Windshear Cape', NULL),
(14, 6, 'Cloak of Firemaw', NULL),
( 4, 1, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 2, 'Vest of Swift Execution', NULL),
( 4, 3, 'Thick Silithid Chestguard', NULL),
( 4, 4, 'Genesis Vest', NULL),
( 4, 5, 'Breastplate of Bloodthirst', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Wristguards of Stability', NULL),
( 8, 3, 'Dragonspur Wraps', NULL),
( 8, 4, 'Scaled Bracers of the Gorger', NULL),
( 8, 5, 'Blackmist Armguards', NULL),
( 9, 1, 'Gloves of the Hidden Temple', NULL),
( 9, 2, 'Gloves of Enforcement', NULL),
( 9, 3, 'Bile-Covered Gauntlets', NULL),
( 9, 4, 'Toughened Silithid Hide Gloves', NULL),
( 9, 5, 'Blooddrenched Grips', NULL),
( 9, 6, 'Shadow Panther Hide Gloves', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Thick Qirajihide Belt', NULL),
( 5, 3, 'Taut Dragonhide Belt', NULL),
( 5, 4, 'Belt of Preserved Heads', NULL),
( 6, 1, 'Genesis Trousers', NULL),
( 6, 2, 'Dark Heart Pants', NULL),
( 6, 3, 'Blooddrenched Leggings', NULL),
( 6, 4, 'Devilsaur Leggings', NULL),
( 6, 5, 'Cadaverous Leggings', NULL),
( 7, 1, 'Boots of the Shadow Flame', NULL),
( 7, 2, 'Hive Tunneler''s Boots', NULL),
( 7, 3, 'Boots of the Vanguard', NULL),
( 7, 4, 'Drudge Boots', NULL),
( 7, 5, 'Blooddrenched Footpads', NULL),
(10, 1, 'Master Dragonslayer''s Ring', NULL),
(10, 2, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 3, 'Ring of the Qiraji Fury', NULL),
(10, 4, 'Band of Accuria', NULL),
(10, 5, 'Ring of Emperor Vek''lor', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Earthstrike', NULL),
(12, 3, 'Badge of the Swarmguard', NULL),
(12, 4, 'Jom Gabbar', NULL),
(12, 5, 'Vanquished Tentacle of C''Thun', NULL),
(12, 6, 'Blackhand''s Breadth', NULL),
(15, 1, 'Manual Crowd Pummeler', NULL),
(15, 2, 'Blessed Qiraji War Hammer', NULL),
(15, 3, 'Hammer of Bestial Fury', NULL),
(15, 4, 'Mace of Unending Life', NULL),
(15, 5, 'Draconic Maul', NULL),
(16, 1, 'Tome of Knowledge', NULL),
(17, 1, 'Idol of Brutality', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 10 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 10, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 11 AND `spec` IN (10) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
