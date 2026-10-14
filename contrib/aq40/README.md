# Strategie AQ40 — Empereurs Jumeaux

mod-playerbots n'a pas de dossier `Aq40`. La carte 531 (Temple d'Ahn'Qiraj)
n'est rattachee a aucune strategie : les bots s'y deplacent et y combattent
avec leur IA generique, sans rien savoir de l'encontre. Les Jumeaux sont le
premier boss que ca rend infaisable, parce qu'ils sont immunises a moitie
chacun.

Ces dix fichiers sont du code mod-playerbots, pas du code mod-playerbots-bis.
Ils vivent ici pour une raison : un `git pull` dans `mod-playerbots` ecrase
son arborescence. Ici ils sont versionnes, et `tools\installer_aq40_twins.ps1`
les recopie au bon endroit — a relancer apres chaque mise a jour de
mod-playerbots.

## Ce que la strategie fait

Tout vient du script du coeur,
`src/server/scripts/Kalimdor/TempleOfAhnQiraj/boss_twinemperors.cpp`, pas
d'un guide. Les trois chiffres qui comptent en sortent.

**0. Un tank par piedestal, et ils priment sur tout le reste.** Chaque
Empereur apparait sur son socle, aux deux bouts de la salle — mesure sur une
base reelle : **158,2 yards** entre les deux. Les y GARDER vaut mieux que les
separer une fois qu'ils se sont rejoints.

Les bots tanks du groupe sont ranges par GUID — un ordre qui ne change jamais,
et c'est tout ce qu'on lui demande : un choix « malin » qui changerait d'avis
d'un tick a l'autre ferait osciller deux tanks entre les deux bouts de la
salle. Le rang donne le poste :

| Rang | Poste |
|---|---|
| 0 | le piedestal de Vek'nilash |
| 1 | le piedestal de Vek'lor |
| 2 | les bestioles du milieu |
| au-dela | rien de particulier, ils se battent comme les autres |

Un humain compte comme tank mais n'est jamais range : rien ici ne le ferait
bouger. Si c'est toi qui tiens un cote, le bot de rang 0 doublera ton poste.

### Les deux postes, et ou les mettre

Ce ne sont **pas** les points d'apparition. Les deux Empereurs poussent sur les
plateformes du fond, aux deux coins hauts de la salle; le raid les tire contre
les murs gauche et droit, a mi-hauteur — c'est la qu'on les tient.

Les deux postes sont deux constantes de `Aq40Utils.h` :

```cpp
constexpr Aq40TankPost TANK_POST_A = { 0.0f, 0.0f, 0.0f };
constexpr Aq40TankPost TANK_POST_B = { 0.0f, 0.0f, 0.0f };
```

Pour les remplir : se placer a chaque endroit en jeu, faire `.gps`, et coller
les deux relevés. **L'ordre n'a pas d'importance** — le code donne a chaque rang
le poste le plus proche de la plateforme qui lui revient, donc chaque tank garde
son cote du debut a la fin.

**A zero, on se rabat sur `GetHomePosition()`**, donc sur les plateformes
d'apparition. Le script du coeur n'y touche jamais — aucun `SetHomePosition`
dans `boss_twinemperors.cpp` — donc elles restent justes apres trois
teleportations, et 158,2 yards les separent : Heal Brother ne part pas. Mais ce
n'est pas le placement de la guilde.

**Ce que le tank peut et ne peut pas tirer.** Vek'nilash suit son attaquant au
contact : son tank le ramene ou il veut. Vek'lor, lui, garde 45 yards de sa
cible et ne bouge que si elle s'en eloigne — sa position est donc decidee par
qui tient sa menace, c'est-a-dire les lanceurs de sorts, pas par un tank. Le
mettre a un endroit precis veut dire placer les lanceurs de sorts a 45 yards de
cet endroit, du cote du milieu.

**Le partage des jumeaux se fait en une seule comparaison**, et les deux tanks
font la meme : l'Empereur le plus proche du socle du rang 0 lui revient, l'autre
va au rang 1. Donner a chacun « le jumeau le plus proche de MON socle » aurait
donne le meme aux deux le jour ou les deux se retrouvent sur le meme piedestal
— c'est-a-dire exactement le jour ou cette regle doit servir.

