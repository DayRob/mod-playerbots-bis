-- mod-playerbots-bis : les jetons de Zul'Gurub deviennent reclamables.
--
-- LE PROBLEME
-- -----------
-- Les listes nomment la piece FINIE - "Zandalar Haruspex's Tunic" - parce que
-- c'est elle que la page classe. Le jeton qui l'achete porte un AUTRE
-- identifiant et n'est dans aucune liste. Quand un Etancon primordial hakkari
-- tombe, le module cherche son identifiant dans playerbots_bis_item, ne le
-- trouve pas, et aucun bot ne le reclame : il part au premier venu alors qu'il
-- vaut une piece de rang 1 pour trois classes du raid.
--
-- LA REGLE QUE CE FICHIER APPLIQUE
-- --------------------------------
-- Un jeton herite EXACTEMENT des creneau, palier, spe et rang de la piece
-- qu'il achete, la ou cette piece est deja listee. Rien n'est invente : si la
-- page n'a jamais classe la piece pour une classe, le jeton n'y entre pas non
-- plus. C'est pour ca que l'INSERT va chercher ses valeurs dans
-- playerbots_bis_item au lieu de les porter en dur - les lignes suivent les
-- listes, et suivront leurs corrections futures.
--
-- POURQUOI AUCUN BOT N'ESSAIERA DE L'EQUIPER
-- ------------------------------------------
-- BisEquipAction.cpp ligne 86 ecarte tout ce qui n'est ni ITEM_CLASS_WEAPON ni
-- ITEM_CLASS_ARMOR. Un jeton est un objet de quete : il entre dans la logique
-- de reclamation et d'annonce, jamais dans celle d'equipement.
--
-- CE QUI N'Y EST PAS, ET POURQUOI
-- -------------------------------
-- Primal Hakkari Idol (22637) est absent a dessein. Ses neuf quetes - Hoodoo
-- Hex, Animist's Caress, Presence of Sight... - rendent des ENCHANTEMENTS, pas
-- des pieces d'equipement. Il n'a donc aucun creneau ou se poser.
--
-- D'OU VIENNENT CES DONNEES
-- -------------------------
-- De la base monde du serveur : item_template.AllowableClass donne les trois
-- classes de chaque jeton, et quest_template donne les quetes "Paragons of
-- Power" qui l'echangent. Les deux se recoupent sans une exception - le masque
-- 1296 du Sash vaut pretre + demoniste + druide, et ses trois quetes rendent
-- bien du Confessor, du Demoniac et du Haruspex.
--
-- UN SEUL PAS N'EST PAS VERIFIE PAR LA BASE : le passage du titre de quete
-- "Paragons of Power: The Haruspex's Tunic" au nom d'objet "Zandalar
-- Haruspex's Tunic". C'est une deduction de ma part. La VERIFICATION 1
-- ci-dessous la met a l'epreuve : toute piece dont le nom ne tombe pas juste
-- y apparait.

