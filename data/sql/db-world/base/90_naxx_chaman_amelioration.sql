-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 7, spe 1, palier 70.
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
( 0, 1, 'Crown of Destruction', NULL),
( 0, 2, 'Southwind Helm', NULL),
( 0, 3, 'Bloodstained Coif', NULL),
( 0, 4, 'Eye of Rend', NULL),
( 0, 5, 'Blooddrenched Mask', NULL),
( 1, 1, 'Stormrage''s Talisman of Seething', NULL),
( 1, 2, 'Barbed Choker', NULL),
( 1, 3, 'The Eye of Hakkar', NULL),
( 1, 4, 'Onyxia Tooth Pendant', NULL),
( 1, 5, 'Fury of the Forgotten Swarm', NULL),
( 1, 6, 'Prestor''s Talisman of Connivery', NULL),
( 2, 1, 'Mantle of Wicked Revenge', NULL),
( 2, 2, 'Truestrike Shoulders', NULL),
( 2, 3, 'Chitinous Shoulderguards', NULL),
( 2, 4, 'Stormcaller''s Pauldrons', NULL),
( 2, 5, 'Taut Dragonhide Shoulderpads', NULL),
( 2, 6, 'Dark Warder''s Pauldrons', NULL),
(14, 1, 'Shroud of Dominion', NULL),
(14, 2, 'Cloak of Concentrated Hatred', NULL),
(14, 3, 'Puissant Cape', NULL),
(14, 4, 'Cloak of the Fallen God', NULL),
(14, 5, 'Cloak of Draconic Might', NULL),
(14, 6, 'Cloak of the Scourge', NULL),
( 4, 1, 'Ghoul Skin Tunic', NULL),
( 4, 2, 'Savage Gladiator Chain', NULL),
( 4, 3, 'Obsidian Mail Tunic', NULL),
( 4, 4, 'Vest of Swift Execution', NULL),
( 4, 5, 'Stormcaller''s Hauberk', NULL),
( 4, 6, 'Cadaverous Armor', NULL),
( 8, 1, 'Qiraji Execution Bracers', NULL),
( 8, 2, 'Wristguards of Stability', NULL),
( 8, 3, 'Wristguards of True Flight', NULL),
( 8, 4, 'Scaled Bracers of the Gorger', NULL),
( 8, 5, 'Primal Batskin Bracers', NULL),
( 9, 1, 'Gloves of Enforcement', NULL),
( 9, 2, 'Gloves of the Hidden Temple', NULL),
( 9, 3, 'Blooddrenched Grips', NULL),
( 9, 4, 'Doomhide Gauntlets', NULL),
( 9, 5, 'Aged Core Leather Gloves', NULL),
( 5, 1, 'Belt of Never-ending Agony', NULL),
( 5, 2, 'Ossirian''s Binding', NULL),
( 5, 3, 'Therazane''s Link', NULL),
( 5, 4, 'Belt of Preserved Heads', NULL),
( 5, 5, 'Taut Dragonhide Belt', NULL),
( 6, 1, 'Leggings of Apocalypse', NULL),
( 6, 2, 'Scaled Sand Reaver Leggings', NULL),
( 6, 3, 'Dark Heart Pants', NULL),
( 6, 4, 'Devilsaur Leggings', NULL),
( 6, 5, 'Legguards of the Chromatic Defier', NULL),
( 7, 1, 'Boots of the Shadow Flame', NULL),
( 7, 2, 'Boots of the Vanguard', NULL),
( 7, 3, 'Boots of the Fallen Prophet', NULL),
( 7, 4, 'Stormcaller''s Footguards', NULL),
( 7, 5, 'Bloodmail Boots', NULL),
( 7, 6, 'Blooddrenched Footpads', NULL),
(10, 1, 'Band of Unnatural Forces', NULL),
(10, 2, 'Master Dragonslayer''s Ring', NULL),
(10, 3, 'Quick Strike Ring', NULL),
(10, 4, 'Ring of the Qiraji Fury', NULL),
(10, 5, 'Band of Accuria', NULL),
(12, 1, 'Kiss of the Spider', NULL),
(12, 2, 'Mark of the Champion', 23206),
(12, 3, 'Slayer''s Crest', NULL),
(12, 4, 'Jom Gabbar', NULL),
(12, 5, 'Earthstrike', NULL),
(12, 6, 'Drake Fang Talisman', NULL),
(15, 1, 'Might of Menethil', NULL),
(15, 2, 'Dark Edge of Insanity', NULL),
(15, 3, 'Severance', NULL),
(15, 4, 'Drake Talon Cleaver', NULL),
(15, 5, 'Spinal Reaper', NULL),
(17, 1, 'Totem of Rage', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 1 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 1, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (1) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
