-- mod-playerbots-bis : palier 10 (Vanilla Pre-Raid).
--
-- Les identifiants d'objets ne sont PAS ecrits en dur : chaque ligne est resolue
-- par nom contre item_template au moment de l'import. Un nom errone n'insere
-- simplement rien, au lieu de faire equiper un mauvais objet a un bot. La requete
-- de verification en fin de fichier liste les noms non resolus.
--
-- Les noms sont les noms ANGLAIS d'item_template. Si ta base world est localisee,
-- item_template garde quand meme les noms anglais (les traductions vivent dans
-- item_template_locale), donc rien a changer.
--
-- PIEGE : quelques objets ont ete RENOMMES entre Vanilla et WotLK, alors que les
-- guides Wowhead Classic gardent l'ancien nom. La base d'un serveur 3.3.5 porte
-- le nom WotLK, et c'est celui-la qu'il faut ecrire ici. Deux cas rencontres :
--
--   20671  "Abyssal Plate Legplates"   -> "Abyssal Plate Legguards"
--   22403  "Nacreous Shell Necklace"   -> "Diana's Pearl Necklace"
--
-- Le second montre que le renommage n'est pas toujours un simple mot change :
-- l'objet porte un nom entierement different. La seule facon fiable de trancher
-- est de chercher l'identifiant dans item_template, pas le nom.
-- La premiere requete de verification en fin de fichier attrape ces cas.
--
-- rank : 1 = premier choix, 2 = alternative, 3 = depannage. Le bot prend la
-- meilleure ligne qu'il possede. Un palier superieur bat toujours ce palier-ci.
--
-- Source : guides Best-in-Slot Pre-Raid de Wowhead Classic.
-- Contenu actuel : Guerrier Armes (1/0), Guerrier Fureur (1/1), Guerrier Protection (1/2),
-- Paladin Sacre (2/0), Paladin Protection (2/1), Paladin Vindicte (2/2),
-- Chasseur (3/0,1,2), Voleur (4/0,1,2), Pretre soin (5/0,1),
-- Chaman Elementaire (7/0), Chaman Amelioration (7/1), Chaman Restauration (7/2), Druide Ours (11/10), Druide Restauration (11/2), Druide Farouche (11/1), Druide Equilibre (11/0)
-- contre item_template sur un serveur AzerothCore reel.

-- Rejeu du fichier : les INSERT plus bas sont en INSERT IGNORE et n'ecrasent
-- donc jamais une ligne existante. Pour que ce fichier redevienne la source de
-- verite quand son contenu change, il efface d'abord SES PROPRES combinaisons.
-- La portee est volontairement limitee aux classes/spes couvertes ici : le
-- palier 10 est aussi alimente par 04_vanilla_preraid_wowsims.sql, dont les
-- combinaisons ne doivent pas etre emportees au passage.
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 1  AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 2  AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 3  AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 4  AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 5  AND `spec` IN (0, 1);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 7  AND `spec` IN (0, 1, 2);
DELETE FROM `playerbots_bis_item` WHERE `tier_id` = 10 AND `class` = 11 AND `spec` IN (0, 1, 2, 10);

