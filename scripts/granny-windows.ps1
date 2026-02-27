$ErrorActionPreference = "Stop"

function Say {
  param([string]$Message)
  Write-Host ""
  Write-Host $Message
}

function Die {
  param([string]$Message)
  Write-Host ""
  Write-Host "ERROR: $Message" -ForegroundColor Red
  exit 1
}

if (-not [Environment]::Is64BitOperatingSystem) {
  Die "This installer currently supports Windows x64 only."
}

$RepoRawBase = if ([string]::IsNullOrWhiteSpace($env:REPO_RAW_BASE)) {
  "https://raw.githubusercontent.com/5310S/lantern_release/main"
} else {
  $env:REPO_RAW_BASE
}
$RepoRawBase = $RepoRawBase.TrimEnd("/")

$WorkDir = Join-Path $env:TEMP ("lantern-release-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

try {
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  } catch {
    # Continue; older/newer PowerShell versions can handle TLS policy differently.
  }

  Say "Lantern Easy Install (Windows x64)"
  Say "This script downloads Lantern, verifies checksum, and launches the installer."

  $ManifestUrl = "$RepoRawBase/latest.json"
  $ManifestPath = Join-Path $WorkDir "latest.json"

  Say "Loading release metadata..."
  Invoke-WebRequest -UseBasicParsing -Uri $ManifestUrl -OutFile $ManifestPath
  $Manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json

  if (-not $Manifest.version) {
    Die "Release metadata is missing version."
  }
  if (-not $Manifest.windows_x86_64_installer) {
    Die "Release metadata is missing windows_x86_64_installer."
  }

  $Version = [string]$Manifest.version
  $ArtifactRel = [string]$Manifest.windows_x86_64_installer.artifact
  $ExpectedSha = ([string]$Manifest.windows_x86_64_installer.sha256).ToLowerInvariant()

  if ([string]::IsNullOrWhiteSpace($ArtifactRel) -or [string]::IsNullOrWhiteSpace($ExpectedSha)) {
    Die "Windows installer metadata is incomplete."
  }

  $InstallerName = [System.IO.Path]::GetFileName($ArtifactRel)
  if ([string]::IsNullOrWhiteSpace($InstallerName)) {
    $InstallerName = "LanternSetup.exe"
  }
  $InstallerUrl = "$RepoRawBase/$ArtifactRel"
  $InstallerPath = Join-Path $WorkDir $InstallerName

  Say "Downloading $InstallerName for $Version ..."
  Invoke-WebRequest -UseBasicParsing -Uri $InstallerUrl -OutFile $InstallerPath

  Say "Verifying checksum..."
  $ActualSha = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($ActualSha -ne $ExpectedSha) {
    Die "Checksum mismatch. Expected $ExpectedSha, got $ActualSha"
  }

  $Reply = Read-Host "Ready to run the installer now? [Y/n]"
  if ([string]::IsNullOrWhiteSpace($Reply)) { $Reply = "Y" }
  if ($Reply -match "^[Nn]$") {
    Die "Install cancelled by user."
  }

  Say "Launching installer (Windows may ask for Administrator permission)..."
  $Proc = Start-Process -FilePath $InstallerPath -Wait -PassThru
  if ($Proc.ExitCode -ne 0) {
    Die "Installer exited with code $($Proc.ExitCode)."
  }

  Say "Install complete."
  Write-Host ""
  Write-Host "Next steps:"
  Write-Host "1) Open Start Menu -> Lantern -> Lantern Control Panel"
  Write-Host "2) Click Start"
  Write-Host "3) Click Refresh after 10-20 seconds"
  Write-Host "4) Optional health check in PowerShell:"
  Write-Host "   curl.exe -k -H ""Authorization: Bearer testnet-local-admin"" https://127.0.0.1:8645/weave/chain/head"
} catch {
  Die $_.Exception.Message
} finally {
  if (Test-Path $WorkDir) {
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
