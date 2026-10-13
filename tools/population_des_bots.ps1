<#
.SYNOPSIS
    Interdit aux bots niveau 1 et aux chevaliers de la mort de se connecter.

.DESCRIPTION
    Deux regles, deux reglages, et ils existaient deja : ils etaient seulement
    ignores tant que playerbots.conf portait l'ancien prefixe.

      Playerbots.DisableDeathKnightLogin = 1
          tryLoginBot refuse la connexion, c'est ecrit dans le coeur :

              if (... || (disableDeathKnightLogin && rClass == CLASS_DEATH_KNIGHT))
                  return false;

      Playerbots.RandomBotMinLevel = <Niveau>
          Le niveau plancher de TOUT tirage. A 1 - le reglage par defaut - un
          bot peut etre tire au niveau 1 a chaque randomisation, et c'est la
          source permanente des bots niveau 1 qu'on croit voir apparaitre.

          Le defaut de ce script est 3, et non 60. Un plancher a 60 supprime
          bien les niveau 1, mais il vide aussi le monde : plus un seul bot de
          bas niveau nulle part, et la population finit uniformement au niveau
          maximum. Un serveur ou des bots montent en niveau perd ce qui le
          rendait vivant.

          A 3, seuls les deux niveaux degeneres disparaissent. Un bot niveau 45
          qui a grind reste un bot niveau 45.

    Le plafond de population est regle au passage, parce qu'il ne faut PAS le
    monter : un plafond plus haut fait creer des comptes, donc des personnages
    neufs, donc exactement les bots niveau 1 qu'on veut eviter.

    Ce que ce script ne fait pas : supprimer les personnages niveau 1 qui
    existent deja. Ils se mettront a niveau a leur prochaine randomisation.
    Pour les sortir du vivier tout de suite, c'est pas_de_bots_niveau_1.ps1.

.PARAMETER Niveau
    Niveau plancher des bots. Defaut 3 : seuls les niveaux 1 et 2 sont
    refuses, le reste de la population garde ses niveaux.

.PARAMETER Bots
    Playerbots.MinRandomBots et MaxRandomBots. 0 pour ne pas y toucher.

.PARAMETER Cadence
    Playerbots.RandomBotsPerInterval : nombre de bots traites par cycle du
    gestionnaire (connexion, deconnexion, mise a jour confondues). Defaut du
    coeur 60. 0 pour ne pas y toucher.

    Monter a 200 multiplie le debit de connexion par un peu plus de trois, au
    prix d'un pic de travail plus gros a chaque cycle. Au-dela, le serveur
    passe son temps dans ce traitement et le jeu saccade.

.PARAMETER Guilde
    PlayerbotsBis.VipGuildId : la guilde dont les bots passent devant tout le
    monde a la connexion. 0 pour ne pas y toucher.

    Rend bots_de_guilde_en_premier.ps1 inutile : le module refait le travail a
    chaque demarrage, au lieu de dependre d'un script lance a la main et dont
    l'effet s'efface au redemarrage suivant.

.PARAMETER Intervalle
    Playerbots.RandomBotUpdateInterval : duree du cycle du gestionnaire, en
    secondes. Defaut du coeur 20. 0 pour ne pas y toucher.

    A 10 le remplissage va deux fois plus vite une fois le turbo de demarrage
    termine. Mais ce reglage ne concerne pas que les connexions : il fait
    retraiter chaque bot deja en ligne aussi souvent, en permanence. Descendre
    sous 10 coute cher pour un gain qui ne se voit qu'a la fin du remplissage.

.PARAMETER AvecDK
    Laisse les chevaliers de la mort se connecter. Par defaut ils sont exclus.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tools\population_des_bots.ps1 -Bots 500 -Appliquer

.NOTES
    Redemarrer le worldserver ensuite. Un .reload config ne suffit pas.

    ATTENTION : -Niveau 60 ne laisse plus un seul bot de bas niveau sur le
    serveur. Les zones de depart se vident et la population s'uniformise. Ne le
    demande que si c'est vraiment ce que tu veux.
#>

