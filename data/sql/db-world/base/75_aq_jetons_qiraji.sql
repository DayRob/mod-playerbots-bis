-- mod-playerbots-bis : les jetons d'Ahn'Qiraj deviennent reclamables.
--
-- LE MEME PROBLEME QU'A ZUL'GURUB
-- -------------------------------
-- Les listes nomment la piece FINIE - "Blessed Qiraji War Axe" - parce que
-- c'est elle que la page classe. Le jeton qui l'achete porte un AUTRE
-- identifiant et n'est dans aucune liste. Quand un Imperial Qiraji Armaments
-- tombe, le module cherche son identifiant dans playerbots_bis_item, ne le
-- trouve pas, et aucun bot ne le reclame : il part au premier venu alors qu'il
-- vaut une piece de rang 1.
--
-- Le fichier 56 a resolu ca pour Zul'Gurub. Celui-ci fait la meme chose pour
-- Ahn'Qiraj, avec les deux memes moities :
--
--   1. des lignes dans playerbots_bis_item, pour que le bot RECLAME le jeton
--      (BisPriorityMgr::WantsQuestToken, utilise par BisLootRollAction)
--   2. des lignes dans playerbots_bis_quest_token, pour qu'il le CONVERTISSE
--      des qu'il le tient (BisEquipUpgradesAction::ConvertQuestTokens)
--
-- Aucun code n'est ajoute : les deux mecanismes existent et sont generiques.
-- Ce fichier n'apporte que des donnees.
--
-- CE QUE CELUI-CI FAIT MIEUX QUE LE 56
-- ------------------------------------
-- Le fichier 56 ecrit les NOMS DE PIECE a la main, un par jeton et par classe -
-- vingt-sept lignes deduites du titre de la quete. Deux s'etaient revelees
-- fausses ("Robes" au pluriel la ou la base ecrit "Robe"), et seule une
-- verification les a rattrapees.
--
-- Ici, RIEN n'est deduit. Seuls les DIX NOMS DE JETON sont ecrits. Tout le
-- reste vient de la base monde :
--
--   le jeton       -> item_template.name
--   la piece       -> quest_template : la quete qui EXIGE le jeton
--                     (RequiredItemId1..6) et ce qu'elle rend
--                     (RewardItem1..4, RewardChoiceItemID1..6)
--   la classe      -> playerbots_bis_item : la classe pour qui la liste
--                     classe deja cette piece
--
-- Un nom de jeton mal orthographie ne produit donc aucune ligne - jamais une
-- mauvaise - et la VERIFICATION 1 le nomme.
--
-- LA REGLE EST CELLE DU 56 : un jeton herite EXACTEMENT des creneau, palier,
-- spe et rang de la piece qu'il achete, la ou cette piece est deja listee. Pas
-- de piece listee, pas de jeton.
--
-- POURQUOI AUCUN BOT N'ESSAIERA DE L'EQUIPER
-- ------------------------------------------
-- BisEquipAction.cpp ecarte tout ce qui n'est ni ITEM_CLASS_WEAPON ni
-- ITEM_CLASS_ARMOR. Un jeton est un objet de quete : il entre dans la logique
-- de reclamation et de conversion, jamais dans celle d'equipement.
--
-- CE QUI N'EST PAS ICI, ET POURQUOI
-- ---------------------------------
-- Les SCARABEES et les IDOLES qirajis sont traites par le fichier 77, et non
-- ici. Ce fichier a longtemps affirme qu'ils "achetent des ENCHANTEMENTS, pas
-- des pieces d'equipement" : c'etait FAUX, et jamais verifie. La base monde
-- montre qu'ils achetent tout le palier 2.5 des Ruines.
--
-- Ils ne sont pas pour autant des jetons au sens de ce fichier-ci. Une piece
-- leur en coute PLUSIEURS a la fois - la quete 8627 exige un Bone Scarab, un
-- Silver Scarab et une Idol of the Sage - donc la conversion "un jeton, une
-- piece" qu'on ecrit plus bas ne s'y applique pas. Le 77 les rend reclamables
-- sans conversion, et explique pourquoi.
--
-- Primal Hakkari Idol, elle, reste hors du fichier 56 pour la raison qu'on
-- croyait valoir ici : ses quetes rendent des enchantements.
--
-- Les RENDUS DE TETE a une seule recompense - "For All To See" pour Onyxia
-- Tooth Pendant, "The Fall of Ossirian" pour Charm of the Shifting Sands - ne
-- sont pas des jetons de classe : une seule piece, pour tout le monde, au bout
-- d'une chaine. Les traiter comme des jetons ferait reclamer a un bot une tete
-- de boss pour une conversion qu'il ne peut pas declencher seul.
--
-- POUR VOIR CE QUE TA BASE CONTIENT VRAIMENT
-- ------------------------------------------
--   Get-Content tools\jetons_aq.sql -Raw |
--     & $m -uacore -padmin acore_world --table --force

