<#
.SYNOPSIS
    Repare le blocage cause par Min/MaxRandomBotInWorldTime portes trop haut :
    remet les deux reglages, puis leve les interdictions de connexion en base.

.DESCRIPTION
    Symptome qui justifie ce script : apres redemarrage, seuls des bots NIVEAU
    1 se connectent, dans les zones de depart, et en petit nombre. Aucun bot
    equipe, aucun bot de la guilde.

    Quand un randombot se deconnecte, le coeur lui pose un delai de carence :

        SetEventValue(bot, "logout", 1,
                      urand(minRandomBotInWorldTime, maxRandomBotInWorldTime));

    et tryLoginBot refuse tout bot qui en porte un :

        if (GetEventValue(guid, "add") || GetEventValue(guid, "logout") || ...)
            return false;

    Cette ligne est INCONDITIONNELLE - contrairement au "add" voisin, elle ne
    regarde pas EnablePeriodicOnlineOffline. Ces deux reglages ne sont donc
    jamais sans effet : ils fixent la duree pendant laquelle un bot deconnecte
    est interdit de revenir.

    Les porter a 604800 revient a interdire une semaine a tout bot qui se
    deconnecte. A l'arret du serveur, c'est tout le monde. Ne restent eligibles
    que les personnages jamais connectes : les comptes neufs, niveau 1.

    Le script fait les deux moities de la reparation, parce qu'une seule ne
    suffirait pas : lever les interdictions sans corriger les reglages les
    reposerait a la prochaine deconnexion.

.PARAMETER Min
    Nouvelle valeur de Playerbots.MinRandomBotInWorldTime. Defaut 600, la
    valeur d'usine.

.PARAMETER Max
    Nouvelle valeur de Playerbots.MaxRandomBotInWorldTime. Defaut 28800.

.PARAMETER Force
    Passe outre la verification du serveur arrete.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\debloquer_les_bots.ps1

.NOTES
    Redemarrer le worldserver ensuite.
#>

[CmdletBinding()]
param(
    [int]      $Min = 600,
    [int]      $Max = 28800,
    [string]   $Conf,
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore'),
    [string]   $Mysql,
    [string]   $Utilisateur = 'acore',
    [string]   $MotDePasse  = 'admin',
    [string]   $Base        = 'acore_playerbots',
    [switch]   $Force
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Deblocage des bots ===' -ForegroundColor Cyan
Write-Host ''

# --- Le serveur doit etre arrete -------------------------------------------
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
Write-Host 'Serveur arrete. On peut reparer.' -ForegroundColor Green

# --- Moitie 1 : les deux reglages ------------------------------------------
if (-not $Conf) {
    foreach ($r in $Racine) {
        if (-not (Test-Path $r)) { continue }
        $f = Get-ChildItem -Path $r -File -Recurse -Filter 'playerbots.conf' -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -notlike '*.dist' } | Select-Object -First 1
        if ($f) { $Conf = $f.FullName; break }
    }
}
if (-not $Conf -or -not (Test-Path $Conf)) {
    Write-Host 'playerbots.conf introuvable. Relance avec -Conf "C:\chemin\playerbots.conf"' -ForegroundColor Red
    exit 1
}

$voulu = [ordered]@{
    'Playerbots.MinRandomBotInWorldTime' = $Min
    'Playerbots.MaxRandomBotInWorldTime' = $Max
}

$lignes = Get-Content -LiteralPath $Conf
$sortie = New-Object System.Collections.Generic.List[string]
$posees = @{}
$aChanger = 0

foreach ($l in $lignes) {
    $remplacee = $false
    foreach ($c in $voulu.Keys) {
        if ($l -match "^\s*$([regex]::Escape($c))\s*=\s*(.*?)\s*$") {
            if ($Matches[1] -ne [string]$voulu[$c]) {
                Write-Host ("  {0} : {1} -> {2}" -f $c, $Matches[1], $voulu[$c]) -ForegroundColor Yellow
                $aChanger++
            }
            $sortie.Add(("{0} = {1}" -f $c, $voulu[$c]))
            $posees[$c] = $true
            $remplacee = $true
            break
        }
    }
    if (-not $remplacee) { $sortie.Add($l) }
}

foreach ($c in $voulu.Keys) {
    if (-not $posees.ContainsKey($c)) {
        $sortie.Add(("{0} = {1}" -f $c, $voulu[$c]))
        Write-Host ("  {0} : (absent) -> {1}" -f $c, $voulu[$c]) -ForegroundColor Yellow
        $aChanger++
    }
}

if ($aChanger) {
    $sauvegarde = "$Conf.avant-deblocage-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $Conf -Destination $sauvegarde
    [System.IO.File]::WriteAllLines($Conf, $sortie, (New-Object System.Text.UTF8Encoding $false))
    Write-Host ("Configuration corrigee ({0}). Sauvegarde : {1}" -f $Conf, $sauvegarde) -ForegroundColor Green
}
else {
    Write-Host 'Configuration deja correcte, rien a ecrire.' -ForegroundColor DarkGray
}
Write-Host ''

# --- Moitie 2 : les interdictions en base ----------------------------------
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

$sql = Join-Path $PSScriptRoot 'debloquer_les_bots.sql'
if (-not (Test-Path $sql)) {
    Write-Host ("Introuvable : {0} (git pull ?)" -f $sql) -ForegroundColor Red
    exit 1
}

Get-Content -LiteralPath $sql -Raw |
    & $Mysql "-u$Utilisateur" "-p$MotDePasse" $Base --table --default-character-set=utf8mb4

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'La base a refuse. Verifie -Utilisateur / -MotDePasse / -Base.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Dans le tableau 3, interdictions_restantes doit valoir 0,' -ForegroundColor Cyan
Write-Host 'et dont_la_guilde doit retrouver tes bots reserves.' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Tu peux redemarrer le worldserver.' -ForegroundColor Yellow
Write-Host ''
