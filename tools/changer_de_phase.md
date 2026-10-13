# Passer les bots a la phase suivante

Ecrit pour le passage en **Ahn'Qiraj (palier 60)**, mais la marche a suivre vaut
pour n'importe quelle phase : seul le numero change.

| Phase | Palier |
|---|---|
| Vanilla Pre-Raid | 10 |
| Molten Core / Onyxia | 20 |
| Blackwing Lair | 30 |
| Zul'Gurub | 40 |
| **Ahn'Qiraj (20 et 40)** | **60** |
| Naxxramas 40 | 70 |

Il n'y a **pas** de palier 50. Les deux Ahn'Qiraj sont le meme palier : wowtbc.gg
publie une seule liste par spe pour la phase, et ses objets viennent des deux
raids melanges.

Et une confusion a ecarter tout de suite : les en-tetes des fichiers AQ disent
`Source : Vanilla P5 AQ (wowtbc.gg)`. Le **P5 y qualifie la source**, pas le
palier - wowtbc.gg compte ses phases autrement. Ici Ahn'Qiraj est la phase 4 et
Naxxramas la 5, comme dans Classic.

## Ce que ce palier a de particulier

C'est le palier le mieux couvert du depot : **seize spes relevees une par une**
sur wowtbc.gg, sur huit classes - guerrier, chasseur, voleur, pretre, chaman,
mage, demoniste, druide - plus les jetons qirajis.

**Le paladin n'en fait pas partie.** Aucune page paladin n'a ete relevee, donc
ses trois spes gardent au palier 60 les lignes de la conversion d'origine, dont
les rangs ne viennent d'aucun guide. Sur un serveur Horde en contenu Vanilla ca
ne se voit pas ; si des bots paladin apparaissent, leur equipement AQ est le
seul du palier a n'etre pas verifie.

Trois spes n'ont pas de page a elles non plus et sont **recopiees** par
`20_specs_partagees.sql` : voleur Assassinat et Subtilite portent la liste de
Combat, pretre Discipline celle de Sacre, demoniste Demonologie celle
d'Affliction. C'est voulu - en Vanilla ces arbres cherchent le meme equipement.

Deux consequences pratiques, toutes deux traitees ci-dessous : il faut un import
**a froid** (le fichier 01 a change), et c'est le palier sur lequel
`PlayerbotsBis.MaxTier` doit se caler.

## 1. Serveur arrete : le code

```powershell
cd C:\Azerothcore\modules\mod-playerbots-bis
git pull origin claude/randombots-bis-logic-0mbx4x
```

Puis **Clean Full Build**, pas "Rebuild only". Deux fichiers C++ ont ete
ajoutes depuis le palier 40 - `BisBotGate.cpp` et `BisBotQueue.cpp`, le filtre
de connexion et la file d'attente - donc la configuration CMake a bouge, et un
rebuild partiel ne les compile pas.

Au demarrage, le journal doit annoncer **3637** scripts C++ et non 3634 : c'est
la preuve la plus simple que le binaire est bien le neuf. Trois demarrages ont
ete perdus une fois a diagnostiquer une file d'attente qui ne tournait pas,
alors que le binaire etait simplement l'ancien.

## 2. Les fichiers de configuration

`C:\Azerothcore\configs\modules\playerbots_bis.conf` :

```
PlayerbotsBis.MaxTier = 60
PlayerbotsBis.NeedOnlyForBis = 1
PlayerbotsBis.ForceNeedForBis = 1
PlayerbotsBis.ClaimClassRestricted = 1
```

Le `.dist` livre desormais `MaxTier = 60` par defaut, mais **le build n'installe
que le `.dist`** : ton `.conf`, lui, garde la valeur que tu y as mise.

Un script s'en charge, et le serveur peut rester allume :

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\changer_le_palier.ps1 -Appliquer
```

Il trouve le `.conf` tout seul, sauvegarde l'ancien, puis **relit le fichier** et
affiche ce qu'il y a trouve. Cette relecture est le point : sans elle, un
remplacement qui n'a pas porte - cle absente, fichier en lecture seule -
ressemble exactement a un remplacement reussi.

Sans `-Appliquer`, il montre seulement ce qu'il changerait. Et si la cle manque
dans ton `.conf` - le cas normal pour un fichier ecrit avant que le reglage
existe - il l'ajoute au lieu de repartir sans rien faire.

Pour un autre palier : `-Palier 40`. Le script refuse un numero absent de
l'echelle plutot que de l'ecrire, parce qu'un palier inexistant se comporte
comme un plafond a zero - les bots viseraient le sommet, en silence.

**Pourquoi 60 et pas 0.** Les paliers 10 a 60 ont des listes curees. Au-dela,
les lignes viennent encore de la conversion de `playerbots_bis_gear`, dont les
rangs ne sortent d'aucun guide. Sans plafond, un bot de niveau 60 irait chercher
des objets que personne n'a classes. 60 est le sommet de ce qui est verifie.

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

## 3. Importer les listes - A FROID pour ce palier

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\importer_tout.ps1 -Depuis 1 `
  -WowPath "C:\test\world of warcraft 3.3.5a hd"