-- ---------------------------------------------------------------------
-- 1. Les dix noms de jeton. La SEULE chose ecrite a la main.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq_noms`;
CREATE TEMPORARY TABLE `bis_jetons_aq_noms` (
    `nom_jeton` VARCHAR(60) NOT NULL,
    PRIMARY KEY (`nom_jeton`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_jetons_aq_noms` (`nom_jeton`) VALUES
-- Les armes et le bouclier : une quete, un CHOIX de plusieurs armes.
('Imperial Qiraji Armaments'),
('Imperial Qiraji Regalia'),
-- Le palier 2.5 : un jeton par creneau, double - une version pour les classes
-- de melee, une pour les lanceurs de sorts.
('Vek''lor''s Diadem'),
('Vek''nilash''s Circlet'),
('Carapace of the Old God'),
('Husk of the Old God'),
('Ouro''s Intact Hide'),
('Skin of the Great Sandworm'),
('Qiraji Bindings of Command'),
('Qiraji Bindings of Dominance');

-- ---------------------------------------------------------------------
-- 2. Le jeton et la piece qu'il achete, lus dans quest_template.
--
--    Les dix colonnes de recompense sont depliees par UNION ALL : une quete
--    de jeton rend soit une piece fixe (RewardItem, cas du palier 2.5), soit
--    un CHOIX (RewardChoiceItemID, cas des Armaments et de la Regalia). Les
--    deux doivent etre lus, et NULLIF ecarte les emplacements vides - qui
--    valent 0 et non NULL, l'erreur qui avait fait afficher "0" a cote d'un
--    nom correct dans tools/jetons_zg.sql.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq`;
CREATE TEMPORARY TABLE `bis_jetons_aq` (
    `jeton`     INT UNSIGNED NOT NULL,
    `nom_jeton` VARCHAR(60)  NOT NULL,
    `piece`     INT UNSIGNED NOT NULL,
    PRIMARY KEY (`jeton`, `piece`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_jetons_aq` (`jeton`, `nom_jeton`, `piece`)
