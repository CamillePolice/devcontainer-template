# detect_os.ps1 — Set OS and editor user dirs for Windows PowerShell.
# Dot-source from host scripts. $IsWindows is true in PowerShell Core; fallback for Windows PowerShell.

if ($env:OS -eq "Windows_NT" -or $IsWindows) {
    $script:OS = "windows"
    $script:CONFIG_HOME = $env:APPDATA
    $script:CURSOR_USER_DIR = Join-Path $env:APPDATA "Cursor\User"
    $script:VSCODE_USER_DIR = Join-Path $env:APPDATA "Code\User"
} else {
    $script:OS = "linux"
    $script:CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:HOME ".config" }
    $script:CURSOR_USER_DIR = Join-Path $script:CONFIG_HOME "Cursor\User"
    $script:VSCODE_USER_DIR = Join-Path $script:CONFIG_HOME "Code\User"
}

$env:OS_DETECTED = $script:OS
$env:CURSOR_USER_DIR = $script:CURSOR_USER_DIR
$env:VSCODE_USER_DIR = $script:VSCODE_USER_DIR
$env:CONFIG_HOME = $script:CONFIG_HOME
