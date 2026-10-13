-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 9, spe 0,2, palier 60.
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
( 0, 1, 'Doomcaller''s Circlet', NULL),
( 0, 2, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 3, 'Spellweaver''s Turban', NULL),
( 0, 4, 'The Hexxer''s Cover', NULL),
( 0, 5, 'Nemesis Skullcap', NULL),
( 1, 1, 'Amulet of Vek''nilash', NULL),
( 1, 2, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Jeklik''s Opaline Talisman', NULL),
( 1, 4, 'Charm of the Shifting Sands', NULL),
( 1, 5, 'Diana''s Pearl Necklace', NULL),
( 1, 6, 'Dark Advisor''s Pendant', NULL),
( 2, 1, 'Doomcaller''s Mantle', NULL),
( 2, 2, 'Mantle of the Blackwing Cabal', NULL),
( 2, 3, 'Felcloth Shoulders', NULL),
( 2, 4, 'Nemesis Spaulders', NULL),
(14, 1, 'Cloak of the Devoured', NULL),
(14, 2, 'Cloak of Consumption', NULL),
(14, 3, 'Cloak of the Brood Lord', NULL),
(14, 4, 'Cloak of the Hakkari Worshippers', NULL),
(14, 5, 'Cape of the Trinity', NULL),
( 4, 1, 'Bloodvine Vest', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Doomcaller''s Robes', NULL),
( 4, 4, 'Jade Inlaid Vestments', NULL),
( 4, 5, 'Robe of the Void', NULL),
( 4, 6, 'Robe of Volatile Power', NULL),
( 8, 1, 'Rockfury Bracers', NULL),
( 8, 2, 'Bracers of Arcane Accuracy', NULL),
( 8, 3, 'Burrower Bracers', NULL),
( 8, 4, 'Black Bark Wristbands', NULL),
( 8, 5, 'Shackles of the Unscarred', NULL),
( 8, 6, 'Nemesis Bracers', NULL),
( 9, 1, 'Dark Storm Gauntlets', NULL),
( 9, 2, 'Ebony Flame Gloves', NULL),
( 9, 3, 'Felcloth Gloves', NULL),
( 9, 4, 'Bloodtinged Gloves', NULL),
( 9, 5, 'Hands of Power', NULL),
( 9, 6, 'Nemesis Gloves', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Mana Igniting Cord', NULL),
( 5, 3, 'Firemaw''s Clutch', NULL),
( 5, 4, 'Nemesis Belt', NULL),
( 5, 5, 'Sash of Whispered Secrets', NULL),
( 5, 6, 'Belt of Untapped Power', NULL),
( 6, 1, 'Bloodvine Leggings', NULL),
( 6, 2, 'Fel Infused Leggings', NULL),
( 6, 3, 'Leggings of the Black Blizzard', NULL),
( 6, 4, 'Doomcaller''s Trousers', NULL),
( 6, 5, 'Nemesis Leggings', NULL),
( 7, 1, 'Bloodvine Boots', NULL),
( 7, 2, 'Boots of Epiphany', NULL),
( 7, 3, 'Snowblind Shoes', NULL),
( 7, 4, 'Betrayer''s Boots', NULL),
( 7, 5, 'Doomcaller''s Footwraps', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Ring of Unspoken Names', NULL),
(10, 3, 'Band of Forced Concentration', NULL),
(10, 4, 'Ritssyn''s Ring of Chaos', NULL),
(10, 5, 'Band of Dark Dominion', NULL),
(10, 6, 'Ring of Spell Power', NULL),
(12, 1, 'Zandalarian Hero Charm', NULL),
(12, 2, 'Neltharion''s Tear', NULL),
(12, 3, 'Talisman of Ephemeral Power', NULL),
(12, 4, 'Draconic Infused Emblem', NULL),
(12, 5, 'Briarwood Reed', NULL),
(12, 6, 'Royal Seal of Eldre''Thalas', NULL),
(15, 1, 'Sharpened Silithid Femur', NULL),
(15, 2, 'Blessed Qiraji Acolyte Staff', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 4, 'Claw of Chromaggus', NULL),
(15, 5, 'Staff of the Ruins', NULL),
(15, 6, 'Azuresong Mageblade', NULL),
(16, 1, 'Royal Scepter of Vek''lor', NULL),
(16, 2, 'Scepter of Interminable Focus', NULL),
(16, 3, 'Jin''do''s Bag of Whammies', NULL),
(16, 4, 'Talon of Furious Concentration', NULL),
(17, 1, 'Wand of Qiraji Nobility', NULL),
(17, 2, 'Touch of Chaos', NULL),
(17, 3, 'Skul''s Ghastly Touch', NULL),
(17, 4, 'Bonecreeper Stylus', NULL),
(17, 5, 'Ritssyn''s Wand of Bad Mojo', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 9 AND `spec` = 0 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 9, 0, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 9 AND `spec` = 2 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 9, 2, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 9 AND `spec` IN (0,2) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
