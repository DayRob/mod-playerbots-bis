-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 11, spe 1, palier 60.
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
( 0, 1, 'Wolfshead Helm', NULL),
( 0, 2, 'Southwind Helm', NULL),
( 0, 3, 'Blooddrenched Mask', NULL),
( 0, 3, 'Genesis Helm', NULL),
( 0, 3, 'Guise of the Devourer', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Fury of the Forgotten Swarm', NULL),
( 1, 3, 'Pendant of Celerity', NULL),
( 1, 3, 'Barbed Choker', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Chitinous Shoulderguards', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 3, 'Genesis Shoulderpads', NULL),
( 2, 3, 'Dark Warder''s Pauldrons', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Cloak of Draconic Might', NULL),
(14, 3, 'Earthweave Cloak', NULL),
(14, 3, 'Zulian Tigerhide Cloak', NULL),
(14, 3, 'Puissant Cape', NULL),
( 4, 1, 'Vest of Swift Execution', NULL),
( 4, 2, 'Primal Batskin Jerkin', NULL),
( 4, 3, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 3, 'Thick Silithid Chestguard', NULL),
( 4, 3, 'Genesis Vest', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Primal Batskin Bracers', NULL),
( 8, 3, 'Scaled Bracers of the Gorger', NULL),
( 8, 3, 'Wristguards of Stability', NULL),
( 8, 3, 'Deepfury Bracers', NULL),
( 9, 1, 'Gloves of Enforcement', NULL),
( 9, 2, 'Gloves of the Hidden Temple', NULL),
( 9, 3, 'Primal Batskin Gloves', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Bile-Covered Gauntlets', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Cloudrunner Girdle', NULL),
( 5, 3, 'Thick Qirajihide Belt', NULL),
( 6, 1, 'Genesis Trousers', NULL),
( 6, 2, 'Plaguehound Leggings', NULL),
( 6, 3, 'Shadowcraft Pants', NULL),
( 6, 3, 'Blooddrenched Leggings', NULL),
( 6, 3, 'Dark Heart Pants', NULL),
( 7, 1, 'Boots of the Vanguard', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Blooddrenched Footpads', NULL),
( 7, 3, 'Drudge Boots', NULL),
( 7, 3, 'Hive Tunneler''s Boots', NULL),
( 7, 3, 'Swiftwalker Boots', NULL),
(10, 1, 'Band of Accuria', NULL),
(10, 2, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Ring of the Godslayer', NULL),
(10, 3, 'Band of Earthen Might', NULL),
(10, 3, 'Tarnished Elven Ring', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Jom Gabbar', NULL),
(12, 3, 'Vanquished Tentacle of C''Thun', NULL),
(12, 3, 'Badge of the Swarmguard', NULL),
(12, 3, 'Earthstrike', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(15, 1, 'Manual Crowd Pummeler', NULL),
(15, 2, 'Blessed Qiraji War Hammer', NULL),
(15, 3, 'Hammer of Bestial Fury', NULL),
(15, 3, 'Mace of Unending Life', NULL),
(15, 3, 'Bonecrusher', NULL),
(16, 1, 'Tome of Knowledge', NULL),
(17, 1, 'Idol of Ferocity', NULL);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 1, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 11 AND `spec` IN (1) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
