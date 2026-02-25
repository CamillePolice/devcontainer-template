# Install Claude Code CLI on Windows.
$ErrorActionPreference = "Stop"
$HOST_DIR = $env:HOST_DIR
if ($env:USE_CLAUDE_CODE -eq "false") { Write-Host "USE_CLAUDE_CODE=false; skipping."; exit 0 }
if (Get-Command claude -ErrorAction SilentlyContinue) { Write-Host "Claude Code already installed."; exit 0 }
$tmp = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }
Invoke-WebRequest -Uri "https://claude.ai/install.sh" -OutFile (Join-Path $tmp "install.sh") -UseBasicParsing
# On Windows the install script may not exist; suggest manual install
if (Test-Path (Join-Path $tmp "install.sh")) {
    Push-Location $tmp
    try { bash install.sh } catch { Write-Host "Run install manually: https://claude.ai/download" }
    Pop-Location
}
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Write-Host "Claude Code install step done."
