-- mod-playerbots-bis : retire le PvP et la reputation des listes VANILLA.
--
-- Pourquoi ce fichier existe
-- --------------------------
-- La regle du projet depuis le debut : pas de PvP, pas de reputation. Les
-- fichiers cures (03 a 16) la respectent - ils sont ecrits a la main a partir
-- des guides. Le fichier 02, lui, ne la respecte pas : c'est la conversion de
-- la table d'origine playerbots_bis_gear, ses rangs ne viennent d'aucun guide,
-- et il place par exemple les epaulieres PvP du demoniste en RANG 1 au palier
-- 20. Tant qu'une spe n'a pas son fichier cure, c'est lui qui la gouverne.
--
-- Ce que ce fichier supprime, et sur quelle preuve
-- ------------------------------------------------
-- Trois criteres, tous lisibles dans la base monde. Aucun ne repose sur le nom
-- de l'objet.
--
--   1. item_template.RequiredReputationRank > 0
--      L'objet exige une reputation. C'est le mecanisme meme des recompenses de
--      faction.
--
--   2. item_template.requiredhonorrank > 0
--      Rang de haut fait exige. Souvent 0 en 3.3.5 - le systeme a change en 2.0
--      et les anciens rangs ont ete effaces - mais le test est gratuit.
--
--   3. npc_vendor.ExtendedCost > 0
--      L'objet est VENDU contre autre chose que de l'or : honneur, marques de
--      champ de bataille, insignes. En Vanilla, c'est exactement la definition
--      de l'equipement PvP.
--
--      Le detail du cout vit dans ItemExtendedCost.dbc, cote CLIENT, donc on ne
--      peut pas joindre dessus - mais on n'en a pas besoin : le simple fait
--      qu'un cout etendu existe suffit a trancher.
--
-- Ce qu'il ne supprime PAS
-- -------------------------
-- Une premiere version reconnaissait le PvP aux prefixes des sets de rang
-- ("Lieutenant Commander's", "Warlord's"...). Un test sur une base reelle a
-- montre que ca supprime aussi "Commander's Crest", qui est un objet PvE. Les
-- noms restent donc en SIGNALEMENT (requete 4c) et ne declenchent rien : a toi
-- de trancher sur les rares cas qu'ils revelent.
--
-- Portee : paliers 10 a 70 (Vanilla) uniquement. Les paliers TBC et WotLK ne
-- sont atteints par personne et leurs listes n'ont jamais ete revues.

-- ---------------------------------------------------------------------------
-- 1. Ce qui va partir. A lire AVANT le DELETE.
-- ---------------------------------------------------------------------------
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, i.`name`,
       CASE
           WHEN i.`RequiredReputationRank` > 0
                THEN CONCAT('reputation (faction ', i.`RequiredReputationFaction`, ')')
           WHEN i.`requiredhonorrank` > 0
                THEN 'rang de haut fait'
           ELSE 'vendu contre honneur / marques'
       END AS `motif`
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`tier_id` BETWEEN 10 AND 70
  AND (
        i.`RequiredReputationRank` > 0
     OR i.`requiredhonorrank` > 0
     OR EXISTS (SELECT 1 FROM `npc_vendor` v
                WHERE v.`item` = b.`item_id` AND v.`ExtendedCost` > 0)
      )
ORDER BY b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`;

-- ---------------------------------------------------------------------------
-- 2. La suppression.
-- ---------------------------------------------------------------------------
DELETE b FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`tier_id` BETWEEN 10 AND 70
  AND (
        i.`RequiredReputationRank` > 0
     OR i.`requiredhonorrank` > 0
     OR EXISTS (SELECT 1 FROM `npc_vendor` v
                WHERE v.`item` = b.`item_id` AND v.`ExtendedCost` > 0)
      );

-- ---------------------------------------------------------------------------
-- 3. Verifications.
-- ---------------------------------------------------------------------------

-- 3a. Il ne doit plus rien rester.
SELECT COUNT(*) AS `pvp_ou_reputation_restants`
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`tier_id` BETWEEN 10 AND 70
  AND (i.`RequiredReputationRank` > 0
       OR i.`requiredhonorrank` > 0
       OR EXISTS (SELECT 1 FROM `npc_vendor` v
                  WHERE v.`item` = b.`item_id` AND v.`ExtendedCost` > 0));

-- 3b. SIGNALEMENT, sans suppression : ce qui PORTE un nom de set de rang PvP
--     mais qu'aucun des trois criteres n'a attrape. Sur une base saine la liste
--     est vide ; si elle ne l'est pas, regarde chaque ligne - ce peut etre un
--     vrai objet PvP absent des tables de vendeur, comme ce peut etre un objet
--     PvE dont le nom commence par un titre.
SELECT b.`tier_id`, b.`class`, b.`spec`, b.`slot`, b.`rank`, i.`name`
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`tier_id` BETWEEN 10 AND 70
  AND (i.`name` LIKE 'Lieutenant Commander''s %' OR i.`name` LIKE 'Knight-Lieutenant''s %'
    OR i.`name` LIKE 'Knight-Captain''s %'       OR i.`name` LIKE 'Knight-Champion''s %'
    OR i.`name` LIKE 'Marshal''s %'              OR i.`name` LIKE 'Field Marshal''s %'
    OR i.`name` LIKE 'Grand Marshal''s %'        OR i.`name` LIKE 'Sergeant Major''s %'
    OR i.`name` LIKE 'Master Sergeant''s %'      OR i.`name` LIKE 'First Sergeant''s %'
    OR i.`name` LIKE 'Senior Sergeant''s %'      OR i.`name` LIKE 'Stone Guard''s %'
    OR i.`name` LIKE 'Blood Guard''s %'          OR i.`name` LIKE 'Legionnaire''s %'
    OR i.`name` LIKE 'Centurion''s %'            OR i.`name` LIKE 'Champion''s %'
    OR i.`name` LIKE 'Lieutenant General''s %'   OR i.`name` LIKE 'Warlord''s %'
    OR i.`name` LIKE 'High Warlord''s %')
ORDER BY b.`tier_id`, b.`class`, b.`spec`;

-- 3c. Couverture restante par spe aux paliers 20 et 30. C'est la liste des
--     trous a combler avec un guide : une spe a 3 creneaux couverts sur 17 n'a
--     pas une liste, elle a des restes.
SELECT b.`tier_id`, b.`class`, b.`spec`, COUNT(DISTINCT b.`slot`) AS `creneaux_couverts`
FROM `playerbots_bis_item` b
WHERE b.`tier_id` IN (20, 30)
GROUP BY b.`tier_id`, b.`class`, b.`spec`
ORDER BY `creneaux_couverts` ASC, b.`tier_id`, b.`class`, b.`spec`;
