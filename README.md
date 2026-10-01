# mod-playerbots-bis

Extension de [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) pour AzerothCore.

Les randombots s'équipent et rollent en suivant une **échelle de progression BiS** par
classe et par spécialisation, au lieu de la règle « ce nouvel objet vaut 1,1 fois mieux
que l'ancien ». Un objet absent de la liste de leur spé n'est ni équipé, ni convoité.

**Ce module ne modifie pas mod-playerbots.** Il s'installe à côté, comme n'importe quel
module AzerothCore, et vos modifications locales de mod-playerbots restent intactes.

---

## Le principe

Le module **n'enlève rien** à mod-playerbots. Sa logique d'origine — comparer le score de
l'objet à celui de la pièce portée, équiper si le rapport dépasse `EquipUpgradeThreshold`
— reste le socle, à tous les niveaux. Le module pose une couche de reconnaissance BiS
par-dessus, et cette couche ne se déclenche que sur les objets que les tables connaissent.

Face à une arme ou une armure, un bot tranche en trois branches :

| Situation | Comportement |
|---|---|
| L'objet est **son** BiS | Il l'annonce à son maître — *« Couronne de vent du Néant - c'est mon BiS (Vanilla Phase 1 - Molten Core / Onyxia) »* — et roll dessus |
| L'objet est le BiS **d'une autre** classe/spé | Il passe, et le laisse à qui il revient |
| L'objet n'est le BiS de personne | Logique d'origine, inchangée |

La troisième branche est le cas courant : l'immense majorité du butin n'est dans aucune
liste, et les bots continuent de s'équiper exactement comme avant.

**Il n'y a pas de niveau minimum.** Un bot de niveau 30 reconnaît son BiS de niveau 60
aussi bien qu'un bot au cap — il ne le portera simplement que lorsqu'il en aura le niveau,
la vérification d'équipabilité étant faite avant tout verdict forcé. Une classe ou une spé
absente des tables garde intégralement la logique d'origine : le module ne bloque jamais un
bot qu'il ne sait pas habiller.

Chaque objet appartient à un **palier** (`tier_id`) qui donne l'ordre de progression :

```
Vanilla Pre-Raid  <  MC/Ony  <  BWL  <  ZG  <  AQ20  <  AQ40  <  Naxx40
                  <  TBC Pre-Raid  <  Karazhan  <  SSC/TK  <  Hyjal/BT  <  Sunwell
                  <  WotLK Pre-Raid  <  Naxx  <  Ulduar  <  ToC  <  ICC  <  Ruby Sanctum
```

Un palier supérieur l'emporte toujours, et `rank` ordonne les choix à l'intérieur d'un
même palier et d'un même emplacement.

## Ce que le module couvre — et ce qu'il ne couvre pas

| Décision | Gouvernée ? |
|---|---|
| Roll Need/Greed/Pass en groupe | Oui |
| Équipement d'un objet ramassé, échangé ou reçu en quête | Oui |
| Génération d'équipement au randomize d'un bot | **Non** — reste aux poids de stats |

La génération (`PlayerbotFactory::InitEquipment`) est un appel direct dans
mod-playerbots, pas un objet du registre : aucun module ne peut s'y substituer. En
pratique cela compte peu, car c'est la dérive au fil du loot qui éloigne les bots de
leur BiS, pas leur équipement initial.

## Comment ça marche

Le moteur de mod-playerbots résout ses valeurs **par nom**, et
`SharedNamedObjectContextList::Add()` *assigne* dans sa table de créateurs au lieu d'y
insérer. Le dernier contexte enregistré pour un nom l'emporte donc. Ce module enregistre
ses propres `"item usage"` et `"item upgrade"` au premier tick du monde — après
mod-playerbots, et avant la connexion du moindre bot.

Les deux valeurs délèguent d'abord à celles d'origine, puis ne restreignent le verdict
que pour les armes et armures. Tout le reste — quêtes, munitions, consommables, décisions
de vente, d'hôtel des ventes et de désenchantement — passe inchangé.

Un bot revendique son BiS **quel que soit son niveau**. Le cœur refuse d'équiper une
pièce niveau 60 à un personnage niveau 57 (`EQUIP_ERR_CANT_EQUIP_LEVEL_I`), mais c'est un
obstacle *temporaire* : le module le distingue de la classe, la race, la faction et la
maîtrise d'arme, qui eux disqualifient définitivement. Un bot trop jeune annonce donc la
pièce en précisant le niveau qui lui manque, la garde en sac, et l'équipera en
grandissant. `PlayerbotsBis.ClaimBelowRequiredLevel = 0` rétablit l'exigence de niveau.

