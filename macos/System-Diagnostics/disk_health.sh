#!/usr/bin/env bash
# ============================================================
# Name      : disk_health.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Required (for diskutil and smartctl)
# Reversible: Yes  (read-only, no changes made)
# Desc      : Runs diskutil on all physical disks reporting
#             SMART status, partition scheme, file system,
#             and capacity. If smartmontools is installed,
#             reads full SMART attribute table.
# ============================================================

set -euo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           DISK HEALTH CHECKER  v1.0.0                ║"
    echo "  ║     SMART status, partition info, and health          ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Disk Health Report (all drives)"
    echo -e "  ${BOLD}[2]${NC}  SMART Status Summary"
    echo -e "  ${BOLD}[3]${NC}  Disk Usage (volumes)"
    echo -e "  ${BOLD}[4]${NC}  SMART Attributes (requires smartmontools)"
    echo -e "  ${BOLD}[5]${NC}  Run First Aid on a Volume"
    echo -e "  ${BOLD}[6]${NC}  Export Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "\n  ${YELLOW}[INFO]${NC} Some features require sudo for full access."
        echo -e "  Run with: ${BOLD}sudo ./disk_health.sh${NC} for complete results.\n"
    fi
}

full_report() {
    check_sudo
    clear
    echo -e "${BOLD}${CYAN}  FULL DISK HEALTH REPORT${NC}"
    echo -e "  ${DASH}"
    echo -e "\n  ${BOLD}Physical Disks:${NC}\n"

    diskutil list 2>/dev/null | grep "^/dev/disk" | awk '{print $1}' | while read -r dev; do
        echo -e "  ${BOLD}${CYAN}Drive: $dev${NC}"
        echo -e "  ${DASH}"
        local info; info=$(diskutil info "$dev" 2>/dev/null)

        local size;       size=$(echo "$info"       | grep "Disk Size"              | awk -F': ' '{print $2}' | sed 's/ (.*//;s/^ *//')
        local media;      media=$(echo "$info"      | grep "Device / Media Name"    | awk -F': ' '{print $2}' | sed 's/^ *//')
        local protocol;   protocol=$(echo "$info"   | grep "Device Protocol"        | awk -F': ' '{print $2}' | sed 's/^ *//')
        local smart;      smart=$(echo "$info"      | grep "SMART Status"           | awk -F': ' '{print $2}' | sed 's/^ *//')
        local part_map;   part_map=$(echo "$info"   | grep "Partition Map Scheme"   | awk -F': ' '{print $2}' | sed 's/^ *//')
        local disk_type;  disk_type=$(echo "$info"  | grep "Solid State"            | awk -F': ' '{print $2}' | sed 's/^ *//')

        printf "  %-26s %s\n" "Media Name:"   "${media:-N/A}"
        printf "  %-26s %s\n" "Size:"         "${size:-N/A}"
        printf "  %-26s %s\n" "Protocol:"     "${protocol:-N/A}"
        printf "  %-26s %s\n" "Partition Map:" "${part_map:-N/A}"
        printf "  %-26s %s\n" "Solid State:"  "${disk_type:-N/A}"

        # SMART status with color
        if [[ "$smart" == "Verified" || "$smart" == "Supported" ]]; then
            echo -e "  $(printf '%-26s' 'SMART Status:') ${GREEN}${smart}${NC}"
        elif [[ "$smart" == "Not Supported" || -z "$smart" ]]; then
            echo -e "  $(printf '%-26s' 'SMART Status:') ${YELLOW}${smart:-Not Available}${NC}"
        else
            echo -e "  $(printf '%-26s' 'SMART Status:') ${RED}${smart}${NC}"
        fi

        # List partitions
        echo -e "\n  Partitions:"
        diskutil list "$dev" 2>/dev/null | grep "^\s" | awk '{printf "    %s  %s  %s\n", $1, $3, $NF}'
        echo
    done
}

smart_summary() {
    clear
    echo -e "${BOLD}${CYAN}  SMART STATUS SUMMARY${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-12s %-35s %-12s %s\n" "Device" "Media Name" "Size" "SMART"
    echo -e "  ${DASH}"

    diskutil list 2>/dev/null | grep "^/dev/disk" | awk '{print $1}' | while read -r dev; do
        local info;  info=$(diskutil info "$dev" 2>/dev/null)
        local media; media=$(echo "$info" | grep "Device / Media Name" | awk -F': ' '{print $2}' | sed 's/^ *//' | cut -c1-33)
        local size;  size=$(echo "$info"  | grep "Disk Size"           | awk -F': ' '{print $2}' | sed 's/ (.*//;s/^ *//')
        local smart; smart=$(echo "$info" | grep "SMART Status"        | awk -F': ' '{print $2}' | sed 's/^ *//')

        local color="$NC"
        [[ "$smart" == "Verified" ]] && color="$GREEN"
        [[ "$smart" != "Verified" && -n "$smart" ]] && color="$RED"

        printf "  %-12s %-35s %-12s ${color}%s${NC}\n" "$dev" "${media:-N/A}" "${size:-N/A}" "${smart:-N/A}"
    done
    echo
}

