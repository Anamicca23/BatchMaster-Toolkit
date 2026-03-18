#!/usr/bin/env bash
# ============================================================
# Name      : hardware_report.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW
# Sudo      : Required  (dmidecode needs root)
# Reversible: Yes  (read-only, no changes made)
# Desc      : Full hardware inventory using dmidecode, lshw,
#             and inxi (if available). Saves timestamped report
#             to ~/Desktop/hardware_report_YYYYMMDD.txt.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./hardware_report.sh${NC}\n"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
REAL_HOME=$(eval echo "~$REAL_USER")

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         HARDWARE REPORT  v1.0.0                      ║"
    echo "  ║     dmidecode · lshw · inxi — full inventory          ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Hardware Report  (all sections)"
    echo -e "  ${BOLD}[2]${NC}  System / Motherboard Info"
    echo -e "  ${BOLD}[3]${NC}  BIOS / Firmware Info"
    echo -e "  ${BOLD}[4]${NC}  CPU Details"
    echo -e "  ${BOLD}[5]${NC}  Memory Slots (DIMM info)"
    echo -e "  ${BOLD}[6]${NC}  PCI Devices"
    echo -e "  ${BOLD}[7]${NC}  USB Devices"
    echo -e "  ${BOLD}[8]${NC}  Storage Devices"
    echo -e "  ${BOLD}[9]${NC}  inxi Full Report  (if installed)"
    echo -e "  ${BOLD}[E]${NC}  Export Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_dep() {
    local cmd="$1" pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "  ${YELLOW}[INFO]${NC} $cmd not found. Install: ${BOLD}apt install $pkg${NC}"
        return 1
    fi
    return 0
}

auto_install() {
    local pkg="$1"
    printf "  Install $pkg now? (y/N): "
    read -r ans
    if [[ "${ans,,}" == "y" ]]; then
        apt-get install -y "$pkg" 2>&1 | tail -3 | sed 's/^/  /'
        return $?
    fi
    return 1
}

section() {
    echo -e "\n${BOLD}${CYAN}  ══ $1 ══${NC}"
    echo -e "  ${DASH}"
}

get_system() {
    section "SYSTEM / MOTHERBOARD"
    dmidecode -t 1 2>/dev/null | grep -v "^#" | sed 's/^/  /'
    echo
    dmidecode -t 2 2>/dev/null | grep -v "^#" | sed 's/^/  /'
}

get_bios() {
    section "BIOS / FIRMWARE"
    dmidecode -t 0 2>/dev/null | grep -v "^#" | sed 's/^/  /'
}

get_cpu_detail() {
    section "PROCESSOR"
    dmidecode -t 4 2>/dev/null | grep -v "^#" | \
        grep -E "Socket|Family|Manufacturer|Version|Voltage|Speed|Core|Thread|Serial" | \
        sed 's/^/  /'
    echo
    lscpu 2>/dev/null | sed 's/^/  /'
}

get_memory() {
    section "MEMORY SLOTS"
    dmidecode -t 17 2>/dev/null | grep -v "^#" | \
        grep -E "^Memory|Size|Form Factor|Type:|Speed|Manufacturer|Serial|Locator|Bank" | \
        sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Current usage:${NC}"
    free -h | sed 's/^/  /'
}

get_pci() {
    section "PCI DEVICES"
    if check_dep lspci pciutils; then
        lspci -v 2>/dev/null | sed 's/^/  /' | head -80
    fi
}

get_usb() {
    section "USB DEVICES"
    if check_dep lsusb usbutils; then
        lsusb -v 2>/dev/null | grep -E "^Bus|iProduct|iManufacturer|idProduct|idVendor" | \
            sed 's/^/  /' | head -60
    else
        lsusb 2>/dev/null | sed 's/^/  /'
    fi
}

get_storage() {
    section "STORAGE DEVICES"
    echo -e "  ${BOLD}Block devices:${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>/dev/null | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Disk details (dmidecode):${NC}"
    dmidecode -t 10 2>/dev/null | grep -v "^#" | sed 's/^/  /' | head -20
    echo
    if command -v smartctl &>/dev/null; then
        echo -e "  ${BOLD}SMART status per disk:${NC}"
        lsblk -d -o NAME 2>/dev/null | grep -v "NAME" | while read -r dev; do
            echo -e "  ${BOLD}/dev/$dev${NC}"
            smartctl -H "/dev/$dev" 2>/dev/null | grep "SMART overall\|result" | sed 's/^/    /'
        done
    else
        echo -e "  ${YELLOW}Install smartmontools for SMART data:${NC} apt install smartmontools"
    fi
}

get_inxi() {
    section "INXI FULL REPORT"
    if ! command -v inxi &>/dev/null; then
        echo -e "  ${YELLOW}inxi not installed.${NC}"
        auto_install inxi && inxi -Fxxxz 2>/dev/null | sed 's/^/  /' || \
            echo -e "  Install manually: ${BOLD}apt install inxi${NC}"
        return
    fi
    inxi -Fxxxz 2>/dev/null | sed 's/^/  /'
}

full_report() {
    clear
    echo -e "${BOLD}${CYAN}  FULL HARDWARE REPORT — $(hostname)${NC}"
    echo -e "  ${DASH}"
    get_system
    get_bios
    get_cpu_detail
    get_memory
    get_pci
    get_usb
    get_storage
    echo
}

export_report() {
    mkdir -p "$REAL_HOME/Desktop" 2>/dev/null
    local rpt="$REAL_HOME/Desktop/HardwareReport_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "\n  Generating full hardware report..."
    {
        echo "========================================================"
        echo "  HARDWARE REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo; echo "[SYSTEM]";  dmidecode -t 1,2 2>/dev/null
        echo; echo "[BIOS]";    dmidecode -t 0 2>/dev/null
        echo; echo "[CPU]";     dmidecode -t 4 2>/dev/null; lscpu
        echo; echo "[MEMORY]";  dmidecode -t 17 2>/dev/null; free -h
        echo; echo "[PCI]";     lspci -v 2>/dev/null
        echo; echo "[USB]";     lsusb 2>/dev/null
        echo; echo "[STORAGE]"; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL; dmidecode -t 10 2>/dev/null
        command -v inxi &>/dev/null && { echo; echo "[INXI]"; inxi -Fxxxz 2>/dev/null; }
        echo
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    chown "$REAL_USER":"$REAL_USER" "$rpt" 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC} Report saved: $rpt"
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_report;      read -rp "  Press Enter..." ;;
        2) clear; get_system;      echo; read -rp "  Press Enter..." ;;
        3) clear; get_bios;        echo; read -rp "  Press Enter..." ;;
        4) clear; get_cpu_detail;  echo; read -rp "  Press Enter..." ;;
        5) clear; get_memory;      echo; read -rp "  Press Enter..." ;;
        6) clear; get_pci;         echo; read -rp "  Press Enter..." ;;
        7) clear; get_usb;         echo; read -rp "  Press Enter..." ;;
        8) clear; get_storage;     echo; read -rp "  Press Enter..." ;;
        9) clear; get_inxi;        echo; read -rp "  Press Enter..." ;;
        e|E) export_report;        read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
