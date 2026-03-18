# ⚡ BatchMaster Toolkit

**One repository. Every script you need to own your machine.**
Cross-platform power-user automation for Windows (.bat), macOS (.sh), and Linux (.sh) — built for developers, sysadmins, and anyone who refuses to click through GUIs.

---

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white)](./windows/)
[![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)](./macos/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)](./linux/)
[![Scripts](https://img.shields.io/badge/Scripts-30%2B-brightgreen)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

---

## Table of Contents

- [Why This Toolkit](#why-this-toolkit)
- [Repository Structure](#repository-structure)
- [Script Directory](#script-directory)
  - [Windows](#-windows-scripts-bat)
  - [macOS](#-macos-scripts-sh)
  - [Linux](#-linux-scripts-sh)
- [Quick Start](#quick-start)
- [Safety & Backup Policy](#safety--backup-policy)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Toolkit

Most power-user scripts are scattered across forums, pastebin, and decade-old blog posts. This repo solves that by giving you:

- **Categorized, documented scripts** — no mystery meat
- **Cross-platform parity** — same job done the right way on each OS
- **Safe defaults** — every destructive operation has a confirmation prompt
- **Extensible structure** — add your own scripts in the right folder and they just fit

---

## Repository Structure

```
BatchMaster-Toolkit/
│
├── windows/
│   ├── System-Diagnostics/
│   │   ├── SystemInfo.bat
│   │   ├── BatteryGuard.bat
│   │   ├── DriverChecker.bat
│   │   ├── BootSpeedAnalyzer.bat
│   │   └── ThermalMonitor.bat
│   │
│   ├── Maintenance-Cleaning/
│   │   ├── DeepClean.bat
│   │   ├── RAMCleaner.bat
│   │   ├── LargeFileFinder.bat
│   │   ├── DuplicateFinder.bat
│   │   └── RecycleBinManager.bat
│   │
│   ├── Network-Tools/
│   │   ├── NetworkOptimizer.bat
│   │   ├── WifiPasswordViewer.bat
│   │   ├── PortScanner.bat
│   │   ├── NetworkSpeedLogger.bat
│   │   └── ConnectionKiller.bat
│   │
│   ├── Security-Privacy/
│   │   ├── PrivacyGuard.bat
│   │   ├── AccountAuditor.bat
│   │   ├── AutorunAuditor.bat
│   │   └── SuspiciousProcessHunter.bat
│   │
│   └── Utility-Scripts/
│       ├── GameBoost.bat
│       ├── FileOrganizer.bat
│       ├── FolderBackup.bat
│       ├── AppInstaller.bat
│       ├── PCHealthScore.bat
│       └── SystemBenchmark.bat
│
├── macos/
│   ├── System-Diagnostics/
│   ├── Maintenance-Cleaning/
│   ├── Network-Tools/
│   ├── Security-Privacy/
│   └── Utility-Scripts/
│
├── linux/
│   ├── System-Diagnostics/
│   ├── Maintenance-Cleaning/
│   ├── Network-Tools/
│   ├── Security-Privacy/
│   └── Utility-Scripts/
│
├── manifest.json
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## Script Directory

> [!IMPORTANT]
> **All scripts in this repository must be run as Administrator (Windows) or with `sudo` (macOS/Linux).**
> Running without elevated privileges will cause silent failures or incomplete results.
> Right-click any `.bat` file → **Run as administrator**.

---

### 🪟 Windows Scripts (.bat)

#### System-Diagnostics/

| File | Description |
|------|-------------|
| `SystemInfo.bat` | Full interactive dashboard — CPU, RAM, GPU, disk, battery, network, and security in one place. Live bar charts for CPU load and disk usage. |
| `BatteryGuard.bat` | Detailed battery health report including wear level percentage, charge cycle estimate, and a health alert when capacity drops below 80%. |
| `DriverChecker.bat` | Lists all installed drivers with version numbers and dates. Flags drivers older than 1 year and any unsigned/unverified drivers. |
| `BootSpeedAnalyzer.bat` | Reads Windows boot event logs and ranks which startup programs and services are adding the most time to your boot sequence. |
| `ThermalMonitor.bat` | Live refresh loop showing CPU and disk temperatures via WMI. Triggers a color-coded warning when temps exceed defined thresholds. |

#### Maintenance-Cleaning/

| File | Description |
|------|-------------|
| `DeepClean.bat` | Full system clean: user/system temp folders, prefetch, thumbnail cache, DNS cache, browser caches (Edge, Chrome, Firefox), Windows Update cache, recycle bin, event logs, and error reports. |
| `RAMCleaner.bat` | Clears the Windows RAM standby list and working set. Displays before/after memory usage so you can see the actual freed RAM. |
| `LargeFileFinder.bat` | Scans all drives for files over 100 MB. Outputs a ranked list with file size, name, and full path so you can decide what to remove. |
| `DuplicateFinder.bat` | Scans a user-specified folder for duplicate files by comparing size and name. Lists all duplicates with full paths for manual review. |
| `RecycleBinManager.bat` | Shows the current size of every drive's recycle bin and lets you empty them individually or all at once from an interactive menu. |

#### Network-Tools/

| File | Description |
|------|-------------|
| `NetworkOptimizer.bat` | Full network tune-up: flush DNS, release/renew IP, reset Winsock and TCP/IP stack, set fast DNS servers, disable network throttling, and run a before/after ping comparison. |
| `WifiPasswordViewer.bat` | Reads all saved WiFi profiles from the Windows credential store and displays each network name alongside its saved password in plain text. |
| `PortScanner.bat` | Scans the 50 most common ports on localhost. Reports which ports are open and which running process or service is bound to each one. |
| `NetworkSpeedLogger.bat` | Pings 5 servers (Google, Cloudflare, OpenDNS, etc.) every 10 seconds for 5 minutes and writes a timestamped latency log to your Desktop. |
| `ConnectionKiller.bat` | Lists all active TCP connections with their remote address and owning PID. Lets you terminate any connection by selecting it from the list. |

#### Security-Privacy/

| File | Description |
|------|-------------|
| `PrivacyGuard.bat` | Disables Windows telemetry services, Cortana data collection, advertising ID, Windows Error Reporting, and Customer Experience Improvement. Blocks known tracking domains via the hosts file. Fully reversible. |
| `AccountAuditor.bat` | Lists all local user accounts with last login timestamps. Flags accounts that have never been logged into, accounts with blank passwords, and disabled accounts that still exist. |
| `AutorunAuditor.bat` | Scans all known autorun registry keys and startup folders. Flags any entries pointing to temp directories, unusual locations, or paths that no longer exist. |
| `SuspiciousProcessHunter.bat` | Scans all running processes and flags any executing from `%TEMP%`, `%APPDATA%`, Downloads, or other non-standard locations that are commonly used by malware. |

#### Utility-Scripts/

| File | Description |
|------|-------------|
| `GameBoost.bat` | Pre-game optimizer: kills background apps, sets CPU to High Performance power plan, disables Windows Update and Defender scanning, boosts network for low-latency, and restores everything afterward. |
| `FileOrganizer.bat` | Scans a folder and automatically sorts all files into typed subfolders: Images, Documents, Videos, Music, Archives, and Others — based on file extension. |
| `FolderBackup.bat` | Interactive backup script. Prompts for source and destination folders, copies all files with a timestamped folder name, and shows a live progress counter. |
| `AppInstaller.bat` | One-click silent installer using `winget`. Installs Chrome, VLC, 7-Zip, Notepad++, and VS Code with no popups. Checks if each app is already installed before proceeding. |
| `PCHealthScore.bat` | Runs 10 quick diagnostic checks (RAM usage, disk health, CPU load, battery level, firewall status, Defender state, open ports, startup bloat, etc.) and gives your PC a score out of 100 with a letter grade. |
| `SystemBenchmark.bat` | Benchmarks CPU (arithmetic operations per second), disk read/write speed (using `fsutil`), and RAM throughput. Outputs a summary table with a performance tier rating. |

---

### 🍎 macOS Scripts (.sh)

> [!NOTE]
> macOS scripts use `#!/bin/bash` or `#!/bin/zsh`. Run with `chmod +x script.sh && ./script.sh` or `sudo ./script.sh` for privileged operations.

#### System-Diagnostics/

| File | Description |
|------|-------------|
| `system_info.sh` | Full system snapshot using `system_profiler`, `sysctl`, `top`, and `df`. Displays CPU, RAM, GPU, disk, battery (on MacBooks), and macOS version. |
| `battery_health.sh` | Reads battery cycle count, condition, and max capacity from `ioreg`. Calculates wear percentage and flags batteries past 80% wear. |
| `disk_health.sh` | Runs `diskutil` and `smartctl` (if available) on all physical disks. Reports SMART status, temperature, and reallocated sector count. |

#### Maintenance-Cleaning/

| File | Description |
|------|-------------|
| `deep_clean.sh` | Clears system and user caches (`~/Library/Caches`), DNS cache (`dscacheutil -flushcache`), Spotlight index rebuild, Homebrew cleanup, old log files, and Trash. |
| `brew_maintenance.sh` | Runs `brew update`, `brew upgrade`, `brew cleanup --prune=all`, and `brew doctor` in sequence. Reports reclaimed disk space. |
| `large_file_finder.sh` | Uses `find` to locate files over 500 MB anywhere on the filesystem and outputs a ranked list with human-readable sizes. |

#### Network-Tools/

| File | Description |
|------|-------------|
| `network_optimizer.sh` | Flushes DNS cache, renews DHCP lease, resets network preferences, and sets Cloudflare (1.1.1.1) and Google (8.8.8.8) as DNS resolvers. |
| `wifi_passwords.sh` | Reads saved WiFi passwords from the macOS Keychain using `security find-generic-password`. Requires user password confirmation per entry. |
| `port_scanner.sh` | Uses `nmap` (or `nc` fallback) to scan localhost for open ports and lists which service is bound to each. |

#### Security-Privacy/

| File | Description |
|------|-------------|
| `privacy_guard.sh` | Disables macOS telemetry (`diagnostics`), Safari suggestions, Spotlight Siri suggestions, and location services for system analytics. |
| `firewall_manager.sh` | Enables the macOS Application Firewall via `socketfilterfw`, turns on stealth mode, and lists all firewall rules. |
| `gatekeeper_check.sh` | Reports current Gatekeeper status, lists quarantined apps (`xattr -r`), and checks System Integrity Protection status via `csrutil`. |

---

### 🐧 Linux Scripts (.sh)

> [!NOTE]
> Linux scripts are tested on Ubuntu 22.04+ and Debian 12+. Package manager commands default to `apt`. Adjust for `dnf`/`pacman` as needed.

#### System-Diagnostics/

| File | Description |
|------|-------------|
| `system_info.sh` | Collects OS version, kernel, CPU (`lscpu`), RAM (`free -h`), disk (`df -h`, `lsblk`), GPU (`lspci`), and uptime into a formatted dashboard. |
| `hardware_report.sh` | Uses `dmidecode`, `lshw`, and `inxi` (if available) to generate a detailed hardware inventory report and saves it to `~/hardware_report.txt`. |
| `thermal_monitor.sh` | Reads CPU temperatures from `/sys/class/thermal/` and `sensors` (lm-sensors). Loops every 5 seconds with a color-coded warning threshold. |

#### Maintenance-Cleaning/

| File | Description |
|------|-------------|
| `deep_clean.sh` | Clears `apt` cache (`apt autoremove`, `apt clean`), user cache (`~/.cache`), old logs (`/var/log`), temp files (`/tmp`), thumbnail cache, and old snap versions. |
| `log_cleaner.sh` | Truncates all files in `/var/log` older than 7 days, runs `journalctl --vacuum-time=7d`, and reports reclaimed space. |
| `orphan_cleaner.sh` | Finds and removes orphaned packages (`deborphan`), unused kernels (keeps current + 1), and broken symlinks in `/usr/local`. |

#### Network-Tools/

| File | Description |
|------|-------------|
| `network_optimizer.sh` | Flushes DNS (`systemd-resolve --flush-caches`), resets network interface, sets Google/Cloudflare DNS in `/etc/resolv.conf`, and tests latency. |
| `port_scanner.sh` | Uses `ss -tulnp` to list all listening ports with owning processes. Optionally runs `nmap localhost` for a fuller picture. |
| `bandwidth_monitor.sh` | Uses `nethogs` or `iftop` to show real-time per-process bandwidth usage. Falls back to `vnstat` daily stats if neither is installed. |

#### Security-Privacy/

| File | Description |
|------|-------------|
| `privacy_guard.sh` | Disables `whoopsie` (Ubuntu crash reporter), `apport`, `avahi-daemon` (mDNS), and `cups` if not in use. Blocks ad/tracker domains in `/etc/hosts`. |
| `ufw_setup.sh` | Configures UFW with secure defaults: deny all incoming, allow all outgoing, allow SSH only from local subnet, enable logging. |
| `rootkit_scan.sh` | Installs and runs `rkhunter` and `chkrootkit` if not present. Saves a timestamped scan report to `~/security_scan_YYYYMMDD.txt`. |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/BatchMaster-Toolkit.git
cd BatchMaster-Toolkit

# 2. Windows — navigate to the script you need
cd windows/System-Diagnostics
# Right-click SystemInfo.bat → Run as administrator
# OR from an elevated Command Prompt:
SystemInfo.bat

# 3. macOS / Linux — make scripts executable
chmod +x macos/System-Diagnostics/system_info.sh
./macos/System-Diagnostics/system_info.sh
# For privileged operations:
sudo ./macos/Maintenance-Cleaning/deep_clean.sh
```

> [!IMPORTANT]
> **Windows users:** Never double-click a script you have not read first. Open it in Notepad, understand what it does, then run it as Administrator.

> [!WARNING]
> **Backup your data before running any Maintenance-Cleaning or Security-Privacy script.**
> These scripts delete files, modify the registry, or change system settings. While they are designed to be safe and reversible, running them on a system without a backup is entirely at your own risk.

---

## Safety & Backup Policy

Every script in this repository follows these rules:

| Rule | How it is enforced |
|------|--------------------|
| No silent destructive actions | All delete/modify operations print what they will do before doing it |
| Reversible changes | Scripts that modify registry or system settings include a documented undo option |
| Admin check | Scripts that require elevation check for it on launch and warn the user if missing |
| No network downloads | No script downloads or executes code from the internet at runtime |
| Tested on clean VMs | All scripts are tested on fresh OS installs before being merged |

> [!CAUTION]
> The `Security-Privacy/PrivacyGuard` scripts modify system settings and hosts files. Test them on a non-critical machine first if you are unsure about the impact on your workflow.

---

## Contributing

Pull requests are welcome. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) before submitting a script.

The short version:
1. Fork the repo
2. Add your script to the correct category folder for the correct OS
3. Update `manifest.json` with your script's entry
4. Open a PR with a clear description of what the script does and what it was tested on

---

## License

MIT — see [LICENSE](./LICENSE) for details.

---

<p align="center">
  Built by the community, for the community. Star ⭐ the repo if it saved you time.
</p>
