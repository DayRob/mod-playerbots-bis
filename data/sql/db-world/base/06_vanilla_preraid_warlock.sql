-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid) - Demoniste (classe 9).
--
-- Complete 04_vanilla_preraid_wowsims.sql, qui ne donne QU'UN objet par creneau
-- pour cette classe : l'export WoWSims n'a pas de colonne `rank`. Un bot ne
-- reconnaissait donc qu'une seule piece par creneau comme etant la sienne, et la
-- fenetre d'etat n'avait aucun repli a proposer.
--
-- IMPORTANT - ORDRE D'IMPORT : ce fichier doit passer APRES 04. Rejouer 04
-- ensuite effacerait ces lignes et rendrait au demoniste sa liste a un rang.
--
-- Les trois specialisations partagent la meme liste : en pre-raid, Affliction,
-- Demonologie et Destruction courent apres la meme puissance des sorts.
--
-- Les identifiants ne sont pas ecrits en dur : chaque ligne est resolue par nom
-- contre item_template a l'import, et les requetes de verification en fin de
-- fichier listent ce qui n'a pas ete resolu.
--
-- ABSENTS VOLONTAIREMENT : les objets a suffixe aleatoire ("... of Shadow
-- Wrath"), que le guide place souvent en tete. Ils n'ont pas d'identifiant
-- unique dans item_template - un meme nom de base couvre des dizaines de
-- suffixes - donc rien a pointer. C'est une limite de la table, pas un oubli.
--
-- RESERVE SUR LA SOURCE : le guide est ecrit pour Season of Mastery, qui ouvre
-- des le depart le systeme d'honneur, Dire Maul et quelques objets du Loot
-- Revamp. Les objets existent dans item_template d'un serveur 3.3.5, mais le
-- classement suppose cette disponibilite. Les pieces PvP de rang sont donc
-- classees 2 ou 3, jamais 1 : un bot ne fera jamais le rang.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage.
-- faction : 0 = les deux, 1 = Alliance, 2 = Horde.
--
-- Source : guide Best-in-Slot Pre-Raid "Warlock DPS" de Wowhead Classic.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 9 AND `spec` IN (0, 1, 2);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wl`;
CREATE TEMPORARY TABLE `bis_seed_wl` (
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- Note collation : item_template.name est en utf8mb4_unicode_ci sur AzerothCore,
-- alors qu'une table creee sans COLLATE explicite herite du defaut du serveur.
-- Les jointures forcent donc la meme collation des deux cotes.

INSERT INTO `bis_seed_wl` (`slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
( 0, 0, 1, 'Spellweaver''s Turban'),
( 0, 1, 2, 'Lieutenant Commander''s Dreadweave Cowl'),   -- Alliance uniquement
( 0, 2, 2, 'Champion''s Dreadweave Cowl'),   -- Horde uniquement
( 0, 0, 2, 'Deathmist Mask'),
( 0, 0, 3, 'Green Lens'),
( 0, 0, 3, 'Felcloth Hood'),
( 0, 0, 3, 'Crimson Felt Hat'),
( 0, 0, 3, 'Cap of the Scarlet Savant'),
( 0, 0, 3, 'Shadoweave Mask'),
( 0, 0, 3, 'Dreamweave Circlet'),
( 0, 0, 3, 'Crown of the Ogre King'),
-- Cou (1)
( 1, 0, 1, 'Diana''s Pearl Necklace'),
( 1, 0, 2, 'Dark Advisor''s Pendant'),
( 1, 0, 3, 'Star of Mystaria'),
( 1, 0, 3, 'Tempest Talisman'),
( 1, 0, 3, 'Anastari Heirloom'),
-- Epaules (2)
( 2, 1, 1, 'Lieutenant Commander''s Dreadweave Spaulders'),   -- Alliance uniquement
( 2, 2, 1, 'Champion''s Dreadweave Spaulders'),   -- Horde uniquement
( 2, 0, 2, 'Felcloth Shoulders'),
( 2, 0, 2, 'Burial Shawl'),
( 2, 0, 3, 'Kentic Amice'),
( 2, 0, 3, 'Thuzadin Mantle'),
( 2, 0, 3, 'Shroud of the Nathrezim'),
( 2, 0, 3, 'Deathmist Mantle'),
( 2, 0, 3, 'Shadoweave Shoulders'),
( 2, 0, 3, 'Deadwalker Mantle'),
-- Torse (4)
( 4, 0, 1, 'Robe of the Void'),
( 4, 0, 1, 'Robe of Winter Night'),
( 4, 0, 3, 'Felcloth Robe'),
( 4, 0, 3, 'Deathmist Robe'),
( 4, 0, 3, 'Robe of Everlasting Night'),
( 4, 0, 3, 'Robes of the Royal Crown'),
( 4, 0, 3, 'Dreamweave Vest'),
( 4, 0, 3, 'Shadoweave Robe'),
-- Ceinture (5)
( 5, 0, 1, 'Ban''thok Sash'),
( 5, 1, 2, 'Highlander''s Cloth Girdle'),   -- Alliance uniquement
( 5, 2, 2, 'Defiler''s Cloth Girdle'),   -- Horde uniquement
( 5, 0, 3, 'Felheart Belt'),
( 5, 1, 3, 'Stormpike Cloth Girdle'),   -- Alliance uniquement
( 5, 2, 3, 'Frostwolf Cloth Belt'),   -- Horde uniquement
( 5, 0, 3, 'Belt of the Archmage'),
( 5, 0, 3, 'Clutch of Andros'),
( 5, 0, 3, 'Deathmist Belt'),
( 5, 0, 3, 'Star Belt'),
-- Jambes (6)
( 6, 0, 1, 'Flarecore Leggings'),
( 6, 0, 2, 'Leggings of Torment'),
( 6, 0, 2, 'Skyshroud Leggings'),
( 6, 1, 3, 'Knight-Captain''s Dreadweave Legguards'),   -- Alliance uniquement
( 6, 2, 3, 'Legionnaire''s Dreadweave Legguards'),   -- Horde uniquement
( 6, 0, 3, 'Felcloth Pants'),
( 6, 0, 3, 'Deathmist Leggings'),
( 6, 0, 3, 'Shadoweave Pants'),
-- Pieds (7)
( 7, 0, 1, 'Maleki''s Footwraps'),
( 7, 0, 2, 'Omnicast Boots'),
( 7, 0, 2, 'Dragonrider Boots'),
( 7, 1, 2, 'Knight-Lieutenant''s Dreadweave Walkers'),   -- Alliance uniquement
( 7, 2, 2, 'Blood Guard''s Dreadweave Walkers'),   -- Horde uniquement
( 7, 0, 3, 'Deathmist Sandals'),
( 7, 1, 3, 'Highlander''s Cloth Boots'),   -- Alliance uniquement
( 7, 2, 3, 'Defiler''s Cloth Boots'),   -- Horde uniquement
( 7, 0, 3, 'Shadoweave Boots'),
-- Poignets (8)
( 8, 0, 1, 'Flameweave Cuffs'),
( 8, 0, 2, 'Felheart Bracers'),
( 8, 0, 2, 'Sublime Wristguards'),
( 8, 0, 3, 'Deathmist Bracers'),
-- Mains (9)
( 9, 0, 1, 'Felcloth Gloves'),
( 9, 0, 1, 'Deathmist Wraps'),
( 9, 0, 2, 'Hands of Power'),
( 9, 0, 2, 'Gloves of Spell Mastery'),
( 9, 0, 2, 'Earth Warder''s Gloves'),
( 9, 1, 2, 'Knight-Lieutenant''s Dreadweave Handwraps'),   -- Alliance uniquement
( 9, 2, 2, 'Blood Guard''s Dreadweave Handwraps'),   -- Horde uniquement
( 9, 0, 3, 'Mana Shaping Handwraps'),
( 9, 0, 3, 'Dreamweave Gloves'),
( 9, 0, 3, 'Shadoweave Gloves'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(10, 0, 1, 'Rune Band of Wizardry'),
(10, 0, 1, 'Don Mauricio''s Band of Domination'),
(10, 1, 2, 'Songstone of Ironforge'),   -- Alliance uniquement
(10, 2, 2, 'Eye of Orgrimmar'),   -- Horde uniquement
(10, 0, 2, 'Maiden''s Circle'),
(10, 0, 3, 'Underworld Band'),
(10, 0, 3, 'Band of Rumination'),
(10, 0, 3, 'Band of the Unicorn'),
(10, 0, 3, 'Cyclopean Band'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(12, 0, 1, 'Briarwood Reed'),
(12, 0, 1, 'Draconic Infused Emblem'),
(12, 0, 2, 'Rune of the Dawn'),
(12, 0, 2, 'Eye of the Beast'),
(12, 0, 3, 'Royal Seal of Eldre''Thalas'),
(12, 0, 3, 'Burst of Knowledge'),
-- Dos (14)
(14, 0, 1, 'Archivist Cape'),
(14, 0, 2, 'Shroud of Arcane Mastery'),
(14, 0, 2, 'Amplifying Cloak'),
(14, 0, 3, 'Heliotrope Cloak'),
(14, 0, 3, 'Spritecaster Cape'),
(14, 0, 3, 'Deep Woodlands Cloak'),
(14, 1, 3, 'Stormpike Sage''s Cloak'),   -- Alliance uniquement
(14, 2, 3, 'Frostwolf Advisor''s Cloak'),   -- Horde uniquement
-- Main droite (15)
(15, 0, 1, 'Blade of the New Moon'),
(15, 0, 2, 'Witchblade'),
(15, 0, 3, 'Blade of Eternal Darkness'),
(15, 0, 3, 'Inventor''s Focal Sword'),
(15, 0, 3, 'Hypnotic Blade'),
(15, 0, 3, 'Arbiter''s Blade'),
(15, 0, 3, 'Blood-etched Blade'),
(15, 0, 3, 'Lord Valthalak''s Staff of Command'),
(15, 0, 3, 'Rod of the Ogre Magi'),
(15, 0, 3, 'Staff of Jordan'),
-- Main gauche (16)
(16, 0, 1, 'Scepter of Interminable Focus'),
(16, 0, 2, 'Tome of Shadow Force'),
(16, 0, 2, 'Therazane''s Touch'),
(16, 0, 3, 'Drakestone'),
(16, 0, 3, 'Tome of the Lost'),
(16, 0, 3, 'Spirit of Aquementas'),
(16, 0, 3, 'Umbral Crystal'),
(16, 0, 3, 'Orb of Dar''Orahil'),
(16, 0, 3, 'Orb of the Forgotten Seer'),
(16, 0, 3, 'Omega Orb'),
-- Distance / baguette (17)
(17, 0, 1, 'Skul''s Ghastly Touch'),
(17, 0, 2, 'Bonecreeper Stylus'),
(17, 0, 2, 'Ritssyn''s Wand of Bad Mojo'),
(17, 0, 3, 'Lethtendris''s Wand');

-- Les trois specialisations partagent la liste, donc elle est insere une fois
-- par spe plutot que recopiee trois fois.
DROP TEMPORARY TABLE IF EXISTS `bis_specs_wl`;
CREATE TEMPORARY TABLE `bis_specs_wl` (`spec` TINYINT UNSIGNED NOT NULL) ENGINE=MEMORY;
INSERT INTO `bis_specs_wl` (`spec`) VALUES (0), (1), (2);

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT 9, sp.`spec`, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed_wl` s
CROSS JOIN `bis_specs_wl` sp
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms non resolus.
-- Toute ligne renvoyee est un nom absent d'item_template : l'objet n'a pas ete
-- insere. Corrige le nom et relance le fichier.
-- ---------------------------------------------------------------------
SELECT s.`slot`, s.`rank`, s.`item_name` AS nom_non_resolu
FROM `bis_seed_wl` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- Un nom peut exister tout en etant range ailleurs que l'emplacement declare.
-- Le module cherche par emplacement : en cas de desaccord, la ligne ne servira
-- jamais. Toute ligne renvoyee est a corriger.
-- ---------------------------------------------------------------------
SELECT s.`slot` AS emplacement_declare, it.`InventoryType` AS emplacement_reel,
       s.`item_name`
FROM `bis_seed_wl` s
JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE NOT (
       (s.`slot` =  0 AND it.`InventoryType` = 1)
    OR (s.`slot` =  1 AND it.`InventoryType` = 2)
    OR (s.`slot` =  2 AND it.`InventoryType` = 3)
    OR (s.`slot` =  4 AND it.`InventoryType` IN (5, 20))
    OR (s.`slot` =  5 AND it.`InventoryType` = 6)
    OR (s.`slot` =  6 AND it.`InventoryType` = 7)
    OR (s.`slot` =  7 AND it.`InventoryType` = 8)
    OR (s.`slot` =  8 AND it.`InventoryType` = 9)
    OR (s.`slot` =  9 AND it.`InventoryType` = 10)
    OR (s.`slot` IN (10, 11) AND it.`InventoryType` = 11)
    OR (s.`slot` IN (12, 13) AND it.`InventoryType` = 12)
    OR (s.`slot` = 14 AND it.`InventoryType` = 16)
    OR (s.`slot` = 15 AND it.`InventoryType` IN (13, 17, 21))
    OR (s.`slot` = 16 AND it.`InventoryType` IN (13, 14, 22, 23))
    OR (s.`slot` = 17 AND it.`InventoryType` IN (15, 25, 26, 28))
);

DROP TEMPORARY TABLE IF EXISTS `bis_seed_wl`;
DROP TEMPORARY TABLE IF EXISTS `bis_specs_wl`;
