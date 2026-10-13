-- mod-playerbots-bis : ce que la base monde sait des jetons d'Ahn'Qiraj.
--
-- A QUOI CA SERT
-- --------------
-- Le fichier 75 ecrit DIX NOMS DE JETON a la main et deduit tout le reste de
-- la base. Si un de ces dix noms n'est pas celui de ta base, son jeton ne sera
-- pas pose - silencieusement, du point de vue du jeu. Cette requete montre ce
-- que la base contient vraiment, pour confirmer les dix ou les corriger.
--
-- POUR LA PASSER
-- --------------
--   Get-Content tools\jetons_aq.sql -Raw |
--     & $m -uacore -padmin acore_world --table --force
--
-- --force compte : les requetes sont INDEPENDANTES a dessein, pour qu'une qui
-- echoue sur un nom de colonne n'emporte pas les autres. Si l'une rend
-- "Unknown column", colle l'erreur telle quelle.

-- ---------------------------------------------------------------------
-- 1. Tous les objets de quete d'Ahn'Qiraj qui ressemblent a un jeton.
--
--    On cherche LARGE - par motif de nom - au lieu de verifier les dix noms
--    un par un : une requete qui ne trouve pas ce qu'on lui nomme ne dit rien,
--    tandis qu'une liste complete montre aussi ce a quoi on n'avait pas pense.
-- ---------------------------------------------------------------------
SELECT 'Objets de quete AQ qui ressemblent a un jeton' AS section;
SELECT `entry`, `name`, `AllowableClass`, `Quality`, `ItemLevel`
FROM `item_template`
WHERE `name` LIKE 'Imperial Qiraji %'
   OR `name` LIKE 'Qiraji Bindings %'
   OR `name` LIKE '%of the Old God'
   OR `name` LIKE 'Vek%or%s Diadem'
   OR `name` LIKE 'Vek%nilash%s Circlet'
   OR `name` LIKE 'Ouro%s Intact Hide'
   OR `name` LIKE 'Skin of the Great Sandworm'
ORDER BY `name`;

-- ---------------------------------------------------------------------
-- 2. Chaque quete qui EXIGE un de ces objets, et ce qu'elle rend.
--
--    C'est la requete qui compte : c'est exactement le raisonnement du
--    fichier 75, sorti a l'ecran. Ce qu'elle montre ici est ce que le fichier
--    posera.
--
--    RewardItem1..4 pour une recompense fixe (le palier 2.5), et
--    RewardChoiceItemID1..6 pour un CHOIX (les Armaments et la Regalia). Les
--    emplacements vides valent 0 et non NULL, d'ou le NULLIF : sans lui, un
--    COALESCE nu rend 0 en s'arretant au premier terme non nul, et la colonne
--    affiche 0 a cote d'un nom correct.
-- ---------------------------------------------------------------------
SELECT 'Quetes de jeton AQ : ce qu elles exigent et ce qu elles rendent' AS section;
SELECT j.`name` AS jeton, q.`ID` AS quete, q.`LogTitle` AS titre,
       p.`name` AS piece, p.`entry` AS piece_entry,
       p.`AllowableClass` AS classes_de_la_piece,
       p.`InventoryType` AS type_emplacement
FROM `item_template` j
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
) r ON r.`quete` = q.`ID` AND r.`piece` IS NOT NULL
JOIN `item_template` p ON p.`entry` = r.`piece`
WHERE j.`name` LIKE 'Imperial Qiraji %'
   OR j.`name` LIKE 'Qiraji Bindings %'
   OR j.`name` LIKE '%of the Old God'
   OR j.`name` LIKE 'Vek%or%s Diadem'
   OR j.`name` LIKE 'Vek%nilash%s Circlet'
   OR j.`name` LIKE 'Ouro%s Intact Hide'
   OR j.`name` LIKE 'Skin of the Great Sandworm'
ORDER BY j.`name`, p.`name`;

-- ---------------------------------------------------------------------
-- 3. Parmi ces pieces, celles que les listes classent DEJA au palier 60.
--    C'est la que les jetons se poseront : pas de piece listee, pas de jeton.
-- ---------------------------------------------------------------------
SELECT 'Pieces achetables par jeton et deja dans les listes AQ' AS section;
SELECT b.`class`, b.`spec`, b.`slot`, b.`rank`, i.`name` AS piece, b.`comment`
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`tier_id` = 60
  AND (i.`name` LIKE 'Blessed Qiraji %'
    OR i.`name` LIKE 'Conqueror%'
    OR i.`name` LIKE 'Doomcaller%'
    OR i.`name` LIKE 'Stormcaller%'
    OR i.`name` LIKE 'Genesis %'
    OR i.`name` LIKE 'Enigma %'
    OR i.`name` LIKE 'Avenger%'
    OR i.`name` LIKE 'Striker%'
    OR i.`name` LIKE 'Deathdealer%'
    OR i.`name` LIKE 'Vestments of the Shifting Sands'
    OR i.`name` LIKE 'Garments of the Oracle')
ORDER BY b.`class`, b.`slot`, b.`rank`;

-- ---------------------------------------------------------------------
-- 4. Ce que le fichier 75 a effectivement pose, une fois l'import passe.
--    A lancer APRES importer_tout.ps1, pour controler le resultat.
-- ---------------------------------------------------------------------
SELECT 'Jetons AQ poses dans les listes' AS section;
SELECT b.`class`, b.`spec`, b.`slot`, b.`rank`, b.`comment`
FROM `playerbots_bis_item` b
WHERE b.`tier_id` = 60 AND b.`comment` LIKE 'jeton %'
ORDER BY b.`comment`, b.`class`, b.`spec`;

SELECT 'Conversions AQ enregistrees' AS section;
SELECT t.`token_id`, j.`name` AS jeton, t.`class`, p.`name` AS piece
FROM `playerbots_bis_quest_token` t
JOIN `item_template` j ON j.`entry` = t.`token_id`
JOIN `item_template` p ON p.`entry` = t.`piece_id`
WHERE j.`name` LIKE '%Qiraji%' OR j.`name` LIKE '%Old God%'
   OR j.`name` LIKE 'Vek%' OR j.`name` LIKE 'Ouro%'
   OR j.`name` LIKE 'Skin of the Great Sandworm'
ORDER BY j.`name`, t.`class`;
