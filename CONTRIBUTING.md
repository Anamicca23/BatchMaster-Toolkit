<a name="top"></a>

<div align="center">

# 🤝 Contributing to BatchMaster Toolkit

### Every script here was written by someone who wanted to save others time.
### Your contribution — no matter how small — keeps that chain alive.

<br/>

[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge)](https://github.com/Anamicca23/BatchMaster-Toolkit/pulls)
[![Issues](https://img.shields.io/badge/Open_Issues-GitHub-blue?style=for-the-badge)](https://github.com/Anamicca23/BatchMaster-Toolkit/issues)
[![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)](./LICENSE)

</div>

---

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Before You Start](#before-you-start)
- [What We Accept](#what-we-accept)
- [What We Do Not Accept](#what-we-do-not-accept)
- [Risk Levels](#risk-levels)
- [Script Requirements](#script-requirements)
  - [1. Standard Header Block](#1-standard-header-block)
  - [2. Admin / Sudo Check](#2-admin--sudo-check)
  - [3. Confirmation Prompts](#3-confirmation-prompts)
  - [4. Error Handling](#4-error-handling)
  - [5. No Hardcoded Paths](#5-no-hardcoded-paths)
  - [6. Dependency Checks](#6-dependency-checks)
  - [7. Clean Exit & Restore](#7-clean-exit--restore)
  - [8. Tested on a Clean Install](#8-tested-on-a-clean-install)
- [Adding a Script — Step by Step](#adding-a-script--step-by-step)
- [Updating manifest.json](#updating-manifestjson)
- [Bumping an Existing Script Version](#bumping-an-existing-script-version)
- [Code Style Guide](#code-style-guide)
  - [Windows (.bat)](#windows-bat)
  - [macOS / Linux (.sh)](#macos--linux-sh)
- [Pull Request Checklist](#pull-request-checklist)
- [Reporting Issues](#reporting-issues)
- [Security Vulnerabilities](#security-vulnerabilities)

---

## Ways to Contribute

You do not have to write a brand-new script to contribute. Here are all the ways you can help:

| Type | What it looks like | Label to use on your PR |
|------|--------------------|------------------------|
| 🆕 New script | A fully new `.bat` or `.sh` in the right folder | `add:` |
| 🐛 Bug fix | A broken command, wrong output, crash on a specific OS | `fix:` |
| ⚡ Enhancement | Better output, new menu option, improved accuracy | `enhance:` |
| 📝 Docs | README typos, missing descriptions, broken links | `docs:` |
| 🌐 Cross-platform port | macOS port of a Windows script (or vice versa) | `port:` |
| 🔒 Security patch | Privilege escalation risk, injection vulnerability | `security:` |

---

## Before You Start

1. **Read the [README](./README.md)** to understand the full structure
2. **Check [open issues](https://github.com/Anamicca23/BatchMaster-Toolkit/issues)** — someone may already be building the same thing
3. **Check [open PRs](https://github.com/Anamicca23/BatchMaster-Toolkit/pulls)** — a script may already be in review
4. **Open an issue first** if you are adding a major new script — discuss scope before writing code
5. **Read [REPO_STRUCTURE.md](./REPO_STRUCTURE.md)** to find the right folder for your script

> [!TIP]
> First-time contributor? Look for issues tagged `good first issue` — these are well-scoped, low-risk tasks that are a great way to get started.

---

## What We Accept

- ✅ Scripts that solve a **genuine, recurring problem** for power users
- ✅ **Cross-platform contributions** — Windows `.bat`, macOS `.sh`, Linux `.sh`
- ✅ **Bug fixes** and accuracy improvements to existing scripts
- ✅ **Enhanced output** — better formatting, more accurate data, new sections
- ✅ **Documentation fixes** — typos, missing descriptions, unclear instructions
- ✅ **Cross-platform ports** — porting a Windows script to macOS or Linux

---

## What We Do Not Accept

| ❌ Type | Why |
|---------|-----|
| Scripts that fetch and execute code from the internet at runtime | Cannot be audited — security risk |
| Scripts with destructive operations and no confirmation prompt | Too dangerous for general use |
| Scripts that collect or transmit user data | Privacy violation |
| Obfuscated, minified, or encoded script content | Must be human-readable to be trusted |
| Scripts that duplicate existing functionality without meaningful improvement | Keeps the repo maintainable |
| Scripts that require paid software or closed-source dependencies | Must be usable without cost |
| Anything that violates applicable law in any jurisdiction | Non-negotiable |

---

## Risk Levels

Every script in `manifest.json` carries a `risk_level` field. When writing or updating a script, assign the correct level:

| Level | Definition | Examples |
|-------|-----------|---------|
| `LOW` | Reads data only. No files modified, no settings changed. | `SystemInfo.bat`, `BatteryGuard.bat` |
| `MEDIUM` | Modifies cache or temp files. Non-critical, easily reversible. | `DeepClean.bat`, `FileOrganizer.bat` |
| `HIGH` | Modifies system settings, registry, or service config. Must include an undo option. | `PrivacyGuard.bat`, `NetworkOptimizer.bat`, `GameBoost.bat` |
| `CRITICAL` | Permanently deletes files or makes irreversible system changes. Explicit backup warning required. | Any script using `--force` deletion without recovery |

> [!IMPORTANT]
> Any script with `risk_level: HIGH` or `CRITICAL` **must** include a working restore/undo option and display an explicit warning before executing.

---

## Script Requirements

Every script submitted must satisfy all of the following requirements. PRs that skip any requirement will not be merged.

---

### 1. Standard Header Block

The first thing in every script must be a standard header comment. This is how the toolkit stays auditable.

**Windows `.bat`:**
```bat
:: ============================================================
:: Name     : YourScript.bat
:: Version  : 1.0.0
:: Author   : your-github-username
:: Tested   : Windows 10 22H2, Windows 11 23H2
:: Min OS   : Windows 10 1803
:: Risk     : LOW | MEDIUM | HIGH | CRITICAL
:: Admin    : Required / Not Required
:: Reversible: Yes / No
:: Desc     : One clear sentence describing what this script does.
:: ============================================================
```

**macOS / Linux `.sh`:**
```bash
#!/usr/bin/env bash
# ============================================================
# Name      : your_script.sh
# Version   : 1.0.0
# Author    : your-github-username
# Tested    : Ubuntu 22.04 LTS, macOS 14 Sonoma
# Min OS    : Ubuntu 20.04 / macOS 12 Monterey
# Risk      : LOW | MEDIUM | HIGH | CRITICAL
# Sudo      : Required / Not Required
# Reversible: Yes / No
# Desc      : One clear sentence describing what this script does.
# ============================================================
```

---

### 2. Admin / Sudo Check

If your script requires elevated privileges, it **must** check at startup and exit clearly if the check fails.

**Windows:**
```bat
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo  [ERROR] This script must be run as Administrator.
    echo  Right-click the file and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)
```

**macOS / Linux:**
```bash
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "  [ERROR] This script must be run as root."
    echo "  Try: sudo ./$(basename "$0")"
    echo ""
    exit 1
fi
```

---

### 3. Confirmation Prompts

Any operation that **deletes files**, **modifies the registry**, **changes system settings**, or **terminates processes** must display a clear warning and ask for confirmation.

**Windows:**
```bat
echo.
echo  [WARNING] This will permanently delete all temp files.
echo  This action cannot be undone.
echo.
set /p confirm=  Proceed? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo  Cancelled. No changes were made.
    pause & exit /b 0
)
```

**macOS / Linux:**
```bash
echo ""
echo "  [WARNING] This will permanently delete cache files."
echo "  This action cannot be undone."
echo ""
read -rp "  Proceed? (y/N): " confirm
[[ "${confirm,,}" != "y" ]] && echo "  Cancelled." && exit 0
```

---

### 4. Error Handling

Scripts must not fail silently.

**Windows:**
```bat
:: Use 2>nul ONLY on commands where a missing resource is expected and harmless
:: Do NOT suppress errors you need to see
if %errorlevel% neq 0 (
    echo  [ERROR] Command failed with exit code %errorlevel%.
    pause & exit /b %errorlevel%
)
```

**macOS / Linux:**
```bash
set -euo pipefail   # Add to every script top — exits on error, undefined var, pipe fail

# For recoverable errors, trap and report:
trap 'echo "[ERROR] Script failed on line $LINENO. Exit code: $?"' ERR
```

---

### 5. No Hardcoded Paths

Never hardcode paths to a specific user account or machine. Always use environment variables.

| ❌ Do not use | ✅ Use instead |
|--------------|--------------|
| `C:\Users\John\AppData` | `%APPDATA%` |
| `C:\Users\John\Desktop` | `%USERPROFILE%\Desktop` |
| `/home/john/.config` | `$HOME/.config` |
| `C:\Windows\System32` | `%SystemRoot%\System32` |
| `/Users/john/Library` | `$HOME/Library` |

---

### 6. Dependency Checks

If your script requires a tool that may not be installed, check for it before use.

**Windows:**
```bat
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] winget is not installed. This script requires Windows 10 1809+.
    pause & exit /b 1
)
```

**macOS / Linux:**
```bash
if ! command -v nmap &>/dev/null; then
    echo "  [INFO] nmap is not installed. Install with: brew install nmap"
    echo "  Falling back to nc-based scan..."
    USE_NMAP=false
else
    USE_NMAP=true
fi
```

---

### 7. Clean Exit & Restore

Scripts with `risk_level: HIGH` must include a working restore/undo option that reverses every change made.

```bat
:RESTORE
:: Undo all changes made by :BOOST or :APPLY
echo  Restoring original settings...
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e  >nul 2>&1
sc config wuauserv start= auto  >nul 2>&1
sc start wuauserv  >nul 2>&1
echo  [OK] All settings restored.
pause
goto MENU
```

---

### 8. Tested on a Clean Install

Test your script on a virtual machine or clean OS install. State the exact OS version in the header. Do not assume the reviewer's machine has the same configuration as yours.

**Recommended free tools for clean-VM testing:**
- [VirtualBox](https://www.virtualbox.org/) (free, Windows/macOS/Linux host)
- [UTM](https://mac.getutm.app/) (free, macOS host)
- [Windows Sandbox](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview) (built into Windows 10/11 Pro)

---

## Adding a Script — Step by Step

```bash
# ── Step 1: Fork the repo on GitHub, then clone your fork ──────────────────
git clone https://github.com/YOUR-USERNAME/BatchMaster-Toolkit.git
cd BatchMaster-Toolkit

# ── Step 2: Create a feature branch ────────────────────────────────────────
# Format: <action>-<scriptname>-<platform>
git checkout -b add-wifi-analyzer-windows
git checkout -b fix-deepclean-edge-cache-windows
git checkout -b port-networkoptimizer-linux

# ── Step 3: Add your script to the correct folder ──────────────────────────
# Windows  → windows/<Category>/YourScript.bat
# macOS    → macos/<Category>/your_script.sh
# Linux    → linux/<Category>/your_script.sh
# (See REPO_STRUCTURE.md for the category decision guide)

# ── Step 4: Update manifest.json (see next section) ────────────────────────

# ── Step 5: Stage and commit ───────────────────────────────────────────────
git add windows/Network-Tools/WifiAnalyzer.bat manifest.json
git commit -m "add: WifiAnalyzer.bat — lists saved WiFi profiles with signal strength"

# ── Step 6: Push and open a Pull Request ───────────────────────────────────
git push origin add-wifi-analyzer-windows
# Then open a PR at: https://github.com/Anamicca23/BatchMaster-Toolkit/compare
```

**PR title format:**
```
add: WifiAnalyzer.bat — lists saved WiFi profiles with signal strength
fix: DeepClean.bat — correct Edge cache path on Windows 11 23H2
enhance: SystemInfo.bat — add GPU temperature to display section
docs: README — fix broken link in macOS quick start
port: network_optimizer.sh (Linux) — ported from Windows NetworkOptimizer.bat
```

---

## Updating manifest.json

Add your entry to `scripts.<platform>.<Category>[]` in `manifest.json`. Use this complete template — every field is required:

```json
{
  "file": "WifiAnalyzer.bat",
  "path": "windows/Network-Tools/WifiAnalyzer.bat",
  "version": "1.0.0",
  "status": "stable",
  "platform": "windows",
  "category": "Network-Tools",
  "description": "Lists all saved WiFi profiles with SSID, signal strength, security type, and last connected date.",
  "long_description": "Uses netsh wlan show profiles to enumerate SSIDs. For each profile runs netsh wlan show profile name='...' to get security type, signal, and channel. Displays results in a formatted table sorted by signal strength. Does not read or display passwords.",
  "requires_admin": true,
  "risk_level": "LOW",
  "reversible": true,
  "estimated_runtime_seconds": 5,
  "tested_on": ["Windows 10 22H2", "Windows 11 23H2"],
  "min_os_version": "Windows 10 1803",
  "tags": ["wifi", "network", "diagnostics", "signal"],
  "dependencies": [],
  "changelog": {
    "1.0.0": {
      "date": "2025-03-18",
      "notes": "Initial release."
    }
  }
}
```

**Field rules:**

| Field | Rule |
|-------|------|
| `file` | Exact filename including extension |
| `path` | Relative path from repo root |
| `version` | Start at `1.0.0`. Follow semver: patch for fixes, minor for new features, major for rewrites |
| `status` | `"stable"` for tested scripts, `"beta"` if experimental |
| `platform` | `"windows"`, `"macos"`, or `"linux"` |
| `risk_level` | Must be one of: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |
| `reversible` | `true` only if the script includes a working undo/restore option |
| `estimated_runtime_seconds` | Use `999` for scripts that run until CTRL+C |
| `tags` | 3–6 lowercase hyphenated words. Reuse existing tags where possible |
| `dependencies` | Empty array `[]` if none. Otherwise list tool names with install hints |
| `changelog` | Object with version keys. Each value is `{"date": "YYYY-MM-DD", "notes": "..."}` |

---

## Bumping an Existing Script Version

When fixing or enhancing an **existing** script:

1. Increment the version in the script's header comment
2. Update the `version` field in `manifest.json`
3. Add a new changelog entry — do not edit existing entries

```json
"version": "1.2.0",
"changelog": {
  "1.2.0": {
    "date": "2025-04-01",
    "notes": "Added signal strength column. Fixed crash when no profiles saved."
  },
  "1.1.0": {
    "date": "2025-03-20",
    "notes": "Added last-connected date column."
  },
  "1.0.0": {
    "date": "2025-03-18",
    "notes": "Initial release."
  }
}
```

**Semver guide for this repo:**

| Change type | Version bump | Example |
|-------------|-------------|---------|
| Fix a bug, typo, or wrong path | Patch `x.x.+1` | `1.0.0` → `1.0.1` |
| Add a new menu option or output section | Minor `x.+1.0` | `1.0.0` → `1.1.0` |
| Complete rewrite or breaking change to behavior | Major `+1.0.0` | `1.0.0` → `2.0.0` |

---

## Code Style Guide

### Windows (.bat)

```bat
@echo off
setlocal enabledelayedexpansion     ← Always include this
title YOUR SCRIPT TITLE v1.0.0
mode con: cols=80 lines=45          ← Set consistent window size
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit   ← Keep window open

:: ── Sections use this comment style ──────────────────────────────────────
:MENU
:SECTION_NAME

:: Variable naming: descriptive, no spaces
set "sourceDir=%~1"
set "outputFile=%USERPROFILE%\Desktop\report.txt"

:: Use call :SubroutineName for any reused logic
call :WGet "wmic os get Caption /value" "Caption" vOSName

:: Color conventions:
::   color 0A  → green text, normal output
::   color 0B  → cyan text, success messages
::   color 0C  → red text, errors
::   color 0E  → yellow text, warnings
::   color 0D  → magenta, info/secondary sections

:: Menu numbering: [0] through [9], [0] always = Exit
echo    [1]  Option One
echo    [2]  Option Two
echo    [0]  Exit

:: Suppress only expected errors, never suppress unexpectedly
wmic os get Caption /value 2>nul | findstr "="   ← OK: 2>nul on wmic
del /f /q "%tempFile%" 2>nul                      ← OK: file may not exist
```

---

### macOS / Linux (.sh)

```bash
#!/usr/bin/env bash           ← Always this exact shebang — not #!/bin/bash
set -euo pipefail             ← Always include — exits on any error

# ── Constants ──────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# ── Color output ──────────────────────────────────────────────────────────
RED='\033[0;31m'   YELLOW='\033[1;33m'
GREEN='\033[0;32m' CYAN='\033[0;36m'
NC='\033[0m'       # No Color (reset)

log_info()    { echo -e "${CYAN}  [INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}  [ OK ]${NC}  $*"; }
log_warn()    { echo -e "${YELLOW}  [WARN]${NC}  $*"; }
log_error()   { echo -e "${RED} [ERROR]${NC}  $*" >&2; }

# ── Function naming: snake_case ────────────────────────────────────────────
check_dependency() {
    local tool="$1"
    if ! command -v "$tool" &>/dev/null; then
        log_warn "$tool not found. Install with: $2"
        return 1
    fi
}

# ── Always quote variables ─────────────────────────────────────────────────
local_path="$HOME/output"      ← OK
local_path=$HOME/output        ← Never do this — breaks on spaces

# ── Section headers ────────────────────────────────────────────────────────
echo ""
echo "  ════════════════════════════════════"
echo "    SECTION NAME"
echo "  ════════════════════════════════════"
```

---

## Pull Request Checklist

Copy this checklist into your PR description. Every box must be checked before a reviewer will look at the PR.

```
### Script checklist
- [ ] Standard header comment block is present and complete
- [ ] Script checks for admin/sudo privileges if required and exits cleanly if missing
- [ ] All destructive operations display a warning and require Y confirmation
- [ ] No hardcoded user paths — uses environment variables throughout
- [ ] Dependency check included for any tool that may not be pre-installed
- [ ] Scripts with risk_level HIGH include a working Restore/Undo option
- [ ] Tested on a clean VM or fresh install — OS version stated in header
- [ ] Script does not download or execute code from the internet at runtime
- [ ] No obfuscated, encoded, or minified code

### manifest.json checklist
- [ ] Entry added to the correct platform and category in manifest.json
- [ ] All fields populated: file, path, version, status, platform, category,
      description, long_description, requires_admin, risk_level, reversible,
      estimated_runtime_seconds, tested_on, min_os_version, tags, dependencies, changelog
- [ ] risk_level matches the script's actual behavior
- [ ] reversible: true only if an undo/restore option exists in the script
- [ ] changelog entry uses {"date": "YYYY-MM-DD", "notes": "..."} format

### PR format checklist
- [ ] PR title format: "add|fix|enhance|docs|port: ScriptName — one-line description"
- [ ] Branch name is descriptive: "add-scriptname-platform"
- [ ] Only the new/changed script and manifest.json are included in the commit
```

---

## Reporting Issues

Found a bug in an existing script? [Open an issue](https://github.com/Anamicca23/BatchMaster-Toolkit/issues/new) with the following information:

```
**Script:** windows/Network-Tools/NetworkOptimizer.bat
**OS:** Windows 11 23H2 (Build 22631)
**Ran as:** Administrator ✅ / Standard user ❌

**What happened:**
[Paste the exact error output from the terminal here]

**What you expected:**
[One sentence describing the expected behavior]

**Steps to reproduce:**
1. Right-click NetworkOptimizer.bat → Run as administrator
2. Select option [1] Full Network Optimization
3. Error appears at step [3/9]
```

**Issue labels to use:**

| Label | When to use |
|-------|------------|
| `bug` | Script crashes, produces wrong output, or fails on a supported OS |
| `enhancement` | Suggestion to improve an existing script |
| `new script` | Proposal for a new script before writing it |
| `docs` | Documentation error or improvement |
| `question` | Usage question |

---

## Security Vulnerabilities

> [!CAUTION]
> **Do NOT open a public GitHub issue for security vulnerabilities.**
>
> If you discover a privilege escalation, code injection, path traversal, or any other security issue in a script, report it privately.
>
> Email: **[see maintainer profile for contact](https://github.com/Anamicca23)**
>
> Please include: the affected script path, the vulnerability description, steps to reproduce, and your suggested fix if you have one.
>
> We will acknowledge receipt within 48 hours and aim to release a fix within 7 days.

---

<div align="center">

Thank you for making this toolkit better for everyone.
Every contribution matters — from a one-line typo fix to a complete new script.

<br/>

**[`↑ Back to Top`](#top)**

</div>