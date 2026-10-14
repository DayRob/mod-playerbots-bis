-- mod-playerbots-bis : les idoles et scarabees d'Ahn'Qiraj deviennent reclamables.
--
-- CE FICHIER CORRIGE UNE ERREUR DU FICHIER 75
-- -------------------------------------------
-- Le 75 les ecartait en affirmant : "Ils achetent des ENCHANTEMENTS, pas des
-- pieces d'equipement : ils n'ont aucun creneau ou se poser." C'etait faux, et
-- jamais verifie - une supposition ecrite comme une certitude.
--
-- La base monde dit le contraire : idoles et scarabees achetent TOUT le palier
-- 2.5 des Ruines - Avenger's, Conqueror's, Deathdealer's, Doomcaller's,
-- Enigma, Genesis, Stormcaller's, Striker's, Oracle - plus des anneaux et des
-- armes. L'Idole de la vie seule entre dans six quetes.
--
-- POURQUOI LA RECLAMATION SEULE, SANS CONVERSION
-- ----------------------------------------------
-- Les jetons d'Ahn'Qiraj 40 suivent "un jeton, une piece" : le fichier 75 peut
-- donc ecrire la conversion, et le bot echange l'un contre l'autre des qu'il
-- le tient.
--
-- Ici, NON. La quete 8627 - Avenger's Breastplate - exige a la fois un Bone
-- Scarab, un Silver Scarab et une Idol of the Sage. Une piece coute PLUSIEURS
-- objets, en quantites que ce fichier ne lit meme pas. Ecrire une conversion
-- "une idole -> une piece" serait ecrire quelque chose de faux, et la
-- VERIFICATION 4 du fichier 75 aurait raison de s'y opposer.
--
-- Le bot reclamera donc l'idole et la GARDERA. C'est deja tout l'enjeu : sans
-- ces lignes, personne ne vote dessus et elle part au premier venu. Rendre les
-- quetes reste a la charge du joueur, ou d'un travail ulterieur sur la
-- conversion a plusieurs objets.
--
-- EFFET DE BORD ASSUME : les idoles s'accumulent dans les sacs des bots. Elles
-- ne s'equipent pas - BisEquipAction n'accepte que les armes et les armures -
-- et rien ne les consomme. Si les sacs deviennent un probleme, c'est ce
-- fichier qu'il faut retirer, pas un reglage.

-- ---------------------------------------------------------------------
-- 1. Les seize noms. La SEULE chose ecrite a la main.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_idoles_noms`;
CREATE TEMPORARY TABLE `bis_idoles_noms` (
    `nom` VARCHAR(60) NOT NULL,
    PRIMARY KEY (`nom`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_idoles_noms` (`nom`) VALUES
('Idol of Death'), ('Idol of Life'), ('Idol of Night'), ('Idol of Rebirth'),
('Idol of Strife'), ('Idol of the Sage'), ('Idol of the Sun'), ('Idol of War'),
('Bone Scarab'), ('Bronze Scarab'), ('Clay Scarab'), ('Crystal Scarab'),
('Gold Scarab'), ('Ivory Scarab'), ('Silver Scarab'), ('Stone Scarab');

-- ---------------------------------------------------------------------
-- 2. L'objet et les pieces qu'il permet d'obtenir, lus dans quest_template.
--    Meme depliage que le fichier 75 : une quete rend soit une piece fixe,
--    soit un choix, et NULLIF ecarte les emplacements vides, qui valent 0.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_idoles`;
CREATE TEMPORARY TABLE `bis_idoles` (
    `objet` INT UNSIGNED NOT NULL,
    `piece` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`objet`, `piece`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_idoles` (`objet`, `piece`)
