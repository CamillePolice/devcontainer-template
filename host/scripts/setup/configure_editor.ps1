# Configure both Cursor and VSCode user-level. Copy editor-config/cursor and editor-config/vscode.
$ErrorActionPreference = "Stop"
. (Join-Path $env:HOST_SCRIPTS "lib\detect_os.ps1")
$HOST_DIR = $env:HOST_DIR
$cursorSrc = Join-Path $HOST_DIR "editor-config\cursor"
$vscodeSrc = Join-Path $HOST_DIR "editor-config\vscode"
$cursorDest = $env:CURSOR_USER_DIR
$vscodeDest = $env:VSCODE_USER_DIR
function Copy-Into { param($src, $dest, $name)
    if (-not (Test-Path $src)) { Write-Host "Skip $name : source not found"; return }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Get-ChildItem $src -File | ForEach-Object { Copy-Item $_.FullName (Join-Path $dest $_.Name) -Force; Write-Host "Copied $name : $($_.Name)" }
    Get-ChildItem $src -Directory | ForEach-Object { Copy-Item $_.FullName (Join-Path $dest $_.Name) -Recurse -Force; Write-Host "Copied $name dir : $($_.Name)" }
}
Copy-Into $cursorSrc $cursorDest "Cursor"
Copy-Into $vscodeSrc $vscodeDest "VSCode"
Write-Host "Cursor and VSCode user configs updated."
