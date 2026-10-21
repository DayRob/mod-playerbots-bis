# Playerbots BiS Butin

Addon 3.3.5a. Une fenetre, calquee sur le cadre de guilde, qui repond a une
seule question : **qu'est-ce qu'il reste a aller chercher, et ou ?**

```
+ Temple d'Ahn'Qiraj                      18 objets    31 bots
    + Princesse Huhuran                    4 objets     7 bots
        Ailes de Huhuran                                3 bots
        Carapace du royaume des insectes                2 bots
    + Empereurs jumeaux                    3 objets     5 bots
+ Repaire de l'Aile noire                 11 objets    19 bots
```

Lu : il reste dix-huit objets **rang 1** a faire tomber dans AQ40 ; quatre chez
Huhuran ; et les Ailes doivent tomber encore **trois** fois, parce que trois
bots les attendent.

L'etat BiS des bots repond bot par bot - ce qui manque a Gorkozu. Utile quand on
regarde un bot, inutile quand on choisit un raid. C'est la meme information lue
par l'autre bout : par la piece, et par le boss qui la lache.

## Installation

```powershell
.\tools\export_bis_butin.ps1 -WowPath "C:\Wow335"
```

Le script copie l'addon **et** genere ses donnees. Un addon nouveau n'est jamais
pris en compte par un `/reload` : il faut quitter le client et le relancer.

## Utilisation

- `/pbbutin` ou `/butin` : ouvrir ou fermer la fenetre
- bouton de minicarte : **clic gauche** ouvre, **clic droit** demande un releve,
  **glisser** le deplace autour de la minicarte
- `/pbbutin minicarte` : cacher ou remontrer le bouton
- clic sur un raid ou un boss : deplier
- Maj+clic sur un objet : coller le lien dans le tchat
- survol d'un objet : son infobulle, **et la liste des bots qui l'attendent**

Le bouton **Actualiser** envoie `.playerbotsbis report` - c'est ce releve qui
remplit la fenetre.

## D'ou viennent les chiffres

Du flux de `.playerbotsbis report`, le meme que l'etat BiS des bots. Le serveur
envoie, bot par bot, chaque ligne de sa liste avec son rang et son etat. Cet
addon ne retient que les lignes **rang 1** dont l'etat est **manquant** : ni
portee, ni en sac.

Consequences a connaitre :

- un objet que **tous** les bots qui le listent portent deja **disparait** de la
  fenetre : il n'y a plus rien a aller chercher ;
- une piece deja dans les sacs d'un bot ne compte pas - elle n'a plus besoin de
  tomber ;
- un objet hors de portee du palier du serveur n'apparait pas, parce que le
  serveur ne l'envoie pas. La fenetre dit ce qui est **obtenable**, pas ce qui
  existe.

L'addon ecoute `CHAT_MSG_SYSTEM` directement, et non le filtre de tchat de
l'autre addon : un filtre qui renvoie `true` interrompt la chaine, donc le
second charge ne verrait jamais rien. L'evenement, lui, est remis a tout le
monde. Les deux fenetres peuvent donc vivre cote a cote sur le meme releve.

## D'ou viennent les boss

Pas du client : le tooltip 3.3.5 ne contient **aucune** information de
provenance, ni boss, ni donjon. C'est la base MONDE qui sait, et
`tools/export_bis_butin.ps1` l'y lit pour ecrire `ButinData.lua` :

- le butin direct de la creature (`creature_loot_template`) ;
- le butin passant par une table de reference (`reference_loot_template`) -
  c'est le cas de beaucoup de pieces de raid ;
- les pieces **achetees avec un jeton** (`playerbots_bis_quest_token`) : la
  piece ne tombe nulle part, c'est le jeton qui tombe, et sans ce chemin les
  jetons d'Ahn'Qiraj et hakkari laisseraient leurs pieces invisibles.

Un objet tombe souvent de plusieurs creatures - le boss, son trash, un rare du
meme donjon. Une seule est gardee, celle qui repond a « ou vais-je le chercher » :
une source directe l'emporte sur un jeton, une carte connue sur le monde ouvert,
un boss sur du trash, et a egalite la meilleure chance.

Le nom d'une carte n'est pas dans la base monde - il vit dans les DBC du client -
donc la table des raids est ecrite dans le script d'export, dans l'ordre de la
**progression** et non dans l'ordre alphabetique : c'est dans cet ordre qu'on
choisit un raid.

Sans `ButinData.lua`, l'addon se charge quand meme : il range tout sous
« source inconnue » et le dit en clair, plutot que de faire semblant.

## Limites

- **C'est un instantane**, celui du dernier `.playerbotsbis report`. Rien ne le
  rafraichit tout seul.
- Les sources sont celles de ta base au moment de l'export. Apres un import de
  nouvelles listes BiS, relance `export_bis_butin.ps1`.
- Une piece de quete, de reputation ou d'artisanat n'a pas de boss : elle tombe
  sous « source inconnue », et c'est normal.
