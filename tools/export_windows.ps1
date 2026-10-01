param(
    [string]$GodotExecutable = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localConfig = Join-Path $PSScriptRoot 'godot.local.txt'

if (-not $GodotExecutable) { $GodotExecutable = $env:GODOT_BIN }
if (-not $GodotExecutable -and (Test-Path -LiteralPath $localConfig)) {
    $GodotExecutable = (Get-Content -LiteralPath $localConfig -Raw).Trim()
}
if (-not $GodotExecutable) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) { $GodotExecutable = $command.Source }
}
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
    throw 'Set GODOT_BIN, pass -GodotExecutable, or put the full Godot executable path in tools/godot.local.txt.'
}

$versionOutput = (& $GodotExecutable --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $versionOutput -notmatch '^4\.7\.2\.stable\.official\.') {
    throw "Expected the official Godot 4.7.2 stable editor; found '$versionOutput'."
}

$outputDirectory = Join-Path $projectRoot 'builds/windows'
$outputExecutable = Join-Path $outputDirectory 'kimoz.exe'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

Write-Host "Exporting Windows x64 release with Godot $versionOutput..."
$exportOutput = & $GodotExecutable --headless --path $projectRoot --export-release 'Windows x64' $outputExecutable 2>&1
$exportExitCode = $LASTEXITCODE
$exportOutput | ForEach-Object { Write-Host $_ }
if ($exportExitCode -ne 0 -or ($exportOutput -match 'SCRIPT ERROR:|ERROR:')) {
    throw "Godot release export failed with exit code $exportExitCode. Confirm the matching Windows x64 export templates are installed."
}
if (-not (Test-Path -LiteralPath $outputExecutable -PathType Leaf)) {
    throw "Godot returned success but did not create '$outputExecutable'."
}

$onlineGuide = Join-Path $projectRoot 'docs/ONLINE.md'
if (Test-Path -LiteralPath $onlineGuide -PathType Leaf) {
    $distributionGuide = Join-Path $outputDirectory 'ONLINE.txt'
    Copy-Item -LiteralPath $onlineGuide -Destination $distributionGuide -Force
    $packageFiles = @($outputExecutable, $distributionGuide)
} else {
    $packageFiles = @($outputExecutable)
}

$packageZip = Join-Path $outputDirectory 'kimoz-windows-x64.zip'
Compress-Archive -LiteralPath $packageFiles -DestinationPath $packageZip -CompressionLevel Optimal -Force

Write-Host "Release ready: $outputExecutable"
Write-Host "Distributable archive: $packageZip"