Les deux postes ne font pas le meme travail :

- **Cote Vek'nilash**, le tank le prend pour cible, le provoque des qu'il
  regarde ailleurs, va le chercher s'il est a plus de 25 yards, et **rentre sur
  son socle** — Vek'nilash suit son attaquant au contact, donc il revient chez
  lui.
- **Cote Vek'lor**, le tank ne le touche pas. Vek'lor est immunise a tout ce
  qu'un tank frappe, et le provoquer ne ferait que le promener : il suit sa
  cible jusqu'a 45 yards, donc l'aggro d'un tank qui recule le ferait avancer.
  Son travail, c'est d'**etre la quand ca bascule**. Il se tient a **10 yards**
  — deux de plus que la portee de contact qu'Arcane Burst (568) cherche avant
  de repousser, et bien moins que les 25 ou se tiennent les lanceurs de sorts.
  Apres la teleportation, le joueur le plus proche recoit 2000 de menace : c'est
  lui.

Un tank qui attend trente secondes sans rien faire, c'est le prix de l'echange,
et c'est ce que fait un vrai raid. Il rend quand meme la main a son IA de classe
si une bestiole lui tombe dessus.

**0 bis. Le troisieme tank prend les bestioles.** Vek'lor lance Explode Bug
(804) toutes les **4,5 a 10 secondes** et Vek'nilash Mutate Bug (802) toutes les
**10 a 20** : chaque incantation retourne UNE bestiole de la salle — le script
du sort fait `RandomResize(targets, 1)` — qui passe hostile et entre en combat
avec la zone entiere.

Sans menace sur personne, elle part vers qui lui en donne, et c'est le
**soigneur** : chaque sort de soin fabrique de la menace sur tout ce qui est en
combat avec lui. D'ou la provocation en premier geste — attendre d'en produire
par les degats laisse le soigneur se faire mordre plusieurs secondes de plus.

L'ordre d'urgence : la bestiole qui mange un soigneur, puis celle qui mange
quelqu'un d'autre, puis la sienne ou celle qui n'a encore personne.

**C'est un poste, pas une reaction.** Entre deux bestioles, il tient le MILIEU
des deux socles — la ou elles se reveillent, et ou se tiennent les soigneurs.
Le laisser repartir sur Vek'nilash entre-temps le mettait a quatre-vingts yards
de la suivante : le temps qu'il revienne, le soigneur avait deja ete mordu.

Le milieu se calcule sur les deux SOCLES, pas sur les deux Empereurs : les
socles ne bougent jamais, alors qu'un milieu calcule sur les boss ferait marcher
le tank a chaque tick.

**1. Chacun tape le jumeau qu'il peut blesser.** Vek'lor (15276) est immunise
au physique, Vek'nilash (15275) au magique sauf au sacre. Les degats sont
partages entre les deux et ils meurent ensemble, donc la moitie du raid qui
se trompe de cible ne contribue a rien du tout. La strategie range chaque bot
d'un cote :

| Bot | Jumeau |
|---|---|
| mage, demoniste, pretre ombre, druide equilibre, chaman elementaire | Vek'lor |
| guerrier (tank compris), voleur, chasseur, druide farouche, chaman amelioration | Vek'nilash |
| soigneurs | aucun — ils suivent et soignent, on ne touche a rien |

Le chasseur va sur Vek'nilash malgre sa distance : ses tirs sont physiques.

**2. Personne ne reste colle au jumeau qu'il ne peut pas blesser.** Les
physiques s'ecartent a 15 yards de Vek'lor — y rester ne rapporte rien et
declenche Arcane Burst (568), qui les repousse. Les casters s'ecartent a
25 yards de Vek'nilash, qui frappe au contact et qui, apres chaque
teleportation, agresse la cible la plus proche avec 2000 de menace offerte.

