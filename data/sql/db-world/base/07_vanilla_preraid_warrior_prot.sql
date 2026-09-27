-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Guerrier Protection (1/2).
--
-- Complete 04_vanilla_preraid_wowsims.sql, qui ne donne qu'un objet par creneau
-- pour cette combinaison.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 03 ET 04, tous deux couvrant 1/2. Rejouer
-- l'un des deux ensuite effacerait ces lignes.
--
-- CLASSEMENT : le rang 1 reprend la liste "Realistic First Raid Goal" du guide,
-- celle qu'on obtient en donjon. Ce qui est verrouille derriere une reputation
-- exaltee, un rang PvP ou la chaine T0.5 est classe 2, meme quand le guide le
-- donne comme meilleur objet : un bot ne fera jamais Alterac Valley jusqu'a
-- exalte ni la chaine T0.5, et le laisser en rang 1 rendrait son creneau
-- eternellement incomplet dans la fenetre d'etat.
--
-- LE CHOIX D'ARME EST APLATI : le guide trie les armes par race, parce que la
-- specialisation d'arme d'un Humain ou d'un Orc decide du type a porter. La
-- table n'a pas de dimension race - seulement classe / spe / faction - donc
-- toutes les armes sont rangees ensemble par priorite. Le module choisira selon
-- ce que le bot peut porter.
--
-- Le bouclier occupe l'emplacement 16 : les dagues de main gauche du guide, qui
-- supposent un tank en double arme, sont volontairement absentes.
--
-- Les identifiants sont resolus par nom contre item_template a l'import ; les
-- requetes de verification en fin de fichier listent ce qui n'a pas ete resolu.
--
-- "Abyssal Plate Legplates" du guide Classic s'appelle "Abyssal Plate Legguards"
-- en WotLK, et c'est ce nom-la qui est utilise ici.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Warrior Tank" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 1 AND `spec` = 2;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_prot`;
CREATE TEMPORARY TABLE `bis_seed_prot` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_prot` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Helm of the Executioner'),
( 0, 0, 2, 'Helm of Heroism'),
( 0, 0, 2, 'Lionheart Helm'),
( 0, 0, 2, 'Crown of Tyranny'),
( 0, 0, 2, 'Helm of Valor'),
( 0, 0, 2, 'Golem Skull Helm'),
( 0, 0, 2, 'Helm of Awareness'),
( 0, 0, 3, 'Avenguard Helm'),
-- Cou (1)
( 1, 0, 1, 'Will of the Martyr'),
( 1, 0, 2, 'Beads of Ogre Might'),
( 1, 0, 2, 'Mark of Fordring'),
( 1, 0, 2, 'Pendant of Celerity'),
-- Epaules (2)
( 2, 0, 1, 'Spaulders of Valor'),
( 2, 0, 2, 'Spaulders of Heroism'),
( 2, 0, 2, 'Stockade Pauldrons'),
( 2, 0, 2, 'Slamshot Shoulders'),
( 2, 0, 2, 'Ebonsteel Spaulders'),
-- Torse (4)
( 4, 0, 1, 'Breastplate of Valor'),
( 4, 0, 2, 'Breastplate of Heroism'),
( 4, 0, 2, 'Savage Gladiator Chain'),
( 4, 0, 2, 'Breastplate of the Chromatic Flight'),
( 4, 0, 2, 'Ogre Forged Hauberk'),
( 4, 0, 3, 'Ornate Adamantium Breastplate'),
( 4, 0, 3, 'Kromcrush''s Chestplate'),
-- Ceinture (5)
( 5, 0, 1, 'Brigam Girdle'),
( 5, 0, 2, 'Mugger''s Belt'),
( 5, 0, 2, 'Omokk''s Girth Restrainer'),
( 5, 0, 2, 'Handcrafted Mastersmith Girdle'),
( 5, 0, 3, 'Belt of Heroism'),
-- Jambes (6)
( 6, 0, 1, 'Eldritch Reinforced Legplates'),
( 6, 0, 2, 'Cloudkeeper Legplates'),
( 6, 0, 2, 'Abyssal Plate Legguards'),
( 6, 0, 2, 'Legplates of Heroism'),
( 6, 0, 2, 'Legplates of Valor'),
( 6, 0, 2, 'Legplates of Vigilance'),
( 6, 0, 3, 'Wraithplate Leggings'),
-- Pieds (7)
( 7, 0, 1, 'Boots of Valor'),
( 7, 0, 2, 'Boots of Heroism'),
( 7, 0, 2, 'Bloodmail Boots'),
( 7, 0, 2, 'Ribsteel Footguards'),
( 7, 0, 2, 'Sapphiron''s Scale Boots'),
( 7, 0, 2, 'Boots of Avoidance'),
-- Poignets (8)
( 8, 0, 1, 'Bracers of Valor'),
( 8, 0, 2, 'Bracers of Heroism'),
( 8, 0, 2, 'Battleborn Armbraces'),
( 8, 0, 2, 'Vigorsteel Vambraces'),
( 8, 0, 2, 'Blackmist Armguards'),
( 8, 0, 2, 'Slashclaw Bracers'),
( 8, 0, 2, 'Vambraces of the Sadist'),
-- Mains (9)
( 9, 0, 1, 'Voone''s Vice Grips'),
( 9, 0, 2, 'Edgemaster''s Handguards'),
( 9, 0, 2, 'Gauntlets of Heroism'),
( 9, 0, 2, 'Reiver Claws'),
( 9, 0, 2, 'Force Imbued Gauntlets'),
( 9, 0, 3, 'Gordok''s Handguards'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Band of the Ogre King'),
(10, 0, 1, 'Band of Flesh'),
(10, 0, 2, 'Myrmidon''s Signet'),
(10, 0, 2, 'Blackstone Ring'),
(10, 0, 2, 'Tarnished Elven Ring'),
(10, 0, 2, 'Painweaver Band'),
(10, 1, 2, 'Magni''s Will'),   -- Alliance uniquement
(10, 0, 3, 'Band of the Steadfast Hero'),
(10, 0, 3, 'Naglering'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Diamond Flask'),
(12, 0, 1, 'Blackhand''s Breadth'),
(12, 0, 2, 'Hand of Justice'),
(12, 2, 2, 'Rune of the Guard Captain'),   -- Horde uniquement
(12, 0, 2, 'Counterattack Lodestone'),
(12, 0, 2, 'Vigilance Charm'),
(12, 0, 3, 'Mark of the Chosen'),
(12, 0, 3, 'Force of Will'),
-- Dos (14)
(14, 0, 1, 'Stoneskin Gargoyle Cape'),
(14, 0, 2, 'Shifting Cloak'),
(14, 0, 2, 'The Emperor''s New Cape'),
(14, 0, 2, 'Phantasmal Cloak'),
(14, 0, 2, 'Armswake Cloak'),
(14, 0, 2, 'Redoubt Cloak'),
-- Main droite (15)
(15, 0, 1, 'Mirah''s Song'),
(15, 0, 2, 'Blackguard'),
(15, 0, 2, 'Quel''Serrar'),
(15, 0, 2, 'Mass of McGowan'),
(15, 0, 2, 'Annihilator'),
(15, 0, 2, 'Heartseeker'),
(15, 0, 3, 'Ironfoe'),
(15, 0, 3, 'Timeworn Mace'),
(15, 0, 3, 'Bone Slicing Hatchet'),
(15, 0, 3, 'Hedgecutter'),
(15, 0, 3, 'Serathil'),
(15, 0, 3, 'Tooth of Eranikus'),
(15, 0, 3, 'Felstriker'),
(15, 0, 3, 'Scarlet Kris'),
(15, 0, 3, 'Bonescraper'),
(15, 0, 3, 'Darrowspike'),
-- Main gauche - bouclier (16)
(16, 0, 1, 'Dreadguard''s Protector'),
(16, 0, 2, 'Force Reactive Disk'),
(16, 0, 2, 'Wall of the Dead'),
(16, 0, 2, 'Draconian Deflector'),
(16, 0, 3, 'Sacred Protector'),
(16, 0, 3, 'Darrowshire Strongguard'),
-- Distance (17)
(17, 0, 1, 'Satyr''s Bow'),
(17, 0, 2, 'Blackcrow'),
(17, 0, 2, 'Gorewood Bow'),
(17, 0, 3, 'Carapace Spine Crossbow');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 1, 2, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_prot` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_prot` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_prot` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_prot`;
