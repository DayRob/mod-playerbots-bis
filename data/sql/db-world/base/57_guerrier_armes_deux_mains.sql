-- mod-playerbots-bis : l'arme a deux mains du Guerrier Armes, paliers 30 et 40.
--
-- D'OU VIENNENT CES LIGNES, ET POURQUOI C'EST UNE EXCEPTION
-- --------------------------------------------------------
-- Toutes les autres listes de ce depot sont converties depuis wowtbc.gg. Pas
-- celles-ci : la page Arms de ces deux phases n'a jamais ete recuperee, et le
-- creneau 15 est reste VIDE pour la seule spe qui vit de son arme. Un Guerrier
-- Armes sans cible au creneau 15 ne reclame aucune arme, jamais.
--
-- Elles sont donc deduites de la BASE DU SERVEUR : toutes les armes a deux
-- mains lachees dans Zul'Gurub (carte 309) et Blackwing Lair (carte 469),
-- croisees avec leurs statistiques. Le classement ci-dessous est un jugement,
-- pas une page recopiee - c'est la difference avec les autres fichiers, et
-- c'est pour ca qu'elle est ecrite ici.
--
-- SUR QUOI LE CLASSEMENT REPOSE
-- -----------------------------
-- Armes vit de Frappe mortelle, donc de la FORCE et du DEGAT MAXIMUM, et la
-- lenteur sert les coups blancs et Blessure profonde. Le DPS affiche sur
-- l'arme compte moins : deux armes de meme DPS ne valent pas la meme chose si
-- l'une frappe a 3.80 et l'autre a 2.80.
--
-- CE QUI A ETE ECARTE, ET POURQUOI
-- --------------------------------
-- Warp-Master's Maul (30395) : niveau d'objet 114 - trois fois Blackwing Lair,
-- il vient d'un module - et lache par Ebonroc a 100 %. Il ne figure pas ici
-- parce que ses statistiques sont Intelligence 21 et critique des SORTS 16 :
-- c'est une arme de lanceur de sorts, quel que soit son niveau d'objet. Un
-- guerrier n'en tirerait rien.
--
-- Zulian Stone Axe (19900) : Intelligence 22. Meme raison.
--
-- Les batons (Shadow Wing Focus Staff, Jin'do's Judgement, Zulian Ceremonial
-- Staff) : un guerrier peut les porter, mais ils ne portent ni Force ni
-- puissance d'attaque.
--
-- Le butin de trash a 0,1 % des Death Talon Wyrmguard (Blade of Hanna,
-- Massacre Sword, Brutehammer...) : niveau 58 a 65, sans rapport avec le
-- palier.
--
-- LES IDENTIFIANTS SONT EN DUR, pas des noms. Ils viennent d'une requete sur
-- la base elle-meme, donc le detour par item_template.name - utile quand la
-- source est une page web - n'apporterait ici qu'un risque de ne pas resoudre.

-- Rejouable, et sans toucher aux autres creneaux : seules les lignes du
-- creneau 15 de ce couple classe/spe partent.
DELETE FROM `playerbots_bis_item`
WHERE `class` = 1 AND `spec` = 0 AND `slot` = 15 AND `tier_id` IN (30, 40);