DROP TEMPORARY TABLE IF EXISTS `bis_jetons_zg`;
CREATE TEMPORARY TABLE `bis_jetons_zg` (
    `jeton`      INT UNSIGNED NOT NULL,
    `nom_jeton`  VARCHAR(60)  NOT NULL,
    `classe`     TINYINT UNSIGNED NOT NULL,
    `piece`      VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- Classes : 1 guerrier, 2 paladin, 3 chasseur, 4 voleur, 5 pretre,
--           7 chaman, 8 mage, 9 demoniste, 11 druide.
-- Sets    : Vindicator guerrier, Freethinker paladin, Predator chasseur,
--           Madcap voleur, Confessor pretre, Augur chaman, Illusionist mage,
--           Demoniac demoniste, Haruspex druide.
INSERT INTO `bis_jetons_zg` (`jeton`, `nom_jeton`, `classe`, `piece`) VALUES
(19724, 'Primal Hakkari Aegis',      3, 'Zandalar Predator''s Mantle'),
(19724, 'Primal Hakkari Aegis',      5, 'Zandalar Confessor''s Mantle'),
(19724, 'Primal Hakkari Aegis',      4, 'Zandalar Madcap''s Tunic'),

(19717, 'Primal Hakkari Armsplint',  7, 'Zandalar Augur''s Bracers'),
(19717, 'Primal Hakkari Armsplint',  1, 'Zandalar Vindicator''s Armguards'),
(19717, 'Primal Hakkari Armsplint',  4, 'Zandalar Madcap''s Bracers'),

(19716, 'Primal Hakkari Bindings',   2, 'Zandalar Freethinker''s Armguards'),
(19716, 'Primal Hakkari Bindings',   8, 'Zandalar Illusionist''s Wraps'),
(19716, 'Primal Hakkari Bindings',   3, 'Zandalar Predator''s Bracers'),

(19719, 'Primal Hakkari Girdle',     4, 'Zandalar Madcap''s Mantle'),
(19719, 'Primal Hakkari Girdle',     7, 'Zandalar Augur''s Belt'),
(19719, 'Primal Hakkari Girdle',     1, 'Zandalar Vindicator''s Belt'),

-- Robe au SINGULIER pour ces deux-la, alors que la quete s'intitule
-- "...'s Robes" au pluriel. Les vingt-cinq autres pieces portent exactement le
-- nom de leur quete ; ces deux seules font exception, et je les avais deduites
-- du titre comme les autres. La base du joueur l'a montre : entrees 20034 et
-- 20033, "Zandalar Illusionist's Robe" et "Zandalar Demoniac's Robe".
(19723, 'Primal Hakkari Kossack',    8, 'Zandalar Illusionist''s Robe'),
(19723, 'Primal Hakkari Kossack',    9, 'Zandalar Demoniac''s Robe'),
(19723, 'Primal Hakkari Kossack',    1, 'Zandalar Vindicator''s Breastplate'),

(19720, 'Primal Hakkari Sash',      11, 'Zandalar Haruspex''s Belt'),
(19720, 'Primal Hakkari Sash',       5, 'Zandalar Confessor''s Bindings'),
(19720, 'Primal Hakkari Sash',       9, 'Zandalar Demoniac''s Mantle'),

(19721, 'Primal Hakkari Shawl',      2, 'Zandalar Freethinker''s Belt'),
(19721, 'Primal Hakkari Shawl',      3, 'Zandalar Predator''s Belt'),
(19721, 'Primal Hakkari Shawl',      8, 'Zandalar Illusionist''s Mantle'),

(19718, 'Primal Hakkari Stanchion', 11, 'Zandalar Haruspex''s Bracers'),
(19718, 'Primal Hakkari Stanchion',  9, 'Zandalar Demoniac''s Wraps'),
(19718, 'Primal Hakkari Stanchion',  5, 'Zandalar Confessor''s Wraps'),

(19722, 'Primal Hakkari Tabard',     2, 'Zandalar Freethinker''s Breastplate'),
(19722, 'Primal Hakkari Tabard',    11, 'Zandalar Haruspex''s Tunic'),
(19722, 'Primal Hakkari Tabard',     7, 'Zandalar Augur''s Hauberk');

-- Rejouable : les lignes de jetons partent avant d'etre reposees, sinon un
-- changement de rang dans les listes laisserait l'ancienne derriere.
DELETE FROM `playerbots_bis_item`
WHERE `item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_zg`);

-- Le jeton prend les creneau, spe, palier et rang de la piece, la ou cette
-- piece est deja listee pour sa classe. Pas de piece listee, pas de jeton.
INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT b.`class`, b.`spec`, b.`slot`, 0, b.`tier_id`, j.`jeton`, b.`rank`,
       CONCAT('jeton ', j.`nom_jeton`, ' -> ', j.`piece`)
FROM `bis_jetons_zg` j
JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = j.`piece` COLLATE utf8mb4_general_ci
JOIN `playerbots_bis_item` b
  ON b.`item_id` = i.`entry` AND b.`class` = j.`classe`;

-- VERIFICATION 1 - pieces dont le nom ne tombe pas juste (aucune ligne = bon).
-- C'est le seul pas que la base n'a pas confirme : la deduction du nom d'objet
-- depuis le titre de quete.
-- L'alias s'appelle nom_non_resolu, comme dans les fichiers generes, et non
-- "nom_introuvable" : importer_tout.ps1 repere les noms perdus par CE libelle.
-- Avec un alias different, les deux erreurs ci-dessus sont passees a l'import
-- sans que rien ne les signale.
SELECT j.`nom_jeton`, j.`classe`, j.`piece` AS nom_non_resolu
FROM `bis_jetons_zg` j
LEFT JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = j.`piece` COLLATE utf8mb4_general_ci
WHERE i.`entry` IS NULL
ORDER BY j.`nom_jeton`, j.`classe`;

