<#
    Extrait nom / classe / spe / niveau de chaque bot depuis le journal de chat
    du client, apres un ".playerbotsbis report".

    POURQUOI PAR LE CHAT ET PAS PAR SQL

    La spe d'un bot n'est pas dans la base. mod-playerbots la calcule a la
    volee dans AiFactory::GetPlayerSpecTab(), en comptant les points de chaque
    arbre - et l'arbre d'un talent se lit dans sTalentStore, c'est-a-dire dans
    les DBC du serveur, pas dans characters.character_talent. Aucune requete
    SQL ne peut donc la retrouver sans embarquer la table des talents.

    La commande qui la connait, ".playerbotsbis report", est Console::No : elle
    a besoin d'une session joueur pour savoir de quels bots parler. Elle n'est
    donc joignable ni par la console ni par SOAP.

    Reste le chat. "/chatlog" fait ecrire au client tout ce qui passe dans ses
    fenetres, journal systeme compris, et ce fichier-la, PowerShell le lit.

    MODE D'EMPLOI

      1. en jeu :  /chatlog
      2. en jeu :  .playerbotsbis report all
      3. en jeu :  /chatlog          (pour refermer le fichier)
      4. ici    :  .\extraire_spes_bots.ps1 -WowPath "C:\Wow335"

    -Csv ecrit en plus un fichier a plat.
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $WowPath,
    [string] $Csv = ""
)

$log = Join-Path $WowPath 'Logs\WoWChatLog.txt'
if (-not (Test-Path $log)) {
    throw "Journal de chat introuvable : $log`nLance /chatlog en jeu, puis .playerbotsbis report all, puis /chatlog a nouveau."
}

# Les deux formes que le rapport produit par bot. La seconde est celle d'un bot
# dont aucune liste ne couvre le palier : elle porte la meme identite, et la
# laisser de cote reviendrait a perdre les bots qui ont le plus besoin d'une
# table.
$avecListe  = '^(?<nom>\S+) - (?<classe>.+?) niv (?<niveau>\d+) : (?<eq>\d+)/(?<tot>\d+) equipes'
$sansListe  = '^(?<nom>\S+) - (?<classe>.+?) niv (?<niveau>\d+) : aucune liste'

$vus = @{}
$lignes = New-Object System.Collections.Generic.List[object]

foreach ($ligne in (Get-Content -LiteralPath $log -Encoding UTF8)) {
    # Le client prefixe chaque ligne de son horodatage ; on part du premier
    # caractere utile.
    $t = $ligne -replace '^\s*\d+/\d+\s+\d+:\d+:\d+\.\d+\s*', ''

    $m = [regex]::Match($t, $avecListe)
    $couvert = $true
    if (-not $m.Success) {
        $m = [regex]::Match($t, $sansListe)
        $couvert = $false
    }
    if (-not $m.Success) { continue }

    $nom = $m.Groups['nom'].Value
    # Le rapport peut avoir ete lance plusieurs fois : seul le dernier releve
    # compte, et c'est celui qui arrive en dernier dans le fichier.
    $vus[$nom] = [pscustomobject]@{
        Nom       = $nom
        ClasseSpe = $m.Groups['classe'].Value.Trim()
        Niveau    = [int] $m.Groups['niveau'].Value
        Equipes   = if ($couvert) { [int] $m.Groups['eq'].Value }  else { $null }
        Total     = if ($couvert) { [int] $m.Groups['tot'].Value } else { $null }
    }
}

$lignes = $vus.Values | Sort-Object ClasseSpe, Nom

if ($lignes.Count -eq 0) {
    throw "Aucune ligne de rapport trouvee dans $log.`nLe rapport a-t-il bien ete lance entre deux /chatlog ?"
}

$lignes | Format-Table -AutoSize
Write-Host ""
Write-Host "$($lignes.Count) bot(s)."

if ($Csv) {
    $lignes | Export-Csv -LiteralPath $Csv -NoTypeInformation -Encoding UTF8
    Write-Host "Ecrit : $Csv"
}