-- PALIER 30 - Blackwing Lair.
--
--   1. The Untamed Blade   3.40, max 289, Agi 22 Endu 16, proc de Force
--   2. Drake Talon Cleaver 3.40, max 300, For 22 Endu 17, proc
--   3. Herald of Woe       3.40, max 300, For 31 Endu 22, sans proc
--   4. Draconic Maul       3.50, max 282, For 27 Endu 19
--   5. Draconic Avenger    3.20, max 262, For 21 Endu 18
--
-- Les deux premieres se jouent sur leur proc, la seule chose que la base ne
-- m'a pas dite : item_template porte l'identifiant du sort, pas son effet.
-- The Untamed Blade passe devant malgre ses statistiques d'Agilite parce que
-- son proc donne de la Force, et que c'est le choix retenu par les guides
-- Vanilla pour Armes. Herald of Woe a la meilleure Force brute des cinq (31)
-- et le meme degat maximum, mais rien qui se declenche - d'ou la 3e place et
-- non la 1re.
INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`) VALUES
(1, 0, 15, 0, 30, 19334, 1, 'deduit de la base - The Untamed Blade (BWL, 3.40, proc Force)'),
(1, 0, 15, 0, 30, 19353, 2, 'deduit de la base - Drake Talon Cleaver (BWL, 3.40, For 22)'),
(1, 0, 15, 0, 30, 19357, 3, 'deduit de la base - Herald of Woe (BWL, 3.40, For 31)'),
(1, 0, 15, 0, 30, 19358, 4, 'deduit de la base - Draconic Maul (BWL, 3.50, For 27)'),
(1, 0, 15, 0, 30, 19354, 5, 'deduit de la base - Draconic Avenger (BWL, 3.20, For 21)');

-- PALIER 40 - Zul'Gurub, qui garde les armes de Blackwing Lair.
--
-- Une liste de palier nomme ce qu'il y a de MIEUX a ce moment-la, pas ce qui
-- tombe dans ce raid-la : Zul'Gurub ne remplace pas une arme de Blackwing Lair
-- par le seul fait d'etre la phase suivante. Les trois premieres de BWL
-- restent donc devant.
--
--   4. Zin'rokh    3.80, max 295, Endurance 28 et RIEN d'autre
--   5. Halberd of Smiting  3.50, max 263, aucune statistique
--   6. Jeklik's Crusher    3.60, max 248, aucune statistique
--
-- Zin'rokh est l'arme la plus LENTE des deux raids, ce qui sert Armes, et je
-- l'avais annoncee en tete avant de voir ses statistiques. Elle ne porte que
-- de l'Endurance : aucune Force, aucune puissance d'attaque. Elle passe donc
-- derriere les trois de BWL, qui en portent toutes.
INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`) VALUES
(1, 0, 15, 0, 40, 19334, 1, 'deduit de la base - The Untamed Blade (BWL, 3.40, proc Force)'),
(1, 0, 15, 0, 40, 19353, 2, 'deduit de la base - Drake Talon Cleaver (BWL, 3.40, For 22)'),
(1, 0, 15, 0, 40, 19357, 3, 'deduit de la base - Herald of Woe (BWL, 3.40, For 31)'),
(1, 0, 15, 0, 40, 19854, 4, 'deduit de la base - Zin''rokh (ZG, 3.80, Endu seule)'),
(1, 0, 15, 0, 40, 19874, 5, 'deduit de la base - Halberd of Smiting (ZG, 3.50)'),
(1, 0, 15, 0, 40, 19918, 6, 'deduit de la base - Jeklik''s Crusher (ZG, 3.60)');

-- VERIFICATION 1 - un identifiant que la base ne connait pas (aucune ligne = bon).
-- Ils viennent d'une requete sur cette base, donc ce controle ne devrait jamais
-- rien rendre : s'il parle, c'est que le fichier a ete repris sur une autre
-- installation que celle qui l'a produit.
SELECT b.`tier_id`, b.`rank`, b.`item_id` AS nom_non_resolu
FROM `playerbots_bis_item` b
LEFT JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`class` = 1 AND b.`spec` = 0 AND b.`slot` = 15 AND i.`entry` IS NULL;

-- VERIFICATION 2 - ce que le creneau 15 d'Armes contient desormais.
SELECT b.`tier_id`, b.`rank`, i.`name`,
       ROUND(i.`delay` / 1000, 2) AS vitesse, i.`dmg_max1` AS degats_max
FROM `playerbots_bis_item` b
JOIN `item_template` i ON i.`entry` = b.`item_id`
WHERE b.`class` = 1 AND b.`spec` = 0 AND b.`slot` = 15
ORDER BY b.`tier_id`, b.`rank`;
