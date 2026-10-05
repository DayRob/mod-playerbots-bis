-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 4, spe 1, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Bloodfang Hood'),
( 0, 2, 'Nightslayer Cover'),
( 0, 3, 'Eye of Rend'),
( 0, 3, 'Mask of the Unforgiven'),
( 1, 1, 'Prestor''s Talisman of Connivery'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'Mark of Fordring'),
( 1, 3, 'Beads of Ogre Might'),
( 1, 3, 'Imperial Jewel'),
( 2, 1, 'Bloodfang Spaulders'),
( 2, 2, 'Nightslayer Shoulder Pads'),
( 2, 3, 'Truestrike Shoulders'),
( 2, 3, 'Wyrmtongue Shoulders'),
( 2, 3, 'Spaulders of the Unseen'),
(14, 1, 'Cloak of Firemaw'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cape of the Black Baron'),
(14, 3, 'Cloak of Draconic Might'),
(14, 3, 'Cloak of the Shrouded Mists'),
(14, 3, 'Blackveil Cape'),
( 4, 1, 'Bloodfang Chestpiece'),
( 4, 2, 'Nightslayer Chestpiece'),
( 4, 3, 'Cadaverous Armor'),
( 4, 3, 'Breastplate of Bloodthirst'),
( 4, 3, 'Nightbrace Tunic'),
( 8, 1, 'Bloodfang Bracers'),
( 8, 2, 'Bracers of the Eclipse'),
( 8, 3, 'Nightslayer Bracelets'),
( 8, 3, 'Deepfury Bracers'),
( 9, 1, 'Bloodfang Gloves'),
( 9, 2, 'Doomhide Gauntlets'),
( 9, 3, 'Nightslayer Gloves'),
( 9, 3, 'Devilsaur Gauntlets'),
( 9, 3, 'Cadaverous Gloves'),
( 9, 3, 'Gargoyle Slashers'),
( 5, 1, 'Bloodfang Belt'),
( 5, 2, 'Nightslayer Belt'),
( 5, 3, 'Taut Dragonhide Belt'),
( 5, 3, 'Cloudrunner Girdle'),
( 6, 1, 'Bloodfang Pants'),
( 6, 2, 'Nightslayer Pants'),
( 6, 3, 'Plaguehound Leggings'),
( 6, 3, 'Devilsaur Leggings'),
( 7, 1, 'Bloodfang Boots'),
( 7, 2, 'Boots of the Shadow Flame'),
( 7, 3, 'Nightslayer Boots'),
( 7, 3, 'Swiftwalker Boots'),
( 7, 3, 'Mongoose Boots'),
(10, 1, 'Band of Accuria'),
(10, 2, 'Master Dragonslayer''s Ring'),
(10, 3, 'Quick Strike Ring'),
(10, 3, 'Circle of Applied Force'),
(10, 3, 'Tarnished Elven Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Hand of Justice'),
(12, 3, 'Blackhand''s Breadth'),
(12, 3, 'Rune of the Guard Captain'),
(12, 3, 'Royal Seal of Eldre''Thalas'),
(12, 3, 'Counterattack Lodestone'),
(15, 1, 'Chromatically Tempered Sword'),
(15, 2, 'Thunderfury, Blessed Blade of the Windseeker'),
(15, 3, 'Vis''kag the Bloodletter'),
(15, 3, 'Brutality Blade'),
(15, 3, 'Dal''Rend''s Sacred Charge'),
(15, 3, 'Teebu''s Blazing Longsword'),
(16, 1, 'Maladath, Runed Blade of the Black Flight'),
(16, 2, 'Thunderfury, Blessed Blade of the Windseeker'),
(16, 3, 'Chromatically Tempered Sword'),
(16, 3, 'Brutality Blade'),
(16, 3, 'Vis''kag the Bloodletter'),
(16, 3, 'Dal''Rend''s Tribal Guardian'),
(17, 1, 'Striker''s Mark'),
(17, 2, 'Precisely Calibrated Boomstick'),
(17, 3, 'Dragonbreath Hand Cannon'),
(17, 3, 'Blackcrow'),
(17, 3, 'Satyr''s Bow'),
(17, 3, 'Blastershot Launcher');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 1 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 1, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 4 AND `spec` IN (1) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
