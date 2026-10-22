-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 11, spe 10, palier 70.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.
-- La jointure des noms est restreinte a AllowableClass : quatre objets
-- s'appellent "Atiesh, Greatstaff of the Guardian" et MIN(entry) seul
-- donnait le meme baton a toutes les listes, dont la plupart ne peuvent
-- pas l'equiper. Un nom qui ne resout plus ressort en VERIFICATION 1.

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
( 1, 1, 'Stormrage''s Talisman of Seething', NULL),
( 1, 2, 'Sadist''s Collar', NULL),
( 1, 3, 'Onyxia Tooth Pendant', NULL),
( 1, 4, 'Barbed Choker', NULL),
( 1, 5, 'Pendant of the Qiraji Guardian', NULL),
( 1, 6, 'Prestor''s Talisman of Connivery', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Taut Dragonhide Shoulderpads', NULL),
( 2, 3, 'Genesis Shoulderpads', NULL),
( 2, 4, 'Chitinous Shoulderguards', NULL),
( 2, 5, 'Truestrike Shoulders', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Cloak of the Scourge', NULL),
(14, 4, 'Shroud of Dominion', NULL),
(14, 5, 'Cryptfiend Silk Cloak', NULL),
(14, 6, 'Puissant Cape', NULL),
( 4, 1, 'Ghoul Skin Tunic', NULL),
( 4, 2, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 3, 'Vest of Swift Execution', NULL),
( 4, 4, 'Thick Silithid Chestguard', NULL),
( 4, 5, 'Genesis Vest', NULL),
( 4, 6, 'Breastplate of Bloodthirst', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Wristguards of Stability', NULL),
( 8, 3, 'Polar Bracers', NULL),
( 8, 4, 'Dragonspur Wraps', NULL),
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
( 6, 1, 'Leggings of Apocalypse', NULL),
( 6, 2, 'Dark Heart Pants', NULL),
( 6, 3, 'Genesis Trousers', NULL),
( 6, 4, 'Blooddrenched Leggings', NULL),
( 6, 5, 'Polar Leggings', NULL),
( 7, 1, 'Boots of the Shadow Flame', NULL),
( 7, 2, 'Hive Tunneler''s Boots', NULL),
( 7, 3, 'Boots of Displacement', NULL),
( 7, 4, 'Boots of the Vanguard', NULL),
( 7, 5, 'Drudge Boots', NULL),
(10, 1, 'Signet of the Fallen Defender', NULL),
(10, 2, 'Band of Unnatural Forces', NULL),
(10, 3, 'Master Dragonslayer''s Ring', NULL),
(10, 4, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 5, 'Ring of the Qiraji Fury', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Kiss of the Spider', NULL),
(12, 3, 'Slayer''s Crest', NULL),
(12, 4, 'Earthstrike', NULL),
(12, 5, 'Badge of the Swarmguard', NULL),
(12, 6, 'Jom Gabbar', NULL),
(15, 1, 'Manual Crowd Pummeler', NULL),
(15, 2, 'Atiesh, Greatstaff of the Guardian', NULL),
(15, 3, 'Blessed Qiraji War Hammer', NULL),
(15, 4, 'The End of Dreams', NULL),
(15, 5, 'Hammer of Bestial Fury', NULL),
(15, 6, 'Mace of Unending Life', NULL),
(16, 1, 'Tome of Knowledge', NULL),
(17, 1, 'Idol of Brutality', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 10 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 10, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 1024) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 1024) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` IN (10) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
