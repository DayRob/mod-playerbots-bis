<#
.SYNOPSIS
    Installe (ou retire) la strategie AQ40 "Empereurs Jumeaux" dans mod-playerbots.

.DESCRIPTION
    mod-playerbots n'a pas de dossier Aq40 : la carte 531 (Temple d'Ahn'Qiraj)
    n'est rattachee a aucune strategie. Les fichiers sources vivent donc ici,
    dans contrib\aq40\ de mod-playerbots-bis, et ce script les recopie dans
    mod-playerbots\src\Ai\Raid\Aq40\ puis branche la strategie aux quatre
    endroits ou mod-playerbots declare ses strategies de raid.

    Garder les sources ici et non la-bas est volontaire : un "git pull" dans
    mod-playerbots ecrase son arborescence. Apres chaque mise a jour de
    mod-playerbots, relancer ce script remet la strategie en place.

    Le script est idempotent : relance sans danger, il saute ce qui est deja
    fait. Chaque fichier modifie est sauvegarde avant, et relu apres pour
    prouver que l'ecriture a bien atterri.

.PARAMETER CheminPlayerbots
    Racine de mod-playerbots. Par defaut, le dossier mod-playerbots voisin
    de ce depot (C:\Azerothcore\modules\mod-playerbots).

.PARAMETER Retirer
    Desinstalle : supprime le dossier Aq40 et annule les quatre branchements.

.EXAMPLE
    .\tools\installer_aq40_twins.ps1

.EXAMPLE
    .\tools\installer_aq40_twins.ps1 -Retirer
#>

[CmdletBinding()]
param(
    [string]$CheminPlayerbots,
    [switch]$Retirer
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- utilitaires

function Lire-Texte {
    param([string]$Chemin)
    return [System.IO.File]::ReadAllText($Chemin)
}

function Ecrire-Texte {
    param([string]$Chemin, [string]$Texte)
    # UTF-8 sans BOM : un BOM au milieu d'un .cpp casse la compilation sur
    # certains compilateurs, et de toute facon ces fichiers n'en ont pas.
    $encodage = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Chemin, $Texte, $encodage)
}

function Sauvegarder {
    param([string]$Chemin)
    $copie = "$Chemin.avant_aq40"
    if (-not (Test-Path -LiteralPath $copie)) {
        Copy-Item -LiteralPath $Chemin -Destination $copie
        Write-Host "    sauvegarde -> $(Split-Path -Leaf $copie)" -ForegroundColor DarkGray
    }
}

# Insere $Ajout juste apres la ligne qui contient exactement $Ancre.
# Renvoie $true si le fichier a change.
function Inserer-Apres {
    param(
        [string]$Chemin,
        [string]$Ancre,
        [string]$Ajout,
        [string]$Temoin
    )

    $texte = Lire-Texte $Chemin

    if ($texte.Contains($Temoin)) {
        Write-Host "    deja branche : $Temoin" -ForegroundColor DarkGray
        return $false
    }

    if (-not $texte.Contains($Ancre)) {
        throw "Ancre introuvable dans $Chemin :`n    $Ancre`nmod-playerbots a change de forme ; le script doit etre mis a jour."
    }

    $occurrences = ([regex]::Matches($texte, [regex]::Escape($Ancre))).Count
    if ($occurrences -ne 1) {
        throw "L'ancre apparait $occurrences fois dans $Chemin (une seule attendue) :`n    $Ancre"
    }

    $saut = if ($texte.Contains("`r`n")) { "`r`n" } else { "`n" }

    Sauvegarder $Chemin
    $texte = $texte.Replace($Ancre, $Ancre + $saut + $Ajout)
    Ecrire-Texte $Chemin $texte

    # Relecture : on ne fait pas confiance a l'ecriture, on la verifie.
    $relu = Lire-Texte $Chemin
    if (-not $relu.Contains($Temoin)) {
        throw "Ecriture faite mais le temoin est absent a la relecture de $Chemin : $Temoin"
    }

    Write-Host "    branche : $Temoin" -ForegroundColor Green
    return $true
}

