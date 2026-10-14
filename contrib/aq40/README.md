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

**2. Personne ne reste collé au jumeau qu'il ne peut pas blesser.** Les
physiques s'ecartent a 15 yards de Vek'lor — y rester ne rapporte rien et
declenche Arcane Burst (568), qui les repousse. Les casters s'ecartent a
25 yards de Vek'nilash, qui frappe au contact et qui, apres chaque
teleportation, agresse la cible la plus proche avec 2000 de menace offerte.

**3. Les physiques eloignent Vek'nilash de son frere.** Heal Brother (7393)
part toutes les 3,6 secondes, mais seulement si les deux jumeaux sont a moins
de **60 yards** l'un de l'autre. C'est la seule chose qui fait perdre le
combat.

Mesure sur une base reelle : les deux spawns sont a **158,2 yards** l'un de
l'autre. Ils commencent donc deja separes, et cette regle ne sert qu'a
rattraper une separation perdue en cours de combat, pas a faire le travail du
pull. Vek'nilash suit qui le frappe, donc les attaquants physiques se
placent 8 yards derriere lui, cote oppose a Vek'lor, et il les suit. Ils
repetent jusqu'a **70 yards** de separation, puis ils arretent et tapent
normalement.

Vek'lor, lui, ne bouge presque pas : le script lui fait rejoindre sa cible
jusqu'a 45 yards, puis `StopMoving`. Il ne frappe jamais au contact. Donc la
separation se joue entierement sur Vek'nilash — c'est pour ca qu'un seul
groupe tire.

**Rien de tout ca ne bouge avant le pull.** Les trois declencheurs repondent
non tant qu'aucun jumeau n'est en combat. En dehors du combat lui-meme, les
bots restent entierement sous le controle de ce qui les mene d'habitude —
mod-dungeon-clear compris.

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

- **Elle ne designe pas de tank pour Vek'lor.** Pas besoin : il ne frappe
  jamais au contact, il reste a 45 yards et lance Shadow Bolt. Celui qui lui
  fait le plus de degats le garde, et c'est tout.
- **Elle ne gere pas Unbalancing Strike** (26613, -100 de defense pendant
  6 s sur le tank de Vek'nilash). Pas de rotation de tanks.
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
| `CASTER_STAY_AWAY_FROM_VEKNILASH` | 25 | `AddThreat(victim, 2000.f)` sur le plus proche apres teleportation |
| `BUG_ALERT_RANGE` | 15 | un bot aux prises avec un scarabe reveille est laisse tranquille |
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
