-- mod-playerbots-bis : noms d'instances pour le plan de donjons.
--
-- La base monde ne contient AUCUN nom de carte : ils vivent dans les DBC du
-- client. Le planificateur (".playerbotsbis donjons") a pourtant besoin d'un
-- nom lisible en face de chaque identifiant de carte.
--
-- Il pioche dans trois sources, dans cet ordre :
--   1. cette table, si elle existe ;
--   2. areatrigger_teleport, qui nomme la destination de chaque portail - en
--      anglais, et parfois avec le nom de la porte plutot que du donjon ;
--   3. "carte <id>", moche mais jamais faux.
--
-- Ce fichier est OPTIONNEL et ADDITIF : il ne touche a aucune donnee BiS, et
-- sans lui le plan fonctionne avec les noms anglais. Tu peux ajouter ou
-- corriger une ligne a chaud, puis ".playerbotsbis reload" - pas de
-- reconstruction necessaire.
--
-- Seules les instances Vanilla sont listees ici, parce que ce sont les seules
-- dont je connais le nom francais avec certitude. Pour BC et Wrath, la source 2
-- prend le relais toute seule ; ajoute tes propres lignes si l'anglais te gene.
--
-- Sans accents, comme le reste du projet : ces noms traversent le tchat systeme
-- pour atteindre l'addon.

DROP TABLE IF EXISTS `playerbots_bis_map_name`;
CREATE TABLE `playerbots_bis_map_name` (
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `name`   VARCHAR(100) NOT NULL,
    PRIMARY KEY (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `playerbots_bis_map_name` (`map_id`, `name`) VALUES
-- Donjons
( 33, 'Chateau d''Ombrecroc'),
( 34, 'Les Carcans'),
( 36, 'Les Mortemines'),
( 43, 'Grottes des Lamentations'),
( 47, 'Kraal de Tranchebauge'),
( 48, 'Profondeurs de Brassenoire'),
( 70, 'Uldaman'),
( 90, 'Gnomeregan'),
(109, 'Temple englouti d''Atal''Hakkar'),
(129, 'Souilles de Tranchebauge'),
(189, 'Monastere ecarlate'),
(209, 'Zul''Farrak'),
(229, 'Pic Rochenoire'),
(230, 'Profondeurs de Rochenoire'),
(289, 'Scholomance'),
(329, 'Stratholme'),
(349, 'Maraudon'),
(389, 'Gouffre de Ragefeu'),
(429, 'Hache-tripes'),
-- Raids
(249, 'Repaire d''Onyxia'),
(309, 'Zul''Gurub'),
(409, 'Coeur du Magma'),
(469, 'Repaire de l''Aile noire'),
(509, 'Ruines d''Ahn''Qiraj'),
(531, 'Temple d''Ahn''Qiraj'),
(533, 'Naxxramas');
