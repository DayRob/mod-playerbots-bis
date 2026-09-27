<#
.SYNOPSIS
    Copie l'addon PlayerbotsBisTooltip dans le dossier AddOns du client.

.DESCRIPTION
    L'addon est UN dossier contenant plusieurs fichiers .lua, listes dans le
    .toc. Ajouter une fonctionnalite veut donc dire ajouter un fichier - et un
    fichier absent du dossier du client n'existe tout simplement pas pour le
    jeu, meme si le serveur, lui, envoie bien les donnees.

    C'est pour cela qu'une nouvelle fenetre demande de recopier le dossier :
    ce n'est pas une etape differente des precedentes, c'est la meme.

    Le script ne supprime rien. Il copie, puis dit ce qui a change.

.PARAMETER WowPath
    Racine du client WoW 3.3.5 (le dossier contenant Wow.exe).

.EXAMPLE
    .\tools\install_addon.ps1 -WowPath "C:\Wow335"

.EXAMPLE
    Si PowerShell refuse de lancer le script ("execution de scripts desactivee") :
    powershell -ExecutionPolicy Bypass -File .\tools\install_addon.ps1 -WowPath "C:\Wow335"

.NOTES
    Un fichier NOUVEAU n'est jamais pris en compte par /reload : il faut
    quitter le client entierement et le relancer.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot '..\addon\PlayerbotsBisTooltip'
$source = (Resolve-Path $source).Path

$addons = Join-Path $WowPath 'Interface\AddOns'
if (-not (Test-Path $addons)) {
    throw "Dossier AddOns introuvable : $addons`nVerifie -WowPath : il doit pointer sur le dossier contenant Wow.exe."
}

$target = Join-Path $addons 'PlayerbotsBisTooltip'

# BisData.lua est GENERE depuis la base par export_bis_tooltip.ps1. L'ecraser
# avec une version plus ANCIENNE viderait les infobulles ou les ferait mentir,
# mais refuser de le copier tout court empecherait de propager un export frais
# fait dans le depot. La version la plus recente gagne donc.
#
# La date de la GENERATION decide, pas celle du fichier : git horodate les
# fichiers au moment du clone, si bien qu'un depot fraichement recupere porte
# un substitut "plus recent" que l'export reel du client. Comparer les dates du
# systeme de fichiers aurait donc remplace de vraies donnees par le substitut,
# ce qui est exactement l'accident que cette regle doit empecher.
$generated = 'BisData.lua'

# Lit l'horodatage inscrit en tete d'un BisData.lua genere. Renvoie $null pour
# le substitut du depot, qui n'en porte pas.
function Get-BisDataStamp([string] $path) {
    if (-not (Test-Path $path)) { return $null }
    foreach ($line in (Get-Content -Path $path -TotalCount 10)) {
        if ($line -match '^--\s*Source\s*:.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2})') {
            return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm',
                                          [Globalization.CultureInfo]::InvariantCulture)
        }
    }
    return $null
}

Write-Host "Source : $source"
Write-Host "Cible  : $target"
Write-Host ""

if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target | Out-Null
    Write-Host "Dossier cree." -ForegroundColor Green
}

$copied = @()
$skipped = @()

foreach ($file in Get-ChildItem -Path $source -File) {
    if ($file.Name -eq $generated) {
        $destPath = Join-Path $target $generated
        if (Test-Path $destPath) {
            $srcStamp  = Get-BisDataStamp $file.FullName
            $destStamp = Get-BisDataStamp $destPath

            # Source non generee : jamais au-dessus de donnees reelles.
            if (-not $srcStamp) {
                $skipped += $file.Name
                continue
            }
            if ($destStamp -and $destStamp -ge $srcStamp) {
                $skipped += $file.Name
                continue
            }
        }
    }

    $dest = Join-Path $target $file.Name
    $isNew = -not (Test-Path $dest)
    Copy-Item -Path $file.FullName -Destination $dest -Force

    # L'etat est calcule AVANT la table : PowerShell 5.1, celui livre avec
    # Windows, refuse un "if" comme valeur dans un litteral de hashtable.
    $etat = 'mis a jour'
    if ($isNew) { $etat = 'NOUVEAU' }
    $copied += [PSCustomObject]@{ Fichier = $file.Name; Etat = $etat }
}

$copied | Format-Table -AutoSize

if ($skipped.Count -gt 0) {
    Write-Host "Laisse en place, la copie du client est plus recente ou plus complete : $($skipped -join ', ')" -ForegroundColor DarkGray
    Write-Host "Pour la regenerer : .\tools\export_bis_tooltip.ps1 -WowPath ""$WowPath""" -ForegroundColor DarkGray
    Write-Host ""
}

# Le .toc est la liste de chargement : un .lua qui n'y figure pas est ignore
# par le client, meme present dans le dossier.
$toc = Join-Path $target 'PlayerbotsBisTooltip.toc'
$tocLines = Get-Content $toc
$version = ($tocLines | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', ''
$listed = $tocLines | Where-Object { $_ -match '\.lua\s*$' }

Write-Host "Version du .toc : $version"
Write-Host "Fichiers charges par le client :"
foreach ($entry in $listed) {
    $name = $entry.Trim()
    $present = Test-Path (Join-Path $target $name)
    $mark = 'MANQUANT'
    $colour = 'Red'
    if ($present) { $mark = 'ok'; $colour = 'Gray' }
    Write-Host ("   {0,-32} {1}" -f $name, $mark) -ForegroundColor $colour
}

$anyNew = $copied | Where-Object { $_.Etat -eq 'NOUVEAU' }
Write-Host ""
if ($anyNew) {
    Write-Host "Un fichier NOUVEAU a ete installe : quitte le client entierement et relance-le." -ForegroundColor Yellow
    Write-Host "/reload ne suffit pas, il ne relit que les fichiers deja charges." -ForegroundColor Yellow
} else {
    Write-Host "Aucun fichier nouveau : /reload suffit." -ForegroundColor Green
}
