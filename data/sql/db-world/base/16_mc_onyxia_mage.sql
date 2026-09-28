-- mod-playerbots-bis : palier 20 (Vanilla Phase 1 - MC / Onyxia) - Mage (classe 8).
--
-- Les trois specialisations partagent la meme liste, comme au pre-raid : en
-- phase 1 elles courent toutes apres puissance des sorts, critique et toucher.
--
-- POURQUOI CE FICHIER : le palier 20 n'avait jamais ete relu, ses lignes
-- venant telles quelles de 02_playerbots_bis_item.sql. Confronte au guide, il
-- manquait TROIS pieces du Tier 1 mage - Arcanist Crown, Arcanist Bindings,
-- Arcanist Gloves - et deux creneaux portaient un objet PvP en rang 1.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 02 et 05.
--
-- PvP ET REPUTATIONS ECARTES, comme partout. Ce guide en est truffe, et la
-- regle redistribue beaucoup : le guide donne un objet de rang d'honneur en
-- MEILLEUR aux epaules, aux pieds et en main gauche. Les rangs 1 y reviennent
-- donc au meilleur objet accessible - Boreal Mantle, Snowblind Shoes,
-- Drakestone. Sont absents : les pieces de soie de lieutenant-commandant et de
-- capitaine-chevalier (rangs 7, 8 et 10), Tome of the Ice Lord (exalte
-- Alterac) et la baguette des heros de Stormpike.
--
-- ARTISANAT EN RANG 2 : un bot ne monte pas un metier. Robe of the Archmage,
-- que le guide juge imbattable au torse, passe donc derriere Robe of Volatile
-- Power. Meme chose pour les pieces Frostweave.
--
-- Green Lens demande l'ingenierie pour etre PORTE : rang 3.
--
-- OBJETS A SUFFIXE ALEATOIRE ("... de la Colere Glacee") entres sous leur NOM
-- DE BASE : Archivist Cape, Flameweave Cuffs, Tearfall Bracers, Drakestone.
--
-- Le guide entier est repris, y compris les drops monde a suffixe aleatoire de
-- la serie "Master's" et "Eternal", entres sous leur nom de base. Ce sont des
-- replis, jamais des cibles, mais ils expliquent ce qu'un bot porte deja.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Wowhead Classic "Mage DPS - Equipement P2 BiS".

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 8 AND `spec` IN (0, 1, 2);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_mage_mc`;
CREATE TEMPORARY TABLE `bis_seed_mage_mc` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_mage_mc` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Arcanist Crown'),
( 0, 0, 2, 'Netherwind Crown'),
( 0, 0, 2, 'Eternal Crown'),
( 0, 0, 3, 'Green Lens'),
-- Cou (1)
( 1, 0, 1, 'Choker of the Fire Lord'),
( 1, 0, 2, 'Choker of Enlightenment'),
( 1, 0, 2, 'Star of Mystaria'),
-- Epaules (2) - le meilleur du guide est un rang 10 d'honneur
( 2, 0, 1, 'Boreal Mantle'),
( 2, 0, 2, 'Eternal Spaulders'),
( 2, 0, 2, 'Burial Shawl'),
-- Torse (4)
( 4, 0, 1, 'Robe of Volatile Power'),
( 4, 0, 2, 'Robe of the Archmage'),
( 4, 0, 2, 'Freezing Lich Robes'),
( 4, 0, 2, 'Master''s Vest'),
-- Taille (5)
( 5, 0, 1, 'Mana Igniting Cord'),
( 5, 0, 2, 'Ban''thok Sash'),
( 5, 0, 2, 'Clutch of Andros'),
( 5, 0, 2, 'Thuzadin Sash'),
-- Jambes (6)
( 6, 0, 1, 'Netherwind Pants'),
( 6, 0, 2, 'Skyshroud Leggings'),
( 6, 0, 2, 'Arcanist Leggings'),
( 6, 0, 2, 'Frostweave Pants'),
-- Pieds (7) - le meilleur du guide est un rang 7 d'honneur
( 7, 0, 1, 'Snowblind Shoes'),
( 7, 0, 2, 'Master''s Boots'),
( 7, 0, 2, 'Omnicast Boots'),
-- Poignets (8)
( 8, 0, 1, 'Arcanist Bindings'),
( 8, 0, 2, 'Tearfall Bracers'),
( 8, 0, 2, 'Flameweave Cuffs'),
( 8, 0, 2, 'Sublime Wristguards'),
( 8, 0, 2, 'Master''s Bracers'),
-- Mains (9)
( 9, 0, 1, 'Arcanist Gloves'),
( 9, 0, 2, 'Hands of Power'),
( 9, 0, 2, 'Frostweave Gloves'),
( 9, 0, 2, 'Earth Warder''s Gloves'),
-- Anneaux (10) - le module apparie lui-meme le second doigt
(10, 0, 1, 'Ring of Spell Power'),
(10, 0, 2, 'Freezing Band'),
(10, 0, 2, 'Maiden''s Circle'),
(10, 1, 2, 'Songstone of Ironforge'),
(10, 2, 2, 'Eye of Orgrimmar'),
-- Bijoux (12) - le guide en donne deux en tete
(12, 0, 1, 'Talisman of Ephemeral Power'),
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 2, 'Eye of the Beast'),
(12, 0, 2, 'Burst of Knowledge'),
-- Dos (14)
(14, 0, 1, 'Archivist Cape'),
(14, 0, 2, 'Sapphiron Drape'),
(14, 0, 2, 'Master''s Cloak'),
-- Main droite (15) - une main et deux mains cohabitent
(15, 0, 1, 'Azuresong Mageblade'),
(15, 0, 2, 'Fang of the Mystics'),
(15, 0, 2, 'Staff of Dominance'),
(15, 0, 2, 'Witchblade'),
(15, 0, 2, 'Bloodstrike Dagger'),
(15, 0, 2, 'Rod of the Ogre Magi'),
(15, 0, 2, 'Solstice Staff'),
-- Main gauche (16) - le meilleur du guide est un exalte Alterac
(16, 0, 1, 'Drakestone'),
(16, 0, 2, 'Spirit of Aquementas'),
-- Distance - baguette (17)
(17, 0, 1, 'Cold Snap'),
(17, 0, 2, 'Bonecreeper Stylus'),
(17, 0, 2, 'Lunar Wand'),
(17, 0, 2, 'Icefury Wand');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 8, specs.`spec`, s.`slot`, s.`faction`, 20, r.entry, s.`rank`,
       CONCAT('Vanilla P1 MC/Ony - ', s.`item_name`)
FROM `bis_seed_mage_mc` s
JOIN (SELECT 0 AS `spec` UNION ALL SELECT 1 UNION ALL SELECT 2) specs
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_mage_mc` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_mage_mc` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_mage_mc`;
