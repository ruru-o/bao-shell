# bao-shell

<img width="1291" height="741" alt="Screenshot 2026-08-09 194149" src="https://github.com/user-attachments/assets/de56723b-0812-4cb9-8c1f-d588108624c5" />

## Quick Installation

Run the following command in PowerShell:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iex (irm https://raw.githubusercontent.com/ruru-o/bao-shell-profile/main/bao-shell.ps1)
```

> [!WARNING]
> If you're in a newly installed operating system, Windows blocks custom PowerShell scripts by default on fresh installs. Setting `CurrentUser` scope enables user profile scripts without requiring administrator privileges.

Alternative process execution policy bypass syntax:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (irm https://raw.githubusercontent.com/ruru-o/bao-shell-profile/main/bao-shell.ps1)
```

## Features

- Bootstrap dependencies via winget (PowerShell 7, Oh My Posh, Fastfetch).
- Automated font installation for JetBrainsMono Nerd Font.
- Custom Fastfetch system info layout with ASCII branding.
- Automatic backups of existing PowerShell profiles before modification.
- Interactive TUI menu for installation, custom reverting, or full system purge.

## Environment Components

<img width="1230" height="685" alt="Screenshot 2026-08-09 194312" src="https://github.com/user-attachments/assets/f67b98be-8fde-4d1b-a2d4-43a11b4202e1" />

| Component | Function |
| --- | --- |
| `winget` | Windows Package Manager for dependency bootstrap |
| `PowerShell 7` | Core terminal shell execution environment |
| `oh-my-posh` | Prompt engine configured with agnosterplus theme |
| `fastfetch` | Fast system fetch visualization on terminal launch |
| `Nerd Font` | JetBrainsMono Nerd Font Mono with glyph support |
| `terminal theme` | Custom Windows Terminal settings (40% opacity, One Half Dark) |

## Interactive Menu

Running `bao.ps1` without flags launches the interactive console interface:

- **Install**: Bootstraps missing dependencies, configures profiles, and updates terminal settings.
- **Uninstall**: Opens the revert menu with granular options:
  - `[1] Profiles & Configs`: Reverts PowerShell profiles and cleans Fastfetch configuration.
  - `[2] Terminal Defaults`: Resets Windows Terminal font, opacity, and color schemes.
  - `[3] Full System Purge`: Restores profiles, resets terminal settings, and uninstalls packages via winget.
  - `[4] Back to Main Menu`: Cancels revert operation.
- **Cancel**: Exits the installer without making changes.

## Command-Line Arguments

The script supports automated non-interactive parameters:

```powershell
# Non-interactive automated setup
.\bao.ps1 -Force

# Skip font download during installation
.\bao.ps1 -SkipFont

# Install without creating backup files
.\bao.ps1 -NoBackup

# Full automated system purge
.\bao.ps1 -Uninstall
```

| Parameter | Type | Description |
| --- | --- | --- |
| `-Force` | Switch | Runs non-interactive installation immediately |
| `-Uninstall` | Switch | Performs non-interactive full system purge |
| `-SkipFont` | Switch | Bypasses JetBrainsMono Nerd Font installation |
| `-NoBackup` | Switch | Overwrites existing profiles without creating `.bak` backups |

## File Layout

```text
bao-shell/
├── bao.ps1                             # Installer and uninstaller tool
├── config/
│   ├── ascii.txt                       # ASCII banner for Fastfetch
│   └── config.jsonc                    # Fastfetch configuration
└── profile/
    └── Microsoft.PowerShell_profile.ps1 # Managed PowerShell profile
```

## Reverting Changes

To completely revert all modifications:

1. Open PowerShell and run `.\bao.ps1`.
2. Select `Uninstall` from the main menu.
3. Select `[3] Full System Purge`.

Alternatively, execute:

```powershell
.\bao.ps1 -Uninstall
```

Existing profile files are preserved in `$HOME\Documents\PowerShell\` with `.bak-<timestamp>` extensions prior to any modifications.
