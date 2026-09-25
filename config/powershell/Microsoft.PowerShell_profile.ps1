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
# Syntax colors as you type (same palette as the VS Code theme) and history suggestions
if (Get-Module -ListAvailable PSReadLine) {
    $c = { param($hex) $r,$g,$b = [Convert]::ToInt32($hex.Substring(0,2),16),[Convert]::ToInt32($hex.Substring(2,2),16),[Convert]::ToInt32($hex.Substring(4,2),16); "`e[38;2;$r;$g;${b}m" }
    Set-PSReadLineOption -Colors @{
        Command            = & $c '6a9fb5'   # blue
        Parameter          = & $c 'f4bf75'   # yellow
        String             = & $c '90a959'   # green
        Number             = & $c 'f4bf75'
        Variable           = & $c 'd8d8d8'
        Operator           = & $c 'aa759f'   # magenta
        Keyword            = & $c 'aa759f'
        Type               = & $c 'f4bf75'
        Member             = & $c 'd06060'   # red
        Comment            = & $c '7f7f7f'
        Error              = & $c 'd06060'
        InlinePrediction   = & $c '6b6b6b'
        Default            = & $c 'd8d8d8'
    }
    # Predictions need a real terminal; skip quietly when output is redirected
    try { Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView } catch {}
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}
