-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 9, spe 0,2, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Mish''undare, Circlet of the Mind Flayer'),
( 0, 2, 'Eternal Crown of Shadow Wrath'),
( 0, 3, 'Nemesis Skullcap'),
( 0, 3, 'Crimson Felt Hat'),
( 0, 3, 'Felcloth Hood'),
( 1, 1, 'Choker of the Fire Lord'),
( 1, 2, 'Diana''s Pearl Necklace'),
( 1, 3, 'Dark Advisor''s Pendant'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Beads of Ogre Mojo'),
( 1, 3, 'Star of Mystaria'),
( 2, 1, 'Mantle of the Blackwing Cabal'),
( 2, 2, 'Eternal Spaulders of Shadow Wrath'),
( 2, 3, 'Felcloth Shoulders'),
( 2, 3, 'Nemesis Spaulders'),
( 2, 3, 'Burial Shawl'),
(14, 1, 'Cloak of the Brood Lord'),
(14, 2, 'Master''s Cloak of Shadow Wrath'),
(14, 3, 'Amplifying Cloak'),
(14, 3, 'Sapphiron Drape'),
(14, 3, 'Spritecaster Cape'),
( 4, 1, 'Robe of Volatile Power'),
( 4, 2, 'Robe of the Void'),
( 4, 3, 'Nemesis Robes'),
( 4, 3, 'Robe of Winter Night'),
( 4, 3, 'Eternal Chestguard of Shadow Wrath'),
( 4, 3, 'Felcloth Robe'),
( 8, 1, 'Bracers of Arcane Accuracy'),
( 8, 2, 'Nemesis Bracers'),
( 8, 3, 'Master''s Bracers of Shadow Wrath'),
( 8, 3, 'Felheart Bracers'),
( 8, 3, 'Sublime Wristguards'),
( 9, 1, 'Ebony Flame Gloves'),
( 9, 2, 'Felcloth Gloves'),
( 9, 3, 'Hands of Power'),
( 9, 3, 'Nemesis Gloves'),
( 9, 3, 'Earth Warder''s Gloves'),
( 5, 1, 'Nemesis Belt'),
( 5, 2, 'Mana Igniting Cord'),
( 5, 3, 'Firemaw''s Clutch'),
( 5, 3, 'Sash of Whispered Secrets'),
( 5, 3, 'Angelista''s Grasp'),
( 5, 3, 'Ban''thok Sash'),
( 6, 1, 'Fel Infused Leggings'),
( 6, 2, 'Nemesis Leggings'),
( 6, 3, 'Skyshroud Leggings'),
( 6, 3, 'Felheart Pants'),
( 7, 1, 'Maleki''s Footwraps'),
( 7, 2, 'Snowblind Shoes'),
( 7, 3, 'Master''s Boots of Shadow Wrath'),
( 7, 3, 'Nemesis Boots'),
( 7, 3, 'Omnicast Boots'),
( 7, 3, 'Dragonrider Boots'),
(10, 1, 'Band of Forced Concentration'),
(10, 2, 'Band of Dark Dominion'),
(10, 3, 'Ring of Spell Power'),
(10, 3, 'Maiden''s Circle'),
(10, 3, 'Eye of Orgrimmar'),
(10, 3, 'Underworld Band'),
(12, 1, 'Neltharion''s Tear'),
(12, 2, 'Talisman of Ephemeral Power'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Royal Seal of Eldre''Thalas'),
(12, 3, 'Eye of the Beast'),
(12, 3, 'Burst of Knowledge'),
(15, 1, 'Staff of the Shadow Flame'),
(15, 2, 'Claw of Chromaggus'),
(15, 3, 'Azuresong Mageblade'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Shadow Wing Focus Staff'),
(15, 3, 'Sorcerous Dagger'),
(16, 1, 'Master Dragonslayer''s Orb'),
(16, 2, 'Eternal Rod of Shadow Wrath'),
(16, 3, 'Spirit of Aquementas'),
(17, 1, 'Skul''s Ghastly Touch'),
(17, 2, 'Lunar Wand of Shadow Wrath'),
(17, 3, 'Bonecreeper Stylus'),
(17, 3, 'Lethtendris''s Wand'),
(17, 3, 'Oblivion''s Touch');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 9 AND `spec` = 0 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 9, 0, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 9 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 9, 2, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
FROM `bis_seed_wowtbc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- VERIFICATION 1 - noms non resolus (aucune ligne = bon).
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wowtbc` s
LEFT JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE r.entry IS NULL;

-- VERIFICATION 2 - couverture obtenue.
SELECT `spec`, `slot`, `rank`, COUNT(*) AS objets FROM `playerbots_bis_item`
WHERE `class` = 9 AND `spec` IN (0,2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