SELECT j.`entry`, j.`name`, r.`piece`
FROM `bis_jetons_aq_noms` n
JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom_jeton` COLLATE utf8mb4_general_ci
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
-- 3. Les lignes de liste que les jetons vont copier, FIGEES d'abord.
--
--    On lit avant d'ecrire. playerbots_bis_item est a la fois la source du
--    creneau et la cible des lignes de jeton : lire et ecrire la meme table
--    dans une seule instruction marche aujourd'hui et se brise le jour ou un
--    jeton devient lui-meme une piece listee. La photo coute une table
--    temporaire et supprime la question.
--
--    PALIER 60 UNIQUEMENT. Une piece d'Ahn'Qiraj figure aussi dans les listes
--    des paliers suivants quand rien ne la remplace ; sans ce filtre, le jeton
--    s'y poserait aussi et serait reclame dans un raid ou il ne tombe pas.
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `bis_listes_aq`;
CREATE TEMPORARY TABLE `bis_listes_aq` (
    `item_id` INT UNSIGNED NOT NULL,
    `class`   TINYINT UNSIGNED NOT NULL,
    `spec`    TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `tier_id` SMALLINT UNSIGNED NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`item_id`, `class`, `spec`, `slot`, `tier_id`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `bis_listes_aq` (`item_id`, `class`, `spec`, `slot`, `tier_id`, `rank`)
SELECT b.`item_id`, b.`class`, b.`spec`, b.`slot`, b.`tier_id`, b.`rank`
FROM `playerbots_bis_item` b
JOIN `bis_jetons_aq` j ON j.`piece` = b.`item_id`
WHERE b.`tier_id` = 60;

-- ---------------------------------------------------------------------
-- 4. PREMIERE MOITIE : le bot reclame le jeton.
--
--    Rejouable : les lignes de jeton partent avant d'etre reposees, sinon un
--    changement de rang dans les listes laisserait l'ancienne derriere.
-- ---------------------------------------------------------------------
DELETE FROM `playerbots_bis_item`
WHERE `tier_id` = 60
  AND `item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_aq`);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT b.`class`, b.`spec`, b.`slot`, 0, b.`tier_id`, j.`jeton`, b.`rank`,
       CONCAT('jeton ', j.`nom_jeton`, ' -> ', i.`name`)
FROM `bis_jetons_aq` j
JOIN `bis_listes_aq` b ON b.`item_id` = j.`piece`
JOIN `item_template` i ON i.`entry` = j.`piece`;

-- ---------------------------------------------------------------------
-- 5. SECONDE MOITIE : le bot convertit le jeton des qu'il le tient.
--
--    La table est creee par le fichier 56 ; ce CREATE IF NOT EXISTS la repete
--    a l'identique pour que ce fichier reste jouable seul.
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- LA TABLE DE CONVERSION A GAGNE UNE COLONNE spec
--
-- Sa cle etait (token_id, class). Les jetons de Zul'Gurub donnaient une piece
-- par CLASSE, donc la classe suffisait. Ahn'Qiraj a montre la limite : ses deux
-- jetons d'arme ouvrent un CHOIX, et le choix depend de la SPE.
--
--   Imperial Qiraji Armaments, guerrier -> hache pour Fureur,
--                                          BOUCLIER pour Protection
--   Imperial Qiraji Regalia,   chaman   -> baton Acolyte pour Elementaire,
--                                          baton Augur pour Restauration
--
-- Avec l'ancienne cle, le meilleur rang de la CLASSE gagnait : un guerrier
-- Protection echangeait son jeton contre la hache et laissait le bouclier.
--
-- La table est ENTIEREMENT DERIVEE des listes - les fichiers 56 et 75 la
-- remplissent - donc la migration peut la supprimer sans rien perdre. Le test
-- porte sur la COLONNE et non sur la table : une base d'avant le changement a
-- bien la table, c'est spec qui lui manque.
-- ---------------------------------------------------------------------
SET @spec_absente := (
    SELECT COUNT(*) = 0 FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'playerbots_bis_quest_token'
      AND `COLUMN_NAME` = 'spec');

-- ET LA CLE DOIT CONTENIR piece_id.
--
-- Elle valait (token_id, class, spec), donc UNE piece par bot : c'est ce qui
-- rendait la seconde piece d'un jeton inaccessible pour toujours. Un guerrier
-- qui portait les Conqueror's Spaulders - rang 1 - ne reclamait plus le jeton
-- et n'obtenait jamais les Conqueror's Greaves qu'il ouvrait pourtant aussi.
--
-- Le test porte sur la CLE et non sur la table : une base d'avant le changement
-- a bien les quatre colonnes, c'est la cle primaire qui lui manque.
SET @piece_hors_cle := (
    SELECT COUNT(*) = 0 FROM `information_schema`.`STATISTICS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'playerbots_bis_quest_token'
      AND `INDEX_NAME` = 'PRIMARY'
      AND `COLUMN_NAME` = 'piece_id');

SET @table_presente := (
    SELECT COUNT(*) > 0 FROM `information_schema`.`TABLES`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'playerbots_bis_quest_token');

SET @ordre := IF(@spec_absente OR (@table_presente AND @piece_hors_cle),
                 'DROP TABLE IF EXISTS `playerbots_bis_quest_token`', 'DO 0');
PREPARE migre FROM @ordre;
EXECUTE migre;
DEALLOCATE PREPARE migre;

