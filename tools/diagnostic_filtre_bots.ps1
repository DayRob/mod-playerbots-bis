<#
.SYNOPSIS
    Dit pourquoi des bots niveau 1 se connectent encore malgre le filtre.

.DESCRIPTION
    Trois causes possibles, et elles demandent des reponses opposees :

      1. le module n'a pas ete recompile - BisBotGate.cpp est du C++, un
         git pull ne suffit pas ;
      2. il l'a ete, mais PlayerbotsBis.MinBotLevel manque au fichier de
         configuration, donc le filtre reste a 0 (desactive) ;
      3. tout est en place et le filtre travaille - les bots vus etaient deja
         connectes avant, ou le serveur n'a pas redemarre depuis.

    Elles se distinguent a un detail que le journal donne gratuitement.
    AzerothCore se plaint d'un reglage qu'un module LUI DEMANDE et qu'il ne
    trouve pas :

        Config: Missing property PlayerbotsBis.MinBotLevel ...

    Ce message ne peut sortir que d'un binaire qui connait le reglage. Sa
    presence prouve donc la recompilation, et son absence - combinee a celle du
    reglage dans le fichier - prouve le contraire. On lit une cause dans ce que
    le serveur dit de lui-meme, au lieu de la supposer.

    Le script ne modifie rien.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\diagnostic_filtre_bots.ps1
#>

[CmdletBinding()]
param(
    [string]   $Conf,
    [string]   $Logs = 'C:\Azerothcore\logs',
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore')
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Pourquoi des bots niveau 1 passent encore ===' -ForegroundColor Cyan
Write-Host ''

# --- 1. Le fichier de configuration du module ------------------------------
if (-not $Conf) {
    foreach ($r in $Racine) {
        if (-not (Test-Path $r)) { continue }
        $f = Get-ChildItem -Path $r -File -Recurse -Filter 'playerbots_bis.conf' -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -notlike '*.dist' } | Select-Object -First 1
        if ($f) { $Conf = $f.FullName; break }
    }
}

$reglagePose = $false
$valeur = '(fichier introuvable)'
if ($Conf -and (Test-Path $Conf)) {
    Write-Host ("Configuration : {0}" -f $Conf) -ForegroundColor DarkGray
    $valeur = '(absent)'
    foreach ($l in (Get-Content -LiteralPath $Conf)) {
        if ($l -match '^\s*PlayerbotsBis\.MinBotLevel\s*=\s*(.*?)\s*$') { $valeur = $Matches[1]; break }
    }
    $reglagePose = ($valeur -match '^\d+$' -and [int]$valeur -gt 0)
}
else {
    Write-Host 'playerbots_bis.conf INTROUVABLE' -ForegroundColor Red
}
Write-Host ("  PlayerbotsBis.MinBotLevel = {0}" -f $valeur) `
    -ForegroundColor $(if ($reglagePose) { 'Green' } else { 'Red' })
Write-Host ''

# --- 2. Ce que le serveur dit de lui-meme ----------------------------------
$journaux = @()
if (Test-Path $Logs) {
    $journaux = @(Get-ChildItem -Path $Logs -File -Filter '*.log' -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 5)
}
if (-not $journaux.Count) {
    Write-Host ("Aucun journal sous {0} - relance avec -Logs <dossier>" -f $Logs) -ForegroundColor Red
    Write-Host ''
    exit 1
}
Write-Host ("Journaux lus : {0}" -f ($journaux.Name -join ', ')) -ForegroundColor DarkGray

function Chercher {
    param([string] $Motif)
    return @(Select-String -Path $journaux.FullName -Pattern $Motif -ErrorAction SilentlyContinue)
}

# Ce message ne peut venir que d'un binaire qui connait le reglage : c'est la
# preuve de recompilation, et elle ne coute rien a obtenir.
$seReclame  = (Chercher 'Missing property PlayerbotsBis\.MinBotLevel').Count -gt 0
$aDemarre   = (Chercher '\[mod-playerbots-bis\] Active').Count -gt 0
$aExpulse   = (Chercher '\[mod-playerbots-bis\].*deconnecte')

Write-Host ''
Write-Host ("  module charge au demarrage      : {0}" -f $(if ($aDemarre) { 'oui' } else { 'NON' })) `
    -ForegroundColor $(if ($aDemarre) { 'Green' } else { 'Red' })
Write-Host ("  binaire connait MinBotLevel     : {0}" -f $(if ($seReclame -or $reglagePose) { 'probable' } else { 'NON - pas recompile' })) `
    -ForegroundColor $(if ($seReclame -or $reglagePose) { 'Green' } else { 'Red' })
Write-Host ("  expulsions enregistrees         : {0}" -f $aExpulse.Count) `
    -ForegroundColor $(if ($aExpulse.Count) { 'Green' } else { 'Yellow' })
Write-Host ''

if ($aExpulse.Count) {
    Write-Host 'Dernieres expulsions :' -ForegroundColor Cyan
    $aExpulse | Select-Object -Last 5 | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) -ForegroundColor DarkGray }
    Write-Host ''
}

# --- 3. Le verdict ---------------------------------------------------------
Write-Host 'VERDICT' -ForegroundColor Cyan
if (-not $aDemarre) {
    Write-Host '  Le module ne se charge pas. Rien d autre ne peut marcher.' -ForegroundColor Red
}
elseif (-not $reglagePose -and -not $seReclame) {
    Write-Host '  Le binaire ignore PlayerbotsBis.MinBotLevel : IL FAUT RECOMPILER.' -ForegroundColor Red
    Write-Host '  BisBotGate.cpp est du C++ ; un git pull ne suffit pas.' -ForegroundColor Red
}
elseif (-not $reglagePose) {
    Write-Host '  Recompile, mais le reglage est absent ou a 0 : le filtre dort.' -ForegroundColor Red
    Write-Host '  .\tools\population_des_bots.ps1 -Bots 500 -Appliquer' -ForegroundColor Yellow
}
elseif (-not $aExpulse.Count) {
    Write-Host '  Tout est en place, mais aucune expulsion enregistree.' -ForegroundColor Yellow
    Write-Host '  Soit le serveur n a pas redemarre depuis, soit aucun bot sous le' -ForegroundColor Yellow
    Write-Host '  plancher ne s est presente - les niveau 1 vus etaient deja la.' -ForegroundColor Yellow
}
else {
    Write-Host '  Le filtre travaille. Les bots niveau 1 encore visibles etaient' -ForegroundColor Green
    Write-Host '  connectes avant lui : ils partiront a leur prochaine deconnexion.' -ForegroundColor Green
}
Write-Host ''
