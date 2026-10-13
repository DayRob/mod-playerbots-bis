-- mod-playerbots-bis : les armes a deux mains candidates pour Guerrier Armes
-- au palier 60 (Ahn'Qiraj), avec les chiffres dont Armes depend.
--
-- A QUOI CA SERT
-- --------------
-- Le fichier 57 pose un classement pour le creneau 15 d'Armes au palier 60.
-- Ses deux premieres places - Dark Edge of Insanity et Ashkandi - viennent des
-- guides de la phase, PAS d'une mesure sur la base, contrairement aux paliers
-- 30 et 40 du meme fichier. Cette requete donne les chiffres de TA base pour
-- trancher.
--
-- CE QU'ELLE MONTRE, ET POURQUOI
-- ------------------------------
-- Frappe mortelle prend le DEGAT MAXIMUM de l'arme et la FORCE du porteur, et
-- la lenteur sert les coups blancs et Blessure profonde. Le DPS affiche compte
-- moins : deux armes de meme DPS ne valent pas la meme chose si l'une frappe a
-- 3.80 et l'autre a 2.80. Le tri suit donc le degat maximum, puis la lenteur.
--
-- La colonne "proc" ne dit QUE si un sort est attache a l'arme, jamais ce
-- qu'il fait : item_template porte l'identifiant du sort, pas son effet. C'est
-- la seule chose que la base ne peut pas dire, et c'est pour ca que The
-- Untamed Blade garde une place haute malgre des statistiques d'Agilite - son
-- proc donne de la Force.
--
-- POUR LA PASSER
-- --------------
--   Get-Content tools\armes_deux_mains_palier_60.sql -Raw |
--     & $m -uacore -padmin acore_world --table
--
-- Un nom absent du resultat n'existe pas sous ce nom dans ta base ; c'est une
-- information, pas une panne.

SELECT
    i.`entry`,
    i.`name`,
    ROUND(i.`delay` / 1000, 2) AS vitesse,
    i.`dmg_min1`               AS degats_min,
    i.`dmg_max1`               AS degats_max,
    ROUND((i.`dmg_min1` + i.`dmg_max1`) / 2 / (i.`delay` / 1000), 1) AS dps,
    (CASE WHEN i.`stat_type1` = 4 THEN i.`stat_value1` ELSE 0 END +
           CASE WHEN i.`stat_type2` = 4 THEN i.`stat_value2` ELSE 0 END +
           CASE WHEN i.`stat_type3` = 4 THEN i.`stat_value3` ELSE 0 END +
           CASE WHEN i.`stat_type4` = 4 THEN i.`stat_value4` ELSE 0 END +
           CASE WHEN i.`stat_type5` = 4 THEN i.`stat_value5` ELSE 0 END +
           CASE WHEN i.`stat_type6` = 4 THEN i.`stat_value6` ELSE 0 END +
           CASE WHEN i.`stat_type7` = 4 THEN i.`stat_value7` ELSE 0 END +
           CASE WHEN i.`stat_type8` = 4 THEN i.`stat_value8` ELSE 0 END +
           CASE WHEN i.`stat_type9` = 4 THEN i.`stat_value9` ELSE 0 END +
           CASE WHEN i.`stat_type10` = 4 THEN i.`stat_value10` ELSE 0 END) AS force_,
    (CASE WHEN i.`stat_type1` = 7 THEN i.`stat_value1` ELSE 0 END +
           CASE WHEN i.`stat_type2` = 7 THEN i.`stat_value2` ELSE 0 END +
           CASE WHEN i.`stat_type3` = 7 THEN i.`stat_value3` ELSE 0 END +
           CASE WHEN i.`stat_type4` = 7 THEN i.`stat_value4` ELSE 0 END +
           CASE WHEN i.`stat_type5` = 7 THEN i.`stat_value5` ELSE 0 END +
           CASE WHEN i.`stat_type6` = 7 THEN i.`stat_value6` ELSE 0 END +
           CASE WHEN i.`stat_type7` = 7 THEN i.`stat_value7` ELSE 0 END +
           CASE WHEN i.`stat_type8` = 7 THEN i.`stat_value8` ELSE 0 END +
           CASE WHEN i.`stat_type9` = 7 THEN i.`stat_value9` ELSE 0 END +
           CASE WHEN i.`stat_type10` = 7 THEN i.`stat_value10` ELSE 0 END) AS endurance,
    (CASE WHEN i.`stat_type1` = 3 THEN i.`stat_value1` ELSE 0 END +
           CASE WHEN i.`stat_type2` = 3 THEN i.`stat_value2` ELSE 0 END +
           CASE WHEN i.`stat_type3` = 3 THEN i.`stat_value3` ELSE 0 END +
           CASE WHEN i.`stat_type4` = 3 THEN i.`stat_value4` ELSE 0 END +
           CASE WHEN i.`stat_type5` = 3 THEN i.`stat_value5` ELSE 0 END +
           CASE WHEN i.`stat_type6` = 3 THEN i.`stat_value6` ELSE 0 END +
           CASE WHEN i.`stat_type7` = 3 THEN i.`stat_value7` ELSE 0 END +
           CASE WHEN i.`stat_type8` = 3 THEN i.`stat_value8` ELSE 0 END +
           CASE WHEN i.`stat_type9` = 3 THEN i.`stat_value9` ELSE 0 END +
           CASE WHEN i.`stat_type10` = 3 THEN i.`stat_value10` ELSE 0 END) AS agilite,
    IF(i.`spellid_1` > 0, 'oui', '-') AS proc,
    i.`ItemLevel` AS niveau_objet
FROM `item_template` i
WHERE i.`name` IN (
    'Dark Edge of Insanity',
    'Ashkandi, Greatsword of the Brotherhood',
    'The Untamed Blade',
    'Obsidian Edged Blade',
    'Bonereaver''s Edge',
    'Herald of Woe',
    'Drake Talon Cleaver',
    'Zin''rokh, Destroyer of Worlds',
    'Arcanite Reaper'
)
ORDER BY i.`dmg_max1` DESC, i.`delay` DESC;
