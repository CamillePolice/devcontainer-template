# Session init (Windows): global git config, optional pre-commit.
# Uses $env:HOST_DIR and $env:HOST_SCRIPTS from run_init_env.ps1.

$ErrorActionPreference = "Stop"
$HOST_DIR = $env:HOST_DIR
$HOST_SCRIPTS = $env:HOST_SCRIPTS
$LOG_DIR = Join-Path $HOST_DIR ".log"
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null
$LOGFILE = Join-Path $LOG_DIR "init_env.log"

function Log { param($msg); $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"; Write-Host $line; Add-Content -Path $LOGFILE -Value $line }

Log "=== Host init_env ==="

git config --global pull.rebase true
git config --global push.autoSetupRemote true
if (Get-Command cursor -ErrorAction SilentlyContinue) {
    git config --global core.editor "cursor --wait"
} elseif (Get-Command code -ErrorAction SilentlyContinue) {
    git config --global core.editor "code --wait"
}
Log "Global git config updated."

# Pre-commit: install for user if not present
if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    if (Get-Command pip3 -ErrorAction SilentlyContinue) {
        pip3 install --user pre-commit 2>$null; if ($LASTEXITCODE -eq 0) { Log "Installed pre-commit (user)." }
    } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
        pip install --user pre-commit 2>$null; if ($LASTEXITCODE -eq 0) { Log "Installed pre-commit (user)." }
    } else { Log "pip not found; skip pre-commit." }
} else { Log "pre-commit already installed." }

Log "=== Host init_env completed. Log: $LOGFILE ==="
