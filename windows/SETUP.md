# Reinstall guide

Steps to rebuild this machine by hand after a fresh Windows 10 or 11 install. Updated 2026-10-09.

Projects live in `C:\dev`. The `dev` shell shortcut already points there. Personal files live in
`~\files`, not `Documents`, which programs fill with their own folders.

Every block below is plain PowerShell, copy and paste it straight into a terminal. Most steps
check first and skip anything already in place, so it is fine to run a step again.

## 0. Before touching the installer

Use a custom install and format only the OS drive. The other physical drives, including the
backup drive (labeled `Backup`) and the Ventoy USB stick, must not be selected in the Windows
installer's partition screen.

Then install drivers and run Windows Update, rebooting until nothing is pending. A pending
reboot makes some installers in step 4 fail (Visual Studio Build Tools exits with 5008).

### DNS: IPv4 only

This connection has no working IPv6 (the router announces an IPv6 route, but the PC only gets a
`fe80::` address). With IPv6 DNS servers configured, Windows tries them first for every new name
and waits for them to time out: every new site takes 7 to 15 s to start loading.

- If you debloat with WinUtil, set its DNS option to **Default**, never a provider: picking one
  (Cloudflare, Google...) also sets its IPv6 servers. Its "IPv6: Set IPv4 as Preferred" tweak
  is fine to keep, it does not touch DNS.
- Set Cloudflare by hand, **IPv4 only**:
  - **Windows 11**, in the Settings app: Settings > Network & internet > Ethernet > DNS server
    assignment > Edit > Manual. Turn on **IPv4**: preferred `1.1.1.1`, alternate `1.0.0.1`, DNS
    over HTTPS **On (automatic template)** for both. Leave **IPv6 off**. Save.
  - **Windows 10**, whose Settings app cannot change only the DNS and has no DNS over HTTPS:
    Win + R, `ncpa.cpl`, right click Ethernet > Properties. "Internet Protocol Version 4
    (TCP/IPv4)" > "Use the following DNS server addresses": `1.1.1.1` and `1.0.0.1`. "Internet
    Protocol Version 6 (TCP/IPv6)" > "Obtain DNS server address automatically". OK on both.

Step 8 checks that it worked.

## 1. Base tools

`winget` comes with the App Installer package. On a fresh Windows 10 it can be missing or too
old: if `winget --version` fails, update **App Installer** from the Microsoft Store first.

```powershell
winget --version
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { winget install --id Git.Git -e } else { "Git already installed" }
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { winget install --id Microsoft.PowerShell -e } else { "PowerShell 7 already installed" }
```

Close that window and open **PowerShell 7** (`pwsh`). Every step below runs in it.

## 2. Find the backup drive

Its letter is not fixed (it changes with what else is plugged in), so look it up by label:

```powershell
$backup = (Get-Volume -FileSystemLabel Backup).DriveLetter + ":"
$backup
```

Steps 3 and 6 use `$backup`. In a new window, run this block again first.

## 3. Restore SSH keys and Git identity

```powershell
if (Test-Path "$HOME\.ssh\id_ed25519_github") {
    "SSH keys already present, skipping"
} else {
    New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
    Copy-Item "$backup\credentials\.ssh\*" "$HOME\.ssh\" -Force
    icacls "$HOME\.ssh" /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F" | Out-Null
    Get-ChildItem "$HOME\.ssh" -File | ForEach-Object {
        icacls $_.FullName /inheritance:r /grant:r "${env:USERNAME}:F" /grant:r "SYSTEM:F" | Out-Null
    }
}

if (Test-Path "$HOME\.config\git\config") {
    "Git config already present, skipping"
} else {
    New-Item -ItemType Directory -Force "$HOME\.config\git" | Out-Null
    Copy-Item "$backup\credentials\.config\git\*" "$HOME\.config\git\" -Force
}

ssh -T git@github.com
```

The last line should answer `Hi zeldxh!` (its exit code is 1 even then, GitHub gives no shell).
The `icacls` lines matter: OpenSSH refuses a private key that other accounts can read.

## 4. Clone the dotfiles and install everything

