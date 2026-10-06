-- mod-playerbots-bis : les objets sur lesquels le projet attend une reponse
-- de la base monde du serveur, et qu'aucun raisonnement ne peut trancher d'ici.
--
--   mysql -u acore -p acore_world --table < tools/objets_en_attente.sql
--
-- Sous PowerShell, "source" n'existe pas et -e avale mal un fichier :
--   Get-Content tools\objets_en_attente.sql -Raw |
--     & $mysql -uacore -padmin acore_world --table --default-character-set=utf8mb4

-- ---------------------------------------------------------------------
-- 1. Les deux noms ZG que la base ne reconnait pas.
--
-- Lizardscale Eyepatch manque a sept listes, Cloak of the Hakkari Worshipers
-- a cinq. Ce sont de vrais objets de Zul'Gurub, donc c'est l'ORTHOGRAPHE qui
-- differe, pas l'objet. La recherche est volontairement large : il faut voir
-- le nom tel que la base l'ecrit, pas confirmer celui que je suppose.
-- ---------------------------------------------------------------------
SELECT 'ZG - casque et cape introuvables' AS question;
SELECT `entry`, `name`, `InventoryType`, `ItemLevel`, `Quality`
FROM `item_template`
WHERE `name` LIKE '%Eyepatch%'
   OR `name` LIKE '%Lizardscale%'
   OR `name` LIKE '%Worship%'
ORDER BY `name`;

-- ---------------------------------------------------------------------
-- 2. Warblade of the Hakkari : deux entrees pour un seul nom.
--
-- L'objet existe en version main droite et main gauche. Les fichiers resolvent
-- par MIN(entry), donc ils prennent l'une des deux sans savoir laquelle. Il est
-- pour l'instant ECARTE des fichiers 40 et 47, et garde au creneau 15 dans 41
-- et 43 sur une hypothese NON VERIFIEE.
--
-- InventoryType 13 = arme a une main, 22 = main gauche, 23 = tenu en main gauche.
-- ---------------------------------------------------------------------
SELECT 'Warblade of the Hakkari - quelle entree est la main gauche' AS question;
SELECT `entry`, `name`, `InventoryType`, `ItemLevel`
FROM `item_template`
WHERE `name` LIKE '%Hakkari%'
ORDER BY `name`, `entry`;

-- ---------------------------------------------------------------------
-- 3. Les cinq objets ARTISANAUX bloques par la regle reputation.
--
-- La regle du projet ecarte le PvP et la reputation, et la page wowtbc.gg les
-- annonce comme "Reputation ... - Revered". Mais pour ceux-la, c'est le PATRON
-- qui demande la reputation, pas le port : un bot qui recoit l'objet fini n'a
-- aucune reputation a gagner. Si RequiredReputationRank vaut 0, ils peuvent
-- revenir dans les listes par --garde, et plusieurs y retrouveraient leur
-- rang 1 - Corehound Belt est rang 1 de ceinture chez le druide soigneur,
-- Molten Belt chez le druide farouche.
-- ---------------------------------------------------------------------
SELECT 'Objets artisanaux : le PORTEUR exige-t-il vraiment une reputation' AS question;
SELECT `entry`, `name`, `InventoryType`, `ItemLevel`,
       `RequiredReputationFaction`, `RequiredReputationRank`, `requiredhonorrank`
FROM `item_template`
WHERE `name` IN ('Chromatic Gauntlets', 'Nightfall', 'Corehound Belt',
                 'Molten Belt', 'Flarecore Leggings')
ORDER BY `name`;
