-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 3, spe 1, palier 70.
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
( 0, 1, 'Cryptstalker Headpiece', NULL),
( 0, 2, 'Striker''s Diadem', NULL),
( 0, 3, 'Blooddrenched Mask', NULL),
( 0, 4, 'Dragonstalker''s Helm', NULL),
( 0, 5, 'Crown of Destruction', NULL),
( 1, 1, 'Prestor''s Talisman of Connivery', NULL),
( 1, 2, 'Onyxia Tooth Pendant', NULL),
( 1, 3, 'Stormrage''s Talisman of Seething', NULL),
( 1, 4, 'Barbed Choker', NULL),
( 1, 5, 'The Eye of Hakkar', NULL),
( 1, 6, 'Pendant of Celerity', NULL),
( 2, 1, 'Cryptstalker Spaulders', NULL),
( 2, 2, 'Mantle of Wicked Revenge', NULL),
( 2, 3, 'Dragonstalker''s Spaulders', NULL),
( 2, 4, 'Giantstalker''s Epaulets', NULL),
( 2, 5, 'Barrage Shoulders', NULL),
(14, 1, 'Cloak of the Fallen God', NULL),
(14, 2, 'Shroud of Dominion', NULL),
(14, 3, 'Cloak of the Unseen Path', NULL),
(14, 4, 'Cloak of Concentrated Hatred', NULL),
(14, 5, 'Earthweave Cloak', NULL),
(14, 6, 'Puissant Cape', NULL),
( 4, 1, 'Cryptstalker Tunic', NULL),
( 4, 2, 'Striker''s Hauberk', NULL),
( 4, 3, 'Dragonstalker''s Breastplate', NULL),
( 4, 4, 'Vest of Swift Execution', NULL),
( 4, 5, 'Primal Batskin Jerkin', NULL),
( 4, 6, 'Obsidian Mail Tunic', NULL),
( 8, 1, 'Cryptstalker Wristguards', NULL),
( 8, 2, 'Wristguards of True Flight', NULL),
( 8, 3, 'Qiraji Execution Bracers', NULL),
( 8, 4, 'Dragonstalker''s Bracers', NULL),
( 8, 5, 'Primal Batskin Bracers', NULL),
( 8, 6, 'Giantstalker''s Bracers', NULL),
( 9, 1, 'Cryptstalker Handguards', NULL),
( 9, 2, 'Vek''lor''s Gloves of Devastation', NULL),
( 9, 3, 'Dragonstalker''s Gauntlets', NULL),
( 9, 4, 'Giantstalker''s Gloves', NULL),
( 9, 5, 'Gloves of the Tormented', NULL),
( 9, 6, 'Doomhide Gauntlets', NULL),
( 5, 1, 'Cryptstalker Girdle', NULL),
( 5, 2, 'Belt of Never-ending Agony', NULL),
( 5, 3, 'Ossirian''s Binding', NULL),
( 5, 4, 'Dragonstalker''s Belt', NULL),
( 5, 5, 'Marksman''s Girdle', NULL),
( 5, 6, 'Giantstalker''s Belt', NULL),
( 6, 1, 'Cryptstalker Legguards', NULL),
( 6, 2, 'Leggings of Apocalypse', NULL),
( 6, 3, 'Dragonstalker''s Legguards', NULL),
( 6, 4, 'Striker''s Leggings', NULL),
( 6, 5, 'Scaled Sand Reaver Leggings', NULL),
( 7, 1, 'Cryptstalker Boots', NULL),
( 7, 2, 'Boots of the Shadow Flame', NULL),
( 7, 3, 'Boots of Displacement', NULL),
( 7, 4, 'Striker''s Footguards', NULL),
( 7, 5, 'Dragonstalker''s Greaves', NULL),
( 7, 6, 'Blooddrenched Footpads', NULL),
(10, 1, 'Band of Reanimation', NULL),
(10, 2, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 3, 'Band of Accuria', NULL),
(10, 4, 'Band of Unnatural Forces', NULL),
(10, 5, 'Ring of the Cryptstalker', NULL),
(10, 6, 'Ring of the Godslayer', NULL),
(12, 1, 'Slayer''s Crest', NULL),
(12, 2, 'Mark of the Champion', 23206),
(12, 3, 'Kiss of the Spider', NULL),
(12, 4, 'Jom Gabbar', NULL),
(12, 5, 'Drake Fang Talisman', NULL),
(12, 6, 'Renataki''s Charm of Beasts', NULL),
(15, 1, 'Kingsfall', NULL),
(15, 2, 'Harbinger of Doom', NULL),
(15, 3, 'Iblis, Blade of the Fallen Seraph', NULL),
(15, 4, 'Blessed Qiraji Pugio', NULL),
(15, 5, 'Silithid Claw', NULL),
(15, 6, 'Warblade of the Hakkari', 19865),
(16, 1, 'Iblis, Blade of the Fallen Seraph', NULL),
(16, 2, 'Kingsfall', NULL),
(16, 3, 'Harbinger of Doom', NULL),
(16, 4, 'Blessed Qiraji Pugio', NULL),
(16, 5, 'Fang of the Faceless', NULL),
(16, 6, 'Brutality Blade', NULL),
(17, 1, 'Nerubian Slavemaker', NULL),
(17, 2, 'Soulstring', NULL),
(17, 3, 'Ashjre''thul, Crossbow of Smiting', NULL),
(17, 4, 'Larvae of the Great Worm', NULL),
(17, 5, 'Huhuran''s Stinger', NULL),
(17, 6, 'Blessed Qiraji Musket', NULL);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 3, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 3 AND `spec` IN (1) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