```powershell
New-Item -ItemType Directory -Force "C:\dev" | Out-Null
if (Test-Path "C:\dev\dotfiles") { "dotfiles already cloned" } else { git clone git@github.com:zeldxh/dotfiles.git "C:\dev\dotfiles" }
Set-Location "C:\dev\dotfiles"
pwsh ./windows/packages/install-packages.ps1
```

`install-packages.ps1` installs, with `winget`: Git, GitHub CLI, PowerShell, Windows Terminal,
Starship, fastfetch, zoxide, mise, VS Code, 7-Zip, Tailscale, Brave, Discord and Visual Studio
Build Tools. Then the IosevkaTerm Nerd Font, the "Open with Code" Explorer menu and the
Terminal-Icons module. Some installers ask for admin rights (UAC), accept them.

**Close the window and open a new one** so `code` and the rest are on PATH. Without this,
`install.ps1` skips the VS Code extensions and the Ash theme.

```powershell
Set-Location "C:\dev\dotfiles"
pwsh ./windows/install.ps1
git config core.hooksPath hooks
```

`install.ps1` copies the configs into place (PowerShell profile, Starship, fastfetch, git, mise,
Windows Terminal, VS Code settings), installs the VS Code extensions in
`shared/vscode/extensions.txt`, clones [`ash-theme`](https://github.com/zeldxh/ash-theme) next to
`dotfiles` and installs it into VS Code, and patches Discord with Vencord. The last line enables
the pre-push hook that checks for secrets before a push.

Both scripts are safe to run again. Run `install.ps1` again after a Discord update, which undoes
the Vencord patch.

## 5. Sign in to the rest

```powershell
if ((gh auth status 2>&1) -match "Logged in") { "Already signed in to GitHub CLI" } else { gh auth login }
tailscale login
mise install
```

In `gh auth login` pick GitHub.com, SSH, **Skip** the key upload (`id_ed25519_github` is already
on the account), and log in with the browser. `mise install` installs node, java, python, pnpm
and fzf. Sign in to Brave and Discord too if you use their sync, there is nothing to script for
either.

## 6. Restore your own files

Robocopy only copies what is missing or changed, so these are safe to run more than once.

```powershell
foreach ($d in 'business', 'personal', 'university') {
    robocopy "$backup\$d" "$HOME\files\$d" /E /COPY:DAT /DCOPY:DAT /MT:8
}
robocopy "$backup\games\emulators" "C:\Games\Emulators" /E /COPY:DAT /DCOPY:DAT /MT:8
```

`security` (account recovery codes and the like) stays on the backup drive only. Projects come
back by cloning them from GitHub into `C:\dev`.

Reinstall Steam and Riot into `C:\Games\Steam` and `C:\Games\Riot Games` directly, a file copy
doesn't restore a game library properly.

## 7. Optional: SSH into this PC from the other machines

Windows has no SSH server by default. From an **admin** PowerShell:

```powershell
pwsh -ExecutionPolicy Bypass -File "$backup\credentials\scripts\enable-sshd.ps1"
```

It installs OpenSSH Server (several silent minutes on the first step), allows port 22 only from
Tailscale addresses (`100.64.0.0/10`), makes PowerShell 7 the login shell and authorizes sao's
key, so `ssh atlas` from sao gets in without a password.

## 8. Verify

DNS first: no IPv6 DNS servers, and a lookup of a name nobody asked for before (so the cache
cannot hide anything) well under 1000 ms:

```powershell
Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv6 | Select-Object -ExpandProperty ServerAddresses
(Measure-Command { Resolve-DnsName "check$(Get-Random).cloudflare.com" }).TotalMilliseconds
```

The first line must print nothing. If it prints addresses and the lookup takes seconds, remove
them from an admin terminal: `netsh interface ipv6 delete dnsservers "Ethernet" all`.

Open a new Windows Terminal window and check for the Ash color scheme, the IosevkaTerm font, and
the Starship prompt showing `user@hostname`. Running `dev` should jump to `C:\dev`. VS Code
should open with the Ash theme. A commit should show as verified once the same SSH key is also
added as a signing key in your GitHub account settings, which is a setting on GitHub's side and
not something restored by any file here.

## What is intentionally not backed up

SSH private keys never go into any git repository, only into `credentials\.ssh` on the backup
drive, restored by copy in step 3. GitHub CLI and Tailscale tokens are not stored anywhere, they
come back by signing in again.
