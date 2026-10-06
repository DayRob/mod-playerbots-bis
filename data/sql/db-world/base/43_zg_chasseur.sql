-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 3, spe 0,1,2, palier 40.
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
( 0, 1, 'Dragonstalker''s Helm', NULL),
( 0, 2, 'Blooddrenched Mask', NULL),
( 0, 3, 'Crown of Destruction', NULL),
( 0, 3, 'Giantstalker''s Helmet', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 1, 3, 'Beads of Ogre Might', NULL),
( 2, 1, 'Dragonstalker''s Spaulders', NULL),
( 2, 2, 'Giantstalker''s Epaulets', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 3, 'Wyrmtongue Shoulders', NULL),
( 2, 3, 'Spaulders of the Unseen', NULL),
(14, 1, 'Cape of the Black Baron', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Cloak of the Shrouded Mists', NULL),
(14, 3, 'Zulian Tigerhide Cloak', NULL),
(14, 3, 'Cloak of Firemaw', NULL),
( 4, 1, 'Dragonstalker''s Breastplate', NULL),
( 4, 2, 'Primal Batskin Jerkin', NULL),
( 4, 3, 'Giantstalker''s Breastplate', NULL),
( 4, 3, 'Savage Gladiator Chain', NULL),
( 4, 3, 'Beastmaster''s Tunic', NULL),
( 8, 1, 'Dragonstalker''s Bracers', NULL),
( 8, 2, 'Wristguards of True Flight', NULL),
( 8, 3, 'Primal Batskin Bracers', NULL),
( 8, 3, 'Giantstalker''s Bracers', NULL),
( 8, 3, 'Bracers of the Eclipse', NULL),
( 9, 1, 'Dragonstalker''s Gauntlets', NULL),
( 9, 2, 'Giantstalker''s Gloves', NULL),
( 9, 3, 'Gloves of the Tormented', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Voone''s Vice Grips', NULL),
( 9, 3, 'Gauntlets of Accuracy', NULL),
( 5, 1, 'Dragonstalker''s Belt', NULL),
( 5, 2, 'Giantstalker''s Belt', NULL),
( 5, 3, 'Molten Belt', NULL),
( 5, 3, 'Zandalar Predator''s Belt', NULL),
( 5, 3, 'Warpwood Binding', NULL),
( 6, 1, 'Dragonstalker''s Legguards', NULL),
( 6, 2, 'Giantstalker''s Leggings', NULL),
( 6, 3, 'Plaguehound Leggings', NULL),
( 6, 3, 'Legguards of the Chromatic Defier', NULL),
( 7, 1, 'Dragonstalker''s Greaves', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Blooddrenched Footpads', NULL),
( 7, 3, 'Windreaver Greaves', NULL),
( 7, 3, 'Giantstalker''s Boots', NULL),
( 7, 3, 'Beastmaster''s Boots', NULL),
(10, 1, 'Band of Accuria', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Tarnished Elven Ring', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Band of Jin', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Renataki''s Charm of Beasts', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(12, 3, 'Royal Seal of Eldre''Thalas', NULL),
(12, 3, 'Rune of the Guard Captain', NULL),
(12, 3, 'Counterattack Lodestone', NULL),
(15, 1, 'Brutality Blade', NULL),
(15, 2, 'Warblade of the Hakkari', 19865),
(15, 3, 'Core Hound Tooth', NULL),
(15, 3, 'Dragonfang Blade', NULL),
(15, 3, 'Doom''s Edge', NULL),
(15, 3, 'Ashkandi, Greatsword of the Brotherhood', NULL),
(16, 1, 'Fang of the Faceless', NULL),
(16, 2, 'Brutality Blade', NULL),
(16, 3, 'Core Hound Tooth', NULL),
(16, 3, 'Doom''s Edge', NULL),
(16, 3, 'Bone Slicing Hatchet', NULL),
(17, 1, 'Ashjre''thul, Crossbow of Smiting', NULL),
(17, 2, 'Rhok''delar, Longbow of the Ancient Keepers', NULL),
(17, 3, 'Dragonbreath Hand Cannon', NULL),
(17, 3, 'Gurubashi Dwarf Destroyer', NULL),
(17, 3, 'Blastershot Launcher', NULL),
(17, 3, 'Striker''s Mark', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 0 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 0, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 1, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 3 AND `spec` = 2 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 2, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 3 AND `spec` IN (0,1,2) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
