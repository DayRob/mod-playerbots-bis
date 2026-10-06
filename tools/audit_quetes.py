#!/usr/bin/env python3
"""Verifie qu'aucune recompense de quete PvP n'a glisse dans les listes.

La regle du projet est "pas de PvP, pas de reputation", mais une recompense de
quete ne porte RIEN qui la trahisse : wowtbc.gg l'affiche "Quest Reward", que la
quete se deroule dans un donjon ou en Vallee d'Alterac. Deux objets etaient
ainsi passes - Bloodseeker et Wand of Biting Cold, tous deux de "Hero of the
Frostwolf" - et ils n'ont ete rattrapes que parce que je les avais ecartes a la
main un jour, puis perdus en regenerant.

Ce script relit les pages de data/pages/ et montre les deux cotes :

  - ce que la regle ECARTE, qui doit etre entierement du PvP ;
  - les NOMS DE QUETE gardes, a parcourir des yeux pour y reperer un champ de
    bataille.

Le second ne peut pas etre automatise : rien dans "Warlord's Command (H)" ne dit
si c'est un donjon ou un front. C'est un outil de relecture, pas un verdict.

  python3 tools/audit_quetes.py [dossier]
"""
import glob
import importlib.util
import os
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def charger_convertisseur():
    chemin = os.path.join(RACINE, "tools", "convert_wowtbc_bis.py")
    spec = importlib.util.spec_from_file_location("conv", chemin)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    dossier = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RACINE, "data", "pages")
    pages = sorted(glob.glob(os.path.join(dossier, "*.txt")))
    if not pages:
        print("aucune page dans %s" % dossier)
        return 1

    conv = charger_convertisseur()
    gardes, ecartes = {}, {}

    for fichier in pages:
        lignes = []
        for ligne in open(fichier, encoding="utf-8").read().splitlines():
            ligne = ligne.strip()
            bas = ligne.lower()
            if not ligne or bas in conv.DECOR or bas.startswith("enchant"):
                continue
            lignes.append(ligne)

        for nom, creneau, source in conv.lire_blocs(lignes):
            if creneau is None or creneau in conv.IGNORES:
                continue
            if "Quest Reward" not in source:
                continue
            quete = source.replace("Quest Reward", "").strip()
            cible = ecartes if conv.EXCLUS.search(source) else gardes
            cible.setdefault((nom, quete), set()).add(os.path.basename(fichier))

    print("%d page(s) lue(s) dans %s\n" % (len(pages), dossier))

    print("ECARTEES - doivent TOUTES etre du PvP :")
    if not ecartes:
        print("   aucune")
    for (nom, quete), fichiers in sorted(ecartes.items()):
        print("   %-34s <- %-28s (%d liste(s))" % (nom, quete, len(fichiers)))

    quetes = sorted({q for _, q in gardes})
    print("\nGARDEES : %d objet(s) sur %d quete(s)." % (len(gardes), len(quetes)))
    print("Relis ces noms : un champ de bataille s'y cacherait sans rien dire.")
    for quete in quetes:
        print("   %s" % quete)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        # "python3 tools/audit_quetes.py | head" ferme le tuyau avant la fin, et
        # Python repond par une trace qui ressemble a un plantage alors que tout
        # s'est bien passe. On sort en silence, comme n'importe quel outil Unix.
        os._exit(0)
