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

## Une seule strategie, et rien a armer

`aq40`, posee toute seule en entrant sur la carte 531. Elle porte tout : ne pas
reveiller les bestioles, se placer, puller, et le combat. **Aucune commande a
taper en jeu.**

mod-playerbots la pose dans les DEUX moteurs, et c'est ce qui rend la chose
possible — fin de `ApplyInstanceStrategies`, `src\Bot\PlayerbotAI.cpp` :

```cpp
engines[BOT_STATE_COMBAT]->addStrategy(strategyName);
engines[BOT_STATE_NON_COMBAT]->addStrategy(strategyName);
```

**Il y a eu une seconde strategie, `aq40danse`, et c'etait une erreur.** La
mise en place et le pull avaient ete sortis dans une strategie que le joueur
devait armer depuis le chat de groupe, pour qu'ils ne se disputent pas avec
mod-dungeon-clear. Mais rien n'arme une strategie que la carte n'apporte pas :
`+aq40danse` dit dans le chat de groupe est reste du chat de groupe. Releve
dans le journal du run : quarante bots engagent Vek'nilash a 35 yards de sa
plateforme, personne sur les marques, le tank a 64 yards de la sienne, et
dix-neuf bots empiles sur un scarabe qui n'avait pas bouge de son point
d'apparition.

La cohabitation avec mod-dungeon-clear ne se regle donc pas par une commande,
mais par deux verrous dans les regles d'avant-pull : elles se taisent tant
qu'aucun Empereur n'est a portee (le raid est encore en chemin, et le chemin
appartient a dungeon-clear) et tant que le bot n'est pas DANS la salle. Les
regles de COMBAT, elles, repondent faux tant qu'un Empereur n'est pas engage.

## On ne frappe jamais le premier

Aucun bot n'attaque un PNJ qui ne nous attaque pas — barre de vie **jaune**, pas
rouge — nulle part dans le temple. La regle ne nomme aucune entree de creature :
nommer, c'etait se tromper a la premiere oubliee.

Elle existe a cause du script du coeur des bestioles de la salle des Jumeaux,
`npc_ahnqiraji_critter` :

```cpp
if (Player* player = me->SelectNearestPlayer(10.f))
    if (player->IsInCombat())
        AttackStart(player);

context.Repeat(3500ms, 4s);
```

Toutes les quatre secondes, chacune cherche un joueur **en combat** a moins de
dix yards et lui saute dessus. Un seul bot qui engage une bestiole tranquille,
et tout ce qui traine a dix yards d'un combattant rejoint — puis a dix yards de
ceux-la. C'est comme ca qu'on passe de six bots en combat a dix-huit empiles sur
des scarabes qui n'avaient pas bouge de leur point d'apparition.

**Ce qui nous attaque se tue**, en revanche, jaune ou rouge : la regle rend la
main des que la cible a pour victime un joueur du groupe. Ces bestioles
attaquent sans changer de faction, donc elles restent jaunes tout en etant un
vrai danger — Percer l'armure et Crachat acide pour le scorpion.

**Verifier que c'est en place**, en jeu, sur un bot :

```
/w <bot> co ?
/w <bot> nc ?
```

`aq40` doit apparaitre dans les deux listes. Le point d'interrogation compte :
`ChangeStrategy` ne traite que `+ - ~ ?`, donc un `co` seul ne repond rien.

## Ce que la strategie fait

Tout vient du script du coeur,
`src/server/scripts/Kalimdor/TempleOfAhnQiraj/boss_twinemperors.cpp`, et de la
strategie de guilde que le joueur a decrite. Rien de memoire.

**Ce qui fait perdre le combat, et c'est la seule chose :**

```cpp
.Schedule(3600ms, [this](TaskContext context)
{
    if (Creature* twin = GetTwin())
        if (me->IsWithinDist(twin, 60.f))
            DoCast(twin, SPELL_HEAL_BROTHER, true);
    context.Repeat();
});
```

Chacun soigne son frere toutes les 3,6 secondes, mais seulement a moins de
**60 yards**. Et les degats sont partages (Twin Empathy, 1177), donc deux
Empereurs cote a cote annulent le raid entier.

### Ce que chacun permet

