-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 4, spe 0,1,2, palier 70.
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
( 0, 1, 'Bonescythe Helmet', NULL),
( 0, 2, 'Deathdealer''s Helm', NULL),
( 0, 3, 'Bloodfang Hood', NULL),
( 0, 4, 'Nightslayer Cover', NULL),
( 0, 5, 'Darkmantle Cap', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Stormrage''s Talisman of Seething', NULL),
( 1, 3, 'Barbed Choker', NULL),
( 1, 4, 'Onyxia Tooth Pendant', NULL),
( 1, 5, 'The Eye of Hakkar', NULL),
( 1, 6, 'Fury of the Forgotten Swarm', NULL),
( 2, 1, 'Bonescythe Pauldrons', NULL),
( 2, 2, 'Deathdealer''s Spaulders', NULL),
( 2, 3, 'Mantle of Wicked Revenge', NULL),
( 2, 4, 'Nightslayer Shoulder Pads', NULL),
( 2, 5, 'Zandalar Madcap''s Mantle', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Shroud of Dominion', NULL),
(14, 3, 'Cloak of Concentrated Hatred', NULL),
(14, 4, 'Puissant Cape', NULL),
(14, 5, 'Cloak of Veiled Shadows', NULL),
(14, 6, 'Cloak of Firemaw', NULL),
( 4, 1, 'Bonescythe Breastplate', NULL),
( 4, 2, 'Deathdealer''s Vest', NULL),
( 4, 3, 'Bloodfang Chestpiece', NULL),
( 4, 4, 'Vest of Swift Execution', NULL),
( 4, 5, 'Darkmantle Tunic', NULL),
( 4, 6, 'Ghoul Skin Tunic', NULL),
( 8, 1, 'Bonescythe Bracers', NULL),
( 8, 2, 'Qiraji Execution Bracers', NULL),
( 8, 3, 'Bloodfang Bracers', NULL),
( 8, 4, 'Primal Batskin Bracers', NULL),
( 8, 5, 'Bracers of the Eclipse', NULL),
( 9, 1, 'Bonescythe Gauntlets', NULL),
( 9, 2, 'Gloves of Enforcement', NULL),
( 9, 3, 'Doomhide Gauntlets', NULL),
( 9, 4, 'Nightslayer Gloves', NULL),
( 9, 5, 'Gloves of the Hidden Temple', NULL),
( 9, 6, 'Bloodfang Gloves', NULL),
( 5, 1, 'Bonescythe Waistguard', NULL),
( 5, 2, 'Belt of Never-ending Agony', NULL),
( 5, 3, 'Bloodfang Belt', NULL),
( 5, 4, 'Nightslayer Belt', NULL),
( 5, 5, 'Belt of Preserved Heads', NULL),
( 5, 6, 'Taut Dragonhide Belt', NULL),
( 6, 1, 'Bonescythe Legplates', NULL),
( 6, 2, 'Leggings of Apocalypse', NULL),
( 6, 3, 'Deathdealer''s Leggings', NULL),
( 6, 4, 'Bloodfang Pants', NULL),
( 6, 5, 'Nightslayer Pants', NULL),
( 6, 6, 'Dark Heart Pants', NULL),
( 7, 1, 'Bonescythe Sabatons', NULL),
( 7, 2, 'Deathdealer''s Boots', NULL),
( 7, 3, 'Boots of the Shadow Flame', NULL),
( 7, 4, 'Boots of the Vanguard', NULL),
( 7, 5, 'Boots of Displacement', NULL),
( 7, 6, 'Blooddrenched Footpads', NULL),
(10, 1, 'Band of Unnatural Forces', NULL),
(10, 2, 'Bonescythe Ring', NULL),
(10, 3, 'Band of Accuria', NULL),
(10, 4, 'Master Dragonslayer''s Ring', NULL),
(10, 5, 'Band of Reanimation', NULL),
(10, 6, 'Signet Ring of the Bronze Dragonflight', NULL),
(12, 1, 'Kiss of the Spider', NULL),
(12, 2, 'Slayer''s Crest', NULL),
(12, 3, 'Mark of the Champion', 23206),
(12, 4, 'Drake Fang Talisman', NULL),
(12, 5, 'Jom Gabbar', NULL),
(12, 6, 'Earthstrike', NULL),
(15, 1, 'Gressil, Dawn of Ruin', NULL),
(15, 2, 'Ancient Qiraji Ripper', NULL),
(15, 3, 'Chromatically Tempered Sword', NULL),
(15, 4, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(15, 5, 'Vis''kag the Bloodletter', NULL),
(15, 6, 'Brutality Blade', NULL),
(16, 1, 'The Hungering Cold', NULL),
(16, 2, 'Iblis, Blade of the Fallen Seraph', NULL),
(16, 3, 'Kingsfall', NULL),
(16, 4, 'Claw of the Frost Wyrm', NULL),
(16, 5, 'Thunderfury, Blessed Blade of the Windseeker', NULL),
(16, 6, 'Maladath, Runed Blade of the Black Flight', NULL),
(17, 1, 'Striker''s Mark', NULL),
(17, 2, 'Nerubian Slavemaker', NULL),
(17, 3, 'Larvae of the Great Worm', NULL),
(17, 4, 'Soulstring', NULL),
(17, 5, 'Crossbow of Imminent Doom', NULL),
(17, 6, 'Huhuran''s Stinger', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 0 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 0, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 8) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 1 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 8) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` = 2 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 4, 2, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 8) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 8) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 4 AND `spec` IN (0,1,2) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
