-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 4, spe 1, palier 60.
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
( 0, 1, 'Deathdealer''s Helm', NULL),
( 0, 2, 'Bloodfang Hood', NULL),
( 0, 3, 'Nightslayer Cover', NULL),
( 0, 4, 'Darkmantle Cap', NULL),
( 0, 5, 'Southwind Helm', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Barbed Choker', NULL),
( 1, 3, 'Onyxia Tooth Pendant', NULL),
( 1, 4, 'The Eye of Hakkar', NULL),
( 1, 5, 'Fury of the Forgotten Swarm', NULL),
( 1, 6, 'Mark of Fordring', NULL),
( 2, 1, 'Deathdealer''s Spaulders', NULL),
( 2, 2, 'Mantle of Wicked Revenge', NULL),
( 2, 3, 'Nightslayer Shoulder Pads', NULL),
( 2, 4, 'Zandalar Madcap''s Mantle', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Puissant Cape', NULL),
(14, 4, 'Cloak of Veiled Shadows', NULL),
(14, 5, 'Cloak of Firemaw', NULL),
(14, 6, 'Cape of the Black Baron', NULL),
( 4, 1, 'Deathdealer''s Vest', NULL),
( 4, 2, 'Bloodfang Chestpiece', NULL),
( 4, 3, 'Vest of Swift Execution', NULL),
( 4, 4, 'Darkmantle Tunic', NULL),
( 4, 5, 'Zandalar Madcap''s Tunic', NULL),
( 4, 6, 'Nightslayer Chestpiece', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Bloodfang Bracers', NULL),
( 8, 3, 'Primal Batskin Bracers', NULL),
( 8, 4, 'Bracers of the Eclipse', NULL),
( 8, 5, 'Scaled Bracers of the Gorger', NULL),
( 9, 1, 'Gloves of Enforcement', NULL),
( 9, 2, 'Doomhide Gauntlets', NULL),
( 9, 3, 'Nightslayer Gloves', NULL),
( 9, 4, 'Gloves of the Hidden Temple', NULL),
( 9, 5, 'Bloodfang Gloves', NULL),
( 9, 6, 'Blooddrenched Grips', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Bloodfang Belt', NULL),
( 5, 3, 'Nightslayer Belt', NULL),
( 5, 4, 'Belt of Preserved Heads', NULL),
( 5, 5, 'Taut Dragonhide Belt', NULL),
( 6, 1, 'Deathdealer''s Leggings', NULL),
( 6, 2, 'Bloodfang Pants', NULL),
( 6, 3, 'Nightslayer Pants', NULL),
( 6, 4, 'Dark Heart Pants', NULL),
( 6, 5, 'Plaguehound Leggings', NULL),
( 7, 1, 'Deathdealer''s Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Boots of the Vanguard', NULL),
( 7, 4, 'Blooddrenched Footpads', NULL),
( 7, 5, 'Bloodfang Boots', NULL),
( 7, 6, 'Nightslayer Boots', NULL),
(10, 1, 'Band of Accuria', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 4, 'Ring of the Qiraji Fury', NULL),
(10, 5, 'Quick Strike Ring', NULL),
(10, 6, 'Circle of Applied Force', NULL),
(12, 1, 'Drake Fang Talisman', NULL),
(12, 2, 'Jom Gabbar', NULL),
(12, 3, 'Earthstrike', NULL),
(12, 4, 'Renataki''s Charm of Trickery', NULL),
(12, 5, 'Hand of Justice', NULL),
(12, 6, 'Blackhand''s Breadth', NULL),
(15, 1, 'Ancient Qiraji Ripper', NULL),
(15, 2, 'Chromatically Tempered Sword', NULL),
(15, 3, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(15, 4, 'Vis''kag the Bloodletter', NULL),
(15, 5, 'Brutality Blade', NULL),
(15, 6, 'Dal''Rend''s Sacred Charge', NULL),
(16, 1, 'Maladath, Runed Blade of the Black Flight', NULL),
(16, 2, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(16, 3, 'Chromatically Tempered Sword', NULL),
(16, 4, 'Ravencrest''s Legacy', NULL),
(16, 5, 'Brutality Blade', NULL),
(16, 6, 'Warblade of the Hakkari', 19866),
(17, 1, 'Larvae of the Great Worm', NULL),
(17, 2, 'Striker''s Mark', NULL),
(17, 3, 'Crossbow of Imminent Doom', NULL),
(17, 4, 'Huhuran''s Stinger', NULL),
(17, 5, 'Gurubashi Dwarf Destroyer', NULL),
(17, 6, 'Precisely Calibrated Boomstick', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 1 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 1, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 4 AND `spec` IN (1) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