### Un objet listé à plusieurs paliers

Une même pièce apparaît souvent dans plusieurs phases : `Dal'Rend's Sacred Charge` est
rang 1 en pré-raid, rang 3 à MC et rang 2 à BWL pour un guerrier Fureur. Les lignes sont
donc conservées côte à côte, et `GetItemPriority` retient **le palier le plus haut que le
bot peut atteindre**, le rang départageant une égalité.

C'est indispensable : ne garder que la ligne du palier le plus élevé rendait la pièce
invisible pour un bot plafonné plus bas. Un guerrier Fureur en pré-raid ne voyait plus du
tout ses Dal'Rend, pourtant rang 1 de sa propre liste, parce que seule la ligne du palier
30 survivait au chargement et se trouvait hors de sa portée.

### Une pièce hors liste ne déloge jamais une pièce de la liste

La branche 3 délègue à mod-playerbots, dont la règle est « 1,1 fois mieux selon le score
de stats » — et qui ignore tout de l'échelle. Sans garde-fou, un bleu de donjon délogeait
donc un BiS, que la branche 1 remettait au tick suivant : va-et-vient sans fin, et un
« c'est mon BiS » annoncé à chaque cycle.

La branche 3 vérifie donc l'emplacement de destination avant de valider un équipement.
Si la pièce portée y est sur la liste du bot, un objet qui n'y est pas se voit refusé.
`GetWornPriorityPaired` renvoyant le plus faible d'une paire, un deuxième anneau ou bijou
part toujours du côté libre ou hors liste : seul un emplacement déjà occupé par une pièce
listée est protégé.

Conséquence assumée : un objet meilleur en stats mais absent de la liste ne sera pas
équipé par-dessus une pièce listée, même de rang 3. La liste fait autorité.

### Réserver le NEED au BiS

Par défaut, mod-playerbots vote NEED sur toute pièce que son calcul juge meilleure d'un
facteur 1.1. En raid, quarante bots se disputent donc des objets dont aucun ne fera son
équipement final. `PlayerbotsBis.NeedOnlyForBis = 1` réserve le NEED au véritable BiS et
rétrograde le reste en GREED :

| Situation | Vote |
|---|---|
| La pièce est le BiS du bot, et une amélioration | NEED |
| Amélioration ordinaire selon la logique d'origine | GREED |
| L'objet ne lui sert à rien | PASS |

Le GREED reste soumis à `AiPlayerbot.LootGreedRollLevel` : à `0`, les bots passent au
lieu de greeder. Une spé sans liste atteignable garde ses NEED d'origine, sinon elle ne
pourrait plus s'équiper du tout.

L'implémentation ne recopie pas l'arbre de décision de mod-playerbots : elle vote GREED
elle-même sur les rolls à rétrograder, puis délègue à `LootRollAction::Execute()`, qui
ignore les rolls déjà votés.

Ce verdict est consulté par mod-playerbots à **neuf endroits** : le roll de butin, le
ramassage, le choix d'une récompense de quête, l'échange, l'achat, la vente, la
comparaison interne sac / équipé, et l'interrogation directe. Le module n'a donc pas
besoin de toucher à l'équipement lui-même — il suffit de répondre juste à la question
« cet objet me sert-il ? ».

### Le butin de maître

Une exception, et c'est un vrai trou dans mod-playerbots. En butin de maître, chaque bot
calcule son vote **puis le jette** :

```cpp
case MASTER_LOOT:
case FREE_FOR_ALL:
    group->CountRollVote(bot->GetGUID(), guid, PASS);
```

et `MasterLootRollAction::isUseful()` renvoie faux dès que le maître du butin est un vrai
joueur. Résultat : quand c'est vous qui distribuez, aucun bot n'exprime jamais rien.

`BisMasterLootAnnounce.cpp` comble ce trou. Il s'accroche au hook
`OnPlayerBeforeSendLoot` — qui se déclenche à l'ouverture du cadavre et fournit le butin
complet — et interroge chaque bot du groupe avec le **même** test
`BisPriorityMgr::WantsAsUpgrade()` que la couche d'item usage. Les intéressés chuchotent
au maître : « Je need cet objet : *nom* (*phase*) ».

