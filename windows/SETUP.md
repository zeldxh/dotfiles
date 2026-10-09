# Reinstall guide

Steps to rebuild this machine after a fresh Windows install. Written 2026-09-29.

Projects live in `C:\dev`. The `dev` shell shortcut already points there, no need to edit
anything for that. Personal files live in `~\files`, not `Documents`, which programs fill with
their own folders.

Every block below is plain PowerShell, copy and paste it straight into a terminal. Most steps
check first and skip anything already in place, so it is fine to run this even if some of it
was already done by hand, for example installing Git or PowerShell just to get this far in the
first place.

## 0. Before touching the installer

Confirm the install only formats the Windows drive. `D:` (Media), `E:` (Ventoy), `F:`
(VTOYEFI) and `G:` (Backup) are separate physical drives and must not be selected in the
Windows installer's partition screen. Use a custom install and format only the OS drive.

Everything below is pulled from the backup drive, labeled `Backup`. Its letter is not fixed:
it depends on what else is plugged in, and it changes if the Ventoy USB stick is not connected
(that stick normally takes `E:` and `F:`). Find the real letter first and keep using it instead
of typing `G:` from memory:

```powershell
$backup = (Get-Volume -FileSystemLabel Backup).DriveLetter + ":"
$backup
```

Every command below that references the backup drive uses `$backup`, run in the same session so
the variable stays set. If a step is run later or in a new window, set `$backup` again first.

## 1. Base tools

```powershell
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { winget install --id Git.Git -e } else { "Git already installed" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { winget install --id GitHub.cli -e } else { "GitHub CLI already installed" }
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { winget install --id Microsoft.PowerShell -e } else { "PowerShell 7 already installed" }
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) { winget install --id jdx.mise -e } else { "mise already installed" }
```

Open a new PowerShell window after this so `git`, `gh`, `pwsh` and `mise` are on PATH.

## 2. Restore SSH keys and Git identity

Do this before cloning anything private.

```powershell
if (Test-Path "$HOME\.ssh\id_ed25519_github") {
    "SSH keys already present, skipping"
} else {
    New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
    Copy-Item "$backup\Credentials\ssh\*" "$HOME\.ssh\" -Force
    icacls "$HOME\.ssh" /inheritance:r | Out-Null
    icacls "$HOME\.ssh" /grant:r "${env:USERNAME}:(OI)(CI)F" | Out-Null
}

if (Test-Path "$HOME\.config\git\config") {
    "Git config already present, skipping"
} else {
    New-Item -ItemType Directory -Force "$HOME\.config\git" | Out-Null
    Copy-Item "$backup\Credentials\gitconfig\.gitconfig" "$HOME\.config\git\config" -Force
}
```

The `icacls` step matters: OpenSSH refuses a private key that other accounts can read. Test
with:

```powershell
ssh -T git@github.com
```

Then sign in for real Git operations:

```powershell
if ((gh auth status 2>&1) -match "Logged in") { "Already signed in to GitHub CLI" } else { gh auth login }
```

Pick SSH and use the existing key.

## 3. Clone the repos

```powershell
New-Item -ItemType Directory -Force "C:\dev" | Out-Null
Set-Location "C:\dev"
if (Test-Path dotfiles) { "dotfiles already cloned" } else { git clone git@github.com:zeldxh/dotfiles.git }
```

The Ash theme (`ash-theme`) does not need cloning by hand: `install.ps1` in step 4 clones it next
to `dotfiles` and installs it into VS Code. Clone the rest of your repos as you need them, the
same check-first pattern works for any of them:

```powershell
if (Test-Path some-repo-name) { "already cloned" } else { git clone git@github.com:zeldxh/some-repo-name.git }
```

## 4. Install everything the dotfiles configure

```powershell
Set-Location "C:\dev\dotfiles"
pwsh ./windows/packages/install-packages.ps1
pwsh ./windows/install.ps1
git config core.hooksPath hooks
```

Every line here is safe to run again later, `winget` skips what is already installed and the
scripts just overwrite the config files with the same content.

`install-packages.ps1` installs Starship, fastfetch, zoxide, Git, GitHub CLI,
PowerShell, Windows Terminal, VS Code, 7-Zip, Tailscale, Brave, Discord and the IosevkaTerm
Nerd Font. `install.ps1` copies the configs into place, sets up Windows Terminal and VS Code,
installs the VS Code extensions listed in `shared/vscode/extensions.txt` plus the Ash theme
(cloned from `ash-theme` next to `dotfiles`), and patches Discord with Vencord. Run it again after
a Discord update, which undoes the Vencord patch. The last line enables
the pre-push hook that checks for secrets before a push.

## 5. Sign in to the rest

```powershell
tailscale status
```

If that shows logged out, run `tailscale login` to reach the VPS over SSH again. Sign in to
Brave and Discord too if you use their sync, there is nothing to script for either.

## 6. Restore your own files

Robocopy only copies what is missing or changed, so these are safe to run more than once.

```powershell
robocopy "$backup\Dev" "C:\dev" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "$backup\Andrew" "$HOME\files" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "$backup\Games\Emulators" "C:\Games\Emulators" /E /COPY:DAT /DCOPY:DAT /MT:8
```

The `Dev` folder on the backup drive is the ongoing backup of `C:\dev`, kept up to date by
hand. Restore from whatever is there at the time. Anything that already lives in its own GitHub
repo doesn't need this, just clone it again.

Reinstall Steam and Riot into `C:\Games\Steam` and `C:\Games\Riot Games` directly, a file copy
doesn't restore a game library properly.

If any of your repos point at a GitHub account other than your own, confirm you still have
access to it rather than assuming it will be there.

## 7. Verify

Open a new Windows Terminal window and check for the Ash color scheme, the IosevkaTerm font, and
the Starship prompt showing `user@hostname` (your actual Windows username and computer name,
these can be anything, nothing here depends on a specific one). Running `dev` should jump to
`C:\dev`. A commit should show as verified once the same SSH key is also added as a signing
key in your GitHub account settings, which is a setting on GitHub's side and not something
restored by any file here.

## What is intentionally not backed up

SSH private keys never go into any git repository, only into `Credentials\ssh` on the backup
drive, restored by copy in step 2. GitHub CLI and Tailscale tokens are not stored anywhere,
they come back by signing in again.
