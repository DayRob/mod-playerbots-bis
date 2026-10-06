-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 5, spe 2, palier 30.
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
( 0, 2, 'Felcloth Hood', NULL),
( 0, 3, 'Crimson Felt Hat', NULL),
( 0, 3, 'Spellpower Goggles Xtreme Plus', NULL),
( 1, 1, 'Choker of the Fire Lord', NULL),
( 1, 2, 'Dark Advisor''s Pendant', NULL),
( 1, 3, 'Choker of Enlightenment', NULL),
( 1, 3, 'Beads of Ogre Mojo', NULL),
( 1, 3, 'Anastari Heirloom', NULL),
( 1, 3, 'Star of Mystaria', NULL),
( 2, 1, 'Mantle of the Blackwing Cabal', NULL),
( 2, 2, 'Felcloth Shoulders', NULL),
( 2, 3, 'Burial Shawl', NULL),
( 2, 3, 'Shadoweave Shoulders', NULL),
(14, 1, 'Cloak of the Brood Lord', NULL),
(14, 2, 'Amplifying Cloak', NULL),
(14, 3, 'Sapphiron Drape', NULL),
(14, 3, 'Spritecaster Cape', NULL),
( 4, 1, 'Robe of Winter Night', NULL),
( 4, 2, 'Felcloth Robe', NULL),
( 4, 3, 'Robe of Everlasting Night', NULL),
( 4, 3, 'Robe of Volatile Power', NULL),
( 4, 3, 'Robe of the Magi', NULL),
( 8, 1, 'Bracers of Arcane Accuracy', NULL),
( 8, 2, 'Sublime Wristguards', NULL),
( 8, 3, 'Shadowy Bracers', NULL),
( 8, 3, 'Blacklight Bracer', NULL),
( 9, 1, 'Ebony Flame Gloves', NULL),
( 9, 2, 'Felcloth Gloves', NULL),
( 9, 3, 'Hands of Power', NULL),
( 9, 3, 'Earth Warder''s Gloves', NULL),
( 9, 3, 'Gloves of Shadowy Mist', NULL),
( 5, 1, 'Firemaw''s Clutch', NULL),
( 5, 2, 'Sash of Whispered Secrets', NULL),
( 5, 3, 'Mana Igniting Cord', NULL),
( 5, 3, 'Ban''thok Sash', NULL),
( 5, 3, 'Angelista''s Grasp', NULL),
( 6, 1, 'Flarecore Leggings', NULL),
( 6, 2, 'Fel Infused Leggings', NULL),
( 6, 3, 'Skyshroud Leggings', NULL),
( 6, 3, 'Felcloth Pants', NULL),
( 6, 3, 'Spellshock Leggings', NULL),
( 7, 1, 'Maleki''s Footwraps', NULL),
( 7, 2, 'Snowblind Shoes', NULL),
( 7, 3, 'Omnicast Boots', NULL),
( 7, 3, 'Dragonrider Boots', NULL),
(10, 1, 'Band of Dark Dominion', NULL),
(10, 2, 'Ring of Spell Power', NULL),
(10, 3, 'Band of Forced Concentration', NULL),
(10, 3, 'Ring of Blackrock', NULL),
(10, 3, 'Eye of Orgrimmar', NULL),
(10, 3, 'Maiden''s Circle', NULL),
(12, 1, 'Neltharion''s Tear', NULL),
(12, 2, 'Talisman of Ephemeral Power', NULL),
(12, 3, 'Briarwood Reed', NULL),
(12, 3, 'Burst of Knowledge', NULL),
(12, 3, 'Eye of the Beast', NULL),
(12, 3, 'Shard of the Scale', NULL),
(15, 1, 'Lok''amir il Romathis', NULL),
(15, 2, 'Claw of Chromaggus', NULL),
(15, 3, 'Staff of the Shadow Flame', NULL),
(15, 3, 'Anathema', NULL),
(15, 3, 'Fang of the Mystics', NULL),
(15, 3, 'Aurastone Hammer', NULL),
(16, 1, 'Master Dragonslayer''s Orb', NULL),
(16, 2, 'Spirit of Aquementas', NULL),
(16, 3, 'Umbral Crystal', NULL),
(17, 1, 'Skul''s Ghastly Touch', NULL),
(17, 2, 'Bonecreeper Stylus', NULL),
(17, 3, 'Lethtendris''s Wand', NULL),
(17, 3, 'Oblivion''s Touch', NULL);

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 2 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 2, s.`slot`, 0, 30, COALESCE(s.`entry`, r.entry), s.`rank`,
       CONCAT('Vanilla P3 BWL (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 5 AND `spec` IN (2) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
