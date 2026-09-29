# Installs the programs these dotfiles configure (winget), then the font.
winget import -i "$PSScriptRoot\winget.json" --accept-package-agreements --accept-source-agreements --ignore-unavailable
& "$PSScriptRoot\install-font.ps1"

# PowerShell modules the profile uses
if (-not (Get-Module -ListAvailable Terminal-Icons)) {
    Install-Module Terminal-Icons -Scope CurrentUser -Force -Repository PSGallery
}
