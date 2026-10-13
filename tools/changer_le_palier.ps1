<#
.SYNOPSIS
    Cale PlayerbotsBis.MaxTier dans le .conf du serveur.

.DESCRIPTION
    Le build n'installe que le .conf.dist. Le .conf, lui, garde la valeur que tu
    y as mise : changer de phase demande donc de l'editer a la main, et c'est le
    genre de geste qu'on croit avoir fait.

    Ce script le fait, et surtout il RELIT le fichier apres ecriture pour le
    prouver. Sans cette relecture, un remplacement qui n'a pas porte - cle
    absente, faute de frappe, fichier en lecture seule - ressemble exactement a
    un remplacement reussi.

    Il trouve le .conf tout seul, par la meme recherche que
    export_bis_tooltip.ps1 : les emplacements habituels d'AzerothCore, puis une
    fouille bornee depuis la racine du serveur. C'est elle qui avait trouve
    C:\Azerothcore\configs\modules\, que les chemins devines ne couvraient pas.

    SANS -Appliquer, il ne fait que montrer ce qu'il changerait.

    LE SERVEUR PEUT TOURNER. Apres l'ecriture, ".playerbotsbis reload" relit le
    fichier depuis le disque et annonce le palier obtenu - pas besoin de
    redemarrer.

.PARAMETER Palier
    Le palier a viser. Defaut 60 (Ahn'Qiraj 20 et 40).

      10 Pre-Raid    30 BWL    60 AQ 20+40    0 = pas de plafond
      20 MC/Ony      40 ZG     70 Naxx40

    Il n'y a pas de palier 50 : les deux Ahn'Qiraj sont le meme palier.

.PARAMETER Conf
    Chemin du .conf, si la recherche ne le trouve pas.

.PARAMETER Appliquer
    Ecrire. Sans ce drapeau, rien n'est touche.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\changer_le_palier.ps1
    Montre ce qui changerait, sans rien ecrire.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\changer_le_palier.ps1 -Appliquer
    Ecrit MaxTier = 60, sauvegarde l'ancien fichier, et relit pour verifier.
#>

[CmdletBinding()]
param(
    [int]      $Palier = 60,
    [string]   $Conf   = '',
    [switch]   $Appliquer
)

$ErrorActionPreference = 'Stop'
$CLE = 'PlayerbotsBis.MaxTier'

Write-Host ''
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host '   Palier maximum des bots                 ' -ForegroundColor Cyan
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host ''

# Les paliers que l'echelle contient vraiment. 50 n'y est plus : les deux
# Ahn'Qiraj ont fusionne, et un palier qui n'existe pas se comporte comme un
# plafond a zero - les bots viseraient le sommet, en silence.
$connus = @{
    0 = 'pas de plafond'; 10 = 'Vanilla Pre-Raid'; 20 = 'MC / Onyxia'
    30 = 'Blackwing Lair'; 40 = "Zul'Gurub"; 60 = "Ahn'Qiraj (20 et 40)"
    70 = 'Naxxramas 40'; 80 = 'TBC Pre-Raid'; 90 = 'TBC Karazhan'
    100 = 'TBC SSC / TK'; 110 = 'TBC Hyjal / BT'; 120 = 'TBC Sunwell'
    130 = 'WotLK Pre-Raid'; 140 = 'WotLK Naxx'; 150 = 'WotLK Ulduar'
    160 = 'WotLK ToC'; 170 = 'WotLK ICC'; 180 = 'WotLK Ruby Sanctum'
}
if (-not $connus.ContainsKey($Palier)) {
    Write-Host ("{0} n'est pas un palier de l'echelle." -f $Palier) -ForegroundColor Red
    if ($Palier -eq 50) {
        Write-Host 'Le palier 50 a ete retire : les deux Ahn Qiraj sont le meme' -ForegroundColor Yellow
        Write-Host 'palier, le 60. Relance avec -Palier 60.' -ForegroundColor Yellow
    } else {
        Write-Host ('Paliers valides : ' + (($connus.Keys | Sort-Object) -join ', ')) -ForegroundColor Yellow
    }
    Write-Host ''
    exit 1
}
Write-Host ("Palier demande : {0}  ({1})" -f $Palier, $connus[$Palier]) -ForegroundColor Cyan
Write-Host ''

function Trouver-Conf {
    if ($Conf) {
        if (Test-Path $Conf) { return (Resolve-Path $Conf).Path }
        throw "Fichier de configuration introuvable : $Conf"
    }
    $pistes = @(
        (Join-Path $PSScriptRoot '..\..\..\configs\modules\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\env\dist\etc\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\etc\playerbots_bis.conf'),
        (Join-Path $PSScriptRoot '..\..\..\bin\etc\playerbots_bis.conf')
    )
    foreach ($p in $pistes) {
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
    # Aucune des dispositions devinees n'est universelle. Plutot que d'abandonner
    # - ou pire, d'ecrire dans le .conf.dist du depot, qui ne sert a rien au
    # serveur - on fouille la racine sur une profondeur bornee.
    $racine = Join-Path $PSScriptRoot '..\..\..'
    if (Test-Path $racine) {
        $trouve = Get-ChildItem -Path $racine -Filter 'playerbots_bis.conf' `
                    -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
                  Select-Object -First 1
        if ($trouve) { return $trouve.FullName }
    }
    return $null
}

$fichier = Trouver-Conf
if (-not $fichier) {
    Write-Host 'playerbots_bis.conf introuvable.' -ForegroundColor Red
    Write-Host 'Relance avec -Conf "C:\Azerothcore\configs\modules\playerbots_bis.conf"' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Le .conf.dist du depot n est PAS le bon fichier : le serveur ne' -ForegroundColor DarkGray
    Write-Host 'le lit pas, le build se contente de le recopier au premier jet.' -ForegroundColor DarkGray
    Write-Host ''
    exit 1
}
Write-Host ("Fichier : {0}" -f $fichier) -ForegroundColor DarkGray

# Ecrire dans le .dist ne servirait a rien et donnerait l'illusion du contraire.
if ($fichier -like '*.conf.dist') {
    Write-Host ''
    Write-Host 'Ce fichier est un .conf.dist : le serveur ne le lit pas.' -ForegroundColor Red
    Write-Host 'Copie-le en .conf a cote, puis relance.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

$lignes = Get-Content -LiteralPath $fichier
$actuelle = '(absent)'
foreach ($l in $lignes) {
    if ($l -match "^\s*$([regex]::Escape($CLE))\s*=\s*(.*?)\s*$") { $actuelle = $Matches[1]; break }
}

Write-Host ''
Write-Host ("  {0}   {1,10}  ->  {2}" -f $CLE, $actuelle, $Palier) `
    -ForegroundColor $(if ($actuelle -ne [string]$Palier) { 'Yellow' } else { 'DarkGray' })
Write-Host ''

if ($actuelle -eq [string]$Palier) {
    Write-Host 'Deja a cette valeur, rien a faire.' -ForegroundColor Green
    Write-Host ''
    exit 0
}

if (-not $Appliquer) {
    Write-Host 'Relance avec -Appliquer pour ecrire.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

$sortie = New-Object System.Collections.Generic.List[string]
$posee = $false
foreach ($l in $lignes) {
    if (-not $posee -and $l -match "^\s*$([regex]::Escape($CLE))\s*=") {
        $sortie.Add(("{0} = {1}" -f $CLE, $Palier))
        $posee = $true
    } else {
        $sortie.Add($l)
    }
}
# Cle absente du fichier : on l'ajoute plutot que de repartir sans rien faire.
# Un .conf ecrit avant que le reglage existe ne la contient pas, et c'est le cas
# le plus courant apres une mise a jour du module.
if (-not $posee) {
    $sortie.Add('')
    $sortie.Add('####################################################################')
    $sortie.Add('# Palier maximum des bots (tools/changer_le_palier.ps1)')
    $sortie.Add('# La cle etait absente de ce fichier : elle est ajoutee ici.')
    $sortie.Add('####################################################################')
    $sortie.Add(("{0} = {1}" -f $CLE, $Palier))
}

$sauvegarde = "$fichier.avant-palier-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $fichier -Destination $sauvegarde
Write-Host ("sauvegarde : {0}" -f $sauvegarde) -ForegroundColor DarkGray

# UTF-8 SANS BOM : un BOM en tete de .conf fait echouer la lecture de la
# PREMIERE cle du fichier par le lecteur d'AzerothCore, et le symptome est un
# reglage qui "ne marche pas" sans qu'aucune erreur ne soit affichee.
[System.IO.File]::WriteAllLines($fichier, $sortie, (New-Object System.Text.UTF8Encoding $false))

# LA RELECTURE. C'est la seule preuve que l'ecriture a porte.
$relu = '(absent)'
foreach ($l in (Get-Content -LiteralPath $fichier)) {
    if ($l -match "^\s*$([regex]::Escape($CLE))\s*=\s*(.*?)\s*$") { $relu = $Matches[1]; break }
}
Write-Host ''
if ($relu -eq [string]$Palier) {
    Write-Host ("Relu dans le fichier : {0} = {1}" -f $CLE, $relu) -ForegroundColor Green
} else {
    Write-Host ("ECHEC : le fichier contient encore {0}" -f $relu) -ForegroundColor Red
    Write-Host ("L'ancien fichier est en {0}" -f $sauvegarde) -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

Write-Host ''
Write-Host 'Puis, en jeu - le serveur peut rester allume :' -ForegroundColor Yellow
Write-Host '  .playerbotsbis reload' -ForegroundColor White
Write-Host ''
Write-Host 'Elle relit le .conf depuis le disque et ANNONCE le palier obtenu.' -ForegroundColor DarkGray
Write-Host ("Verifie qu'elle dit bien {0}." -f $Palier) -ForegroundColor DarkGray
Write-Host ''
