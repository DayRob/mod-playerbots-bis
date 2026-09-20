-- mod-playerbots-bis : palier 20 (Vanilla Phase 1 - Molten Core / Onyxia).
--
-- Meme principe que le fichier 03 : les objets sont resolus PAR NOM contre
-- item_template a l'import, jamais codes en dur. Un nom errone n'insere rien
-- plutot que de faire equiper n'importe quoi, et les deux requetes de
-- verification en fin de fichier signalent les noms non resolus et les
-- emplacements incoherents.
--
-- Contenu actuel : Guerrier Armes (1/0) et Guerrier Fureur (1/1).
--
-- Source : guide Wowhead "Warrior DPS Phase 2 Best-in-Slot", qui couvre le
-- butin de Molten Core et d'Onyxia.
--
-- --- Pourquoi ce fichier efface avant d'inserer ---
-- Le palier 20 contient deja des lignes issues du fichier 02, converties depuis
-- la table playerbots_bis_gear d'origine. Leurs rangs ne viennent d'aucun guide.
-- INSERT IGNORE n'ecrasant jamais une ligne existante, et le fichier 02 passant
-- en premier, ses rangs l'emporteraient. On supprime donc d'abord les lignes du
-- guerrier a ce palier. L'operation est idempotente : le systeme de mises a jour
-- d'AzerothCore rejoue ce fichier a chaque changement d'empreinte.
--
-- --- Guerrier Armes ---
-- Wowhead ne publie pas plus de guide Armes a MC qu'en pre-raid : en Vanilla la
-- spe DPS de raid du guerrier est Fureur. Armes reprend donc l'armure et la
-- bijouterie de Fureur - les deux spes veulent les memes statistiques - et
-- recoit un bloc de deux-mains a la place des deux une-main. Bonereaver's Edge,
-- la deux-mains de Ragnaros, y prend le rang 1 ; les autres sont les deux-mains
-- pre-raid, qui restent les meilleures disponibles jusqu'a BWL.
--
-- --- Armes a une main ---
-- Le guide separe les armes de Fureur en deux tableaux, Humain et Orc, selon les
-- specialisations raciales d'arme. Le module ne modelise pas la race : les deux
-- tableaux sont fusionnes, comme pour le guerrier Protection en pre-raid.
--
-- Rangs : Best -> 1, Great -> 2, Good -> 3. Les recompenses de rang PvP et de
-- reputation de champ de bataille sont systematiquement en rang 3, un bot ne les
-- atteignant pas.

DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 20 AND `class` = 1 AND `spec` IN (0, 1);

