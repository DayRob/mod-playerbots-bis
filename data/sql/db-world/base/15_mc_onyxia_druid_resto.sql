-- mod-playerbots-bis : palier 20 (Vanilla Phase 1 - MC / Onyxia)
-- Druide Restauration (11/2).
--
-- POURQUOI CE FICHIER : contrairement au pre-raid, le palier 20 n'avait jamais
-- ete relu. Les lignes venaient telles quelles de 02_playerbots_bis_item.sql,
-- qui n'est qu'une conversion mecanique de la table playerbots_bis_gear de
-- mod-playerbots. 05_vanilla_mc_onyxia.sql n'a couvert que sept combinaisons -
-- guerrier Armes et Fureur, les trois voleurs, pretre Discipline et Sacre -
-- et aucun druide.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 02 et 05.
--
-- PvP ET REPUTATIONS ECARTES, comme partout : Lei of the Lifegiver (exalte
-- Alterac), Warden's Cloak et Battle Healer's Cloak (honore Ailes d'Argent /
-- Chanteguerre), Stormpike Cloth Belt. Le guide donne pourtant Lei of the
-- Lifegiver en tete de la main gauche.
--
-- ARTISANAT EN RANG 2, comme dans les listes pre-raid : un bot ne monte pas un
-- metier. Cela deplace Hide of the Wild, que le guide juge meilleur dos, au
-- profit de Drape of Benediction.
--
-- Green Lens demande l'ingenierie pour etre PORTE : rang 3, jamais une cible.
--
-- BOSS DE MONDE CONSERVES EN RANG 1 : Azuregos donne la couronne et la cape.
-- Contrairement a une reputation, c'est a la portee d'un raid de quarante, donc
-- la piece reste une cible legitime.
--
-- ABSENT VOLONTAIREMENT : le guide range "Hand of Justice" parmi les armes a
-- une main alors que c'est un bijou, et donne une source qui ne correspond pas.
-- Je ne tranche pas a sa place, la ligne est laissee de cote.
--
-- CRENEAU 17 (idole) : le guide n'en propose aucune a cette phase. Aucune ligne
-- ici, et c'est voulu : le module retient par creneau le palier le plus haut
-- QU'IL TROUVE, donc l'idole pre-raid reste la cible. L'echelle se degrade
-- toute seule au lieu de laisser le creneau vide.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Wowhead Classic "Druide Soigneur - Equipement P2 BiS".

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 11 AND `spec` = 2;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_resto_mc`;
CREATE TEMPORARY TABLE `bis_seed_resto_mc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_resto_mc` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Crystal Adorned Crown'),
( 0, 0, 2, 'Stormrage Cover'),
( 0, 0, 2, 'Insightful Hood'),
( 0, 0, 2, 'Tribal War Feathers'),
( 0, 0, 2, 'Cassandra''s Grace'),
( 0, 0, 3, 'Green Lens'),
-- Cou (1)
( 1, 0, 1, 'Choker of the Fire Lord'),
( 1, 0, 2, 'Animated Chain Necklace'),
( 1, 0, 2, 'Tooth of Gnarr'),
-- Epaules (2)
( 2, 0, 1, 'Wild Growth Spaulders'),
( 2, 0, 2, 'Cenarion Spaulders'),
( 2, 0, 2, 'Living Shoulders'),
( 2, 0, 2, 'Burial Shawl'),
-- Torse (4)
( 4, 0, 1, 'Robes of the Exalted'),
( 4, 0, 2, 'Robe of Volatile Power'),
( 4, 0, 2, 'Cenarion Vestments'),
( 4, 0, 2, 'Chestplate of Tranquility'),
( 4, 0, 2, 'Alanna''s Embrace'),
-- Taille (5)
( 5, 0, 1, 'Sash of Mercy'),
( 5, 0, 2, 'Whipvine Cord'),
( 5, 0, 2, 'Eyestalk Cord'),
( 5, 0, 2, 'Flayed Doomguard Belt'),
-- Jambes (6)
( 6, 0, 1, 'Salamander Scale Pants'),
( 6, 0, 2, 'Stormrage Legguards'),
( 6, 0, 2, 'Padre''s Trousers'),
( 6, 0, 2, 'Senior Designer''s Pantaloons'),
( 6, 0, 2, 'Ghoul Skin Leggings'),
( 6, 0, 2, 'Cenarion Leggings'),
-- Pieds (7)
( 7, 0, 1, 'Verdant Footpads'),
( 7, 0, 2, 'Snowblind Shoes'),
( 7, 0, 2, 'Cenarion Boots'),
( 7, 0, 2, 'Boots of the Full Moon'),
( 7, 0, 2, 'Waterspout Boots'),
-- Poignets (8)
( 8, 0, 1, 'Bracers of Prosperity'),
( 8, 0, 2, 'Flameweave Cuffs'),
( 8, 0, 2, 'Bleak Howler Armguards'),
( 8, 0, 2, 'Sublime Wristguards'),
( 8, 0, 2, 'Cenarion Bracers'),
-- Mains (9)
( 9, 0, 1, 'Gloves of Restoration'),
( 9, 0, 2, 'Hands of the Exalted Herald'),
( 9, 0, 2, 'Hands of Power'),
( 9, 0, 2, 'Cenarion Gloves'),
-- Anneaux (10) - le module apparie lui-meme le second doigt
(10, 0, 1, 'Cauterizing Band'),
(10, 0, 2, 'Seal of Fordring'),
(10, 0, 2, 'Rosewine Circle'),
(10, 0, 2, 'Maiden''s Circle'),
(10, 1, 2, 'Songstone of Ironforge'),
(10, 2, 2, 'Eye of Orgrimmar'),
(10, 0, 2, 'Emerald Flame Ring'),
-- Bijoux (12) - idem pour le second emplacement
(12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 2, 'Shard of the Scale'),
(12, 0, 2, 'Second Wind'),
(12, 0, 2, 'Mindtap Talisman'),
-- Dos (14)
(14, 0, 1, 'Drape of Benediction'),
(14, 0, 2, 'Hide of the Wild'),
(14, 0, 2, 'Archivist Cape'),
(14, 0, 2, 'Cloak of the Cosmos'),
-- Main droite (15) - une main et deux mains cohabitent
(15, 0, 1, 'Aurastone Hammer'),
(15, 0, 2, 'The Hammer of Grace'),
(15, 0, 2, 'Staff of Dominance'),
(15, 0, 2, 'Guiding Stave of Wisdom'),
(15, 0, 2, 'Energetic Rod'),
-- Main gauche (16)
(16, 0, 1, 'Brightly Glowing Stone'),
(16, 0, 2, 'Thaurissan''s Royal Scepter');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 2, s.`slot`, s.`faction`, 20, r.entry, s.`rank`,
       CONCAT('Vanilla P1 MC/Ony - ', s.`item_name`)
FROM `bis_seed_resto_mc` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_resto_mc` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_resto_mc` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_resto_mc`;
