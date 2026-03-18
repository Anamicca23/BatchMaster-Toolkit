#!/usr/bin/env bash
# ============================================================
# Name      : system_info.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (read-only, no changes made)
# Desc      : Full system snapshot dashboard — CPU, RAM, GPU,
#             disk, battery, network, and uptime using
#             system_profiler, sysctl, vm_stat, df, and ioreg.
# ============================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m';   YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m';  BLUE='\033[0;34m';   BOLD='\033[1m'
MAGENTA='\033[0;35m'; NC='\033[0m'

SEP="════════════════════════════════════════════════════════"
DASH="────────────────────────────────────────────────────────"

header() { echo -e "\n${BOLD}${CYAN}  ══ $1 ══${NC}"; echo -e "  ${DASH}"; }
row()    { printf "  ${BOLD}%-22s${NC} %s\n" "$1" "$2"; }

# ── Menu ──────────────────────────────────────────────────────────────
show_menu() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         SYSTEM INFO DASHBOARD  v1.0.0                ║"
    echo "  ║     macOS System Analytics & Hardware Report         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full System Dashboard"
    echo -e "  ${BOLD}[2]${NC}  CPU Details"
    echo -e "  ${BOLD}[3]${NC}  Memory / RAM"
    echo -e "  ${BOLD}[4]${NC}  Disk Usage"
    echo -e "  ${BOLD}[5]${NC}  GPU and Display"
    echo -e "  ${BOLD}[6]${NC}  Network Interfaces"
    echo -e "  ${BOLD}[7]${NC}  Battery Status"
    echo -e "  ${BOLD}[8]${NC}  Export Full Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

# ── OS Info ───────────────────────────────────────────────────────────
get_os() {
    header "OPERATING SYSTEM"
    local os_name; os_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
    local os_ver;  os_ver=$(sw_vers -productVersion 2>/dev/null || echo "N/A")
    local os_build; os_build=$(sw_vers -buildVersion 2>/dev/null || echo "N/A")
    local hostname; hostname=$(hostname 2>/dev/null || echo "N/A")
    local uptime_raw; uptime_raw=$(uptime 2>/dev/null | sed 's/.*up //' | sed 's/,.*//')
    local kernel; kernel=$(uname -r 2>/dev/null || echo "N/A")
    local arch; arch=$(uname -m 2>/dev/null || echo "N/A")

    row "OS Name:"      "$os_name $os_ver"
    row "Build:"        "$os_build"
    row "Kernel:"       "$kernel ($arch)"
    row "Hostname:"     "$hostname"
    row "Uptime:"       "$uptime_raw"
    row "User:"         "$(whoami)"
}

# ── CPU ───────────────────────────────────────────────────────────────
get_cpu() {
    header "PROCESSOR"
    local cpu_brand; cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || \
        system_profiler SPHardwareDataType 2>/dev/null | grep "Chip\|Processor Name" | head -1 | sed 's/.*: //')
    local cores_phy; cores_phy=$(sysctl -n hw.physicalcpu 2>/dev/null || echo "N/A")
    local cores_log; cores_log=$(sysctl -n hw.logicalcpu 2>/dev/null || echo "N/A")
    local cpu_freq
    if sysctl -n hw.cpufrequency_max &>/dev/null; then
        cpu_freq=$(( $(sysctl -n hw.cpufrequency_max 2>/dev/null) / 1000000 ))
        cpu_freq="${cpu_freq} MHz"
    else
        cpu_freq=$(system_profiler SPHardwareDataType 2>/dev/null | grep -i "speed\|GHz" | head -1 | sed 's/.*: //' || echo "N/A")
    fi
    local load; load=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print $3}' | tr -d '%' || echo "N/A")

    row "CPU Model:"    "$cpu_brand"
    row "Physical Cores:" "$cores_phy"
    row "Logical Cores:"  "$cores_log"
    row "Max Frequency:"  "$cpu_freq"
    row "CPU Load:"       "${load}% (user)"
}