DROP TEMPORARY TABLE IF EXISTS `bis_seed`;
CREATE TEMPORARY TABLE `bis_seed` (
    `class`     TINYINT UNSIGNED NOT NULL,
    `spec`      TINYINT UNSIGNED NOT NULL,
    `slot`      TINYINT UNSIGNED NOT NULL,
    `faction`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `item_name` VARCHAR(100) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4;

-- Note collation : item_template.name est en utf8mb4_unicode_ci sur AzerothCore,
-- alors qu'une table creee sans COLLATE explicite herite du defaut du serveur
-- (utf8mb4_0900_ai_ci sur MySQL 8 et 9). Comparer les deux directement leve
-- ERROR 1267 "Illegal mix of collations". Les deux jointures ci-dessous forcent
-- donc explicitement la meme collation des deux cotes, ce qui rend le fichier
-- portable quelle que soit la configuration du serveur.

-- =====================================================================
-- Guerrier Fureur (classe 1, spe 1)
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
-- Tete (0)
(1, 1,  0, 0, 1, 'Lionheart Helm'),
(1, 1,  0, 0, 2, 'Helm of the Executioner'),
(1, 1,  0, 0, 3, 'Eye of Rend'),
(1, 1,  0, 0, 3, 'Mask of the Unforgiven'),
-- Cou (1)
(1, 1,  1, 0, 1, 'Mark of Fordring'),
(1, 1,  1, 0, 2, 'Pendant of Celerity'),
(1, 1,  1, 0, 3, 'Imperial Jewel'),
-- Epaules (2)
(1, 1,  2, 0, 1, 'Truestrike Shoulders'),
(1, 1,  2, 0, 1, 'Black Dragonscale Shoulders'),
(1, 1,  2, 0, 3, 'Wyrmhide Spaulders'),
-- Torse (4)
(1, 1,  4, 0, 1, 'Savage Gladiator Chain'),
(1, 1,  4, 0, 2, 'Cadaverous Armor'),
(1, 1,  4, 0, 2, 'Tombstone Breastplate'),
(1, 1,  4, 0, 2, 'Deathdealer Breastplate'),
-- Ceinture (5)
(1, 1,  5, 0, 1, 'Omokk''s Girth Restrainer'),
(1, 1,  5, 0, 1, 'Brigam Girdle'),
(1, 1,  5, 0, 2, 'Cloudrunner Girdle'),
-- Jambes (6)
(1, 1,  6, 0, 1, 'Devilsaur Leggings'),
(1, 1,  6, 0, 1, 'Eldritch Reinforced Legplates'),
(1, 1,  6, 0, 1, 'Black Dragonscale Leggings'),
(1, 1,  6, 0, 2, 'Cloudkeeper Legplates'),
-- Pieds (7)
(1, 1,  7, 0, 1, 'Boots of Heroism'),
(1, 1,  7, 0, 2, 'Black Dragonscale Boots'),
(1, 1,  7, 0, 3, 'Battlechaser''s Greaves'),
(1, 1,  7, 0, 3, 'Shadefiend Boots'),
-- Poignets (8)
(1, 1,  8, 0, 1, 'Vambraces of the Sadist'),
(1, 1,  8, 0, 1, 'Battleborn Armbraces'),
(1, 1,  8, 0, 2, 'Wristguards of Renown'),
-- Mains (9)
(1, 1,  9, 0, 1, 'Edgemaster''s Handguards'),
(1, 1,  9, 0, 1, 'Devilsaur Gauntlets'),
(1, 1,  9, 0, 1, 'Gauntlets of Heroism'),
(1, 1,  9, 0, 3, 'Gargoyle Slashers'),
-- Anneaux (10) - le module compare automatiquement avec l'emplacement 11
(1, 1, 10, 0, 1, 'Painweaver Band'),
(1, 1, 10, 0, 1, 'Blackstone Ring'),
(1, 1, 10, 0, 2, 'Tarnished Elven Ring'),
-- Bijoux (12) - le module compare automatiquement avec l'emplacement 13
(1, 1, 12, 0, 1, 'Diamond Flask'),
(1, 1, 12, 0, 1, 'Blackhand''s Breadth'),
(1, 1, 12, 0, 1, 'Hand of Justice'),
(1, 1, 12, 2, 2, 'Rune of the Guard Captain'),   -- Horde uniquement
-- Dos (14)
(1, 1, 14, 0, 1, 'Cape of the Black Baron'),
(1, 1, 14, 0, 2, 'Blackveil Cape'),
(1, 1, 14, 0, 3, 'Shroud of Domination'),
-- Main droite (15) - les lignes rank 2 sont les choix orcs (specialisation hache)
(1, 1, 15, 0, 1, 'Ironfoe'),
(1, 1, 15, 0, 1, 'Dal''Rend''s Sacred Charge'),
(1, 1, 15, 0, 1, 'Krol Blade'),
(1, 1, 15, 0, 2, 'Rivenspike'),
(1, 1, 15, 0, 2, 'Axe of the Deep Woods'),
(1, 1, 15, 0, 3, 'Assassination Blade'),
(1, 1, 15, 0, 3, 'Mass of McGowan'),
-- Main gauche (16)
(1, 1, 16, 0, 1, 'Dal''Rend''s Tribal Guardian'),
(1, 1, 16, 0, 2, 'Bone Slicing Hatchet'),
(1, 1, 16, 0, 2, 'Mirah''s Song'),
(1, 1, 16, 0, 3, 'Serathil'),
(1, 1, 16, 0, 3, 'Bonescraper'),
-- Distance (17)
(1, 1, 17, 0, 1, 'Satyr''s Bow'),
(1, 1, 17, 0, 2, 'Blackcrow'),
(1, 1, 17, 0, 3, 'Riphook');

-- =====================================================================
-- Chasseur (classe 3) - liste unique appliquee aux trois onglets :
-- en Vanilla pre-raid, Maitrise / Precision / Survie portent le meme stuff.
--
-- Les armes Dal'Rend sont volontairement ABSENTES de cette liste, bien que le
-- guide les propose en une-main. Elles sont beaucoup trop rares pour que le
-- chasseur les dispute au guerrier, dont elles sont le BiS de main droite ET de
-- main gauche. Les retirer d'ici ne fait pas que l'empecher de rouler dessus :
-- l'objet devient "le BiS d'une autre spe", donc le chasseur le laisse
-- activement au guerrier. L'arme a deux mains reste de toute facon son
-- meilleur choix d'apres le set d'exemple du guide.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(3, 0,  0, 0, 1, 'Backwood Helm'),
(3, 1,  0, 0, 1, 'Backwood Helm'),
(3, 2,  0, 0, 1, 'Backwood Helm'),
(3, 0,  0, 0, 2, 'Beastmaster''s Cap'),
(3, 1,  0, 0, 2, 'Beastmaster''s Cap'),
(3, 2,  0, 0, 2, 'Beastmaster''s Cap'),
(3, 0,  0, 0, 2, 'Crown of Tyranny'),
(3, 1,  0, 0, 2, 'Crown of Tyranny'),
(3, 2,  0, 0, 2, 'Crown of Tyranny'),
(3, 0,  1, 0, 1, 'Pendant of Celerity'),
(3, 1,  1, 0, 1, 'Pendant of Celerity'),
(3, 2,  1, 0, 1, 'Pendant of Celerity'),
(3, 0,  1, 0, 2, 'Mark of Fordring'),
(3, 1,  1, 0, 2, 'Mark of Fordring'),
(3, 2,  1, 0, 2, 'Mark of Fordring'),
(3, 0,  1, 0, 2, 'Imperial Jewel'),
(3, 1,  1, 0, 2, 'Imperial Jewel'),
(3, 2,  1, 0, 2, 'Imperial Jewel'),
(3, 0,  1, 0, 2, 'Will of the Martyr'),
(3, 1,  1, 0, 2, 'Will of the Martyr'),
(3, 2,  1, 0, 2, 'Will of the Martyr'),
(3, 0,  2, 0, 1, 'Truestrike Shoulders'),
(3, 1,  2, 0, 1, 'Truestrike Shoulders'),
(3, 2,  2, 0, 1, 'Truestrike Shoulders'),
(3, 0,  2, 0, 2, 'Wyrmhide Spaulders'),
(3, 1,  2, 0, 2, 'Wyrmhide Spaulders'),
(3, 2,  2, 0, 2, 'Wyrmhide Spaulders'),
(3, 0,  2, 0, 2, 'Wyrmtongue Shoulders'),
(3, 1,  2, 0, 2, 'Wyrmtongue Shoulders'),
(3, 2,  2, 0, 2, 'Wyrmtongue Shoulders'),
(3, 0,  4, 0, 1, 'Savage Gladiator Chain'),
(3, 1,  4, 0, 1, 'Savage Gladiator Chain'),
(3, 2,  4, 0, 1, 'Savage Gladiator Chain'),
(3, 0,  4, 0, 2, 'Cadaverous Armor'),
(3, 1,  4, 0, 2, 'Cadaverous Armor'),
(3, 2,  4, 0, 2, 'Cadaverous Armor'),
(3, 0,  4, 0, 2, 'Nightbrace Tunic'),
(3, 1,  4, 0, 2, 'Nightbrace Tunic'),
(3, 2,  4, 0, 2, 'Nightbrace Tunic'),
(3, 0,  5, 0, 1, 'Marksman''s Girdle'),
(3, 1,  5, 0, 1, 'Marksman''s Girdle'),
(3, 2,  5, 0, 1, 'Marksman''s Girdle'),
(3, 0,  5, 0, 2, 'Warpwood Binding'),
(3, 1,  5, 0, 2, 'Warpwood Binding'),
(3, 2,  5, 0, 2, 'Warpwood Binding'),
(3, 0,  5, 0, 2, 'Chiselbrand Girdle'),
(3, 1,  5, 0, 2, 'Chiselbrand Girdle'),
(3, 2,  5, 0, 2, 'Chiselbrand Girdle'),
(3, 0,  6, 0, 1, 'Devilsaur Leggings'),
(3, 1,  6, 0, 1, 'Devilsaur Leggings'),
(3, 2,  6, 0, 1, 'Devilsaur Leggings'),
(3, 0,  6, 0, 2, 'Blademaster Leggings'),
(3, 1,  6, 0, 2, 'Blademaster Leggings'),
(3, 2,  6, 0, 2, 'Blademaster Leggings'),
(3, 0,  6, 0, 2, 'Beastmaster''s Pants'),
(3, 1,  6, 0, 2, 'Beastmaster''s Pants'),
(3, 2,  6, 0, 2, 'Beastmaster''s Pants'),
(3, 0,  7, 0, 1, 'Beastmaster''s Boots'),
(3, 1,  7, 0, 1, 'Beastmaster''s Boots'),
(3, 2,  7, 0, 1, 'Beastmaster''s Boots'),
(3, 0,  7, 0, 2, 'Mongoose Boots'),
(3, 1,  7, 0, 2, 'Mongoose Boots'),
(3, 2,  7, 0, 2, 'Mongoose Boots'),
(3, 0,  7, 0, 2, 'Windreaver Greaves'),
(3, 1,  7, 0, 2, 'Windreaver Greaves'),
(3, 2,  7, 0, 2, 'Windreaver Greaves'),
(3, 0,  8, 0, 1, 'Bracers of the Eclipse'),
(3, 1,  8, 0, 1, 'Bracers of the Eclipse'),
(3, 2,  8, 0, 1, 'Bracers of the Eclipse'),
(3, 0,  8, 0, 2, 'Slashclaw Bracers'),
(3, 1,  8, 0, 2, 'Slashclaw Bracers'),
(3, 2,  8, 0, 2, 'Slashclaw Bracers'),
(3, 0,  8, 0, 2, 'Beastmaster''s Bindings'),
(3, 1,  8, 0, 2, 'Beastmaster''s Bindings'),
(3, 2,  8, 0, 2, 'Beastmaster''s Bindings'),
(3, 0,  9, 0, 1, 'Devilsaur Gauntlets'),
(3, 1,  9, 0, 1, 'Devilsaur Gauntlets'),
(3, 2,  9, 0, 1, 'Devilsaur Gauntlets'),
(3, 0,  9, 0, 2, 'Beastmaster''s Gloves'),
(3, 1,  9, 0, 2, 'Beastmaster''s Gloves'),
(3, 2,  9, 0, 2, 'Beastmaster''s Gloves'),
(3, 0,  9, 0, 2, 'Skul''s Fingerbone Claws'),
(3, 1,  9, 0, 2, 'Skul''s Fingerbone Claws'),
(3, 2,  9, 0, 2, 'Skul''s Fingerbone Claws'),
(3, 0,  9, 0, 2, 'Trueaim Gauntlets'),
(3, 1,  9, 0, 2, 'Trueaim Gauntlets'),
(3, 2,  9, 0, 2, 'Trueaim Gauntlets'),
(3, 0, 10, 0, 1, 'Tarnished Elven Ring'),
(3, 1, 10, 0, 1, 'Tarnished Elven Ring'),
(3, 2, 10, 0, 1, 'Tarnished Elven Ring'),
(3, 0, 10, 0, 2, 'Blackstone Ring'),
(3, 1, 10, 0, 2, 'Blackstone Ring'),
(3, 2, 10, 0, 2, 'Blackstone Ring'),
(3, 0, 10, 0, 2, 'Painweaver Band'),
(3, 1, 10, 0, 2, 'Painweaver Band'),
(3, 2, 10, 0, 2, 'Painweaver Band'),
(3, 0, 12, 0, 1, 'Blackhand''s Breadth'),
(3, 1, 12, 0, 1, 'Blackhand''s Breadth'),
(3, 2, 12, 0, 1, 'Blackhand''s Breadth'),
(3, 0, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(3, 1, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(3, 2, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(3, 0, 12, 0, 2, 'Devilsaur Eye'),
(3, 1, 12, 0, 2, 'Devilsaur Eye'),
(3, 2, 12, 0, 2, 'Devilsaur Eye'),
(3, 0, 14, 0, 1, 'Cape of the Black Baron'),
(3, 1, 14, 0, 1, 'Cape of the Black Baron'),
(3, 2, 14, 0, 1, 'Cape of the Black Baron'),
(3, 0, 14, 0, 2, 'Dark Phantom Cape'),
(3, 1, 14, 0, 2, 'Dark Phantom Cape'),
(3, 2, 14, 0, 2, 'Dark Phantom Cape'),
(3, 0, 14, 0, 2, 'Blackveil Cape'),
(3, 1, 14, 0, 2, 'Blackveil Cape'),
(3, 2, 14, 0, 2, 'Blackveil Cape'),
(3, 0, 15, 0, 1, 'Huntsman''s Harpoon'),
(3, 1, 15, 0, 1, 'Huntsman''s Harpoon'),
(3, 2, 15, 0, 1, 'Huntsman''s Harpoon'),
(3, 0, 15, 0, 1, 'Warmonger'),
(3, 1, 15, 0, 1, 'Warmonger'),
(3, 2, 15, 0, 1, 'Warmonger'),
(3, 0, 15, 0, 2, 'Barbarous Blade'),
(3, 1, 15, 0, 2, 'Barbarous Blade'),
(3, 2, 15, 0, 2, 'Barbarous Blade'),
(3, 0, 15, 0, 2, 'Peacemaker'),
(3, 1, 15, 0, 2, 'Peacemaker'),
(3, 2, 15, 0, 2, 'Peacemaker'),
(3, 0, 16, 0, 1, 'Bone Slicing Hatchet'),
(3, 1, 16, 0, 1, 'Bone Slicing Hatchet'),
(3, 2, 16, 0, 1, 'Bone Slicing Hatchet'),
(3, 0, 17, 0, 1, 'Bloodseeker'),
(3, 1, 17, 0, 1, 'Bloodseeker'),
(3, 2, 17, 0, 1, 'Bloodseeker'),
(3, 0, 17, 0, 2, 'Blackcrow'),
(3, 1, 17, 0, 2, 'Blackcrow'),
(3, 2, 17, 0, 2, 'Blackcrow'),
(3, 0, 17, 0, 2, 'Heartseeking Crossbow'),
(3, 1, 17, 0, 2, 'Heartseeking Crossbow'),
(3, 2, 17, 0, 2, 'Heartseeking Crossbow'),
(3, 0, 17, 0, 2, 'Dwarven Hand Cannon'),
(3, 1, 17, 0, 2, 'Dwarven Hand Cannon'),
(3, 2, 17, 0, 2, 'Dwarven Hand Cannon'),
(3, 0, 17, 0, 2, 'Carapace Spine Crossbow'),
(3, 1, 17, 0, 2, 'Carapace Spine Crossbow'),
(3, 2, 17, 0, 2, 'Carapace Spine Crossbow');

-- =====================================================================
-- Pretre soin (classe 5) - onglets Discipline (0) et Sacre (1).
-- Le guide ne distingue pas les deux : en Vanilla, un pretre soigneur porte le
-- meme equipement quel que soit son arbre.
--
-- Rangs de la page : Best -> 1, Great -> 2, Optional -> 3.
--
-- ECARTES volontairement, car ce sont des objets a SUFFIXE ALEATOIRE, sans
-- identifiant fixe : Green Lens of Healing, Eternal Crown of Healing,
-- Archivists Cape of Healing, Masterwork Cape of Healing, Drakestone of Healing,
-- Lunar Wand of Healing. Ils ne resoudraient jamais par nom.
--
-- Redemption (baton) est mis au meme rang que la paire Hammer of Grace + Tome of
-- Divine Right : le guide les dit equivalents.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(5, 0,  0, 0, 1, 'Cassandra''s Grace'),
(5, 1,  0, 0, 1, 'Cassandra''s Grace'),
(5, 0,  0, 0, 2, 'Crimson Felt Hat'),
(5, 1,  0, 0, 2, 'Crimson Felt Hat'),
(5, 0,  0, 0, 3, 'Virtuous Crown'),
(5, 1,  0, 0, 3, 'Virtuous Crown'),
(5, 0,  1, 0, 1, 'Animated Chain Necklace'),
(5, 1,  1, 0, 1, 'Animated Chain Necklace'),
(5, 0,  1, 0, 3, 'Amulet of the Redeemed'),
(5, 1,  1, 0, 3, 'Amulet of the Redeemed'),
(5, 0,  1, 0, 3, 'Tooth of Gnarr'),
(5, 1,  1, 0, 3, 'Tooth of Gnarr'),
(5, 0,  2, 0, 1, 'Mantle of Lost Hope'),
(5, 1,  2, 0, 1, 'Mantle of Lost Hope'),
(5, 0,  2, 0, 3, 'Mantle of the Scarlet Crusade'),
(5, 1,  2, 0, 3, 'Mantle of the Scarlet Crusade'),
(5, 0,  2, 0, 3, 'Burial Shawl'),
(5, 1,  2, 0, 3, 'Burial Shawl'),
(5, 0,  2, 0, 3, 'Virtuous Mantle'),
(5, 1,  2, 0, 3, 'Virtuous Mantle'),
(5, 0,  2, 0, 3, 'Kentic Amice'),
(5, 1,  2, 0, 3, 'Kentic Amice'),
(5, 0,  4, 0, 1, 'Truefaith Vestments'),
(5, 1,  4, 0, 1, 'Truefaith Vestments'),
(5, 0,  4, 0, 3, 'Robes of the Exalted'),
(5, 1,  4, 0, 3, 'Robes of the Exalted'),
(5, 0,  4, 0, 3, 'Virtuous Robe'),
(5, 1,  4, 0, 3, 'Virtuous Robe'),
(5, 0,  5, 0, 1, 'Whipvine Cord'),
(5, 1,  5, 0, 1, 'Whipvine Cord'),
(5, 0,  5, 0, 3, 'Virtuous Belt'),
(5, 1,  5, 0, 3, 'Virtuous Belt'),
(5, 0,  5, 0, 3, 'Thuzadin Sash'),
(5, 1,  5, 0, 3, 'Thuzadin Sash'),
(5, 0,  6, 0, 1, 'Padre''s Trousers'),
(5, 1,  6, 0, 1, 'Padre''s Trousers'),
(5, 0,  6, 0, 2, 'Senior Designer''s Pantaloons'),
(5, 1,  6, 0, 2, 'Senior Designer''s Pantaloons'),
(5, 0,  6, 0, 3, 'Virtuous Skirt'),
(5, 1,  6, 0, 3, 'Virtuous Skirt'),
(5, 0,  6, 0, 3, 'Wolfshear Leggings'),
(5, 1,  6, 0, 3, 'Wolfshear Leggings'),
(5, 0,  6, 0, 3, 'Cenarion Reservist''s Pants'),
(5, 1,  6, 0, 3, 'Cenarion Reservist''s Pants'),
(5, 0,  7, 0, 1, 'Virtuous Sandals'),
(5, 1,  7, 0, 1, 'Virtuous Sandals'),
(5, 0,  7, 0, 1, 'Faith Healer''s Boots'),
(5, 1,  7, 0, 1, 'Faith Healer''s Boots'),
(5, 0,  7, 0, 2, 'Boots of the Full Moon'),
(5, 1,  7, 0, 2, 'Boots of the Full Moon'),
(5, 0,  7, 0, 2, 'Soot Encrusted Footwear'),
(5, 1,  7, 0, 2, 'Soot Encrusted Footwear'),
(5, 0,  8, 0, 1, 'Sublime Wristguards'),
(5, 1,  8, 0, 1, 'Sublime Wristguards'),
(5, 0,  8, 0, 1, 'Virtuous Bracers'),
(5, 1,  8, 0, 1, 'Virtuous Bracers'),
(5, 0,  8, 0, 3, 'Wyrmthalak''s Shackles'),
(5, 1,  8, 0, 3, 'Wyrmthalak''s Shackles'),
(5, 0,  8, 0, 3, 'Aristocratic Cuffs'),
(5, 1,  8, 0, 3, 'Aristocratic Cuffs'),
(5, 0,  8, 0, 3, 'Devout Bracers'),
(5, 1,  8, 0, 3, 'Devout Bracers'),
(5, 0,  9, 0, 1, 'Desert Bloom Gloves'),
(5, 1,  9, 0, 1, 'Desert Bloom Gloves'),
(5, 0,  9, 0, 1, 'Hands of the Exalted Herald'),
(5, 1,  9, 0, 1, 'Hands of the Exalted Herald'),
(5, 0,  9, 0, 3, 'Virtuous Gloves'),
(5, 1,  9, 0, 3, 'Virtuous Gloves'),
(5, 0,  9, 0, 3, 'Hands of Power'),
(5, 1,  9, 0, 3, 'Hands of Power'),
(5, 0,  9, 0, 3, 'Runecloth Gloves'),
(5, 1,  9, 0, 3, 'Runecloth Gloves'),
(5, 0, 10, 0, 1, 'Rosewine Circle'),
(5, 1, 10, 0, 1, 'Rosewine Circle'),
(5, 0, 10, 0, 1, 'Band of Mending'),
(5, 1, 10, 0, 1, 'Band of Mending'),
(5, 0, 10, 0, 1, 'Fordring''s Seal'),
(5, 1, 10, 0, 1, 'Fordring''s Seal'),
(5, 0, 10, 0, 3, 'Emerald Flame Ring'),
(5, 1, 10, 0, 3, 'Emerald Flame Ring'),
(5, 0, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(5, 1, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(5, 0, 12, 0, 1, 'Draconic Infused Emblem'),
(5, 1, 12, 0, 1, 'Draconic Infused Emblem'),
(5, 0, 12, 0, 1, 'Blessed Prayer Beads'),
(5, 1, 12, 0, 1, 'Blessed Prayer Beads'),
(5, 0, 12, 0, 2, 'Briarwood Reed'),
(5, 1, 12, 0, 2, 'Briarwood Reed'),
(5, 0, 12, 0, 2, 'Second Wind'),
(5, 1, 12, 0, 2, 'Second Wind'),
(5, 0, 12, 0, 3, 'Mindtap Talisman'),
(5, 1, 12, 0, 3, 'Mindtap Talisman'),
(5, 0, 12, 0, 3, 'Burst of Knowledge'),
(5, 1, 12, 0, 3, 'Burst of Knowledge'),
(5, 0, 12, 0, 3, 'Major Recombobulator'),
(5, 1, 12, 0, 3, 'Major Recombobulator'),
(5, 0, 14, 0, 1, 'Hide of the Wild'),
(5, 1, 14, 0, 1, 'Hide of the Wild'),
(5, 0, 14, 0, 3, 'Cloak of the Cosmos'),
(5, 1, 14, 0, 3, 'Cloak of the Cosmos'),
(5, 0, 14, 0, 3, 'Spritecaster Cape'),
(5, 1, 14, 0, 3, 'Spritecaster Cape'),
(5, 0, 15, 0, 1, 'The Hammer of Grace'),
(5, 1, 15, 0, 1, 'The Hammer of Grace'),
(5, 0, 15, 0, 1, 'Redemption'),
(5, 1, 15, 0, 1, 'Redemption'),
(5, 0, 15, 0, 3, 'Hammer of Revitalization'),
(5, 1, 15, 0, 3, 'Hammer of Revitalization'),
(5, 0, 15, 0, 3, 'Hand of Righteousness'),
(5, 1, 15, 0, 3, 'Hand of Righteousness'),
(5, 0, 15, 0, 3, 'Guiding Stave of Wisdom'),
(5, 1, 15, 0, 3, 'Guiding Stave of Wisdom'),
(5, 0, 15, 0, 3, 'Staff of Metanoia'),
(5, 1, 15, 0, 3, 'Staff of Metanoia'),
(5, 0, 16, 0, 1, 'Tome of Divine Right'),
(5, 1, 16, 0, 1, 'Tome of Divine Right'),
(5, 0, 16, 0, 3, 'Brightly Glowing Stone'),
(5, 1, 16, 0, 3, 'Brightly Glowing Stone'),
(5, 0, 16, 0, 3, 'Thaurissan''s Royal Scepter'),
(5, 1, 16, 0, 3, 'Thaurissan''s Royal Scepter'),
(5, 0, 16, 0, 3, 'Spirit of Aquementas'),
(5, 1, 16, 0, 3, 'Spirit of Aquementas'),
(5, 0, 17, 0, 1, 'Wand of Eternal Light'),
(5, 1, 17, 0, 1, 'Wand of Eternal Light'),
(5, 0, 17, 0, 3, 'Mana Channeling Wand'),
(5, 1, 17, 0, 3, 'Mana Channeling Wand'),
(5, 0, 17, 0, 3, 'Bonecreeper Stylus'),
(5, 1, 17, 0, 3, 'Bonecreeper Stylus'),
(5, 0, 10, 2, 3, 'Eye of Orgrimmar'),
(5, 1, 10, 2, 3, 'Eye of Orgrimmar'),
(5, 0, 10, 1, 3, 'Songstone of Ironforge'),
(5, 1, 10, 1, 3, 'Songstone of Ironforge');

-- =====================================================================
-- Voleur (classe 4) - Assassinat (0), Combat (1), Subtilite (2).
-- L'armure et les bijoux sont communs aux trois onglets : le guide ne les
-- distingue pas, et l'ensemble Darkmantle est le coeur du set pre-raid.
--
-- Les ARMES en revanche sont reparties par onglet, car le guide propose deux
-- montages : dague et epee. Assassinat et Subtilite prennent les dagues
-- (Felstriker / Distracting Dagger), Combat prend les epees.
--
-- Les Dal'Rend sont VOLONTAIREMENT CONSERVEES ici pour Combat, contrairement au
-- chasseur a qui on les a retirees. Elles sont un vrai BiS de voleur Combat, pas
-- un simple depannage. Consequence mecanique : guerrier Fureur et voleur Combat
-- les listent tous les deux, donc aucun des deux ne laisse l'objet a l'autre -
-- les deux rollent. C'est le comportement voulu : la regle "je le laisse a
-- l'autre" ne se declenche que quand l'objet n'est PAS dans ma propre liste.
--
-- Rangs de la page : Best -> 1, Optional -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(4, 0,  0, 0, 1, 'Darkmantle Cap'),
(4, 1,  0, 0, 1, 'Darkmantle Cap'),
(4, 2,  0, 0, 1, 'Darkmantle Cap'),
(4, 0,  0, 0, 3, 'Shadowcraft Cap'),
(4, 1,  0, 0, 3, 'Shadowcraft Cap'),
(4, 2,  0, 0, 3, 'Shadowcraft Cap'),
(4, 0,  0, 0, 3, 'Mask of the Unforgiven'),
(4, 1,  0, 0, 3, 'Mask of the Unforgiven'),
(4, 2,  0, 0, 3, 'Mask of the Unforgiven'),
(4, 0,  0, 0, 3, 'Eye of Rend'),
(4, 1,  0, 0, 3, 'Eye of Rend'),
(4, 2,  0, 0, 3, 'Eye of Rend'),
(4, 0,  1, 0, 1, 'Pendant of Celerity'),
(4, 1,  1, 0, 1, 'Pendant of Celerity'),
(4, 2,  1, 0, 1, 'Pendant of Celerity'),
(4, 0,  1, 0, 1, 'Mark of Fordring'),
(4, 1,  1, 0, 1, 'Mark of Fordring'),
(4, 2,  1, 0, 1, 'Mark of Fordring'),
(4, 0,  1, 0, 3, 'Beads of Ogre Might'),
(4, 1,  1, 0, 3, 'Beads of Ogre Might'),
(4, 2,  1, 0, 3, 'Beads of Ogre Might'),
(4, 0,  2, 0, 1, 'Darkmantle Spaulders'),
(4, 1,  2, 0, 1, 'Darkmantle Spaulders'),
(4, 2,  2, 0, 1, 'Darkmantle Spaulders'),
(4, 0,  2, 0, 3, 'Shadowcraft Spaulders'),
(4, 1,  2, 0, 3, 'Shadowcraft Spaulders'),
(4, 2,  2, 0, 3, 'Shadowcraft Spaulders'),
(4, 0,  2, 0, 3, 'Truestrike Shoulders'),
(4, 1,  2, 0, 3, 'Truestrike Shoulders'),
(4, 2,  2, 0, 3, 'Truestrike Shoulders'),
(4, 0,  2, 0, 3, 'Wyrmhide Spaulders'),
(4, 1,  2, 0, 3, 'Wyrmhide Spaulders'),
(4, 2,  2, 0, 3, 'Wyrmhide Spaulders'),
(4, 0,  4, 0, 1, 'Darkmantle Tunic'),
(4, 1,  4, 0, 1, 'Darkmantle Tunic'),
(4, 2,  4, 0, 1, 'Darkmantle Tunic'),
(4, 0,  4, 0, 3, 'Shadowcraft Tunic'),
(4, 1,  4, 0, 3, 'Shadowcraft Tunic'),
(4, 2,  4, 0, 3, 'Shadowcraft Tunic'),
(4, 0,  4, 0, 3, 'Cadaverous Armor'),
(4, 1,  4, 0, 3, 'Cadaverous Armor'),
(4, 2,  4, 0, 3, 'Cadaverous Armor'),
(4, 0,  4, 0, 3, 'Traphook Jerkin'),
(4, 1,  4, 0, 3, 'Traphook Jerkin'),
(4, 2,  4, 0, 3, 'Traphook Jerkin'),
(4, 0,  5, 0, 1, 'Darkmantle Belt'),
(4, 1,  5, 0, 1, 'Darkmantle Belt'),
(4, 2,  5, 0, 1, 'Darkmantle Belt'),
(4, 0,  5, 0, 3, 'Shadowcraft Belt'),
(4, 1,  5, 0, 3, 'Shadowcraft Belt'),
(4, 2,  5, 0, 3, 'Shadowcraft Belt'),
(4, 0,  5, 0, 3, 'Cloudrunner Girdle'),
(4, 1,  5, 0, 3, 'Cloudrunner Girdle'),
(4, 2,  5, 0, 3, 'Cloudrunner Girdle'),
(4, 0,  5, 0, 3, 'Mugger''s Belt'),
(4, 1,  5, 0, 3, 'Mugger''s Belt'),
(4, 2,  5, 0, 3, 'Mugger''s Belt'),
(4, 0,  6, 0, 1, 'Devilsaur Leggings'),
(4, 1,  6, 0, 1, 'Devilsaur Leggings'),
(4, 2,  6, 0, 1, 'Devilsaur Leggings'),
(4, 0,  6, 0, 3, 'Darkmantle Pants'),
(4, 1,  6, 0, 3, 'Darkmantle Pants'),
(4, 2,  6, 0, 3, 'Darkmantle Pants'),
(4, 0,  6, 0, 3, 'Shadowcraft Pants'),
(4, 1,  6, 0, 3, 'Shadowcraft Pants'),
(4, 2,  6, 0, 3, 'Shadowcraft Pants'),
(4, 0,  7, 0, 1, 'Darkmantle Boots'),
(4, 1,  7, 0, 1, 'Darkmantle Boots'),
(4, 2,  7, 0, 1, 'Darkmantle Boots'),
(4, 0,  7, 0, 3, 'Shadowcraft Boots'),
(4, 1,  7, 0, 3, 'Shadowcraft Boots'),
(4, 2,  7, 0, 3, 'Shadowcraft Boots'),
(4, 0,  7, 0, 3, 'Swiftwalker Boots'),
(4, 1,  7, 0, 3, 'Swiftwalker Boots'),
(4, 2,  7, 0, 3, 'Swiftwalker Boots'),
(4, 0,  8, 0, 1, 'Darkmantle Bracers'),
(4, 1,  8, 0, 1, 'Darkmantle Bracers'),
(4, 2,  8, 0, 1, 'Darkmantle Bracers'),
(4, 0,  8, 0, 3, 'Shadowcraft Bracers'),
(4, 1,  8, 0, 3, 'Shadowcraft Bracers'),
(4, 2,  8, 0, 3, 'Shadowcraft Bracers'),
(4, 0,  8, 0, 3, 'Bracers of the Eclipse'),
(4, 1,  8, 0, 3, 'Bracers of the Eclipse'),
(4, 2,  8, 0, 3, 'Bracers of the Eclipse'),
(4, 0,  8, 0, 3, 'Deepfury Bracers'),
(4, 1,  8, 0, 3, 'Deepfury Bracers'),
(4, 2,  8, 0, 3, 'Deepfury Bracers'),
(4, 0,  9, 0, 1, 'Devilsaur Gauntlets'),
(4, 1,  9, 0, 1, 'Devilsaur Gauntlets'),
(4, 2,  9, 0, 1, 'Devilsaur Gauntlets'),
(4, 0,  9, 0, 3, 'Darkmantle Gloves'),
(4, 1,  9, 0, 3, 'Darkmantle Gloves'),
(4, 2,  9, 0, 3, 'Darkmantle Gloves'),
(4, 0,  9, 0, 3, 'Shadowcraft Gloves'),
(4, 1,  9, 0, 3, 'Shadowcraft Gloves'),
(4, 2,  9, 0, 3, 'Shadowcraft Gloves'),
(4, 0, 10, 0, 1, 'Tarnished Elven Ring'),
(4, 1, 10, 0, 1, 'Tarnished Elven Ring'),
(4, 2, 10, 0, 1, 'Tarnished Elven Ring'),
(4, 0, 10, 0, 3, 'Painweaver Band'),
(4, 1, 10, 0, 3, 'Painweaver Band'),
(4, 2, 10, 0, 3, 'Painweaver Band'),
(4, 0, 10, 0, 3, 'Blackstone Ring'),
(4, 1, 10, 0, 3, 'Blackstone Ring'),
(4, 2, 10, 0, 3, 'Blackstone Ring'),
(4, 0, 12, 0, 1, 'Hand of Justice'),
(4, 1, 12, 0, 1, 'Hand of Justice'),
(4, 2, 12, 0, 1, 'Hand of Justice'),
(4, 0, 12, 0, 1, 'Blackhand''s Breadth'),
(4, 1, 12, 0, 1, 'Blackhand''s Breadth'),
(4, 2, 12, 0, 1, 'Blackhand''s Breadth'),
(4, 0, 12, 0, 3, 'Royal Seal of Eldre''Thalas'),
(4, 1, 12, 0, 3, 'Royal Seal of Eldre''Thalas'),
(4, 2, 12, 0, 3, 'Royal Seal of Eldre''Thalas'),
(4, 0, 14, 0, 1, 'Cape of the Black Baron'),
(4, 1, 14, 0, 1, 'Cape of the Black Baron'),
(4, 2, 14, 0, 1, 'Cape of the Black Baron'),
(4, 0, 14, 0, 3, 'Shadow Prowler''s Cloak'),
(4, 1, 14, 0, 3, 'Shadow Prowler''s Cloak'),
(4, 2, 14, 0, 3, 'Shadow Prowler''s Cloak'),
(4, 0, 14, 0, 3, 'Blackveil Cape'),
(4, 1, 14, 0, 3, 'Blackveil Cape'),
(4, 2, 14, 0, 3, 'Blackveil Cape'),
(4, 0, 17, 0, 1, 'Precisely Calibrated Boomstick'),
(4, 1, 17, 0, 1, 'Precisely Calibrated Boomstick'),
(4, 2, 17, 0, 1, 'Precisely Calibrated Boomstick'),
(4, 0, 17, 0, 3, 'Blackcrow'),
(4, 1, 17, 0, 3, 'Blackcrow'),
(4, 2, 17, 0, 3, 'Blackcrow'),
(4, 0, 17, 0, 3, 'Satyr''s Bow'),
(4, 1, 17, 0, 3, 'Satyr''s Bow'),
(4, 2, 17, 0, 3, 'Satyr''s Bow'),
(4, 0, 17, 0, 3, 'Ancient Bone Bow'),
(4, 1, 17, 0, 3, 'Ancient Bone Bow'),
(4, 2, 17, 0, 3, 'Ancient Bone Bow'),
(4, 0, 15, 0, 1, 'Felstriker'),
(4, 0, 15, 0, 3, 'Heartseeker'),
(4, 0, 16, 0, 1, 'Distracting Dagger'),
(4, 0, 16, 0, 3, 'Bonescraper'),
(4, 2, 15, 0, 1, 'Felstriker'),
(4, 2, 15, 0, 3, 'Heartseeker'),
(4, 2, 16, 0, 1, 'Distracting Dagger'),
(4, 2, 16, 0, 3, 'Bonescraper'),
(4, 1, 15, 0, 1, 'Dal''Rend''s Sacred Charge'),
(4, 1, 15, 0, 3, 'Sword of Zeal'),
(4, 1, 16, 0, 1, 'Dal''Rend''s Tribal Guardian'),
(4, 1, 16, 0, 3, 'Mirah''s Song'),
(4, 0, 12, 2, 3, 'Rune of the Guard Captain'),
(4, 1, 12, 2, 3, 'Rune of the Guard Captain'),
(4, 2, 12, 2, 3, 'Rune of the Guard Captain');

-- =====================================================================
-- Paladin Sacre (classe 2, spe 0) - soigneur.
--
-- Le libram va sur l'emplacement 17 (l'emplacement "distance" d'AzerothCore,
-- qui accueille aussi les reliques de paladin, druide, chaman et chevalier).
--
-- Rangs de la page : Best -> 1, Optional -> 3. Exception a la ceinture :
-- Sash of Mercy est le vrai BiS mais c'est un drop monde aleatoire, donc le
-- guide batit son set d'exemple avec Whipvine Cord. On garde donc Sash of Mercy
-- en 1 et on remonte Whipvine Cord en 2 : le bot portera Whipvine Cord en
-- pratique, et basculera tout seul s'il met la main sur la Sash.
--
-- "Uncommon Legs of Healing" n'est pas importe : c'est un drop monde a suffixe
-- aleatoire, il n'a pas de nom fixe resolvable dans item_template.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(2, 0,  0, 0, 1, 'Insightful Hood'),
(2, 0,  0, 0, 3, 'Whitesoul Helm'),
(2, 0,  0, 0, 3, 'Tribal War Feathers'),
(2, 0,  1, 0, 1, 'Animated Chain Necklace'),
(2, 0,  1, 0, 3, 'Amulet of the Redeemed'),
(2, 0,  1, 0, 3, 'Tooth of Gnarr'),
(2, 0,  2, 0, 1, 'Royal Cap Spaulders'),
(2, 0,  2, 0, 3, 'Living Shoulders'),
(2, 0,  2, 0, 3, 'Burial Shawl'),
(2, 0,  4, 0, 1, 'Robes of the Exalted'),
(2, 0,  4, 0, 3, 'Red Dragonscale Breastplate'),
(2, 0,  4, 0, 3, 'Chestplate of Tranquility'),
(2, 0,  5, 0, 1, 'Sash of Mercy'),
(2, 0,  5, 0, 2, 'Whipvine Cord'),
(2, 0,  5, 0, 3, 'Belt of the Ordained'),
(2, 0,  6, 0, 1, 'Padre''s Trousers'),
(2, 0,  6, 0, 3, 'Senior Designer''s Pantaloons'),
(2, 0,  7, 0, 1, 'Boots of the Full Moon'),
(2, 0,  7, 0, 3, 'Verdant Footpads'),
(2, 0,  7, 0, 3, 'Merciful Greaves'),
(2, 0,  8, 0, 1, 'Gallant''s Wristguards'),
(2, 0,  8, 0, 3, 'Loomguard Armbraces'),
(2, 0,  8, 0, 3, 'Bracers of Prosperity'),
(2, 0,  9, 0, 1, 'Harmonious Gauntlets'),
(2, 0,  9, 0, 3, 'Atal''ai Gloves'),
(2, 0,  9, 0, 3, 'Gloves of Restoration'),
(2, 0, 10, 0, 1, 'Fordring''s Seal'),
(2, 0, 11, 0, 1, 'Fordring''s Seal'),
(2, 0, 10, 0, 1, 'Rosewine Circle'),
(2, 0, 11, 0, 1, 'Rosewine Circle'),
(2, 0, 10, 0, 3, 'Band of Mending'),
(2, 0, 11, 0, 3, 'Band of Mending'),
(2, 0, 10, 0, 3, 'Emerald Flame Ring'),
(2, 0, 11, 0, 3, 'Emerald Flame Ring'),
(2, 0, 12, 0, 1, 'Briarwood Reed'),
(2, 0, 13, 0, 1, 'Briarwood Reed'),
(2, 0, 12, 0, 1, 'Second Wind'),
(2, 0, 13, 0, 1, 'Second Wind'),
(2, 0, 12, 0, 3, 'Royal Seal of Eldre''Thalas'),
(2, 0, 13, 0, 3, 'Royal Seal of Eldre''Thalas'),
(2, 0, 14, 0, 1, 'Hide of the Wild'),
(2, 0, 14, 0, 3, 'Cloak of the Cosmos'),
(2, 0, 14, 0, 3, 'Archivist Cape'),
(2, 0, 15, 0, 1, 'The Hammer of Grace'),
(2, 0, 15, 0, 3, 'Hammer of Revitalization'),
(2, 0, 15, 0, 3, 'Energetic Rod'),
(2, 0, 16, 0, 1, 'Brightly Glowing Stone'),
(2, 0, 16, 0, 3, 'Tome of Divine Right'),
(2, 0, 16, 0, 3, 'Thaurissan''s Royal Scepter'),
(2, 0, 17, 0, 1, 'Libram of Divinity');

-- =====================================================================
-- Guerrier Armes (classe 1, spe 0).
--
-- Wowhead ne publie AUCUN guide pre-raid Armes pour Vanilla : en 1.12 la spe
-- DPS de raid du guerrier est Fureur, et Armes ne sert qu'en PvP. Cette liste
-- n'est donc pas issue d'une page de guide.
--
-- Pourquoi ne pas simplement laisser Armes sans liste : sans ligne a son nom,
-- un bot Armes tombe en branche 2 sur TOUS les objets, et comme le BiS de
-- Fureur appartient a une autre spe (1/1 contre 1/0), il le laisse activement
-- aux autres. Un guerrier Armes finirait le plus mal equipe du serveur.
--
-- L'armure et les bijoux sont donc repris tels quels de la liste Fureur : en
-- Vanilla les deux spes veulent exactement les memes statistiques sur les memes
-- pieces de plaques. Seules les ARMES changent : Armes veut une deux-mains
-- lente, la ou Fureur porte deux une-main. L'emplacement 16 (main gauche) est
-- donc volontairement vide, une deux-mains occupant les deux mains.
--
-- Les deux-mains ci-dessous ne viennent pas d'un guide mais du consensus
-- Vanilla habituel. La requete de verification d'emplacement en fin de fichier
-- signalera toute entree qui ne serait pas reellement une deux-mains.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(1, 0,  0, 0, 1, 'Lionheart Helm'),
(1, 0,  0, 0, 2, 'Helm of the Executioner'),
(1, 0,  0, 0, 3, 'Eye of Rend'),
(1, 0,  0, 0, 3, 'Mask of the Unforgiven'),
(1, 0,  1, 0, 1, 'Mark of Fordring'),
(1, 0,  1, 0, 2, 'Pendant of Celerity'),
(1, 0,  1, 0, 3, 'Imperial Jewel'),
(1, 0,  2, 0, 1, 'Truestrike Shoulders'),
(1, 0,  2, 0, 1, 'Black Dragonscale Shoulders'),
(1, 0,  2, 0, 3, 'Wyrmhide Spaulders'),
(1, 0,  4, 0, 1, 'Savage Gladiator Chain'),
(1, 0,  4, 0, 2, 'Cadaverous Armor'),
(1, 0,  4, 0, 2, 'Tombstone Breastplate'),
(1, 0,  4, 0, 2, 'Deathdealer Breastplate'),
(1, 0,  5, 0, 1, 'Omokk''s Girth Restrainer'),
(1, 0,  5, 0, 1, 'Brigam Girdle'),
(1, 0,  5, 0, 2, 'Cloudrunner Girdle'),
(1, 0,  6, 0, 1, 'Devilsaur Leggings'),
(1, 0,  6, 0, 1, 'Eldritch Reinforced Legplates'),
(1, 0,  6, 0, 1, 'Black Dragonscale Leggings'),
(1, 0,  6, 0, 2, 'Cloudkeeper Legplates'),
(1, 0,  7, 0, 1, 'Boots of Heroism'),
(1, 0,  7, 0, 2, 'Black Dragonscale Boots'),
(1, 0,  7, 0, 3, 'Battlechaser''s Greaves'),
(1, 0,  7, 0, 3, 'Shadefiend Boots'),
(1, 0,  8, 0, 1, 'Vambraces of the Sadist'),
(1, 0,  8, 0, 1, 'Battleborn Armbraces'),
(1, 0,  8, 0, 2, 'Wristguards of Renown'),
(1, 0,  9, 0, 1, 'Edgemaster''s Handguards'),
(1, 0,  9, 0, 1, 'Devilsaur Gauntlets'),
(1, 0,  9, 0, 1, 'Gauntlets of Heroism'),
(1, 0,  9, 0, 3, 'Gargoyle Slashers'),
(1, 0, 10, 0, 1, 'Painweaver Band'),
(1, 0, 10, 0, 1, 'Blackstone Ring'),
(1, 0, 10, 0, 2, 'Tarnished Elven Ring'),
(1, 0, 12, 0, 1, 'Diamond Flask'),
(1, 0, 12, 0, 1, 'Blackhand''s Breadth'),
(1, 0, 12, 0, 1, 'Hand of Justice'),
(1, 0, 12, 2, 2, 'Rune of the Guard Captain'),   -- Horde uniquement
(1, 0, 14, 0, 1, 'Cape of the Black Baron'),
(1, 0, 14, 0, 2, 'Blackveil Cape'),
(1, 0, 14, 0, 3, 'Shroud of Domination'),
(1, 0, 17, 0, 1, 'Satyr''s Bow'),
(1, 0, 17, 0, 2, 'Blackcrow'),
(1, 0, 17, 0, 3, 'Riphook'),
(1, 0, 15, 0, 1, 'Arcanite Reaper'),
(1, 0, 15, 0, 1, 'The Unstoppable Force'),
(1, 0, 15, 0, 2, 'Corpsemaker'),
(1, 0, 15, 0, 2, 'Skullforge Reaver'),
(1, 0, 15, 0, 3, 'Ice Barbed Spear'),
(1, 0, 15, 0, 3, 'Sceptre of Smiting');

-- =====================================================================
-- Chaman Elementaire (classe 7, spe 0) - degats lanceur de sorts.
--
-- Le totem va sur l'emplacement 17 (l'emplacement "distance" d'AzerothCore,
-- partage par les reliques de chaman, paladin, druide et chevalier de la mort).
--
-- Rangs : Best -> 1, Optional -> 3.
--
-- Les deux objets classes "Cooldown Swap" par le guide (Draconic Infused Emblem,
-- Enamored Water Spirit) sont mis en rang 3, pas 1. Ce sont des bijoux qu'un
-- joueur echange le temps d'un cooldown puis retire ; un bot ne sait pas faire
-- ca et le porterait en permanence, ce qui serait moins bon que le Royal Seal.
-- En rang 3 ils servent de depannage sans jamais evincer un vrai BiS.
--
-- Eye of Orgrimmar et Eye of the Beast viennent de quetes Horde, d'ou faction 2.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(7, 0,  0, 0, 1, 'Spellweaver''s Turban'),
(7, 0,  0, 0, 3, 'Crimson Felt Hat'),
(7, 0,  0, 0, 3, 'Helm of Latent Power'),
(7, 0,  1, 0, 1, 'Barbed Thorn Necklace'),
(7, 0,  1, 0, 3, 'Diana''s Pearl Necklace'),
(7, 0,  1, 0, 3, 'Star of Mystaria'),
(7, 0,  2, 0, 1, 'Burial Shawl'),
(7, 0,  2, 0, 3, 'Elder Wizard''s Mantle'),
(7, 0,  2, 0, 3, 'Denwatcher''s Shoulders'),
(7, 0,  4, 0, 1, 'Wildthorn Mail'),
(7, 0,  4, 0, 1, 'Robe of Everlasting Night'),
(7, 0,  4, 0, 1, 'Chestplate of Tranquility'),
(7, 0,  5, 0, 1, 'Sash of the Windreaver'),
(7, 0,  5, 0, 1, 'Ban''thok Sash'),
(7, 0,  5, 0, 3, 'Barrage Girdle'),
(7, 0,  6, 0, 1, 'Skyshroud Leggings'),
(7, 0,  6, 0, 3, 'Silvermoon Leggings'),
(7, 0,  6, 0, 3, 'Spiritshroud Leggings'),
(7, 0,  7, 0, 1, 'Omnicast Boots'),
(7, 0,  7, 0, 1, 'Waterspout Boots'),
(7, 0,  7, 0, 3, 'Kayser''s Boots of Precision'),
(7, 0,  7, 0, 3, 'Verdant Footpads'),
(7, 0,  8, 0, 1, 'Sublime Wristguards'),
(7, 0,  8, 0, 3, 'Modest Armguards'),
(7, 0,  8, 0, 3, 'Bindings of The Five Thunders'),
(7, 0,  8, 0, 3, 'Earthfury Bracers'),
(7, 0,  9, 0, 1, 'Hands of Power'),
(7, 0,  9, 0, 3, 'Elven Spirit Claws'),
(7, 0,  9, 0, 3, 'Dracorian Gauntlets'),
(7, 0, 10, 0, 1, 'Rune Band of Wizardry'),
(7, 0, 11, 0, 1, 'Rune Band of Wizardry'),
(7, 0, 10, 0, 1, 'Maiden''s Circle'),
(7, 0, 11, 0, 1, 'Maiden''s Circle'),
(7, 0, 10, 0, 1, 'Band of Rumination'),
(7, 0, 11, 0, 1, 'Band of Rumination'),
(7, 0, 10, 2, 1, 'Eye of Orgrimmar'),
(7, 0, 11, 2, 1, 'Eye of Orgrimmar'),
(7, 0, 12, 0, 1, 'Briarwood Reed'),
(7, 0, 13, 0, 1, 'Briarwood Reed'),
(7, 0, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(7, 0, 13, 0, 1, 'Royal Seal of Eldre''Thalas'),
(7, 0, 12, 2, 3, 'Eye of the Beast'),
(7, 0, 13, 2, 3, 'Eye of the Beast'),
(7, 0, 12, 0, 3, 'Draconic Infused Emblem'),
(7, 0, 13, 0, 3, 'Draconic Infused Emblem'),
(7, 0, 12, 0, 3, 'Enamored Water Spirit'),
(7, 0, 13, 0, 3, 'Enamored Water Spirit'),
(7, 0, 14, 0, 1, 'Crystalline Threaded Cape'),
(7, 0, 14, 0, 3, 'Amplifying Cloak'),
(7, 0, 14, 0, 3, 'Heliotrope Cloak'),
(7, 0, 14, 0, 3, 'Deep Woodlands Cloak'),
(7, 0, 15, 0, 1, 'Witchblade'),
(7, 0, 15, 0, 3, 'Energetic Rod'),
(7, 0, 15, 0, 3, 'Rod of the Ogre Magi'),
(7, 0, 16, 0, 1, 'Scepter of Interminable Focus'),
(7, 0, 16, 0, 3, 'Draconian Aegis of the Legion'),
(7, 0, 16, 0, 3, 'Spirit of Aquementas'),
(7, 0, 16, 0, 3, 'Gizlock''s Hypertech Buckler'),
(7, 0, 17, 0, 1, 'Totem of the Storm'),
(7, 0, 17, 0, 3, 'Totem of Rebirth');

-- =====================================================================
-- Chaman Amelioration (classe 7, spe 1) - degats en melee.
--
-- Le guide monte le set Black Dragonscale (epaules, jambes, bottes) pour ses
-- bonus de panoplie, d'ou leur rang 1 malgre des statistiques individuelles
-- inferieures a Devilsaur ou Bloodmail. Les pieces concurrentes sont donc
-- listees en rang 1 elles aussi : le bot prendra ce qu'il trouve en premier,
-- faute de savoir raisonner en panoplies.
--
-- Emplacement 15 : le guide melange une arme a une main (Annihilator) et des
-- deux-mains (Nightfall et les alternatives). Les deux vivent au meme
-- emplacement ; le coeur empeche de toute facon de porter une main gauche avec
-- une deux-mains, donc le bouclier en 16 ne sert qu'avec Annihilator.
--
-- Rangs : Best -> 1, Optional -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(7, 1,  0, 0, 1, 'Crown of Tyranny'),
(7, 1,  0, 0, 3, 'Eye of Rend'),
(7, 1,  0, 0, 3, 'Backwood Helm'),
(7, 1,  1, 0, 1, 'Mark of Fordring'),
(7, 1,  1, 0, 3, 'Imperial Jewel'),
(7, 1,  1, 0, 3, 'Will of the Martyr'),
(7, 1,  2, 0, 1, 'Black Dragonscale Shoulders'),
(7, 1,  2, 0, 3, 'Truestrike Shoulders'),
(7, 1,  2, 0, 3, 'Wyrmhide Spaulders'),
(7, 1,  4, 0, 1, 'Savage Gladiator Chain'),
(7, 1,  4, 0, 3, 'Black Dragonscale Breastplate'),
(7, 1,  4, 0, 3, 'Cadaverous Armor'),
(7, 1,  5, 0, 1, 'Cloudrunner Girdle'),
(7, 1,  5, 0, 3, 'Bloodmail Belt'),
(7, 1,  5, 0, 3, 'Warpwood Binding'),
(7, 1,  6, 0, 1, 'Black Dragonscale Leggings'),
(7, 1,  6, 0, 1, 'Devilsaur Leggings'),
(7, 1,  6, 0, 3, 'Warbear Woolies'),
(7, 1,  7, 0, 1, 'Black Dragonscale Boots'),
(7, 1,  7, 0, 1, 'Bloodmail Boots'),
(7, 1,  7, 0, 3, 'Windreaver Greaves'),
(7, 1,  8, 0, 1, 'Bracers of the Eclipse'),
(7, 1,  8, 0, 3, 'Blackmist Armguards'),
(7, 1,  8, 0, 3, 'Lordly Armguards'),
(7, 1,  8, 0, 3, 'Slashclaw Bracers'),
(7, 1,  9, 0, 1, 'Chromatic Gauntlets'),
(7, 1,  9, 0, 1, 'Devilsaur Gauntlets'),
(7, 1,  9, 0, 3, 'Voone''s Vice Grips'),
(7, 1, 10, 0, 1, 'Tarnished Elven Ring'),
(7, 1, 11, 0, 1, 'Tarnished Elven Ring'),
(7, 1, 10, 0, 1, 'Blackstone Ring'),
(7, 1, 11, 0, 1, 'Blackstone Ring'),
(7, 1, 10, 0, 1, 'Painweaver Band'),
(7, 1, 11, 0, 1, 'Painweaver Band'),
(7, 1, 10, 0, 3, 'Band of the Ogre King'),
(7, 1, 11, 0, 3, 'Band of the Ogre King'),
(7, 1, 10, 0, 3, 'Myrmidon''s Signet'),
(7, 1, 11, 0, 3, 'Myrmidon''s Signet'),
(7, 1, 12, 0, 1, 'Blackhand''s Breadth'),
(7, 1, 13, 0, 1, 'Blackhand''s Breadth'),
(7, 1, 12, 0, 1, 'Hand of Justice'),
(7, 1, 13, 0, 1, 'Hand of Justice'),
(7, 1, 12, 2, 3, 'Rune of the Guard Captain'),
(7, 1, 13, 2, 3, 'Rune of the Guard Captain'),
(7, 1, 14, 0, 1, 'Cape of the Black Baron'),
(7, 1, 14, 0, 3, 'Shroud of Domination'),
(7, 1, 14, 0, 3, 'Blackveil Cape'),
(7, 1, 15, 0, 1, 'Annihilator'),
(7, 1, 15, 0, 1, 'Nightfall'),
(7, 1, 15, 0, 3, 'The Unstoppable Force'),
(7, 1, 15, 0, 3, 'Treant''s Bane'),
(7, 1, 15, 0, 3, 'Crystal Spiked Maul'),
(7, 1, 15, 0, 3, 'Arcanite Reaper'),
(7, 1, 15, 0, 3, 'Slavedriver''s Cane'),
(7, 1, 16, 0, 1, 'Draconian Aegis of the Legion'),
(7, 1, 16, 0, 3, 'Gizlock''s Hypertech Buckler'),
(7, 1, 17, 0, 1, 'Totem of Rage'),
(7, 1, 17, 0, 3, 'Totem of Rebirth');

-- =====================================================================
-- Chaman Restauration (classe 7, spe 2) - soigneur.
--
-- Le guide propose DEUX montages : empilage de Mp5, ou empilage de +Soins. On
-- fusionne les deux, le module ne sachant pas choisir une orientation. Les
-- pieces exclusives a l'un des deux sets gardent donc le rang 1 toutes les
-- deux, et le bot portera la premiere obtenue.
--
-- Rangs : Best -> 1, Optional -> 3. Exception habituelle : une piece que le
-- guide note "Optional" mais qu'il utilise dans un de ses sets d'exemple passe
-- en rang 2 (Flarecore Wraps, Tooth of Gnarr, Royal Seal of Eldre'Thalas).
--
-- Earthfury Belt est en rang 2 et non 1 : son interet tient au bonus des 8
-- pieces du set Tier 1, que le module ne sait pas prendre en compte. Seule,
-- elle ne vaut pas la Corehound Belt.
--
-- Draconic Infused Emblem et Enamored Water Spirit sont des bijoux d'echange
-- sur cooldown, mis en rang 3 pour la meme raison que chez l'Elementaire : un
-- bot les porterait en permanence.
--
-- Flarecore Wraps, Earthfury Bracers et Earthfury Belt viennent de Molten Core
-- mais sont liees-quand-equipees, donc achetables a l'hotel des ventes sans
-- mettre un pied dans le raid. Leur place au palier 10 est justifiee.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(7, 2,  0, 0, 1, 'Insightful Hood'),
(7, 2,  0, 0, 3, 'Tribal War Feathers'),
(7, 2,  0, 0, 3, 'Cassandra''s Grace'),
(7, 2,  1, 0, 1, 'Animated Chain Necklace'),
(7, 2,  1, 0, 2, 'Tooth of Gnarr'),
(7, 2,  1, 0, 3, 'Amulet of the Redeemed'),
(7, 2,  2, 0, 1, 'Mantle of Lost Hope'),
(7, 2,  2, 0, 3, 'Royal Cap Spaulders'),
(7, 2,  2, 0, 3, 'Burial Shawl'),
(7, 2,  2, 0, 3, 'Mantle of the Scarlet Crusade'),
(7, 2,  2, 0, 3, 'Living Shoulders'),
(7, 2,  4, 0, 1, 'Robes of the Exalted'),
(7, 2,  4, 0, 1, 'Mindsurge Robe'),
(7, 2,  4, 0, 1, 'Red Dragonscale Breastplate'),
(7, 2,  5, 0, 1, 'Corehound Belt'),
(7, 2,  5, 0, 2, 'Earthfury Belt'),
(7, 2,  5, 0, 3, 'Whipvine Cord'),
(7, 2,  5, 0, 3, 'Eyestalk Cord'),
(7, 2,  5, 0, 3, 'Sash of Mercy'),
(7, 2,  6, 0, 1, 'Padre''s Trousers'),
(7, 2,  6, 0, 3, 'Ghoul Skin Leggings'),
(7, 2,  6, 0, 3, 'Senior Designer''s Pantaloons'),
(7, 2,  7, 0, 1, 'Faith Healer''s Boots'),
(7, 2,  7, 0, 1, 'Boots of the Full Moon'),
(7, 2,  7, 0, 1, 'Verdant Footpads'),
(7, 2,  8, 0, 1, 'Loomguard Armbraces'),
(7, 2,  8, 0, 2, 'Flarecore Wraps'),
(7, 2,  8, 0, 3, 'Bracers of Prosperity'),
(7, 2,  8, 0, 3, 'Earthfury Bracers'),
(7, 2,  9, 0, 1, 'Harmonious Gauntlets'),
(7, 2,  9, 0, 3, 'Gloves of Restoration'),
(7, 2,  9, 0, 3, 'Hands of the Exalted Herald'),
(7, 2, 10, 0, 1, 'Rosewine Circle'),
(7, 2, 11, 0, 1, 'Rosewine Circle'),
(7, 2, 10, 0, 1, 'Fordring''s Seal'),
(7, 2, 11, 0, 1, 'Fordring''s Seal'),
(7, 2, 10, 0, 1, 'Band of Mending'),
(7, 2, 11, 0, 1, 'Band of Mending'),
(7, 2, 12, 0, 1, 'Mindtap Talisman'),
(7, 2, 13, 0, 1, 'Mindtap Talisman'),
(7, 2, 12, 0, 1, 'Briarwood Reed'),
(7, 2, 13, 0, 1, 'Briarwood Reed'),
(7, 2, 12, 0, 2, 'Royal Seal of Eldre''Thalas'),
(7, 2, 13, 0, 2, 'Royal Seal of Eldre''Thalas'),
(7, 2, 12, 0, 3, 'Second Wind'),
(7, 2, 13, 0, 3, 'Second Wind'),
(7, 2, 12, 0, 3, 'Draconic Infused Emblem'),
(7, 2, 13, 0, 3, 'Draconic Infused Emblem'),
(7, 2, 12, 0, 3, 'Enamored Water Spirit'),
(7, 2, 13, 0, 3, 'Enamored Water Spirit'),
(7, 2, 14, 0, 1, 'Hide of the Wild'),
(7, 2, 14, 0, 3, 'Cloak of the Cosmos'),
(7, 2, 14, 0, 3, 'Deep Woodlands Cloak'),
(7, 2, 15, 0, 1, 'The Hammer of Grace'),
(7, 2, 15, 0, 1, 'Redemption'),
(7, 2, 15, 0, 3, 'Lorespinner'),
(7, 2, 16, 0, 1, 'Tome of Divine Right'),
(7, 2, 16, 0, 1, 'Brightly Glowing Stone'),
(7, 2, 16, 0, 3, 'Milli''s Lexicon'),
(7, 2, 17, 0, 1, 'Totem of Sustaining'),
(7, 2, 17, 0, 3, 'Totem of Rebirth');

-- =====================================================================
-- Druide Ours (classe 11, spe 10) - tank.
--
-- La spe 10 est la SENTINELLE du module, pas un vrai onglet de talents :
-- Farouche couvre le chat et l'ours sous le meme arbre (tab 1), et
-- ResolveSpec() bascule sur 10 quand PlayerbotAI::IsTank(bot) est vrai.
--
-- --- Objets a suffixe aleatoire ---
-- Le guide nomme des variantes ("Atal'ai Spaulders of the Bear", "Slaghide
-- Gauntlets of the Bear", "Abyssal Leather Leggings of Striking"...). Dans
-- item_template ces objets n'ont QU'UNE entree, portant le nom de base ; le
-- suffixe est tire au sort a la chute. On importe donc le nom de base, et les
-- trois variantes de Slaghide Gauntlets ou d'Atal'ai Spaulders se confondent
-- en une seule ligne. Le bot ne sait pas distinguer "of the Bear" de "of the
-- Monkey" : c'est une limite assumee, pas un oubli.
--
-- --- Manual Crowd Pummeler ---
-- Le guide en fait le BiS absolu, et il a raison pour un joueur. Mais c'est une
-- arme a CHARGES LIMITEES qui se detruit une fois epuisee. Un bot ne sait ni
-- la remplacer ni en farmer d'autres : il la porterait jusqu'a la perdre, puis
-- se retrouverait les mains vides. Elle est donc en rang 3, et Unyielding Maul
-- - que le guide donne comme meilleure arme permanente - prend le rang 1.
--
-- Emplacement 16 volontairement vide : l'ours tank a deux mains.
-- Les recompenses de rang PvP sont exclues, conformement au guide lui-meme.
--
-- Rangs : BiS -> 1, "Best ... swap" -> 2, Alternative -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(11, 10,  0, 0, 1, 'Mask of the Unforgiven'),
(11, 10,  0, 0, 3, 'Wolfshead Helm'),
(11, 10,  0, 0, 3, 'Shadowcraft Cap'),
(11, 10,  0, 0, 3, 'Tattered Leather Hood'),
(11, 10,  0, 0, 3, 'Eye of Rend'),
(11, 10,  1, 0, 1, 'Beads of Ogre Might'),
(11, 10,  1, 0, 3, 'Pendant of Celerity'),
(11, 10,  1, 0, 3, 'Will of the Martyr'),
(11, 10,  1, 0, 3, 'Mark of Fordring'),
(11, 10,  2, 0, 1, 'Truestrike Shoulders'),
(11, 10,  2, 0, 1, 'Atal''ai Spaulders'),
(11, 10,  2, 0, 3, 'Flamescarred Shoulders'),
(11, 10,  4, 0, 1, 'Breastplate of Bloodthirst'),
(11, 10,  4, 0, 3, 'Tombstone Breastplate'),
(11, 10,  4, 0, 3, 'Feralheart Vest'),
(11, 10,  4, 0, 3, 'Mixologist''s Tunic'),
(11, 10,  4, 0, 3, 'Cadaverous Armor'),
(11, 10,  4, 0, 3, 'Warbear Harness'),
(11, 10,  5, 0, 1, 'Cloudrunner Girdle'),
(11, 10,  5, 0, 3, 'Serpentine Sash'),
(11, 10,  5, 0, 3, 'Frostbite Girdle'),
(11, 10,  5, 0, 3, 'Girdle of Beastial Fury'),
(11, 10,  5, 0, 3, 'Mugger''s Belt'),
(11, 10,  5, 0, 3, 'Cadaverous Belt'),
(11, 10,  6, 0, 1, 'Abyssal Leather Leggings'),
(11, 10,  6, 0, 1, 'Devilsaur Leggings'),
(11, 10,  6, 0, 3, 'Plaguehound Leggings'),
(11, 10,  6, 0, 3, 'Cadaverous Leggings'),
(11, 10,  6, 0, 3, 'Shadowcraft Pants'),
(11, 10,  7, 0, 1, 'Boots of Ferocity'),
(11, 10,  7, 0, 3, 'Pads of the Dread Wolf'),
(11, 10,  7, 0, 3, 'Cadaverous Walkers'),
(11, 10,  7, 0, 3, 'Feralheart Boots'),
(11, 10,  7, 0, 3, 'Shadefiend Boots'),
(11, 10,  8, 0, 1, 'Blackmist Armguards'),
(11, 10,  8, 0, 3, 'Bracers of the Eclipse'),
(11, 10,  8, 0, 3, 'Wristguards of Renown'),
(11, 10,  8, 0, 3, 'Malefic Bracers'),
(11, 10,  8, 0, 3, 'Cinderhide Armsplints'),
(11, 10,  9, 0, 1, 'Devilsaur Gauntlets'),
(11, 10,  9, 0, 2, 'Slaghide Gauntlets'),
(11, 10,  9, 0, 3, 'Gargoyle Slashers'),
(11, 10, 10, 0, 1, 'Myrmidon''s Signet'),
(11, 10, 11, 0, 1, 'Myrmidon''s Signet'),
(11, 10, 10, 0, 1, 'Blackstone Ring'),
(11, 10, 11, 0, 1, 'Blackstone Ring'),
(11, 10, 10, 2, 2, 'Thrall''s Resolve'),
(11, 10, 11, 2, 2, 'Thrall''s Resolve'),
(11, 10, 10, 0, 2, 'Ring of Protection'),
(11, 10, 11, 0, 2, 'Ring of Protection'),
(11, 10, 10, 0, 3, 'Band of the Ogre King'),
(11, 10, 11, 0, 3, 'Band of the Ogre King'),
(11, 10, 10, 0, 3, 'Tarnished Elven Ring'),
(11, 10, 11, 0, 3, 'Tarnished Elven Ring'),
(11, 10, 10, 0, 3, 'Archaedic Stone'),
(11, 10, 11, 0, 3, 'Archaedic Stone'),
(11, 10, 10, 0, 3, 'Painweaver Band'),
(11, 10, 11, 0, 3, 'Painweaver Band'),
(11, 10, 12, 0, 1, 'Gnomish Battle Chicken'),
(11, 10, 13, 0, 1, 'Gnomish Battle Chicken'),
(11, 10, 12, 0, 1, 'Blackhand''s Breadth'),
(11, 10, 13, 0, 1, 'Blackhand''s Breadth'),
(11, 10, 12, 0, 1, 'Mark of Tyranny'),
(11, 10, 13, 0, 1, 'Mark of Tyranny'),
(11, 10, 12, 0, 2, 'Mark of the Chosen'),
(11, 10, 13, 0, 2, 'Mark of the Chosen'),
(11, 10, 12, 0, 2, 'Smoking Heart of the Mountain'),
(11, 10, 13, 0, 2, 'Smoking Heart of the Mountain'),
(11, 10, 12, 2, 2, 'Rune of the Guard Captain'),
(11, 10, 13, 2, 2, 'Rune of the Guard Captain'),
(11, 10, 12, 0, 3, 'Glimmering Mithril Insignia'),
(11, 10, 13, 0, 3, 'Glimmering Mithril Insignia'),
(11, 10, 14, 0, 1, 'Phantasmal Cloak'),
(11, 10, 14, 0, 3, 'Stoneskin Gargoyle Cape'),
(11, 10, 14, 0, 3, 'Stoneshield Cloak'),
(11, 10, 14, 0, 3, 'Shroud of Domination'),
(11, 10, 14, 0, 3, 'Cloak of Warding'),
(11, 10, 15, 0, 1, 'Unyielding Maul'),
(11, 10, 15, 0, 3, 'Manual Crowd Pummeler'),
(11, 10, 15, 0, 3, 'Impervious Giant'),
(11, 10, 15, 0, 3, 'Fist of Omokk'),
(11, 10, 15, 0, 3, 'Bonecrusher'),
(11, 10, 17, 0, 1, 'Idol of Brutality');

-- =====================================================================
-- Druide Restauration (classe 11, spe 2) - soigneur.
--
-- Premiere liste ou le guide propose des objets PvP. Ils sont importes mais
-- TOUS en rang 3 : ils demandent des reputations de champ de bataille
-- (Warsong, Alterac) qu'un bot n'atteindra quasiment jamais. En rang 3 ils ne
-- bloquent rien et servent si le hasard les amene. Les paires Horde/Alliance
-- sont separees par faction ; les objets communs aux deux restent en faction 0.
--
-- "Green Lens of Healing" et "Atal'ai Gloves of Healing" sont des objets a
-- suffixe aleatoire : item_template n'a qu'une entree, au nom de base. Le bot
-- ne saura pas distinguer le suffixe "of Healing" d'un autre.
--
-- Le guide ecrit qu'une une-main plus une main gauche rapportent plus qu'une
-- deux-mains. The Hammer of Grace garde donc le rang 1 et Redemption, meilleure
-- deux-mains, descend en rang 2.
--
-- Rangs : Best -> 1, piece du set d'exemple notee "Optional" -> 2, reste -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(11, 2,  0, 0, 1, 'Green Lens'),
(11, 2,  0, 0, 1, 'Cassandra''s Grace'),
(11, 2,  0, 0, 2, 'Insightful Hood'),
(11, 2,  0, 0, 3, 'Spellweaver''s Turban'),
(11, 2,  0, 0, 3, 'Tribal War Feathers'),
(11, 2,  0, 0, 3, 'Crimson Felt Hat'),
(11, 2,  0, 0, 3, 'Holy Shroud'),
(11, 2,  1, 0, 1, 'Animated Chain Necklace'),
(11, 2,  1, 0, 3, 'Tempest Talisman'),
(11, 2,  1, 0, 3, 'Tooth of Gnarr'),
(11, 2,  1, 2, 3, 'Frostwolf Advisor''s Pendant'),
(11, 2,  1, 1, 3, 'Stormpike Sage''s Pendant'),
(11, 2,  2, 0, 1, 'Living Shoulders'),
(11, 2,  2, 0, 3, 'Mantle of the Scarlet Crusade'),
(11, 2,  2, 0, 3, 'Burial Shawl'),
(11, 2,  4, 0, 1, 'Robes of the Exalted'),
(11, 2,  4, 0, 3, 'Forest''s Embrace'),
(11, 2,  4, 0, 3, 'Living Breastplate'),
(11, 2,  4, 0, 3, 'Alanna''s Embrace'),
(11, 2,  4, 0, 3, 'Robe of Everlasting Night'),
(11, 2,  4, 0, 3, 'Chestplate of Tranquility'),
(11, 2,  5, 0, 1, 'Sash of Mercy'),
(11, 2,  5, 0, 2, 'Whipvine Cord'),
(11, 2,  5, 0, 3, 'Eyestalk Cord'),
(11, 2,  6, 0, 1, 'Padre''s Trousers'),
(11, 2,  6, 0, 3, 'Senior Designer''s Pantaloons'),
(11, 2,  6, 0, 3, 'Ghoul Skin Leggings'),
(11, 2,  7, 0, 1, 'Faith Healer''s Boots'),
(11, 2,  7, 0, 3, 'Boots of the Full Moon'),
(11, 2,  7, 0, 3, 'Verdant Footpads'),
(11, 2,  7, 0, 3, 'Waterspout Boots'),
(11, 2,  7, 0, 3, 'Omnicast Boots'),
(11, 2,  8, 0, 1, 'Bracers of Prosperity'),
(11, 2,  8, 0, 3, 'Dryad''s Wrist Bindings'),
(11, 2,  8, 0, 3, 'Bleak Howler Armguards'),
(11, 2,  8, 0, 3, 'Flarecore Wraps'),
(11, 2,  9, 0, 1, 'Hands of the Exalted Herald'),
(11, 2,  9, 0, 1, 'Atal''ai Gloves'),
(11, 2,  9, 0, 3, 'Gloves of Restoration'),
(11, 2,  9, 0, 3, 'Hands of Power'),
(11, 2,  9, 0, 3, 'Fallbrush Handgrips'),
(11, 2,  9, 0, 3, 'Mar Alom''s Grip'),
(11, 2, 10, 0, 1, 'Rosewine Circle'),
(11, 2, 11, 0, 1, 'Rosewine Circle'),
(11, 2, 10, 0, 1, 'Fordring''s Seal'),
(11, 2, 11, 0, 1, 'Fordring''s Seal'),
(11, 2, 10, 0, 3, 'Band of Mending'),
(11, 2, 11, 0, 3, 'Band of Mending'),
(11, 2, 10, 0, 3, 'Maiden''s Circle'),
(11, 2, 11, 0, 3, 'Maiden''s Circle'),
(11, 2, 10, 0, 3, 'Emerald Flame Ring'),
(11, 2, 11, 0, 3, 'Emerald Flame Ring'),
(11, 2, 10, 2, 3, 'Advisor''s Ring'),
(11, 2, 11, 2, 3, 'Advisor''s Ring'),
(11, 2, 10, 1, 3, 'Lorekeeper''s Ring'),
(11, 2, 11, 1, 3, 'Lorekeeper''s Ring'),
(11, 2, 12, 0, 1, 'Royal Seal of Eldre''Thalas'),
(11, 2, 13, 0, 1, 'Royal Seal of Eldre''Thalas'),
(11, 2, 12, 0, 2, 'Mindtap Talisman'),
(11, 2, 13, 0, 2, 'Mindtap Talisman'),
(11, 2, 12, 0, 3, 'Briarwood Reed'),
(11, 2, 13, 0, 3, 'Briarwood Reed'),
(11, 2, 12, 0, 3, 'Second Wind'),
(11, 2, 13, 0, 3, 'Second Wind'),
(11, 2, 12, 0, 3, 'Eye of the Beast'),
(11, 2, 13, 0, 3, 'Eye of the Beast'),
(11, 2, 12, 0, 3, 'Burst of Knowledge'),
(11, 2, 13, 0, 3, 'Burst of Knowledge'),
(11, 2, 14, 0, 1, 'Hide of the Wild'),
(11, 2, 14, 0, 3, 'Cloak of the Cosmos'),
(11, 2, 14, 2, 3, 'Battle Healer''s Cloak'),
(11, 2, 14, 1, 3, 'Caretaker''s Cape'),
(11, 2, 15, 0, 1, 'The Hammer of Grace'),
(11, 2, 15, 0, 2, 'Redemption'),
(11, 2, 15, 0, 3, 'Hammer of Revitalization'),
(11, 2, 15, 0, 3, 'Hand of Righteousness'),
(11, 2, 15, 0, 3, 'Energetic Rod'),
(11, 2, 15, 0, 3, 'Guiding Stave of Wisdom'),
(11, 2, 15, 0, 3, 'Ironbark Staff'),
(11, 2, 15, 0, 3, 'Moonshadow Stave'),
(11, 2, 15, 0, 3, 'Rod of the Ogre Magi'),
(11, 2, 15, 0, 3, 'Staff of Jordan'),
(11, 2, 15, 0, 3, 'Hammer of the Grand Crusader'),
(11, 2, 16, 0, 1, 'Brightly Glowing Stone'),
(11, 2, 16, 0, 3, 'Lei of the Lifegiver'),
(11, 2, 16, 0, 3, 'Therazane''s Touch'),
(11, 2, 16, 0, 3, 'Tome of Divine Right'),
(11, 2, 16, 0, 3, 'Thaurissan''s Royal Scepter'),
(11, 2, 16, 0, 3, 'Beacon of Hope'),
(11, 2, 17, 0, 1, 'Idol of Rejuvenation');

-- =====================================================================
-- Paladin Protection (classe 2, spe 1) - tank.
--
-- ATTENTION, SOURCE DIFFERENTE : cette liste vient d'un guide Classic Phase 3
-- et non d'un guide Season of Mastery comme les autres. Il n'affiche AUCUN
-- rang : il se contente d'enumerer les objets par emplacement, du meilleur au
-- moins bon. La convention appliquee ici est donc positionnelle :
--   1er de la liste -> rang 1, 2e -> rang 2, 3e et suivants -> rang 3.
-- C'est une interpretation, pas une donnee du guide. A reviser si un guide
-- SoM du paladin tank apparait.
--
-- Les recompenses PvP (Sergeant's Cape, Stormpike Insignia) sont descendues en
-- rang 3 quelle que soit leur position : elles demandent un grade de classement
-- PvP qu'un bot n'obtiendra pas.
--
-- Stormpike Insignia est cote Alliance. L'equivalent Horde n'est pas importe :
-- le guide ne le nomme pas et je ne veux pas inventer un nom d'objet.
--
-- Aucun libram (emplacement 17) : ce guide n'en propose pas pour le tank.
--
-- Note de securite : si l'une de ces pieces s'averait reservee a une autre
-- classe, elle ne ferait rien de mal. La branche 1 du module revalide
-- bot->BotCanUseItem() avant de forcer le verdict, donc un objet inequipable
-- est simplement ignore.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(2, 1,  0, 0, 1, 'Enchanted Thorium Helm'),
(2, 1,  0, 0, 2, 'Gyth''s Skull'),
(2, 1,  0, 0, 3, 'Golem Skull Helm'),
(2, 1,  0, 0, 3, 'Helm of Awareness'),
(2, 1,  1, 0, 1, 'Medallion of Grand Marshal Morris'),
(2, 1,  1, 0, 2, 'Talisman of Evasion'),
(2, 1,  1, 0, 3, 'Verek''s Collar'),
(2, 1,  1, 0, 3, 'Evil Eye Pendant'),
(2, 1,  2, 0, 1, 'Stockade Pauldrons'),
(2, 1,  2, 0, 2, 'Wailing Nightbane Pauldrons'),
(2, 1,  2, 0, 3, 'Stoneform Shoulders'),
(2, 1,  2, 0, 3, 'Spaulders of Valor'),
(2, 1,  4, 0, 1, 'Deathbone Chestplate'),
(2, 1,  4, 0, 2, 'Ornate Adamantium Breastplate'),
(2, 1,  4, 0, 3, 'Enchanted Thorium Breastplate'),
(2, 1,  4, 0, 3, 'Kromcrush''s Chestplate'),
(2, 1,  5, 0, 1, 'Deathbone Girdle'),
(2, 1,  5, 0, 2, 'Stalwart Clutch'),
(2, 1,  5, 0, 3, 'Lightforge Belt'),
(2, 1,  6, 0, 1, 'Deathbone Legguards'),
(2, 1,  6, 0, 2, 'Enchanted Thorium Leggings'),
(2, 1,  6, 0, 3, 'Legplates of the Eternal Guardian'),
(2, 1,  6, 0, 3, 'Bejeweled Legguards'),
(2, 1,  7, 0, 1, 'Deathbone Sabatons'),
(2, 1,  7, 0, 2, 'Shalehusk Boots'),
(2, 1,  7, 0, 3, 'Boots of Avoidance'),
(2, 1,  7, 0, 3, 'Master Cannoneer Boots'),
(2, 1,  8, 0, 1, 'Vigorsteel Vambraces'),
(2, 1,  8, 0, 2, 'Bracers of Valor'),
(2, 1,  8, 0, 3, 'Lightforge Bracers'),
(2, 1,  8, 0, 3, 'Fel Hardened Bracers'),
(2, 1,  9, 0, 1, 'Deathbone Gauntlets'),
(2, 1,  9, 0, 2, 'Boneclenched Gauntlets'),
(2, 1,  9, 0, 3, 'Stonegrip Gauntlets'),
(2, 1,  9, 0, 3, 'Voone''s Vice Grips'),
(2, 1,  9, 0, 3, 'Force Imbued Gauntlets'),
(2, 1, 10, 0, 1, 'Naglering'),
(2, 1, 11, 0, 1, 'Naglering'),
(2, 1, 10, 0, 1, 'Ring of Protection'),
(2, 1, 11, 0, 1, 'Ring of Protection'),
(2, 1, 10, 0, 3, 'Hardened Stone Band'),
(2, 1, 11, 0, 3, 'Hardened Stone Band'),
(2, 1, 10, 0, 3, 'Myrmidon''s Signet'),
(2, 1, 11, 0, 3, 'Myrmidon''s Signet'),
(2, 1, 12, 0, 1, 'Force of Will'),
(2, 1, 13, 0, 1, 'Force of Will'),
(2, 1, 12, 0, 1, 'Smotts'' Compass'),
(2, 1, 13, 0, 1, 'Smotts'' Compass'),
(2, 1, 12, 0, 2, 'Mark of the Chosen'),
(2, 1, 13, 0, 2, 'Mark of the Chosen'),
(2, 1, 12, 0, 3, 'Vigilance Charm'),
(2, 1, 13, 0, 3, 'Vigilance Charm'),
(2, 1, 12, 0, 3, 'Mindtap Talisman'),
(2, 1, 13, 0, 3, 'Mindtap Talisman'),
(2, 1, 12, 1, 3, 'Stormpike Insignia Rank 6'),
(2, 1, 13, 1, 3, 'Stormpike Insignia Rank 6'),
(2, 1, 14, 0, 1, 'The Emperor''s New Cape'),
(2, 1, 14, 0, 2, 'Redoubt Cloak'),
(2, 1, 14, 1, 3, 'Sergeant''s Cape'),
(2, 1, 15, 0, 1, 'Flurry Axe'),
(2, 1, 15, 0, 2, 'Mastersmith''s Hammer'),
(2, 1, 15, 0, 3, 'Arbiter''s Blade'),
(2, 1, 15, 0, 3, 'Hedgecutter'),
(2, 1, 15, 0, 3, 'Mirah''s Song'),
(2, 1, 16, 0, 1, 'Draconian Deflector'),
(2, 1, 16, 0, 2, 'Barrier Shield'),
(2, 1, 16, 0, 3, 'Argent Defender'),
(2, 1, 16, 0, 3, 'Troll Protector');

-- =====================================================================
-- Paladin Vindicte (classe 2, spe 2) - degats en melee.
--
-- CAS PARTICULIER : huit emplacements ont pour BiS de l'equipement de
-- reputation de champ de bataille (League of Arathor, Silverwing Sentinels,
-- Stormpike Guard - tous exaltes). Un bot n'atteindra pas ces reputations.
-- Tous ces objets sont donc descendus en RANG 3, et la meilleure alternative
-- non-PvP est REMONTEE en rang 1 :
--   dos      : Cloak of the Honor Guard    -> Cape of the Black Baron
--   poignets : Berserker Bracers           -> Battleborn Armbraces
--   jambes   : Sentinel's Plate Legguards  -> Devilsaur Leggings
--   arme     : The Unstoppable Force       -> Arcanite Reaper
--   anneau   : Don Julio's Band            -> Blackstone Ring (deja BiS)
-- Le guide se contredit d'ailleurs lui-meme : son intro annonce exclure le
-- PvP, puis son set d'exemple en est rempli.
--
-- Blackblade of Shahram reste en rang 3 malgre sa puissance : le guide le
-- decrit comme une chute "extremement rare" impossible a farmer de facon
-- fiable. Arcanite Reaper, fabriquee, est bien plus sure pour un bot.
--
-- Les vendeurs cites sont tous Alliance, d'ou faction 1 sur ces lignes. Les
-- equivalents Horde existent mais le guide ne les nomme pas ; je prefere ne
-- rien mettre plutot qu'inventer un nom d'objet.
--
-- Supreme Sash, Mighty Girdle et Nightshade Girdle sont des objets a suffixe
-- aleatoire ("of the Tiger") : nom de base uniquement.
--
-- Libram of Hope tombe d'Isalien, un boss du Tier 0.5. Avec
-- AllowEarlyDungeonSet2 = 0 il reste hors de portee jusqu'a BWL.
--
-- Rangs : BiS -> 1, alternative fiable -> 2, reste et PvP -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(2, 2,  0, 0, 1, 'Lionheart Helm'),
(2, 2,  0, 0, 2, 'Helm of the Executioner'),
(2, 2,  0, 0, 3, 'Eye of Rend'),
(2, 2,  0, 0, 3, 'Mask of the Unforgiven'),
(2, 2,  1, 0, 1, 'Beads of Ogre Might'),
(2, 2,  1, 0, 2, 'Pendant of Celerity'),
(2, 2,  1, 0, 3, 'Mark of Fordring'),
(2, 2,  1, 0, 3, 'Imperial Jewel'),
(2, 2,  2, 0, 1, 'Truestrike Shoulders'),
(2, 2,  2, 0, 2, 'Black Dragonscale Shoulders'),
(2, 2,  2, 0, 3, 'Wyrmhide Spaulders'),
(2, 2,  2, 1, 3, 'Highlander''s Plate Spaulders'),
(2, 2,  4, 0, 1, 'Savage Gladiator Chain'),
(2, 2,  4, 0, 1, 'Cadaverous Armor'),
(2, 2,  4, 0, 3, 'Breastplate of Bloodthirst'),
(2, 2,  4, 0, 3, 'Bonebrace Hauberk'),
(2, 2,  5, 0, 1, 'Brigam Girdle'),
(2, 2,  5, 0, 3, 'Supreme Sash'),
(2, 2,  5, 0, 3, 'Mighty Girdle'),
(2, 2,  5, 0, 3, 'Nightshade Girdle'),
(2, 2,  5, 1, 3, 'Highlander''s Plate Girdle'),
(2, 2,  6, 0, 1, 'Devilsaur Leggings'),
(2, 2,  6, 0, 2, 'Cloudkeeper Legplates'),
(2, 2,  6, 0, 3, 'Handcrafted Mastersmith Leggings'),
(2, 2,  6, 0, 3, 'Black Dragonscale Leggings'),
(2, 2,  6, 1, 3, 'Sentinel''s Plate Legguards'),
(2, 2,  7, 0, 1, 'Bloodmail Boots'),
(2, 2,  7, 0, 2, 'Battlechaser''s Greaves'),
(2, 2,  7, 1, 3, 'Highlander''s Plate Greaves'),
(2, 2,  8, 0, 1, 'Battleborn Armbraces'),
(2, 2,  8, 0, 2, 'Bracers of the Eclipse'),
(2, 2,  8, 0, 3, 'Blackmist Armguards'),
(2, 2,  8, 1, 3, 'Berserker Bracers'),
(2, 2,  9, 0, 1, 'Chromatic Gauntlets'),
(2, 2,  9, 0, 2, 'Devilsaur Gauntlets'),
(2, 2,  9, 0, 3, 'Voone''s Vice Grips'),
(2, 2,  9, 0, 3, 'Gloves of the Dawn'),
(2, 2, 10, 0, 1, 'Blackstone Ring'),
(2, 2, 11, 0, 1, 'Blackstone Ring'),
(2, 2, 10, 0, 2, 'Tarnished Elven Ring'),
(2, 2, 11, 0, 2, 'Tarnished Elven Ring'),
(2, 2, 10, 1, 3, 'Don Julio''s Band'),
(2, 2, 11, 1, 3, 'Don Julio''s Band'),
(2, 2, 10, 1, 3, 'Protector''s Band'),
(2, 2, 11, 1, 3, 'Protector''s Band'),
(2, 2, 12, 0, 1, 'Blackhand''s Breadth'),
(2, 2, 13, 0, 1, 'Blackhand''s Breadth'),
(2, 2, 12, 0, 1, 'Hand of Justice'),
(2, 2, 13, 0, 1, 'Hand of Justice'),
(2, 2, 12, 0, 3, 'Gnomish Battle Chicken'),
(2, 2, 13, 0, 3, 'Gnomish Battle Chicken'),
(2, 2, 12, 0, 3, 'Counterattack Lodestone'),
(2, 2, 13, 0, 3, 'Counterattack Lodestone'),
(2, 2, 12, 0, 3, 'Heart of Wyrmthalak'),
(2, 2, 13, 0, 3, 'Heart of Wyrmthalak'),
(2, 2, 14, 0, 1, 'Cape of the Black Baron'),
(2, 2, 14, 0, 2, 'Shroud of Domination'),
(2, 2, 14, 0, 3, 'Shadewood Cloak'),
(2, 2, 14, 1, 3, 'Cloak of the Honor Guard'),
(2, 2, 15, 0, 1, 'Arcanite Reaper'),
(2, 2, 15, 0, 2, 'Dreadforge Retaliator'),
(2, 2, 15, 0, 3, 'Blackblade of Shahram'),
(2, 2, 15, 0, 3, 'Barbarous Blade'),
(2, 2, 15, 0, 3, 'Blade of Hanna'),
(2, 2, 15, 0, 3, 'Nightfall'),
(2, 2, 15, 1, 3, 'The Unstoppable Force'),
(2, 2, 17, 0, 1, 'Libram of Hope');

-- =====================================================================
-- Guerrier Protection (classe 1, spe 2) - tank.
--
-- Remplace les 8 lignes wowsims du fichier 04, qui ne couvraient que la moitie
-- des emplacements : ni cou, ni anneau, ni bijou, ni dos, ni aucune arme.
-- Les lignes wowsims restent inserees, la cle primaire dedoublonnant ce qui
-- se recoupe ; ce fichier passant en premier, ses rangs l'emportent.
--
-- --- Armes : trois tableaux fusionnes en un ---
-- Le guide separe les armes par race : epees et masses pour l'Humain, haches
-- pour l'Orc, dagues pour les autres (via Mugger's Belt). Tout cela repose sur
-- les bonus de competence d'arme, que le module ne modelise pas - sa table
-- connait la classe, la spe, l'emplacement et la faction, pas la race.
-- Les trois listes sont donc fusionnees sur l'emplacement 15. Un guerrier
-- maitrisant de toute facon les quatre types d'arme, le bot prendra la mieux
-- classee qu'il obtient. Il perdra le bonus de +5 en competence d'arme que le
-- guide met en avant, faute de pouvoir raisonner dessus.
--
-- --- Rangs ---
-- 1 = "Best Overall" ou "Best Threat" du guide, plus les pieces de son set
--     d'exemple "Realistic First Raid Goal"
-- 2 = autres alternatives nommees, accessibles
-- 3 = reputation PvP (Alterac, Arathi), drops monde tres rares, armes de niche
--
-- Beaucoup de pieces en rang 1 appartiennent au set Heroism, c'est-a-dire au
-- Tier 0.5. Avec AllowEarlyDungeonSet2 = 0 elles restent hors de portee
-- jusqu'a BWL : le bot se rabattra sur les rangs 2 en attendant, ce qui est
-- exactement le role de l'echelle de rangs.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(1, 2,  0, 0, 1, 'Helm of Heroism'),
(1, 2,  0, 0, 1, 'Lionheart Helm'),
(1, 2,  0, 0, 1, 'Helm of the Executioner'),
(1, 2,  0, 0, 2, 'Crown of Tyranny'),
(1, 2,  0, 0, 2, 'Helm of Valor'),
(1, 2,  0, 0, 2, 'Golem Skull Helm'),
(1, 2,  0, 0, 3, 'Helm of Awareness'),
(1, 2,  0, 0, 3, 'Avenguard Helm'),
(1, 2,  1, 0, 1, 'Beads of Ogre Might'),
(1, 2,  1, 0, 1, 'Mark of Fordring'),
(1, 2,  1, 0, 2, 'Pendant of Celerity'),
(1, 2,  1, 0, 2, 'Will of the Martyr'),
(1, 2,  1, 0, 3, 'Stormpike Soldier''s Pendant'),
(1, 2,  1, 0, 3, 'Master Sergeant''s Insignia'),
(1, 2,  2, 0, 1, 'Spaulders of Heroism'),
(1, 2,  2, 0, 1, 'Spaulders of Valor'),
(1, 2,  2, 0, 2, 'Slamshot Shoulders'),
(1, 2,  2, 0, 2, 'Ebonsteel Spaulders'),
(1, 2,  2, 0, 3, 'Stockade Pauldrons'),
(1, 2,  4, 0, 1, 'Breastplate of Heroism'),
(1, 2,  4, 0, 1, 'Savage Gladiator Chain'),
(1, 2,  4, 0, 1, 'Breastplate of Valor'),
(1, 2,  4, 0, 2, 'Breastplate of the Chromatic Flight'),
(1, 2,  4, 0, 2, 'Ogre Forged Hauberk'),
(1, 2,  4, 0, 3, 'Ornate Adamantium Breastplate'),
(1, 2,  4, 0, 3, 'Kromcrush''s Chestplate'),
(1, 2,  5, 0, 1, 'Mugger''s Belt'),
(1, 2,  5, 0, 1, 'Brigam Girdle'),
(1, 2,  5, 0, 2, 'Omokk''s Girth Restrainer'),
(1, 2,  5, 0, 2, 'Handcrafted Mastersmith Girdle'),
(1, 2,  5, 0, 2, 'Belt of Heroism'),
(1, 2,  5, 0, 3, 'Highlander''s Plate Girdle'),
(1, 2,  6, 0, 1, 'Eldritch Reinforced Legplates'),
(1, 2,  6, 0, 1, 'Legplates of Heroism'),
(1, 2,  6, 0, 2, 'Cloudkeeper Legplates'),
(1, 2,  6, 0, 2, 'Abyssal Plate Legguards'),
(1, 2,  6, 0, 2, 'Legplates of Valor'),
(1, 2,  6, 0, 3, 'Legplates of Vigilance'),
(1, 2,  6, 0, 3, 'Wraithplate Leggings'),
(1, 2,  7, 0, 1, 'Boots of Heroism'),
(1, 2,  7, 0, 1, 'Boots of Valor'),
(1, 2,  7, 0, 2, 'Bloodmail Boots'),
(1, 2,  7, 0, 2, 'Ribsteel Footguards'),
(1, 2,  7, 0, 3, 'Sapphiron''s Scale Boots'),
(1, 2,  7, 0, 3, 'Boots of Avoidance'),
(1, 2,  8, 0, 1, 'Bracers of Heroism'),
(1, 2,  8, 0, 1, 'Battleborn Armbraces'),
(1, 2,  8, 0, 2, 'Vigorsteel Vambraces'),
(1, 2,  8, 0, 2, 'Blackmist Armguards'),
(1, 2,  8, 0, 2, 'Bracers of Valor'),
(1, 2,  8, 0, 3, 'Slashclaw Bracers'),
(1, 2,  8, 0, 3, 'Vambraces of the Sadist'),
(1, 2,  9, 0, 1, 'Edgemaster''s Handguards'),
(1, 2,  9, 0, 1, 'Gauntlets of Heroism'),
(1, 2,  9, 0, 1, 'Voone''s Vice Grips'),
(1, 2,  9, 0, 2, 'Reiver Claws'),
(1, 2,  9, 0, 3, 'Gordok''s Handguards'),
(1, 2,  9, 0, 3, 'Force Imbued Gauntlets'),
(1, 2, 10, 0, 1, 'Band of the Ogre King'),
(1, 2, 11, 0, 1, 'Band of the Ogre King'),
(1, 2, 10, 0, 1, 'Band of Flesh'),
(1, 2, 11, 0, 1, 'Band of Flesh'),
(1, 2, 10, 0, 1, 'Blackstone Ring'),
(1, 2, 11, 0, 1, 'Blackstone Ring'),
(1, 2, 10, 0, 2, 'Myrmidon''s Signet'),
(1, 2, 11, 0, 2, 'Myrmidon''s Signet'),
(1, 2, 10, 0, 2, 'Tarnished Elven Ring'),
(1, 2, 11, 0, 2, 'Tarnished Elven Ring'),
(1, 2, 10, 0, 2, 'Painweaver Band'),
(1, 2, 11, 0, 2, 'Painweaver Band'),
(1, 2, 10, 1, 2, 'Magni''s Will'),
(1, 2, 11, 1, 2, 'Magni''s Will'),
(1, 2, 10, 0, 3, 'Band of the Steadfast Hero'),
(1, 2, 11, 0, 3, 'Band of the Steadfast Hero'),
(1, 2, 10, 0, 3, 'Naglering'),
(1, 2, 11, 0, 3, 'Naglering'),
(1, 2, 10, 0, 3, 'Don Julio''s Band'),
(1, 2, 11, 0, 3, 'Don Julio''s Band'),
(1, 2, 12, 0, 1, 'Diamond Flask'),
(1, 2, 13, 0, 1, 'Diamond Flask'),
(1, 2, 12, 0, 1, 'Blackhand''s Breadth'),
(1, 2, 13, 0, 1, 'Blackhand''s Breadth'),
(1, 2, 12, 0, 1, 'Hand of Justice'),
(1, 2, 13, 0, 1, 'Hand of Justice'),
(1, 2, 12, 2, 2, 'Rune of the Guard Captain'),
(1, 2, 13, 2, 2, 'Rune of the Guard Captain'),
(1, 2, 12, 0, 2, 'Counterattack Lodestone'),
(1, 2, 13, 0, 2, 'Counterattack Lodestone'),
(1, 2, 12, 0, 2, 'Vigilance Charm'),
(1, 2, 13, 0, 2, 'Vigilance Charm'),
(1, 2, 12, 0, 3, 'Mark of the Chosen'),
(1, 2, 13, 0, 3, 'Mark of the Chosen'),
(1, 2, 12, 0, 3, 'Force of Will'),
(1, 2, 13, 0, 3, 'Force of Will'),
(1, 2, 12, 1, 3, 'Stormpike Insignia Rank 6'),
(1, 2, 13, 1, 3, 'Stormpike Insignia Rank 6'),
(1, 2, 12, 2, 3, 'Frostwolf Insignia Rank 6'),
(1, 2, 13, 2, 3, 'Frostwolf Insignia Rank 6'),
(1, 2, 14, 0, 1, 'Stoneskin Gargoyle Cape'),
(1, 2, 14, 0, 2, 'Shifting Cloak'),
(1, 2, 14, 0, 2, 'The Emperor''s New Cape'),
(1, 2, 14, 0, 2, 'Phantasmal Cloak'),
(1, 2, 14, 0, 3, 'Armswake Cloak'),
(1, 2, 14, 0, 3, 'Redoubt Cloak'),
(1, 2, 15, 0, 1, 'Blackguard'),
(1, 2, 15, 0, 1, 'Mirah''s Song'),
(1, 2, 15, 0, 2, 'Ironfoe'),
(1, 2, 15, 0, 2, 'Mass of McGowan'),
(1, 2, 15, 0, 2, 'Annihilator'),
(1, 2, 15, 0, 2, 'Bone Slicing Hatchet'),
(1, 2, 15, 0, 2, 'Hedgecutter'),
(1, 2, 15, 0, 2, 'Felstriker'),
(1, 2, 15, 0, 2, 'Heartseeker'),
(1, 2, 15, 0, 3, 'Timeworn Mace'),
(1, 2, 15, 0, 3, 'Serathil'),
(1, 2, 15, 0, 3, 'Tooth of Eranikus'),
(1, 2, 15, 0, 3, 'Scarlet Kris'),
(1, 2, 15, 0, 3, 'Bonescraper'),
(1, 2, 15, 0, 3, 'Darrowspike'),
(1, 2, 15, 0, 3, 'The Lobotomizer'),
(1, 2, 15, 1, 3, 'Stormstrike Hammer'),
(1, 2, 15, 1, 3, 'Electrified Dagger'),
(1, 2, 15, 2, 3, 'Frostbite'),
(1, 2, 15, 2, 3, 'Glacial Blade'),
(1, 2, 16, 0, 1, 'Dreadguard''s Protector'),
(1, 2, 16, 0, 2, 'Force Reactive Disk'),
(1, 2, 16, 0, 2, 'Draconian Deflector'),
(1, 2, 16, 0, 3, 'The Immovable Object'),
(1, 2, 16, 0, 3, 'Wall of the Dead'),
(1, 2, 16, 0, 3, 'Sacred Protector'),
(1, 2, 16, 0, 3, 'Darrowshire Strongguard'),
(1, 2, 16, 0, 3, 'Distracting Dagger'),
(1, 2, 17, 0, 1, 'Satyr''s Bow'),
(1, 2, 17, 0, 1, 'Blackcrow'),
(1, 2, 17, 0, 2, 'Gorewood Bow'),
(1, 2, 17, 0, 3, 'Bloodseeker'),
(1, 2, 17, 0, 3, 'Carapace Spine Crossbow');

-- =====================================================================
-- Druide Farouche / chat (classe 11, spe 1) - degats en melee.
--
-- Remplace les 8 lignes wowsims du fichier 04, qui laissaient a nu le cou,
-- les anneaux, les bijoux, le dos et les deux emplacements d'arme.
--
-- Manual Crowd Pummeler : meme arbitrage que chez l'ours. Le guide en fait le
-- BiS absolu ("MCP a lui seul apporte 10 % du DPS total"), mais c'est une arme
-- a charges limitees qui se detruit une fois epuisee et qu'il faut refarmer a
-- Gnomeregan. Un bot ne sait pas faire ca : elle passe en rang 3, et
-- Bonecrusher - le "Distant Second" du guide - prend le rang 1.
--
-- Beaucoup d'objets a suffixe aleatoire ici ("of the Tiger", "of Striking") :
-- seul le nom de base existe dans item_template, le bot ne distinguera donc
-- pas un bon suffixe d'un mauvais. Ils sont tous en rang 3 pour cette raison.
--
-- Le guide precise qu'aucune idole ne sert au chat : Idol of Brutality, l'idole
-- de tank, reste donc le meilleur choix pour l'emplacement 17.
-- Emplacement 16 vide : le chat porte une deux-mains.
--
-- Rangs : BiS -> 1, alternative solide -> 2, suffixe aleatoire et reste -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(11, 1,  0, 0, 1, 'Wolfshead Helm'),
(11, 1,  1, 0, 1, 'Pendant of Celerity'),
(11, 1,  1, 0, 2, 'Beads of Ogre Might'),
(11, 1,  1, 0, 3, 'Mark of Fordring'),
(11, 1,  1, 0, 3, 'Prismatic Pendant'),
(11, 1,  1, 0, 3, 'Jungle Necklace'),
(11, 1,  2, 0, 1, 'Truestrike Shoulders'),
(11, 1,  2, 0, 3, 'Dark Warder''s Pauldrons'),
(11, 1,  2, 0, 3, 'Wyrmhide Spaulders'),
(11, 1,  2, 0, 3, 'Flamescarred Shoulders'),
(11, 1,  2, 0, 3, 'Wyrmtongue Shoulders'),
(11, 1,  2, 1, 3, 'Clouddrift Mantle'),
(11, 1,  4, 0, 1, 'Cadaverous Armor'),
(11, 1,  4, 0, 3, 'Breastplate of Bloodthirst'),
(11, 1,  4, 0, 3, 'Grizzled Pelt'),
(11, 1,  4, 0, 3, 'Tombstone Breastplate'),
(11, 1,  5, 0, 1, 'Cloudrunner Girdle'),
(11, 1,  5, 0, 3, 'Adventurer''s Belt'),
(11, 1,  5, 0, 3, 'Supreme Sash'),
(11, 1,  5, 0, 3, 'Mighty Girdle'),
(11, 1,  5, 0, 3, 'Nightshade Girdle'),
(11, 1,  6, 0, 1, 'Plaguehound Leggings'),
(11, 1,  6, 0, 1, 'Devilsaur Leggings'),
(11, 1,  6, 0, 3, 'Abyssal Leather Leggings'),
(11, 1,  6, 0, 3, 'Shadowcraft Pants'),
(11, 1,  6, 0, 3, 'Traveler''s Leggings'),
(11, 1,  7, 0, 1, 'Boots of Ferocity'),
(11, 1,  7, 0, 3, 'Swiftwalker Boots'),
(11, 1,  7, 0, 3, 'Mongoose Boots'),
(11, 1,  7, 0, 3, 'Swiftfoot Treads'),
(11, 1,  7, 0, 3, 'Sandstalker Ankleguards'),
(11, 1,  8, 0, 1, 'Bracers of the Eclipse'),
(11, 1,  8, 0, 1, 'Wristguards of Renown'),
(11, 1,  8, 0, 1, 'Deepfury Bracers'),
(11, 1,  8, 0, 3, 'Blackmist Armguards'),
(11, 1,  9, 0, 1, 'Devilsaur Gauntlets'),
(11, 1,  9, 0, 2, 'Slaghide Gauntlets'),
(11, 1,  9, 0, 3, 'Adventurer''s Gloves'),
(11, 1,  9, 0, 3, 'Supreme Gloves'),
(11, 1,  9, 0, 3, 'Mighty Gauntlets'),
(11, 1, 10, 0, 1, 'Tarnished Elven Ring'),
(11, 1, 11, 0, 1, 'Tarnished Elven Ring'),
(11, 1, 10, 0, 2, 'Blackstone Ring'),
(11, 1, 11, 0, 2, 'Blackstone Ring'),
(11, 1, 10, 0, 3, 'Prismatic Band'),
(11, 1, 11, 0, 3, 'Prismatic Band'),
(11, 1, 10, 0, 3, 'Jungle Ring'),
(11, 1, 11, 0, 3, 'Jungle Ring'),
(11, 1, 10, 0, 3, 'Drakeclaw Band'),
(11, 1, 11, 0, 3, 'Drakeclaw Band'),
(11, 1, 10, 0, 3, 'Magma Forged Band'),
(11, 1, 11, 0, 3, 'Magma Forged Band'),
(11, 1, 12, 0, 1, 'Gnomish Battle Chicken'),
(11, 1, 13, 0, 1, 'Gnomish Battle Chicken'),
(11, 1, 12, 0, 1, 'Blackhand''s Breadth'),
(11, 1, 13, 0, 1, 'Blackhand''s Breadth'),
(11, 1, 12, 0, 1, 'Hand of Justice'),
(11, 1, 13, 0, 1, 'Hand of Justice'),
(11, 1, 12, 2, 1, 'Rune of the Guard Captain'),
(11, 1, 13, 2, 1, 'Rune of the Guard Captain'),
(11, 1, 12, 0, 3, 'Counterattack Lodestone'),
(11, 1, 13, 0, 3, 'Counterattack Lodestone'),
(11, 1, 12, 0, 3, 'Heart of Wyrmthalak'),
(11, 1, 13, 0, 3, 'Heart of Wyrmthalak'),
(11, 1, 12, 0, 3, 'Glimmering Mithril Insignia'),
(11, 1, 13, 0, 3, 'Glimmering Mithril Insignia'),
(11, 1, 14, 0, 1, 'Cape of the Black Baron'),
(11, 1, 14, 0, 2, 'Blackveil Cape'),
(11, 1, 14, 0, 3, 'Shadow Prowler''s Cloak'),
(11, 1, 14, 0, 3, 'Shifting Cloak'),
(11, 1, 14, 0, 3, 'Shroud of Domination'),
(11, 1, 15, 0, 1, 'Bonecrusher'),
(11, 1, 15, 0, 3, 'Manual Crowd Pummeler'),
(11, 1, 15, 0, 3, 'Impervious Giant'),
(11, 1, 15, 0, 3, 'Brutehammer'),
(11, 1, 15, 0, 3, 'Fierce Mauler'),
(11, 1, 15, 0, 3, 'Painbringer'),
(11, 1, 17, 0, 1, 'Idol of Brutality');

-- =====================================================================
-- Druide Equilibre (classe 11, spe 0) - degats lanceur de sorts.
--
-- Complete les 15 lignes wowsims du fichier 04, a qui il manquait la main
-- gauche et l'idole.
--
-- Le BiS de cou de cette spe est celui que le guide appelle "Nacreous Shell
-- Necklace". Sur une base 3.3.5 l'objet 22403 porte le nom WotLK
-- "Diana's Pearl Necklace" - voir l'en-tete du fichier sur les renommages.
--
-- Le guide met en "Best" plusieurs objets a suffixe aleatoire ("of Arcane
-- Wrath") : Archivist Cape, Flameweave Cuffs, Drakestone. Seul le nom de base
-- existe en table, et le bot ne distinguera pas le bon suffixe du mauvais - ce
-- qui, pour un lanceur de sorts, rend la piece inutile. Ils sont donc en
-- rang 3, et l'objet du set d'exemple remonte en rang 1 a leur place.
--
-- Les recompenses de reputation PvP (Warsong, Alterac) sont en rang 3 : un bot
-- n'atteindra pas ces reputations. Les paires Horde/Alliance sont separees.
--
-- Une-main et deux-mains partagent l'emplacement 15. Le set d'exemple part sur
-- une deux-mains, donc les entrees de main gauche ne servent qu'a un bot qui
-- aurait mis la main sur une une-main.
--
-- Rangs : Best -> 1, alternative solide -> 2, suffixe aleatoire et PvP -> 3.
-- =====================================================================
INSERT INTO `bis_seed` (`class`, `spec`, `slot`, `faction`, `rank`, `item_name`) VALUES
(11, 0,  0, 0, 1, 'Spellweaver''s Turban'),
(11, 0,  0, 0, 2, 'Crimson Felt Hat'),
(11, 0,  0, 0, 3, 'Green Lens'),
(11, 0,  0, 0, 3, 'Dreamweave Circlet'),
(11, 0,  1, 0, 1, 'Diana''s Pearl Necklace'),
(11, 0,  1, 0, 2, 'Star of Mystaria'),
(11, 0,  1, 0, 3, 'Tempest Talisman'),
(11, 0,  1, 0, 3, 'Lady Maye''s Pendant'),
(11, 0,  1, 0, 3, 'Jeweled Amulet of Cainwyn'),
(11, 0,  1, 0, 3, 'Tooth of Gnarr'),
(11, 0,  2, 0, 1, 'Burial Shawl'),
(11, 0,  2, 0, 2, 'Kentic Amice'),
(11, 0,  2, 0, 3, 'Cyclone Spaulders'),
(11, 0,  4, 0, 1, 'Robe of Everlasting Night'),
(11, 0,  4, 0, 2, 'Chestplate of Tranquility'),
(11, 0,  4, 0, 3, 'Robe of the Magi'),
(11, 0,  4, 0, 3, 'Alanna''s Embrace'),
(11, 0,  5, 0, 1, 'Ban''thok Sash'),
(11, 0,  5, 0, 2, 'Oddly Magical Belt'),
(11, 0,  5, 0, 3, 'Star Belt'),
(11, 0,  5, 0, 3, 'Thuzadin Sash'),
(11, 0,  5, 2, 3, 'Frostwolf Cloth Belt'),
(11, 0,  5, 1, 3, 'Stormpike Cloth Girdle'),
(11, 0,  6, 0, 1, 'Skyshroud Leggings'),
(11, 0,  6, 0, 3, 'Spellshock Leggings'),
(11, 0,  6, 0, 3, 'Luminary Kilt'),
(11, 0,  7, 0, 1, 'Waterspout Boots'),
(11, 0,  7, 0, 2, 'Omnicast Boots'),
(11, 0,  7, 0, 3, 'Dragonrider Boots'),
(11, 0,  8, 0, 1, 'Sublime Wristguards'),
(11, 0,  8, 0, 3, 'Flameweave Cuffs'),
(11, 0,  8, 0, 3, 'Arena Wristguards'),
(11, 0,  8, 0, 3, 'Dryad''s Wrist Bindings'),
(11, 0,  9, 0, 1, 'Hands of Power'),
(11, 0,  9, 0, 3, 'Earth Warder''s Gloves'),
(11, 0,  9, 0, 3, 'Bloodfire Talons'),
(11, 0,  9, 0, 3, 'Dreamweave Gloves'),
(11, 0, 10, 0, 1, 'Rune Band of Wizardry'),
(11, 0, 11, 0, 1, 'Rune Band of Wizardry'),
(11, 0, 10, 0, 2, 'Maiden''s Circle'),
(11, 0, 11, 0, 2, 'Maiden''s Circle'),
(11, 0, 10, 1, 2, 'Songstone of Ironforge'),
(11, 0, 11, 1, 2, 'Songstone of Ironforge'),
(11, 0, 10, 2, 2, 'Eye of Orgrimmar'),
(11, 0, 11, 2, 2, 'Eye of Orgrimmar'),
(11, 0, 10, 0, 3, 'Band of the Unicorn'),
(11, 0, 11, 0, 3, 'Band of the Unicorn'),
(11, 0, 10, 2, 3, 'Advisor''s Ring'),
(11, 0, 11, 2, 3, 'Advisor''s Ring'),
(11, 0, 10, 1, 3, 'Lorekeeper''s Ring'),
(11, 0, 11, 1, 3, 'Lorekeeper''s Ring'),
(11, 0, 12, 0, 1, 'Briarwood Reed'),
(11, 0, 13, 0, 1, 'Briarwood Reed'),
(11, 0, 12, 0, 1, 'Eye of the Beast'),
(11, 0, 13, 0, 1, 'Eye of the Beast'),
(11, 0, 12, 0, 3, 'Burst of Knowledge'),
(11, 0, 13, 0, 3, 'Burst of Knowledge'),
(11, 0, 14, 0, 1, 'Spritecaster Cape'),
(11, 0, 14, 0, 2, 'Amplifying Cloak'),
(11, 0, 14, 0, 3, 'Archivist Cape'),
(11, 0, 14, 0, 3, 'Deep Woodlands Cloak'),
(11, 0, 14, 2, 3, 'Frostwolf Advisor''s Cloak'),
(11, 0, 14, 1, 3, 'Stormpike Sage''s Cloak'),
(11, 0, 15, 0, 1, 'Lord Valthalak''s Staff of Command'),
(11, 0, 15, 0, 2, 'Rod of the Ogre Magi'),
(11, 0, 15, 0, 2, 'Staff of Jordan'),
(11, 0, 15, 0, 2, 'Witchblade'),
(11, 0, 15, 0, 3, 'Moonshadow Stave'),
(11, 0, 15, 0, 3, 'Zum''rah''s Vexing Cane'),
(11, 0, 15, 0, 3, 'Spire of Hakkar'),
(11, 0, 15, 0, 3, 'Mastersmith''s Hammer'),
(11, 0, 15, 0, 3, 'Energetic Rod'),
(11, 0, 15, 0, 3, 'Ironbark Staff'),
(11, 0, 15, 1, 3, 'Mindfang'),
(11, 0, 15, 2, 3, 'Sageclaw'),
(11, 0, 16, 0, 1, 'Scepter of Interminable Focus'),
(11, 0, 16, 0, 2, 'Spirit of Aquementas'),
(11, 0, 16, 0, 2, 'Tome of the Lost'),
(11, 0, 16, 0, 3, 'Drakestone'),
(11, 0, 16, 0, 3, 'Orb of the Forgotten Seer'),
(11, 0, 16, 0, 3, 'Tome of Arcane Domination'),
(11, 0, 16, 0, 3, 'Therazane''s Touch'),
(11, 0, 17, 0, 1, 'Idol of the Moon');

-- Resolution des noms -> item_template.entry.
-- MIN(entry) departage les rares homonymes d'item_template.
INSERT IGNORE INTO `playerbots_bis_item`
    (`class`, `spec`, `slot`, `faction`, `tier_id`, `item_id`, `rank`, `comment`)
SELECT s.`class`, s.`spec`, s.`slot`, s.`faction`, 10, r.entry, s.`rank`,
       CONCAT('Vanilla Pre-Raid - ', s.`item_name`)
FROM `bis_seed` s
JOIN (SELECT `name`, MIN(`entry`) AS entry FROM `item_template` GROUP BY `name`) r
  ON r.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- VERIFICATION - a executer apres l'import.
-- Toute ligne renvoyee est un nom qui n'existe pas dans item_template :
-- l'objet n'a pas ete insere, corrige le nom et relance le fichier.
-- ---------------------------------------------------------------------
SELECT s.`class`, s.`spec`, s.`slot`, s.`item_name` AS nom_non_resolu
FROM `bis_seed` s
LEFT JOIN `item_template` it
  ON it.`name` COLLATE utf8mb4_general_ci = s.`item_name` COLLATE utf8mb4_general_ci
WHERE it.`entry` IS NULL;

-- ---------------------------------------------------------------------
-- VERIFICATION 2 - coherence de l'emplacement.
-- Un nom peut tres bien exister tout en etant range dans le mauvais
-- emplacement (une arme notee en main gauche alors qu'elle est en main droite,
-- par exemple). Le module cherche l'objet par emplacement : si l'emplacement
-- declare ici ne correspond pas a celui de l'objet, la ligne ne servira jamais.
-- Toute ligne renvoyee par cette requete est a corriger.
--
-- Correspondance InventoryType d'item_template -> emplacement :
--   1 tete | 2 cou | 3 epaules | 5,20 torse | 6 taille | 7 jambes | 8 pieds
--   9 poignets | 10 mains | 11 doigt | 12 bijou | 16 dos
--   13 une-main | 17 deux-mains | 21 main droite | 22,23 main gauche
--   14 bouclier | 15,25,26 distance | 28 relique
-- ---------------------------------------------------------------------
SELECT s.`class`, s.`spec`, s.`slot` AS emplacement_declare,
       it.`InventoryType` AS emplacement_reel, s.`item_name`
FROM `bis_seed` s
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

DROP TEMPORARY TABLE IF EXISTS `bis_seed`;
