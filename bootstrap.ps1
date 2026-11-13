# RiFA Technology dev environment bootstrap (Windows PowerShell 5.1+).
# Run once on a new machine. Safe to re-run.
#
#   irm https://raw.githubusercontent.com/aikotoba883/redant-dev-env/main/bootstrap.ps1 | iex
#   # or, from a downloaded copy:
#   powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
#
# Steps: install MSYS2 -> first full update -> set user env vars ->
#        clone this repo (if needed) -> run setup.sh in UCRT64.
# Keep this file ASCII-only: PowerShell 5.1 reads BOM-less files as ANSI.

$ErrorActionPreference = 'Stop'

$Msys2Root = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { 'C:\msys64' }
$RepoUrl   = if ($env:REDANT_DEVENV_REPO) { $env:REDANT_DEVENV_REPO } else { 'https://github.com/aikotoba883/redant-dev-env.git' }
$Bash      = Join-Path $Msys2Root 'usr\bin\bash.exe'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Invoke-Msys([string]$cmd) {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'
    & $Bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { throw "MSYS2 command failed ($LASTEXITCODE): $cmd" }
}

# 1. Install MSYS2
Step 'Checking MSYS2'
if (-not (Test-Path $Bash)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install MSYS2 manually from https://www.msys2.org/ and re-run.'
    }
    winget install --id MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
    if (-not (Test-Path $Bash)) { throw "MSYS2 not found at $Msys2Root after install." }
} else {
    Write-Host "  MSYS2 found at $Msys2Root"
}

# 2. First full update. MSYS2 needs two rounds: the first one may update
#    the core runtime and end the shell early.
Step 'Updating MSYS2 (pacman -Syu, two rounds)'
& $Bash -lc 'pacman -Syu --noconfirm'
Invoke-Msys 'pacman -Syu --noconfirm'

# 3. User environment variables
#    CLAUDE_CODE_GIT_BASH_PATH makes Claude Code use MSYS2 bash instead of Git for Windows bash.
Step 'Setting user environment variables'
$vars = @{
    'CLAUDE_CODE_GIT_BASH_PATH' = $Bash
    'MSYSTEM'                   = 'UCRT64'
    'CHERE_INVOKING'            = '1'
}
foreach ($k in $vars.Keys) {
    [Environment]::SetEnvironmentVariable($k, $vars[$k], 'User')
    Write-Host "  $k = $($vars[$k])"
}

# 4. Locate or clone this repo
Step 'Locating redant-dev-env'
$repoDir = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'setup.sh'))) {
    $repoDir = $PSScriptRoot
} else {
    Invoke-Msys 'pacman -S --needed --noconfirm git'
    $homeWin = (& $Bash -lc 'cygpath -w ~').Trim()
    $repoDir = Join-Path $homeWin 'ZeNX\redant-dev-env'
    if (-not (Test-Path (Join-Path $repoDir 'setup.sh'))) {
        $repoUnix = (& $Bash -lc "cygpath -u '$repoDir'").Trim()
        Invoke-Msys "mkdir -p `"`$(dirname '$repoUnix')`" && git clone '$RepoUrl' '$repoUnix'"
    }
}
Write-Host "  $repoDir"

# 5. Run setup.sh inside UCRT64
Step 'Running setup.sh'
$repoUnix = (& $Bash -lc "cygpath -u '$repoDir'").Trim()
Invoke-Msys "cd '$repoUnix' && ./setup.sh"

Write-Host "`nDone. Open the 'MSYS2 UCRT64' shell, and restart Claude Code so it picks up the new environment variables." -ForegroundColor Green
