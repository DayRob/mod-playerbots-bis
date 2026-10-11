<#
.SYNOPSIS
    Force la remise a niveau des bots restes sous le plancher apres un
    changement de Playerbots.RandomBotMinLevel.

.DESCRIPTION
    Changer RandomBotMinLevel ne touche pas les bots existants : le niveau
    n'est tire qu'a la randomisation, et la suivante est programmee entre 2
    heures et QUATORZE JOURS plus tard. Un bot tire au niveau 1 sous l'ancien
    reglage peut donc y rester deux semaines.

    Le coeur reprogramme une randomisation des qu'il n'en trouve plus :

        if (!GetEventValue(botId, "randomize"))
            ScheduleRandomize(bot, randomTime);   // quelques secondes

    Effacer la minuterie d'un bot revient donc a lui dire : refais-toi
    maintenant.

    SERVEUR ARRETE OBLIGATOIREMENT. GetEventValue lit un cache memoire, pas la
    base : a chaud, l'effacement serait sans effet jusqu'au redemarrage, et le
    serveur reecrirait les lignes par-dessus.

    Ne touche ni au stuff, ni a la guilde, ni aux marques "add" reservees -
    verifie sur banc d'essai. Les personnages de joueur sont epargnes : le
    filtre ne retient que les comptes rndbot.

.PARAMETER Plancher
    Niveau en dessous duquel un bot est remis a niveau. Mets-y ton
    Playerbots.RandomBotMinLevel. Defaut 60.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\remettre_a_niveau_les_bots.ps1 -Plancher 60
#>

[CmdletBinding()]
param(
    [int]    $Plancher    = 60,
    [string] $Mysql,
    [string] $Utilisateur = 'acore',
    [string] $MotDePasse  = 'admin',
    [string] $Base        = 'acore_playerbots',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Remise a niveau des bots sous le plancher ===' -ForegroundColor Cyan
Write-Host ''

$vivants = @(Get-Process -Name 'worldserver' -ErrorAction SilentlyContinue)
if ($vivants.Count -and -not $Force) {
    Write-Host 'worldserver.exe TOURNE ENCORE :' -ForegroundColor Red
    foreach ($p in $vivants) {
        Write-Host ("  PID {0}, demarre a {1}" -f $p.Id, $p.StartTime) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host 'Arrete-le avant (.server shutdown 30), puis relance.' -ForegroundColor Yellow
    Write-Host 'GetEventValue lit un cache memoire : a chaud ce script est sans effet.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}
Write-Host 'Serveur arrete. On peut ecrire.' -ForegroundColor Green

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

$sql = Join-Path $PSScriptRoot 'remettre_a_niveau_les_bots.sql'
if (-not (Test-Path $sql)) {
    Write-Host ("Introuvable : {0} (git pull ?)" -f $sql) -ForegroundColor Red
    exit 1
}

Write-Host ("Plancher : niveau {0}" -f $Plancher) -ForegroundColor DarkGray
Write-Host ''

((Get-Content -LiteralPath $sql -Raw) -replace 'SET @plancher := \d+;', "SET @plancher := $Plancher;") |
    & $Mysql "-u$Utilisateur" "-p$MotDePasse" $Base --table --default-character-set=utf8mb4

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'La base a refuse. Verifie -Utilisateur / -MotDePasse / -Base.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Au redemarrage, ces bots se referont dans les secondes qui suivent' -ForegroundColor Cyan
Write-Host 'leur connexion, avec le plancher actuel.' -ForegroundColor Cyan
Write-Host ''
