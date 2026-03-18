#!/usr/bin/env bash
# ============================================================
# Name      : log_cleaner.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : MEDIUM
# Sudo      : Required
# Reversible: No  (deleted log files cannot be recovered)
# Desc      : Cleans system logs older than 7 days.
#             journalctl --vacuum-time + rotated .gz/.1/.old
#             files in /var/log. Does NOT touch active logs.
#             Reports size before and after each step.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./log_cleaner.sh${NC}\n"
    exit 1
fi

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           LOG CLEANER  v1.0.0                        ║"
    echo "  ║     Trim journals, rotated logs, and crash reports   ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Log Clean  (all steps)"
    echo -e "  ${BOLD}[2]${NC}  Vacuum systemd Journal  (keep 7 days)"
    echo -e "  ${BOLD}[3]${NC}  Remove Rotated Logs  (.gz .1 .old files)"
    echo -e "  ${BOLD}[4]${NC}  Clear Crash Reports  (/var/crash)"
    echo -e "  ${BOLD}[5]${NC}  Clear Old Kern/Syslog archives"
    echo -e "  ${BOLD}[6]${NC}  Show Log Sizes  (preview)"
    echo -e "  ${BOLD}[7]${NC}  View Recent Journal Errors"
    echo -e "  ${BOLD}[8]${NC}  Export Log Size Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

folder_mb() { [[ -d "$1" ]] && du -sm "$1" 2>/dev/null | awk '{print $1}' || echo 0; }

confirm() {
    echo; echo -e "  ${YELLOW}[WARNING]${NC} $1"
    printf "  Proceed? (y/N): "; read -r ans
    [[ "${ans,,}" == "y" ]] && return 0 || { echo "  Cancelled."; return 1; }
}

step() { echo -e "\n  ${BOLD}${CYAN}[$1/$2]${NC} $3"; }
ok()   { echo -e "  ${GREEN}[DONE]${NC} $1"; }

vacuum_journal() {
    step "$1" "$2" "Vacuuming systemd journal..."
    local before; before=$(folder_mb "/var/log/journal")
    journalctl --vacuum-time=7d   2>&1 | sed 's/^/  /'
    journalctl --vacuum-size=100M 2>&1 | sed 's/^/  /'
    local after; after=$(folder_mb "/var/log/journal")
    ok "Journal vacuumed.  Freed: ~$(( before - after )) MB"
}

clean_rotated() {
    step "$1" "$2" "Removing rotated log archives (.gz .1 .2 .old)..."
    local before; before=$(folder_mb "/var/log")
    local count=0

    # Remove compressed archives
    find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null && count=$(( count + 1 )) || true
    # Remove numbered rotations older than 7 days
    find /var/log -name "*.1" -o -name "*.2" -o -name "*.3" 2>/dev/null | \
        xargs -I{} find {} -mtime +7 -delete 2>/dev/null || true
    # Remove .old files
    find /var/log -name "*.old" -mtime +7 -delete 2>/dev/null || true
    # Truncate zero-byte logs
    find /var/log -name "*.log" -empty -delete 2>/dev/null || true

    local after; after=$(folder_mb "/var/log")
    ok "Rotated logs removed.  Freed: ~$(( before - after )) MB"
}

clean_crash() {
    step "$1" "$2" "Clearing crash reports..."
    local before=0
    if [[ -d /var/crash ]]; then
        before=$(folder_mb "/var/crash")
        rm -rf /var/crash/*.crash /var/crash/*.upload 2>/dev/null || true
    fi
    if [[ -d /var/lib/apport/coredump ]]; then
        rm -rf /var/lib/apport/coredump/* 2>/dev/null || true
    fi
    ok "Crash reports cleared.  Freed: ~${before} MB"
}

clean_kern_syslog() {
    step "$1" "$2" "Removing old kern/syslog archives..."
    local before; before=$(folder_mb "/var/log")
    for f in /var/log/kern.log.* /var/log/syslog.* /var/log/messages.* /var/log/auth.log.*; do
        [[ -f "$f" ]] && rm -f "$f" 2>/dev/null && echo "  Removed: $f" || true
    done
    local after; after=$(folder_mb "/var/log")
    ok "Old log archives removed.  Freed: ~$(( before - after )) MB"
}

show_sizes() {
    clear
    echo -e "${BOLD}${CYAN}  LOG SIZES — PREVIEW${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-50s %s\n" "Path" "Size"
    echo -e "  ${DASH}"
    printf "  %-50s %s MB\n" "/var/log  (total)" "$(folder_mb /var/log)"
    printf "  %-50s %s MB\n" "/var/log/journal" "$(folder_mb /var/log/journal)"

    # Count rotated files
    local gz_count; gz_count=$(find /var/log -name "*.gz" 2>/dev/null | wc -l)
    local gz_size; gz_size=$(find /var/log -name "*.gz" 2>/dev/null -exec du -sm {} + 2>/dev/null | awk '{s+=$1}END{print s+0}')
    printf "  %-50s %s files (%s MB)\n" "Rotated logs (.gz)" "$gz_count" "$gz_size"

    local crash_size; crash_size=$(folder_mb "/var/crash")
    printf "  %-50s %s MB\n" "/var/crash" "$crash_size"
    echo
    echo -e "  Total /var/log disk usage: $(du -sh /var/log 2>/dev/null | awk '{print $1}')"
    echo
}

view_errors() {
    clear
    echo -e "${BOLD}${CYAN}  RECENT JOURNAL ERRORS${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  ${BOLD}Last 50 ERROR/CRITICAL messages:${NC}\n"
    journalctl -p err --since "24 hours ago" 2>/dev/null | tail -50 | sed 's/^/  /'
    echo
}

full_clean() {
    confirm "Full log clean will delete rotated/old logs and vacuum the journal." || return
    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL LOG CLEAN...${NC}\n"
    local before; before=$(folder_mb "/var/log")
    vacuum_journal   1 4
    clean_rotated    2 4
    clean_crash      3 4
    clean_kern_syslog 4 4
    local after; after=$(folder_mb "/var/log")
    echo
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  LOG CLEAN COMPLETE                                   ║"
    printf "  ║  %-52s  ║\n" "/var/log freed: ~$(( before - after )) MB"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

export_report() {
    local rpt="/root/Desktop/LogReport_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p /root/Desktop 2>/dev/null
    {
        echo "========================================================"
        echo "  LOG SIZE REPORT"
        echo "  Generated: $(date)"
        echo "========================================================"
        echo
        du -sh /var/log/* 2>/dev/null | sort -rh | head -30
        echo
        echo "[JOURNAL SIZE]"
        journalctl --disk-usage 2>/dev/null
        echo
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved: $rpt\n"
}

while true; do
    show_menu
    case "$choice" in
        1) full_clean ;;
        2) confirm "Vacuum systemd journal?" && vacuum_journal 1 1; echo; read -rp "  Press Enter..." ;;
        3) confirm "Remove rotated log files?" && clean_rotated 1 1; echo; read -rp "  Press Enter..." ;;
        4) confirm "Clear crash reports?" && clean_crash 1 1; echo; read -rp "  Press Enter..." ;;
        5) confirm "Remove old kern/syslog archives?" && clean_kern_syslog 1 1; echo; read -rp "  Press Enter..." ;;
        6) show_sizes;   read -rp "  Press Enter..." ;;
        7) view_errors;  read -rp "  Press Enter..." ;;
        8) export_report; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
