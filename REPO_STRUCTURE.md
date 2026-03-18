<a name="top"></a>

<div align="center">

# 🗂️ Repository Structure Reference

### Your complete map for navigating, adding, and maintaining scripts in BatchMaster Toolkit.

<br/>

[![Windows](https://img.shields.io/badge/Windows-25_scripts-0078D6?style=flat-square&logo=windows&logoColor=white)](./windows/)
[![macOS](https://img.shields.io/badge/macOS-13_scripts-000000?style=flat-square&logo=apple&logoColor=white)](./macos/)
[![Linux](https://img.shields.io/badge/Linux-13_scripts-FCC624?style=flat-square&logo=linux&logoColor=black)](./linux/)
[![Total](https://img.shields.io/badge/Total_Scripts-51-brightgreen?style=flat-square)]()

</div>

---

## Table of Contents

- [Full Directory Tree](#full-directory-tree)
- [Script Count by Platform and Category](#script-count-by-platform-and-category)
- [Risk Level Legend](#risk-level-legend)
- [Category Decision Guide](#category-decision-guide)
- [Naming Conventions](#naming-conventions)
- [Root File Reference](#root-file-reference)
- [manifest.json Schema Reference](#manifestjson-schema-reference)
- [How to Add a New Script — Quick Reference](#how-to-add-a-new-script--quick-reference)

---

## Full Directory Tree

```
BatchMaster-Toolkit/
│
│  ← ROOT FILES
├── 📄 README.md                         Main documentation + full script directory tables
├── 📄 CONTRIBUTING.md                   How to add scripts, code style, PR checklist
├── 📄 REPO_STRUCTURE.md                 This file — your navigation map
├── 📄 manifest.json                     Machine-readable metadata for all 51 scripts
└── 📄 LICENSE                           MIT License
│
│
├── 📁 windows/                          Windows batch scripts (.bat)
│   │
│   ├── 📁 System-Diagnostics/           ← READ ONLY. No system changes.
│   │   ├── SystemInfo.bat               v4.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Full 14-section analytics dashboard
│   │   │                                CPU · RAM · GPU · Disk · Battery · Network
│   │   │                                Live ASCII bar charts for load + disk usage
│   │   │
│   │   ├── BatteryGuard.bat             v1.0.0 │ Admin ❌ │ Risk: LOW
│   │   │                                Wear level % · Cycle count · Health alerts
│   │   │                                HTML battery report saved to Desktop
│   │   │
│   │   ├── DriverChecker.bat            v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Flags drivers older than 12 months
│   │   │                                Flags unsigned/unverified drivers
│   │   │
│   │   ├── BootSpeedAnalyzer.bat        v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Reads event log ID 100 boot performance data
│   │   │                                Ranks startup items by boot delay added
│   │   │
│   │   └── ThermalMonitor.bat           v1.0.0 │ Admin ❌ │ Risk: LOW
│   │                                    Live CPU + disk temp via WMI
│   │                                    Warn >80°C · Critical >90°C
│   │
│   ├── 📁 Maintenance-Cleaning/         ← Deletes cache/temp. Mostly not reversible.
│   │   ├── DeepClean.bat                v2.0.0 │ Admin ✅ │ Risk: MEDIUM
│   │   │                                14 steps: Temp · Prefetch · DNS · All browsers
│   │   │                                Windows Update cache · Recycle Bin · Event logs
│   │   │
│   │   ├── RAMCleaner.bat               v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Clears standby RAM + working set trim
│   │   │                                Before/after MB display
│   │   │
│   │   ├── LargeFileFinder.bat          v1.0.0 │ Admin ❌ │ Risk: LOW
│   │   │                                Finds files >100 MB on all drives
│   │   │                                Ranked by size · Full path · Modified date
│   │   │
│   │   ├── DuplicateFinder.bat          v1.0.0 │ Admin ❌ │ Risk: LOW
│   │   │                                Scans folder for files with same name + size
│   │   │                                Lists duplicates for manual review (no auto-delete)
│   │   │
│   │   └── RecycleBinManager.bat        v1.0.0 │ Admin ❌ │ Risk: MEDIUM
│   │                                    Size per drive · Empty individually or all
│   │                                    Confirmation prompt before any deletion
│   │
│   ├── 📁 Network-Tools/                ← Some modify system settings. Reversible.
│   │   ├── NetworkOptimizer.bat         v1.0.0 │ Admin ✅ │ Risk: HIGH (reversible)
│   │   │                                DNS flush · Winsock reset · TCP reset
│   │   │                                Set 8.8.8.8 + 1.1.1.1 · Disable throttling
│   │   │                                Includes full Undo option
│   │   │
│   │   ├── WifiPasswordViewer.bat       v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                All saved SSIDs + plaintext passwords
│   │   │                                Local credential store only · No external tools
│   │   │
│   │   ├── PortScanner.bat              v1.0.0 │ Admin ❌ │ Risk: LOW
│   │   │                                Top 50 ports on localhost
│   │   │                                Maps open ports to owning process + PID
│   │   │
│   │   ├── NetworkSpeedLogger.bat       v1.0.0 │ Admin ❌ │ Risk: LOW
│   │   │                                5 targets · Every 10 sec · 5 min total
│   │   │                                Timestamped latency log saved to Desktop
│   │   │
│   │   └── ConnectionKiller.bat         v1.0.0 │ Admin ✅ │ Risk: HIGH (irreversible)
│   │                                    Lists all ESTABLISHED connections
│   │                                    Select by number → taskkill /f /pid
│   │
│   ├── 📁 Security-Privacy/             ← Modifies registry/services/hosts. Use with care.
│   │   ├── PrivacyGuard.bat             v1.0.0 │ Admin ✅ │ Risk: HIGH (reversible)
│   │   │                                DiagTrack off · Cortana off · Ad ID off
│   │   │                                Blocks ~30 tracking domains in hosts file
│   │   │                                Full restore option included
│   │   │
│   │   ├── AccountAuditor.bat           v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Last login · Password age · Account status
│   │   │                                Flags never-logged-in + blank-password accounts
│   │   │
│   │   ├── AutorunAuditor.bat           v1.0.0 │ Admin ✅ │ Risk: LOW
│   │   │                                Scans 12 registry autorun keys + startup folders
│   │   │                                Flags temp-dir / missing-path / AppData entries
│   │   │
│   │   └── SuspiciousProcessHunter.bat  v1.0.0 │ Admin ✅ │ Risk: LOW
│   │                                    Flags processes running from Temp/AppData/Downloads
│   │                                    Also flags processes masquerading as system names
│   │
│   └── 📁 Utility-Scripts/             ← Mixed risk. Read each script's header.
│       ├── GameBoost.bat                v1.0.0 │ Admin ✅ │ Risk: HIGH (reversible)
│       │                                Kills 13 background apps · High Perf power plan
│       │                                Disables Defender scan · TCP latency tweak
│       │                                Full Restore option included
│       │
│       ├── FileOrganizer.bat            v1.0.0 │ Admin ❌ │ Risk: MEDIUM
│       │                                Moves files into Images/Docs/Videos/Music/Archives
│       │                                9 image types · 11 doc types · 5 video types
│       │
│       ├── FolderBackup.bat             v1.0.0 │ Admin ❌ │ Risk: LOW
│       │                                robocopy /e with retry · Timestamped folder
│       │                                Live counter · Backup log alongside output
│       │
│       ├── AppInstaller.bat             v1.0.0 │ Admin ✅ │ Risk: MEDIUM
│       │                                winget silent install: Chrome·VLC·7zip·Notepad++·VSCode
│       │                                Checks if installed first · Logs results to Desktop
│       │
│       ├── PCHealthScore.bat            v1.0.0 │ Admin ✅ │ Risk: LOW
│       │                                10 checks → score /100 → letter grade A–F
│       │                                RAM·Disk·CPU·Battery·Firewall·Defender·Ports…
│       │
│       └── SystemBenchmark.bat          v1.0.0 │ Admin ❌ │ Risk: LOW
│                                        CPU (ops/sec) · Disk (MB/s read+write) · RAM
│                                        Five-tier rating: Entry→Enthusiast
│
│
├── 📁 macos/                            macOS shell scripts (.sh)
│   │
│   ├── 📁 System-Diagnostics/
│   │   ├── system_info.sh               v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │   │                                system_profiler · sysctl · vm_stat · df · ioreg
│   │   │
│   │   ├── battery_health.sh            v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │   │                                ioreg AppleSmartBattery · CycleCount · Wear %
│   │   │
│   │   └── disk_health.sh               v1.0.0 │ Sudo ✅ │ Risk: LOW
│   │                                    diskutil + optional smartctl SMART attributes
│   │
│   ├── 📁 Maintenance-Cleaning/
│   │   ├── deep_clean.sh                v1.0.0 │ Sudo ✅ │ Risk: MEDIUM
│   │   │                                ~/Library/Caches · DNS · Spotlight · Brew · Trash
│   │   │
│   │   ├── brew_maintenance.sh          v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │   │                                update → upgrade → cleanup --prune=all → doctor
│   │   │
│   │   └── large_file_finder.sh         v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │                                    find / -size +500M (excludes /System /dev /vm)
│   │
│   ├── 📁 Network-Tools/
│   │   ├── network_optimizer.sh         v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
│   │   │                                dscacheutil · mDNSResponder · DHCP renew · networksetup DNS
│   │   │
│   │   ├── wifi_passwords.sh            v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │   │                                Keychain security find-generic-password
│   │   │                                System auth dialog per SSID
│   │   │
│   │   └── port_scanner.sh              v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │                                    nmap -sV (if installed) or nc fallback + lsof -i
│   │
│   ├── 📁 Security-Privacy/
│   │   ├── privacy_guard.sh             v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
│   │   │                                defaults write: Safari · Spotlight · Analytics
│   │   │                                launchctl unload SubmitDiagInfo · hosts blocks
│   │   │
│   │   ├── firewall_manager.sh          v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
│   │   │                                socketfilterfw: enable · stealth mode · app rules
│   │   │
│   │   └── gatekeeper_check.sh          v1.0.0 │ Sudo ❌ │ Risk: LOW
│   │                                    spctl · csrutil · xattr quarantine · Launch Agents
│   │
│   └── 📁 Utility-Scripts/
│       └── screenshot_renamer.sh         v1.0.0 │ Sudo ❌ │ Risk: LOW
│                                         fswatch daemon · YYYYMMDD_HHMMSS rename
│                                         Moves to ~/Pictures/Screenshots archive
│
│
└── 📁 linux/                            Linux shell scripts (.sh)
    │
    ├── 📁 System-Diagnostics/
    │   ├── system_info.sh               v1.0.0 │ Sudo ❌ │ Risk: LOW
    │   │                                lscpu · free -h · df -h · lsblk · lspci · hostnamectl
    │   │
    │   ├── hardware_report.sh           v1.0.0 │ Sudo ✅ │ Risk: LOW
    │   │                                dmidecode · lshw · inxi (optional) → ~/hardware_report.txt
    │   │
    │   └── thermal_monitor.sh           v1.0.0 │ Sudo ❌ │ Risk: LOW
    │                                    /sys/class/thermal + lm-sensors · 5-sec refresh loop
    │
    ├── 📁 Maintenance-Cleaning/
    │   ├── deep_clean.sh                v1.0.0 │ Sudo ✅ │ Risk: MEDIUM
    │   │                                apt autoremove+clean · ~/.cache · /tmp · journal · snaps
    │   │
    │   ├── log_cleaner.sh               v1.0.0 │ Sudo ✅ │ Risk: MEDIUM
    │   │                                journalctl --vacuum-time=7d · /var/log *.gz *.1 trim
    │   │
    │   └── orphan_cleaner.sh            v1.0.0 │ Sudo ✅ │ Risk: HIGH (irreversible)
    │                                    deborphan · old kernels (keeps current+1) · broken symlinks
    │
    ├── 📁 Network-Tools/
    │   ├── network_optimizer.sh         v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
    │   │                                resolvectl flush · ip link reset · /etc/resolv.conf
    │   │
    │   ├── port_scanner.sh              v1.0.0 │ Sudo ❌ │ Risk: LOW
    │   │                                ss -tulnp · optional nmap -sV · system vs app ports
    │   │
    │   └── bandwidth_monitor.sh         v1.0.0 │ Sudo ✅ │ Risk: LOW
    │                                    nethogs > iftop > vnstat > /proc/net/dev fallback
    │
    ├── 📁 Security-Privacy/
    │   ├── privacy_guard.sh             v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
    │   │                                Masks whoopsie·apport·avahi·cups · /etc/hosts blocks
    │   │
    │   ├── ufw_setup.sh                 v1.0.0 │ Sudo ✅ │ Risk: HIGH (reversible)
    │   │                                ufw reset → deny in → allow out → SSH local subnet
    │   │
    │   └── rootkit_scan.sh              v1.0.0 │ Sudo ✅ │ Risk: LOW
    │                                    rkhunter + chkrootkit → ~/security_scan_TIMESTAMP.txt
    │
    └── 📁 Utility-Scripts/
        └── folder_backup.sh              v1.0.0 │ Sudo ❌ │ Risk: LOW
                                          rsync -avh with progress · BACKUP_TIMESTAMP/ subfolder
```

---

## Script Count by Platform and Category

| Category | Windows | macOS | Linux | Total |
|----------|:-------:|:-----:|:-----:|:-----:|
| System-Diagnostics | 5 | 3 | 3 | **11** |
| Maintenance-Cleaning | 5 | 3 | 3 | **11** |
| Network-Tools | 5 | 3 | 3 | **11** |
| Security-Privacy | 4 | 3 | 3 | **10** |
| Utility-Scripts | 6 | 1 | 1 | **8** |
| **Total** | **25** | **13** | **13** | **51** |

---

## Risk Level Legend

| Risk | Symbol | What it means | `reversible` in manifest |
|------|--------|--------------|--------------------------|
| `LOW` | 🟢 | Reads data only. Zero system changes. | `true` |
| `MEDIUM` | 🟡 | Deletes cache/temp files. Non-critical. | Usually `false` |
| `HIGH` | 🟠 | Modifies settings, registry, or services. **Must include Undo option.** | `true` (required) |
| `CRITICAL` | 🔴 | Irreversible deletions or destructive changes. Backup required. | `false` |

---

## Category Decision Guide

Not sure which folder to put your script in? Use this table:

| If your script... | Platform | Folder |
|-------------------|----------|--------|
| Displays info about hardware, OS, CPU, RAM, GPU, disk, battery | Any | `System-Diagnostics/` |
| Reads driver info, boot times, or temperatures | Any | `System-Diagnostics/` |
| Deletes temp files, clears caches, or frees disk space | Any | `Maintenance-Cleaning/` |
| Cleans package manager artifacts (apt, brew, snap) | macOS/Linux | `Maintenance-Cleaning/` |
| Deals with WiFi, DNS, TCP/IP, ports, or network connections | Any | `Network-Tools/` |
| Monitors or logs network traffic or latency | Any | `Network-Tools/` |
| Modifies firewall rules or privacy/telemetry settings | Any | `Security-Privacy/` |
| Scans for threats, audits accounts, or checks autorun entries | Any | `Security-Privacy/` |
| Automates a task (backup, organize, install, benchmark, boost) | Any | `Utility-Scripts/` |
| Does not clearly fit any of the above | Any | `Utility-Scripts/` |

> [!NOTE]
> When a script spans two categories (e.g., it both monitors and cleans), choose the category that best describes its **primary purpose**. A script that monitors temps with a cleanup option goes in `System-Diagnostics/`, not `Maintenance-Cleaning/`.

---

## Naming Conventions

| Platform | File format | Example |
|----------|------------|---------|
| Windows | `PascalCase.bat` | `NetworkOptimizer.bat` |
| macOS | `snake_case.sh` | `network_optimizer.sh` |
| Linux | `snake_case.sh` | `network_optimizer.sh` |

**Branch names for PRs:**

| Action | Format | Example |
|--------|--------|---------|
| New script | `add-<scriptname>-<platform>` | `add-wifi-analyzer-windows` |
| Bug fix | `fix-<scriptname>-<platform>` | `fix-deepclean-edge-path-windows` |
| Enhancement | `enhance-<scriptname>-<platform>` | `enhance-systeminfo-gpu-section` |
| Cross-platform port | `port-<scriptname>-<platform>` | `port-networkoptimizer-linux` |

**Commit message format:**
```
add: WifiAnalyzer.bat — lists saved WiFi profiles with signal strength
fix: DeepClean.bat — correct Edge Chromium cache path on Windows 11
enhance: system_info.sh — add GPU temperature from sensors output
docs: CONTRIBUTING.md — clarify manifest.json risk_level field
port: network_optimizer.sh (Linux) — ported from Windows NetworkOptimizer.bat
```

---

## Root File Reference

| File | Purpose | Edit when... |
|------|---------|-------------|
| `README.md` | Main docs — project overview, all script tables, quick start | Adding a script (update the table) or changing anything user-visible |
| `CONTRIBUTING.md` | How to contribute — standards, templates, checklist | Adding a new requirement or changing the PR process |
| `REPO_STRUCTURE.md` | This file — navigation map and structure reference | Adding or moving a script |
| `manifest.json` | Machine-readable metadata for all scripts | Every time a script is added, updated, or removed |
| `LICENSE` | MIT License text | Never (don't edit) |

---

## manifest.json Schema Reference

Every script entry must contain all of these fields. See `CONTRIBUTING.md` for field-by-field rules.

```json
{
  "file":                    "ScriptName.bat",
  "path":                    "windows/Category/ScriptName.bat",
  "version":                 "1.0.0",
  "status":                  "stable",
  "platform":                "windows",
  "category":                "System-Diagnostics",
  "description":             "One clear sentence. What it does.",
  "long_description":        "Technical detail: exact commands, flags, thresholds, edge cases.",
  "requires_admin":          true,
  "risk_level":              "LOW",
  "reversible":              true,
  "estimated_runtime_seconds": 10,
  "tested_on":               ["Windows 10 22H2", "Windows 11 23H2"],
  "min_os_version":          "Windows 10 1803",
  "tags":                    ["tag1", "tag2", "tag3"],
  "dependencies":            [],
  "changelog": {
    "1.0.0": {
      "date":  "YYYY-MM-DD",
      "notes": "Initial release."
    }
  }
}
```

**Quick field reference:**

| Field | Type | Valid values |
|-------|------|-------------|
| `status` | string | `"stable"`, `"beta"`, `"deprecated"` |
| `platform` | string | `"windows"`, `"macos"`, `"linux"` |
| `risk_level` | string | `"LOW"`, `"MEDIUM"`, `"HIGH"`, `"CRITICAL"` |
| `reversible` | boolean | `true` only if script has a working Undo/Restore option |
| `estimated_runtime_seconds` | integer | Actual seconds. Use `999` for scripts that run until CTRL+C |
| `tags` | array | 3–6 lowercase hyphenated strings |
| `dependencies` | array | Empty `[]` if none. Else: `["winget"]`, `["brew"]`, `["rsync"]` |

---

## How to Add a New Script — Quick Reference

```
1. ✅  Read CONTRIBUTING.md fully
2. ✅  Pick the right platform folder: windows/ macos/ linux/
3. ✅  Pick the right category (see Category Decision Guide above)
4. ✅  Name your file correctly (PascalCase.bat or snake_case.sh)
5. ✅  Add the standard header block to your script
6. ✅  Add admin/sudo check if required
7. ✅  Add confirmation prompts on destructive operations
8. ✅  Test on a clean VM — note the OS version
9. ✅  Add your entry to manifest.json (all fields required)
10. ✅ Update this file (REPO_STRUCTURE.md) with your new entry
11. ✅ Update README.md script table with your new entry
12. ✅ Open a PR with the correct title format
```

---

<div align="center">

See something out of date in this file?
[Open an issue](https://github.com/Anamicca23/BatchMaster-Toolkit/issues) or send a `docs:` PR.

<br/>

**[`↑ Back to Top`](#top)**

</div>