-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Druide Equilibre (11/0).
--
-- Derniere combinaison encore servie par 04_vanilla_preraid_wowsims.sql, qui ne
-- donnait qu'un objet par creneau. Celle-ci la remplace par une liste complete
-- et hierarchisee. Avec ce fichier, les vingt-huit specialisations ont un
-- pre-raid fourni.
--
-- IMPORTANT - ORDRE D'IMPORT : apres 04.
--
-- PvP ET REPUTATIONS ECARTES, comme partout dans le projet : un bot ne monte ni
-- son rang d'honneur ni une reputation de champ de bataille. Sont donc absents
-- Frostwolf Advisor's Cloak, Stormpike Sage's Cloak, Dryad's Wrist Bindings,
-- Frostwolf Cloth Belt, Stormpike Cloth Girdle, Advisor's Ring, Lorekeeper's
-- Ring, Mindfang, Sageclaw, Ironbark Staff, Tome of Arcane Domination et
-- Therazane's Touch. Le guide les signalait tous explicitement "PvP".
--
-- Utile : la liste de tete du guide ecarte deja d'elle-meme le PvP et les
-- suffixes aleatoires, ce qui en fait exactement notre jeu de contraintes. Les
-- rangs 1 la suivent donc a la lettre.
--
-- OBJETS A SUFFIXE ALEATOIRE ("... of Arcane Wrath") : entres sous leur NOM DE
-- BASE - Archivist Cape, Flameweave Cuffs, Green Lens, Drakestone - comme dans
-- les autres listes de lanceurs de sorts. Le bot visera la piece sans exiger le
-- bon suffixe : un suffixe median vaut mieux que rien.
--
-- "Nacreous Shell Necklace" du guide Classic s'appelle "Diana's Pearl Necklace"
-- en WotLK, et c'est ce nom-la qui est utilise ici.
--
-- Green Lens demande l'ingenierie pour etre PORTE : rang 3, il ne sera jamais
-- une cible.
--
-- MAIN DROITE ET MAIN GAUCHE : la tenue de tete du guide tient un baton a deux
-- mains, donc aucune main gauche. Les deux creneaux sont pourtant remplis ici,
-- parce que le module raisonne creneau par creneau et qu'un bot qui n'a pas le
-- baton doit savoir vers quoi se tourner. Les batons et les armes a une main
-- cohabitent en creneau 15, comme dans la liste des mages.
--
-- Scepter of Interminable Focus est range en main gauche parce que le guide le
-- classe la, mais je n'ai pas pu confirmer qu'il est bien "tenu en main gauche"
-- et non une arme a une main - ce qui serait inutilisable par un druide, qui ne
-- combat pas a deux armes. Il reste en rang 2 pour cette raison, et la
-- VERIFICATION 2 en fin de fichier le signalera sur ta base si le creneau est
-- faux. Le rang 1 revient a Drakestone, comme dans la liste du pretre Ombre ;
-- Spirit of Aquementas est le repli fiable, recompense de quete.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Balance Druid DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 11 AND `spec` = 0;

DROP TEMPORARY TABLE IF EXISTS `bis_seed_balance`;
CREATE TEMPORARY TABLE `bis_seed_balance` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed_balance` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Spellweaver''s Turban'),
( 0, 0, 2, 'Crimson Felt Hat'),
( 0, 0, 2, 'Dreamweave Circlet'),
( 0, 0, 3, 'Green Lens'),
-- Cou (1)
( 1, 0, 1, 'Diana''s Pearl Necklace'),
( 1, 0, 2, 'Star of Mystaria'),
( 1, 0, 2, 'Tempest Talisman'),
( 1, 0, 2, 'Lady Maye''s Pendant'),
( 1, 0, 2, 'Jeweled Amulet of Cainwyn'),
( 1, 0, 2, 'Tooth of Gnarr'),
-- Epaules (2)
( 2, 0, 1, 'Burial Shawl'),
( 2, 0, 2, 'Kentic Amice'),
( 2, 0, 2, 'Cyclone Spaulders'),
-- Torse (4)
( 4, 0, 1, 'Robe of Everlasting Night'),
( 4, 0, 2, 'Chestplate of Tranquility'),
( 4, 0, 2, 'Robe of the Magi'),
( 4, 0, 2, 'Alanna''s Embrace'),
-- Taille (5)
( 5, 0, 1, 'Ban''thok Sash'),
( 5, 0, 2, 'Oddly Magical Belt'),
( 5, 0, 2, 'Thuzadin Sash'),
( 5, 0, 2, 'Star Belt'),
-- Jambes (6)
( 6, 0, 1, 'Skyshroud Leggings'),
( 6, 0, 2, 'Spellshock Leggings'),
( 6, 0, 2, 'Luminary Kilt'),
-- Pieds (7)
( 7, 0, 1, 'Waterspout Boots'),
( 7, 0, 2, 'Omnicast Boots'),
( 7, 0, 2, 'Dragonrider Boots'),
-- Poignets (8)
( 8, 0, 1, 'Sublime Wristguards'),
( 8, 0, 2, 'Flameweave Cuffs'),
( 8, 0, 2, 'Arena Wristguards'),
-- Mains (9)
( 9, 0, 1, 'Hands of Power'),
( 9, 0, 2, 'Earth Warder''s Gloves'),
( 9, 0, 2, 'Bloodfire Talons'),
( 9, 0, 2, 'Dreamweave Gloves'),
-- Anneaux (10) - le module apparie lui-meme le second doigt
(10, 0, 1, 'Rune Band of Wizardry'),
(10, 0, 2, 'Maiden''s Circle'),
(10, 1, 2, 'Songstone of Ironforge'),
(10, 2, 2, 'Eye of Orgrimmar'),
(10, 0, 2, 'Band of the Unicorn'),
-- Bijoux (12) - idem pour le second emplacement
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 2, 'Eye of the Beast'),
(12, 0, 2, 'Burst of Knowledge'),
-- Dos (14)
(14, 0, 1, 'Archivist Cape'),
(14, 0, 2, 'Spritecaster Cape'),
(14, 0, 2, 'Amplifying Cloak'),
(14, 0, 2, 'Deep Woodlands Cloak'),
-- Main droite (15) - baton a deux mains en tete, armes a une main ensuite
(15, 0, 1, 'Lord Valthalak''s Staff of Command'),
(15, 0, 2, 'Rod of the Ogre Magi'),
(15, 0, 2, 'Staff of Jordan'),
(15, 0, 2, 'Witchblade'),
(15, 0, 2, 'Mastersmith''s Hammer'),
(15, 0, 2, 'Energetic Rod'),
(15, 0, 3, 'Moonshadow Stave'),
(15, 0, 3, 'Zum''rah''s Vexing Cane'),
(15, 0, 3, 'Spire of Hakkar'),
-- Main gauche (16)
(16, 0, 1, 'Drakestone'),
(16, 0, 2, 'Scepter of Interminable Focus'),
(16, 0, 2, 'Spirit of Aquementas'),
(16, 0, 2, 'Tome of the Lost'),
(16, 0, 2, 'Orb of the Forgotten Seer'),
-- Distance - idole (17)
(17, 0, 1, 'Idol of the Moon');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 11, 0, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_balance` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_balance` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_balance` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed_balance`;