DROP TEMPORARY TABLE IF EXISTS `bis_seed20`;
CREATE TEMPORARY TABLE `bis_seed20` (
    `class`     TINYINT UNSIGNED NOT NULL,
    `spec`      TINYINT UNSIGNED NOT NULL,
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

INSERT INTO `bis_seed20` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(1, 1,  0, 0, 1, 'Lionheart Helm'),
(1, 1,  0, 0, 2, 'Crown of Destruction'),
(1, 1,  0, 0, 3, 'Eye of Rend'),
(1, 1,  0, 0, 3, 'Mask of the Unforgiven'),
(1, 1,  0, 1, 3, 'Lieutenant Commander''s Plate Helm'),
(1, 1,  0, 2, 3, 'Champion''s Plate Helm'),
(1, 1,  1, 0, 1, 'Onyxia Tooth Pendant'),
(1, 1,  1, 0, 2, 'Mark of Fordring'),
(1, 1,  1, 0, 3, 'Imperial Jewel'),
(1, 1,  1, 0, 3, 'Will of the Martyr'),
(1, 1,  2, 0, 1, 'Truestrike Shoulders'),
(1, 1,  2, 0, 2, 'Black Dragonscale Shoulders'),
(1, 1,  2, 0, 3, 'Spaulders of Valor'),
(1, 1,  2, 0, 3, 'Pauldrons of Might'),
(1, 1,  2, 0, 3, 'Wyrmhide Spaulders'),
(1, 1,  2, 1, 3, 'Lieutenant Commander''s Plate Shoulders'),
(1, 1,  2, 2, 3, 'Champion''s Plate Shoulders'),
(1, 1,  4, 0, 1, 'Savage Gladiator Chain'),
(1, 1,  4, 0, 1, 'Cadaverous Armor'),
(1, 1,  4, 0, 2, 'Tombstone Breastplate'),
(1, 1,  4, 0, 3, 'Deathdealer Breastplate'),
(1, 1,  4, 0, 3, 'Ogre Forged Hauberk'),
(1, 1,  4, 0, 3, 'Black Dragonscale Breastplate'),
(1, 1,  4, 1, 3, 'Knight-Captain''s Plate Hauberk'),
(1, 1,  4, 2, 3, 'Legionnaire''s Plate Hauberk'),
(1, 1,  5, 0, 1, 'Onslaught Girdle'),
(1, 1,  5, 0, 2, 'Omokk''s Girth Restrainer'),
(1, 1,  5, 0, 2, 'Brigam Girdle'),
(1, 1,  5, 0, 3, 'Mugger''s Belt'),
(1, 1,  5, 1, 3, 'Stormpike Plate Girdle'),
(1, 1,  5, 2, 3, 'Frostwolf Plate Belt'),
(1, 1,  6, 0, 1, 'Cloudkeeper Legplates'),
(1, 1,  6, 0, 2, 'Devilsaur Leggings'),
(1, 1,  6, 0, 3, 'Eldritch Reinforced Legplates'),
(1, 1,  6, 1, 3, 'Knight-Captain''s Plate Leggings'),
(1, 1,  6, 2, 3, 'Legionnaire''s Plate Leggings'),
(1, 1,  7, 0, 1, 'Bloodmail Boots'),
(1, 1,  7, 0, 2, 'Battlechaser''s Greaves'),
(1, 1,  7, 0, 2, 'Windreaver Greaves'),
(1, 1,  7, 0, 2, 'Pads of the Dread Wolf'),
(1, 1,  7, 0, 2, 'Sapphiron''s Scale Boots'),
(1, 1,  7, 0, 2, 'Savage Gladiator Greaves'),
(1, 1,  7, 0, 3, 'Black Dragonscale Boots'),
(1, 1,  8, 0, 1, 'Wristguards of Stability'),
(1, 1,  8, 0, 2, 'Battleborn Armbraces'),
(1, 1,  8, 0, 2, 'Wristguards of True Flight'),
(1, 1,  8, 0, 3, 'Gordok Bracers of Power'),
(1, 1,  8, 0, 3, 'Vambraces of the Sadist'),
(1, 1,  8, 1, 3, 'Berserker Bracers'),
(1, 1,  9, 0, 1, 'Flameguard Gauntlets'),
(1, 1,  9, 0, 1, 'Edgemaster''s Handguards'),
(1, 1,  9, 0, 2, 'Gauntlets of Might'),
(1, 1,  9, 0, 3, 'Devilsaur Gauntlets'),
(1, 1,  9, 0, 3, 'Voone''s Vice Grips'),
(1, 1, 17, 0, 1, 'Striker''s Mark'),
(1, 1, 17, 0, 2, 'Blastershot Launcher'),
(1, 1, 17, 0, 3, 'Bloodseeker'),
(1, 1, 17, 0, 3, 'Blackcrow'),
(1, 1, 17, 0, 3, 'Satyr''s Bow'),
(1, 1, 17, 0, 3, 'Riphook'),
(1, 1, 10, 0, 1, 'Quick Strike Ring'),
(1, 1, 11, 0, 1, 'Quick Strike Ring'),
(1, 1, 10, 0, 2, 'Band of Accuria'),
(1, 1, 11, 0, 2, 'Band of Accuria'),
(1, 1, 10, 0, 3, 'Blackstone Ring'),
(1, 1, 11, 0, 3, 'Blackstone Ring'),
(1, 1, 10, 0, 3, 'Painweaver Band'),
(1, 1, 11, 0, 3, 'Painweaver Band'),
(1, 1, 10, 0, 3, 'Tarnished Elven Ring'),
(1, 1, 11, 0, 3, 'Tarnished Elven Ring'),
(1, 1, 10, 0, 3, 'Don Julio''s Band'),
(1, 1, 11, 0, 3, 'Don Julio''s Band'),
(1, 1, 10, 1, 3, 'Magni''s Will'),
(1, 1, 11, 1, 3, 'Magni''s Will'),
(1, 1, 12, 0, 1, 'Hand of Justice'),
(1, 1, 13, 0, 1, 'Hand of Justice'),
(1, 1, 12, 0, 2, 'Blackhand''s Breadth'),
(1, 1, 13, 0, 2, 'Blackhand''s Breadth'),
(1, 1, 12, 0, 3, 'Counterattack Lodestone'),
(1, 1, 13, 0, 3, 'Counterattack Lodestone'),
(1, 1, 12, 2, 2, 'Rune of the Guard Captain'),
(1, 1, 13, 2, 2, 'Rune of the Guard Captain'),
(1, 1, 15, 0, 1, 'Empyrean Demolisher'),
(1, 1, 15, 0, 1, 'Deathbringer'),
(1, 1, 15, 0, 2, 'Vis''kag the Bloodletter'),
(1, 1, 15, 0, 2, 'Brutality Blade'),
(1, 1, 15, 0, 2, 'Ironfoe'),
(1, 1, 15, 0, 3, 'Dal''Rend''s Sacred Charge'),
(1, 1, 15, 0, 3, 'Quel''Serrar'),
(1, 1, 15, 0, 3, 'Krol Blade'),
(1, 1, 15, 0, 3, 'Thrash Blade'),
(1, 1, 15, 0, 3, 'Axe of the Deep Woods'),
(1, 1, 15, 0, 3, 'Rivenspike'),
(1, 1, 15, 1, 3, 'Stormstrike Hammer'),
(1, 1, 15, 2, 3, 'Frostbite'),
(1, 1, 16, 0, 1, 'Brutality Blade'),
(1, 1, 16, 0, 1, 'Deathbringer'),
(1, 1, 16, 0, 2, 'Vis''kag the Bloodletter'),
(1, 1, 16, 0, 2, 'Dal''Rend''s Tribal Guardian'),
(1, 1, 16, 0, 2, 'Distracting Dagger'),
(1, 1, 16, 0, 3, 'Mirah''s Song'),
(1, 1, 16, 0, 3, 'Bone Slicing Hatchet'),
(1, 1, 16, 0, 3, 'Flurry Axe'),
(1, 1, 16, 0, 3, 'Serathil'),
(1, 1, 16, 2, 3, 'Frostbite'),
(1, 0,  0, 0, 1, 'Lionheart Helm'),
(1, 0,  0, 0, 2, 'Crown of Destruction'),
(1, 0,  0, 0, 3, 'Eye of Rend'),
(1, 0,  0, 0, 3, 'Mask of the Unforgiven'),
(1, 0,  0, 1, 3, 'Lieutenant Commander''s Plate Helm'),
(1, 0,  0, 2, 3, 'Champion''s Plate Helm'),
(1, 0,  1, 0, 1, 'Onyxia Tooth Pendant'),
(1, 0,  1, 0, 2, 'Mark of Fordring'),
(1, 0,  1, 0, 3, 'Imperial Jewel'),
(1, 0,  1, 0, 3, 'Will of the Martyr'),
(1, 0,  2, 0, 1, 'Truestrike Shoulders'),
(1, 0,  2, 0, 2, 'Black Dragonscale Shoulders'),
(1, 0,  2, 0, 3, 'Spaulders of Valor'),
(1, 0,  2, 0, 3, 'Pauldrons of Might'),
(1, 0,  2, 0, 3, 'Wyrmhide Spaulders'),
(1, 0,  2, 1, 3, 'Lieutenant Commander''s Plate Shoulders'),
(1, 0,  2, 2, 3, 'Champion''s Plate Shoulders'),
(1, 0,  4, 0, 1, 'Savage Gladiator Chain'),
(1, 0,  4, 0, 1, 'Cadaverous Armor'),
(1, 0,  4, 0, 2, 'Tombstone Breastplate'),
(1, 0,  4, 0, 3, 'Deathdealer Breastplate'),
(1, 0,  4, 0, 3, 'Ogre Forged Hauberk'),
(1, 0,  4, 0, 3, 'Black Dragonscale Breastplate'),
(1, 0,  4, 1, 3, 'Knight-Captain''s Plate Hauberk'),
(1, 0,  4, 2, 3, 'Legionnaire''s Plate Hauberk'),
(1, 0,  5, 0, 1, 'Onslaught Girdle'),
(1, 0,  5, 0, 2, 'Omokk''s Girth Restrainer'),
(1, 0,  5, 0, 2, 'Brigam Girdle'),
(1, 0,  5, 0, 3, 'Mugger''s Belt'),
(1, 0,  5, 1, 3, 'Stormpike Plate Girdle'),
(1, 0,  5, 2, 3, 'Frostwolf Plate Belt'),
(1, 0,  6, 0, 1, 'Cloudkeeper Legplates'),
(1, 0,  6, 0, 2, 'Devilsaur Leggings'),
(1, 0,  6, 0, 3, 'Eldritch Reinforced Legplates'),
(1, 0,  6, 1, 3, 'Knight-Captain''s Plate Leggings'),
(1, 0,  6, 2, 3, 'Legionnaire''s Plate Leggings'),
(1, 0,  7, 0, 1, 'Bloodmail Boots'),
(1, 0,  7, 0, 2, 'Battlechaser''s Greaves'),
(1, 0,  7, 0, 2, 'Windreaver Greaves'),
(1, 0,  7, 0, 2, 'Pads of the Dread Wolf'),
(1, 0,  7, 0, 2, 'Sapphiron''s Scale Boots'),
(1, 0,  7, 0, 2, 'Savage Gladiator Greaves'),
(1, 0,  7, 0, 3, 'Black Dragonscale Boots'),
(1, 0,  8, 0, 1, 'Wristguards of Stability'),
(1, 0,  8, 0, 2, 'Battleborn Armbraces'),
(1, 0,  8, 0, 2, 'Wristguards of True Flight'),
(1, 0,  8, 0, 3, 'Gordok Bracers of Power'),
(1, 0,  8, 0, 3, 'Vambraces of the Sadist'),
(1, 0,  8, 1, 3, 'Berserker Bracers'),
(1, 0,  9, 0, 1, 'Flameguard Gauntlets'),
(1, 0,  9, 0, 1, 'Edgemaster''s Handguards'),
(1, 0,  9, 0, 2, 'Gauntlets of Might'),
(1, 0,  9, 0, 3, 'Devilsaur Gauntlets'),
(1, 0,  9, 0, 3, 'Voone''s Vice Grips'),
(1, 0, 17, 0, 1, 'Striker''s Mark'),
(1, 0, 17, 0, 2, 'Blastershot Launcher'),
(1, 0, 17, 0, 3, 'Bloodseeker'),
(1, 0, 17, 0, 3, 'Blackcrow'),
(1, 0, 17, 0, 3, 'Satyr''s Bow'),
(1, 0, 17, 0, 3, 'Riphook'),
(1, 0, 10, 0, 1, 'Quick Strike Ring'),
(1, 0, 11, 0, 1, 'Quick Strike Ring'),
(1, 0, 10, 0, 2, 'Band of Accuria'),
(1, 0, 11, 0, 2, 'Band of Accuria'),
(1, 0, 10, 0, 3, 'Blackstone Ring'),
(1, 0, 11, 0, 3, 'Blackstone Ring'),
(1, 0, 10, 0, 3, 'Painweaver Band'),
(1, 0, 11, 0, 3, 'Painweaver Band'),
(1, 0, 10, 0, 3, 'Tarnished Elven Ring'),
(1, 0, 11, 0, 3, 'Tarnished Elven Ring'),
(1, 0, 10, 0, 3, 'Don Julio''s Band'),
(1, 0, 11, 0, 3, 'Don Julio''s Band'),
(1, 0, 10, 1, 3, 'Magni''s Will'),
(1, 0, 11, 1, 3, 'Magni''s Will'),
(1, 0, 12, 0, 1, 'Hand of Justice'),
(1, 0, 13, 0, 1, 'Hand of Justice'),
(1, 0, 12, 0, 2, 'Blackhand''s Breadth'),
(1, 0, 13, 0, 2, 'Blackhand''s Breadth'),
(1, 0, 12, 0, 3, 'Counterattack Lodestone'),
(1, 0, 13, 0, 3, 'Counterattack Lodestone'),
(1, 0, 12, 2, 2, 'Rune of the Guard Captain'),
(1, 0, 13, 2, 2, 'Rune of the Guard Captain'),
(1, 0, 15, 0, 1, 'Bonereavers Edge'),
(1, 0, 15, 0, 1, 'Arcanite Reaper'),
(1, 0, 15, 0, 2, 'The Unstoppable Force'),
(1, 0, 15, 0, 2, 'Corpsemaker'),
(1, 0, 15, 0, 3, 'Skullforge Reaver'),
(1, 0, 15, 0, 3, 'Ice Barbed Spear'),
(1, 0, 15, 0, 3, 'Sceptre of Smiting');

INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT s.`class`, s.`spec`, s.`slot`, s.`faction`, 20, r.entry, s.`rank`,
       CONCAT('MC / Onyxia - ', s.`item_name`)
FROM `bis_seed20` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION 1 - noms absents d'item_template.
-- ---------------------------------------------------------------------
SELECT s.`class`, s.`spec`, s.`slot`, s.`item_name` AS nom_non_resolu
FROM `bis_seed20` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement declare.
-- ---------------------------------------------------------------------
SELECT s.`class`, s.`spec`, s.`slot` AS emplacement_declare,
       it.`InventoryType` AS emplacement_reel, s.`item_name`
FROM `bis_seed20` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed20`;
