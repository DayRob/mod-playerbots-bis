# Passer les bots a la phase suivante

Ecrit pour le passage en Blackwing Lair (palier 30), mais la marche a suivre
vaut pour n'importe quelle phase : seul le numero change.

| Phase | Palier |
|---|---|
| Vanilla Pre-Raid | 10 |
| Molten Core / Onyxia | 20 |
| **Blackwing Lair** | **30** |
| Zul'Gurub | 40 |
| Ahn'Qiraj 20 | 50 |
| Ahn'Qiraj 40 | 60 |
| Naxxramas 40 | 70 |

## 1. Serveur arrete : le code

```powershell
cd C:\Azerothcore\modules\mod-playerbots-bis
git pull origin claude/randombots-bis-logic-0mbx4x
```

Puis **Build** dans le gestionnaire. Si "Rebuild only" echoue, "Clean Full
Build" : des fichiers C++ ont ete ajoutes (`BisUnbind`) et d'autres retires
(`BisDungeonPlan`), donc la configuration CMake a bouge.

## 2. Les fichiers de configuration

`C:\Azerothcore\configs\modules\playerbots_bis.conf` :

```
PlayerbotsBis.MaxTier = 30
PlayerbotsBis.NeedOnlyForBis = 1
PlayerbotsBis.ForceNeedForBis = 1
PlayerbotsBis.ClaimClassRestricted = 1
```

Les trois dernieres manquaient : ton `.conf` date d'avant leur ajout, et le
build n'installe que le `.dist`. Elles tournaient donc sur leurs defauts, dont
`NeedOnlyForBis = 0` - la moitie qui RETIRE le Besoin a ce qui n'est pas BiS.

`C:\Azerothcore\configs\modules\playerbots.conf` :

```
AiPlayerbot.LootNeedRollLevel = 2
```

Sinon mod-playerbots reecrit chaque Besoin en Cupidite juste avant de voter
(`LootRollAction.cpp`). Avec `ForceNeedForBis = 1` le module emet le Besoin
lui-meme, donc ce reglage n'est plus indispensable - mais il evite une
incoherence entre les deux.

`C:\Azerothcore\configs\worldserver.conf`, si tu rejoues une instance
d'affilee :

```
AccountInstancesPerHour = 100
```

Pas 0 : la comparaison est `size() < config`, donc 0 veut dire "aucune".

### Repartir d'instances neuves a chaque demarrage

Dans `playerbots_bis.conf` :

```
PlayerbotsBis.ResetInstancesOnStartup = 1
```

A chaque demarrage du serveur, tous les verrous de raid sont effaces - ceux des
bots comme ceux des vrais joueurs. La premiere entree de la soiree ouvre donc
une copie neuve que les 40 bots partagent, et tu n'as plus a y penser.

`2` au lieu de `1` inclut les donjons. `0` desactive.

Ce n'est pas anodin : les boss deja tues de la semaine disparaissent avec les
verrous. Sur un serveur ou des joueurs etalent un raid sur plusieurs soirees,
laisse a 0 et utilise `.playerbotsbis libere` en cours de session, qui ne touche
que les bots.

## 3. Importer les listes du nouveau palier

Ouvre le client MySQL, puis donne-lui les fichiers. C'est la methode qui sert
depuis le debut du projet :

```powershell
& "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe" -u acore -p
```

A l'invite `mysql>` :

```
USE acore_world;
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/18_bwl_wowsims.sql
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/19_mc_wowsims.sql
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/20_specs_partagees.sql
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/17_purge_pvp_reputation.sql
```

Puis `exit`.

**L'ordre compte** : 18, 19 et 20 ecrivent, 17 nettoie derriere. Le 17 est le
seul a savoir reconnaitre le PvP et la reputation dans la base monde ; le passer
avant les autres laisserait ces objets dans les listes fraichement posees.

**`USE` et `source` sont des commandes du client, pas du shell.** Collees dans
PowerShell elles repondent `Le terme USE n'est pas reconnu`. Et `source` n'existe
pas non plus via `mysql -e "..."` : le client l'envoie au serveur, qui repond
`ERROR 1064`. Il faut l'invite interactive.

Les barres obliques NORMALES dans les chemins : `source` prend mal les
antislashs.

En une seule ligne depuis PowerShell, si tu preferes - les trois fichiers sont
en ASCII pur, donc le tube ne peut rien abimer :

```powershell
$mysql = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe"
$base  = "C:\Azerothcore\modules\mod-playerbots-bis\data\sql\db-world\base"
Get-Content -Raw "$base\18_bwl_wowsims.sql" | & $mysql -u acore -padmin --table acore_world
```

