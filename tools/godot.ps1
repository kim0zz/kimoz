param(
    [ValidateSet('check', 'run', 'editor')]
    [string]$Mode = 'check'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localConfig = Join-Path $PSScriptRoot 'godot.local.txt'
$godotExecutable = $env:GODOT_BIN
if (-not $godotExecutable -and (Test-Path -LiteralPath $localConfig)) {
    $godotExecutable = (Get-Content -LiteralPath $localConfig -Raw).Trim()
}
if (-not $godotExecutable) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) { $godotExecutable = $command.Source }
}
if (-not $godotExecutable -or -not (Test-Path -LiteralPath $godotExecutable -PathType Leaf)) {
    throw 'Set GODOT_BIN or put the full Godot executable path in tools/godot.local.txt.'
}

function Invoke-GodotCheck {
    param([string[]]$GodotArguments)
    $captured = & $godotExecutable @GodotArguments 2>&1
    $resultCode = $LASTEXITCODE
    $captured | ForEach-Object { Write-Host $_ }
    if ($resultCode -ne 0 -or ($captured -match 'SCRIPT ERROR:|ERROR:')) {
        throw "Godot check failed (exit code $resultCode)."
    }
}

switch ($Mode) {
    'check' {
        Invoke-GodotCheck -GodotArguments @('--headless', '--path', $projectRoot, '--import')
        Invoke-GodotCheck -GodotArguments @('--headless', '--path', $projectRoot, '--quit-after', '60')
        Write-Host 'OK: import and startup completed.'
    }
    'run' {
        & $godotExecutable --path $projectRoot
        exit $LASTEXITCODE
    }
    'editor' {
        & $godotExecutable --path $projectRoot --editor
        exit $LASTEXITCODE
    }
}
