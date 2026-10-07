# APP FLOW — mod-playerbots-bis

> Enchaînement des décisions d'un bot, et parcours de l'administrateur.

## 1. Démarrage du serveur

```
worldserver démarre
  ├─ import des fichiers SQL inconnus de data/sql/db-world/
  ├─ chargement de la configuration playerbots_bis.conf
  ├─ BisPriorityMgr charge paliers, items, jetons
  └─ premier tick du monde : enregistrement de "item usage" / "item upgrade" (après mod-playerbots)
Log : Active (N paliers, M objets) | Dormant | Tables unavailable
```

## 2. Un bot rencontre une arme ou une armure

```
Objet proposé (roll, ramassage, quête, échange, achat…)
  └─ verdict d'origine de mod-playerbots
       └─ arme ou armure ? ── non ──► verdict d'origine
            │ oui
            ▼
       Classe/spé avec liste atteignable ? ── non ──► verdict d'origine
            │ oui
            ▼
       L'objet est-il sur MA liste (palier ≤ plafond) ?
         ├─ oui ──► meilleur que la pièce portée (palier, puis rang) ?
         │            ├─ oui ──► « c'est mon BiS (palier), à la place de [Ancien] » ──► Need / équipe
         │            │          (niveau insuffisant : annonce + garde en sac)
         │            └─ non ──► pas d'intérêt
         ├─ non, mais BiS d'une autre classe/spé ──► Pass (LeaveOtherSpecsBis)
         └─ BiS de personne ──► logique d'origine (×1,1)
                                 sauf si l'emplacement porte déjà une pièce listée ──► refus
```

## 3. Vote de roll avec `NeedOnlyForBis = 1`

```
BiS et amélioration ──► NEED
Amélioration ordinaire ──► GREED (soumis à LootGreedRollLevel)
Inutile ──► PASS
```

## 4. Butin de maître

```
Ouverture du cadavre ──► hook OnPlayerBeforeSendLoot
  └─ pour chaque bot du groupe : WantsAsUpgrade() + WouldReplace()
       └─ un seul chuchotement par bot au maître :
          « Je need cet objet : [Objet] à la place de [Ancien] (phase) »
Le maître distribue en connaissance de cause.
```

## 5. Jeton de quête

```
Bot reçoit un jeton (ex. Hakkari) ──► table playerbots_bis_quest_token
  ──► le jeton est traité comme la pièce qu'il achète pour sa classe
```

## 6. Parcours administrateur

```
Installer : clone dans modules/mod-playerbots-bis ──► build ──► copier la conf ──► Enable = 1 ──► démarrer
Changer de phase : MaxTier = palier suivant ──► .playerbotsbis reload
Contrôler : .playerbotsbis report | missing | equipe
Contribuer une liste : page source ──► convertisseur ──► SQL résolu par nom ──► import ──► noms_absents
Côté client : export_bis_tooltip ──► install_addon ──► relancer le jeu ──► /pbbis
```