Ces deux fichiers sont **generes** depuis les sets du simulateur WoWSims Classic
par `tools/convert_wowsims_gear.py`. Ils remplacent, pour les spes qu'ils
couvrent, les listes issues de la conversion d'origine.

Le palier 30 y gagne quatre spes curees la ou il n'en avait aucune - guerrier
Armes et Fureur, chaman Elementaire et Amelioration, druide Equilibre. Le palier
20 en gagne neuf : chasseur x3, chaman x2, demoniste x3, druide Equilibre.

`20_specs_partagees.sql` aligne les spes qui visent le meme equipement, a tous
les paliers : voleur Assassinat et Subtilite portent la liste de Combat, pretre
Discipline celle de Sacre. En Vanilla les trois arbres de voleur cherchent le
meme stuff DPS - WoWSims ne publie d'ailleurs qu'un set de voleur par phase,
comme pour le chasseur et le mage - et Discipline soigne avec l'equipement de
Sacre.

Ce fichier REMPLACE : sur un palier ou la spe source a une liste, celle de la
cible est effacee puis recopiee, ce qui garantit qu'elles sont identiques. Un
palier ou la source n'a rien n'est pas touche. Pour redonner plus tard sa propre
liste a une spe, retire sa ligne de la table `bis_copie_spec` en tete du
fichier, sinon le passage suivant l'ecrasera.

Apres ces quatre fichiers, le palier 30 doit afficher 28 lignes de couverture -
9 classes x 3 spes, plus l'ours druide (11/10). Le palier 20 aussi.

Ce qu'ils ne font PAS :

- ils n'ecrasent jamais une liste ecrite a la main depuis un guide Wowhead
  (guerrier Armes/Fureur et mage au palier 20, par exemple) : un set de
  simulateur ne donne qu'un objet par emplacement, un guide classe des
  alternatives ;
- ils refusent de remplacer une spe quand le set tombe sous douze creneaux -
  c'est alors le set de raid de la classe, pas une liste d'equipement ;
- ils ne couvrent aucun soigneur : WoWSims Classic ne simule pas le soin, et
  ses repertoires correspondants sont vides.

## 4. Nettoyer les listes du nouveau palier

Meme methode que ci-dessus : a l'invite `mysql>`,

```
source C:/Azerothcore/modules/mod-playerbots-bis/data/sql/db-world/base/17_purge_pvp_reputation.sql
```

Le palier 30 n'a **aucun fichier curé** : ses 24 combinaisons classe/spe
viennent toutes de la conversion d'origine, dont les rangs ne sortent d'aucun
guide et qui contient du PvP en rang 1. Ce fichier retire au moins ce qui viole
la regle du projet - PvP et reputation - sur preuve et non sur supposition :
reputation requise, rang de haut fait, ou vente contre un cout etendu (honneur,
marques).

Il affiche ce qu'il va supprimer AVANT de le faire. Lis cette premiere table.

**Ca n'en fait pas des listes justes pour autant** : l'ordre des rangs reste
celui de la conversion. Pour de vraies listes BWL il faut les guides, spe par
spe.

## 5. Regenerer les donnees de l'addon

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\export_bis_tooltip.ps1 -WowPath "C:\test\world of warcraft 3.3.5a hd"
powershell -ExecutionPolicy Bypass -File .\tools\install_addon.ps1 -WowPath "C:\test\world of warcraft 3.3.5a hd"
```

Les deux passent par `-ExecutionPolicy Bypass` : la politique par defaut de
Windows refuse d'executer un script telecharge, et l'appel direct echoue sur
`UnauthorizedAccess`.

L'infobulle lit un export fige : sans ca elle continue d'annoncer les anciennes
listes pendant que les bots suivent les nouvelles. La fenetre du releve, elle,
vient en direct du serveur - en cas de desaccord, c'est elle qui a raison.

## 6. Au redemarrage

```
.playerbotsbis reload
```

Elle relit le `.conf` depuis le disque et **annonce le palier obtenu**. Verifie
qu'il dit bien 30.

```
.playerbotsbis report
```

Les lignes doivent maintenant citer `Vanilla Phase 2 - Blackwing Lair`. Si un
bot est ignore, la commande dit lequel et pourquoi.

## 7. Avant le premier raid BWL

```
.playerbotsbis libere moi
```

Tout le monde repart sans verrou, donc la premiere entree cree une copie neuve
et les 40 y vont ensemble. Puis les macros d'invitation, tu entres le premier,
et `summon` en tchat de raid. Le detail est dans `macros_raid.md`.
