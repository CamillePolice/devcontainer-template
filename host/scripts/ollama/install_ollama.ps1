# Ollama on Windows: suggest native installer.
$ErrorActionPreference = "Stop"
if ($env:USE_OLLAMA -ne "true") { Write-Host "USE_OLLAMA=false; skipping."; exit 0 }
Write-Host "On Windows install Ollama from https://ollama.com and run it."
Write-Host "Then set OLLAMA_HOST=http://localhost:11434 if needed."
