-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 4, spe 1, palier 40.
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
( 0, 1, 'Darkmantle Cap', NULL),
( 0, 2, 'Bloodfang Hood', NULL),
( 0, 3, 'Nightslayer Cover', NULL),
( 0, 3, 'Eye of Rend', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 3, 'Mark of Fordring', NULL),
( 1, 3, 'Beads of Ogre Might', NULL),
( 2, 1, 'Zandalar Madcap''s Mantle', NULL),
( 2, 2, 'Nightslayer Shoulder Pads', NULL),
( 2, 3, 'Truestrike Shoulders', NULL),
( 2, 3, 'Bloodfang Spaulders', NULL),
(14, 1, 'Cloak of Firemaw', NULL),
(14, 2, 'Puissant Cape', NULL),
(14, 3, 'Cape of the Black Baron', NULL),
(14, 3, 'Cloak of Draconic Might', NULL),
(14, 3, 'Cloak of the Shrouded Mists', NULL),
( 4, 1, 'Darkmantle Tunic', NULL),
( 4, 2, 'Bloodfang Chestpiece', NULL),
( 4, 3, 'Zandalar Madcap''s Tunic', NULL),
( 4, 3, 'Nightslayer Chestpiece', NULL),
( 4, 3, 'Cadaverous Armor', NULL),
( 8, 1, 'Bloodfang Bracers', NULL),
( 8, 2, 'Primal Batskin Bracers', NULL),
( 8, 3, 'Bracers of the Eclipse', NULL),
( 8, 3, 'Nightslayer Bracelets', NULL),
( 8, 3, 'Darkmantle Bracers', NULL),
( 9, 1, 'Darkmantle Gloves', NULL),
( 9, 2, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Nightslayer Gloves', NULL),
( 9, 3, 'Bloodfang Gloves', NULL),
( 9, 3, 'Blooddrenched Grips', NULL),
( 9, 3, 'Devilsaur Gauntlets', NULL),
( 5, 1, 'Bloodfang Belt', NULL),
( 5, 2, 'Nightslayer Belt', NULL),
( 5, 3, 'Belt of Preserved Heads', NULL),
( 5, 3, 'Taut Dragonhide Belt', NULL),
( 5, 3, 'Molten Belt', NULL),
( 6, 1, 'Bloodfang Pants', NULL),
( 6, 2, 'Nightslayer Pants', NULL),
( 6, 3, 'Dark Heart Pants', NULL),
( 6, 3, 'Plaguehound Leggings', NULL),
( 7, 1, 'Darkmantle Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Blooddrenched Footpads', NULL),
( 7, 3, 'Bloodfang Boots', NULL),
( 7, 3, 'Nightslayer Boots', NULL),
( 7, 3, 'Swiftwalker Boots', NULL),
(10, 1, 'Band of Accuria', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Quick Strike Ring', NULL),
(10, 3, 'Circle of Applied Force', NULL),
(10, 3, 'Tarnished Elven Ring', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Renataki''s Charm of Trickery', NULL),
(12, 3, 'Hand of Justice', NULL),
(12, 3, 'Blackhand''s Breadth', NULL),
(12, 3, 'Rune of the Guard Captain', NULL),
(12, 3, 'Royal Seal of Eldre''Thalas', NULL),
(15, 1, 'Chromatically Tempered Sword', NULL),
(15, 2, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(15, 3, 'Vis''kag the Bloodletter', NULL),
(15, 3, 'Brutality Blade', NULL),
(15, 3, 'Dal''Rend''s Sacred Charge', NULL),
(15, 3, 'Teebu''s Blazing Longsword', NULL),
(16, 1, 'Maladath, Runed Blade of the Black Flight', NULL),
(16, 2, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(16, 3, 'Chromatically Tempered Sword', NULL),
(16, 3, 'Brutality Blade', NULL),
(16, 3, 'Warblade of the Hakkari', 19866),
(16, 3, 'Vis''kag the Bloodletter', NULL),
(17, 1, 'Striker''s Mark', NULL),
(17, 2, 'Gurubashi Dwarf Destroyer', NULL),
(17, 3, 'Precisely Calibrated Boomstick', NULL),
(17, 3, 'Dragonbreath Hand Cannon', NULL),
(17, 3, 'Blackcrow', NULL),
(17, 3, 'Satyr''s Bow', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 1 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 1, s.`slot`, 0, 40, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 4 AND `spec` IN (1) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