# ── RAM ───────────────────────────────────────────────────────────────
get_ram() {
    header "MEMORY  (RAM)"
    local total_bytes; total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    local total_gb; total_gb=$(( total_bytes / 1073741824 ))

    # vm_stat gives page-based memory breakdown
    local page_size; page_size=$(vm_stat 2>/dev/null | grep "page size" | awk '{print $8}' || echo 4096)
    local pages_free; pages_free=$(vm_stat 2>/dev/null | grep "^Pages free:" | awk '{print $3}' | tr -d '.' || echo 0)
    local pages_active; pages_active=$(vm_stat 2>/dev/null | grep "^Pages active:" | awk '{print $3}' | tr -d '.' || echo 0)
    local pages_inactive; pages_inactive=$(vm_stat 2>/dev/null | grep "^Pages inactive:" | awk '{print $3}' | tr -d '.' || echo 0)
    local pages_wired; pages_wired=$(vm_stat 2>/dev/null | grep "^Pages wired down:" | awk '{print $4}' | tr -d '.' || echo 0)
    local pages_compressed; pages_compressed=$(vm_stat 2>/dev/null | grep "^Pages occupied by compressor:" | awk '{print $5}' | tr -d '.' || echo 0)

    local free_mb=$(( pages_free * page_size / 1048576 ))
    local active_mb=$(( pages_active * page_size / 1048576 ))
    local inactive_mb=$(( pages_inactive * page_size / 1048576 ))
    local wired_mb=$(( pages_wired * page_size / 1048576 ))
    local compressed_mb=$(( pages_compressed * page_size / 1048576 ))
    local used_mb=$(( active_mb + wired_mb + compressed_mb ))
    local total_mb=$(( total_bytes / 1048576 ))
    local pct=0
    [[ $total_mb -gt 0 ]] && pct=$(( used_mb * 100 / total_mb ))

    # Bar
    local bar_len=30; local filled=$(( pct * bar_len / 100 ))
    local bar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $filled ]] && bar+="#" || bar+="."; done

    row "Total RAM:"      "${total_gb} GB  (${total_mb} MB)"
    row "Used (approx):"  "${used_mb} MB  (${pct}%)"
    row "Free:"           "${free_mb} MB"
    row "Active:"         "${active_mb} MB"
    row "Wired:"          "${wired_mb} MB"
    row "Compressed:"     "${compressed_mb} MB"
    row "Inactive:"       "${inactive_mb} MB"
    echo
    echo -e "  Usage  [${GREEN}${bar}${NC}] ${pct}%"

    # Memory modules
    echo
    echo -e "  ${BOLD}Memory Modules:${NC}"
    system_profiler SPMemoryDataType 2>/dev/null | \
        grep -E "Size:|Speed:|Type:|Manufacturer:" | \
        sed 's/^[[:space:]]*/    /' | head -20
}

# ── Disk ──────────────────────────────────────────────────────────────
get_disk() {
    header "DISK USAGE"
    echo -e "  ${BOLD}Physical Drives:${NC}"
    diskutil list 2>/dev/null | grep "^/dev/disk" | while read -r dev _rest; do
        local info; info=$(diskutil info "$dev" 2>/dev/null)
        local size; size=$(echo "$info" | grep "Disk Size" | awk -F': ' '{print $2}' | sed 's/ (.*//')
        local media; media=$(echo "$info" | grep "Device / Media Name:" | awk -F': ' '{print $2}')
        local smart; smart=$(echo "$info" | grep "SMART Status" | awk -F': ' '{print $2}')
        printf "  %-12s  %-10s  %-30s  SMART: %s\n" "$dev" "$size" "$media" "${smart:-N/A}"
    done
    echo
    echo -e "  ${BOLD}Volume Usage:${NC}"
    printf "  %-35s %8s %8s %8s %5s\n" "Volume" "Total" "Used" "Free" "Use%"
    echo -e "  ${DASH}"
    df -h 2>/dev/null | grep -v "^Filesystem\|devfs\|map\|/dev/loop\|tmpfs" | \
        awk 'NR>1 {printf "  %-35s %8s %8s %8s %5s\n", $9, $2, $3, $4, $5}' | head -15
}

# ── GPU ───────────────────────────────────────────────────────────────
get_gpu() {
    header "GPU AND DISPLAY"
    echo -e "  ${BOLD}GPU:${NC}"
    system_profiler SPDisplaysDataType 2>/dev/null | \
        grep -E "^\s+(Chipset Model|VRAM|Resolution|Vendor|Metal):" | \
        sed 's/^[[:space:]]*/    /'
}

# ── Network ───────────────────────────────────────────────────────────
get_network() {
    header "NETWORK INTERFACES"
    ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | \
        grep -v "inet6\|lo0\|127.0.0.1" | \
        sed 's/^[[:space:]]*/    /'
    echo
    echo -e "  ${BOLD}Default Gateway:${NC}"
    netstat -rn 2>/dev/null | grep "^default" | awk '{print "  "$2}' | head -3
    echo
    echo -e "  ${BOLD}DNS Servers:${NC}"
    cat /etc/resolv.conf 2>/dev/null | grep "nameserver" | sed 's/^/    /'
    scutil --dns 2>/dev/null | grep "nameserver\[0\]" | head -3 | sed 's/^/    /'
}

