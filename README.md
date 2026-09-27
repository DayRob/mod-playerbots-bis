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

Après édition des tables, `.playerbotsbis reload` les recharge sans redémarrer. La même
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

## Savoir quel donjon faire, et avec qui

Le relevé dit ce qui manque à chaque bot. Celui-ci dit **où aller le chercher**, et **avec
lesquels y aller**.

```
.playerbotsbis donjons
```

`donjons all` couvre tous les bots au lieu de la seule guilde. Comme pour le relevé, les
bots doivent être connectés.

Rien n'est stocké : le module croise à la demande les pièces manquantes de chaque bot avec
un index objet → instance construit une fois et gardé en mémoire. `.playerbotsbis reload`
le jette, donc une table de butin modifiée est reprise sans redémarrage.

### D'où vient l'information

Le tooltip du client 3.3.5 **n'a jamais porté de source** : ni le boss, ni le donjon. C'est
Wowhead qui reconstitue cela depuis sa propre base. La base monde, elle, sait tout, et
c'est elle qu'on interroge — butin de créature, butin par table de référence, objets du
décor — en remontant à la carte où la créature apparaît.

Le filtre qui rend le résultat lisible est une simple jointure sur `instance_template` :
cette table ne contient que les cartes instanciées, donc **un objet qui ne tombe qu'en
monde ouvert disparaît de lui-même**, sans liste d'exclusion à maintenir.

Trois choses restent hors de portée, et c'est assumé :

- **Les récompenses de quête.** Une quête ne sait pas à quel donjon elle appartient. Un
  `Œil de la bête` ne sera donc pas rattaché au Pic Rochenoire.
- **L'artisanat et les vendeurs.** Pareil, et de toute façon ce n'est pas un run.
- **Le nom des cartes.** Il vit dans les DBC du client. Le module lit d'abord
  `playerbots_bis_map_name` (fichier `14`, optionnel, en français), sinon
  `areatrigger_teleport` (anglais), sinon affiche `carte <id>`.

La commande te dit combien de cibles sont ainsi restées hors plan.

### La fenêtre

`/pbisplan`, le bouton **Plan de donjons** de la fenêtre du relevé, ou **Maj+clic** sur le
bouton de minicarte (gauche : ouvrir, droite : recalculer).

```
- Stratholme                              3 cible(s) / 5 piece(s) / 2 bot(s)
   + Ahlo       Demoniste Affliction niv 59   dps              2 cible(s) / 3
        > Coiffe du savant ecarlate                Balnazzar        2.0%
          Burst of Knowledge              Ambassador Flamelash      4.0%
   + Kweopewu   Druide Restauration niv 57    soigneur         1 cible(s) / 2
     Grim       Guerrier Protection niv 60    tank             renfort
```

Clic sur une instance pour la replier, sur un bot pour voir ses pièces. Le `>` marque une
**cible** — la pièce que sa liste retient pour ce créneau — par opposition à un repli.

Le taux à droite est le **meilleur taux de drop** de la pièce dans cette instance. Il est
rouge sous 3 %, jaune jusqu'à 10 %, vert au-delà : une cible à 0,9 % n'est pas une raison
d'y aller, et ça doit se voir sans ouvrir une base de données.

Un **`?`** à la place du taux n'est pas une erreur. AzerothCore écrit `0` dans la colonne
`Chance` quand la ligne appartient à un **groupe de butin** et tient ses chances du groupe
plutôt que d'elle-même. Afficher « 0,0 % » en rouge serait un mensonge ; le point
d'interrogation dit ce qu'on sait.

### Une instance sans cible n'est pas un plan

Les instances où **toutes** les pièces sont des replis sont écartées, et le résumé dit
combien. Sans ce filtre, Naxxramas remonte en tête pour des bots niveau 60 : sa piétaille
hérite de tables de butin monde, donc quelques rangs 3 s'y trouvent, et un classement au
nombre de pièces place le raid entier au-dessus du donjon qui contient réellement la BiS de
quelqu'un.

Quand il ne reste rien, la commande le dit, et **nomme quelques cibles introuvables** —
une liste de récompenses de vendeur se lit très différemment d'une liste de drops de donjon
qui auraient dû être trouvés. Dans ce second cas, `tools/diagnostic_plan_donjons.sql`
rejoue l'index en SQL pur et désigne le maillon qui casse.

### Comment le groupe est choisi

Les instances sont classées par **nombre de cibles**, pas de pièces : un bot à qui il manque
trois replis du même créneau ne vaut pas un bot à qui il manquent trois cibles.

Le groupe proposé compte **quatre bots** — tu es le cinquième. La cupidité pure enverrait
volontiers quatre tissus à Stratholme, donc **une place est réservée au tank et une au
soigneur** avant que le reste n'aille aux plus demandeurs.

Quand aucun des bots concernés ne tient l'un de ces deux rôles, un **renfort** est tiré du
reste de la liste : il n'y gagne rien, il est là pour que le run ait lieu. Il **prend** une
place au lieu d'en ajouter une, et il doit être à moins de cinq niveaux de la moyenne du
groupe — sans quoi il est laissé de côté plutôt que traîné hors de sa zone.

Le bouton en haut bascule entre *groupe conseillé* et *tous les bots concernés*.

### Le transport

Même chemin que le relevé — messages système marqués, ici `PBBISPLN;` — pour les mêmes
raisons. Le nom de la source voyage **dans** le champ d'une pièce, à côté de l'identifiant
et du taux, donc les virgules et les deux-points en sont retirés en plus des `;`.

## Licence et crédits

GNU GPL v2, comme AzerothCore et mod-playerbots.

Les listes pré-raid du fichier `04` proviennent de
[**WoWSims Classic**](https://github.com/wowsims/classic), sous licence MIT. Le projet
demande un lien visible vers l'original dans tout travail qui réutilise ses données —
le voici, et il figure aussi en tête du fichier SQL concerné.
