$ErrorActionPreference = "Stop"
$name = "wasm-xprs-desktop-daemon"
$task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
if ($null -ne $task) {
  Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $name -Confirm:$false
}
Write-Host "removed scheduled task $name"

$runner = Join-Path $HOME ".wasm-xprs\daemon\run-daemon.ps1"
Remove-Item -LiteralPath $runner -Force -ErrorAction SilentlyContinue
