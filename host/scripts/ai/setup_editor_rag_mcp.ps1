# Configure RAG MCP for both Cursor and VSCode (user-level) on Windows.
$ErrorActionPreference = "Stop"
$HOST_DIR = $env:HOST_DIR
$HOST_SCRIPTS = $env:HOST_SCRIPTS
. (Join-Path $HOST_SCRIPTS "lib\detect_os.ps1")
$MCP_RAG_DIR = Join-Path $HOST_DIR "mcp\rag"
if ($env:USE_RAG -ne "true") { Write-Host "USE_RAG=false; skipping."; exit 0 }
$serverJs = Join-Path $MCP_RAG_DIR "mcp-rag-server.js"
if (-not (Test-Path $serverJs)) { Write-Host "mcp-rag-server.js not found"; exit 1 }
if (-not (Test-Path (Join-Path $MCP_RAG_DIR "node_modules\pg"))) {
    Set-Location $MCP_RAG_DIR; npm install --silent; Set-Location $HOST_DIR
}
$serverPath = (Resolve-Path $serverJs).Path -replace '\\','/'
$cursorMcp = Join-Path $env:CURSOR_USER_DIR "mcp.json"
$vscodeMcp = Join-Path $env:VSCODE_USER_DIR "mcp.json"
New-Item -ItemType Directory -Force -Path $env:CURSOR_USER_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $env:VSCODE_USER_DIR | Out-Null
$cursorJson = @{ mcpServers = @{ "rag-supabase" = @{ command = "node"; args = @($serverPath); env = @{ RAG_DSN = "`$env:RAG_DSN"; RAG_PROJECT = "`$env:RAG_PROJECT" } } } } | ConvertTo-Json -Depth 5
$vscodeJson = @{ mcp = @{ servers = @{ "rag-supabase" = @{ type = "stdio"; command = "node"; args = @($serverPath); env = @{ RAG_DSN = "`${env:RAG_DSN}"; RAG_PROJECT = "`${env:RAG_PROJECT}" } } } } } } | ConvertTo-Json -Depth 6
Set-Content -Path $cursorMcp -Value $cursorJson
Set-Content -Path $vscodeMcp -Value $vscodeJson
$rulesSrc = Join-Path $MCP_RAG_DIR "rag-cursor-rules.mdc"
if (Test-Path $rulesSrc) { Copy-Item $rulesSrc (Join-Path $env:CURSOR_USER_DIR "rules-rag.mdc") -Force }
Write-Host "RAG MCP configured for both editors."
