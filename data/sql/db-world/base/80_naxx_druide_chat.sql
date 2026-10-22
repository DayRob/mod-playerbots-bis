-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 11, spe 1, palier 70.
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
( 0, 4, 'Genesis Helm', NULL),
( 0, 5, 'Guise of the Devourer', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Chitinous Shoulderguards', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 4, 'Genesis Shoulderpads', NULL),
( 2, 5, 'Dark Warder''s Pauldrons', NULL),
(14, 1, 'Cloak of Concentrated Hatred', NULL),
(14, 2, 'Cloak of the Fallen God', NULL),
(14, 3, 'Cloak of Draconic Might', NULL),
(14, 4, 'Earthweave Cloak', NULL),
(14, 5, 'Shroud of Dominion', NULL),
(14, 6, 'Zulian Tigerhide Cloak', NULL),
( 4, 1, 'Vest of Swift Execution', NULL),
( 4, 2, 'Ghoul Skin Tunic', NULL),
( 4, 3, 'Primal Batskin Jerkin', NULL),
( 4, 4, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 5, 'Thick Silithid Chestguard', NULL),
( 4, 6, 'Genesis Vest', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Primal Batskin Bracers', NULL),
( 8, 3, 'Scaled Bracers of the Gorger', NULL),
( 8, 4, 'Wristguards of Stability', NULL),
( 8, 5, 'Deepfury Bracers', NULL),
( 9, 1, 'Gloves of Enforcement', NULL),
( 9, 2, 'Gloves of the Hidden Temple', NULL),
( 9, 3, 'Primal Batskin Gloves', NULL),
( 9, 4, 'Doomhide Gauntlets', NULL),
( 9, 5, 'Bile-Covered Gauntlets', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Cloudrunner Girdle', NULL),
( 5, 4, 'Thick Qirajihide Belt', NULL),
( 6, 1, 'Leggings of Apocalypse', NULL),
( 6, 2, 'Plaguehound Leggings', NULL),
( 6, 3, 'Genesis Trousers', NULL),
( 6, 4, 'Shadowcraft Pants', NULL),
( 6, 5, 'Blooddrenched Leggings', NULL),
( 7, 1, 'Boots of the Vanguard', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Blooddrenched Footpads', NULL),
( 7, 4, 'Boots of Displacement', NULL),
( 7, 5, 'Drudge Boots', NULL),
( 7, 6, 'Hive Tunneler''s Boots', NULL),
(10, 1, 'Band of Accuria', NULL),
(10, 2, 'Band of Unnatural Forces', NULL),
(10, 3, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 4, 'Band of Reanimation', NULL),
(10, 5, 'Circle of Applied Force', NULL),
(10, 6, 'Ring of the Godslayer', NULL),
(12, 1, 'Kiss of the Spider', NULL),
(12, 2, 'Mark of the Champion', 23206),
(12, 3, 'Drake Fang Talisman', NULL),
(12, 4, 'Jom Gabbar', NULL),
(12, 5, 'Vanquished Tentacle of C''Thun', NULL),
(12, 6, 'Badge of the Swarmguard', NULL),
(15, 1, 'Manual Crowd Pummeler', NULL),
(15, 2, 'Atiesh, Greatstaff of the Guardian', NULL),
(15, 3, 'Blessed Qiraji War Hammer', NULL),
(15, 4, 'The End of Dreams', NULL),
(15, 5, 'Hammer of Bestial Fury', NULL),
(15, 6, 'Mace of Unending Life', NULL),
(16, 1, 'Tome of Knowledge', NULL),
(17, 1, 'Idol of Ferocity', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 1 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 11 AND `spec` IN (1) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
