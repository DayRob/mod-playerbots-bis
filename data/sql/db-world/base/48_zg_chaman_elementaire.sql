-- mod-playerbots-bis : GENERE par tools/convert_wowtbc_bis.py
-- Source : Vanilla P4 ZG (wowtbc.gg). Classe 7, spe 0, palier 40.
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
( 0, 2, 'The Hexxer''s Cover'),
( 0, 3, 'Crimson Felt Hat'),
( 0, 3, 'Bloodvine Goggles'),
( 0, 3, 'Spellpower Goggles Xtreme Plus'),
( 1, 1, 'Choker of the Fire Lord'),
( 1, 2, 'Jeklik''s Opaline Talisman'),
( 1, 3, 'Diana''s Pearl Necklace'),
( 1, 3, 'Choker of Enlightenment'),
( 1, 3, 'Barbed Thorn Necklace'),
( 1, 3, 'Beads of Ogre Mojo'),
( 2, 1, 'Deep Earth Spaulders'),
( 2, 2, 'Mantle of the Blackwing Cabal'),
( 2, 3, 'Burial Shawl'),
( 2, 3, 'Denwatcher''s Shoulders'),
(14, 1, 'Cloak of Consumption'),
(14, 2, 'Cloak of the Brood Lord'),
(14, 3, 'Cloak of the Hakkari Worshipers'),
(14, 3, 'Amplifying Cloak'),
(14, 3, 'Sapphiron Drape'),
( 4, 1, 'Bloodvine Vest'),
( 4, 2, 'Jade Inlaid Vestments'),
( 4, 3, 'Zandalar Augur''s Hauberk'),
( 4, 3, 'Robe of Volatile Power'),
( 4, 3, 'Wildthorn Mail'),
( 8, 1, 'Bracers of Arcane Accuracy'),
( 8, 2, 'Black Bark Wristbands'),
( 8, 3, 'Zandalar Augur''s Bracers'),
( 8, 3, 'Sublime Wristguards'),
( 9, 1, 'Bloodtinged Gloves'),
( 9, 2, 'Gloves of Delusional Power'),
( 9, 3, 'Hands of Power'),
( 9, 3, 'Earth Warder''s Gloves'),
( 9, 3, 'Storm Gauntlets'),
( 5, 1, 'Firemaw''s Clutch'),
( 5, 2, 'Mana Igniting Cord'),
( 5, 3, 'Belt of Untapped Power'),
( 5, 3, 'Sash of the Windreaver'),
( 5, 3, 'Flayed Doomguard Belt'),
( 5, 3, 'Ban''thok Sash'),
( 6, 1, 'Bloodvine Leggings'),
( 6, 2, 'Legplates of Ten Storms'),
( 6, 3, 'Skyshroud Leggings'),
( 7, 1, 'Bloodvine Boots'),
( 7, 2, 'Boots of Fright'),
( 7, 3, 'Snowblind Shoes'),
( 7, 3, 'Betrayer''s Boots'),
( 7, 3, 'Malignant Footguards'),
(10, 1, 'Band of Forced Concentration'),
(10, 2, 'Ring of Spell Power'),
(10, 3, 'Mindtear Band'),
(10, 3, 'Band of Servitude'),
(10, 3, 'Zanzil''s Seal'),
(10, 3, 'Ring of Blackrock'),
(12, 1, 'Neltharion''s Tear'),
(12, 2, 'Natural Alignment Crystal'),
(12, 3, 'Talisman of Ephemeral Power'),
(12, 3, 'Zandalarian Hero Charm'),
(12, 3, 'Briarwood Reed'),
(12, 3, 'Royal Seal of Eldre''Thalas'),
(15, 1, 'Lok''amir il Romathis'),
(15, 2, 'Staff of the Shadow Flame'),
(15, 3, 'Claw of Chromaggus'),
(15, 3, 'Fang of the Mystics'),
(15, 3, 'Shadow Wing Focus Staff'),
(16, 1, 'Jin''do''s Bag of Whammies'),
(16, 2, 'Master Dragonslayer''s Orb'),
(16, 3, 'Spirit of Aquementas'),
(16, 3, 'Fire Runed Grimoire'),
(16, 3, 'Orb of the Forgotten Seer');

-- REMPLACE : la liste existante de ce couple classe/spe/palier part
-- d'abord. Sans ca elle coexisterait avec celle-ci, et un creneau
-- se retrouverait avec deux objets de rang 1 - ce que l'echelle ne
-- sait pas departager.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 7 AND `spec` = 0 AND `tier_id` = 40;

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 7, 0, s.`slot`, 0, 40, r.entry, s.`rank`,
       CONCAT('Vanilla P4 ZG (wowtbc.gg) - ', s.`item_name`)
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
WHERE `class` = 7 AND `spec` IN (0) AND `tier_id` = 40
GROUP BY `spec`, `slot`, `rank` ORDER BY `spec`, `slot`, `rank`;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wowtbc`;