disk_usage() {
    clear
    echo -e "${BOLD}${CYAN}  DISK USAGE — ALL VOLUMES${NC}"
    echo -e "  ${DASH}"
    echo
    printf "  %-38s %8s %8s %8s %6s\n" "Filesystem/Volume" "Total" "Used" "Free" "Use%"
    echo -e "  ${DASH}"
    df -h 2>/dev/null | awk 'NR>1 && !/devfs|map|/dev/loop/ {printf "  %-38s %8s %8s %8s %6s\n", $9, $2, $3, $4, $5}' | head -20
    echo
    echo -e "  ${BOLD}Volumes detail (diskutil list):${NC}"
    diskutil list 2>/dev/null
    echo
}

smart_attributes() {
    clear
    echo -e "${BOLD}${CYAN}  SMART ATTRIBUTES${NC}"
    echo -e "  ${DASH}\n"

    if ! command -v smartctl &>/dev/null; then
        echo -e "  ${YELLOW}[INFO]${NC} smartmontools is not installed."
        echo -e "  Install with: ${BOLD}brew install smartmontools${NC}"
        echo -e "  or: ${BOLD}sudo port install smartmontools${NC}"
        echo
        echo -e "  smartmontools provides detailed SMART attributes including:"
        echo -e "    - Reallocated sector count  (indicates bad sectors)"
        echo -e "    - Power-on hours            (total drive runtime)"
        echo -e "    - Temperature               (drive operating temp)"
        echo -e "    - Uncorrectable error count (critical failures)"
        echo
        return
    fi

    diskutil list 2>/dev/null | grep "^/dev/disk" | awk '{print $1}' | while read -r dev; do
        echo -e "  ${BOLD}${CYAN}$dev${NC}"
        echo -e "  ${DASH}"
        if [[ $EUID -eq 0 ]]; then
            smartctl -a "$dev" 2>/dev/null | grep -E "SMART overall|Model|Capacity|Power On|Temperature|Reallocated|Uncorrectable|Pending" || \
                echo "  No SMART data available for $dev"
        else
            echo -e "  ${YELLOW}Run as sudo for SMART attribute data on $dev${NC}"
        fi
        echo
    done
}

run_firstaid() {
    clear
    echo -e "${BOLD}${CYAN}  FIRST AID${NC}"
    echo -e "  ${DASH}\n"
    echo  "  Available volumes:"
    diskutil list 2>/dev/null | grep -v "^/dev/disk\|TYPE\|Container\|Apple_partition_map" | grep "/" | awk '{print "   "$NF}' | head -15
    echo
    printf "  Enter volume path to verify (e.g. /dev/disk0s1 or /): "
    read -r vol
    if [[ -z "$vol" ]]; then
        echo -e "  ${RED}No volume specified.${NC}"; echo; return
    fi
    echo
    echo -e "  ${YELLOW}Running First Aid on $vol...${NC}"
    echo -e "  ${YELLOW}This may take several minutes.${NC}\n"
    diskutil verifyVolume "$vol" 2>&1 | sed 's/^/  /'
    echo
}

export_report() {
    local rpt="$HOME/Desktop/DiskHealth_Report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  DISK HEALTH REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        echo "[DISK LIST]"
        diskutil list 2>/dev/null
        echo
        echo "[SMART STATUS PER DISK]"
        diskutil list 2>/dev/null | grep "^/dev/disk" | awk '{print $1}' | while read -r dev; do
            echo "--- $dev ---"
            diskutil info "$dev" 2>/dev/null | grep -E "Disk Size|Device / Media Name|SMART Status|Partition Map|Solid State|Device Protocol"
            echo
        done
        echo "[VOLUME USAGE]"
        df -h 2>/dev/null
        echo
        if command -v smartctl &>/dev/null && [[ $EUID -eq 0 ]]; then
            echo "[SMARTCTL DETAILS]"
            diskutil list 2>/dev/null | grep "^/dev/disk" | awk '{print $1}' | while read -r dev; do
                echo "--- $dev ---"
                smartctl -a "$dev" 2>/dev/null
            done
        fi
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved to Desktop: $(basename "$rpt")"
}

while true; do
    show_menu
    case "$choice" in
        1) full_report;       read -rp "  Press Enter..." ;;
        2) smart_summary;     read -rp "  Press Enter..." ;;
        3) disk_usage;        read -rp "  Press Enter..." ;;
        4) smart_attributes;  read -rp "  Press Enter..." ;;
        5) run_firstaid;      read -rp "  Press Enter..." ;;
        6) export_report;     read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
