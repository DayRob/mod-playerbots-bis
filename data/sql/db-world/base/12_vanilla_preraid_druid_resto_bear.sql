-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Druide Restauration (11/2)
-- et Druide Farouche ours (11/10).
--
-- L'ours porte la specialisation 10, sentinelle du module : il partage l'onglet
-- de talents 1 avec le chat, et le module l'y aiguille quand le bot a la
-- strategie tank. Les deux listes vivent donc dans le meme fichier sans se
-- marcher dessus.
--
-- Ces deux combinaisons avaient deja une liste dans 03_vanilla_preraid.sql ;
-- celle-ci la remplace par une version plus fournie.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 03.
--
-- Le guide de l'ours ecarte lui-meme le PvP, pour la raison qui vaut ici : trop
-- long a obtenir. Les insignes de rang sont absents. Du cote Restauration, le
-- guide propose en revanche plusieurs pieces PvP - Dryad's Wrist Bindings, Lei
-- of the Lifegiver, Battle Healer's Cloak, les anneaux et pendentifs de
-- reputation - qui sont retirees ici comme partout ailleurs dans le projet.
--
-- ABSENTS : les objets a suffixe aleatoire, entres sous leur NOM DE BASE quand
-- le guide les met en avant - Atal'ai Spaulders, Slaghide Gauntlets, Abyssal
-- Leather Leggings, Atal'ai Gloves, Green Lens. Le bot visera la piece sans
-- exiger le bon suffixe.
--
-- SET BONUS IGNORE, comme pour le chat : le module raisonne piece par piece.
-- Le rang 1 revient a la meilleure piece individuellement - Slaghide Gauntlets
-- aux mains, Abyssal Leather Leggings aux jambes - et le cuir Devilsaur passe
-- en rang 2.
--
-- Gnomish Battle Chicken demande la specialisation gnome en ingenierie pour
-- etre utilise : rang 3, il ne sera jamais une cible.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Sources : guides Best-in-Slot Pre-Raid "Restoration Druid Healing" et
-- "Feral Druid Tank" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 11 AND `spec` IN (2, 10);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_druid`;
CREATE TEMPORARY TABLE `bis_seed_druid` (
    `spec`      TINYINT UNSIGNED NOT NULL,
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- Druide Restauration (spe 2), puis Druide Farouche ours (spe 10)
-- =====================================================================
INSERT INTO `bis_seed_druid` (`spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 2,  0, 0, 1, 'Insightful Hood'),
( 2,  0, 0, 2, 'Cassandra''s Grace'),
( 2,  0, 0, 2, 'Spellweaver''s Turban'),
( 2,  0, 0, 2, 'Tribal War Feathers'),
( 2,  0, 0, 2, 'Crimson Felt Hat'),
( 2,  0, 0, 3, 'Green Lens'),
( 2,  0, 0, 3, 'Holy Shroud'),
-- Cou (1)
( 2,  1, 0, 1, 'Animated Chain Necklace'),
( 2,  1, 0, 2, 'Tempest Talisman'),
( 2,  1, 0, 2, 'Tooth of Gnarr'),
-- Epaules (2)
( 2,  2, 0, 1, 'Living Shoulders'),
( 2,  2, 0, 2, 'Mantle of the Scarlet Crusade'),
( 2,  2, 0, 2, 'Burial Shawl'),
-- Torse (4)
( 2,  4, 0, 1, 'Robes of the Exalted'),
( 2,  4, 0, 2, 'Forest''s Embrace'),
( 2,  4, 0, 2, 'Living Breastplate'),
( 2,  4, 0, 2, 'Alanna''s Embrace'),
( 2,  4, 0, 2, 'Robe of Everlasting Night'),
( 2,  4, 0, 2, 'Chestplate of Tranquility'),
-- Ceinture (5)
( 2,  5, 0, 1, 'Whipvine Cord'),
( 2,  5, 0, 2, 'Sash of Mercy'),
( 2,  5, 0, 2, 'Eyestalk Cord'),
-- Jambes (6)
( 2,  6, 0, 1, 'Padre''s Trousers'),
( 2,  6, 0, 2, 'Senior Designer''s Pantaloons'),
( 2,  6, 0, 2, 'Ghoul Skin Leggings'),
-- Pieds (7)
( 2,  7, 0, 1, 'Faith Healer''s Boots'),
( 2,  7, 0, 2, 'Boots of the Full Moon'),
( 2,  7, 0, 2, 'Verdant Footpads'),
( 2,  7, 0, 2, 'Waterspout Boots'),
( 2,  7, 0, 2, 'Omnicast Boots'),
-- Poignets (8)
( 2,  8, 0, 1, 'Bracers of Prosperity'),
( 2,  8, 0, 2, 'Bleak Howler Armguards'),
( 2,  8, 0, 2, 'Flarecore Wraps'),
-- Mains (9)
( 2,  9, 0, 1, 'Hands of the Exalted Herald'),
( 2,  9, 0, 1, 'Atal''ai Gloves'),
( 2,  9, 0, 2, 'Gloves of Restoration'),
( 2,  9, 0, 2, 'Hands of Power'),
( 2,  9, 0, 2, 'Fallbrush Handgrips'),
( 2,  9, 0, 3, 'Mar Alom''s Grip'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
( 2, 10, 0, 1, 'Rosewine Circle'),
( 2, 10, 0, 1, 'Fordring''s Seal'),
( 2, 10, 0, 2, 'Band of Mending'),
( 2, 10, 0, 2, 'Emerald Flame Ring'),
( 2, 10, 0, 3, 'Maiden''s Circle'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
( 2, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
( 2, 12, 0, 2, 'Mindtap Talisman'),
( 2, 12, 0, 2, 'Briarwood Reed'),
( 2, 12, 0, 2, 'Second Wind'),
( 2, 12, 0, 2, 'Eye of the Beast'),
( 2, 12, 0, 2, 'Burst of Knowledge'),
-- Dos (14)
( 2, 14, 0, 1, 'Hide of the Wild'),
( 2, 14, 0, 2, 'Cloak of the Cosmos'),
-- Main droite (15)
( 2, 15, 0, 1, 'The Hammer of Grace'),
( 2, 15, 0, 2, 'Hammer of Revitalization'),
( 2, 15, 0, 2, 'Hand of Righteousness'),
( 2, 15, 0, 2, 'Energetic Rod'),
( 2, 15, 0, 3, 'Redemption'),
( 2, 15, 0, 3, 'Guiding Stave of Wisdom'),
( 2, 15, 0, 3, 'Moonshadow Stave'),
( 2, 15, 0, 3, 'Rod of the Ogre Magi'),
( 2, 15, 0, 3, 'Staff of Jordan'),
( 2, 15, 0, 3, 'Hammer of the Grand Crusader'),
-- Main gauche (16)
( 2, 16, 0, 1, 'Brightly Glowing Stone'),
( 2, 16, 0, 2, 'Tome of Divine Right'),
( 2, 16, 0, 2, 'Thaurissan''s Royal Scepter'),
( 2, 16, 0, 3, 'Beacon of Hope'),
-- Distance - idole (17)
( 2, 17, 0, 1, 'Idol of Rejuvenation'),
-- Tete (0)
(10,  0, 0, 1, 'Mask of the Unforgiven'),
(10,  0, 0, 2, 'Wolfshead Helm'),
(10,  0, 0, 2, 'Shadowcraft Cap'),
(10,  0, 0, 2, 'Tattered Leather Hood'),
(10,  0, 0, 2, 'Eye of Rend'),
-- Cou (1)
(10,  1, 0, 1, 'Beads of Ogre Might'),
(10,  1, 0, 2, 'Pendant of Celerity'),
(10,  1, 0, 2, 'Will of the Martyr'),
(10,  1, 0, 2, 'Mark of Fordring'),
-- Epaules (2)
(10,  2, 0, 1, 'Truestrike Shoulders'),
(10,  2, 0, 2, 'Atal''ai Spaulders'),
(10,  2, 0, 2, 'Flamescarred Shoulders'),
-- Torse (4)
(10,  4, 0, 1, 'Breastplate of Bloodthirst'),
(10,  4, 0, 2, 'Tombstone Breastplate'),
(10,  4, 0, 2, 'Feralheart Vest'),
(10,  4, 0, 2, 'Mixologist''s Tunic'),
(10,  4, 0, 2, 'Cadaverous Armor'),
(10,  4, 0, 2, 'Warbear Harness'),
-- Ceinture (5)
(10,  5, 0, 1, 'Cloudrunner Girdle'),
(10,  5, 0, 2, 'Frostbite Girdle'),
(10,  5, 0, 2, 'Girdle of Beastial Fury'),
(10,  5, 0, 2, 'Mugger''s Belt'),
(10,  5, 0, 2, 'Cadaverous Belt'),
-- Jambes (6)
(10,  6, 0, 1, 'Abyssal Leather Leggings'),
(10,  6, 0, 2, 'Devilsaur Leggings'),
(10,  6, 0, 2, 'Plaguehound Leggings'),
(10,  6, 0, 2, 'Cadaverous Leggings'),
(10,  6, 0, 2, 'Shadowcraft Pants'),
-- Pieds (7)
(10,  7, 0, 1, 'Boots of Ferocity'),
(10,  7, 0, 2, 'Pads of the Dread Wolf'),
(10,  7, 0, 2, 'Cadaverous Walkers'),
(10,  7, 0, 2, 'Feralheart Boots'),
(10,  7, 0, 3, 'Shadefiend Boots'),
-- Poignets (8)
(10,  8, 0, 1, 'Blackmist Armguards'),
(10,  8, 0, 2, 'Bracers of the Eclipse'),
(10,  8, 0, 2, 'Wristguards of Renown'),
(10,  8, 0, 2, 'Malefic Bracers'),
(10,  8, 0, 3, 'Cinderhide Armsplints'),
-- Mains (9)
(10,  9, 0, 1, 'Slaghide Gauntlets'),
(10,  9, 0, 2, 'Devilsaur Gauntlets'),
(10,  9, 0, 3, 'Gargoyle Slashers'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 10, 0, 1, 'Blackstone Ring'),
(10, 10, 0, 1, 'Myrmidon''s Signet'),
(10, 10, 2, 2, 'Thrall''s Resolve'),   -- Horde uniquement
(10, 10, 0, 2, 'Ring of Protection'),
(10, 10, 0, 2, 'Band of the Ogre King'),
(10, 10, 0, 2, 'Tarnished Elven Ring'),
(10, 10, 0, 2, 'Painweaver Band'),
(10, 10, 0, 3, 'Archaedic Stone'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(10, 12, 0, 1, 'Blackhand''s Breadth'),
(10, 12, 0, 1, 'Mark of Tyranny'),
(10, 12, 0, 2, 'Mark of the Chosen'),
(10, 12, 2, 2, 'Rune of the Guard Captain'),   -- Horde uniquement
(10, 12, 0, 2, 'Smoking Heart of the Mountain'),
(10, 12, 0, 3, 'Glimmering Mithril Insignia'),
(10, 12, 0, 3, 'Gnomish Battle Chicken'),
-- Dos (14)
(10, 14, 0, 1, 'Phantasmal Cloak'),
(10, 14, 0, 2, 'Stoneskin Gargoyle Cape'),
(10, 14, 0, 2, 'Stoneshield Cloak'),
(10, 14, 0, 2, 'Shroud of Domination'),
(10, 14, 0, 2, 'Cloak of Warding'),
-- Main droite (15)
(10, 15, 0, 1, 'Manual Crowd Pummeler'),
(10, 15, 0, 2, 'Unyielding Maul'),
(10, 15, 0, 2, 'Impervious Giant'),
(10, 15, 0, 2, 'Fist of Omokk'),
(10, 15, 0, 3, 'Bonecrusher'),
-- Distance - idole (17)
(10, 17, 0, 1, 'Idol of Brutality');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, s.`spec`, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_druid` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`spec`, s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_druid` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`spec`, s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_druid` s
JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE NOT (
       (s.`slot` =  0 AND it.`InventoryType` = 1)
    OR (s.`slot` =  1 AND it.`InventoryType` = 2)
    OR (s.`slot` =  2 AND it.`InventoryType` = 3)
    OR (s.`slot` =  4 AND it.`InventoryType` IN (5, 20))
    OR (s.`slot` =  5 AND it.`InventoryType` = 6)
    OR (s.`slot` =  6 AND it.`InventoryType` = 7)
    OR (s.`slot` =  7 AND it.`InventoryType` = 8)
    OR (s.`slot` =  8 AND it.`InventoryType` = 9)
    OR (s.`slot` =  9 AND it.`InventoryType` = 10)
    OR (s.`slot` IN (10, 11) AND it.`InventoryType` = 11)
    OR (s.`slot` IN (12, 13) AND it.`InventoryType` = 12)
    OR (s.`slot` = 14 AND it.`InventoryType` = 16)
    OR (s.`slot` = 15 AND it.`InventoryType` IN (13, 17, 21))
    OR (s.`slot` = 16 AND it.`InventoryType` IN (13, 14, 22, 23))
    OR (s.`slot` = 17 AND it.`InventoryType` IN (15, 25, 26, 28))
);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_druid`;
