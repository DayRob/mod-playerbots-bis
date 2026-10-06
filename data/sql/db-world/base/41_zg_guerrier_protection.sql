-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 1, spe 2, palier 40.
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
( 0, 1, 'Helm of Endless Rage', NULL),
( 0, 2, 'Lionheart Helm', NULL),
( 0, 3, 'Crown of Destruction', NULL),
( 0, 3, 'Helm of Wrath', NULL),
( 0, 3, 'Helm of Might', NULL),
( 0, 3, 'Mask of the Unforgiven', NULL),
( 1, 1, 'Onyxia Tooth Pendant', NULL),
( 1, 2, 'The Eye of Hakkar', NULL),
( 1, 3, 'Prestor''s Talisman of Connivery', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 1, 3, 'Master Dragonslayer''s Medallion', NULL),
( 1, 3, 'Medallion of Steadfast Might', NULL),
( 2, 1, 'Drake Talon Pauldrons', NULL),
( 2, 2, 'Pauldrons of Wrath', NULL),
( 2, 3, 'Pauldrons of Might', NULL),
( 2, 3, 'Spaulders of Valor', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 3, 'Wyrmhide Spaulders', NULL),
(14, 1, 'Cloak of Firemaw', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Cloak of Draconic Might', NULL),
(14, 3, 'Zulian Tigerhide Cloak', NULL),
(14, 3, 'Cloak of the Shrouded Mists', NULL),
(14, 3, 'Stoneskin Gargoyle Cape', NULL),
( 4, 1, 'Savage Gladiator Chain', NULL),
( 4, 2, 'Breastplate of Heroism', NULL),
( 4, 3, 'Runed Bloodstained Hauberk', NULL),
( 4, 3, 'Malfurion''s Blessed Bulwark', NULL),
( 4, 3, 'Zandalar Vindicator''s Breastplate', NULL),
( 4, 3, 'Breastplate of the Chromatic Flight', NULL),
( 8, 1, 'Zandalar Vindicator''s Armguards', NULL),
( 8, 2, 'Wristguards of True Flight', NULL),
( 8, 3, 'Bracelets of Wrath', NULL),
( 8, 3, 'Bracers of Might', NULL),
( 8, 3, 'Battleborn Armbraces', NULL),
( 9, 1, 'Gauntlets of Might', NULL),
( 9, 2, 'Aged Core Leather Gloves', NULL),
( 9, 3, 'Edgemaster''s Handguards', NULL),
( 9, 3, 'Flameguard Gauntlets', NULL),
( 9, 3, 'Sacrificial Gauntlets', NULL),
( 9, 3, 'Gauntlets of Wrath', NULL),
( 5, 1, 'Onslaught Girdle', NULL),
( 5, 2, 'Zandalar Vindicator''s Belt', NULL),
( 5, 3, 'Therazane''s Link', NULL),
( 5, 3, 'Brigam Girdle', NULL),
( 5, 3, 'Omokk''s Girth Restrainer', NULL),
( 5, 3, 'Waistband of Wrath', NULL),
( 6, 1, 'Legguards of the Fallen Crusader', NULL),
( 6, 2, 'Bloodsoaked Legplates', NULL),
( 6, 3, 'Eldritch Reinforced Legplates', NULL),
( 6, 3, 'Cloudkeeper Legplates', NULL),
( 6, 3, 'Legplates of Wrath', NULL),
( 7, 1, 'Chromatic Boots', NULL),
( 7, 2, 'Boots of Heroism', NULL),
( 7, 3, 'Sabatons of Might', NULL),
( 7, 3, 'Bloodmail Boots', NULL),
( 7, 3, 'Sabatons of Wrath', NULL),
( 7, 3, 'Windreaver Greaves', NULL),
(10, 1, 'Quick Strike Ring', NULL),
(10, 2, 'Band of Accuria', NULL),
(10, 3, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Archimtiros'' Ring of Reckoning', NULL),
(12, 1, 'Diamond Flask', NULL),
(12, 2, 'Drake Fang Talisman', NULL),
(12, 3, 'Hand of Justice', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(12, 3, 'Rune of the Guard Captain', NULL),
(12, 3, 'Onyxia Blood Talisman', NULL),
(16, 1, 'Elementium Reinforced Bulwark', NULL),
(16, 2, 'Aegis of the Blood God', NULL),
(16, 3, 'Drillborer Disk', NULL),
(16, 3, 'Draconian Deflector', NULL),
(16, 3, 'Force Reactive Disk', NULL),
(15, 1, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(15, 2, 'Warblade of the Hakkari', 19865),
(15, 3, 'Maladath, Runed Blade of the Black Flight', NULL),
(15, 3, 'Chromatically Tempered Sword', NULL),
(15, 3, 'Brutality Blade', NULL),
(15, 3, 'Quel''Serrar', NULL),
(17, 1, 'Blastershot Launcher', NULL),
(17, 2, 'Striker''s Mark', NULL),
(17, 3, 'Satyr''s Bow', NULL),
(17, 3, 'Heartstriker', NULL),
(17, 3, 'Dragonbreath Hand Cannon', NULL),
(17, 3, 'Gurubashi Dwarf Destroyer', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 2 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 2, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 1 AND `spec` IN (2) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
