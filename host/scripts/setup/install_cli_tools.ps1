# Install CLI tools on Windows (winget/choco). Optional.
$ErrorActionPreference = "Stop"
$HOST_DIR = $env:HOST_DIR
$LOG_DIR = Join-Path $HOST_DIR ".log"
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null
function Log { param($m); $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m"; Write-Host $line }
Log "Installing CLI tools (Windows)..."
$pkgs = @("fzf", "ripgrep", "bat", "fd", "eza")
foreach ($p in $pkgs) {
    if (Get-Command $p -ErrorAction SilentlyContinue) { continue }
    winget install --id $p --silent --accept-package-agreements 2>$null
}
Log "CLI tools done. Install manually via winget if needed."
