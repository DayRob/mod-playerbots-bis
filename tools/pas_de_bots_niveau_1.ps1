<#
.SYNOPSIS
    Ecarte du vivier les comptes de bots fraichement crees, dont les
    personnages sont encore au niveau 1.

.DESCRIPTION
    Monter Playerbots.MaxRandomBots fait creer des comptes supplementaires.
    Redescendre le plafond ne les reprend pas : le module n'a aucune branche
    qui desassigne quand on repasse en dessous. Les personnages neufs restent
    candidats, et comme ils naissent au niveau 1, ils peuplent le monde de bots
    niveau 1 qu'on n'a jamais demandes.

    Rien n'est supprime ici. Le module range ses comptes dans
    playerbots_account_type (1 = vivier, 2 = addclass, 0 = ignore) et ne
    remplit rndBotTypeAccounts qu'avec le type 1. Remettre les comptes neufs a
    0 les met hors circuit sans toucher a un seul personnage, et se defait en
    remettant 1.

    Deux garde-fous sont en dur dans le SQL : un compte portant un membre de la
    guilde n'est jamais ecarte, et les comptes addclass ne sont pas touches.

.PARAMETER Plafond
    Le Playerbots.MaxRandomBots que tu comptes utiliser ensuite. Sert au
    controle final : si trop peu de comptes restent, le prochain demarrage les
    reassignerait, et le script te le dit.

.PARAMETER Seuil
    Niveau maximum d'un compte pour etre juge neuf. Defaut 1, soit les comptes
    dont aucun personnage n'a jamais joue.

.PARAMETER Force
    Passe outre la verification du serveur arrete.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\pas_de_bots_niveau_1.ps1 -Plafond 500

.NOTES
    A faire AVANT de redescendre le plafond, puis redemarrer le worldserver.
#>

[CmdletBinding()]
param(
    [int]    $Plafond     = 500,
    [int]    $Seuil       = 1,
    [string] $Mysql,
    [string] $Utilisateur = 'acore',
    [string] $MotDePasse  = 'admin',
    [string] $Base        = 'acore_playerbots',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Ecarter les comptes de bots neufs (niveau 1) ===' -ForegroundColor Cyan
Write-Host ''

# --- Le serveur doit etre arrete -------------------------------------------
#
# L'assignation des types de comptes se fait au demarrage : a chaud, ce qu'on
# ecrit ici serait recouvert sans prevenir.
$vivants = @(Get-Process -Name 'worldserver' -ErrorAction SilentlyContinue)
if ($vivants.Count -and -not $Force) {
    Write-Host 'worldserver.exe TOURNE ENCORE :' -ForegroundColor Red
    foreach ($p in $vivants) {
        Write-Host ("  PID {0}, demarre a {1}" -f $p.Id, $p.StartTime) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host 'Arrete-le avant (.server shutdown 30), puis relance.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}
if ($vivants.Count) {
    Write-Host ('-Force : on continue malgre {0} worldserver.exe en vie.' -f $vivants.Count) -ForegroundColor Yellow
}
else {
    Write-Host 'Serveur arrete. On peut ecrire.' -ForegroundColor Green
}

# --- Le client mysql -------------------------------------------------------
function Essayer-Client {
    param([string] $chemin)
    if (-not (Test-Path $chemin)) { return $false }
    $sauve = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $v = (& $chemin --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $v -match 'Ver\s') { return $true }
    } catch { }
    finally { $ErrorActionPreference = $sauve }
    return $false
}

if ($Mysql -and -not (Essayer-Client $Mysql)) {
    Write-Host ("Le client donne ne s execute pas : {0}" -f $Mysql) -ForegroundColor Red
    exit 1
}

if (-not $Mysql) {
    $candidats = @()
    foreach ($svc in (Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -match 'mysql|mariadb' })) {
        if ($svc.PathName -match '"?([A-Za-z]:\\[^"]*?\\bin)\\[^\\"]*\.exe') {
            $candidats += (Join-Path $Matches[1] 'mysql.exe')
            $candidats += (Join-Path $Matches[1] 'mariadb.exe')
        }
    }
    $candidats += Get-ChildItem 'C:\Program Files','C:\Program Files (x86)' `
                    -Directory -Recurse -Filter 'bin' -ErrorAction SilentlyContinue |
                  ForEach-Object { Join-Path $_.FullName 'mysql.exe'; Join-Path $_.FullName 'mariadb.exe' }

    foreach ($c in ($candidats | Select-Object -Unique)) {
        if (Essayer-Client $c) { $Mysql = $c; break }
    }
}

if (-not $Mysql) {
    Write-Host 'Aucun client mysql utilisable. Relance avec -Mysql "C:\...\mysql.exe"' -ForegroundColor Red
    exit 1
}
Write-Host ("Client MySQL : {0}" -f $Mysql) -ForegroundColor DarkGray

$sql = Join-Path $PSScriptRoot 'pas_de_bots_niveau_1.sql'
if (-not (Test-Path $sql)) {
    Write-Host ("Introuvable : {0} (git pull ?)" -f $sql) -ForegroundColor Red
    exit 1
}

# Les deux variables du SQL sont posees ici plutot que laissees a leur valeur
# ecrite : le controle final n'a de sens que compare au plafond REEL que tu
# comptes utiliser.
$texte = (Get-Content -LiteralPath $sql -Raw) `
         -replace 'SET @seuil := \d+;',   "SET @seuil := $Seuil;" `
         -replace 'SET @plafond := \d+;', "SET @plafond := $Plafond;"

Write-Host ("Seuil : niveau <= {0}   Plafond vise : {1}" -f $Seuil, $Plafond) -ForegroundColor DarkGray
Write-Host ''

$texte | & $Mysql "-u$Utilisateur" "-p$MotDePasse" $Base --table --default-character-set=utf8mb4

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'La base a refuse. Verifie -Utilisateur / -MotDePasse / -Base.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Lis le verdict du tableau 4 avant de redemarrer.' -ForegroundColor Cyan
Write-Host ''