Un seul chuchotement par bot, listant tout ce qu'il convoite sur ce cadavre : un raid de
quarante ne produit pas quarante lignes par boss. Le script ne s'enregistre que sur ce
hook précis, et non sur l'ensemble des événements joueur.

## Installation

> **Le nom du dossier est significatif.** AzerothCore dérive le point d'entrée du module de
> son nom de dossier : il doit être `modules/mod-playerbots-bis`. Cloné sous un autre nom, le
> module compile puis ne fait rien.

```bash
cd /chemin/vers/azerothcore/modules
git clone https://github.com/DayRob/Azeroth mod-playerbots-bis
cd ../build && cmake .. && make -j$(nproc) && make install
```

mod-playerbots doit être présent et activé.

Les tables s'importent **toutes seules** : le système de mises à jour d'AzerothCore scanne
`data/sql/db-world/` de chaque module au démarrage du worldserver et applique les fichiers
qu'il ne connaît pas encore, dans l'ordre alphabétique. Il suffit donc de démarrer le
serveur une fois. Si votre configuration désactive ce système
(`Updates.EnableDatabases = 0`), importez-les à la main, **dans cet ordre** —
`02` porte une clé étrangère vers `01` :

```bash
mysql -u acore -p acore_world < modules/mod-playerbots-bis/data/sql/db-world/base/01_playerbots_bis_tier.sql
mysql -u acore -p acore_world < modules/mod-playerbots-bis/data/sql/db-world/base/02_playerbots_bis_item.sql
mysql -u acore -p acore_world < modules/mod-playerbots-bis/data/sql/db-world/base/03_vanilla_preraid.sql
```

Copiez `conf/playerbots_bis.conf.dist` vers `etc/playerbots_bis.conf` (le build le dépose
à côté de `playerbots.conf.dist`) et mettez `PlayerbotsBis.Enable = 1`.

Au démarrage, le worldserver affiche une de ces trois lignes :

```
[mod-playerbots-bis] Active - BiS ladder governs bot gear and loot rolls (18 tiers, 6323 items)
[mod-playerbots-bis] Dormant (PlayerbotsBis.Enable = 0) - ...
[mod-playerbots-bis] Tables unavailable - bot itemisation left untouched
```

La troisième signifie que le SQL n'a pas été importé. Dans ce cas le module reste inerte
même avec `Enable = 1`, et un `.playerbotsbis reload` ne suffira pas : il faut importer les
tables puis redémarrer.

## Configuration essentielle

```ini
PlayerbotsBis.Enable = 1
PlayerbotsBis.MaxTier = 20            # cale les bots sur la phase de ton serveur
PlayerbotsBis.LeaveOtherSpecsBis = 1  # laisser à son propriétaire le BiS d'une autre spé
PlayerbotsBis.AnnounceOwnBis = 1      # annoncer son propre BiS avant de roller
PlayerbotsBis.NeedOnlyForBis = 0      # 1 = NEED reserve au BiS, GREED sur le reste
```

Le fichier `.conf.dist` documente chaque réglage et donne la table des `tier_id`.

### mod-individual-progression

`PlayerbotsBis.UseIndividualProgression = 1` limite chaque bot aux paliers que **son
propre personnage** a débloqués, via la colonne `required_progression` de
`playerbots_bis_tier`. Un bot qui n'a pas fini Molten Core ne convoitera pas le stuff de
Blackwing Lair.

Il n'y a aucune dépendance de compilation : l'état est lu via les quêtes cachées
`66000 + état` dans lesquelles mod-individual-progression stocke la progression. Laissez
le réglage à 0 si vous n'avez pas ce module.

### Un piège de configuration côté mod-playerbots

Avec `AiPlayerbot.LootNeedRollLevel = 1`, mod-playerbots convertit tout vote NEED en
GREED avant de l'émettre — les bots ne rollent alors jamais Need, y compris sur leur BiS.
Passez ce réglage à `2` pour que les bots réservent un vrai Need à leurs pièces de liste.

## Les tables

`playerbots_bis_tier` définit l'échelle, `playerbots_bis_item` les objets. Les en-têtes
des deux fichiers SQL documentent chaque colonne : numéros de spé par classe, énumération
des emplacements, sentinelle 10 du druide ours, lignes de faction.