# Retire la ligne (et son saut de ligne) qui contient $Temoin.
function Retirer-Ligne {
    param([string]$Chemin, [string]$Temoin)

    $texte = Lire-Texte $Chemin
    if (-not $texte.Contains($Temoin)) {
        Write-Host "    deja absent : $Temoin" -ForegroundColor DarkGray
        return $false
    }

    $saut = if ($texte.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lignes = $texte -split "`r?`n"
    $gardees = @($lignes | Where-Object { -not $_.Contains($Temoin) })
    $texte = [string]::Join($saut, $gardees)

    Ecrire-Texte $Chemin $texte

    $relu = Lire-Texte $Chemin
    if ($relu.Contains($Temoin)) {
        throw "La ligne est toujours la apres ecriture dans $Chemin : $Temoin"
    }

    Write-Host "    retire : $Temoin" -ForegroundColor Yellow
    return $true
}

# Remplace une chaine exacte, une seule fois, avec relecture.
function Remplacer-Une-Fois {
    param(
        [string]$Chemin,
        [string]$Avant,
        [string]$Apres,
        [string]$Temoin
    )

    $texte = Lire-Texte $Chemin

    if ($texte.Contains($Temoin)) {
        Write-Host "    deja branche : $Temoin" -ForegroundColor DarkGray
        return $false
    }

    $occurrences = ([regex]::Matches($texte, [regex]::Escape($Avant))).Count
    if ($occurrences -ne 1) {
        throw "La chaine a remplacer apparait $occurrences fois dans $Chemin (une seule attendue) :`n    $Avant"
    }

    Sauvegarder $Chemin
    Ecrire-Texte $Chemin $texte.Replace($Avant, $Apres)

    $relu = Lire-Texte $Chemin
    if (-not $relu.Contains($Temoin)) {
        throw "Ecriture faite mais le temoin est absent a la relecture de $Chemin : $Temoin"
    }

    Write-Host "    branche : $Temoin" -ForegroundColor Green
    return $true
}

# ------------------------------------------------------------------ reperage

$racineBis = Split-Path -Parent $PSScriptRoot
$dossierSources = Join-Path $racineBis 'contrib\aq40'

if (-not (Test-Path -LiteralPath $dossierSources)) {
    throw "Sources AQ40 introuvables : $dossierSources`nLancer le script depuis le depot mod-playerbots-bis."
}

if (-not $CheminPlayerbots) {
    $voisin = Join-Path (Split-Path -Parent $racineBis) 'mod-playerbots'
    if (Test-Path -LiteralPath $voisin) {
        $CheminPlayerbots = $voisin
    } else {
        throw "mod-playerbots introuvable a cote de ce depot ($voisin).`nPreciser -CheminPlayerbots."
    }
}

$CheminPlayerbots = (Resolve-Path -LiteralPath $CheminPlayerbots).Path

# On verifie qu'on est bien dans mod-playerbots, et pas ailleurs : Aq20 doit
# exister, sinon on s'apprete a copier des fichiers dans un dossier au hasard.
$temoinAq20 = Join-Path $CheminPlayerbots 'src\Ai\Raid\Aq20\Aq20Strategy.h'
if (-not (Test-Path -LiteralPath $temoinAq20)) {
    throw "$CheminPlayerbots ne ressemble pas a mod-playerbots : $temoinAq20 est absent."
}

$fContexte  = Join-Path $CheminPlayerbots 'src\Ai\Raid\RaidStrategyContext.h'
$fActions   = Join-Path $CheminPlayerbots 'src\Bot\Engine\BuildSharedActionContexts.cpp'
$fTriggers  = Join-Path $CheminPlayerbots 'src\Bot\Engine\BuildSharedTriggerContexts.cpp'
$fAI        = Join-Path $CheminPlayerbots 'src\Bot\PlayerbotAI.cpp'
$dossierAq40 = Join-Path $CheminPlayerbots 'src\Ai\Raid\Aq40'

foreach ($f in @($fContexte, $fActions, $fTriggers, $fAI)) {
    if (-not (Test-Path -LiteralPath $f)) {
        throw "Fichier a modifier introuvable : $f"
    }
}

Write-Host ''
Write-Host "mod-playerbots    : $CheminPlayerbots"
Write-Host "sources AQ40      : $dossierSources"
Write-Host ''

# --------------------------------------------------------------- desinstall

if ($Retirer) {
    Write-Host 'Retrait de la strategie AQ40' -ForegroundColor Cyan

    Write-Host "  $(Split-Path -Leaf $fContexte)"
    Retirer-Ligne $fContexte '#include "Aq40Strategy.h"'           | Out-Null
    Retirer-Ligne $fContexte 'creators["aq40"]'                    | Out-Null
    Retirer-Ligne $fContexte 'new RaidAq40Strategy(botAI)'         | Out-Null

    Write-Host "  $(Split-Path -Leaf $fActions)"
    Retirer-Ligne $fActions  '#include "Aq40ActionContext.h"'      | Out-Null
    Retirer-Ligne $fActions  'new RaidAq40ActionContext()'         | Out-Null

    Write-Host "  $(Split-Path -Leaf $fTriggers)"
    Retirer-Ligne $fTriggers '#include "Aq40TriggerContext.h"'     | Out-Null
    Retirer-Ligne $fTriggers 'new RaidAq40TriggerContext()'        | Out-Null

    Write-Host "  $(Split-Path -Leaf $fAI)"
    $texte = Lire-Texte $fAI
    if ($texte.Contains('"aq20", "aq40",')) {
        Ecrire-Texte $fAI $texte.Replace('"aq20", "aq40",', '"aq20",')
        Write-Host '    retire : "aq40" de allInstanceStrategies' -ForegroundColor Yellow
    } else {
        Write-Host '    deja absent : "aq40" de allInstanceStrategies' -ForegroundColor DarkGray
    }

    $texte = Lire-Texte $fAI
    $casAq40 = @(
        '        case 531:',
        '            strategyName = "aq40";  // Temple of Ahn''Qiraj',
        '            break;'
    )
    foreach ($saut in @("`r`n", "`n")) {
        $bloc = $saut + [string]::Join($saut, $casAq40)
        if ($texte.Contains($bloc)) {
            Ecrire-Texte $fAI $texte.Replace($bloc, '')
            Write-Host '    retire : case 531' -ForegroundColor Yellow
            break
        }
    }
    if (-not (Lire-Texte $fAI).Contains('strategyName = "aq40"')) {
        Write-Host '    case 531 absent' -ForegroundColor DarkGray
    } else {
        throw 'Le case 531 est toujours present apres retrait ; a corriger a la main.'
    }

    if (Test-Path -LiteralPath $dossierAq40) {
        Remove-Item -LiteralPath $dossierAq40 -Recurse -Force
        Write-Host "  dossier Aq40 supprime" -ForegroundColor Yellow
    } else {
        Write-Host "  dossier Aq40 deja absent" -ForegroundColor DarkGray
    }

    Write-Host ''
    Write-Host 'Retrait termine. Reconfigurer CMake puis rebuild.' -ForegroundColor Cyan
    Write-Host ''
    exit 0
}

# ------------------------------------------------------------------ install

Write-Host 'Copie des sources' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $dossierAq40)) {
    New-Item -ItemType Directory -Path $dossierAq40 | Out-Null
    Write-Host "  dossier cree : src\Ai\Raid\Aq40" -ForegroundColor Green
}