[CmdletBinding()]
param(
    [int]      $Niveau = 3,
    [int]      $Cadence = 0,
    [int]      $Intervalle = 0,
    [int]      $Guilde = 0,
    [int]      $Bots   = 0,
    [switch]   $AvecDK,
    [string]   $Conf,
    [string[]] $Racine = @('C:\Azerothcore', 'C:\AzerothCore', 'C:\azerothcore'),
    [switch]   $Appliquer
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=== Population des bots : ni niveau 1, ni chevalier de la mort ===' -ForegroundColor Cyan
Write-Host ''

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
Write-Host ("Fichier : {0}" -f $Conf)
Write-Host ''

$voulu = [ordered]@{
    'Playerbots.RandomBotMinLevel'       = $Niveau
    'Playerbots.DisableDeathKnightLogin' = $(if ($AvecDK) { 0 } else { 1 })
}

# Les deux reglages de mod-playerbots-bis vont dans SON fichier, pas dans
# playerbots.conf : un module ne lit que le sien. Ils doublent les deux
# ci-dessus et tiennent meme si ceux-la sont perdus - c'est tout leur interet.
$vouluBis = [ordered]@{
    'PlayerbotsBis.MinBotLevel'       = $Niveau
    'PlayerbotsBis.BlockDeathKnights' = $(if ($AvecDK) { 0 } else { 1 })
}
if ($Guilde -gt 0) {
    $vouluBis['PlayerbotsBis.VipGuildId'] = $Guilde
}
if ($Bots -gt 0) {
    $voulu['Playerbots.MinRandomBots'] = $Bots
    $voulu['Playerbots.MaxRandomBots'] = $Bots
}

# Le debit de connexion. Le coeur partage ce budget entre mettre a jour les
# bots deja la et en connecter de nouveaux :
#
#     updateBots = randomBotsPerInterval * onlineBotFocus / 100;
#     loginBots  = randomBotsPerInterval - updateBots;
#
# onlineBotFocus vaut 25 tant que la population est sous 90 % de MinRandomBots,
# puis 75. Le gros du budget va donc aux connexions pendant le remplissage, et
# bascule vers l'entretien une fois plein - ce qui est le bon arbitrage, mais
# rend la fin du remplissage lente.
#
# Monter ce nombre accelere les deux. Le cout est un pic de travail plus gros a
# chaque cycle : c'est un echange entre debit et a-coups, pas un gain gratuit.
if ($Cadence -gt 0) {
    $voulu['Playerbots.RandomBotsPerInterval'] = $Cadence
}

# La duree du cycle. Elle sort de cette ligne :
#
#     SetNextCheckDelay(updateIntervalTurboBoost * (onlineBotFocus + 25) * 10);
#
# soit, hors turbo et pendant le remplissage, randomBotUpdateInterval * 500 ms.
# A 20 le cycle dure 10 secondes ; a 5, deux secondes et demie.
#
# MAIS CE N'EST PAS UN REGLAGE DE CONNEXION. C'est la cadence de TOUT le
# gestionnaire : baisser ce nombre fait aussi retraiter chaque bot deja connecte
# quatre fois plus souvent, pour toujours, pas seulement au demarrage. Le cout
# ne disparait pas une fois la population remplie.
#
# Et il ne change rien au demarrage lui-meme : pendant le turbo le coeur force
# deja la valeur a 1, quoi qu'on ait ecrit ici.
if ($Intervalle -gt 0) {
    $voulu['Playerbots.RandomBotUpdateInterval'] = $Intervalle
}

# Deux fichiers, deux jeux de reglages, et la meme mecanique : on factorise
# plutot que de la dupliquer, parce qu'une copie se corrige a moitie.
function Appliquer-Reglages {
    param(
        [string] $Fichier,
        [System.Collections.Specialized.OrderedDictionary] $Voulu,
        [string] $Titre,
        [bool]   $Ecrire
    )

    if (-not (Test-Path $Fichier)) {
        Write-Host ("  {0} : fichier absent, ignore" -f $Fichier) -ForegroundColor DarkGray
        return 0
    }

    $lignes = Get-Content -LiteralPath $Fichier
    $large = 0
    foreach ($c in $Voulu.Keys) { if ($c.Length -gt $large) { $large = $c.Length } }

    $aChanger = 0
    foreach ($c in $Voulu.Keys) {
        $actuelle = '(absent)'
        foreach ($l in $lignes) {
            if ($l -match "^\s*$([regex]::Escape($c))\s*=\s*(.*?)\s*$") { $actuelle = $Matches[1]; break }
        }
        $change = ($actuelle -ne [string]$Voulu[$c])
        if ($change) { $aChanger++ }
        Write-Host ("  {0,-$large}   {1,10}  ->  {2}" -f $c, $actuelle, $Voulu[$c]) `
            -ForegroundColor $(if ($change) { 'Yellow' } else { 'DarkGray' })
    }

    if (-not $Ecrire -or $aChanger -eq 0) { return $aChanger }

    $sortie = New-Object System.Collections.Generic.List[string]
    $posees = @{}
    foreach ($l in $lignes) {
        $remplacee = $false
        foreach ($c in $Voulu.Keys) {
            if ($l -match "^\s*$([regex]::Escape($c))\s*=") {
                $sortie.Add(("{0} = {1}" -f $c, $Voulu[$c]))
                $posees[$c] = $true
                $remplacee = $true
                break
            }
        }
        if (-not $remplacee) { $sortie.Add($l) }
    }
    $manquantes = @($Voulu.Keys | Where-Object { -not $posees.ContainsKey($_) })
    if ($manquantes.Count) {
        $sortie.Add('')
        $sortie.Add('####################################################################')
        $sortie.Add('# ' + $Titre + ' (tools/population_des_bots.ps1)')
        $sortie.Add('# Ni bot niveau 1, ni chevalier de la mort.')
        $sortie.Add('####################################################################')
        foreach ($c in $manquantes) { $sortie.Add(("{0} = {1}" -f $c, $Voulu[$c])) }
    }

    $sauvegarde = "$Fichier.avant-population-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $Fichier -Destination $sauvegarde
    Write-Host ("  sauvegarde : {0}" -f $sauvegarde) -ForegroundColor DarkGray
    [System.IO.File]::WriteAllLines($Fichier, $sortie, (New-Object System.Text.UTF8Encoding $false))
    return $aChanger
}

# Le fichier du module vit a cote de celui de mod-playerbots.
$ConfBis = Join-Path (Split-Path $Conf) 'playerbots_bis.conf'

Write-Host 'mod-playerbots (playerbots.conf) :' -ForegroundColor Cyan
$n1 = Appliquer-Reglages -Fichier $Conf -Voulu $voulu -Titre 'Population des bots' -Ecrire $false
Write-Host ''
Write-Host 'mod-playerbots-bis (playerbots_bis.conf) :' -ForegroundColor Cyan
$n2 = Appliquer-Reglages -Fichier $ConfBis -Voulu $vouluBis -Titre 'Filtre de connexion' -Ecrire $false
Write-Host ''

# Le plafond ne doit pas MONTER : il ferait creer des comptes, donc des
# personnages neufs niveau 1 - exactement ce qu'on cherche a eviter ici.
if ($Bots -gt 0) {
    foreach ($l in (Get-Content -LiteralPath $Conf)) {
        if ($l -match '^\s*Playerbots\.MaxRandomBots\s*=\s*(\d+)') {
            if ([int]$Matches[1] -lt $Bots) {
                Write-Host ("ATTENTION : tu MONTES le plafond de {0} a {1}." -f $Matches[1], $Bots) -ForegroundColor Red
                Write-Host 'Le module creera des comptes pour combler, et leurs personnages' -ForegroundColor Red
                Write-Host 'naitront au niveau 1. C est la cause meme du probleme a regler.' -ForegroundColor Red
                Write-Host ''
            }
            break
        }
    }
}

if (-not $Appliquer) {
    Write-Host 'RAPPORT SEUL - rien n a ete modifie.' -ForegroundColor Yellow
    Write-Host 'Relance avec -Appliquer pour ecrire.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

if (($n1 + $n2) -eq 0) {
    Write-Host 'Tout est deja en place. Rien a ecrire.' -ForegroundColor Green
    Write-Host ''
    exit 0
}

Write-Host 'Ecriture :' -ForegroundColor Cyan
$null = Appliquer-Reglages -Fichier $Conf    -Voulu $voulu    -Titre 'Population des bots' -Ecrire $true
$null = Appliquer-Reglages -Fichier $ConfBis -Voulu $vouluBis -Titre 'Filtre de connexion' -Ecrire $true
Write-Host ''

Write-Host ("{0} reglages poses." -f $voulu.Count) -ForegroundColor Green
Write-Host ''
Write-Host 'REDEMARRE le worldserver.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Les personnages niveau 1 qui existent deja ne disparaissent pas :' -ForegroundColor DarkGray
Write-Host 'ils se mettront a niveau a leur prochaine randomisation. Pour les' -ForegroundColor DarkGray
Write-Host 'sortir du vivier tout de suite : .\tools\pas_de_bots_niveau_1.ps1' -ForegroundColor DarkGray
Write-Host ''
