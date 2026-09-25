Import-Module -Name Terminal-Icons

# Real pwsh profile. $PROFILE just dot-sources this file.
# Prompt
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# Smarter cd
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Handy aliases
Set-Alias ff fastfetch

# ep: edit this profile ($env:EDITOR, else VS Code, else Notepad)
function ep {
    $file = "$HOME\.config\powershell\Microsoft.PowerShell_profile.ps1"
    $editor = if ($env:EDITOR) { $env:EDITOR }
              elseif (Get-Command code -ErrorAction SilentlyContinue) { 'code' }
              else { 'notepad' }
    & $editor $file
}


# dev: jump to the projects folder
function dev { Set-Location "$HOME\dev" }

# 7z: alias for 7-Zip
Set-Alias 7z "C:\Program Files\7-Zip\7z.exe"