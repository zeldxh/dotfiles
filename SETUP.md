# Reinstall guide

Everything needed to rebuild this machine after a fresh Windows install. Written 2026-09-29.
Supersedes the old notes at `G:\Setup\windows10\setup.txt` (those referenced `E:\Credentials`,
which is now `G:\Credentials` — drive letters had shifted).

**To trigger this with Claude directly**, in a fresh Claude Code session on the new install, say:

> Read `G:\Setup\windows10\setup.md` and migrate my setup — execute it step by step yourself,
> only asking me for the parts that need my input (UAC prompts, `gh auth login`,
> `tailscale login`, browser sign-ins). First confirm which drive letter is the `Backup` drive
> now, in case it moved.

That instruction is also saved in Claude's own memory backup at `G:\Credentials\claude-memory`,
restored in step 6 below — so once that's copied back, Claude should recognize the request even
without the long version.

**Change from last time:** projects now live in `~\projects`, not `~\dev`. The `dev` shell
shortcut is renamed to `proj` and already points at `~\projects` in this repo — nothing to
edit, just follow the steps below.

## 0. Before touching the installer

- **Confirm the install only formats the Windows drive.** `D:` (Media), `E:` (Ventoy), `F:`
  (VTOYEFI) and `G:` (Backup) are separate physical drives and must not be selected in the
  Windows installer's partition screen. Custom install, format only the OS drive.
- G: is where everything below is pulled from. If it's not the same G: afterward (letters can
  shift with drives connected/disconnected), find it first: `Get-Volume` and look for the
  `Backup` label.
- Optional, from the old notes, entirely up to you and not something to run unattended: Raphi's
  Win11Debloat, Chris Titus Tech's WinUtil, and an activation script were listed in
  `G:\Setup\windows10\debloat.txt`. The activation one bypasses Windows licensing — know what
  it does before running it.

## 1. Base tools

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Microsoft.PowerShell -e
winget install --id jdx.mise -e
```

Open a new PowerShell window after this so `git`, `gh`, `pwsh` and `mise` are on PATH.

## 2. Restore SSH keys and Git identity (before cloning anything private)

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
Copy-Item "G:\Credentials\ssh\*" "$HOME\.ssh\" -Force
icacls "$HOME\.ssh" /inheritance:r | Out-Null
icacls "$HOME\.ssh" /grant:r "${env:USERNAME}:(OI)(CI)F" | Out-Null

New-Item -ItemType Directory -Force "$HOME\.config\git" | Out-Null
Copy-Item "G:\Credentials\gitconfig\.gitconfig" "$HOME\.config\git\config" -Force
```

`icacls` matters: OpenSSH refuses a private key that other accounts can read. Test with:

```powershell
ssh -T git@github.com
```

Then sign in for real Git operations:

```powershell
gh auth login          # pick SSH, use the existing key
```

## 3. Clone the repos

```powershell
New-Item -ItemType Directory -Force "$HOME\projects" | Out-Null
Set-Location "$HOME\projects"
git clone git@github.com:zeldxh/dotfiles.git
git clone git@github.com:zeldxh/alacritty-ports.git   # private — needs step 2 done first
git clone git@github.com:zeldxh/jot.git
```

## 4. Install everything the dotfiles configure

```powershell
cd dotfiles
pwsh ./packages/install-packages.ps1   # winget list + IosevkaTerm Nerd Font
mise use -g rust@stable                # only needed if you'll build jot
pwsh ./install.ps1                     # copies config/* to ~/.config, Windows Terminal, VS Code
git config core.hooksPath hooks        # enables the pre-push secret check, per clone
```

`install-packages.ps1` covers WezTerm, Starship, fastfetch, zoxide, Git, GitHub CLI, PowerShell,
Windows Terminal, VS Code, 7-Zip, Tailscale, Brave, Discord and the Visual Studio Build Tools
package entry — but the Build Tools' C++ workload needs the override flag, winget's plain
install won't include it:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override `
  "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Only needed if you'll build `jot` from source. Skip it if you just want the prebuilt `jot.exe`
from its GitHub releases.

VS Code extensions:

```powershell
Get-Content dotfiles\vscode\extensions.txt | ForEach-Object { code --install-extension $_ }
```

(`install.ps1` already does this automatically — listed here only for reference.)

## 5. Sign in to the rest

- `tailscale login` — needed to reach `royalclean-vps` over SSH.
- Open Brave / Discord and sign in if you use their sync.

## 6. Restore your own files

```powershell
robocopy "G:\Dev" "$HOME\projects" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "G:\Andrew" "$HOME\Documents\Andrew" /E /COPY:DAT /DCOPY:DAT /MT:8
robocopy "G:\Games\Emulators" "C:\Games\Emulators" /E /COPY:DAT /DCOPY:DAT /MT:8
```

`G:\Dev` is where you keep your own ongoing backup of `~/projects` — restore from whatever is
there at the time, it isn't something this guide or Claude creates for you. Repos that are
already on GitHub under your account (`dotfiles`, `alacritty-ports`, `jot`, `lifty`, `busterm`,
`citari` and the rest) don't need this at all, just `git clone` them again as needed.

Restore Claude's memory of this setup, so it doesn't start from zero:

```powershell
Copy-Item "G:\Credentials\claude-memory\*" "$HOME\.claude\projects\C--Users-Zel\memory\" -Force
```

(The project folder hash `C--Users-Zel` is derived from the working directory path; if you're
not working from `C:\Users\Zel`, Claude Code will use a different one — ask it where its memory
directory is and copy there instead.)

Steam, Riot: reinstall the clients into `C:\Games\Steam` and `C:\Games\Riot Games`, libraries
aren't something a file copy restores cleanly.

## 7. Verify

- New WezTerm window: Alacritty colors, `IosevkaTerm Nerd Font Mono`, Starship prompt reads
  `zel@w10 ~ ❯`.
- `proj` jumps to `~\projects`.
- `git commit` on any repo produces a **Verified** commit once the same SSH key is also added
  as a signing key in your GitHub account settings (this is a GitHub-side setting, not
  reproduced by any file here).
- `jot` opens with a translucent window and the tab bar; `cargo build --release` in `~/projects/jot`
  if you installed the Build Tools.

## What's intentionally not backed up

- `~/.ssh` itself, `G:\Credentials` and this repo never store the private keys in git — only
  `G:\Credentials\ssh` has them, restored by copy in step 2.
- GitHub CLI and Tailscale tokens: re-created by signing in, not stored anywhere.
- `MNRepo` (was under `ambiente-web`) points at `github.com/ecalvo92/MNRepo`, someone else's
  account — confirm you still have access rather than expecting to reproduce it here.
