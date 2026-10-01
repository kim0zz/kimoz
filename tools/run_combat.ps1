param(
    [ValidateSet('test', 'quick', 'full')][string]$Mode = 'test',
    [string]$Output = '',
    [string]$Label = 'baseline',
    [switch]$TraceOne,
    [string]$Scenario = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExecutable = $env:GODOT_BIN
$localConfig = Join-Path $PSScriptRoot 'godot.local.txt'
if (-not $godotExecutable -and (Test-Path -LiteralPath $localConfig)) { $godotExecutable = (Get-Content -LiteralPath $localConfig -Raw).Trim() }
if (-not $godotExecutable) { $godotExecutable = (Get-Command godot -ErrorAction Stop).Source }
if (-not $Output) { $Output = Join-Path $projectRoot 'reports/combat' }
$entry = if ($Mode -eq 'test') { 'res://tests/combat_tests.gd' } else { 'res://scripts/testing/simulation_runner.gd' }
$godotArgs = @('--headless','--path',$projectRoot,'--script',$entry)
if ($Mode -ne 'test') {
    $godotArgs += @('--','--suite',$Mode,'--output',$Output,'--label',$Label)
    if ($TraceOne) { $godotArgs += '--trace-one' }
    if ($Scenario) { $godotArgs += @('--scenario', $Scenario) }
}
$foundError = $false
& $godotExecutable @godotArgs 2>&1 | ForEach-Object {
    $line = $_.ToString()
    Write-Host $line
    if ($line -match 'SCRIPT ERROR:|ERROR:|FAIL:') { $foundError = $true }
}
if ($LASTEXITCODE -ne 0 -or $foundError) { throw 'Combat verification failed; inspect output above.' }
