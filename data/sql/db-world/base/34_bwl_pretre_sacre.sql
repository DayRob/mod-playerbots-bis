-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P3 BWL (wowtbc.gg). Classe 5, spe 1, palier 30.
-- Les rangs viennent de l'ordre d'apparition dans la page.
-- PvP et reputation ecartes a la generation.

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
CREATE TEMPORARY TABLE `bis_seed_wowtbc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `rank`      TINYINT UNSIGNED NOT NULL,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_wowtbc` (`slot`, `rank`, `item_name`) VALUES
( 0, 1, 'Halo of Transcendence'),
( 0, 2, 'Crystal Adorned Crown'),
( 0, 3, 'Mish''undare, Circlet of the Mind Flayer'),
( 0, 3, 'Cassandra''s Grace'),
( 0, 3, 'Circlet of Prophecy'),
( 1, 1, 'Animated Chain Necklace'),
( 1, 2, 'Choker of the Fire Lord'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Beads of Ogre Mojo'),
( 1, 3, 'Lady Maye''s Pendant'),
( 1, 3, 'Jeweled Amulet of Cainwyn'),
( 2, 1, 'Pauldrons of Transcendence'),
( 2, 2, 'Mantle of the Blackwing Cabal'),
( 2, 3, 'Mantle of Prophecy'),
( 2, 3, 'Burial Shawl'),
( 2, 3, 'Sunderseer Mantle'),
(14, 1, 'Hide of the Wild'),
(14, 2, 'Drape of Benediction'),
(14, 3, 'Shroud of Pure Thought'),
(14, 3, 'Cloak of the Cosmos'),
( 4, 1, 'Truefaith Vestments'),
( 4, 2, 'Robes of Transcendence'),
( 4, 3, 'Robes of the Exalted'),
( 4, 3, 'Robes of Prophecy'),
( 4, 3, 'Alanna''s Embrace'),
( 4, 3, 'Robe of Volatile Power'),
( 8, 1, 'Bindings of Transcendence'),
( 8, 2, 'Vambraces of Prophecy'),
( 8, 3, 'Sublime Wristguards'),
( 8, 3, 'Wyrmthalak''s Shackles'),
( 9, 1, 'Handguards of Transcendence'),
( 9, 2, 'Hands of the Exalted Herald'),
( 9, 3, 'Gloves of Prophecy'),
( 9, 3, 'Hands of Power'),
( 9, 3, 'Greenleaf Handwraps'),
( 5, 1, 'Firemaw''s Clutch'),
( 5, 2, 'Belt of Transcendence'),
( 5, 3, 'Whipvine Cord'),
( 5, 3, 'Mana Igniting Cord'),
( 5, 3, 'Girdle of Prophecy'),
( 6, 1, 'Empowered Leggings'),
( 6, 2, 'Leggings of Transcendence'),
( 6, 3, 'Senior Designer''s Pantaloons'),
( 6, 3, 'Padre''s Trousers'),
( 6, 3, 'Pants of Prophecy'),
( 7, 1, 'Boots of Pure Thought'),
( 7, 2, 'Boots of Transcendence'),
( 7, 3, 'Boots of Prophecy'),
( 7, 3, 'Boots of the Full Moon'),
( 7, 3, 'Snowblind Shoes'),
( 7, 3, 'Wolfrunner Shoes'),
(10, 1, 'Pure Elementium Band'),
(10, 2, 'Cauterizing Band'),
(10, 3, 'Fordring''s Seal'),
(10, 3, 'Rosewine Circle'),
(10, 3, 'Ring of Spell Power'),
(10, 3, 'Emerald Flame Ring'),
(12, 1, 'Rejuvenating Gem'),
(12, 2, 'Blessed Prayer Beads'),
(12, 3, 'Talisman of Ephemeral Power'),
(12, 3, 'Royal Seal of Eldre''Thalas'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Second Wind'),
(15, 1, 'Benediction'),
(15, 2, 'Lok''amir il Romathis'),
(15, 3, 'Claw of Chromaggus'),
(15, 3, 'Staff of the Shadow Flame'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Aurastone Hammer'),
(16, 1, 'Brightly Glowing Stone'),
(16, 2, 'Master Dragonslayer''s Orb'),
(16, 3, 'Thaurissan''s Royal Scepter'),
(17, 1, 'Bonecreeper Stylus'),
(17, 3, 'Lethtendris''s Wand'),
(17, 3, 'Oblivion''s Touch');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 5 AND `spec` = 1 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 5, 1, s.`slot`, 0, 30, r.entry, s.`rank`,
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
WHERE `class` = 5 AND `spec` IN (1) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
