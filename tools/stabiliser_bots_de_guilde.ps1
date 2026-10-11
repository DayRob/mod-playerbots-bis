<#
.SYNOPSIS
    Arrete la rotation des randombots, pour que les bots de la guilde restent
    connectes.

.DESCRIPTION
    Symptome qui justifie ce script : sur 40 bots de guilde, 34 sont en ligne,
    et ce ne sont pas toujours les memes. Les absents ne sont pas tombes en
    panne - ils ont fini leur temps.

    mod-playerbots donne a chaque randombot une DUREE DE VIE EN LIGNE :

        Playerbots.MinRandomBotInWorldTime =   600   (10 minutes)
        Playerbots.MaxRandomBotInWorldTime = 28800   (8 heures)

    Passe ce delai, le bot se deconnecte et un autre prend sa place. Mais
    l'appartenance a une guilde n'entre pas dans le tirage du remplacant.

    ATTENTION, ET C'EST LE PIEGE DE CE SCRIPT : ces deux reglages ne servent
    QUE si Playerbots.EnablePeriodicOnlineOffline vaut 1. Le coeur en decide
    ainsi, dans RandomPlayerbotMgr::AddRandomBots :

        uint32 add_time = enablePeriodicOnlineOffline
                            ? urand(minRandomBotInWorldTime, maxRandomBotInWorldTime)
                            : permanentlyInWorldTime;

    A 0 - le defaut - c'est Playerbots.PermanentlyInWorldTime qui s'applique,
    soit un an, soit deja l'absence de rotation. Ecrire Min/Max dans ce cas ne
    change strictement rien, et le log du serveur le montre : les lignes
    INSERT INTO playerbots_random_bots portent validIn = 31104000.

    Le script verifie donc EnablePeriodicOnlineOffline et le dit en clair
    plutot que de laisser croire a un effet qu'il n'a pas. Pour garantir la
    presence des bots de la guilde quelle que soit la rotation, c'est
    bots_de_guilde_en_premier.ps1 qu'il faut, pas celui-ci.

    Deux reglages suffisent a l'arreter, mais ils doivent etre faits ENSEMBLE :

      - allonger la duree de vie en ligne, sinon la rotation continue ;
      - monter le plafond au niveau du vivier, sinon les absents du moment
        restent dehors pour toujours - on aurait fige le probleme au lieu de
        le resoudre.

    Le script fait les deux, sauvegarde avant d'ecrire, et sait revenir en
    arriere si la charge ne passe pas.

.PARAMETER Bots
    Le plafond de bots connectes. Mets-y la taille de ton vivier, que donne la
    requete 3 de qui_manque_a_la_guilde.sql (colonne personnages_rndbot).

.PARAMETER Duree
    Duree de vie en ligne, en secondes. Defaut 604800 (une semaine), soit en
    pratique plus aucune rotation.

.PARAMETER Conf
    Le playerbots.conf du serveur. Trouve tout seul s'il est omis.

.PARAMETER Restaurer
    Remet la derniere sauvegarde faite par ce script, et ne change rien d'autre.
    C'est la sortie de secours si le serveur rame avec plus de bots.

.EXAMPLE
    Voir les valeurs actuelles sans rien changer :
    powershell -ExecutionPolicy Bypass -File .\tools\stabiliser_bots_de_guilde.ps1

.EXAMPLE
    Appliquer, avec un vivier de 1060 :
    powershell -ExecutionPolicy Bypass -File .\tools\stabiliser_bots_de_guilde.ps1 -Bots 1060 -Appliquer

.EXAMPLE
    Revenir en arriere :
    powershell -ExecutionPolicy Bypass -File .\tools\stabiliser_bots_de_guilde.ps1 -Restaurer

.NOTES
    Redemarrer le worldserver ensuite. Un .reload config ne recharge pas la
    population de bots.
#>

[CmdletBinding()]
param(
    [int]      $Bots = 0,
    [int]      $Duree = 604800,
    [string]   $Conf,
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore'),
    [switch]   $Appliquer,
    [switch]   $Restaurer
)

$ErrorActionPreference = 'Stop'
$MARQUE = '.avant-stabilisation-'

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

Write-Host ''
Write-Host '=== Stabilisation des bots de guilde ===' -ForegroundColor Cyan
Write-Host ("Fichier : {0}" -f $Conf)
Write-Host ''

