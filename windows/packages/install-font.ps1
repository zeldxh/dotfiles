# Installs IosevkaTerm Nerd Font Mono for the current user (no winget package exists for it).
$url  = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip'
$tmp  = Join-Path $env:TEMP 'IosevkaTerm'
$dest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$reg  = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

if (Get-ChildItem $dest -Filter 'IosevkaTermNerdFontMono-Regular.ttf' -ErrorAction SilentlyContinue) {
    Write-Host 'Font already installed, skipping.'
    return
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $tmp, $dest | Out-Null
Invoke-WebRequest $url -OutFile "$tmp.zip"
Expand-Archive "$tmp.zip" $tmp -Force

Get-ChildItem $tmp -Filter 'IosevkaTermNerdFontMono-*.ttf' | ForEach-Object {
    $target = Join-Path $dest $_.Name
    if (Test-Path $target) {
        # Already there and possibly locked by a running app (font engine has it open); leave it.
        return
    }
    Copy-Item $_.FullName $dest -Force
    New-ItemProperty $reg -Name "$($_.BaseName) (TrueType)" -Value $target -PropertyType String -Force | Out-Null
}
Remove-Item $tmp, "$tmp.zip" -Recurse -Force
Write-Host 'Font installed. Restart apps to pick it up.'
