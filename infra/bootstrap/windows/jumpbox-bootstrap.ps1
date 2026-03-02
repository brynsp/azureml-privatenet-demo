$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$logPath = "C:\Windows\Temp\jumpbox-bootstrap.log"

function Write-Log {
  param([string]$Message)
  $line = "[{0}] {1}" -f (Get-Date -Format s), $Message
  Write-Output $line
  Add-Content -Path $logPath -Value $line
}

function Command-Exists {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Log "Starting jumpbox bootstrap."
$rebootRequired = $false

if (-not (Command-Exists "winget.exe")) {
  Write-Log "winget not found. Installing App Installer."
  try {
    Add-AppxPackage -Path "https://aka.ms/getwinget"
    Start-Sleep -Seconds 5
  } catch {
    throw "Failed to install winget: $($_.Exception.Message)"
  }
}

if (-not (Command-Exists "winget.exe")) {
  throw "winget is not available after installation attempt."
}

Write-Log "Ensuring Windows Terminal is installed on Windows host."
& winget install --id Microsoft.WindowsTerminal --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity

Write-Log "Ensuring Azure CLI is installed on Windows host."
& winget install --id Microsoft.AzureCLI --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity

Write-Log "Setting WSL2 as default version."
& wsl.exe --set-default-version 2
if ($LASTEXITCODE -eq 3010) {
  $rebootRequired = $true
} elseif ($LASTEXITCODE -ne 0) {
  throw "wsl --set-default-version 2 failed with exit code $LASTEXITCODE."
}

$installedDistros = @(& wsl.exe -l -q 2>$null)
if ($installedDistros -notcontains "Ubuntu") {
  Write-Log "Ubuntu distro not found. Installing with wsl --install -d Ubuntu --no-launch."
  & wsl.exe --install -d Ubuntu --no-launch
  if ($LASTEXITCODE -eq 3010) {
    $rebootRequired = $true
  } elseif ($LASTEXITCODE -ne 0) {
    throw "wsl --install failed with exit code $LASTEXITCODE."
  }
}

if ($rebootRequired) {
  Write-Log "Bootstrap completed with pending reboot requirement. Safe to rerun after reboot."
  exit 0
}

Write-Log "Installing Ubuntu packages (azure-cli and python3) inside WSL."
$ubuntuProvision = "set -e; export DEBIAN_FRONTEND=noninteractive; command -v python3 >/dev/null 2>&1 || (apt-get update && apt-get install -y python3); command -v az >/dev/null 2>&1 || (apt-get update && apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg && curl -sL https://aka.ms/InstallAzureCLIDeb | bash)"
& wsl.exe -d Ubuntu -u root -- bash -lc $ubuntuProvision
if ($LASTEXITCODE -ne 0) {
  throw "Ubuntu package provisioning failed with exit code $LASTEXITCODE."
}

Write-Log "Jumpbox bootstrap completed successfully."
