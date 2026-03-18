#!/usr/bin/env bash
# ============================================================
# Name      : system_info.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (read-only, no changes made)
# Desc      : Full system dashboard — OS, CPU, RAM, Disk,
#             GPU, Network, and Uptime using lscpu, free,
#             df, lsblk, lspci, ip, and hostnamectl.
# ============================================================

set -uo pipefail

RED='\033[0;31m';   YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m';  BLUE='\033[0;34m';   BOLD='\033[1m'
MAGENTA='\033[0;35m'; NC='\033[0m'

SEP="════════════════════════════════════════════════════════"
DASH="────────────────────────────────────────────────────────"

header() { echo -e "\n${BOLD}${CYAN}  ══ $1 ══${NC}"; echo -e "  ${DASH}"; }
row()    { printf "  ${BOLD}%-24s${NC} %s\n" "$1" "$2"; }

show_menu() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       LINUX SYSTEM INFO DASHBOARD  v1.0.0            ║"
    echo "  ║     Full hardware and OS analytics report            ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full System Dashboard"
    echo -e "  ${BOLD}[2]${NC}  OS and Kernel Info"
    echo -e "  ${BOLD}[3]${NC}  CPU Details"
    echo -e "  ${BOLD}[4]${NC}  Memory / RAM"
    echo -e "  ${BOLD}[5]${NC}  Disk Usage"
    echo -e "  ${BOLD}[6]${NC}  GPU Info"
    echo -e "  ${BOLD}[7]${NC}  Network Interfaces"
    echo -e "  ${BOLD}[8]${NC}  Running Processes  (top 10 by CPU)"
    echo -e "  ${BOLD}[9]${NC}  Export Full Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

get_os() {
    header "OPERATING SYSTEM"
    local os_name kernel arch hostname uptime_str
    os_name=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)
    kernel=$(uname -r)
    arch=$(uname -m)
    hostname=$(hostname 2>/dev/null)
    uptime_str=$(uptime -p 2>/dev/null || uptime)

    row "OS:"          "$os_name"
    row "Kernel:"      "$kernel ($arch)"
    row "Hostname:"    "$hostname"
    row "Uptime:"      "$uptime_str"
    row "User:"        "$(whoami)"
    row "Shell:"       "$SHELL"

    if command -v hostnamectl &>/dev/null; then
        echo
        echo -e "  ${BOLD}hostnamectl:${NC}"
        hostnamectl 2>/dev/null | sed 's/^/    /'
    fi
}

get_cpu() {
    header "PROCESSOR"
    local model cores threads freq load
    model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | sed 's/^ //')
    cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "N/A")
    threads=$(lscpu 2>/dev/null | grep "^Thread(s) per core" | awk '{print $NF}')
    freq=$(lscpu 2>/dev/null | grep "^CPU MHz" | awk '{print $NF}')
    load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1,$2,$3}')

    row "Model:"       "${model:-N/A}"
    row "Cores:"       "$cores"
    row "Threads/Core:" "${threads:-N/A}"
    row "Frequency:"   "${freq:-N/A} MHz"
    row "Load Avg:"    "$load  (1m 5m 15m)"
    echo
    echo -e "  ${BOLD}lscpu summary:${NC}"
    lscpu 2>/dev/null | grep -E "^Architecture|^CPU\(s\)|^Thread|^Core|^Socket|^Vendor|^Model name|^CPU MHz|^CPU max" | sed 's/^/    /'
}

get_ram() {
    header "MEMORY  (RAM)"
    free -h 2>/dev/null | sed 's/^/  /'
    echo
    local total_kb; total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    local free_kb;  free_kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [[ -n "$total_kb" && "$total_kb" -gt 0 ]]; then
        local pct=$(( (total_kb - free_kb) * 100 / total_kb ))
        local bar_len=30 filled=$(( pct * bar_len / 100 ))
        local bar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $filled ]] && bar+="#" || bar+="."; done
        echo -e "  Usage: [${GREEN}${bar}${NC}] ${pct}%"
    fi
    echo
    echo -e "  ${BOLD}Memory modules (dmidecode, requires sudo):${NC}"
    if [[ $EUID -eq 0 ]]; then
        dmidecode -t 17 2>/dev/null | grep -E "Size:|Speed:|Manufacturer:|Type:" | sed 's/^/    /' | head -20
    else
        echo -e "    ${YELLOW}Run with sudo for memory module details.${NC}"
    fi
}