| | Vek'lor (15276) | Vek'nilash (15275) |
|---|---|---|
| immunise a | **physique, et provocation** | magique sauf sacre |
| au contact | jamais — s'arrete a 45 yards | frappe, Uppercut, Frappe desequilibrante |
| tenu par | un **demoniste**, par les degats | un **guerrier** |
| deplacable par un tank | **non** | oui, il suit son attaquant |

C'est toute l'ossature : aucun tank n'a de prise sur Vek'lor, ni pour le tenir
ni pour le deplacer. L'ecartement se fait donc sur Vek'nilash.

### Les deux marques

Relevees en jeu au `.gps`, sur les deux tetes de mort du schema de guilde :

```cpp
constexpr Aq40Mark MARQUE_A = { -8896.308f, 1283.0752f, -112.292564f };  // gauche
constexpr Aq40Mark MARQUE_B = { -9027.637f, 1259.976f,  -112.294556f };  // droite
```

**133,3 yards** entre les deux — plus du double des 60 de Heal Brother. Ce ne
sont pas les points d'apparition : les Empereurs poussent sur les plateformes du
fond, a 82 yards de la marque qui leur fait face et 166 de l'autre.

### Les postes

| Rang | Qui | Ou |
|---|---|---|
| tank 0 | par ordre de GUID | marque **A**, pour tout le combat |
| tank 1 | | marque **B**, pour tout le combat |
| tank 2 | | le **milieu**, avec les bestioles |
| tank 3+ | | en renfort sur Vek'nilash |
| — | **demoniste** designe | du cote de Vek'lor, en retrait de 25 yards |
| — | corps-a-corps | cote Vek'nilash |
| — | lanceurs de sorts | cote Vek'lor |
| — | soigneurs | **non places** : ils suivent |

**Les tanks ne changent jamais de bout de salle.** C'est le guide qui l'impose :

> le tank guerrier pourra se deplacer le long du mur derriere lui. **Ce sera
> proche de l'endroit ou le guerrier tankera apres la teleportation.**

Celui qui a Vek'nilash de son cote le tient et le ramene sur sa marque, dos au
mur — pour que l'Uppercut ne le sorte pas de position, ni de la zone de soins.
L'autre **attend sur la sienne sans rien faire**, et c'est son travail :

> Pour reprendre l'aggro de Vek'nilash apres une teleportation, le Guerrier doit
> etre **le personnage le plus proche** a proximite de l'empereur.

Le script donne ses 2000 de menace au joueur le plus proche; un tank poste la ou
Vek'nilash va atterrir est donc celui qui le recupere. La geometrie tranche a
chaque instant — aucun etat a conserver, et le role bascule tout seul a
l'echange.

### Le demoniste

Il tient Vek'lor par les degats, et **il recule** :

> Il est essentiel que le Demoniste soit vigilant et recule legerement. S'il ne
> reagit pas assez rapidement, Vek'lor lancera son Jaillissement des arcanes sur
> le Demo Tank, perturbant gravement le positionnement.

Le script ne declenche Arcane Burst que s'il trouve un joueur a portee de
contact — `SelectNearestPlayer(NOMINAL_MELEE_RANGE)` — donc reculer suffit, et
c'est la premiere chose que son action fait. Sa position a lui decide celle de
Vek'lor, qui s'arrete a 45 yards de sa cible et ne bouge plus.

Choisi par GUID parmi les lanceurs de sorts, **demonistes d'abord**.

### Le pull

Il ne part que lorsque les tanks sont sur leurs marques, et les partants voient
la condition devenir vraie au MEME tick — donc ils s'elancent ensemble. Ce n'est
pas du confort :

```cpp
if (Creature* twin = GetTwin())
    if (!twin->IsInCombat())
        twin->AI()->AttackStart(who);
```

Engager un Empereur envoie l'autre sur celui qui l'a engage. Sans le demoniste
sur Vek'lor au meme instant, les deux se rejoignent avant le premier coup — et
aucun tank ne peut l'en empecher, puisque la provocation ne passe pas sur lui.

Les tanks deja arrives **retiennent** le pull pendant que les autres marchent :
leur regle siege au-dessus de la bande de pertinence de mod-dungeon-clear, donc
son action d'engagement n'est pas atteinte. Avec une limite de 20 secondes, pour
qu'un tank mort ou bloque ne gele pas le run.

### Les bestioles

