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
    'windows\config\wezterm'                     = "$HOME\.config\wezterm"
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