# ── Battery ───────────────────────────────────────────────────────────
get_battery() {
    header "BATTERY"
    # Check if battery exists
    if ! ioreg -rn AppleSmartBattery 2>/dev/null | grep -q "CycleCount"; then
        echo -e "  ${YELLOW}No battery detected (Desktop Mac or unsupported model)${NC}"
        return
    fi

    local cycle;   cycle=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep CycleCount | awk '{print $NF}')
    local maxcap;  maxcap=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep '"MaxCapacity"' | awk '{print $NF}')
    local curcap;  curcap=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep '"CurrentCapacity"' | awk '{print $NF}')
    local dscap;   dscap=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep 'DesignCapacity' | grep -v Raw | awk '{print $NF}')
    local charging; charging=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep '"IsCharging"' | awk '{print $NF}')
    local plugged;  plugged=$(ioreg -rn AppleSmartBattery 2>/dev/null | grep 'ExternalConnected' | awk '{print $NF}')

    local pct=0
    [[ -n "$maxcap" && "$maxcap" -gt 0 ]] && pct=$(( curcap * 100 / maxcap )) || true

    local wear=0
    [[ -n "$dscap" && "$dscap" -gt 0 ]] && wear=$(( (dscap - maxcap) * 100 / dscap )) || true

    local status="On Battery"
    [[ "$plugged" == "Yes" || "$plugged" == "1" ]] && status="Plugged In"
    [[ "$charging" == "Yes" || "$charging" == "1" ]] && status="Charging"

    local health="Excellent"
    [[ $wear -ge 20 ]] && health="${YELLOW}Good (normal aging)${NC}"
    [[ $wear -ge 40 ]] && health="${RED}Degraded — consider replacing${NC}"
    [[ $wear -ge 60 ]] && health="${RED}Poor — replace soon${NC}"

    local bar_len=30; local filled=$(( pct * bar_len / 100 ))
    local bar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $filled ]] && bar+="#" || bar+="."; done

    row "Charge:"         "${pct}%  [${bar}]"
    row "Status:"         "$status"
    row "Cycle Count:"    "${cycle:-N/A}"
    row "Max Capacity:"   "${maxcap:-N/A} mAh"
    row "Design Capacity:" "${dscap:-N/A} mAh"
    row "Wear Level:"     "${wear}%"
    echo -e "  Battery Health:  $(eval echo -e \"$health\")"
}

# ── Full Dashboard ────────────────────────────────────────────────────
full_dashboard() {
    clear
    echo -e "${BOLD}${BLUE}  ${SEP}"
    echo -e "  SYSTEM INFO DASHBOARD  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  ${SEP}${NC}"
    get_os
    get_cpu
    get_ram
    get_disk
    get_gpu
    get_battery
    get_network
    echo
    echo -e "${BOLD}${BLUE}  ${SEP}${NC}"
}

# ── Export ────────────────────────────────────────────────────────────
export_report() {
    local rpt="$HOME/Desktop/SystemInfo_Report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  SYSTEM INFO REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        echo "[OS]";       sw_vers
        echo; echo "[CPU]";     sysctl -n machdep.cpu.brand_string 2>/dev/null || system_profiler SPHardwareDataType 2>/dev/null | grep -E "Chip|Processor"
        echo; echo "[MEMORY]";  vm_stat; sysctl hw.memsize
        echo; echo "[DISK]";    df -h; diskutil list
        echo; echo "[GPU]";     system_profiler SPDisplaysDataType 2>/dev/null
        echo; echo "[NETWORK]"; ifconfig; netstat -rn 2>/dev/null | head -20
        echo; echo "[BATTERY]"; ioreg -rn AppleSmartBattery 2>/dev/null | grep -E "CycleCount|MaxCapacity|DesignCapacity|IsCharging|CurrentCapacity|ExternalConnected" | sed 's/^[[:space:]]*/  /'
        echo
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved to Desktop as: $(basename "$rpt")"
}

# ── Main Loop ─────────────────────────────────────────────────────────
while true; do
    show_menu
    case "$choice" in
        1) full_dashboard; read -rp "  Press Enter to continue..." ;;
        2) clear; get_os; get_cpu; echo; read -rp "  Press Enter..." ;;
        3) clear; get_ram; echo; read -rp "  Press Enter..." ;;
        4) clear; get_disk; echo; read -rp "  Press Enter..." ;;
        5) clear; get_gpu; echo; read -rp "  Press Enter..." ;;
        6) clear; get_network; echo; read -rp "  Press Enter..." ;;
        7) clear; get_battery; echo; read -rp "  Press Enter..." ;;
        8) export_report; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "\n  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
