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

-- Et ou ils se trouvent : la carte doit etre 531 pour les deux jumeaux,
-- sinon le case 531 ajoute dans PlayerbotAI.cpp ne les verra jamais.
SELECT cr.`id1`     AS entry,
       ct.`name`,
       cr.`map`     AS carte,
       ROUND(cr.`position_x`, 1) AS x,
       ROUND(cr.`position_y`, 1) AS y,
       ROUND(cr.`position_z`, 1) AS z
FROM `creature` cr
JOIN `creature_template` ct ON ct.`entry` = cr.`id1`
WHERE cr.`id1` IN (15275, 15276)
ORDER BY cr.`id1`;

-- Les scarabes et scorpions de la salle : sont-ils seulement passifs, ou
-- carrement non hostiles ? Un bot ne peut prendre pour cible que ce qui lui
-- est hostile, donc la faction decide si le probleme est cote IA ou cote base.
-- Le script ne leur met la faction 16 (hostile) et REACT_AGGRESSIVE qu'au
-- reveil, par Mutate Bug (802) ou Explode Bug (804) : avant ca, la valeur
-- ci-dessous est celle qu'ils portent en permanence dans la salle.
SELECT c.`entry`,
       c.`name`,
       c.`faction`,
       c.`npcflag`,
       c.`unit_flags`,
       c.`flags_extra`,
       c.`lootid`,
       c.`rank`      AS rang_pnj,
       c.`ScriptName` AS script,
       (SELECT COUNT(*) FROM `creature` s WHERE s.`id1` = c.`entry` AND s.`map` = 531) AS exemplaires_dans_aq40
FROM `creature_template` c
WHERE c.`entry` IN (15316, 15317)
ORDER BY c.`entry`;
