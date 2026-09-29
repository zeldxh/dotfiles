# Reinstall guide

Steps to rebuild this machine after a fresh Windows install. Written 2026-09-29.

Projects now live in `~\projects`, not `~\dev`. The `proj` shell shortcut already points at
`~\projects` in this repo, no need to edit anything for that.

## 0. Before touching the installer

Confirm the install only formats the Windows drive. `D:` (Media), `E:` (Ventoy), `F:`
(VTOYEFI) and `G:` (Backup) are separate physical drives and must not be selected in the
Windows installer's partition screen. Use a custom install and format only the OS drive.

G: is where everything below is pulled from. If the letter isn't the same afterward (it can
shift depending on what's connected), find it with `Get-Volume` and look for the `Backup`
label.

## 1. Base tools

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Microsoft.PowerShell -e
winget install --id jdx.mise -e
```

Open a new PowerShell window after this so `git`, `gh`, `pwsh` and `mise` are on PATH.

## 2. Restore SSH keys and Git identity

Do this before cloning anything private.

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
Copy-Item "G:\Credentials\ssh\*" "$HOME\.ssh\" -Force
icacls "$HOME\.ssh" /inheritance:r | Out-Null
icacls "$HOME\.ssh" /grant:r "${env:USERNAME}:(OI)(CI)F" | Out-Null

New-Item -ItemType Directory -Force "$HOME\.config\git" | Out-Null
Copy-Item "G:\Credentials\gitconfig\.gitconfig" "$HOME\.config\git\config" -Force
```

The `icacls` step matters: OpenSSH refuses a private key that other accounts can read. Test
with:

```powershell
ssh -T git@github.com
```

Then sign in for real Git operations:

```powershell
gh auth login
```

Pick SSH and use the existing key.

## 3. Clone the repos

```powershell
New-Item -ItemType Directory -Force "$HOME\projects" | Out-Null
Set-Location "$HOME\projects"
git clone git@github.com:zeldxh/dotfiles.git
git clone git@github.com:zeldxh/alacritty-ports.git
```

`alacritty-ports` is private, so step 2 has to be done first. Clone the rest of your repos as
you need them.

## 4. Install everything the dotfiles configure

```powershell
cd dotfiles
pwsh ./packages/install-packages.ps1
pwsh ./install.ps1
git config core.hooksPath hooks
```

`install-packages.ps1` installs WezTerm, Starship, fastfetch, zoxide, Git, GitHub CLI,
PowerShell, Windows Terminal, VS Code, 7-Zip, Tailscale, Brave, Discord and the IosevkaTerm
Nerd Font. `install.ps1` copies the configs into place, sets up Windows Terminal and VS Code,
and installs the VS Code extensions listed in `vscode/extensions.txt`. The last line enables
the pre-push hook that checks for secrets before a push.

## 5. Sign in to the rest

Run `tailscale login` to reach the VPS over SSH again, and sign in to Brave and Discord if you
use their sync.

## 6. Restore your own files

```powershell
robocopy "G:\Dev" "$HOME\projects" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "G:\Andrew" "$HOME\Documents\Andrew" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "G:\Games\Emulators" "C:\Games\Emulators" /E /COPY:DAT /DCOPY:DAT /MT:8
```

`G:\Dev` is the ongoing backup of `~/projects`, kept up to date by hand. Restore from whatever
is there at the time. Anything that already lives in its own GitHub repo doesn't need this,
just clone it again.

Reinstall Steam and Riot into `C:\Games\Steam` and `C:\Games\Riot Games` directly, a file copy
doesn't restore a game library properly.

If any of your repos point at a GitHub account other than your own, confirm you still have
access to it rather than assuming it will be there.

## 7. Verify

Open a new WezTerm window and check for the Alacritty color scheme, the IosevkaTerm font, and
the Starship prompt reading `zel@w10 ~`. Running `proj` should jump to `~\projects`. A commit
should show as verified once the same SSH key is also added as a signing key in your GitHub
account settings, which is a setting on GitHub's side and not something restored by any file
here.

## What is intentionally not backed up

SSH private keys never go into any git repository, only into `G:\Credentials\ssh`, restored by
copy in step 2. GitHub CLI and Tailscale tokens are not stored anywhere, they come back by
signing in again.