get_disk() {
    header "DISK USAGE"
    echo -e "  ${BOLD}Volume Usage:${NC}"
    printf "  %-38s %6s %6s %6s %5s\n" "Filesystem" "Size" "Used" "Avail" "Use%"
    echo -e "  ${DASH}"
    df -h 2>/dev/null | awk 'NR>1 && !/tmpfs|devtmpfs|udev|overlay/{
        printf "  %-38s %6s %6s %6s %5s\n",$1,$2,$3,$4,$5
    }' | head -15
    echo
    echo -e "  ${BOLD}Block Devices (lsblk):${NC}"
    lsblk 2>/dev/null | sed 's/^/  /'
}

get_gpu() {
    header "GPU"
    if command -v lspci &>/dev/null; then
        echo -e "  ${BOLD}PCI GPU devices:${NC}"
        lspci 2>/dev/null | grep -iE "VGA|3D|Display|GPU" | sed 's/^/  /'
    fi
    echo
    if command -v nvidia-smi &>/dev/null; then
        echo -e "  ${BOLD}NVIDIA GPU (nvidia-smi):${NC}"
        nvidia-smi --query-gpu=name,memory.total,temperature.gpu,utilization.gpu \
            --format=csv,noheader 2>/dev/null | sed 's/^/  /'
    fi
    if [[ -d /sys/class/drm ]]; then
        echo -e "  ${BOLD}DRM devices:${NC}"
        ls /sys/class/drm/ 2>/dev/null | grep "^card" | sed 's/^/    /'
    fi
}

get_network() {
    header "NETWORK INTERFACES"
    echo -e "  ${BOLD}Active interfaces:${NC}"
    ip -br addr show 2>/dev/null | sed 's/^/  /' || ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Default Gateway:${NC}"
    ip route 2>/dev/null | grep "^default" | sed 's/^/  /' || route -n 2>/dev/null | grep "^0.0.0.0" | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}DNS Servers:${NC}"
    grep "nameserver" /etc/resolv.conf 2>/dev/null | sed 's/^/  /'
    if command -v resolvectl &>/dev/null; then
        resolvectl status 2>/dev/null | grep "DNS Servers" | head -3 | sed 's/^/  /'
    fi
}

get_top_procs() {
    header "TOP 10 PROCESSES  (by CPU)"
    ps aux 2>/dev/null | sort -k3 -rn | awk 'NR==1 || NR<=11' | \
        awk '{printf "  %-20s %6s%% %6s%%   %s\n", $1, $3, $4, $11}' | head -12
}

full_dashboard() {
    clear
    echo -e "${BOLD}${BLUE}  ${SEP}"
    echo -e "  LINUX SYSTEM DASHBOARD  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  ${SEP}${NC}"
    get_os
    get_cpu
    get_ram
    get_disk
    get_gpu
    get_network
    echo
    echo -e "${BOLD}${BLUE}  ${SEP}${NC}"
}

export_report() {
    local rpt="$HOME/Desktop/LinuxSystemReport_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$HOME/Desktop" 2>/dev/null
    {
        echo "========================================================"
        echo "  LINUX SYSTEM INFO REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo; echo "[OS]";       cat /etc/os-release 2>/dev/null; uname -a
        echo; echo "[CPU]";      lscpu 2>/dev/null
        echo; echo "[MEMORY]";   free -h; cat /proc/meminfo 2>/dev/null
        echo; echo "[DISK]";     df -h; lsblk
        echo; echo "[GPU]";      lspci 2>/dev/null | grep -iE "VGA|3D|Display"
        echo; echo "[NETWORK]";  ip -br addr show 2>/dev/null; ip route 2>/dev/null
        echo; echo "[PROCESSES]"; ps aux --sort=-%cpu 2>/dev/null | head -20
        echo
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved: $rpt"
}

while true; do
    show_menu
    case "$choice" in
        1) full_dashboard;  echo; read -rp "  Press Enter..." ;;
        2) clear; get_os;         echo; read -rp "  Press Enter..." ;;
        3) clear; get_cpu;        echo; read -rp "  Press Enter..." ;;
        4) clear; get_ram;        echo; read -rp "  Press Enter..." ;;
        5) clear; get_disk;       echo; read -rp "  Press Enter..." ;;
        6) clear; get_gpu;        echo; read -rp "  Press Enter..." ;;
        7) clear; get_network;    echo; read -rp "  Press Enter..." ;;
        8) clear; get_top_procs;  echo; read -rp "  Press Enter..." ;;
        9) export_report;         read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
