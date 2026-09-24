<#
    Relance worldserver.exe quand il se ferme, et archive de quoi comprendre
    pourquoi.

    A chaque arret, le script horodate l'evenement, met de cote le dump et le
    rapport de plantage produits par AzerothCore ainsi que les journaux, puis
    redemarre. La sortie crashes.csv donne l'heure de chaque arret : c'est ce
    qui permet de confirmer ou d'infirmer une periodicite.

    Si le serveur s'arrete plusieurs fois de suite en quelques minutes, le
    script s'arrete au lieu de boucler a vide.

    Exemple :
      .\worldserver_watchdog.ps1 -ServerDir "C:\Azerothcore\bin" -LogsDir "C:\Azerothcore\logs"

    Ctrl+C arrete la surveillance. Fermer le serveur depuis sa console ou par
    la commande .server shutdown le laisse eteint : seul un arret anormal
    declenche un redemarrage.
#>

param(
    [string] $ServerDir            = "C:\Azerothcore\bin",
    [string] $LogsDir              = "C:\Azerothcore\logs",
    [string] $Archive              = "C:\Azerothcore\crash_archive",
    [int]    $RestartDelaySeconds  = 10,
    [int]    $RapidFailWindowMin   = 5,
    [int]    $RapidFailLimit       = 4
)

$exe = Join-Path $ServerDir "worldserver.exe"
if (-not (Test-Path $exe)) {
    throw "worldserver.exe introuvable : $exe - passe le bon dossier avec -ServerDir."
}

if (-not (Test-Path $Archive)) {
    New-Item -ItemType Directory -Path $Archive -Force | Out-Null
}

$csv = Join-Path $Archive "crashes.csv"
if (-not (Test-Path $csv)) {
    "Horodatage;CodeSortie;DureeMinutes;Dossier" | Set-Content -LiteralPath $csv -Encoding UTF8
}

# Une sortie propre ne doit pas relancer le serveur.
$cleanExitCodes = @(0)

$recent = New-Object System.Collections.Generic.List[datetime]

Write-Host "Surveillance de $exe"
Write-Host "Archive : $Archive"
Write-Host ""

while ($true) {
    $startedAt = Get-Date
    Write-Host ("[{0}] demarrage du serveur..." -f $startedAt.ToString("HH:mm:ss"))

    $proc = Start-Process -FilePath $exe -WorkingDirectory $ServerDir -PassThru
    $proc.WaitForExit()

    $stoppedAt = Get-Date
    $code      = $proc.ExitCode
    $uptime    = [math]::Round(($stoppedAt - $startedAt).TotalMinutes, 1)
    $stamp     = $stoppedAt.ToString("yyyy-MM-dd_HH-mm-ss")

    Write-Host ("[{0}] arret apres {1} min - code {2}" -f $stoppedAt.ToString("HH:mm:ss"), $uptime, $code) -ForegroundColor Yellow

    # Tout ce qui peut expliquer l'arret, mis de cote avant qu'un redemarrage
    # ne le reecrive : les journaux sont en mode Overwrite par defaut.
    $dest = Join-Path $Archive $stamp
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    $crashDir = Join-Path $ServerDir "Crashes"
    if (Test-Path $crashDir) {
        Get-ChildItem -LiteralPath $crashDir -File |
            Where-Object { $_.LastWriteTime -gt $startedAt.AddMinutes(-1) } |
            ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force }
    }

    foreach ($log in @("Server.log", "Errors.log", "DBErrors.log")) {
        $path = Join-Path $LogsDir $log
        if (Test-Path $path) {
            Copy-Item -LiteralPath $path -Destination $dest -Force -ErrorAction SilentlyContinue
        }
    }

    $kept = (Get-ChildItem -LiteralPath $dest -File | Measure-Object).Count
    Write-Host ("        $kept fichier(s) archive(s) dans $dest")

    "{0};{1};{2};{3}" -f $stoppedAt.ToString("yyyy-MM-dd HH:mm:ss"), $code, $uptime, $stamp |
        Add-Content -LiteralPath $csv -Encoding UTF8

    if ($cleanExitCodes -contains $code) {
        Write-Host "Arret propre - la surveillance s'arrete." -ForegroundColor Green
        break
    }

    # Boucle a vide : si le serveur ne tient plus, mieux vaut s'arreter que
    # d'empiler les redemarrages.
    $recent.Add($stoppedAt)
    $cutoff = $stoppedAt.AddMinutes(-$RapidFailWindowMin)
    for ($i = $recent.Count - 1; $i -ge 0; $i--) {
        if ($recent[$i] -lt $cutoff) { $recent.RemoveAt($i) }
    }

    if ($recent.Count -ge $RapidFailLimit) {
        Write-Host ""
        Write-Host ("$($recent.Count) arrets en moins de $RapidFailWindowMin minutes - " +
                    "la surveillance s'arrete. Regarde $dest.") -ForegroundColor Red
        break
    }

    Write-Host ("        redemarrage dans $RestartDelaySeconds s...")
    Start-Sleep -Seconds $RestartDelaySeconds
}
