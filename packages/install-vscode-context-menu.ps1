# Adds "Open with Code" to the Explorer right-click menu (files, folders, and folder background).
# Per-user (HKCU), so no admin needed. Safe to re-run.
$exe = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'
if (-not (Test-Path $exe)) { $exe = 'C:\Program Files\Microsoft VS Code\Code.exe' }
if (-not (Test-Path $exe)) { Write-Warning 'VS Code not found, skipping context menu.'; return }

# reg.exe instead of the registry provider: the provider treats the `*` key as a wildcard.
# registry key -> argument that receives the clicked path
$targets = [ordered]@{
    'HKCU\Software\Classes\*\shell\VSCode'                    = '%1'
    'HKCU\Software\Classes\Directory\shell\VSCode'            = '%V'
    'HKCU\Software\Classes\Directory\Background\shell\VSCode' = '%V'
}
foreach ($key in $targets.Keys) {
    reg add $key /ve /d 'Open with Code' /f | Out-Null
    reg add $key /v Icon /d "`"$exe`"" /f | Out-Null
    reg add "$key\command" /ve /d "`"$exe`" `"$($targets[$key])`"" /f | Out-Null
}
Write-Host 'VS Code context menu entries installed.'