$attendus = @(
    'Aq40ActionContext.h',
    'Aq40Actions.cpp',
    'Aq40Actions.h',
    'Aq40Multipliers.cpp',
    'Aq40Multipliers.h',
    'Aq40Strategy.cpp',
    'Aq40Strategy.h',
    'Aq40TriggerContext.h',
    'Aq40Triggers.cpp',
    'Aq40Triggers.h',
    'Aq40Utils.cpp',
    'Aq40Utils.h'
)

foreach ($nom in $attendus) {
    $source = Join-Path $dossierSources $nom
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Source manquante : $source"
    }
    $cible = Join-Path $dossierAq40 $nom
    Copy-Item -LiteralPath $source -Destination $cible -Force

    # Relecture : meme taille et meme contenu que la source.
    $a = [System.IO.File]::ReadAllBytes($source)
    $b = [System.IO.File]::ReadAllBytes($cible)
    if ($a.Length -ne $b.Length) {
        throw "La copie de $nom ne correspond pas a la source ($($a.Length) vs $($b.Length) octets)."
    }
    Write-Host "  $nom ($($a.Length) octets)"
}

Write-Host ''
Write-Host 'Branchement de la strategie' -ForegroundColor Cyan

Write-Host "  $(Split-Path -Leaf $fContexte)"
Inserer-Apres $fContexte `
    '#include "Aq20Strategy.h"' `
    '#include "Aq40Strategy.h"' `
    '#include "Aq40Strategy.h"' | Out-Null

Inserer-Apres $fContexte `
    '        creators["aq20"] = &RaidStrategyContext::aq20;' `
    '        creators["aq40"] = &RaidStrategyContext::aq40;' `
    'creators["aq40"]' | Out-Null

