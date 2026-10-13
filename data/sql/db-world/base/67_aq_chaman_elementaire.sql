-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 7, spe 0, palier 60.
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
( 0, 1, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 2, 'Spellweaver''s Turban', NULL),
( 0, 3, 'Stormcaller''s Diadem', NULL),
( 0, 4, 'The Hexxer''s Cover', NULL),
( 0, 5, 'Crimson Felt Hat', NULL),
( 1, 1, 'Amulet of Vek''nilash', NULL),
( 1, 2, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Charm of the Shifting Sands', NULL),
( 1, 4, 'Jeklik''s Opaline Talisman', NULL),
( 1, 5, 'Diana''s Pearl Necklace', NULL),
( 1, 6, 'Choker of Enlightenment', NULL),
( 2, 1, 'Deep Earth Spaulders', NULL),
( 2, 2, 'Mantle of the Blackwing Cabal', NULL),
( 2, 3, 'Mantle of the Desert''s Fury', NULL),
( 2, 4, 'Stormcaller''s Pauldrons', NULL),
(14, 1, 'Cloak of the Devoured', NULL),
(14, 2, 'Cloak of Consumption', NULL),
(14, 3, 'Cloak of the Brood Lord', NULL),
(14, 4, 'Cloak of the Hakkari Worshippers', NULL),
(14, 5, 'Cape of the Trinity', NULL),
( 4, 1, 'Stormcaller''s Hauberk', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Bloodvine Vest', NULL),
( 4, 4, 'Jade Inlaid Vestments', NULL),
( 4, 5, 'Zandalar Augur''s Hauberk', NULL),
( 4, 6, 'Robe of Volatile Power', NULL),
( 8, 1, 'Rockfury Bracers', NULL),
( 8, 2, 'Bracers of Arcane Accuracy', NULL),
( 8, 3, 'Burrower Bracers', NULL),
( 8, 4, 'Black Bark Wristbands', NULL),
( 8, 5, 'Shackles of the Unscarred', NULL),
( 9, 1, 'Dark Storm Gauntlets', NULL),
( 9, 2, 'Gloves of Ebru', NULL),
( 9, 3, 'Bloodtinged Gloves', NULL),
( 9, 4, 'Gauntlets of Kalimdor', NULL),
( 9, 5, 'Gloves of Delusional Power', NULL),
( 9, 6, 'Gloves of Earthen Power', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 4, 'Belt of Untapped Power', NULL),
( 5, 5, 'Sash of the Windreaver', NULL),
( 5, 6, 'Southwind''s Grasp', NULL),
( 6, 1, 'Stormcaller''s Leggings', NULL),
( 6, 2, 'Leggings of the Black Blizzard', NULL),
( 6, 3, 'Bloodvine Leggings', NULL),
( 6, 4, 'Scaled Leggings of Qiraji Fury', NULL),
( 6, 5, 'Leggings of Immersion', NULL),
( 7, 1, 'Stormcaller''s Footguards', NULL),
( 7, 2, 'Boots of Epiphany', NULL),
( 7, 3, 'Boots of Fright', NULL),
( 7, 4, 'Snowblind Shoes', NULL),
( 7, 5, 'Betrayer''s Boots', NULL),
( 7, 6, 'Bloodvine Boots', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Ritssyn''s Ring of Chaos', NULL),
(10, 3, 'Band of Forced Concentration', NULL),
(10, 4, 'Ring of Spell Power', NULL),
(10, 5, 'Mindtear Band', NULL),
(10, 6, 'Signet Ring of the Bronze Dragonflight', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'Natural Alignment Crystal', NULL),
(12, 3, 'Talisman of Ephemeral Power', NULL),
(12, 4, 'Zandalarian Hero Charm', NULL),
(12, 5, 'Draconic Infused Emblem', NULL),
(12, 6, 'Briarwood Reed', NULL),
(15, 1, 'Lok''amir il Romathis', NULL),
(15, 2, 'Blessed Qiraji Acolyte Staff', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 4, 'Claw of Chromaggus', NULL),
(15, 5, 'Hammer of the Gathering Storm', NULL),
(15, 6, 'Fang of the Mystics', NULL),
(16, 1, 'Royal Scepter of Vek''lor', NULL),
(16, 2, 'Talon of Furious Concentration', NULL),
(16, 3, 'Master Dragonslayer''s Orb', NULL),
(16, 4, 'Jin''do''s Bag of Whammies', NULL),
(16, 5, 'Scepter of Interminable Focus', NULL),
(17, 1, 'Totem of the Storm', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 0 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 0, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 7 AND `spec` IN (0) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
