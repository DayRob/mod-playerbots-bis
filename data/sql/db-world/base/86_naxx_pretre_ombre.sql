-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 5, spe 2, palier 70.
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
( 0, 1, 'Preceptor''s Hat', NULL),
( 0, 2, 'Spellweaver''s Turban', NULL),
( 0, 3, 'The Hexxer''s Cover', NULL),
( 0, 4, 'Tiara of the Oracle', NULL),
( 0, 5, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 1, 1, 'Choker of the Fire Lord', NULL),
( 1, 2, 'Malice Stone Pendant', NULL),
( 1, 3, 'Amulet of Vek''nilash', NULL),
( 1, 4, 'Charm of the Shifting Sands', NULL),
( 1, 5, 'Jeklik''s Opaline Talisman', NULL),
( 1, 6, 'Dark Advisor''s Pendant', NULL),
( 2, 1, 'Rime Covered Mantle', NULL),
( 2, 2, 'Mantle of the Blackwing Cabal', NULL),
( 2, 3, 'Felcloth Shoulders', NULL),
( 2, 4, 'Mantle of Maz''Nadir', NULL),
( 2, 5, 'Mantle of the Oracle', NULL),
(14, 1, 'Cloak of the Devoured', NULL),
(14, 2, 'Cloak of the Necropolis', NULL),
(14, 3, 'Cloak of Consumption', NULL),
(14, 4, 'Cloak of the Brood Lord', NULL),
(14, 5, 'Veil of Eclipse', NULL),
(14, 6, 'Cloak of the Hakkari Worshippers', NULL),
( 4, 1, 'Crystal Webbed Robe', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Bloodvine Vest', NULL),
( 4, 4, 'Jade Inlaid Vestments', NULL),
( 4, 5, 'Robe of Winter Night', NULL),
( 8, 1, 'Rockfury Bracers', NULL),
( 8, 2, 'Bracers of Arcane Accuracy', NULL),
( 8, 3, 'Burrower Bracers', NULL),
( 8, 4, 'The Soul Harvester''s Bindings', NULL),
( 9, 1, 'Ebony Flame Gloves', NULL),
( 9, 2, 'Dark Storm Gauntlets', NULL),
( 9, 3, 'Felcloth Gloves', NULL),
( 9, 4, 'Bloodtinged Gloves', NULL),
( 9, 5, 'Gloves of Delusional Power', NULL),
( 9, 6, 'Hands of Power', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Sash of Whispered Secrets', NULL),
( 5, 4, 'Belt of Untapped Power', NULL),
( 5, 5, 'Mana Igniting Cord', NULL),
( 5, 6, 'Ban''thok Sash', NULL),
( 6, 1, 'Leggings of Polarity', NULL),
( 6, 2, 'Fel Infused Leggings', NULL),
( 6, 3, 'Bloodvine Leggings', NULL),
( 6, 4, 'Leggings of the Black Blizzard', NULL),
( 6, 5, 'Leggings of Torment', NULL),
( 7, 1, 'Boots of Epiphany', NULL),
( 7, 2, 'Snowblind Shoes', NULL),
( 7, 3, 'Betrayer''s Boots', NULL),
( 7, 4, 'Bloodvine Boots', NULL),
( 7, 5, 'Maleki''s Footwraps', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Band of the Inevitable', NULL),
(10, 3, 'Band of Dark Dominion', NULL),
(10, 4, 'Ring of Spell Power', NULL),
(10, 5, 'Band of Forced Concentration', NULL),
(10, 6, 'Seal of the Damned', NULL),
(12, 1, 'The Restrained Essence of Sapphiron', NULL),
(12, 2, 'Mark of the Champion', 23207),
(12, 3, 'Neltharion''s Tear', NULL),
(12, 4, 'Talisman of Ephemeral Power', NULL),
(12, 5, 'Zandalarian Hero Charm', NULL),
(12, 6, 'Draconic Infused Emblem', NULL),
(15, 1, 'The End of Dreams', NULL),
(15, 2, 'Midnight Haze', NULL),
(15, 3, 'Lok''amir il Romathis', NULL),
(15, 4, 'Brimstone Staff', NULL),
(15, 5, 'Soulseeker', NULL),
(15, 6, 'Claw of Chromaggus', NULL),
(16, 1, 'Sapphiron''s Left Eye', NULL),
(16, 2, 'Royal Scepter of Vek''lor', NULL),
(16, 3, 'Master Dragonslayer''s Orb', NULL),
(16, 4, 'Jin''do''s Bag of Whammies', NULL),
(16, 5, 'Gem of Nerubis', NULL),
(17, 1, 'Wand of Fates', NULL),
(17, 2, 'Wand of Qiraji Nobility', NULL),
(17, 3, 'Touch of Chaos', NULL),
(17, 4, 'Doomfinger', NULL),
(17, 5, 'Skul''s Ghastly Touch', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 2 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 2, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 16) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 16) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` IN (2) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