Inserer-Apres $fContexte `
    '    static Strategy* aq20(PlayerbotAI* botAI) { return new RaidAq20Strategy(botAI); }' `
    '    static Strategy* aq40(PlayerbotAI* botAI) { return new RaidAq40Strategy(botAI); }' `
    'new RaidAq40Strategy(botAI)' | Out-Null

Write-Host "  $(Split-Path -Leaf $fActions)"
Inserer-Apres $fActions `
    '#include "Aq20ActionContext.h"' `
    '#include "Aq40ActionContext.h"' `
    '#include "Aq40ActionContext.h"' | Out-Null

Inserer-Apres $fActions `
    '    actionContexts.Add(new RaidAq20ActionContext());' `
    '    actionContexts.Add(new RaidAq40ActionContext());' `
    'new RaidAq40ActionContext()' | Out-Null

Write-Host "  $(Split-Path -Leaf $fTriggers)"
Inserer-Apres $fTriggers `
    '#include "Aq20TriggerContext.h"' `
    '#include "Aq40TriggerContext.h"' `
    '#include "Aq40TriggerContext.h"' | Out-Null

Inserer-Apres $fTriggers `
    '    triggerContexts.Add(new RaidAq20TriggerContext());' `
    '    triggerContexts.Add(new RaidAq40TriggerContext());' `
    'new RaidAq40TriggerContext()' | Out-Null

Write-Host "  $(Split-Path -Leaf $fAI)"

# La liste que ApplyInstanceStrategies vide avant de poser la bonne strategie.
# Sans "aq40" dedans, la strategie resterait collee au bot apres sa sortie du raid.
Remplacer-Une-Fois $fAI `
    '"aq20", "blacktemple",' `
    '"aq20", "aq40", "blacktemple",' `
    '"aq20", "aq40",' | Out-Null

# La carte 531 n'est rattachee a rien dans mod-playerbots : on l'ajoute juste
# apres la 509 (Ruines d'Ahn'Qiraj), son voisin logique.
$texte = Lire-Texte $fAI
if ($texte.Contains('strategyName = "aq40"')) {
    Write-Host '    deja branche : case 531' -ForegroundColor DarkGray
} else {
    $saut = if ($texte.Contains("`r`n")) { "`r`n" } else { "`n" }
    $ancre = [string]::Join($saut, @(
        '        case 509:',
        '            strategyName = "aq20";  // Ruins of Ahn''Qiraj',
        '            break;'
    ))
    if (-not $texte.Contains($ancre)) {
        throw "Ancre case 509 introuvable dans $fAI ; mod-playerbots a change de forme."
    }
    $occurrences = ([regex]::Matches($texte, [regex]::Escape($ancre))).Count
    if ($occurrences -ne 1) {
        throw "L'ancre case 509 apparait $occurrences fois dans $fAI (une seule attendue)."
    }

    $ajout = [string]::Join($saut, @(
        '        case 531:',
        '            strategyName = "aq40";  // Temple of Ahn''Qiraj',
        '            break;'
    ))

    Sauvegarder $fAI
    Ecrire-Texte $fAI $texte.Replace($ancre, $ancre + $saut + $ajout)

    $relu = Lire-Texte $fAI
    if (-not $relu.Contains('strategyName = "aq40"')) {
        throw "Ecriture faite mais case 531 absent a la relecture de $fAI."
    }
    Write-Host '    branche : case 531' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Installation terminee.' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Il reste a reconstruire. Un nouveau dossier source veut un passage de' -ForegroundColor Yellow
Write-Host 'CMake : AzerothCore liste les fichiers des modules a la configuration,' -ForegroundColor Yellow
Write-Host 'pas a la compilation. Un simple rebuild ne suffira pas.' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Clean Full Build  (ou "Delete Cache and Reconfigure" puis rebuild)'
Write-Host ''
Write-Host 'Puis en jeu, dans le Temple d''Ahn''Qiraj, verifier sur un bot :'
Write-Host '  /w <bot> co'
Write-Host 'La liste des strategies de combat doit contenir aq40.'
Write-Host ''
