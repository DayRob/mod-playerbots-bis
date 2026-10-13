#!/usr/bin/env python3
"""Cherche les tables TEMPORARY lues deux fois dans une meme instruction SQL.

POURQUOI CE SCRIPT EXISTE
-------------------------
MySQL refuse d'ouvrir une table TEMPORARY deux fois dans la meme instruction :

    ERROR 1137 (HY000) : Can't reopen table: 'j'

MariaDB, lui, l'accepte. Le banc d'essai de ce depot tourne sur MariaDB, donc
un fichier peut y passer sans un mot et tomber chez un joueur qui tourne sur
MySQL. C'est arrive au fichier 75 : un NOT EXISTS relisait les deux tables
temporaires, le test local n'a rien dit, et l'import a echoue en production.

Ce script retrouve ce defaut SANS moteur, en lisant le texte. Il ne remplace
pas un import d'essai : il attrape la seule chose qu'un import sur MariaDB ne
peut PAS attraper.

CE QU'IL NE PRETEND PAS FAIRE
-----------------------------
Le decoupage en instructions se fait sur les points-virgules en fin de ligne,
et le comptage sur le nom de la table. C'est grossier a dessein - ecrire un
analyseur SQL pour ca serait disproportionne. Les deux approximations vont dans
le sens de la prudence : au pire il signale une instruction saine, jamais il ne
passe sous silence une relecture.
"""
import glob
import os
import re
import sys

# Les tables temporaires que le fichier declare lui-meme. On ne s'interesse
# qu'a elles : une table reelle peut etre rouverte autant qu'on veut, et
# plusieurs fichiers le font legitimement (item_template, quest_template).
DECLARE = re.compile(r"CREATE\s+TEMPORARY\s+TABLE\s+`?(\w+)`?", re.I)


def enlever_commentaires(texte):
    # Un nom de table cite dans un commentaire - et ces fichiers en citent
    # beaucoup, pour expliquer precisement ce genre de piege - compterait comme
    # une lecture. Les commentaires partent donc avant tout comptage.
    lignes = []
    for l in texte.splitlines():
        sans = re.sub(r"--.*$", "", l)
        lignes.append(sans)
    return "\n".join(lignes)


def instructions(texte):
    """Decoupe sur les ';' en fin de ligne."""
    courant = []
    for l in texte.splitlines():
        courant.append(l)
        if l.rstrip().endswith(";"):
            yield "\n".join(courant)
            courant = []
    if any(x.strip() for x in courant):
        yield "\n".join(courant)


def lectures(instruction, table):
    """Combien de fois cette instruction NOMME cette table.

    Les DROP et les CREATE sont ecartes : ils ne sont pas des lectures, et un
    "DROP TEMPORARY TABLE IF EXISTS x; CREATE TEMPORARY TABLE x" n'a jamais
    pose de probleme.
    """
    tete = instruction.lstrip()[:40].upper()
    if tete.startswith("DROP") or tete.startswith("CREATE"):
        return 0
    motif = re.compile(r"`?\b" + re.escape(table) + r"\b`?")
    return len(motif.findall(instruction))


def main():
    base = os.path.join(os.path.dirname(__file__), "..", "data", "sql")
    fichiers = sorted(glob.glob(os.path.join(base, "**", "*.sql"), recursive=True))
    if not fichiers:
        print("aucun fichier .sql trouve sous data/sql", file=sys.stderr)
        return 1

    soucis = 0
    examines = 0
    for f in fichiers:
        texte = enlever_commentaires(open(f, encoding="utf-8", errors="replace").read())
        temporaires = set(DECLARE.findall(texte))
        if not temporaires:
            continue
        examines += 1
        for inst in instructions(texte):
            for t in sorted(temporaires):
                n = lectures(inst, t)
                if n > 1:
                    soucis += 1
                    premiere = next((l for l in inst.splitlines() if l.strip()), "")
                    print("%s : `%s` lue %d fois dans une seule instruction"
                          % (os.path.basename(f), t, n))
                    print("    %s" % premiere.strip()[:90])
                    print("    MySQL rendra ERROR 1137 Can't reopen table, MariaDB non.")

    print()
    if soucis:
        print("%d relecture(s) a corriger, sur %d fichier(s) a tables temporaires."
              % (soucis, examines))
        return 1
    print("Aucune relecture de table temporaire, sur %d fichier(s) concerne(s)." % examines)
    return 0


if __name__ == "__main__":
    sys.exit(main())
