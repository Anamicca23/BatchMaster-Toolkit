<a name="top"></a>

<div align="center">

# ⚡ BatchMaster Toolkit

### One repository. Every script you need to own your machine.

Cross-platform power-user automation for **Windows**, **macOS**, and **Linux** —
built for developers, sysadmins, and anyone who refuses to click through GUIs.

<br/>

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](./windows/)
[![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](./macos/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](./linux/)

<br/>

[![Scripts](https://img.shields.io/badge/Scripts-30%2B-brightgreen?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-orange?style=flat-square)](./CONTRIBUTING.md)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-success?style=flat-square)]()
[![Admin Required](https://img.shields.io/badge/Some%20Scripts-Admin%20Required-red?style=flat-square)]()

</div>

---

## Table of Contents

- [Why This Toolkit](#why-this-toolkit)
- [Repository Structure](#repository-structure)
- [Script Directory](#script-directory)
  - [🪟 Windows Scripts](#-windows-scripts-bat)
  - [🍎 macOS Scripts](#-macos-scripts-sh)
  - [🐧 Linux Scripts](#-linux-scripts-sh)
- [Quick Start](#quick-start)
- [Safety & Backup Policy](#safety--backup-policy)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Toolkit

Most power-user scripts are scattered across forums, pastebin, and decade-old blog posts.
This repo solves that with a single, organized, documented collection.

| What you get | Why it matters |
|---|---|
| Categorized scripts per OS | Find what you need in seconds, not minutes |
| Plain-text readable code | Audit every line before running it |
| Safe defaults everywhere | Every destructive operation asks before acting |
| Cross-platform parity | Same job done the right way on each OS |
| `manifest.json` metadata | Build tooling, search UIs, or CI checks on top |

---

## Repository Structure

```
BatchMaster-Toolkit/
│
├── windows/
│   ├── System-Diagnostics/
│   ├── Maintenance-Cleaning/
│   ├── Network-Tools/
│   ├── Security-Privacy/
│   └── Utility-Scripts/
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
├── REPO_STRUCTURE.md
└── LICENSE
```

> See [`REPO_STRUCTURE.md`](./REPO_STRUCTURE.md) for the fully annotated tree with one-line descriptions on every script.

---

## Script Directory

> [!IMPORTANT]
> **All Windows scripts must be run as Administrator.**
> Right-click any `.bat` file → **Run as administrator**.
> macOS and Linux scripts requiring elevation must be run with `sudo`.
> Running without the correct privileges causes silent failures or incomplete results.

---

### 🪟 Windows Scripts (.bat)

#### 📊 System-Diagnostics

| File | Description | Admin |
|------|-------------|:-----:|
| [`SystemInfo.bat`](./windows/System-Diagnostics/SystemInfo.bat) | Full interactive dashboard — CPU, RAM, GPU, disk, battery, network, processes, and security with live bar charts. | ✅ |
| [`BatteryGuard.bat`](./windows/System-Diagnostics/BatteryGuard.bat) | Battery wear level, charge cycle estimate, and alerts when capacity drops below 80%. | ❌ |
| [`DriverChecker.bat`](./windows/System-Diagnostics/DriverChecker.bat) | Lists all installed drivers with version and date. Flags drivers older than 1 year and any unsigned entries. | ✅ |
| [`BootSpeedAnalyzer.bat`](./windows/System-Diagnostics/BootSpeedAnalyzer.bat) | Reads Windows event logs and ranks which startup items are adding the most seconds to your boot time. | ✅ |
| [`ThermalMonitor.bat`](./windows/System-Diagnostics/ThermalMonitor.bat) | Live refresh loop showing CPU and disk temperatures via WMI. Color-coded threshold warnings. | ❌ |

#### 🧹 Maintenance-Cleaning

| File | Description | Admin |
|------|-------------|:-----:|
| [`DeepClean.bat`](./windows/Maintenance-Cleaning/DeepClean.bat) | 14-step clean: temp folders, prefetch, thumbnails, DNS cache, all browser caches, Windows Update cache, recycle bin, event logs. | ✅ |
| [`RAMCleaner.bat`](./windows/Maintenance-Cleaning/RAMCleaner.bat) | Clears standby RAM and working set. Displays before and after memory usage to measure the actual gain. | ✅ |
| [`LargeFileFinder.bat`](./windows/Maintenance-Cleaning/LargeFileFinder.bat) | Scans all drives for files over 100 MB. Outputs a ranked list with full paths and sizes. | ❌ |
| [`DuplicateFinder.bat`](./windows/Maintenance-Cleaning/DuplicateFinder.bat) | Scans a chosen folder for duplicate files by size and name. Lists all duplicates with paths for manual review. | ❌ |
| [`RecycleBinManager.bat`](./windows/Maintenance-Cleaning/RecycleBinManager.bat) | Shows recycle bin size per drive. Empty them individually or all at once from an interactive menu. | ❌ |

#### 🌐 Network-Tools

| File | Description | Admin |
|------|-------------|:-----:|
| [`NetworkOptimizer.bat`](./windows/Network-Tools/NetworkOptimizer.bat) | Flush DNS, reset Winsock and TCP stack, set fast DNS servers, disable throttling, before/after ping test. | ✅ |
| [`WifiPasswordViewer.bat`](./windows/Network-Tools/WifiPasswordViewer.bat) | Reads all saved WiFi profiles and displays each network name alongside its stored password. | ✅ |
| [`PortScanner.bat`](./windows/Network-Tools/PortScanner.bat) | Scans the 50 most common ports on localhost. Reports which are open and which process is bound to each. | ❌ |
| [`NetworkSpeedLogger.bat`](./windows/Network-Tools/NetworkSpeedLogger.bat) | Pings 5 servers every 10 seconds for 5 minutes and writes a timestamped latency log to your Desktop. | ❌ |
| [`ConnectionKiller.bat`](./windows/Network-Tools/ConnectionKiller.bat) | Lists all active TCP connections with remote address and PID. Terminate any by selecting it from the list. | ✅ |

#### 🔒 Security-Privacy

| File | Description | Admin |
|------|-------------|:-----:|
| [`PrivacyGuard.bat`](./windows/Security-Privacy/PrivacyGuard.bat) | Disables telemetry, Cortana tracking, advertising ID, and blocks tracking domains in the hosts file. Fully reversible. | ✅ |
| [`AccountAuditor.bat`](./windows/Security-Privacy/AccountAuditor.bat) | Lists all local user accounts with last login times. Flags unused accounts and those with blank passwords. | ✅ |
| [`AutorunAuditor.bat`](./windows/Security-Privacy/AutorunAuditor.bat) | Scans all registry autorun keys and startup folders. Flags entries pointing to temp dirs or missing paths. | ✅ |
| [`SuspiciousProcessHunter.bat`](./windows/Security-Privacy/SuspiciousProcessHunter.bat) | Flags running processes executing from `%TEMP%`, `%APPDATA%`, Downloads, or other non-standard locations. | ✅ |

#### 🛠️ Utility-Scripts

| File | Description | Admin |
|------|-------------|:-----:|
| [`GameBoost.bat`](./windows/Utility-Scripts/GameBoost.bat) | Kills background apps, sets High Performance power plan, boosts network for gaming. Fully restores after. | ✅ |
| [`FileOrganizer.bat`](./windows/Utility-Scripts/FileOrganizer.bat) | Sorts all files in a folder into typed subfolders: Images, Documents, Videos, Music, Archives, Others. | ❌ |
| [`FolderBackup.bat`](./windows/Utility-Scripts/FolderBackup.bat) | Prompts for source and destination, copies with a timestamped folder name and a live progress counter. | ❌ |
| [`AppInstaller.bat`](./windows/Utility-Scripts/AppInstaller.bat) | Silent one-click installer via `winget`. Installs Chrome, VLC, 7-Zip, Notepad++, VS Code. Skips installed apps. | ✅ |
| [`PCHealthScore.bat`](./windows/Utility-Scripts/PCHealthScore.bat) | Runs 10 diagnostic checks and outputs a health score out of 100 with a letter grade. | ✅ |
| [`SystemBenchmark.bat`](./windows/Utility-Scripts/SystemBenchmark.bat) | Benchmarks CPU, disk read/write speed, and RAM throughput. Outputs results with a performance tier rating. | ❌ |

---

### 🍎 macOS Scripts (.sh)

> [!NOTE]
> Run with `chmod +x script.sh && ./script.sh` or `sudo ./script.sh` for privileged operations.
> Tested on macOS 13 Ventura and macOS 14 Sonoma.

#### 📊 System-Diagnostics

| File | Description | Sudo |
|------|-------------|:----:|
| [`system_info.sh`](./macos/System-Diagnostics/system_info.sh) | Full snapshot via `system_profiler`, `sysctl`, `top`, and `df`. CPU, RAM, GPU, disk, battery, and macOS version. | ❌ |
| [`battery_health.sh`](./macos/System-Diagnostics/battery_health.sh) | Reads cycle count, condition, and max capacity from `ioreg`. Calculates wear % and flags batteries past 80% wear. | ❌ |
| [`disk_health.sh`](./macos/System-Diagnostics/disk_health.sh) | Runs `diskutil` and `smartctl` on all physical disks. Reports SMART status, temperature, and sector health. | ✅ |

#### 🧹 Maintenance-Cleaning

| File | Description | Sudo |
|------|-------------|:----:|
| [`deep_clean.sh`](./macos/Maintenance-Cleaning/deep_clean.sh) | Clears `~/Library/Caches`, flushes DNS, rebuilds Spotlight index, runs Homebrew cleanup, removes old logs. | ✅ |
| [`brew_maintenance.sh`](./macos/Maintenance-Cleaning/brew_maintenance.sh) | Runs `brew update`, `upgrade`, `cleanup --prune=all`, and `doctor` in sequence. Reports reclaimed space. | ❌ |
| [`large_file_finder.sh`](./macos/Maintenance-Cleaning/large_file_finder.sh) | Finds files over 500 MB anywhere on the filesystem. Outputs a ranked list with human-readable sizes. | ❌ |

#### 🌐 Network-Tools

| File | Description | Sudo |
|------|-------------|:----:|
| [`network_optimizer.sh`](./macos/Network-Tools/network_optimizer.sh) | Flushes DNS, renews DHCP lease, resets network preferences, sets Cloudflare + Google DNS resolvers. | ✅ |
| [`wifi_passwords.sh`](./macos/Network-Tools/wifi_passwords.sh) | Reads saved WiFi passwords from the macOS Keychain via `security find-generic-password`. | ❌ |
| [`port_scanner.sh`](./macos/Network-Tools/port_scanner.sh) | Uses `nmap` or `nc` fallback to scan localhost for open ports and identifies the service on each. | ❌ |

#### 🔒 Security-Privacy

| File | Description | Sudo |
|------|-------------|:----:|
| [`privacy_guard.sh`](./macos/Security-Privacy/privacy_guard.sh) | Disables diagnostics submission, Safari suggestions, Spotlight Siri data, and location analytics. | ✅ |
| [`firewall_manager.sh`](./macos/Security-Privacy/firewall_manager.sh) | Enables Application Firewall via `socketfilterfw`, turns on stealth mode, lists all active rules. | ✅ |
| [`gatekeeper_check.sh`](./macos/Security-Privacy/gatekeeper_check.sh) | Reports Gatekeeper and SIP status. Lists quarantined apps via `xattr -r`. | ❌ |

---

### 🐧 Linux Scripts (.sh)

> [!NOTE]
> Tested on Ubuntu 22.04 LTS and Debian 12. Package manager defaults to `apt`.
> Adjust for `dnf` (Fedora/RHEL) or `pacman` (Arch) as needed.

#### 📊 System-Diagnostics

| File | Description | Sudo |
|------|-------------|:----:|
| [`system_info.sh`](./linux/System-Diagnostics/system_info.sh) | Dashboard from `lscpu`, `free -h`, `df -h`, `lsblk`, `lspci`, and uptime in a clean formatted output. | ❌ |
| [`hardware_report.sh`](./linux/System-Diagnostics/hardware_report.sh) | Full hardware inventory via `dmidecode`, `lshw`, and `inxi`. Saves report to `~/hardware_report.txt`. | ✅ |
| [`thermal_monitor.sh`](./linux/System-Diagnostics/thermal_monitor.sh) | Live CPU temp loop from `/sys/class/thermal/` and `sensors`. Color-coded overheating warnings. | ❌ |

#### 🧹 Maintenance-Cleaning

| File | Description | Sudo |
|------|-------------|:----:|
| [`deep_clean.sh`](./linux/Maintenance-Cleaning/deep_clean.sh) | Clears `apt` cache, `~/.cache`, `/tmp`, old journal logs, thumbnail cache, and redundant snap versions. | ✅ |
| [`log_cleaner.sh`](./linux/Maintenance-Cleaning/log_cleaner.sh) | Truncates `/var/log` files older than 7 days, runs `journalctl --vacuum-time=7d`, reports space saved. | ✅ |
| [`orphan_cleaner.sh`](./linux/Maintenance-Cleaning/orphan_cleaner.sh) | Removes orphaned packages, unused older kernels (keeps current + 1), and broken symlinks in `/usr/local`. | ✅ |

#### 🌐 Network-Tools

| File | Description | Sudo |
|------|-------------|:----:|
| [`network_optimizer.sh`](./linux/Network-Tools/network_optimizer.sh) | Flushes DNS via `systemd-resolve`, sets Google/Cloudflare in `/etc/resolv.conf`, runs latency test. | ✅ |
| [`port_scanner.sh`](./linux/Network-Tools/port_scanner.sh) | Uses `ss -tulnp` to list listening ports with owning processes. Optionally runs `nmap localhost`. | ❌ |
| [`bandwidth_monitor.sh`](./linux/Network-Tools/bandwidth_monitor.sh) | Real-time bandwidth via `nethogs` or `iftop`. Falls back to `vnstat` daily stats if neither is installed. | ✅ |

#### 🔒 Security-Privacy

| File | Description | Sudo |
|------|-------------|:----:|
| [`privacy_guard.sh`](./linux/Security-Privacy/privacy_guard.sh) | Disables `whoopsie`, `apport`, `avahi-daemon`, `cups` if unused. Appends tracker blocks to `/etc/hosts`. | ✅ |
| [`ufw_setup.sh`](./linux/Security-Privacy/ufw_setup.sh) | Configures UFW: deny all incoming, allow all outgoing, SSH from local subnet only, enable logging. | ✅ |
| [`rootkit_scan.sh`](./linux/Security-Privacy/rootkit_scan.sh) | Runs `rkhunter` and `chkrootkit`. Saves a timestamped report to `~/security_scan_YYYYMMDD.txt`. | ✅ |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/BatchMaster-Toolkit.git
cd BatchMaster-Toolkit
```

**Windows** — from an elevated Command Prompt:
```bat
cd windows\System-Diagnostics
SystemInfo.bat
```

**macOS / Linux** — make executable and run:
```bash
chmod +x macos/System-Diagnostics/system_info.sh
./macos/System-Diagnostics/system_info.sh

# Privileged scripts:
sudo ./macos/Maintenance-Cleaning/deep_clean.sh
sudo ./linux/Security-Privacy/ufw_setup.sh
```

> [!IMPORTANT]
> **Never run a script you have not read.**
> Every file in this repo is plain text. Open it in any editor, read it top to bottom, and understand what it does before executing it.

---

## Safety & Backup Policy

Every script in this repository follows these rules without exception:

| Rule | How it is enforced |
|------|--------------------|
| No silent destructive actions | All delete and modify operations print what they will do before doing it |
| Reversible changes | Scripts that touch the registry or system settings include a documented undo option |
| Admin/sudo check at startup | Scripts requiring elevation detect the missing privilege and exit before doing anything |
| No runtime downloads | No script fetches or executes code from the internet during execution |
| Tested on clean VMs | Every script is verified on a fresh OS install before being merged |

> [!WARNING]
> **Back up your data before running any Maintenance-Cleaning or Security-Privacy script.**
> While scripts use safe defaults, running them without a recent backup is at your own risk.

> [!CAUTION]
> The `PrivacyGuard` scripts modify the Windows registry, macOS system preferences, and Linux service configuration. Test on a non-critical machine first if you are unsure of the impact on your workflow.

---

## Contributing

Pull requests are welcome. Read [`CONTRIBUTING.md`](./CONTRIBUTING.md) before submitting.

The short version:
1. Fork the repo and create a feature branch
2. Add your script to the correct OS folder and category
3. Include the standard header comment block (see `CONTRIBUTING.md`)
4. Update `manifest.json` with your script's entry
5. Open a PR with the format: `add: ScriptName — one-line description`

---

## License

This project is licensed under the **MIT License** — see [`LICENSE`](./LICENSE) for full details.
Free to use, copy, modify, and distribute for personal or commercial purposes.

---

<div align="center">

Made with care by the community, for the community.
If this toolkit saved you time, consider giving it a ⭐ on GitHub.

<br/>

**[`↑ Back to Top`](#top)**

</div>