SELECT j.`entry`, r.`piece`
FROM `bis_idoles_noms` n
JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom` COLLATE utf8mb4_general_ci
JOIN `quest_template` q
  ON j.`entry` IN (q.`RequiredItemId1`, q.`RequiredItemId2`, q.`RequiredItemId3`,
                   q.`RequiredItemId4`, q.`RequiredItemId5`, q.`RequiredItemId6`)
JOIN (
    SELECT `ID` AS quete, NULLIF(`RewardItem1`, 0)         AS piece FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem2`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem3`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardItem4`, 0)         FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID1`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID2`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID3`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID4`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID5`, 0) FROM `quest_template`
    UNION ALL SELECT `ID`, NULLIF(`RewardChoiceItemID6`, 0) FROM `quest_template`
) r ON r.`quete` = q.`ID` AND r.`piece` IS NOT NULL;

-- ---------------------------------------------------------------------
-- 3. Les lignes de liste a copier, FIGEES. Meme raison qu'au fichier 75 :
--    playerbots_bis_item est a la fois la source du creneau et la cible des
--    lignes posees. Palier 60 seulement.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_listes_idoles`;
CREATE TEMPORARY TABLE `bis_listes_idoles` (
    `item_id` INT UNSIGNED NOT NULL,
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`item_id`, `class`, `spec`, `slot`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_listes_idoles` (`item_id`, `class`, `spec`, `slot`, `rank`)
SELECT b.`item_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`
FROM `playerbots_bis_item` b
JOIN `bis_idoles` i ON i.`piece` = b.`item_id`
WHERE b.`tier_id` = 60;

-- ---------------------------------------------------------------------
-- 4. Le meilleur rang par (objet, classe, spe, creneau).
--
--    Une idole mene souvent a PLUSIEURS pieces : l'Idole de la vie donne les
--    bottes ET le haubert du chasseur. Deux pieces d'un meme creneau se
--    disputeraient alors la meme ligne - meme classe, meme spe, meme creneau,
--    meme objet - et la cle primaire n'en garderait qu'une, au hasard. Le
--    meilleur rang tranche.
--
--    En deux etapes, parce qu'une table TEMPORARY ne peut pas etre lue deux
--    fois dans une seule instruction : MySQL rend ERROR 1137, la ou MariaDB
--    laisse passer. C'est ce qui a casse le fichier 75 en production.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_idoles_rang`;
CREATE TEMPORARY TABLE `bis_idoles_rang` (
    `objet` INT UNSIGNED NOT NULL,
    `class` TINYINT UNSIGNED NOT NULL,
    `spec`  TINYINT UNSIGNED NOT NULL,
    `slot`  TINYINT UNSIGNED NOT NULL,
    `rang`  TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`objet`, `class`, `spec`, `slot`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_idoles_rang` (`objet`, `class`, `spec`, `slot`, `rang`)
SELECT i.`objet`, b.`class`, b.`spec`, b.`slot`, MIN(b.`rank`)
FROM `bis_idoles` i
JOIN `bis_listes_idoles` b ON b.`item_id` = i.`piece`
GROUP BY i.`objet`, b.`class`, b.`spec`, b.`slot`;

-- La piece de ce rang, la plus petite si egalite, pour que le commentaire
-- nomme toujours la meme et que deux imports se ressemblent.
DROP TEMPORARY TABLE IF EXISTS `bis_idoles_choix`;
CREATE TEMPORARY TABLE `bis_idoles_choix` (
    `objet` INT UNSIGNED NOT NULL,
    `class` TINYINT UNSIGNED NOT NULL,
    `spec`  TINYINT UNSIGNED NOT NULL,
    `slot`  TINYINT UNSIGNED NOT NULL,
    `rang`  TINYINT UNSIGNED NOT NULL,
    `piece` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`objet`, `class`, `spec`, `slot`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_idoles_choix` (`objet`, `class`, `spec`, `slot`, `rang`, `piece`)
SELECT r.`objet`, r.`class`, r.`spec`, r.`slot`, r.`rang`, MIN(i.`piece`)
FROM `bis_idoles_rang` r
JOIN `bis_idoles` i ON i.`objet` = r.`objet`
JOIN `bis_listes_idoles` b
  ON b.`item_id` = i.`piece` AND b.`class` = r.`class`
 AND b.`spec` = r.`spec` AND b.`slot` = r.`slot` AND b.`rank` = r.`rang`
GROUP BY r.`objet`, r.`class`, r.`spec`, r.`slot`, r.`rang`;

-- ---------------------------------------------------------------------
-- 5. Les lignes de reclamation. Rejouable.
-- ---------------------------------------------------------------------
DELETE FROM `playerbots_bis_item`
WHERE `tier_id` = 60
  AND `item_id` IN (SELECT DISTINCT `objet` FROM `bis_idoles`);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT c.`class`, c.`spec`, c.`slot`, 0, 60, c.`objet`, c.`rang`,
       CONCAT('idole ', t.`name`, ' -> ', p.`name`)
FROM `bis_idoles_choix` c
JOIN `item_template` t ON t.`entry` = c.`objet`
JOIN `item_template` p ON p.`entry` = c.`piece`;

-- ---------------------------------------------------------------------
-- VERIFICATIONS
-- ---------------------------------------------------------------------

-- 1 - un nom que la base ne connait pas (aucune ligne = bon). Trois colonnes,
--     le nom dans la troisieme : importer_tout.ps1 s'arrete des qu'une ligne
--     n'en a pas exactement trois.
SELECT 'idole' AS `objet`, 60 AS `palier`, n.`nom` AS nom_non_resolu
FROM `bis_idoles_noms` n
LEFT JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom` COLLATE utf8mb4_general_ci
WHERE j.`entry` IS NULL
ORDER BY n.`nom`;

-- 2 - combien de lignes chaque objet a recues, et pour quelles classes.
SELECT t.`name` AS objet, COUNT(*) AS lignes,
       COUNT(DISTINCT b.`class`) AS classes
FROM `playerbots_bis_item` b
JOIN `item_template` t ON t.`entry` = b.`item_id`
WHERE b.`tier_id` = 60
  AND b.`item_id` IN (SELECT DISTINCT `objet` FROM `bis_idoles`)
GROUP BY t.`name`
ORDER BY t.`name`;

-- 3 - une piece achetable par une idole qu'aucune liste ne classe. Ce n'est
--     pas une anomalie : c'est la regle du fichier - pas de piece listee, pas
--     de reclamation - mais autant savoir lesquelles.
SELECT t.`name` AS objet, p.`name` AS piece_absente_des_listes
FROM `bis_idoles` i
JOIN `item_template` t ON t.`entry` = i.`objet`
JOIN `item_template` p ON p.`entry` = i.`piece`
LEFT JOIN `bis_listes_idoles` b ON b.`item_id` = i.`piece`
WHERE b.`item_id` IS NULL
ORDER BY t.`name`, p.`name`;

DROP TEMPORARY TABLE IF EXISTS `bis_idoles_choix`;
DROP TEMPORARY TABLE IF EXISTS `bis_idoles_rang`;
DROP TEMPORARY TABLE IF EXISTS `bis_listes_idoles`;
DROP TEMPORARY TABLE IF EXISTS `bis_idoles`;
DROP TEMPORARY TABLE IF EXISTS `bis_idoles_noms`;