Vek'lor lance Explode Bug toutes les 4,5 a 10 secondes, Vek'nilash Mutate Bug
toutes les 10 a 20. Chaque incantation en reveille **une seule** —
`RandomResize(targets, 1)` — qui passe hostile et entre en combat avec la zone.
Sans menace sur personne, elle part vers qui lui en donne : le soigneur, parce
que chaque sort de soin en fabrique sur tout ce qui est en combat avec lui.

> Le groupe assigne aux insectes doit etre reactif et notamment surveiller
> qu'ils ne s'approchent pas trop des soigneurs.

D'ou un poste, pas une reaction : entre deux bestioles, le tank 2 tient le
milieu. Et la provocation en premier geste — attendre d'avoir de la menace par
les degats laisse le soigneur se faire mordre plusieurs secondes de plus.
L'ordre d'urgence : celle qui mange un soigneur, puis celle qui mange quelqu'un
d'autre, puis la sienne.

## Ce que la strategie ne fait pas

- **Elle ne gere pas Frappe desequilibrante** (26613, −100 de defense pendant
  6 s). Pas de rotation de tanks : les deux postes sont fixes, et c'est la
  teleportation qui fait tourner les Empereurs, pas les tanks.
- **Elle ne fait pas reculer les corps-a-corps avant l'echange.** Le guide le
  demande — « les DPS melee doivent absolument reculer 5 secondes avant la
  prochaine teleportation » — mais rien dans le script ne permet de connaitre ce
  compte a rebours de l'exterieur.
- **Elle ne fait que les Jumeaux.** C'Thun, Ouro, Viscidus et le reste tournent
  sur l'IA generique.
- **Elle ne gere pas la resistance a l'Ombre** du demoniste tank, que le guide
  presente comme la condition de sa survie.
- **Elle demande trois bots tanks** pour que les trois postes soient tenus. Avec
  deux, personne ne prend les bestioles.

## Les chiffres, et d'ou ils viennent

| Constante | Valeur | Source |
|---|---|---|
| `NPC_VEKLOR` | 15276 | `temple_of_ahnqiraj.h` |
| `NPC_VEKNILASH` | 15275 | `temple_of_ahnqiraj.h` |
| `NPC_QIRAJI_SCARAB` | 15316 | `temple_of_ahnqiraj.h` |
| `TWIN_SCAN_RANGE` | 250 | mesure : 166 et 168 yards entre chaque poste et la plateforme d'en face |
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

- `src\Ai\Raid\RaidStrategyContext.h` — include, `creators["aq40"]`, la fabrique
  (et le retrait de `aq40danse`, si une installation precedente l'avait posee)
- `src\Bot\Engine\BuildSharedActionContexts.cpp` — include, `RaidAq40ActionContext`
- `src\Bot\Engine\BuildSharedTriggerContexts.cpp` — include, `RaidAq40TriggerContext`
- `src\Bot\PlayerbotAI.cpp` — `"aq40"` dans `allInstanceStrategies`, et `case 531`

Il sauvegarde chaque fichier avant (`.avant_aq40`), relit apres pour prouver
que l'ecriture a atterri, et se relance sans danger : il saute ce qui est
deja fait. `-Retirer` (ajoute a la meme ligne de commande) annule tout et rend les
quatre fichiers identiques a l'original.

**Quel build, et pourquoi.** AzerothCore liste les fichiers des modules A LA
CONFIGURATION de CMake, pas a la compilation : `CollectSourceFiles` fait un
`file(GLOB)` sans `CONFIGURE_DEPENDS`. Donc :

| Ce qui a change | Ce qu'il faut |
|---|---|
| la LISTE des fichiers (un ajout, un retrait) | Clean Full Build, ou "Delete Cache and Reconfigure" puis rebuild |
| seulement le CONTENU | **Rebuild only** — les fichiers sont deja dans la liste |
| rien | rien du tout |

**L'installeur le dit lui-meme** a la fin de chaque passage : il compare les
empreintes avant de copier et nomme le build qui s'impose. Le premier cas est
rare — il ne se presente qu'a la toute premiere installation, ou le jour ou la
strategie gagne un fichier. Les autres fois, un build complet coute cinquante
minutes pour rien.

En jeu, dans le Temple, `/w <bot> co ?` doit faire apparaitre `aq40` dans la
liste des strategies de combat. Le point d'interrogation compte :
`Engine::ChangeStrategy` ne traite que `+ - ~ ?`, donc un `co` seul ne repond
rien.