Les lignes fournies sont converties depuis la table `playerbots_bis_gear` de
mod-playerbots — identifiants et noms d'objets d'origine — réparties sur l'échelle de
paliers. `tools/convert_playerbots_bis_gear.py` permet de régénérer le fichier.

Le palier 10 (Vanilla Pre-Raid) est fourni à part, en deux fichiers.
`03_vanilla_preraid.sql` vient des guides Best-in-Slot de Wowhead Classic, avec leurs
rangs Best / Optional. `04_vanilla_preraid_wowsims.sql` reprend les sets pré-raid du
simulateur [**WoWSims Classic**](https://github.com/wowsims/classic) (licence MIT) : un
seul choix par emplacement, donc tout en rank 1. Ce fichier ne code aucun identifiant en dur : il résout chaque
objet **par nom** contre `item_template` au moment de l'import. Un nom erroné n'insère
rien plutôt que de faire équiper n'importe quoi, et la requête de vérification en fin de
fichier liste les noms non résolus. C'est le format à suivre pour contribuer une liste.

**Ce jeu de données est un point de départ, pas une liste BiS de référence.** Lacunes
connues :

- Paliers vides : Zul'Gurub (40), AQ20 (50), WotLK Pre-Raid (130), Ruby Sanctum (180).
- Palier 20 (MC / Onyxia) : le guerrier Armes et le guerrier Fureur viennent d'un guide
  Wowhead (fichier `05`) ; les 22 autres spés viennent encore de la conversion du fichier
  `02`, dont les rangs ne proviennent d'aucun guide. Voleur Assassinat, Voleur Subtilité
  et Prêtre Discipline n'y ont toujours aucune ligne.
- Paliers partiels : les trois derniers paliers TBC (100, 110, 120) ne couvrent que 15 à
  16 combinaisons classe/spé, contre 23 à 24 pour les paliers TBC précédents.
- Palier 10 (Vanilla Pre-Raid) : **complet**, 28 combinaisons sur 28, 1238 lignes.
- Palier 10 : **1536 lignes**, les 28 spés couvrant tous leurs emplacements, à une
  exception près — le Paladin Protection n'a pas de libram, son guide n'en proposant
  aucun pour le tank.
- Listes sans alternative au palier 10 : les listes issues de wowsims (Mage ×3,
  Démoniste ×3, Prêtre Ombre) comptent 17 lignes, soit un objet par emplacement et aucun
  repli si le bot ne l'obtient pas.

Une spé sans aucune ligne atteignable ne se retrouve pas pénalisée : `HasReachableList`
la fait sortir de la branche 2, donc elle ne cède le BiS de personne et garde intégralement
la logique d'origine. Attention en revanche aux listes **minces** : il suffit d'une seule
ligne atteignable pour que la spé soit considérée comme ayant une liste, et elle cédera
alors le BiS des autres y compris sur les emplacements où elle ne revendique rien.

Après édition des tables **ou du fichier de configuration**, `.playerbotsbis reload`
recharge les deux sans redémarrer, et annonce le palier maximum obtenu — de quoi
vérifier d'un coup d'œil que le serveur a bien lu le fichier que tu viens d'éditer. La même
commande prend aussi en compte un changement de `PlayerbotsBis.Enable` ou de
`PlayerbotsBis.MaxTier` : le module s'enregistre auprès du moteur dès le premier tick du
monde, même désactivé, précisément pour pouvoir être basculé à chaud.

## Épaisseur des listes selon la source

Les listes ne viennent pas toutes du même endroit, et ça se voit dans la fenêtre d'état :
un créneau qui n'a qu'un seul objet ne propose rien à déplier.

| Fichier | Source | Rangs |
|---|---|---|
| `03`, `05` | guides Wowhead écrits à la main | jusqu'à 5 par créneau |
| `04` | export WoWSims | **un seul** — le format n'a pas de colonne `rank` |
| `06` | guide Wowhead Démoniste | jusqu'à 11 par créneau |
| `07` | guide Wowhead Guerrier Protection | jusqu'à 21 par créneau |
| `08` | guide Wowhead Voleur | jusqu'à 4 par créneau |
| `09` | guide Wowhead Mage | jusqu'à 8 par créneau |
| `10` | guide Wowhead Prêtre Ombre | jusqu'à 8 par créneau |

Les onze combinaisons servies par `04` — guerrier Protection, voleur Combat, prêtre Ombre,
les trois mages, les trois démonistes, druide Équilibre et Farouche — n'ont qu'une pièce par
créneau tant qu'un fichier ne les enrichit pas. `06` traite le démoniste, `07` le guerrier
Protection, `08` le voleur Combat, `09` les trois mages, `10` le prêtre Ombre ; il reste le
druide Équilibre et le druide Farouche.

`08` ne touche qu'à la spé Combat : `03` donne déjà des listes à plusieurs rangs au voleur
Assassinat et Finesse, seule Combat était écrasée par `04`.

### Ni PvP ni réputation

Les listes ne contiennent **aucun objet derrière un rang d'honneur ou une réputation**.
Ce n'est pas un choix de goût, c'est ce que le code permet : dans mod-playerbots,
`GetHonorPoints()` n'est lu qu'à un seul endroit, `TellPvpStatsAction`, qui se contente de
réciter le solde. Rien ne dépense l'honneur, et rien ne pousse un bot vers exalté. Les bots
entrent bien en champ de bataille — `BattleGroundJoinAction` existe — mais le butin ne suit
jamais.

Un objet inatteignable en rang 1 fige le créneau en rouge pour toujours ; en rang 2 il
encombre le dépliage d'options fantômes. Il n'a donc pas sa place du tout.

Sont concernés : les sets PvP de rang (Champion's, Lieutenant Commander's, Blood Guard's,
Knight-Captain's, Legionnaire's, Knight-Lieutenant's), les récompenses de réputation
d'Alterac, du bassin d'Arathi et du Goulet des Chanteguerres, et les quêtes de champ de
bataille.

Ce que les bots **peuvent** obtenir reste en revanche listé : drops de donjon, récompenses
de quête ordinaires, et objets d'artisanat — ceux-là tu peux les fabriquer pour eux.

### Ce qui est classé rang 1

Le rang 1 doit rester **atteignable par un bot**. Un objet verrouillé derrière une
réputation exaltée, un rang PvP ou la chaîne T0.5 est donc classé 2, même quand le guide le
donne comme meilleur en absolu : un bot ne fera jamais Alterac Valley jusqu'à exalté, et le
laisser en rang 1 rendrait son créneau éternellement incomplet dans la fenêtre d'état.

Quand un guide fournit une liste « objectif réaliste avant le premier raid », c'est elle qui
sert de rang 1.

Autre aplatissement : certains guides trient les armes **par race** (spécialisation d'arme
de l'Humain ou de l'Orc). La table n'a pas de dimension race — seulement classe / spé /
faction — donc les armes sont rangées ensemble par priorité, et le module choisit selon ce
que le bot peut porter.

Ce n'est pas qu'un confort d'affichage : avec une seule ligne par créneau, un bot ne
reconnaît qu'un objet comme étant sa BiS et ignore tout le reste.

**Ordre d'import** : `06` doit passer après `04`, sinon `04` écrase ses lignes.

## Les pièces réservées à une classe

mod-playerbots ne revendique que ce que son calcul de stats juge **1,1 fois
meilleur** que la pièce portée. Ce calcul est grossier, et la conséquence est
visible en raid : un mage passe sur un objet marqué « Classes : Mage » tout en
gardant un vert de quête au même créneau. Comme personne d'autre ne peut le
porter, la pièce est perdue.

`PlayerbotsBis.ClaimClassRestricted` corrige ce cas précis. Quand l'objet n'est
sur **aucune** liste mais que son infobulle nomme la classe du bot **et aucune
autre**, le bot le revendique — à deux conditions.

**La lecture est stricte.** `Classes : Mage` compte ; `Classes : Prêtre, Chaman,
Mage, Démoniste, Druide` non. Accepter tout objet simplement autorisé à la classe
couvrirait presque tout le tissu, et quarante bots feraient NEED sur tout — la
ruée que `NeedOnlyForBis` existe justement pour éviter.

**Un créneau réglé n'est jamais dérangé.** Si le bot y porte déjà une pièce que
les listes nomment, rien ne se passe : la couverture BiS ne peut pas reculer.

Et la comparaison se fait au **niveau d'objet**, pas au score de stats. C'est une
mesure fruste, mais elle ne peut ni prendre une régression pour une amélioration,
ni se laisser tromper par des poids calés sur une autre spécialisation.

Le bot le dit, sous `AnnounceOwnBis` :

```
[Trinor] chuchote : [Épaulières de l'arcaniste] - je le prends : réservé à ma
classe, et je n'ai pas encore mon BiS à cet emplacement
```

Ces revendications-là n'ont **aucune liste derrière elles**. Sans un mot, un bot
qui fait NEED sur un objet absent de toutes les tables ressemble à un bug plutôt
qu'à la règle qu'il applique.

## Mettre la pièce, pas seulement la gagner

Remplacer les valeurs `item usage` et `item upgrade` décide de ce qu'un bot
**roule**. Pas de ce qu'il **porte**. Pour les armes, `EquipAction` tranche
lui-même :

```cpp
bool canDualWieldOrTG = (canDualWield || isTwoHander);

if (isWeapon && canDualWieldOrTG)
{
    StatsWeightCalculator calculator(bot);
    ...
    else { /* No improvement, do nothing */ return; }
}
```

Être à deux mains suffit à entrer dans cette branche, et à partir de là **seul
le score de stats de playerbots a voix au chapitre** — il pèse une arme à deux
mains contre la somme des deux mains, et l'échelle n'est jamais consultée.

Le symptôme est spectaculaire : un chaman annonce une hache à deux mains comme
son BiS, roule dessus, la gagne — et la laisse dans ses sacs indéfiniment.

`BisEquipUpgradesAction` remplace `equip upgrades packet action`, qui vit dans
le **même** `WorldPacketActionContext` que `loot roll` : l'override déjà en
place pour le vote atteint donc aussi l'équipement. Elle lance l'originale sans
la modifier, puis fait une passe à elle sur les sacs pour les pièces que
l'échelle réclame et que l'originale a laissées de côté.

Contrairement à la revendication au moment du butin, **un niveau manquant
disqualifie ici** : le cœur refuse l'équipement, donc forcer ne ferait que
dépenser un paquet par tick jusqu'à ce que le bot grandisse.

## Savoir ce qui manque à chaque bot

La spé n'est stockée nulle part : `AiFactory` la recalcule depuis les talents à chaque
fois. Rien en dehors du serveur ne peut donc rattacher un bot à sa liste — ni une requête
SQL, ni un addon. Le module calcule la réponse et la **diffuse au client**.

En jeu :

```
.playerbotsbis report
```

Analyse les bots **de ta guilde** actuellement connectés, résume dans le chat, et ouvre la
fenêtre de l'addon compagnon. `report all` couvre tous les bots au lieu de la seule
guilde. Un bot doit être **connecté** : la réponse vient de son équipement et de ses sacs
en mémoire, il n'y a pas d'autre source.

Rien n'est écrit en base. Le rapport est calculé et envoyé, point.

### La fenêtre

`/pbbis roster` rouvre le dernier relevé. Les bots sont classés **du moins équipé au
mieux équipé**, avec une barre de couverture aux couleurs de classe :

```
- Cruvmarl   Guerrier Fureur niv 60                      1/4
      Faucheuse de Felstriker      manquant       Molten Core
      Anneau de sang               dans ses sacs  Vanilla Pre-Raid
+ Betu       Pretre Sacre niv 58                        15/16
```

Un **bouton de minicarte** l'ouvre (clic gauche) et relance le relevé (clic droit).
Clic sur un bot pour déplier, **Maj+clic** sur un objet pour le lier dans le chat,
**Ctrl+clic** pour l'essayer.

Déplié, un bot est présenté **créneau par créneau**. Fermé, un créneau ne montre que sa
cible — la pièce que la liste retient — et signale à droite le rang que le bot porte à la
place, s'il y en a un :

```
- Cruvmarl   Guerrier Fureur niv 60                      1/17
   Doigt 1
      rang 1  Anneau de sang            dans ses sacs   Vanilla Pre-Raid
 + Main droite                                     rang 2 porte
      rang 1  Faucheuse de Felstriker   manquant        Molten Core
```

**Clic sur un créneau** pour l'ouvrir et voir tous ses rangs :

```
 - Main droite                                     rang 2 porte
      rang 1  Faucheuse de Felstriker   manquant        Molten Core
      rang 2  Main de Justice           equipe          Vanilla Pre-Raid
      rang 3  Hachoir de Gorosh         manquant        Molten Core
```

Le bouton en haut bascule entre *manquants seulement* et *tout afficher*, qui ajoute les
créneaux déjà réglés.

### Ce que compte le ratio

Le dénominateur est le **nombre de créneaux d'équipement** que la liste couvre, pas le
nombre de lignes. Pour chaque créneau on retient **une seule cible** : la pièce du palier le
plus haut que le bot peut atteindre, rang 1 à l'intérieur de ce palier. `12/17` se lit donc
« douze créneaux sur dix-sept portent la bonne pièce ».

Compter toutes les lignes de rang 1 comptait le même créneau une fois par palier — une tête
listée en pré-raid **et** à Molten Core en valait deux — si bien que le dénominateur
grossissait avec le nombre de phases ouvertes et que 100 % devenait inatteignable par
construction. Un guerrier affichait ainsi 35 « pièces » pour dix-sept créneaux.

### Le détail dans le chat

```
.playerbotsbis missing <nom>
```

Même chose pour un seul bot, directement dans le chat, avec les liens d'objets cliquables.

### Quel raid faire

```
/pbbis raids          (aussi /pbbisraids)
```

La fenêtre d'état répond à « ce bot, que lui manque-t-il ». Choisir le raid de la soirée
demande l'inverse : **« ce raid, à qui sert-il, et pour quoi »**. Cette vue regroupe les mêmes
pièces par palier au lieu de les regrouper par bot.

Elle ne demande rien de plus au serveur : le flux de `.playerbotsbis report` porte déjà le
palier de chaque ligne, et cette fenêtre relit ce même relevé. Lance le rapport, ouvre la
fenêtre.

Chaque palier annonce le nombre de pièces encore manquantes et le nombre de bots concernés.
Dépliez-le et les pièces arrivent **triées par nombre de bots en attente** — celle que six bots
convoitent avant celle qu'un seul attend. Le survol d'une pièce donne son infobulle, le survol
de la colonne de droite la liste complète des bots, et un Maj-clic insère le lien dans le chat.

Trois exclusions font tout l'intérêt du classement :

- une pièce **déjà portée** ne justifie pas un raid ;
- une pièce **dans les sacs** non plus — elle demande `.playerbotsbis equipe`, pas une soirée ;
- un **repli** non plus : si la cible d'un créneau est à Blackwing Lair, la pièce de Molten Core
  pour ce même créneau n'est plus l'objectif.

C'est cette dernière règle qui rend le nombre lisible. Chaque créneau de chaque bot compte pour
**un seul** raid, celui qui porte sa meilleure pièce atteignable — donc le chiffre en face d'un
palier est bien le nombre de pièces que cette soirée-là ferait gagner, sans double compte.

La granularité est le **palier**, pas l'instance. Molten Core et Onyxia partagent le palier 20 et
apparaissent donc ensemble ; tous les autres raids Vanilla ont leur palier propre.

### Faire équiper ce qui dort dans les sacs

```
.playerbotsbis equipe             (les bots de ta guilde)
.playerbotsbis equipe all         (tous les bots suivis par le module)
.playerbotsbis equipe <nom>       (un seul bot, avec le detail des refus)
```

L'équipement automatique est une **action de paquet** : elle se déclenche quand un objet
arrive. C'est le bon moment en jeu normal, et le mauvais pour tout ce qui atterrit en dehors —
une récompense de quête rendue par quarante bots d'un coup, une pièce ramassée pendant que le
module était éteint, ou une liste qui change sous un bot qui n'a rien reçu depuis. Dans tous
ces cas la pièce reste dans les sacs, correcte et non portée, sans rien de prévu pour la
regarder à nouveau.

Cette commande passe en revue les sacs de chaque bot et lui fait enfiler tout ce que sa liste
classe au-dessus de ce qu'il porte.

Avec un **nom de bot** à la place de la portée, elle devient bavarde : elle annonce d'abord la
classe, la spé et le **palier plafond** du bot, puis une ligne par pièce d'équipement portée
dans les sacs, avec la raison du refus. C'est ce qu'il faut quand la version muette répond
« 0 ont équipé » : quatre tests peuvent refuser, et ce chiffre ne dit pas lequel.

```
Hurnest - Voleur Combat - palier plafond 30 (Vanilla P2 BWL)
  [Bague du Maître-tueur de dragon] : EQUIPE au creneau 10 (Vanilla P2 BWL)
  [Ceinture en cuir épais] : aucune ligne a son palier
```

Le succès est lu **dans le créneau**, pas déduit de l'envoi du paquet : le cœur refuse en
silence quand les sacs sont pleins, et compter l'envoi ferait état d'un travail qui n'a pas eu
lieu.

### Le transport

Le relevé voyage en **messages système** portant le marqueur `PBBISREP;` : un en-tête, une
ligne par bot, ses pièces par paquets de 200 octets, puis un marqueur de fin sur lequel la
fenêtre s'ouvre. L'addon les intercepte avec un filtre `CHAT_MSG_SYSTEM` et les masque ;
sans l'addon ils sont simplement visibles, jamais fatals. Le flux est plafonné à 150 bots.

Ce n'est pas un `CHAT_MSG_ADDON`, et c'est délibéré : un paquet addon construit côté serveur
**tuait le client 3.3.5** (ERROR #134), alors que les lignes de résumé imprimées par la même
commande arrivaient sans problème. Le flux emprunte donc le chemin déjà prouvé.

Les champs sont séparés par `;`, **jamais par `|`** : le client analyse les séquences
d'échappement avant qu'un addon ne voie le texte, et `B|Cruvmarl` se lit comme un début de
code couleur `|c......`. C'est pour cette raison que `ChatHandler` double les `|` en `||`
dans les messages système.

Un filtre s'exécute une fois **par cadre de tchat**, donc la même ligne arrive une fois par
cadre affichant les messages système. Ces copies se suivent immédiatement — la chaîne de
filtres d'un message se termine avant que le suivant soit traité — donc comparer à la ligne
précédente suffit. Un ensemble de *tout* ce qui a été vu, lui, avalerait un second relevé
dont l'en-tête serait identique au premier.

## Libérer les verrous d'instance des bots

```
.playerbotsbis libere              (les bots de ton groupe ou de ton raid)
.playerbotsbis libere guilde       (tous les bots de ta guilde, avant de grouper)
.playerbotsbis libere moi          (toi compris — plus aucun verrou nulle part)
.playerbotsbis libere guilde 409   (une seule carte : 409 = Cœur du Magma)
```

Le cœur choisit la copie d'un téléport dans cet ordre
(`InstanceSaveMgr::PlayerGetDestinationInstanceId`) :

```cpp
if (ipb && ipb->perm) return ipb->save->GetInstanceId();  // 1. verrou PERMANENT du bot
if (Group* g = player->GetGroup())
{
    if (verrou du chef) return celui-la;                   // 2. le verrou du CHEF
    return 0;                                              // 3. une copie neuve
}
```

Un bot qui a tué un boss quelque part porte un verrou **permanent**, et l'étape 1
l'y renvoie quoi que fasse son groupe. C'est tout le bug : le raid est sur la même
carte, aux mêmes coordonnées, dans deux copies parallèles — visible sur la
minicarte, introuvable à l'écran.

`.instance unbind` ne peut pas le régler en masse : elle s'applique à **une**
cible sélectionnée. Et supprimer les lignes de `character_instance` ne change
rien tant que le serveur n'a pas redémarré, puisqu'il garde ses verrous en
mémoire. Cette commande passe par ce gestionnaire, donc l'effet est immédiat.

La commande atteint **tous** les bots de la portée, y compris ceux que l'échelle
BiS ne gouverne pas — un bot `addclass`, un alt, un que le gestionnaire aléatoire
a laissé tomber. Que le module choisisse ou non son équipement ne dit rien de
l'endroit où le cœur l'envoie en le téléportant, et un bot non libéré casse le
raid tout autant. Seul un vrai joueur est épargné.

**Ton propre verrou n'est jamais touché** sans le mot `moi` : c'est la
progression de ton raid, et l'effacer en plein clear remet le premier boss
debout.

Un bot qui se trouve **dans** l'instance ne peut pas être libéré — le cœur s'y
refuse, et la commande le compte à part pour que tu le saches plutôt que de
rapporter « 0 verrou ». Sors-le d'abord (`.summon <nom>` depuis l'extérieur).

## Licence et crédits

GNU GPL v2, comme AzerothCore et mod-playerbots.

Les listes des fichiers `04`, `18` et `19` proviennent de
[**WoWSims Classic**](https://github.com/wowsims/classic), sous licence MIT. Le projet
demande un lien visible vers l'original dans tout travail qui réutilise ses données —
le voici, et il figure aussi en tête du fichier SQL concerné.
