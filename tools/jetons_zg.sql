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
-- 2. Le lien jeton -> piece. Les quetes "Paragons of Power" demandent un
--    jeton et rendent une piece. ReqItemId* porte le jeton, RewChoiceItemId*
--    ou RewItemId* la recompense.
-- ---------------------------------------------------------------------
SELECT 'Jeton -> piece, par quete' AS section;
SELECT q.`ID` AS quete, q.`LogTitle` AS titre,
       j.`name` AS jeton,
       COALESCE(r1.`name`, r2.`name`) AS piece,
       COALESCE(q.`RewardChoiceItemID1`, q.`RewardItemID1`) AS piece_entry,
       q.`AllowableClasses`
FROM `quest_template` q
JOIN `item_template` j
  ON j.`entry` IN (q.`RequiredItemId1`, q.`RequiredItemId2`, q.`RequiredItemId3`,
                   q.`RequiredItemId4`, q.`RequiredItemId5`, q.`RequiredItemId6`)
LEFT JOIN `item_template` r1 ON r1.`entry` = q.`RewardChoiceItemID1`
LEFT JOIN `item_template` r2 ON r2.`entry` = q.`RewardItemID1`
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
