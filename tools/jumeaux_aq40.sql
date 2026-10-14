-- Les Empereurs Jumeaux d'apres TA base. A coller tel quel.
--
-- La strategie aq40 part de trois hypotheses prises dans le script du coeur
-- (boss_twinemperors.cpp) : Vek'lor porte l'entry 15276 et encaisse zero degat
-- physique, Vek'nilash porte 15275 et encaisse zero degat magique sauf le
-- sacre. Si ta base ne dit pas la meme chose, la repartition melee/casters
-- n'a pas de sens et il faut le savoir avant d'entrer.
--
-- SchoolMask : 1 physique, 2 sacre, 4 feu, 8 nature, 16 givre, 32 ombre, 64 arcane.
-- Attendu : Vek'lor = 1 (physique), Vek'nilash = 124 (tout le magique sauf le sacre).

SELECT c.`entry`,
       c.`name`,
       c.`minlevel`,
       c.`maxlevel`,
       c.`rank`                     AS rang_pnj,
       c.`ScriptName`               AS script,
       c.`CreatureImmunitiesId`     AS id_immunites,
       i.`SchoolMask`               AS masque_ecoles,
       CONCAT_WS(', ',
           IF(i.`SchoolMask` &  1, 'physique', NULL),
           IF(i.`SchoolMask` &  2, 'sacre',    NULL),
           IF(i.`SchoolMask` &  4, 'feu',      NULL),
           IF(i.`SchoolMask` &  8, 'nature',   NULL),
           IF(i.`SchoolMask` & 16, 'givre',    NULL),
           IF(i.`SchoolMask` & 32, 'ombre',    NULL),
           IF(i.`SchoolMask` & 64, 'arcane',   NULL)
       )                            AS immunise_contre,
       i.`Comment`                  AS commentaire
FROM `creature_template` c
LEFT JOIN `creature_immunities` i ON i.`ID` = c.`CreatureImmunitiesId`
WHERE c.`entry` IN (15275, 15276, 15316, 15317)
ORDER BY c.`entry`;

-- -------------------------------------------------------------------------
-- La table `creature` s'appelle `id` sur les AzerothCore plus anciens et
-- `id1` depuis l'arrivee des spawns multi-entry. On regarde laquelle existe
-- plutot que de parier, sinon la requete meurt sur ERROR 1054 et tout ce qui
-- suit ne tourne jamais.
-- -------------------------------------------------------------------------
SET @col := (
    SELECT `COLUMN_NAME`
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME`   = 'creature'
      AND `COLUMN_NAME` IN ('id', 'id1')
    ORDER BY `COLUMN_NAME`
    LIMIT 1
);

-- Ou se trouvent les jumeaux. La carte doit etre 531 pour les deux, sinon le
-- case 531 ajoute dans PlayerbotAI.cpp ne les verra jamais. La distance entre
-- les deux spawns dit aussi si les 70 yards de SAFE_SEPARATION sont tenables.
SET @q := CONCAT(
    'SELECT cr.`guid`, cr.`', @col, '` AS entry, ct.`name`, cr.`map` AS carte, ',
    '       ROUND(cr.`position_x`, 1) AS x, ',
    '       ROUND(cr.`position_y`, 1) AS y, ',
    '       ROUND(cr.`position_z`, 1) AS z ',
    'FROM `creature` cr ',
    'JOIN `creature_template` ct ON ct.`entry` = cr.`', @col, '` ',
    'WHERE cr.`', @col, '` IN (15275, 15276) ',
    'ORDER BY cr.`', @col, '`'
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- La faction des scarabes au repos. `npc_ahnqiraji_critter` fait
-- `me->RestoreFaction()` a chaque Reset, donc c'est bien cette valeur qu'ils
-- portent dans la salle. Un bot ne peut prendre pour cible que ce qui lui est
-- hostile : si cette faction est hostile a la Horde, le probleme est cote IA
-- des bots ; sinon il est ailleurs.
SELECT c.`entry`,
       c.`name`,
       c.`faction`,
       c.`npcflag`,
       c.`unit_flags`,
       c.`flags_extra`,
       c.`type`      AS type_creature,
       c.`lootid`,
       c.`ScriptName` AS script
FROM `creature_template` c
WHERE c.`entry` IN (15316, 15317)
ORDER BY c.`entry`;

-- LE test qui tranche. Dans npc_ahnqiraji_critter::Reset(), un scarabe
-- n'attaque de lui-meme AUCUN joueur si son spawn est lie par
-- `linked_respawn` a un spawn de Vek'lor (15276) :
--
--     ObjectGuid targetGuid = sObjectMgr->GetLinkedRespawnGuid(dbtableHighGuid);
--     if (targetGuid.GetEntry() == NPC_VEKLOR)
--         return;                       // les bestioles des Jumeaux s'arretent la
--
-- Sans ce lien, le planificateur en dessous se met en route et le scarabe
-- attaque tout joueur EN COMBAT a moins de 10 yards, toutes les 3,5 a 4
-- secondes. C'est une cascade : un bot en combat ailleurs reveille un scarabe,
-- qui en reveille un autre, jusqu'aux Empereurs.
--
-- Attendu : une ligne par scarabe de la salle, avec nom_lie = Emperor Vek'lor.
-- Toute ligne ou nom_lie est NULL est un scarabe qui mordra de lui-meme.
SET @q := CONCAT(
    'SELECT cr.`guid`, cr.`', @col, '` AS entry, ct.`name`, ',
    '       ROUND(cr.`position_x`, 1) AS x, ',
    '       ROUND(cr.`position_y`, 1) AS y, ',
    '       lr.`linkedGuid` AS guid_lie, lr.`linkType` AS type_lien, ',
    '       lcr.`', @col, '` AS entry_lie, lct.`name` AS nom_lie, ',
    '       IF(lcr.`', @col, '` = 15276, \'non\', \'OUI\') AS mord_tout_seul ',
    'FROM `creature` cr ',
    'JOIN `creature_template` ct ON ct.`entry` = cr.`', @col, '` ',
    'LEFT JOIN `linked_respawn` lr ON lr.`guid` = cr.`guid` ',
    'LEFT JOIN `creature` lcr      ON lcr.`guid` = lr.`linkedGuid` ',
    'LEFT JOIN `creature_template` lct ON lct.`entry` = lcr.`', @col, '` ',
    'WHERE cr.`map` = 531 AND cr.`', @col, '` IN (15316, 15317) ',
    'ORDER BY (lcr.`', @col, '` = 15276) ASC, cr.`guid`'
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- Le compte, pour lire le resultat ci-dessus d'un coup d'oeil.
-- Attention : l'exception du script ne vaut que pour Vek'lor. Un scarabe lie
-- a Vek'nilash, ou lie a rien, passe le test et mord quand meme.
SET @q := CONCAT(
    'SELECT COUNT(*) AS scarabes_de_la_carte_531, ',
    '       SUM(lcr.`', @col, '` = 15276)                    AS lies_a_veklor_donc_calmes, ',
    '       SUM(lcr.`', @col, '` <=> 15276 = 0 OR lcr.`guid` IS NULL) AS mordeurs ',
    'FROM `creature` cr ',
    'LEFT JOIN `linked_respawn` lr  ON lr.`guid`  = cr.`guid` ',
    'LEFT JOIN `creature` lcr       ON lcr.`guid` = lr.`linkedGuid` ',
    'WHERE cr.`map` = 531 AND cr.`', @col, '` IN (15316, 15317)'
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
