param(
  [string]$Binary = "$HOME\.local\bin\wasmx-desktop-daemon.exe"
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Binary -PathType Leaf)) {
  throw "missing executable: $Binary"
}

$stateDir = Join-Path $HOME ".wasm-xprs\daemon"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$action = New-ScheduledTaskAction -Execute $Binary
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 3650)

Register-ScheduledTask -TaskName "wasm-xprs-desktop-daemon" -Action $action -Trigger $trigger -Settings $settings -Description "wasm-xprs local Wasmtime FaaS daemon" -Force | Out-Null
Start-ScheduledTask -TaskName "wasm-xprs-desktop-daemon"
Write-Host "installed and started scheduled task wasm-xprs-desktop-daemon"
