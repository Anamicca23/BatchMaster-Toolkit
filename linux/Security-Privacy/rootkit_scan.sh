#!/usr/bin/env bash
# ============================================================
# Name      : rootkit_scan.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW  (read-only security scanning)
# Sudo      : Required
# Reversible: Yes
# Desc      : Installs rkhunter and chkrootkit if missing,
#             runs both scanners, combines output into a
#             timestamped report. Highlights WARNING and
#             INFECTED lines in red on the terminal.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./rootkit_scan.sh${NC}\n"
    exit 1
fi

REPORT_DIR="/root"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/security_scan_${TIMESTAMP}.txt"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║          ROOTKIT SCANNER  v1.0.0                     ║"
    echo "  ║     rkhunter + chkrootkit — full threat scan         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Scan  (rkhunter + chkrootkit)"
    echo -e "  ${BOLD}[2]${NC}  rkhunter Scan Only"
    echo -e "  ${BOLD}[3]${NC}  chkrootkit Scan Only"
    echo -e "  ${BOLD}[4]${NC}  Update rkhunter Database"
    echo -e "  ${BOLD}[5]${NC}  Install Scanners  (if missing)"
    echo -e "  ${BOLD}[6]${NC}  View Last Scan Report"
    echo -e "  ${BOLD}[7]${NC}  About — What These Tools Detect"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

install_scanners() {
    local needs_install=0
    echo
    for tool in rkhunter chkrootkit; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "  Installing ${tool}..."
            apt-get install -y "$tool" 2>&1 | tail -3 | sed 's/^/  /'
            needs_install=1
        else
            echo -e "  ${GREEN}[OK]${NC} $tool already installed."
        fi
    done
    [[ $needs_install -eq 1 ]] && echo -e "\n  ${GREEN}[DONE]${NC} Scanners installed." || \
        echo -e "  All required tools are already installed."
    echo
}

update_rkhunter() {
    if ! command -v rkhunter &>/dev/null; then
        echo -e "  ${YELLOW}rkhunter not installed. Run option [5] first.${NC}"
        return
    fi
    echo -e "\n  Updating rkhunter database..."
    rkhunter --update 2>&1 | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC} Database updated."
    echo
}

run_rkhunter() {
    if ! command -v rkhunter &>/dev/null; then
        echo -e "  ${YELLOW}rkhunter not installed.${NC}"
        install_scanners
        command -v rkhunter &>/dev/null || return
    fi

    echo -e "\n  ${BOLD}Running rkhunter...${NC}"
    echo -e "  This may take 2-5 minutes.\n"

    local rk_out; rk_out=$(mktemp)
    rkhunter --check --sk --rwo 2>/dev/null > "$rk_out" || true

    # Display with highlights
    local warn_count=0 ok_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "warning|suspect"; then
            echo -e "  ${YELLOW}${line}${NC}"
            warn_count=$(( warn_count + 1 ))
        elif echo "$line" | grep -qiE "infected|found"; then
            echo -e "  ${RED}${line}${NC}"
            warn_count=$(( warn_count + 1 ))
        elif echo "$line" | grep -qiE "\[ OK \]|not found|not set"; then
            echo -e "  ${GREEN}${line}${NC}"
            ok_count=$(( ok_count + 1 ))
        else
            echo "  $line"
        fi
    done < "$rk_out"

    echo
    echo -e "  ${BOLD}rkhunter summary:${NC} ${GREEN}${ok_count} OK${NC}  ${YELLOW}${warn_count} warnings${NC}"
    cat "$rk_out" >> "$REPORT_FILE" 2>/dev/null
    rm -f "$rk_out"
}

