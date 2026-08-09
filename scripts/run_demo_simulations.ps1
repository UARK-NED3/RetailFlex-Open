[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScenarioDirectory,
    [string]$OpenStudio = 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe'
)

$ErrorActionPreference = 'Stop'
$scenarioDirectory = (Resolve-Path -LiteralPath $ScenarioDirectory).Path
if (-not (Test-Path -LiteralPath $OpenStudio)) { throw "OpenStudio executable not found: $OpenStudio" }

Get-ChildItem -LiteralPath $scenarioDirectory -Directory | ForEach-Object {
    $osw = Join-Path $_.FullName 'in.osw'
    if (-not (Test-Path -LiteralPath $osw)) { throw "Missing OSW: $osw" }
    & $OpenStudio run -w $osw
    if ($LASTEXITCODE -ne 0) { throw "OpenStudio failed for $($_.Name) with exit code $LASTEXITCODE" }
    $endFile = Join-Path $_.FullName 'run\eplusout.end'
    if (-not (Test-Path -LiteralPath $endFile)) { throw "Missing EnergyPlus completion file: $endFile" }
    $completion = Get-Content -LiteralPath $endFile -Raw
    if ($completion -notmatch 'Completed Successfully') { throw "EnergyPlus did not complete successfully for $($_.Name): $completion" }
}