-- VERIFICATION 2 - les jetons effectivement poses, et ce qu'ils rapportent.
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, b.`comment`
FROM `playerbots_bis_item` b
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_zg`)
ORDER BY b.`comment`, b.`class`, b.`spec`;

-- VERIFICATION 3 - pieces connues de la base mais qu'AUCUNE liste ne classe :
-- leur jeton ne sera donc pas reclame. Ce n'est pas une anomalie, c'est la
-- regle du fichier - mais autant savoir lesquelles.
SELECT j.`nom_jeton`, j.`classe`, j.`piece` AS piece_absente_des_listes
FROM `bis_jetons_zg` j
JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = j.`piece` COLLATE utf8mb4_general_ci
LEFT JOIN `playerbots_bis_item` b
  ON b.`item_id` = i.`entry` AND b.`class` = j.`classe`
WHERE b.`item_id` IS NULL
ORDER BY j.`classe`, j.`nom_jeton`;

-- LA CONVERSION : CE QUE LE JETON DEVIENT
-- ---------------------------------------
-- Les lignes ci-dessus font qu'un bot RECLAME le jeton. Elles ne disent pas ce
-- qu'il en fait ensuite, et un jeton n'est ni arme ni armure : il dormait dans
-- le sac pour toujours. Cette table repond a la seule question qui manquait -
-- ce jeton, pour cette classe, donne quelle piece - et le module s'en sert pour
-- echanger l'un contre l'autre des que le bot le tient.
--
-- Pourquoi une table et pas une deduction : la piece se devine sinon en
-- cherchant une ligne de meme classe, spe, creneau, palier et rang, ce qui
-- tombe juste aujourd'hui et faux le jour ou deux pieces partagent un rang.
-- L'identifiant ecrit noir sur blanc ne se trompe pas.
CREATE TABLE IF NOT EXISTS `playerbots_bis_quest_token` (
    `token_id` INT UNSIGNED NOT NULL COMMENT 'objet de quete tenu par le bot',
    `class`    TINYINT UNSIGNED NOT NULL COMMENT 'classe du bot',
    `piece_id` INT UNSIGNED NOT NULL COMMENT 'piece que le jeton achete',
    `comment`  VARCHAR(120) NOT NULL DEFAULT '',
    PRIMARY KEY (`token_id`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='mod-playerbots-bis : jeton de quete -> piece, par classe';

-- Rejouable, comme le bloc precedent.
DELETE FROM `playerbots_bis_quest_token`
WHERE `token_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_zg`);

-- La MEME condition que l'INSERT precedent : seules les pieces que les listes
-- classent pour cette classe entrent ici. Un jeton reclamable sans conversion,
-- ou une conversion vers une piece que personne ne reclame, seraient deux
-- facons de se contredire.
INSERT IGNORE INTO `playerbots_bis_quest_token` (`token_id`, `class`, `piece_id`, `comment`)
SELECT j.`jeton`, j.`classe`, i.`entry`,
       CONCAT(j.`nom_jeton`, ' -> ', j.`piece`)
FROM `bis_jetons_zg` j
JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = j.`piece` COLLATE utf8mb4_general_ci
JOIN `playerbots_bis_item` b
  ON b.`item_id` = i.`entry` AND b.`class` = j.`classe`;

-- VERIFICATION 4 - un jeton reclamable DOIT avoir sa conversion, sinon le bot
-- le gagne et ne peut rien en faire (aucune ligne = bon).
SELECT DISTINCT b.`item_id` AS jeton_sans_conversion, b.`class`, b.`comment`
FROM `playerbots_bis_item` b
LEFT JOIN `playerbots_bis_quest_token` t
  ON t.`token_id` = b.`item_id` AND t.`class` = b.`class`
WHERE b.`item_id` IN (SELECT DISTINCT `jeton` FROM `bis_jetons_zg`)
  AND t.`piece_id` IS NULL
ORDER BY b.`item_id`, b.`class`;

DROP TEMPORARY TABLE IF EXISTS `bis_jetons_zg`;
