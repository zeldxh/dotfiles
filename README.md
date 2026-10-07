# dotfiles

My setup on two systems, with the same look on both: Alacritty's default palette (`#181818`) and
`IosevkaTerm Nerd Font Mono`.

| | Folder | Guide |
|---|---|---|
| Windows 10 | [`windows/`](windows) | WezTerm, Windows Terminal, PowerShell 7, Starship, fastfetch, Git, VS Code. See [`windows/SETUP.md`](windows/SETUP.md) |
| Linux Mint (Cinnamon) | [`linux/`](linux) | Alacritty, zellij, fish, Starship, rofi, riced Cinnamon. See [`linux/README.md`](linux/README.md) |
| Both | [`shared/`](shared) | Starship prompt, global gitignore, mise tools, VS Code settings and extensions |

`hooks/pre-push` is shared too and works on both.

## Layout

```
shared/     used by both systems (starship.toml, git/ignore, mise/, vscode/)
windows/    install.ps1, packages/ (winget), config/ (wezterm, powershell, git, fastfetch),
            powershell/, windows-terminal/, SETUP.md
linux/      install.sh, config/, bin/, cinnamon/, autostart/, README.md
hooks/      pre-push
```

## Use

Windows:

```powershell
pwsh ./windows/install.ps1            # repo -> system
pwsh ./windows/install.ps1 -Collect   # system -> repo (after editing configs live)
```

New PC: `pwsh ./windows/packages/install-packages.ps1` first (programs, font, VS Code context menu).

Linux:

```bash
./linux/install.sh            # repo -> system
./linux/install.sh --collect  # system -> repo (after editing configs live)
```

Then on either system, enable the pre-push secret check once:

```
git config core.hooksPath hooks
```

(`linux/install.sh` already does it.)

## What is shared and what is not

| Shared (`shared/`) | Per system |
|---|---|
| `starship.toml` (one prompt everywhere) | terminal and multiplexer config |
| `git/ignore` (global gitignore) | `git/config` (`autocrlf`, credential helper differ) |
| `mise/config.toml` (node, java, python, pnpm, fzf) | shell config, package installs, desktop |
| `vscode/` (settings, extensions) | |

## Safety

`hooks/pre-push` blocks a push that adds private keys, tokens, `.env` files, `.ssh/` content,
or `CLAUDE.md` / `AGENTS.md`. `shared/git/ignore` is a global gitignore that also skips agent files.

## Not included

- `~/.ssh` (keys, `allowed_signers`): secrets. Each machine has its own key, see `linux/README.md`.
- The VS Code theme lives in its own repo, `alacritty-ports` (with the Brave, Firefox and Discord themes).
- Programs themselves: installed by `windows/packages` (winget) or `linux/install.sh` (apt, mise).
