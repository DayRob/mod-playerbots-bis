-- mod-playerbots-bis : l'échelle de progression.
--
-- tier_id définit l'ordre : un palier plus haut l'emporte TOUJOURS sur un palier
-- plus bas, quelles que soient les stats. Les identifiants avancent par pas de 10
-- pour laisser de la place à des paliers intercalaires (contenu custom, demi-phases).
--
-- required_progression se raccorde à mod-individual-progression : c'est l'état que
-- le personnage doit avoir atteint pour accéder à ce contenu. 0 = jamais bloqué.
-- La colonne est ignorée tant que PlayerbotsBis.UseIndividualProgression = 0, et
-- le module n'a aucune dépendance de compilation envers mod-individual-progression :
-- il lit l'état via les quêtes cachées 66000 + état, absentes si le module ne
-- tourne pas (dans ce cas l'état vaut 0 et seuls les paliers ungated s'appliquent).

-- ---------------------------------------------------------------------
-- LA CLE ETRANGERE DOIT PARTIR AVANT LA TABLE
--
-- playerbots_bis_item porte fk_bis_item_tier, qui pointe ici. MySQL refuse
-- donc de supprimer cette table tant que la contrainte existe :
--
--     ERROR 3730 : Cannot drop table 'playerbots_bis_tier' referenced by a
--     foreign key constraint 'fk_bis_item_tier' on table 'playerbots_bis_item'
--
-- (MariaDB rend 1451 pour la meme raison.)
--
-- Le defaut est reste invisible pendant toute la vie du projet : le defaut de
-- importer_tout.ps1 est -Depuis 24, qui saute ce fichier. Il ne tourne qu'a
-- froid - et sur une base VRAIMENT vierge, playerbots_bis_item n'existe pas
-- encore, donc aucune contrainte ne pointe ici. Il fallait le cas du milieu,
-- le seul qui arrive en vrai : une base deja remplie, reimportee a froid.
--
-- L'instruction est PREPAREE parce qu'un DROP FOREIGN KEY sur une contrainte
-- absente est une erreur, et que ce fichier doit tourner aussi bien sur une
-- base vierge que sur une base en service. 'DO 0' est l'instruction qui ne
-- fait rien.
-- ---------------------------------------------------------------------
SET @contrainte := (
    SELECT COUNT(*) FROM `information_schema`.`TABLE_CONSTRAINTS`
    WHERE `CONSTRAINT_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'playerbots_bis_item'
      AND `CONSTRAINT_NAME` = 'fk_bis_item_tier');
SET @ordre := IF(@contrainte > 0,
    'ALTER TABLE `playerbots_bis_item` DROP FOREIGN KEY `fk_bis_item_tier`',
    'DO 0');
PREPARE detache FROM @ordre;
EXECUTE detache;
DEALLOCATE PREPARE detache;

DROP TABLE IF EXISTS `playerbots_bis_tier`;
CREATE TABLE `playerbots_bis_tier` (
    `tier_id`              SMALLINT UNSIGNED NOT NULL,
    `expansion`            TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=Vanilla 1=TBC 2=WotLK',
    `name`                 VARCHAR(64) NOT NULL,
    `required_progression` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'mod-individual-progression state, 0 = ungated',
    PRIMARY KEY (`tier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `playerbots_bis_tier` (`tier_id`, `expansion`, `name`, `required_progression`) VALUES
-- Vanilla
( 10, 0, 'Vanilla Pre-Raid',                              0),
( 20, 0, 'Vanilla Phase 1 - Molten Core / Onyxia',        0),
( 30, 0, 'Vanilla Phase 2 - Blackwing Lair',              1),
( 40, 0, 'Vanilla Phase 3 - Zul Gurub',                   3),
-- AQ20 et AQ40 sont sortis ensemble et se jouent ensemble : un seul palier,
-- et non deux. Le 50 a donc disparu plutot que de rester vide entre deux
-- etapes reelles - un palier sans objets n'est pas une etape, c'est un trou
-- que le module franchit sans rien y trouver, et que les outils comptent
-- comme une regression a combler.
( 60, 0, 'Vanilla Phase 4 - Ahn Qiraj (20 et 40)',        4),
( 70, 0, 'Vanilla Phase 5 - Naxxramas 40',                6),
-- The Burning Crusade
( 80, 1, 'TBC Pre-Raid',                                  8),
( 90, 1, 'TBC Phase 1 - Karazhan / Gruul / Magtheridon',  8),
(100, 1, 'TBC Phase 2 - Serpentshrine / Tempest Keep',    9),
(110, 1, 'TBC Phase 3 - Hyjal / Black Temple',           10),
(120, 1, 'TBC Phase 4 - Sunwell Plateau',                12),
-- Wrath of the Lich King
(130, 2, 'WotLK Pre-Raid',                               13),
(140, 2, 'WotLK Phase 1 - Naxxramas / EoE / OS',         13),
(150, 2, 'WotLK Phase 2 - Ulduar',                       14),
(160, 2, 'WotLK Phase 3 - Trial of the Crusader',        15),
(170, 2, 'WotLK Phase 4 - Icecrown Citadel',             16),
(180, 2, 'WotLK Phase 5 - Ruby Sanctum',                 17);

-- ---------------------------------------------------------------------
-- LES LIGNES ORPHELINES, PUIS LA CLE ETRANGERE
--
-- Remettre la contrainte VALIDE toutes les lignes existantes : une ligne
-- d'objet dont le palier n'est plus dans la table ci-dessus la ferait echouer.
-- C'est exactement le cas du palier 50, retire quand les deux Ahn'Qiraj ont
-- fusionne : une base importee avant la fusion en garde les lignes.
--
-- Elles sont montrees AVANT d'etre supprimees. Un palier absent de l'echelle
-- rend ses objets inatteignables de toute facon - le module joint sur le
-- palier - mais une suppression qu'on ne voit pas est une suppression qu'on ne
-- peut pas discuter.
-- ---------------------------------------------------------------------
SET @table_objets := (
    SELECT COUNT(*) FROM `information_schema`.`TABLES`
    WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'playerbots_bis_item');

-- VERIFICATION - ce qui va etre retire (aucune ligne = bon).
SET @ordre := IF(@table_objets > 0,
    'SELECT i.`tier_id` AS palier_disparu, COUNT(*) AS lignes_retirees
     FROM `playerbots_bis_item` i
     LEFT JOIN `playerbots_bis_tier` t ON t.`tier_id` = i.`tier_id`
     WHERE t.`tier_id` IS NULL GROUP BY i.`tier_id` ORDER BY i.`tier_id`',
    'DO 0');
PREPARE montre FROM @ordre;
EXECUTE montre;
DEALLOCATE PREPARE montre;

SET @ordre := IF(@table_objets > 0,
    'DELETE i FROM `playerbots_bis_item` i
     LEFT JOIN `playerbots_bis_tier` t ON t.`tier_id` = i.`tier_id`
     WHERE t.`tier_id` IS NULL',
    'DO 0');
PREPARE nettoie FROM @ordre;
EXECUTE nettoie;
DEALLOCATE PREPARE nettoie;

SET @ordre := IF(@table_objets > 0,
    'ALTER TABLE `playerbots_bis_item`
     ADD CONSTRAINT `fk_bis_item_tier` FOREIGN KEY (`tier_id`)
     REFERENCES `playerbots_bis_tier` (`tier_id`) ON DELETE CASCADE',
    'DO 0');
PREPARE rattache FROM @ordre;
EXECUTE rattache;
DEALLOCATE PREPARE rattache;
