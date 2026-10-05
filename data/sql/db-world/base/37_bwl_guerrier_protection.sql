-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 1, spe 2, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Helm of Endless Rage'),
( 0, 2, 'Lionheart Helm'),
( 0, 3, 'Crown of Destruction'),
( 0, 3, 'Helm of Wrath'),
( 0, 3, 'Helm of Might'),
( 0, 3, 'Mask of the Unforgiven'),
( 1, 1, 'Onyxia Tooth Pendant'),
( 1, 2, 'Prestor''s Talisman of Connivery'),
( 1, 3, 'Mark of Fordring'),
( 1, 3, 'Master Dragonslayer''s Medallion'),
( 1, 3, 'Medallion of Steadfast Might'),
( 1, 3, 'Eskhandar''s Collar'),
( 2, 1, 'Drake Talon Pauldrons'),
( 2, 2, 'Pauldrons of Wrath'),
( 2, 3, 'Pauldrons of Might'),
( 2, 3, 'Spaulders of Valor'),
( 2, 3, 'Truestrike Shoulders'),
( 2, 3, 'Wyrmhide Spaulders'),
(14, 1, 'Cloak of Firemaw'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of Draconic Might'),
(14, 3, 'Cloak of the Shrouded Mists'),
(14, 3, 'Stoneskin Gargoyle Cape'),
(14, 3, 'Dragon''s Blood Cape'),
( 4, 1, 'Savage Gladiator Chain'),
( 4, 2, 'Malfurion''s Blessed Bulwark'),
( 4, 3, 'Breastplate of the Chromatic Flight'),
( 4, 3, 'Breastplate of Might'),
( 4, 3, 'Cadaverous Armor'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 8, 1, 'Wristguards of True Flight'),
( 8, 2, 'Bracelets of Wrath'),
( 8, 3, 'Bracers of Might'),
( 8, 3, 'Battleborn Armbraces'),
( 8, 3, 'Wristguards of Stability'),
( 9, 1, 'Gauntlets of Might'),
( 9, 2, 'Aged Core Leather Gloves'),
( 9, 3, 'Edgemaster''s Handguards'),
( 9, 3, 'Flameguard Gauntlets'),
( 9, 3, 'Gauntlets of Wrath'),
( 9, 3, 'Voone''s Vice Grips'),
( 5, 1, 'Onslaught Girdle'),
( 5, 2, 'Therazane''s Link'),
( 5, 3, 'Brigam Girdle'),
( 5, 3, 'Omokk''s Girth Restrainer'),
( 5, 3, 'Waistband of Wrath'),
( 5, 3, 'Belt of Might'),
( 6, 1, 'Legguards of the Fallen Crusader'),
( 6, 2, 'Eldritch Reinforced Legplates'),
( 6, 3, 'Cloudkeeper Legplates'),
( 6, 3, 'Legplates of Wrath'),
( 6, 3, 'Legplates of Might'),
( 7, 1, 'Chromatic Boots'),
( 7, 2, 'Sabatons of Might'),
( 7, 3, 'Bloodmail Boots'),
( 7, 3, 'Sabatons of Wrath'),
( 7, 3, 'Windreaver Greaves'),
( 7, 3, 'Battlechaser''s Greaves'),
(10, 1, 'Quick Strike Ring'),
(10, 2, 'Band of Accuria'),
(10, 3, 'Master Dragonslayer''s Ring'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Archimtiros'' Ring of Reckoning'),
(12, 1, 'Diamond Flask'),
(12, 2, 'Drake Fang Talisman'),
(12, 3, 'Hand of Justice'),
(12, 3, 'Blackhand''s Breadth'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Onyxia Blood Talisman'),
(16, 1, 'Elementium Reinforced Bulwark'),
(16, 2, 'Drillborer Disk'),
(16, 3, 'Draconian Deflector'),
(16, 3, 'Force Reactive Disk'),
(16, 3, 'Intricately Runed Shield'),
(15, 1, 'Thunderfury, Blessed Blade of the Windseeker'),
(15, 2, 'Maladath, Runed Blade of the Black Flight'),
(15, 3, 'Chromatically Tempered Sword'),
(15, 3, 'Brutality Blade'),
(15, 3, 'Quel''Serrar'),
(15, 3, 'Perdition''s Blade'),
(17, 1, 'Blastershot Launcher'),
(17, 2, 'Striker''s Mark'),
(17, 3, 'Satyr''s Bow'),
(17, 3, 'Heartstriker'),
(17, 3, 'Dragonbreath Hand Cannon'),
(17, 3, 'Blackcrow');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 2, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` IN (2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
