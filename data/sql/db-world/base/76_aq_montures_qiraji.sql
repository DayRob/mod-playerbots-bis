-- mod-playerbots-bis : les bots reclament les montures d'Ahn'Qiraj.
--
-- LE PROBLEME
-- -----------
-- Les cristaux resonnants qirajis invoquent une monture utilisable DANS le
-- temple, et les bots s'en servent. Mais ils ne votaient pas dessus : un
-- cristal n'est ni arme ni armure, donc tous les chemins de ce module
-- l'ecartent, et il partait au premier venu - ou a personne.
--
-- C'est le meme angle mort que les jetons hakkari, traite au fichier 56. Un
-- objet precieux qui n'entre dans aucune liste n'est reclame par personne.
--
-- UNE TABLE PLUTOT QU'UN CAS PARTICULIER
-- --------------------------------------
-- playerbots_bis_wanted_item nomme les objets qu'un bot doit reclamer SANS
-- qu'ils soient sur sa liste d'equipement, avec le nombre au-dela duquel il
-- cesse d'en vouloir. Ecrire "si l'objet est un cristal qiraji" dans le C++
-- aurait repondu a cette demande-ci et a aucune autre ; une table repond a
-- toutes celles de la meme forme, et se corrige sans recompiler.
--
-- Elle ne touche ni aux listes ni au compteur de pieces : un cristal n'est pas
-- un BiS, il n'occupe aucun creneau, et le bilan "3/15 equipes" l'ignore.
--
-- LES NOMS, PAS LES IDENTIFIANTS
-- ------------------------------
-- Meme regle qu'au fichier 75 : un identifiant ecrit de memoire ferait
-- reclamer au bot un objet qui n'est pas celui qu'on nomme, tandis qu'un nom
-- qui ne se resout pas ne produit aucune ligne - et la verification le dit.
--
-- CE QUI N'EST PAS ICI
-- --------------------
-- Les Qiraji Battle Tank, montures utilisables PARTOUT, sont la recompense de
-- la chaine du Seigneur scarabee. Elles ne tombent pas : rien a reclamer.

CREATE TABLE IF NOT EXISTS `playerbots_bis_wanted_item` (
    `item_id`   INT UNSIGNED NOT NULL COMMENT 'objet reclame hors liste d equipement',
    `max_count` SMALLINT UNSIGNED NOT NULL DEFAULT 1
                COMMENT 'le bot en veut tant qu il en possede moins que ca',
    `comment`   VARCHAR(120) NOT NULL DEFAULT '',
    PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='mod-playerbots-bis : objets reclames sans etre sur une liste';

DROP TEMPORARY TABLE IF EXISTS `bis_montures_aq`;
CREATE TEMPORARY TABLE `bis_montures_aq` (
    `nom`       VARCHAR(80) NOT NULL,
    `max_count` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`nom`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- UN SEUL EXEMPLAIRE SUFFIT. Le cristal n'est pas consomme a l'usage : il
-- invoque la monture et reste au sac. Un bot qui en tient un n'a donc plus
-- rien a gagner a un second, et le reclamer le retirerait a un bot qui n'en a
-- aucun - la meme regle que pour les pieces.
INSERT INTO `bis_montures_aq` (`nom`, `max_count`) VALUES
('Blue Qiraji Resonating Crystal',   1),
('Green Qiraji Resonating Crystal',  1),
('Red Qiraji Resonating Crystal',    1),
('Yellow Qiraji Resonating Crystal', 1);

-- Rejouable : les lignes de ce fichier partent avant d'etre reposees.
DELETE FROM `playerbots_bis_wanted_item`
WHERE `item_id` IN (
    SELECT `entry` FROM `item_template`
    WHERE `name` COLLATE utf8mb4_general_ci IN (
        SELECT `nom` COLLATE utf8mb4_general_ci FROM `bis_montures_aq`));

INSERT IGNORE INTO `playerbots_bis_wanted_item` (`item_id`, `max_count`, `comment`)
SELECT i.`entry`, m.`max_count`, CONCAT('monture AQ - ', i.`name`)
FROM `bis_montures_aq` m
JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = m.`nom` COLLATE utf8mb4_general_ci;

-- VERIFICATION 1 - un nom que la base ne connait pas (aucune ligne = bon).
-- Trois colonnes, et le nom dans la TROISIEME : importer_tout.ps1 ramasse les
-- noms perdus par cet alias, et s'arrete des qu'une ligne n'a pas exactement
-- trois champs.
SELECT 'monture' AS `objet`, 60 AS `palier`, m.`nom` AS nom_non_resolu
FROM `bis_montures_aq` m
LEFT JOIN `item_template` i
  ON i.`name` COLLATE utf8mb4_general_ci = m.`nom` COLLATE utf8mb4_general_ci
WHERE i.`entry` IS NULL
ORDER BY m.`nom`;

-- VERIFICATION 2 - ce que les bots reclameront desormais.
SELECT w.`item_id`, w.`max_count`, w.`comment`
FROM `playerbots_bis_wanted_item` w
ORDER BY w.`comment`;

DROP TEMPORARY TABLE IF EXISTS `bis_montures_aq`;
