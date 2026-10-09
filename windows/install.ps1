<#
.SYNOPSIS
  Copies the dotfiles in this repo to where Windows programs read them.
  Use -Collect to go the other way: copy the live files back into the repo.
#>
param([switch]$Collect)

# $PSScriptRoot is windows/; shared/ lives next to it
$root = Split-Path $PSScriptRoot -Parent

$wtDir = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter "Microsoft.WindowsTerminal_*" |
    Select-Object -First 1 -ExpandProperty FullName

# repo path (relative to the repo root) -> live path
$map = [ordered]@{
    'windows\config\fastfetch'                   = "$HOME\.config\fastfetch"
    'windows\config\git\config'                 = "$HOME\.config\git\config"
    'shared\git\ignore'                          = "$HOME\.config\git\ignore"
    'shared\mise'                                 = "$HOME\.config\mise"
    'windows\config\powershell'                  = "$HOME\.config\powershell"
    'shared\starship.toml'                        = "$HOME\.config\starship.toml"
    'windows\powershell\profile-stub.ps1'        = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    'shared\vscode\settings.json'                = "$env:APPDATA\Code\User\settings.json"
}
if ($wtDir) { $map['windows\windows-terminal\settings.json'] = "$wtDir\LocalState\settings.json" }

if (Get-Command code -ErrorAction SilentlyContinue) {
    Get-Content (Join-Path $root 'shared\vscode\extensions.txt') | ForEach-Object { code --install-extension $_ }
}

foreach ($rel in $map.Keys) {
    $repo = Join-Path $root $rel
    $live = $map[$rel]
    if ($Collect) { $from, $to = $live, $repo } else { $from, $to = $repo, $live }

    if (-not (Test-Path $from)) { Write-Warning "missing: $from"; continue }
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    if ((Get-Item $from).PSIsContainer) {
        Copy-Item $from (Split-Path $to) -Recurse -Force
    } else {
        Copy-Item $from $to -Force   # file: exact target name (the profile stub gets renamed)
    }
    Write-Host "$from -> $to"
}

# Ash theme for VS Code: its own public repo, cloned next to this one and kept up to date
if (-not $Collect) {
    $ash = Join-Path (Split-Path $root -Parent) 'ash-theme'
    if (Test-Path "$ash\.git") { git -C $ash pull --ff-only -q } else { git clone -q https://github.com/zeldxh/ash-theme.git $ash }
    if (Test-Path "$ash\vscode\install.ps1") { & "$ash\vscode\install.ps1" } else { Write-Warning "Ash theme not available: $ash" }
}

# Vencord: patch Discord with the official installer CLI. Safe to re-run (it re-patches with the
# latest build), and needed after Discord updates itself, which undoes the patch.
if (-not $Collect) {
    if (Test-Path "$env:LOCALAPPDATA\Discord") {
        $cli = Join-Path $env:TEMP 'VencordInstallerCli.exe'
        Invoke-WebRequest 'https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe' -OutFile $cli
        & $cli -install -branch auto
        Remove-Item $cli -ErrorAction SilentlyContinue
    } else {
        Write-Warning 'Discord is not installed, skipping Vencord.'
    }
}
