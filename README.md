
<img width="1492" height="833" alt="image" src="https://github.com/user-attachments/assets/1c848b12-59dd-4a85-af34-b413503f9863" />

## Installation

Run the following command in PowerShell:

```powershell
irm https://raw.githubusercontent.com/ruru-o/bao-shell/main/bao-shell.ps1 | iex
```

### Script Execution Policy

The script automatically configures the `CurrentUser` execution policy to `RemoteSigned` during setup:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

This configuration executes without requiring Administrator privileges and ensures that newly spawned terminal sessions load the dot-sourced profile script without encountering `PSSecurityException: UnauthorizedAccess` errors on fresh Windows installations.

## Features

- Dependency bootstrapping via `winget` (PowerShell 7, Oh My Posh, Fastfetch).
- Automated JetBrainsMono Nerd Font downloading and Windows GDI font installation.
- Custom Fastfetch system information layout with ASCII branding.
- Automatic backups of existing PowerShell profiles prior to modification.
- Interactive TUI menu for setup, reverting configuration, or full system purges.
- Straightforward failure diagnostic output for package installation errors.

## Components

| Component | Function |
| --- | --- |
| `winget` | Windows Package Manager for dependency bootstrapping |
| `PowerShell 7` | Core terminal shell execution environment |
| `oh-my-posh` | Prompt engine configured with agnosterplus theme |
| `fastfetch` | Fast system fetch visualization on terminal launch |
| `bao-shell` | My Windows Terminal settings |

## Interactive TUI Interface

<img width="1221" height="685" alt="image" src="https://github.com/user-attachments/assets/f97b8b53-29c3-40e8-8676-357601cc1832" />

Running `bao-shell.ps1` without parameters opens the interactive console interface:

- **Install**: Installs missing dependencies, sets up font, updates PowerShell profiles, and applies Windows Terminal defaults.
- **Uninstall**: Opens the revert menu with granular options:
  - `[1] Profiles & Configs`: Restores PowerShell profiles and cleans Fastfetch configurations.
  - `[2] Terminal Defaults`: Reverts Windows Terminal font, opacity, and color schemes.
  - `[3] Full System Purge`: Restores profiles, resets terminal settings, and uninstalls packages via winget.
  - `[4] Back to Main Menu`: Cancels revert operation.
- **Exit**: Exits the terminal session.

## Command-Line Parameters

For automated deployments or non-interactive automation:

```powershell
# Non-interactive automated setup
.\bao-shell.ps1 -Force

# Non-interactive full system purge
.\bao-shell.ps1 -Uninstall

# Skip font installation during setup
.\bao-shell.ps1 -SkipFont

# Overwrite profiles without creating backups
.\bao-shell.ps1 -NoBackup
```

| Parameter | Type | Description |
| --- | --- | --- |
| `-Force` | Switch | Runs non-interactive installation immediately |
| `-Uninstall` | Switch | Performs non-interactive full system purge |
| `-SkipFont` | Switch | Bypasses JetBrainsMono Nerd Font installation |
| `-NoBackup` | Switch | Overwrites existing profiles without creating `.bak` backups |

## Reverting Changes

To revert changes and restore previous settings:

1. Run `.\bao-shell.ps1` and select `Uninstall`.
2. Choose `[3] Full System Purge` to remove all configurations and installed packages.

Alternatively, run non-interactively:

```powershell
.\bao-shell.ps1 -Uninstall
```

Existing profile files are backed up to `$HOME\Documents\PowerShell\` with `.bak-<timestamp>` extensions prior to any modifications.
