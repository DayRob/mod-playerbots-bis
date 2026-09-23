<#
    Convertit le SavedVariables de l'addon PlayerbotsCensus en CSV.

    L'addon ecrit chaque personnage recense sur une ligne autonome, prefixee par
    l'horodatage du releve, donc la conversion est une simple extraction de
    chaines : aucun suivi d'imbrication Lua n'est necessaire et le CSV obtenu est
    une table de faits a plat, directement utilisable dans un outil de rapport.

    Exemple :
      .\export_census_csv.ps1 `
        -Sv "C:\test\world of warcraft 3.3.5a hd\WTF\Account\MONCOMPTE\SavedVariables\PlayerbotsCensus.lua" `
        -Out "C:\Azerothcore\reporting\census.csv"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $Sv,
    [string] $Out = (Join-Path $PSScriptRoot "census.csv"),
    [switch] $Append
)

if (-not (Test-Path $Sv)) {
    throw "SavedVariables introuvable : $Sv"
}

$columns = @(
    'Horodatage', 'Royaume', 'Faction', 'Nom', 'Guilde',
    'Niveau', 'Race', 'Classe', 'Zone'
)

Write-Host "Lecture de $Sv ..."
$lines = Get-Content -LiteralPath $Sv -Encoding UTF8

$records = New-Object System.Collections.Generic.List[object]
$skipped = 0

foreach ($line in $lines) {
    $t = $line.Trim()

    # Une ligne de donnees est une chaine seule, eventuellement suivie d'une
    # virgule et du commentaire d'index que WoW ajoute. Les lignes de cle
    # commencent toujours par ["...] ; on les ecarte sur ce critere plutot que
    # sur la presence d'un '=', qu'un nom de guilde pourrait contenir.
    if ($t.StartsWith('[')) { continue }
    if ($t -notmatch '^"(.*)",?\s*(--.*)?$') { continue }

    $payload = $Matches[1]

    # WoW peut serialiser la tabulation telle quelle ou sous la forme \9.
    $payload = $payload -replace '\\9', "`t"
    $payload = $payload -replace '\\"', '"'
    $payload = $payload -replace '\\\\', '\'

    $fields = $payload -split "`t"
    if ($fields.Count -ne $columns.Count) {
        $skipped++
        continue
    }

    $row = [ordered]@{}
    for ($i = 0; $i -lt $columns.Count; $i++) {
        $row[$columns[$i]] = $fields[$i]
    }
    # Type pour que l'outil de rapport n'ait pas a deviner.
    $row['Niveau'] = [int] $row['Niveau']
    $records.Add([pscustomobject] $row)
}

if ($records.Count -eq 0) {
    throw ("Aucune ligne exploitable dans $Sv. Verifie que le detail par " +
           "personnage est active dans l'addon (/pbcensus raw) et qu'un " +
           "balayage a bien ete termine avant la deconnexion.")
}

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

if ($Append -and (Test-Path $Out)) {
    $records | Export-Csv -LiteralPath $Out -NoTypeInformation -Encoding UTF8 -Append
} else {
    $records | Export-Csv -LiteralPath $Out -NoTypeInformation -Encoding UTF8
}

$snapshots = ($records | Select-Object -ExpandProperty Horodatage -Unique).Count
Write-Host ""
Write-Host "Ecrit : $Out"
Write-Host "$($records.Count) lignes, $snapshots releve(s)."
if ($skipped -gt 0) {
    Write-Host "$skipped ligne(s) ignoree(s) (nombre de colonnes inattendu)."
}
