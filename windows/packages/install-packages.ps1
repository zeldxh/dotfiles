# Installs the programs these dotfiles configure (winget), then the font and the VS Code context menu.
winget import -i "$PSScriptRoot\winget.json" --accept-package-agreements --accept-source-agreements --ignore-unavailable
& "$PSScriptRoot\install-font.ps1"
& "$PSScriptRoot\install-vscode-context-menu.ps1"

# PowerShell modules the profile uses
if (-not (Get-Module -ListAvailable Terminal-Icons)) {
    Install-Module Terminal-Icons -Scope CurrentUser -Force -Repository PSGallery
}