# --- Retour en arriere -----------------------------------------------------
if ($Restaurer) {
    $sauvegardes = Get-ChildItem -Path (Split-Path $Conf) -File -Filter "*$MARQUE*" |
                   Sort-Object LastWriteTime -Descending
    if (-not $sauvegardes) {
        Write-Host 'Aucune sauvegarde de ce script a restaurer.' -ForegroundColor Red
        exit 1
    }
    $src = $sauvegardes[0].FullName
    Copy-Item -LiteralPath $src -Destination $Conf -Force
    Write-Host ("Restaure depuis : {0}" -f $src) -ForegroundColor Green
    Write-Host 'Redemarre le worldserver.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

# --- Ce qu'on veut poser ---------------------------------------------------
$voulu = [ordered]@{
    'Playerbots.MinRandomBotInWorldTime' = $Duree
    'Playerbots.MaxRandomBotInWorldTime' = $Duree
}
if ($Bots -gt 0) {
    $voulu['Playerbots.MinRandomBots'] = $Bots
    $voulu['Playerbots.MaxRandomBots'] = $Bots
}

$lignes = Get-Content -LiteralPath $Conf

Write-Host 'Avant / apres :' -ForegroundColor Cyan
Write-Host ''
$large = 0
foreach ($c in $voulu.Keys) { if ($c.Length -gt $large) { $large = $c.Length } }
$aChanger = 0
foreach ($c in $voulu.Keys) {
    $actuelle = '(absent)'
    foreach ($l in $lignes) {
        if ($l -match "^\s*$([regex]::Escape($c))\s*=\s*(.*?)\s*$") { $actuelle = $Matches[1]; break }
    }
    $change = ($actuelle -ne [string]$voulu[$c])
    if ($change) { $aChanger++ }
    $couleur = if ($change) { 'Yellow' } else { 'DarkGray' }
    Write-Host ("  {0,-$large}   {1,12}  ->  {2}" -f $c, $actuelle, $voulu[$c]) -ForegroundColor $couleur
}
Write-Host ''

# La duree de vie en ligne n'est lue que sous EnablePeriodicOnlineOffline = 1.
# Le dire ici evite de croire a un effet qui n'aura pas lieu.
$periodique = $null
foreach ($l in $lignes) {
    if ($l -match '^\s*Playerbots\.EnablePeriodicOnlineOffline\s*=\s*(.*?)\s*$') { $periodique = $Matches[1]; break }
}
if ($periodique -ne '1') {
    $vu = if ($null -eq $periodique) { 'absent, donc 0 par defaut' } else { $periodique }
    Write-Host ("Playerbots.EnablePeriodicOnlineOffline = {0}" -f $vu) -ForegroundColor Yellow
    Write-Host 'Les deux Min/MaxRandomBotInWorldTime ci-dessus SERONT IGNORES :' -ForegroundColor Yellow
    Write-Host 'a 0, le coeur applique Playerbots.PermanentlyInWorldTime (un an).' -ForegroundColor Yellow
    Write-Host 'Pour garantir les bots de la guilde, utilise plutot :' -ForegroundColor Yellow
    Write-Host '  .\tools\bots_de_guilde_en_premier.ps1' -ForegroundColor Yellow
    Write-Host ''
}

if ($Bots -eq 0) {
    Write-Host 'ATTENTION : sans -Bots, le plafond n est pas touche.' -ForegroundColor Red
    Write-Host 'Arreter la rotation SANS monter le plafond fige les absents dehors' -ForegroundColor Red
    Write-Host 'pour de bon. Relance avec -Bots <taille de ton vivier>.' -ForegroundColor Red
    Write-Host ''
}

if (-not $Appliquer) {
    Write-Host 'RAPPORT SEUL - rien n a ete modifie.' -ForegroundColor Yellow
    Write-Host 'Relance avec -Appliquer pour ecrire.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

# Rien a changer : on s'arrete AVANT de sauvegarder.
#
# Ce n'est pas une economie, c'est une correction. Une sauvegarde du fichier
# deja modifie deviendrait la plus recente, et -Restaurer rendrait alors l'etat
# modifie au lieu de l'original - exactement au moment ou on en a besoin.
if ($aChanger -eq 0) {
    Write-Host 'Les quatre reglages sont deja en place. Rien a ecrire.' -ForegroundColor Green
    Write-Host 'La sauvegarde d origine est conservee intacte.' -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

# --- Ecriture --------------------------------------------------------------
#
# Une cle presente est remplacee sur place, pour que le commentaire qui la
# precede reste au-dessus d'elle. Une cle absente est ajoutee a la fin, sous
# un titre qui dit d'ou elle vient : dans un fichier de 890 lignes, un reglage
# sans explication est un reglage qu'on ne saura plus justifier dans six mois.
$sortie = New-Object System.Collections.Generic.List[string]
$posees = @{}

foreach ($l in $lignes) {
    $remplacee = $false
    foreach ($c in $voulu.Keys) {
        if ($l -match "^\s*$([regex]::Escape($c))\s*=") {
            $sortie.Add(("{0} = {1}" -f $c, $voulu[$c]))
            $posees[$c] = $true
            $remplacee = $true
            break
        }
    }
    if (-not $remplacee) { $sortie.Add($l) }
}

$manquantes = @($voulu.Keys | Where-Object { -not $posees.ContainsKey($_) })
if ($manquantes.Count) {
    $sortie.Add('')
    $sortie.Add('####################################################################')
    $sortie.Add('# Stabilisation des bots de guilde (tools/stabiliser_bots_de_guilde.ps1)')
    $sortie.Add('#')
    $sortie.Add('# Duree de vie en ligne allongee : un randombot ne se deconnecte plus')
    $sortie.Add('# au bout de 10 min a 8 h pour ceder sa place a un autre. Le plafond')
    $sortie.Add('# est monte au niveau du vivier dans le meme geste, sans quoi les bots')
    $sortie.Add('# hors ligne au moment du changement le resteraient pour toujours.')
    $sortie.Add('####################################################################')
    foreach ($c in $manquantes) { $sortie.Add(("{0} = {1}" -f $c, $voulu[$c])) }
}

$sauvegarde = "$Conf$MARQUE$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $Conf -Destination $sauvegarde
Write-Host ("Sauvegarde : {0}" -f $sauvegarde) -ForegroundColor DarkGray

[System.IO.File]::WriteAllLines($Conf, $sortie, (New-Object System.Text.UTF8Encoding $false))

Write-Host ("{0} reglages poses ({1} remplaces, {2} ajoutes)." -f `
    $voulu.Count, ($voulu.Count - $manquantes.Count), $manquantes.Count) -ForegroundColor Green
Write-Host ''
Write-Host 'REDEMARRE le worldserver maintenant.' -ForegroundColor Yellow
Write-Host 'Si le serveur rame avec plus de bots :' -ForegroundColor DarkGray
Write-Host '  .\tools\stabiliser_bots_de_guilde.ps1 -Restaurer' -ForegroundColor DarkGray
Write-Host ''
