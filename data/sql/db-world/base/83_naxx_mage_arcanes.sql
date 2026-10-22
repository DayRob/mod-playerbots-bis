-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 8, spe 0, palier 70.
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
( 0, 1, 'Frostfire Circlet', NULL),
( 0, 2, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 3, 'Preceptor''s Hat', NULL),
( 0, 4, 'Enigma Circlet', NULL),
( 0, 5, 'Spellweaver''s Turban', NULL),
( 0, 6, 'The Hexxer''s Cover', NULL),
( 1, 1, 'Gem of Trapped Innocents', NULL),
( 1, 2, 'Amulet of Vek''nilash', NULL),
( 1, 3, 'Choker of the Fire Lord', NULL),
( 1, 4, 'Malice Stone Pendant', NULL),
( 1, 5, 'Charm of the Shifting Sands', NULL),
( 1, 6, 'Jeklik''s Opaline Talisman', NULL),
( 2, 1, 'Rime Covered Mantle', NULL),
( 2, 2, 'Frostfire Shoulderpads', NULL),
( 2, 3, 'Mantle of the Blackwing Cabal', NULL),
( 2, 4, 'Enigma Shoulderpads', NULL),
( 2, 5, 'Boreal Mantle', NULL),
(14, 1, 'Cloak of the Necropolis', NULL),
(14, 2, 'Cloak of the Devoured', NULL),
(14, 3, 'Cloak of Consumption', NULL),
(14, 4, 'Cloak of the Brood Lord', NULL),
(14, 5, 'Veil of Eclipse', NULL),
(14, 6, 'Cloak of the Hakkari Worshippers', NULL),
( 4, 1, 'Frostfire Robe', NULL),
( 4, 2, 'Crystal Webbed Robe', NULL),
( 4, 3, 'Enigma Robes', NULL),
( 4, 4, 'Garb of Royal Ascension', NULL),
( 4, 5, 'Bloodvine Vest', NULL),
( 4, 6, 'Robe of the Archmage', NULL),
( 8, 1, 'The Soul Harvester''s Bindings', NULL),
( 8, 2, 'Rockfury Bracers', NULL),
( 8, 3, 'Bracers of Arcane Accuracy', NULL),
( 8, 4, 'Burrower Bracers', NULL),
( 8, 5, 'Frostfire Bindings', NULL),
( 8, 6, 'Black Bark Wristbands', NULL),
( 9, 1, 'Frostfire Gloves', NULL),
( 9, 2, 'Dark Storm Gauntlets', NULL),
( 9, 3, 'Bloodtinged Gloves', NULL),
( 9, 4, 'Netherwind Gloves', NULL),
( 9, 5, 'Gloves of Delusional Power', NULL),
( 9, 6, 'Sandworm Skin Gloves', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Frostfire Belt', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 4, 'Firemaw''s Clutch', NULL),
( 5, 5, 'Belt of Untapped Power', NULL),
( 5, 6, 'Netherwind Belt', NULL),
( 6, 1, 'Leggings of Polarity', NULL),
( 6, 2, 'Frostfire Leggings', NULL),
( 6, 3, 'Leggings of the Black Blizzard', NULL),
( 6, 4, 'Bloodvine Leggings', NULL),
( 6, 5, 'Enigma Leggings', NULL),
( 7, 1, 'Frostfire Sandals', NULL),
( 7, 2, 'Ringo''s Blizzard Boots', NULL),
( 7, 3, 'Enigma Boots', NULL),
( 7, 4, 'Boots of Epiphany', NULL),
( 7, 5, 'Bloodvine Boots', NULL),
(10, 1, 'Frostfire Ring', NULL),
(10, 2, 'Ring of the Fallen God', NULL),
(10, 3, 'Band of the Inevitable', NULL),
(10, 4, 'Seal of the Damned', NULL),
(10, 5, 'Ritssyn''s Ring of Chaos', NULL),
(10, 6, 'Band of Forced Concentration', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'The Restrained Essence of Sapphiron', NULL),
(12, 3, 'Mind Quickening Gem', NULL),
(12, 4, 'Mark of the Champion', 23207),
(12, 5, 'Zandalarian Hero Charm', NULL),
(12, 6, 'Talisman of Ephemeral Power', NULL),
(15, 1, 'Wraith Blade', NULL),
(15, 2, 'Atiesh, Greatstaff of the Guardian', NULL),
(15, 3, 'Soulseeker', NULL),
(15, 4, 'Brimstone Staff', NULL),
(15, 5, 'Midnight Haze', NULL),
(15, 6, 'Sharpened Silithid Femur', NULL),
(16, 1, 'Sapphiron''s Left Eye', NULL),
(16, 2, 'Royal Scepter of Vek''lor', NULL),
(16, 3, 'Talon of Furious Concentration', NULL),
(16, 4, 'Jin''do''s Bag of Whammies', NULL),
(16, 5, 'Master Dragonslayer''s Orb', NULL),
(17, 1, 'Doomfinger', NULL),
(17, 2, 'Wand of Fates', NULL),
(17, 3, 'Cold Snap', NULL),
(17, 4, 'Wand of Qiraji Nobility', NULL),
(17, 5, 'Touch of Chaos', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 8 AND `spec` = 0 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, 0, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 8 AND `spec` IN (0) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
