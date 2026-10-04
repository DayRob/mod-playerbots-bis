-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P2 BWL (icy-veins). Classe 11, spe 0, palier 30.
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
( 0, 2, 'Eternal Crown of Arcane Wrath'),
( 0, 3, 'Crimson Felt Hat'),
( 0, 3, 'Spellpower Goggles Xtreme Plus'),
( 0, 3, 'Cap of the Scarlet Savant'),
( 1, 1, 'Choker of the Fire Lord'),
( 1, 2, 'Diana''s Pearl Necklace'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Star of Mystaria'),
( 1, 3, 'Beads of Ogre Mojo'),
( 1, 3, 'Tempest Talisman'),
( 2, 1, 'Mantle of the Blackwing Cabal'),
( 2, 2, 'Eternal Spaulders of Arcane Wrath'),
( 2, 3, 'Burial Shawl'),
( 2, 3, 'Kentic Amice'),
( 2, 3, 'Cyclone Spaulders'),
(14, 1, 'Cloak of the Brood Lord'),
(14, 2, 'Master''s Cloak of Arcane Wrath'),
(14, 3, 'Amplifying Cloak'),
(14, 3, 'Shroud of Arcane Mastery'),
(14, 3, 'Sapphiron Drape'),
(14, 3, 'Spritecaster Cape'),
( 4, 1, 'Robe of Volatile Power'),
( 4, 2, 'Eternal Chestguard of Arcane Wrath'),
( 4, 3, 'Robe of Everlasting Night'),
( 4, 3, 'Chestplate of Tranquility'),
( 4, 3, 'Alanna''s Embrace'),
( 4, 3, 'Robes of the Royal Crown'),
( 8, 1, 'Bracers of Arcane Accuracy'),
( 8, 2, 'Master''s Bracers of Arcane Wrath'),
( 8, 3, 'Sublime Wristguards'),
( 8, 3, 'Blacklight Bracer'),
( 8, 3, 'Orphic Bracers'),
( 9, 1, 'Hands of Power'),
( 9, 2, 'Adventurer''s Gloves of Arcane Wrath'),
( 9, 3, 'Earth Warder''s Gloves'),
( 9, 3, 'Bloodfire Talons'),
( 9, 3, 'Dreamweave Gloves'),
( 9, 3, 'Ogreseer Fists'),
( 5, 1, 'Mana Igniting Cord'),
( 5, 2, 'Firemaw''s Clutch'),
( 5, 3, 'Angelista''s Grasp'),
( 5, 3, 'Adventurer''s Belt of Arcane Wrath'),
( 5, 3, 'Ban''thok Sash'),
( 5, 3, 'Flayed Doomguard Belt'),
( 6, 1, 'Adventurer''s Legguards of Arcane Wrath'),
( 6, 2, 'Leggings of Arcane Supremacy'),
( 6, 3, 'Skyshroud Leggings'),
( 7, 1, 'Waterspout Boots'),
( 7, 2, 'Master''s Boots of Arcane Wrath'),
( 7, 3, 'Snowblind Shoes'),
( 7, 3, 'Omnicast Boots'),
( 7, 3, 'Dragonrider Boots'),
(10, 1, 'Band of Forced Concentration'),
(10, 2, 'Ring of Spell Power'),
(10, 3, 'Maiden''s Circle'),
(10, 3, 'Eye of Orgrimmar'),
(10, 3, 'Ring of Entropy'),
(12, 1, 'Neltharion''s Tear'),
(12, 2, 'Talisman of Ephemeral Power'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Eye of the Beast'),
(12, 3, 'Burst of Knowledge'),
(12, 3, 'Shard of the Scale'),
(15, 1, 'Lok''amir il Romathis'),
(15, 2, 'Staff of the Shadow Flame'),
(15, 3, 'Claw of Chromaggus'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Staff of Dominance'),
(15, 3, 'Aurastone Hammer'),
(16, 1, 'Master Dragonslayer''s Orb'),
(16, 2, 'Eternal Rod of Arcane Wrath'),
(16, 3, 'Spirit of Aquementas'),
(16, 3, 'Fire Runed Grimoire'),
(16, 3, 'Orb of the Forgotten Seer');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 11 AND `spec` = 0 AND `tier_id` = 30;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 0, s.`slot`, 0, 30, r.entry, s.`rank`,
       CONCAT('Vanilla P2 BWL (icy-veins) - ', s.`item_name`)
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
WHERE `class` = 11 AND `spec` IN (0) AND `tier_id` = 30
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