**3. Personne ne se tient ENTRE les deux Empereurs.** C'est la moitie
preventive de la separation, et c'est la regle qui compte le plus : un raid
place entre les deux les fait converger sans que personne fasse de faute,
parce que chaque boss marche vers celui qui le tient. Un bot est du mauvais
cote des qu'il est plus pres du jumeau interdit que son propre jumeau ne
l'est ; il traverse alors derriere le sien — au contact pour un physique,
a 25 yards pour un lanceur de sorts, donc sans perdre une seconde de degats.

Twin Teleport echange les positions toutes les 30 a 40 secondes : les deux
groupes se retrouvent du mauvais cote d'un seul coup. Cette regle les renvoie
au tick suivant, sans attendre que la separation soit perdue. C'est
l'equivalent automatique de ce qu'un raid humain fait en se replacant avant
l'echange, avec un WeakAura pour l'annoncer.

**4. Les physiques eloignent Vek'nilash de son frere.** Heal Brother (7393)
part toutes les 3,6 secondes, mais seulement si les deux jumeaux sont a moins
de **60 yards** l'un de l'autre. C'est la seule chose qui fait perdre le
combat.

Mesure sur une base reelle : les deux spawns sont a **158,2 yards** l'un de
l'autre. Mais ca ne dure pas : au pull, les DEUX se dirigent vers le raid, et
s'il est groupe ils arrivent colles. C'est donc bien cette regle qui fait tout
le travail, des la premiere seconde.

Et elle doit alors commander seule. Premier essai en jeu : repartition
parfaite, jumeaux colles. La cause etait dans l'ordre des priorites — Vek'lor
arrivant a moins de 15 yards des melee, « s'ecarter du jumeau interdit »
(ACTION_RAID + 2) battait « ecarter Vek'nilash » (+ 1) a chaque tick, et
l'ecartement n'a jamais tourne. Un melee s'ecarte desormais au jugé seulement
quand les Empereurs sont DEJA assez loin l'un de l'autre ; en dessous, c'est
l'ecartement qui le place — et son point de destination est de l'autre cote de
Vek'nilash par rapport a Vek'lor, donc s'y rendre eloigne du jumeau interdit
de toute facon. Vek'nilash suit qui le frappe, donc les attaquants physiques se
placent 8 yards derriere lui, cote oppose a Vek'lor, et il les suit. Ils
repetent jusqu'a **70 yards** de separation, puis ils arretent et tapent
normalement.

Vek'lor, lui, ne bouge presque pas : le script lui fait rejoindre sa cible
jusqu'a 45 yards, puis `StopMoving`. Il ne frappe jamais au contact. Donc la
separation se joue entierement sur Vek'nilash — c'est pour ca qu'un seul
groupe tire.

**Les scarabes reveilles ne font pas decrocher le raid.** Mutate Bug (802) et
Explode Bug (804) rendent une bestiole hostile et elle va chercher quelqu'un.
Seul le bot qu'elle a effectivement atteint est laisse avec elle —
`Unit::getAttackers()` repond exactement a cette question. Tous les autres
restent sur les Empereurs : une bestiole reveillee est un rang 0 de niveau 60,
et les deux jumeaux partagent une seule barre de vie sur un chrono de 15
minutes.

**Rien de tout ca ne bouge avant le pull.** Les trois declencheurs repondent
non tant qu'aucun jumeau n'est en combat. En dehors du combat lui-meme, les
bots restent entierement sous le controle de ce qui les mene d'habitude —
mod-dungeon-clear compris, dont la conf prevoit explicitement ce partage :

> the boss fights themselves are owned by the playerbots raid strategies while
> dungeon-clear stands down

Sur une carte de raid, mod-dungeon-clear route jusqu'au boss, rassemble le
raid a un point de ralliement (`RaidMusterTotalTimeoutSecs`, 60 s au plafond),
libere le pull, puis se retire du combat. Cette strategie en est donc le
proprietaire attendu : `.dc on` a l'entree doit suffire.

## Les scarabes de la salle : pas pour cette strategie