```

Une seule commande fait tout : la base, puis le reexport de `BisData.lua`, puis
la copie de l'addon.

**`-Depuis 1` n'est pas optionnel cette fois.** Le defaut est `-Depuis 24`, qui
saute les fichiers 01 a 23 parce qu'ils ne changent plus. Or **le 01 a change** :
c'est lui qui porte l'echelle des paliers, et il a perdu le palier 50 et
renumerote les phases. Sans lui, ta base garde un palier 50 fantome et annonce
encore "Vanilla Phase 5 - Ahn Qiraj 40".

A froid, le 02 repasse aussi. Il **recree** `playerbots_bis_item` de zero, ce qui
est exactement ce qu'on veut ici : plus aucune ligne d'avant la fusion ne
survit. Les fichiers 17 et 20 passent deux fois - a leur place numerique, puis a
la fin - et c'est voulu : au premier passage le 20 recopierait des listes encore
absentes.

### L'ordre, et pourquoi le script existe

Les fichiers generes effacent d'abord les lignes de leur couple
classe/spe/palier, donc ils sont rejouables dans n'importe quel ordre **entre
eux**. Trois exceptions, que le script gere :

- `20_specs_partagees.sql` recopie une spe vers une autre - voleur Assassinat et
  Subtilite portent la liste de Combat, pretre Discipline celle de Sacre,
  demoniste Demonologie celle d'Affliction. Il doit passer **apres** les listes
  qu'il recopie, sinon il recopie du vide.
- `17_purge_pvp_reputation.sql` passe en **dernier** : les lignes que le 20 vient
  de recopier peuvent contenir du PvP ou de la reputation, que seul le 17 sait
  reconnaitre dans la base monde.
- `74_aq_guerrier_armes_deux_mains.sql` doit passer **apres** le 73, qui efface
  le couple guerrier Armes / palier 60 en entier. Son numero s'en charge.

### A la main, si tu veux voir passer les fichiers

`source fichier.sql` n'est **pas** du SQL : c'est une commande du client
interactif, et la passer par `-e` donne `ERROR 1064`. Depuis PowerShell, pousse
le contenu dans l'entree standard :

```powershell
$m    = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe"
$base = "C:\Azerothcore\modules\mod-playerbots-bis\data\sql\db-world\base"
Get-Content -Raw "$base\75_aq_jetons_qiraji.sql" |
  & $m -uacore -padmin --table acore_world
```

## 4. Lire le bilan d'import

Le script isole la seule sortie qui demande une action.

**NOMS QUE TA BASE NE CONNAIT PAS.** Chaque ligne est un objet absent de la
liste finale : le creneau garde ses autres rangs, mais celui-la est perdu. Pour
ce palier, deux fichiers meritent un regard :

- `74_aq_guerrier_armes_deux_mains.sql` nomme sept armes a deux mains. Son
  classement vient des **guides**, pas d'une mesure sur ta base - contrairement
  aux paliers 30 et 40 du fichier 57. Pour trancher sur tes chiffres :

  ```powershell
  Get-Content tools\armes_deux_mains_palier_60.sql -Raw |
    & $m -uacore -padmin acore_world --table
  ```

  Si l'ordre de la requete contredit celui du fichier, c'est le fichier qui a
  tort - dis-le et il sera corrige.

- `75_aq_jetons_qiraji.sql` nomme dix jetons. C'est la **seule** chose ecrite a
  la main dans ce fichier : la piece et la classe sortent de `quest_template` et
  des listes. Un nom qui remonte ici est un jeton qui ne sera pas reclame.

  ```powershell
  Get-Content tools\jetons_aq.sql -Raw |
    & $m -uacore -padmin acore_world --table --force
  ```

  Sa section 2 sort **le raisonnement du fichier 75 a l'ecran** : quel jeton,
  quelle quete, quelle piece.

**JETONS SANS CONVERSION.** Un bot peut reclamer ces jetons mais rien ne les
echange contre une piece : il les gagnerait pour rien. Cette liste doit etre
vide.

**Couverture par palier.** Lue dans la base, pas deduite des fichiers.
Ahn'Qiraj doit afficher **28 couples** classe/spe. Le compte se decompose :
24 viennent du fichier 02 et sont remplaces spe par spe par les fichiers AQ,
3 sont ajoutes par les recopies du fichier 20 (voleur 0 et 2, pretre 0), et 1
par le fichier 73 (guerrier Armes, que le 02 n'avait pas). L'ours druide (11/10)
compte comme un couple a part.

## 5. Au redemarrage

```
.playerbotsbis reload
```

Elle relit le `.conf` depuis le disque et **annonce le palier obtenu**. Verifie
qu'il dit bien 60. (Avant la version qui affiche ce palier, editer le `.conf`
puis recharger ne changeait rien : les reglages venaient de la memoire du
serveur. C'est corrige.)

```
.playerbotsbis report
```

Les lignes doivent maintenant citer `Vanilla Phase 4 - Ahn Qiraj (20 et 40)`. Si
un bot est ignore, la commande dit lequel et pourquoi.

## 6. Avant le premier raid AQ

```
.playerbotsbis libere moi
```

Tout le monde repart sans verrou, donc la premiere entree cree une copie neuve
et les 40 y vont ensemble. Puis les macros d'invitation, tu entres le premier,
et `summon` en tchat de raid. Le detail est dans `macros_raid.md`.

## 7. Ce que les jetons changent pendant le raid

Deux choses se declenchent sans que tu aies rien a faire.

**Au lancer de des**, un bot vote Besoin sur un jeton qirajien si la piece que ce
jeton lui donnerait est dans sa liste - au rang qu'elle y porte. Un Imperial
Qiraji Armaments vaut donc Besoin pour le guerrier qui a la hache en rang 1, et
rien pour celui qui ne l'a pas.

**Des qu'il le tient**, le bot echange le jeton contre sa piece et l'equipe. Il
ne le garde pas dans son sac : un jeton n'est ni arme ni armure, il y dormirait
pour toujours.

Une seule piece par jeton et par classe, et c'est celle de **meilleur rang** -
le point qui compte quand un jeton offre un choix d'armes, comme les Armaments.

Les **scarabees et les idoles** qirajis ne sont pas traites : ils achetent des
enchantements, pas des pieces. Ils n'ont aucun creneau ou se poser, et un bot ne
les reclamera pas.
