# One-time host setup (Windows): CLI tools, Claude Code, editor config (Cursor + VSCode), RAG MCP, Ollama.
# Uses $env:HOST_DIR and $env:HOST_SCRIPTS from run_post_create.ps1.

$ErrorActionPreference = "Stop"
$HOST_DIR = $env:HOST_DIR
$HOST_SCRIPTS = $env:HOST_SCRIPTS
if (-not $HOST_DIR -or -not $HOST_SCRIPTS) { throw "HOST_DIR and HOST_SCRIPTS must be set (run via run_post_create.ps1)" }

$LOG_DIR = Join-Path $HOST_DIR ".log"
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null
$LOGFILE = Join-Path $LOG_DIR "post_create.log"

function Log { param($msg); $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"; Write-Host $line; Add-Content -Path $LOGFILE -Value $line }

. (Join-Path $HOST_SCRIPTS "lib\detect_os.ps1")
Log "=== Starting host post_create (OS=$env:OS_DETECTED) ==="

function Run-Script {
    param([string]$ScriptPath)
    if (Test-Path $ScriptPath) {
        try {
            & $ScriptPath
            Log "OK: $ScriptPath"
        } catch {
            Log "WARNING: $ScriptPath failed - $_"
        }
    } else {
        Log "SKIP (not found): $ScriptPath"
    }
}

# CLI tools (Windows: winget/choco)
Run-Script (Join-Path $HOST_SCRIPTS "setup\install_cli_tools.ps1")

# Claude Code CLI
if ($env:USE_CLAUDE_CODE -ne "false") {
    Run-Script (Join-Path $HOST_SCRIPTS "setup\install_claude_code.ps1")
}

# Configure both Cursor and VSCode
if ($env:USE_VSCODE_CONFIG -ne "false") {
    Run-Script (Join-Path $HOST_SCRIPTS "setup\configure_editor.ps1")
}

# RAG MCP (user-level for both editors)
Run-Script (Join-Path $HOST_SCRIPTS "ai\setup_editor_rag_mcp.ps1")

# Ollama (optional)
Run-Script (Join-Path $HOST_SCRIPTS "ollama\install_ollama.ps1")

Log "=== Host post_create completed. Log: $LOGFILE ==="