Il y a **100 scarabes et scorpions dans la salle des Empereurs**, et ils ne
frappent jamais les premiers : `npc_ahnqiraji_critter::Reset()` sort avant son
planificateur pour tout spawn que `linked_respawn` rattache a un spawn de
Vek'lor, et les 100 le sont. Les 83 autres de la carte 531, eux, mordent tout
joueur en combat a moins de 10 yards, mais le plus proche est a **156,7 yards**
d'un Empereur : ils ne peuvent pas pull la salle.

Donc un bot qui attaque un scarabe de la salle a ete **envoye**. Ce n'est pas
son initiative : `creature_template.type` vaut 10 (`NOT_SPECIFIED`, pas 8
`CRITTER`), donc `Player::isHonorOrXPTarget` les accepte comme proies, mais
`grind` et `aggressive` ne sont pas poses sur un bot en groupe.

Sur un serveur avec **[mod-dungeon-clear](https://github.com/jrad7/mod-dungeon-clear)**,
c'est lui : il nettoie le trash en route vers chaque boss, et sa propre conf
decrit le resultat mot pour mot —

> the party follows imperfectly and cuts the corner, so a tight skirt on the
> aggro edge pulls the boss anyway (the SM Cathedral / Mograine failure mode)

Cette strategie ne tente **rien** contre ca, volontairement. Son echelle de
priorites va de 60 a 62, celle de mod-dungeon-clear de 25 a 42 : tout ce
qu'elle poserait avant le pull gagnerait contre lui en silence, et ferait
caler un module qui fait son travail. Un livelock de 30 secondes
(`DungeonClear.RoomClearTimeout`) avant chaque boss n'est pas un correctif.

Les leviers sont les siens, et ils sont par run — rien a changer globalement :

| Commande | Effet |
|---|---|
| `.dc off` | arrete le run et rend les bots au joueur |
| `.dc pause` | stoppe sur place ; la meme commande reprend |
| `.dc go <boss>` | route directement vers un boss nomme |
| `.dc config` | affiche les valeurs effectives du run en cours |

Le plus propre : `.dc on` pour tout le temple, `.dc pause` en arrivant chez les
Jumeaux, le combat a la main avec cette strategie, puis reprise. Et
`DungeonClear.WaitAtBoss = 1`, reglable par run depuis le panneau de l'addon,
fait que le tank arrive au boss et s'arrete au lieu de pull — le joueur garde
le pull, une fois par boss.

## Ce que la strategie ne fait pas

- **Elle ne fait pas tanker Vek'lor.** Le tank de son piedestal attend
  l'echange sans le toucher : il est immunise a tout ce qu'un tank frappe.
  Celui qui lui fait le plus de degats le garde, et c'est tout.
- **Elle ne gere pas Unbalancing Strike** (26613, -100 de defense pendant
  6 s sur le tank de Vek'nilash). Pas de rotation de tanks : les deux postes
  sont fixes pour tout le combat, et c'est la teleportation qui fait tourner
  les jumeaux, pas les tanks.
- **Elle demande trois bots tanks** pour que les trois postes soient tenus.
  Avec deux, personne ne s'occupe des bestioles; avec un seul, il tient le
  piedestal de Vek'nilash et le cote Vek'lor reste vide.
- **Elle ne traverse pas la salle avant la teleportation.** Twin Teleport
  tombe toutes les 30 a 40 secondes, echange les positions et remet les
  menaces a zero ; les deux groupes se retrouvent alors du mauvais cote et
  mettent une dizaine de secondes a se replacer. Ca se corrige tout seul,
  parce que le bot qui recoit les 2000 de menace offerte ne fait aucun degat
  au jumeau en question et se fait depasser vite. Mais c'est la fenetre ou la
  separation peut retomber sous 60 yards.
- **Elle ne fait que les Jumeaux.** C'Thun, Ouro, Viscidus et le reste
  tournent toujours sur l'IA generique.
- **Elle ne remplace pas ton placement.** Si c'est toi qui tanke
  Vek'nilash, c'est toi qui dois l'eloigner : les bots ne tirent que ce
  qu'ils tiennent.
- **Elle ne touche a rien hors du combat des Jumeaux.** Pas de regle avant le
  pull, pas de multiplicateur, aucune interference avec ce qui mene les bots
  dans le reste du temple.

## Les chiffres, et d'ou ils viennent

| Constante | Valeur | Source |
|---|---|---|
| `NPC_VEKLOR` | 15276 | `temple_of_ahnqiraj.h` |
| `NPC_VEKNILASH` | 15275 | `temple_of_ahnqiraj.h` |
| `NPC_QIRAJI_SCARAB` | 15316 | `temple_of_ahnqiraj.h` |
| `NPC_QIRAJI_SCORPION` | 15317 | `temple_of_ahnqiraj.h` |
| `HEAL_BROTHER_RANGE` | 60 | `IsWithinDist(twin, 60.f)` avant Heal Brother |
| `SAFE_SEPARATION` | 70 | 60 plus une marge |
| `MELEE_STAY_AWAY_FROM_VEKLOR` | 15 | Arcane Burst sur `NOMINAL_MELEE_RANGE` |
| `CASTER_FAR_SIDE_OFFSET` | 25 | ou se tient un lanceur de sorts derriere Vek'lor : a portee de sort, et Vek'lor n'a aucune raison de revenir (il ne bouge qu'au-dela de 45 yards) |
| `CASTER_STAY_AWAY_FROM_VEKNILASH` | 25 | `AddThreat(victim, 2000.f)` sur le plus proche apres teleportation |
| carte | 531 | Temple d'Ahn'Qiraj |

Deux mesures prises sur une base reelle, pas supposees : les deux jumeaux
naissent a **158,2 yards** l'un de l'autre, et le scarabe mordeur le plus
proche est a **156,7 yards** d'un Empereur.

A verifier sur ta base avant d'entrer :

```powershell
Get-Content tools\jumeaux_aq40.sql -Raw | & "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -uacore -padmin --default-character-set=utf8mb4 -t acore_world
```

Attendu : Vek'lor immunise `physique`, Vek'nilash immunise
`feu, nature, givre, ombre, arcane`. Les requetes suivantes donnent les
positions de spawn, la faction des scarabes au repos, et surtout la colonne
`mord_tout_seul` : tout scarabe de la salle doit y lire `non`.

## Installation

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Azerothcore\modules\mod-playerbots-bis\tools\installer_aq40_twins.ps1"
```

Le contournement `-ExecutionPolicy Bypass` ne vaut que pour ce lancement et ne
change rien au systeme. Pour en finir une fois pour toutes avec tous les
scripts du projet, sans etre administrateur :

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Les fichiers arrivant par `git pull` ne portent pas la marque de zone
d'Internet, donc `RemoteSigned` les laisse passer sans `Unblock-File`.


Le script copie les dix fichiers dans
`mod-playerbots\src\Ai\Raid\Aq40\` et branche la strategie a quatre endroits :

- `src\Ai\Raid\RaidStrategyContext.h` — include, `creators["aq40"]`, fabrique
- `src\Bot\Engine\BuildSharedActionContexts.cpp` — include, `RaidAq40ActionContext`
- `src\Bot\Engine\BuildSharedTriggerContexts.cpp` — include, `RaidAq40TriggerContext`
- `src\Bot\PlayerbotAI.cpp` — `"aq40"` dans `allInstanceStrategies`, et `case 531`

Il sauvegarde chaque fichier avant (`.avant_aq40`), relit apres pour prouver
que l'ecriture a atterri, et se relance sans danger : il saute ce qui est
deja fait. `-Retirer` (ajoute a la meme ligne de commande) annule tout et rend les
quatre fichiers identiques a l'original.

**Il faut reconfigurer CMake, pas seulement rebuild.** AzerothCore liste les
fichiers des modules a la configuration : un dossier neuf n'existe pas pour un
rebuild seul. Clean Full Build, ou "Delete Cache and Reconfigure" puis rebuild.

En jeu, dans le Temple, `/w <bot> co` doit faire apparaitre `aq40` dans la
liste des strategies de combat.
