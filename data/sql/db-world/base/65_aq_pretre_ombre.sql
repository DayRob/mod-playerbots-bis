-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P5 AQ (wowtbc.gg). Classe 5, spe 2, palier 60.
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
( 0, 1, 'Spellweaver''s Turban', NULL),
( 0, 2, 'The Hexxer''s Cover', NULL),
( 0, 3, 'Tiara of the Oracle', NULL),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 3, 'Felcloth Hood', NULL),
( 1, 1, 'Choker of the Fire Lord', NULL),
( 1, 2, 'Amulet of Vek''nilash', NULL),
( 1, 3, 'Charm of the Shifting Sands', NULL),
( 1, 3, 'Jeklik''s Opaline Talisman', NULL),
( 1, 3, 'Dark Advisor''s Pendant', NULL),
( 1, 3, 'Choker of Enlightenment', NULL),
( 2, 1, 'Mantle of the Blackwing Cabal', NULL),
( 2, 2, 'Felcloth Shoulders', NULL),
( 2, 3, 'Mantle of Maz''Nadir', NULL),
( 2, 3, 'Mantle of the Oracle', NULL),
( 2, 3, 'Burial Shawl', NULL),
(14, 1, 'Cloak of the Devoured', NULL),
(14, 2, 'Cloak of Consumption', NULL),
(14, 3, 'Cloak of the Brood Lord', NULL),
(14, 3, 'Cloak of the Hakkari Worshippers', NULL),
(14, 3, 'Cape of the Trinity', NULL),
( 4, 1, 'Robe of Winter Night', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Bloodvine Vest', NULL),
( 4, 3, 'Jade Inlaid Vestments', NULL),
( 4, 3, 'Vestments of the Oracle', NULL),
( 8, 1, 'Rockfury Bracers', NULL),
( 8, 2, 'Bracers of Arcane Accuracy', NULL),
( 8, 3, 'Burrower Bracers', NULL),
( 8, 3, 'Sublime Wristguards', NULL),
( 9, 1, 'Ebony Flame Gloves', NULL),
( 9, 2, 'Dark Storm Gauntlets', NULL),
( 9, 3, 'Felcloth Gloves', NULL),
( 9, 3, 'Bloodtinged Gloves', NULL),
( 9, 3, 'Gloves of Delusional Power', NULL),
( 9, 3, 'Hands of Power', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Sash of Whispered Secrets', NULL),
( 5, 3, 'Belt of Untapped Power', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 3, 'Ban''thok Sash', NULL),
( 6, 1, 'Fel Infused Leggings', NULL),
( 6, 2, 'Bloodvine Leggings', NULL),
( 6, 3, 'Leggings of the Black Blizzard', NULL),
( 6, 3, 'Leggings of Torment', NULL),
( 6, 3, 'Skyshroud Leggings', NULL),
( 7, 1, 'Boots of Epiphany', NULL),
( 7, 2, 'Snowblind Shoes', NULL),
( 7, 3, 'Betrayer''s Boots', NULL),
( 7, 3, 'Bloodvine Boots', NULL),
( 7, 3, 'Maleki''s Footwraps', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Band of Dark Dominion', NULL),
(10, 3, 'Ring of Spell Power', NULL),
(10, 3, 'Band of Forced Concentration', NULL),
(10, 3, 'Signet Ring of the Bronze Dragonflight', NULL),
(10, 3, 'Ring of Swarming Thought', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'Talisman of Ephemeral Power', NULL),
(12, 3, 'Zandalarian Hero Charm', NULL),
(12, 3, 'Draconic Infused Emblem', NULL),
(12, 3, 'Briarwood Reed', NULL),
(12, 3, 'Burst of Knowledge', NULL),
(15, 1, 'Lok''amir il Romathis', NULL),
(15, 2, 'Claw of Chromaggus', NULL),
(15, 3, 'Blessed Qiraji Acolyte Staff', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 3, 'Staff of the Ruins', NULL),
(15, 3, 'Anathema', NULL),
(16, 1, 'Royal Scepter of Vek''lor', NULL),
(16, 2, 'Master Dragonslayer''s Orb', NULL),
(16, 3, 'Jin''do''s Bag of Whammies', NULL),
(16, 3, 'Talon of Furious Concentration', NULL),
(17, 1, 'Wand of Qiraji Nobility', NULL),
(17, 2, 'Touch of Chaos', NULL),
(17, 3, 'Skul''s Ghastly Touch', NULL),
(17, 3, 'Bonecreeper Stylus', NULL),
(17, 3, 'Ritssyn''s Wand of Bad Mojo', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 2 AND `tier_id` = 60;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 2, s.`slot`, 0, 60, COALESCE(s.`entry`, r.entry), s.`rank`,
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
WHERE `class` = 5 AND `spec` IN (2) AND `tier_id` = 60
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
