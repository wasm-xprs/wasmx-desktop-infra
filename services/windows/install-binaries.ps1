param(
  [string]$InstallDir = "$HOME\.local\bin",
  [string]$DaemonVersion = "latest",
  [string]$CliVersion = "latest"
)

$ErrorActionPreference = "Stop"
$archName = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
switch ($archName) {
  "X64" { $arch = "x86_64" }
  "Arm64" { $arch = "aarch64" }
  default { throw "unsupported Windows architecture: $archName" }
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("wasmx-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

function Install-VerifiedBinary {
  param([string]$Repo, [string]$Version, [string]$Asset, [string]$Destination)
  if ($Version -eq "latest") {
    $base = "https://github.com/wasm-xprs/$Repo/releases/latest/download"
  } else {
    $base = "https://github.com/wasm-xprs/$Repo/releases/download/$Version"
  }
  $sums = Join-Path $temp "$Repo.SHA256SUMS"
  $file = Join-Path $temp $Asset
  Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS" -OutFile $sums
  Invoke-WebRequest -UseBasicParsing -Uri "$base/$Asset" -OutFile $file
  $line = Get-Content $sums | Where-Object { $_ -match ("\s" + [regex]::Escape($Asset) + "$") } | Select-Object -First 1
  if (-not $line) { throw "checksum not found for $Asset" }
  $expected = ($line -split "\s+")[0].ToLowerInvariant()
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw "checksum mismatch for $Asset" }
  Copy-Item -Force -LiteralPath $file -Destination $Destination
}

try {
  Install-VerifiedBinary "wasmx-desktop-daemon" $DaemonVersion "wasmx-desktop-daemon-windows-$arch.exe" (Join-Path $InstallDir "wasmx-desktop-daemon.exe")
  Install-VerifiedBinary "wasmx-desktop-cli" $CliVersion "wasmx-desktop-cli-windows-$arch.exe" (Join-Path $InstallDir "wasmx-desktop-cli.exe")
  Write-Host "installed verified wasm-xprs binaries in $InstallDir"
} finally {
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $temp
}
