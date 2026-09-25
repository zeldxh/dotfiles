# dotfiles

Windows 10 setup: WezTerm, Windows Terminal, PowerShell 7, Starship, fastfetch, Git, VS Code.
Everything uses Alacritty's default palette (`#181818`) and `IosevkaTerm Nerd Font Mono`.

## Layout

| Repo path | Installed to |
|---|---|
| `config/wezterm`, `fastfetch`, `git`, `mise`, `powershell` | `~/.config/<name>` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `powershell/profile-stub.ps1` | `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` (loads the real profile from `~/.config`) |
| `windows-terminal/settings.json` | Windows Terminal `LocalState` |
| `vscode/settings.json` | `%APPDATA%\Code\User` |

## Use

```powershell
pwsh ./install.ps1            # repo -> system
pwsh ./install.ps1 -Collect   # system -> repo (after editing configs live)
```

## Not included

- `~/.ssh` (keys and config): secrets, restore from backup.
- The VS Code theme lives in its own folder, `alacritty-vscode-theme`.
- Programs: WezTerm, Starship, fastfetch, zoxide, Nerd Font (`IosevkaTerm Nerd Font Mono`).
