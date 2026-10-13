#!/usr/bin/env python3
"""Rend aux fichiers generes les rangs que le plafond ecrasait.

LE DEFAUT
---------
Le convertisseur a longtemps plafonne le rang a 3 : tout ce qui arrivait apres
le troisieme objet d'un creneau recevait le rang 3 comme lui. Le module calcule
la priorite par `255 - rank`, donc ces objets avaient la MEME priorite, et un
bot portant le quatrieme choix ne voyait pas le troisieme comme une
amelioration. Il repondait "je n'en ai pas besoin" a mieux que ce qu'il portait.

POURQUOI RENUMEROTER PLUTOT QUE REGENERER
-----------------------------------------
Les fichiers du palier 60 ont ete regeneres depuis leurs pages, qui sont au
depot. Ceux des paliers inferieurs ne le peuvent pas : leurs pages ont disparu,
ou une regle du convertisseur a change depuis - les regenerer produirait des
listes DIFFERENTES, pas les memes mieux rangees.

Or le rang n'a pas besoin de la page. L'ordre des lignes DANS le fichier est
deja l'ordre d'apparition, puisque c'est lui qui a produit les rangs. Il suffit
donc de renumeroter par creneau, sans toucher a un seul nom d'objet.

LE GARDE-FOU
------------
Les objets de rang 1 et 2 ne doivent PAS bouger : eux n'ont jamais ete
plafonnes. Si la renumerotation les deplacait, c'est que l'ordre des lignes
n'est pas celui qu'on croit, et le fichier est laisse intact.

    python3 tools/renumeroter_les_rangs.py            # montre
    python3 tools/renumeroter_les_rangs.py --ecrire   # applique
"""
import glob
import os
import re
import sys

# Le champ du rang, et SEULEMENT lui. Les trois groupes decoupent la ligne en
# "ce qui precede le rang", "le rang", "ce qui suit" : reassembler les trois en
# changeant le milieu ne peut rien perdre d'autre.
#
# La premiere version reconstruisait la ligne entiere avec un format, et le
# "$" de son motif ne capturait pas le saut de ligne : chaque ligne reecrite
# collait a la suivante, et des objets disparaissaient. Le fichier d'essai l'a
# montre tout de suite - un rang 0 apparaissait, ce qui n'existe pas.
LIGNE = re.compile(r"^(\(\s*\d+,\s*)(\d+)(,.*)$")


def traiter(chemin, ecrire):
    texte = open(chemin, encoding="utf-8").read()
    if "bis_seed_wowtbc" not in texte:
        return None

    lignes = texte.splitlines(keepends=True)
    debut = None
    for i, l in enumerate(lignes):
        if "INSERT INTO `bis_seed_wowtbc`" in l:
            debut = i + 1
            break
    if debut is None:
        return None

    compteur = {}
    paires = []          # (ancien rang, nouveau rang)
    change = 0
    for i in range(debut, len(lignes)):
        brut = lignes[i]
        fin = "\n" if brut.endswith("\n") else ""
        corps = brut[:-len(fin)] if fin else brut

        m = LIGNE.match(corps)
        if not m:
            if not corps.strip() or corps.strip().startswith("--"):
                continue
            break

        creneau = re.match(r"^\(\s*(\d+)", corps).group(1)
        rang = int(m.group(2))
        neuf = compteur.get(creneau, 0) + 1
        compteur[creneau] = neuf
        paires.append((rang, neuf))

        if neuf != rang:
            change += 1
            lignes[i] = m.group(1) + str(neuf) + m.group(3) + fin

    if not change:
        return (os.path.basename(chemin), 0, True)

    # GARDE-FOU : un objet de rang 1 ou 2 ne doit pas changer de rang. Eux
    # n'ont jamais ete plafonnes ; s'ils bougent, l'ordre des lignes n'est pas
    # celui qu'on croit et le fichier merite d'etre regarde, pas reecrit.
    sain = all(a == b for a, b in paires if a in (1, 2))
    if sain and ecrire:
        open(chemin, "w", encoding="utf-8").write("".join(lignes))
    return (os.path.basename(chemin), change, sain)


def main():
    ecrire = "--ecrire" in sys.argv
    base = os.path.join(os.path.dirname(__file__), "..", "data", "sql", "db-world", "base")
    total = douteux = 0
    for f in sorted(glob.glob(os.path.join(base, "*.sql"))):
        r = traiter(f, ecrire)
        if not r:
            continue
        nom, n, sain = r
        if not sain:
            douteux += 1
            print("  %-42s %3d rangs - LAISSE INTACT, les rangs 1 et 2 bougeraient" % (nom, n))
        elif n:
            total += n
            print("  %-42s %3d rangs rendus" % (nom, n))

    print()
    print("%d rang(s) %s sur l'ensemble du depot." % (total, "rendus" if ecrire else "a rendre"))
    if douteux:
        print("%d fichier(s) laisses intacts par precaution." % douteux)
    if not ecrire and total:
        print("Relance avec --ecrire pour appliquer.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
