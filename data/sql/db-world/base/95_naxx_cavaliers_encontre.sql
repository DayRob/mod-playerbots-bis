-- mod-playerbots-bis : rendre les Quatre Cavaliers visibles aux modules qui
-- lisent instance_encounters.
--
-- CE QUI MANQUE, ET POURQUOI CA SE VOIT. mod-dungeon-clear ne code aucune
-- liste de boss en dur : son BossSpawnIndex::Build() croise trois sources -
-- les encontres du DBC, la table instance_encounters, et les creatures
-- reellement apparues dans le monde. Il lui faut donc un CREDIT DE CREATURE
-- pour voir un boss.
--
-- Or l'encontre 1009 est creditee par un SORT, pas par une creature :
--
--     entry 1009 | creditType 1 | creditEntry 59450 | The Four Horsemen
--
-- creditType 1 = le sort que le script d'instance lance quand les quatre sont
-- morts. Aucune creature n'y est rattachee, donc le boss n'existe pas pour
-- l'index. Les quatre autres encontres de Naxxramas 40, elles, sont bien en
-- creditType 0 : Gothik 1008, Patchwerk 1010, Saphiron 1014, Kel'Thuzad 1015.
--
-- Resultat en jeu : ".dc go Four Horsemen" repond "Could not find boss
-- matching", et apres Gothik (1008) le planificateur saute directement a
-- Patchwerk (1010). Le Quartier Militaire ne se termine jamais tout seul.
--
-- Ce n'est pas propre a la version 40 : les entrees Wrath des Cavaliers -
-- 16062, 16063, 16064, 16065 - n'ont elles non plus aucun credit de creature.
--
-- POURQUOI UN REMPLACEMENT ET NON UN AJOUT. `entry` est la CLE PRIMAIRE de
-- instance_encounters : une encontre ne porte qu'un seul credit. Ajouter une
-- seconde ligne pour 1009 rend "Duplicate entry '1009' for key PRIMARY". Le
-- credit par sort doit donc ceder la place a un credit par creature.
--
-- On choisit Thane Korth'azz (351039) : c'est celui que la strategie "naxx"
-- de mod-playerbots cible en premier pour tout le monde sauf les tanks
-- secondaires. Le module conduira donc le groupe exactement la ou les bots
-- vont se placer.
--
-- CE QUE CA CHANGE AILLEURS, et c'est le prix a payer. Le coeur marquait
-- l'encontre terminee quand le script lancait 59450, c'est-a-dire a la mort
-- du QUATRIEME Cavalier ; il la marquera desormais a la mort de Korth'azz.
-- Cela ne touche QUE le masque d'encontres du verrou d'instance - affichage
-- du verrou, hauts faits, recherche de groupe. Le script continue de lancer
-- 59450, simplement plus personne ne l'ecoute.
--
-- La porte de Saphiron n'est PAS concernee : elle depend de SetBossState dans
-- instance_naxxramas.cpp, qui tient ses propres etats de boss et ne lit pas
-- instance_encounters. Aucun risque d'ouvrir le quartier trop tot.
--
-- POUR REVENIR EN ARRIERE :
--     UPDATE `instance_encounters`
--     SET `creditType` = 1, `creditEntry` = 59450, `comment` = 'The Four Horsemen'
--     WHERE `entry` = 1009;

-- Un UPDATE est naturellement relancable. Le EXISTS protege un serveur qui
-- n'aurait pas la version 40 de Naxxramas : sans la creature, la ligne reste
-- telle quelle plutot que de pointer dans le vide.
UPDATE `instance_encounters`
SET `creditType`  = 0,
    `creditEntry` = 351039,
    `comment`     = 'The Four Horsemen (credit creature - mod-playerbots-bis)'
WHERE `entry` = 1009
  AND EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 351039);

-- VERIFICATION 1 - l'encontre 1009 doit afficher creditType 0 et le Cavalier.
SELECT `entry`, `creditType`, `creditEntry`, `comment`
FROM `instance_encounters` WHERE `entry` = 1009;

-- VERIFICATION 2 - la creature doit exister. Une ligne attendue.
--
-- Son APPARITION dans le monde compte autant, mais la colonne qui la porte a
-- change de nom selon la revision du coeur - `creature`.`id` avant le support
-- des apparitions multiples, `id1` apres - et ce fichier est rejoue par le
-- systeme de mises a jour. Une colonne inconnue ferait echouer tout le
-- fichier, donc le controle se fait a la main :
--
--     SELECT COUNT(*) FROM `creature` WHERE `id`  = 351039;   -- ancien schema
--     SELECT COUNT(*) FROM `creature` WHERE `id1` = 351039;   -- nouveau
SELECT `entry`, `name` FROM `creature_template` WHERE `entry` = 351039;
