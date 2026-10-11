<#
.SYNOPSIS
    Reserve les premieres places de connexion aux bots de la guilde.

.DESCRIPTION
    mod-playerbots tire au sort les bots qui se connectent - c'est ecrit dans
    RandomPlayerbotMgr::AddRandomBots :

        // Shuffle for class balance
        std::shuffle(allCharacters.begin(), allCharacters.end(), rng);

    Aucun reglage ne donne la priorite a une guilde. Mais ce tirage ne distribue
    que les places RESTANTES : au demarrage, GetBots() remplit d'abord la liste
    avec les bots qui portent deja une marque "add" en base.

    Le script retire cette marque a tout le monde et la rend aux seuls bots de
    la guilde. Au demarrage suivant ils sont les seuls deja inscrits, donc
    retenus d'office, et le tirage ne fait que completer derriere eux.

    C'est tout le travail de bots_de_guilde_en_premier.sql. Ce script-ci
    n'ajoute qu'une chose, mais elle est indispensable : il VERIFIE QUE LE
    SERVEUR EST ARRETE. Le gestionnaire de randombots reecrit ces lignes a
    chaque tick ; lance a chaud, le script semblerait reussir et serait efface
    dans les vingt secondes.

.PARAMETER Mysql
    Chemin du client mysql.exe. Cherche tout seul s'il est omis.

.PARAMETER Utilisateur
    Defaut acore.

.PARAMETER MotDePasse
    Defaut admin.

.PARAMETER Base
    La base playerbots. Defaut acore_playerbots.

.PARAMETER Force
    Passe outre la verification du serveur arrete. A n'utiliser que si tu es
    certain que worldserver.exe detecte n'est pas celui de ce royaume.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\bots_de_guilde_en_premier.ps1

.NOTES
    Apres coup, tu peux redescendre Playerbots.MaxRandomBots : les bots de la
    guilde ne dependent plus du plafond pour entrer. Moins de bots, demarrage
    plus court, guilde intacte.
#>

[CmdletBinding()]
param(
    [string] $Mysql,
    [string] $Utilisateur = 'acore',
    [string] $MotDePasse  = 'admin',
    [string] $Base        = 'acore_playerbots',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Bots de la guilde prioritaires a la connexion ===' -ForegroundColor Cyan
Write-Host ''

# --- Le serveur doit etre arrete -------------------------------------------
#
# Ce n'est pas une precaution de principe. ProcessBot reecrit ces lignes a
# chaque tick : a chaud, le script afficherait un succes parfaitement faux.
$vivants = @(Get-Process -Name 'worldserver' -ErrorAction SilentlyContinue)
if ($vivants.Count -and -not $Force) {
    Write-Host 'worldserver.exe TOURNE ENCORE :' -ForegroundColor Red
    foreach ($p in $vivants) {
        Write-Host ("  PID {0}, demarre a {1}" -f $p.Id, $p.StartTime) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host 'Arrete-le avant (.server shutdown 30 dans sa console), puis relance.' -ForegroundColor Yellow
    Write-Host 'Lance a chaud, ce script serait efface par le serveur en 20 secondes.' -ForegroundColor Yellow
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
    # Le service nomme le serveur qui tourne, donc le bon dossier bin. Les
    # copies livrees avec les sources de build ne sont pas toujours des
    # executables valides pour cette machine, d'ou le test reel.
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

$sql = Join-Path $PSScriptRoot 'bots_de_guilde_en_premier.sql'
if (-not (Test-Path $sql)) {
    Write-Host ("Introuvable : {0} (git pull ?)" -f $sql) -ForegroundColor Red
    exit 1
}

Write-Host ''
Get-Content -LiteralPath $sql -Raw |
    & $Mysql "-u$Utilisateur" "-p$MotDePasse" $Base --table --default-character-set=utf8mb4

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'La base a refuse. Verifie -Utilisateur / -MotDePasse / -Base.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Dans le tableau 4 ci-dessus, les deux nombres doivent etre EGAUX :' -ForegroundColor Cyan
Write-Host 'autant de lignes add que de bots de la guilde, et rien d autre.' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Tu peux redemarrer le worldserver.' -ForegroundColor Yellow
Write-Host ''
