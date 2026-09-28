param(
  [string]$Binary = "$HOME\.local\bin\wasmx-desktop-daemon.exe"
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Binary -PathType Leaf)) {
  throw "missing executable: $Binary"
}

$stateDir = Join-Path $HOME ".wasm-xprs\daemon"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$runner = Join-Path $stateDir "run-daemon.ps1"
$escapedBinary = $Binary.Replace("'", "''")
@"
`$ErrorActionPreference = "Stop"
`$env:WASMX_DESKTOP_ADDR = "127.0.0.1:8765"
`$env:WASMX_MAX_MEMORY_BYTES = "134217728"
`$env:WASMX_MAX_PARALLEL_INVOCATIONS = "8"
`$env:WASMX_MAX_PARALLEL_COMPILES = "2"
`$env:WASMX_MAX_CACHED_MODULES = "32"
`$env:WASMX_MAX_TENANT_DEPLOYMENTS = "64"
`$env:WASMX_MAX_TENANT_STORAGE_BYTES = "536870912"
`$env:WASMX_DEFAULT_FUEL = "50000000"
& '$escapedBinary'
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
"@ | Set-Content -LiteralPath $runner -Encoding UTF8

$powershell = (Get-Command powershell.exe).Source
$action = New-ScheduledTaskAction -Execute $powershell -Argument "-NoProfile -NonInteractive -File `"$runner`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 3650)

Register-ScheduledTask -TaskName "wasm-xprs-desktop-daemon" -Action $action -Trigger $trigger -Settings $settings -Description "wasm-xprs local Wasmtime FaaS daemon" -Force | Out-Null
Start-ScheduledTask -TaskName "wasm-xprs-desktop-daemon"
Write-Host "installed and started scheduled task wasm-xprs-desktop-daemon"
