<#
.SYNOPSIS
  Copies the dotfiles in this repo to where Windows programs read them.
  Use -Collect to go the other way: copy the live files back into the repo.
#>
param([switch]$Collect)

$wtDir = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter "Microsoft.WindowsTerminal_*" |
    Select-Object -First 1 -ExpandProperty FullName

# repo path (relative) -> live path
$map = [ordered]@{
    'config\wezterm'                              = "$HOME\.config\wezterm"
    'config\fastfetch'                            = "$HOME\.config\fastfetch"
    'config\git'                                  = "$HOME\.config\git"
    'config\mise'                                 = "$HOME\.config\mise"
    'config\powershell'                           = "$HOME\.config\powershell"
    'config\starship.toml'                        = "$HOME\.config\starship.toml"
    'powershell\profile-stub.ps1'                 = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    'vscode\settings.json'                        = "$env:APPDATA\Code\User\settings.json"
}
if ($wtDir) { $map['windows-terminal\settings.json'] = "$wtDir\LocalState\settings.json" }

foreach ($rel in $map.Keys) {
    $repo = Join-Path $PSScriptRoot $rel
    $live = $map[$rel]
    if ($Collect) { $from, $to = $live, $repo } else { $from, $to = $repo, $live }

    if (-not (Test-Path $from)) { Write-Warning "missing: $from"; continue }
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item $from (Split-Path $to) -Recurse -Force
    Write-Host "$from -> $to"
}
