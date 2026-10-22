-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : wowtbc.gg. Classe 7, spe 0, palier 70.
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
( 0, 2, 'Mish''undare, Circlet of the Mind Flayer', NULL),
( 0, 3, 'Spellweaver''s Turban', NULL),
( 0, 4, 'Stormcaller''s Diadem', NULL),
( 0, 5, 'The Hexxer''s Cover', NULL),
( 1, 1, 'Amulet of Vek''nilash', NULL),
( 1, 2, 'Choker of the Fire Lord', NULL),
( 1, 3, 'Gem of Trapped Innocents', NULL),
( 1, 4, 'Malice Stone Pendant', NULL),
( 1, 5, 'Charm of the Shifting Sands', NULL),
( 1, 6, 'Jeklik''s Opaline Talisman', NULL),
( 2, 1, 'Pauldrons of Elemental Fury', NULL),
( 2, 2, 'Rime Covered Mantle', NULL),
( 2, 3, 'Deep Earth Spaulders', NULL),
( 2, 4, 'Mantle of the Blackwing Cabal', NULL),
( 2, 5, 'Mantle of the Desert''s Fury', NULL),
( 2, 6, 'Stormcaller''s Pauldrons', NULL),
(14, 1, 'Cloak of the Necropolis', NULL),
(14, 2, 'Cloak of the Devoured', NULL),
(14, 3, 'Cloak of Consumption', NULL),
(14, 4, 'Veil of Eclipse', NULL),
(14, 5, 'Cloak of the Brood Lord', NULL),
(14, 6, 'Cloak of the Hakkari Worshippers', NULL),
( 4, 1, 'Crystal Webbed Robe', NULL),
( 4, 2, 'Garb of Royal Ascension', NULL),
( 4, 3, 'Bloodvine Vest', NULL),
( 4, 4, 'Jade Inlaid Vestments', NULL),
( 4, 5, 'Zandalar Augur''s Hauberk', NULL),
( 4, 6, 'Stormcaller''s Hauberk', NULL),
( 8, 1, 'The Soul Harvester''s Bindings', NULL),
( 8, 2, 'Rockfury Bracers', NULL),
( 8, 3, 'Bracers of Arcane Accuracy', NULL),
( 8, 4, 'Burrower Bracers', NULL),
( 8, 5, 'Black Bark Wristbands', NULL),
( 9, 1, 'Dark Storm Gauntlets', NULL),
( 9, 2, 'Gloves of Ebru', NULL),
( 9, 3, 'Bloodtinged Gloves', NULL),
( 9, 4, 'Gauntlets of Kalimdor', NULL),
( 9, 5, 'Gloves of Delusional Power', NULL),
( 9, 6, 'Gloves of Earthen Power', NULL),
( 5, 1, 'Eyestalk Waist Cord', NULL),
( 5, 2, 'Firemaw''s Clutch', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 4, 'Girdle of Elemental Fury', NULL),
( 5, 5, 'Belt of Untapped Power', NULL),
( 5, 6, 'Sash of the Windreaver', NULL),
( 6, 1, 'Leggings of Polarity', NULL),
( 6, 2, 'Leggings of Elemental Fury', NULL),
( 6, 3, 'Leggings of the Black Blizzard', NULL),
( 6, 4, 'Bloodvine Leggings', NULL),
( 6, 5, 'Scaled Leggings of Qiraji Fury', NULL),
( 7, 1, 'Boots of Epiphany', NULL),
( 7, 2, 'Boots of Fright', NULL),
( 7, 3, 'Snowblind Shoes', NULL),
( 7, 4, 'Betrayer''s Boots', NULL),
( 7, 5, 'Bloodvine Boots', NULL),
( 7, 6, 'Stormcaller''s Footguards', NULL),
(10, 1, 'Ring of the Fallen God', NULL),
(10, 2, 'Band of the Inevitable', NULL),
(10, 3, 'Seal of the Damned', NULL),
(10, 4, 'Ritssyn''s Ring of Chaos', NULL),
(10, 5, 'Band of Forced Concentration', NULL),
(10, 6, 'Ring of Spell Power', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'The Restrained Essence of Sapphiron', NULL),
(12, 3, 'Mark of the Champion', 23207),
(12, 4, 'Natural Alignment Crystal', NULL),
(12, 5, 'Talisman of Ephemeral Power', NULL),
(12, 6, 'Zandalarian Hero Charm', NULL),
(15, 1, 'Brimstone Staff', NULL),
(15, 2, 'Soulseeker', NULL),
(15, 3, 'The End of Dreams', NULL),
(15, 4, 'Midnight Haze', NULL),
(15, 5, 'Lok''amir il Romathis', NULL),
(15, 6, 'Blessed Qiraji Acolyte Staff', NULL),
(16, 1, 'Sapphiron''s Left Eye', NULL),
(16, 2, 'Royal Scepter of Vek''lor', NULL),
(16, 3, 'Talon of Furious Concentration', NULL),
(16, 4, 'Master Dragonslayer''s Orb', NULL),
(17, 1, 'Totem of the Storm', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 0 AND `tier_id` = 70;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 0, s.`slot`, 0, 70, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('wowtbc.gg - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 64) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NOT NULL;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template`
           WHERE `AllowableClass` = -1 OR (`AllowableClass` & 64) <> 0
           GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE COALESCE(s.`entry`, r.entry) IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` IN (0) AND `tier_id` = 70
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
