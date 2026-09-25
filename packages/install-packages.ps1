# Installs the programs these dotfiles configure (winget), then the font.
winget import -i "$PSScriptRoot\winget.json" --accept-package-agreements --accept-source-agreements --ignore-unavailable
& "$PSScriptRoot\install-font.ps1"
