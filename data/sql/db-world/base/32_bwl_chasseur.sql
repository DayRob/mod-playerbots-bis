-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 3, spe 0,1,2, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Dragonstalker''s Helm'),
( 0, 2, 'Crown of Destruction'),
( 0, 3, 'Giantstalker''s Helmet'),
( 0, 4, 'Backwood Helm'),
( 0, 5, 'Mask of the Unforgiven'),
( 1, 1, 'Prestor''s Talisman of Connivery'),
( 1, 2, 'Onyxia Tooth Pendant'),
( 1, 3, 'Mark of Fordring'),
( 1, 4, 'Beads of Ogre Might'),
( 2, 1, 'Dragonstalker''s Spaulders'),
( 2, 2, 'Giantstalker''s Epaulets'),
( 2, 3, 'Truestrike Shoulders'),
( 2, 4, 'Wyrmtongue Shoulders'),
( 2, 5, 'Spaulders of the Unseen'),
(14, 1, 'Cape of the Black Baron'),
(14, 2, 'Puissant Cape'),
(14, 3, 'Cloak of the Shrouded Mists'),
(14, 4, 'Cloak of Firemaw'),
(14, 5, 'Shifting Cloak'),
( 4, 1, 'Dragonstalker''s Breastplate'),
( 4, 2, 'Giantstalker''s Breastplate'),
( 4, 3, 'Savage Gladiator Chain'),
( 4, 4, 'Ogre Forged Hauberk'),
( 4, 5, 'Cadaverous Armor'),
( 8, 1, 'Dragonstalker''s Bracers'),
( 8, 2, 'Wristguards of True Flight'),
( 8, 3, 'Giantstalker''s Bracers'),
( 8, 4, 'Bracers of the Eclipse'),
( 8, 5, 'Slashclaw Bracers'),
( 9, 1, 'Dragonstalker''s Gauntlets'),
( 9, 2, 'Giantstalker''s Gloves'),
( 9, 3, 'Doomhide Gauntlets'),
( 9, 4, 'Voone''s Vice Grips'),
( 9, 5, 'Gauntlets of Accuracy'),
( 9, 6, 'Devilsaur Gauntlets'),
( 5, 1, 'Dragonstalker''s Belt'),
( 5, 2, 'Giantstalker''s Belt'),
( 5, 3, 'Warpwood Binding'),
( 5, 4, 'Chiselbrand Girdle'),
( 5, 5, 'Cloudrunner Girdle'),
( 6, 1, 'Dragonstalker''s Legguards'),
( 6, 2, 'Giantstalker''s Leggings'),
( 6, 3, 'Plaguehound Leggings'),
( 6, 4, 'Legguards of the Chromatic Defier'),
( 7, 1, 'Dragonstalker''s Greaves'),
( 7, 2, 'Boots of the Shadow Flame'),
( 7, 3, 'Windreaver Greaves'),
( 7, 4, 'Giantstalker''s Boots'),
( 7, 5, 'Mongoose Boots'),
( 7, 6, 'Swiftwalker Boots'),
(10, 1, 'Band of Accuria'),
(10, 2, 'Master Dragonslayer''s Ring'),
(10, 3, 'Tarnished Elven Ring'),
(10, 4, 'Circle of Applied Force'),
(10, 5, 'Quick Strike Ring'),
(12, 1, 'Drake Fang Talisman'),
(12, 2, 'Blackhand''s Breadth'),
(12, 3, 'Royal Seal of Eldre''Thalas'),
(12, 4, 'Rune of the Guard Captain'),
(12, 5, 'Counterattack Lodestone'),
(12, 6, 'Hand of Justice'),
(15, 1, 'Brutality Blade'),
(15, 2, 'Core Hound Tooth'),
(15, 3, 'Dragonfang Blade'),
(15, 4, 'Doom''s Edge'),
(15, 5, 'Ashkandi, Greatsword of the Brotherhood'),
(15, 6, 'Barbarous Blade'),
(16, 1, 'Core Hound Tooth'),
(16, 2, 'Brutality Blade'),
(16, 3, 'Doom''s Edge'),
(16, 4, 'Bone Slicing Hatchet'),
(16, 5, 'Lefty''s Brass Knuckle'),
(17, 1, 'Ashjre''thul, Crossbow of Smiting'),
(17, 2, 'Rhok''delar, Longbow of the Ancient Keepers'),
(17, 3, 'Dragonbreath Hand Cannon'),
(17, 4, 'Blastershot Launcher'),
(17, 5, 'Striker''s Mark'),
(17, 6, 'Core Marksman Rifle');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 0 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 0, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 1 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 1, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 2, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 3 AND `spec` IN (0,1,2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