CREATE TABLE IF NOT EXISTS `playerbots_bis_quest_token` (
    `token_id` INT UNSIGNED NOT NULL COMMENT 'objet de quete tenu par le bot',
    `class`    TINYINT UNSIGNED NOT NULL COMMENT 'classe du bot',
    `spec`     TINYINT UNSIGNED NOT NULL COMMENT 'spe du bot - 10 = ours druide',
    `piece_id` INT UNSIGNED NOT NULL COMMENT 'piece que le jeton achete',
    `comment`  VARCHAR(120) NOT NULL DEFAULT '',
    PRIMARY KEY (`token_id`, `class`, `spec`, `piece_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='mod-playerbots-bis : jeton de quete -> pieces, par classe et par spe';

DELETE FROM `playerbots_bis_quest_token`
WHERE `token_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_aq`);

-- TOUTES LES PIECES QUE LE JETON OUVRE, PLUS UNE SEULE.
--
-- La table en gardait une par (jeton, classe, spe) : la mieux classee, choisie
-- ici a l'import. C'etait defendable tant qu'un jeton n'ouvrait qu'un creneau,
-- et faux des qu'il en ouvre deux - les jetons epaules/bottes d'Ahn'Qiraj
-- rendent au guerrier les Conqueror's Spaulders ET les Conqueror's Greaves.
-- La seconde devenait inaccessible : jamais echangee, et plus jamais reclamee
-- des que la premiere etait portee.
--
-- Un jeton rend donc tout ce qu'il ouvre. Le bot ne garde que ce qui lui
-- manque - ConvertQuestTokens ecarte ce qu'il porte deja - et il continue de
-- reclamer le jeton tant qu'une seule des pieces lui fait defaut.
--
-- L'ORDRE COMPTE, et c'est le seul reste de l'ancien choix : les pieces sont
-- rangees par rang, la meilleure d'abord. WantsQuestToken rend le palier de la
-- premiere qui manque, et le lire dans cet ordre donne le palier de la piece la
-- mieux classee plutot que celui d'une queue de liste.
INSERT IGNORE INTO `playerbots_bis_quest_token` (`token_id`, `class`, `spec`, `piece_id`, `comment`)
SELECT j.`jeton`, b.`class`, b.`spec`, j.`piece`,
       CONCAT(t.`name`, ' -> ', i.`name`)
FROM `bis_jetons_aq` j
JOIN `bis_listes_aq` b ON b.`item_id` = j.`piece`
JOIN `item_template` i ON i.`entry` = j.`piece`
JOIN `item_template` t ON t.`entry` = j.`jeton`
ORDER BY j.`jeton`, b.`class`, b.`spec`, b.`rank`, j.`piece`;

-- ---------------------------------------------------------------------
-- VERIFICATIONS
-- ---------------------------------------------------------------------

-- 1 - un nom de jeton que la base ne connait pas (aucune ligne = bon).
--
--     L'alias s'appelle nom_non_resolu, comme dans les fichiers generes :
--     importer_tout.ps1 repere les noms perdus par CE libelle, et un alias
--     different les laisserait passer en silence.
--
--     ET IL FAUT TROIS COLONNES. Le ramasseur de l'importeur s'arrete des
--     qu'une ligne n'a pas exactement trois champs :
--
--         if ($champs.Count -ne 3) { break }
--
--     et lit le nom dans le TROISIEME. Une seule colonne suffisait a rendre
--     ce garde-fou muet dans le bilan d'import - correct a l'ecran, absent la
--     ou on le lit.
SELECT 'jeton' AS `objet`, 60 AS `palier`, n.`nom_jeton` AS nom_non_resolu
FROM `bis_jetons_aq_noms` n
LEFT JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom_jeton` COLLATE utf8mb4_general_ci
WHERE j.`entry` IS NULL
ORDER BY n.`nom_jeton`;

-- 2 - un jeton que la base connait mais dont AUCUNE quete ne depend : il ne
--     s'echange contre rien, donc il ne sera pas pose (aucune ligne = bon).
SELECT j.`name` AS jeton_sans_quete
FROM `bis_jetons_aq_noms` n
JOIN `item_template` j
  ON j.`name` COLLATE utf8mb4_general_ci = n.`nom_jeton` COLLATE utf8mb4_general_ci
LEFT JOIN `bis_jetons_aq` p ON p.`jeton` = j.`entry`
WHERE p.`jeton` IS NULL
ORDER BY j.`name`;

-- 3 - les jetons effectivement poses, et ce qu'ils rapportent.
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, b.`comment`
FROM `playerbots_bis_item` b
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_aq`)
ORDER BY b.`comment`, b.`class`, b.`spec`;

-- 4 - un jeton reclamable DOIT avoir sa conversion, sinon le bot le gagne et
--     ne peut rien en faire (aucune ligne = bon). C'est la verification qui
--     compte le plus : les deux moities de ce fichier doivent se repondre.
SELECT DISTINCT b.`item_id` AS jeton_sans_conversion, b.`class`, b.`comment`
FROM `playerbots_bis_item` b
LEFT JOIN `playerbots_bis_quest_token` t
  ON t.`token_id` = b.`item_id` AND t.`class` = b.`class` AND t.`spec` = b.`spec`
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_aq`)
  AND t.`piece_id` IS NULL
ORDER BY b.`item_id`, b.`class`;

-- 5 - une piece achetable par un jeton qu'aucune liste ne classe : son jeton
--     ne sera pas reclame. Ce n'est pas une anomalie, c'est la regle du
--     fichier - mais autant savoir lesquelles.
SELECT j.`nom_jeton`, i.`name` AS piece_absente_des_listes
FROM `bis_jetons_aq` j
JOIN `item_template` i ON i.`entry` = j.`piece`
LEFT JOIN `bis_listes_aq` b ON b.`item_id` = j.`piece`
WHERE b.`item_id` IS NULL
ORDER BY j.`nom_jeton`, i.`name`;

DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq_choix`;
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq_rang`;
DROP TEMPORARY TABLE IF EXISTS `bis_listes_aq`;
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq`;
DROP TEMPORARY TABLE IF EXISTS `bis_jetons_aq_noms`;