run_chkrootkit() {
    if ! command -v chkrootkit &>/dev/null; then
        echo -e "  ${YELLOW}chkrootkit not installed.${NC}"
        install_scanners
        command -v chkrootkit &>/dev/null || return
    fi

    echo -e "\n  ${BOLD}Running chkrootkit...${NC}"
    echo -e "  This may take 1-3 minutes.\n"

    local ck_out; ck_out=$(mktemp)
    chkrootkit 2>/dev/null > "$ck_out" || true

    # Display with highlights
    local infected_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "INFECTED|Possible"; then
            echo -e "  ${RED}${BOLD}${line}${NC}"
            infected_count=$(( infected_count + 1 ))
        elif echo "$line" | grep -qi "not infected"; then
            echo -e "  ${GREEN}${line}${NC}"
        else
            echo "  $line"
        fi
    done < "$ck_out"

    echo
    if [[ $infected_count -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} chkrootkit found no infections."
    else
        echo -e "  ${RED}[ALERT]${NC} chkrootkit found ${infected_count} potential infection(s)."
        echo -e "  ${YELLOW}Note:${NC} Some are false positives. Investigate before taking action."
    fi
    cat "$ck_out" >> "$REPORT_FILE" 2>/dev/null
    rm -f "$ck_out"
}

full_scan() {
    install_scanners

    # Init report file
    {
        echo "========================================================"
        echo "  ROOTKIT SCAN REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "  Kernel:    $(uname -r)"
        echo "========================================================"
        echo
    } > "$REPORT_FILE"

    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL SECURITY SCAN...${NC}"
    echo -e "  Report will be saved to: $REPORT_FILE\n"

    echo -e "${BOLD}${CYAN}  ── rkhunter ────────────────────────${NC}"
    { echo; echo "=== RKHUNTER ==="; } >> "$REPORT_FILE"
    run_rkhunter

    echo -e "\n${BOLD}${CYAN}  ── chkrootkit ──────────────────────${NC}"
    { echo; echo "=== CHKROOTKIT ==="; } >> "$REPORT_FILE"
    run_chkrootkit

    {
        echo
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } >> "$REPORT_FILE"

    echo
    echo -e "${BOLD}${GREEN}  [DONE]${NC} Full scan complete."
    echo -e "  Report saved: ${BOLD}${REPORT_FILE}${NC}"
    echo
    # Show highlighted summary
    echo -e "  ${BOLD}Findings summary:${NC}"
    grep -iE "warning|INFECTED|Possible" "$REPORT_FILE" 2>/dev/null | \
        head -20 | sed 's/^/  /' | while IFS= read -r line; do
        echo -e "  ${RED}${line}${NC}"
    done || echo -e "  ${GREEN}No warnings or infections found in report.${NC}"
    echo
}

view_last_report() {
    clear
    local latest; latest=$(ls -t /root/security_scan_*.txt 2>/dev/null | head -1)
    if [[ -z "$latest" ]]; then
        echo -e "\n  ${YELLOW}No scan reports found.${NC}"
        echo -e "  Run a scan first (option [1]).\n"
        return
    fi
    echo -e "${BOLD}${CYAN}  LAST SCAN REPORT: $latest${NC}"
    echo -e "  ${DASH}\n"
    # Show warnings highlighted
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "INFECTED|Possible"; then
            echo -e "  ${RED}${line}${NC}"
        elif echo "$line" | grep -qi "warning"; then
            echo -e "  ${YELLOW}${line}${NC}"
        else
            echo "  $line"
        fi
    done < "$latest"
    echo
}

about_scanners() {
    clear
    echo -e "${BOLD}${CYAN}  ABOUT ROOTKIT SCANNERS${NC}"
    echo -e "  ${DASH}\n"
    cat << 'INFO'
  rkhunter (Rootkit Hunter):
  ──────────────────────────
  Checks for known rootkits by examining:
    - Known rootkit signatures and files
    - Hidden files/directories
    - Suspicious file permissions
    - System binary modifications (checks against known-good hashes)
    - Network interfaces in promiscuous mode
    - Listening applications and ports
    - Startup files and scripts

  chkrootkit:
  ────────────
  Shell script that scans for known rootkit signatures by checking:
    - Modifications to system binaries (ps, ls, netstat, etc.)
    - Loadable kernel module (LKM) rootkits
    - Known rootkit files and directories
    - Network interfaces in promiscuous mode
    - Log file tampering signs

  False Positives:
  ─────────────────
  Both tools may report false positives. Common ones include:
    - SSH root login warnings (expected if root SSH is enabled)
    - PACKET_SNIFFER warnings (may be from legit apps like Wireshark)
    - rkhunter warnings about package manager binary hashes
      (can occur after OS updates — run rkhunter --propupd after updates)

  What to do if infections are found:
  ─────────────────────────────────────
    1. Boot from a live USB to scan in a clean environment
    2. Preserve evidence before attempting cleanup
    3. Consider a full OS reinstall if rootkit is confirmed
    4. Change all passwords from a clean machine

INFO
}

while true; do
    show_menu
    case "$choice" in
        1) full_scan;          read -rp "  Press Enter..." ;;
        2) clear; REPORT_FILE="${REPORT_DIR}/security_scan_${TIMESTAMP}_rk.txt"
           { echo "=== RKHUNTER $(date) ==="; } > "$REPORT_FILE"
           run_rkhunter;       read -rp "  Press Enter..." ;;
        3) clear; REPORT_FILE="${REPORT_DIR}/security_scan_${TIMESTAMP}_ck.txt"
           { echo "=== CHKROOTKIT $(date) ==="; } > "$REPORT_FILE"
           run_chkrootkit;     read -rp "  Press Enter..." ;;
        4) update_rkhunter;    read -rp "  Press Enter..." ;;
        5) install_scanners;   read -rp "  Press Enter..." ;;
        6) view_last_report;   read -rp "  Press Enter..." ;;
        7) about_scanners;     read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
