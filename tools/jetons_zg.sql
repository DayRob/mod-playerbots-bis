-- mod-playerbots-bis : a quelle piece de set chaque jeton de Zul'Gurub donne
-- droit, classe par classe.
--
--   Get-Content tools\jetons_zg.sql -Raw |
--     & $m -uacore -padmin acore_world --table --default-character-set=utf8mb4
--
-- POURQUOI CETTE REQUETE
-- ----------------------
-- Les listes BiS nomment la piece FINIE - "Zandalar Haruspex's Tunic" - parce
-- que c'est elle que la page classe. Le jeton qui l'achete, lui, porte un AUTRE
-- identifiant, et n'est donc dans aucune liste.
--
-- Consequence exacte : quand un Etancon primordial hakkari tombe, le module
-- cherche son identifiant dans playerbots_bis_item, ne le trouve pas, et le bot
-- ne le reclame pas. Le jeton part a la cupidite ou au premier venu, alors
-- qu'il vaut une piece de rang 1 ou 3 pour trois classes du raid.
--
-- La correction tient dans les donnees, sans toucher au code : il suffit
-- d'ajouter le JETON aux memes creneau, palier et rang que la piece qu'il
-- donne. BisEquipAction ignore deja tout ce qui n'est ni arme ni armure
-- (ligne 86), donc aucun bot n'essaiera de l'equiper.
--
-- Mais le lien jeton -> piece depend de la classe, et je ne le devinerai pas.
-- Il est dans TA base, dans les quetes de la tribu Zandalar.

-- ---------------------------------------------------------------------
-- 1. Les jetons eux-memes, et les classes autorisees.
--    AllowableClass est un masque de bits : 1 guerrier, 2 paladin,
--    4 chasseur, 8 voleur, 16 pretre, 64 chaman, 128 mage, 256 demoniste,
--    1024 druide. -1 signifie "toutes".
-- ---------------------------------------------------------------------
SELECT 'Les jetons' AS section;
SELECT `entry`, `name`, `AllowableClass`, `Quality`, `ItemLevel`
FROM `item_template`
WHERE `name` LIKE 'Primal Hakkari %'
ORDER BY `name`;

-- ---------------------------------------------------------------------
-- 2a. Les quetes "Paragons of Power" et ce qu'elles rendent.
--
--     Decoupe en deux requetes INDEPENDANTES a dessein : les noms de
--     colonnes de quest_template varient d'une version d'AzerothCore a
--     l'autre, et je n'ai pas pu les verifier contre une vraie base
--     monde. Avec --force, une requete qui echoue n'emporte pas les
--     autres. Si l'une rend "Unknown column", colle l'erreur.
--
--     RewardItem1 et RewardChoiceItemID1 sont ceux qu'utilise deja
--     tools/ou_tombe_cet_objet.sql.
-- ---------------------------------------------------------------------
SELECT 'Quetes Paragons of Power : ce qu elles rendent' AS section;
-- q.AllowableClasses n'existe PAS dans cette version de quest_template : la
-- requete tombait dessus. Les classes se lisent de toute facon sur le JETON,
-- par item_template.AllowableClass, qui lui a repondu.
SELECT q.`ID` AS quete, q.`LogTitle` AS titre,
       COALESCE(c1.`name`, r1.`name`) AS piece,
       COALESCE(q.`RewardChoiceItemID1`, q.`RewardItem1`) AS piece_entry,
       COALESCE(c1.`InventoryType`, r1.`InventoryType`) AS type_emplacement
FROM `quest_template` q
LEFT JOIN `item_template` c1 ON c1.`entry` = q.`RewardChoiceItemID1`
LEFT JOIN `item_template` r1 ON r1.`entry` = q.`RewardItem1`
WHERE q.`LogTitle` LIKE 'Paragons of Power%'
ORDER BY q.`LogTitle`;

-- ---------------------------------------------------------------------
-- 2b. Quel JETON chaque quete demande. C'est la moitie qui manque a la
--     precedente : sans elle on sait ce que la quete rend, pas ce
--     qu'elle coute.
-- ---------------------------------------------------------------------
-- RequiredMinRepFaction / RequiredMinRepValue : les quetes de la tribu
-- Zandalar exigent souvent une REPUTATION en plus du jeton. Un bot qui gagne
-- le jeton ne pourra rendre la quete qu'une fois ce seuil atteint - et les
-- bots gagnent bien cette reputation en raidant Zul'Gurub.
--   0 = aucune exigence. Sinon : 3000 Amical, 9000 Honore, 21000 Revere.
SELECT 'Quetes Paragons of Power : le jeton demande, et la reputation exigee' AS section;
SELECT q.`ID` AS quete, q.`LogTitle` AS titre, j.`entry` AS jeton_entry, j.`name` AS jeton,
       q.`RequiredMinRepFaction` AS faction_exigee, q.`RequiredMinRepValue` AS seuil
FROM `quest_template` q
JOIN `item_template` j
  ON j.`entry` IN (q.`RequiredItemId1`, q.`RequiredItemId2`, q.`RequiredItemId3`,
                   q.`RequiredItemId4`, q.`RequiredItemId5`, q.`RequiredItemId6`)
WHERE j.`name` LIKE 'Primal Hakkari %'
ORDER BY j.`name`, q.`ID`;

-- ---------------------------------------------------------------------
-- 3. Les pieces de set Zandalar deja presentes dans les listes BiS, avec
--    leur creneau, leur palier et leur rang. C'est la que les jetons
--    devront se poser.
-- ---------------------------------------------------------------------
SELECT 'Pieces Zandalar deja dans les listes' AS section;
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, i.`name`
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE i.`name` LIKE 'Zandalar %'
ORDER BY i.`name`, b.`tier_id`, b.`class`, b.`spec`;
