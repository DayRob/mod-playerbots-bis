# PRD — mod-playerbots-bis

> Product Requirements Document : le *quoi* et le *pourquoi*.

## 1. Résumé

Module AzerothCore (World of Warcraft 3.3.5a) qui étend [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) : les bots s'équipent et lancent leurs jets de butin en suivant une **échelle de progression BiS** (*Best in Slot*) par classe et par spécialisation, au lieu de la seule règle « ce nouvel objet vaut 1,1 fois mieux que l'ancien ».

## 2. Problème

Avec mod-playerbots seul :
- en raid, quarante bots votent **Need** sur tout objet légèrement meilleur, et privent les autres de pièces qui ne feront jamais leur équipement final ;
- les bots dérivent loin de l'équipement optimal de leur spé au fil du butin ;
- en **butin de maître**, aucun bot n'exprime d'intérêt : le maître distribue à l'aveugle ;
- un objet bleu de donjon peut déloger une pièce BiS, puis être remplacé au tick suivant (va-et-vient sans fin).

## 3. Utilisateurs

| Utilisateur | Besoin |
|---|---|
| Administrateur d'un serveur privé avec randombots | Des bots crédibles, qui progressent palier par palier |
| Joueur qui raide avec des bots | Savoir qui veut quoi, distribuer le butin à bon escient |
| Contributeur de listes BiS | Ajouter ou corriger une liste sans toucher au C++ |

## 4. Objectifs

| Objectif | Mesure |
|---|---|
| Ne rien casser | mod-playerbots non modifié ; tout objet hors liste suit la logique d'origine |
| Respecter la progression | Un palier supérieur l'emporte toujours ; plafond réglable (`MaxTier`) |
| Butin juste | Need réservé au vrai BiS (option), BiS d'une autre spé laissé à son propriétaire |
| Transparence | Le bot annonce ce qu'il revendique et ce qu'il remplace |
| Données fiables | Aucun nom inventé ; les noms non résolus sont listés à l'import |

## 5. Fonctionnalités

1. **Reconnaissance BiS en trois branches** : son BiS (annonce + roll), BiS d'une autre classe/spé (passe), BiS de personne (logique d'origine).
2. **Échelle de 18 paliers** de Vanilla Pre-Raid à Ruby Sanctum, `rank` à l'intérieur d'un palier.
3. **Protection des pièces listées** contre les objets hors liste.
4. **Need réservé au BiS** (`NeedOnlyForBis`), Greed sur le reste.
5. **Annonces** au roll, en butin de maître (chuchotement au maître) et à l'équipement, en nommant la pièce remplacée.
6. **Revendication sous le niveau requis** : le bot garde la pièce en sac et l'équipera plus tard.
7. **Jetons de quête** (ex. Zul'Gurub) traités comme la pièce qu'ils achètent.
8. **Intégration mod-individual-progression** : chaque bot limité aux paliers qu'il a débloqués.
9. **Commandes MJ** `.playerbotsbis reload | report | missing | libere | equipe`.
10. **Addons client** : infobulle BiS, navigateur de listes, relevé des bots, compositions de raid, recensement de population.
11. **Outillage** : conversion de guides, import ordonné, audit PvP, détection des noms absents, diagnostic de l'addon.

## 6. Hors périmètre

- Équipement généré au *randomize* d'un bot (`PlayerbotFactory::InitEquipment`) : appel direct dans mod-playerbots, non substituable.
- Listes BiS PvP et réputation (purgées volontairement).
- Modification du code de mod-playerbots.

## 7. Contraintes

- Le dossier doit s'appeler `modules/mod-playerbots-bis` (point d'entrée dérivé du nom).
- Le module reste inerte si les tables ne sont pas importées, même avec `Enable = 1`.
