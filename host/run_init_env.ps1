# Session init for host (Windows PowerShell). Run once per machine or after pulling host updates.
# Usage: .\run_init_env.ps1

$ErrorActionPreference = "Stop"
$HOST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:HOST_DIR = $HOST_DIR
$env:HOST_SCRIPTS = Join-Path $HOST_DIR "scripts"

$envFile = Join-Path $HOST_DIR ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}

& (Join-Path $env:HOST_SCRIPTS "lifecycle\init_env.ps1")
