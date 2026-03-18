#!/usr/bin/env bash
# ============================================================
# Name      : wifi_passwords.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (read-only, no changes made)
# Desc      : Lists all saved WiFi SSIDs and retrieves stored
#             passwords from the macOS Keychain. Each lookup
#             triggers a system authentication prompt.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

# Detect Wi-Fi interface
WIFI_IFACE=$(networksetup -listallhardwareports 2>/dev/null | \
    awk '/Wi-Fi|AirPort/{found=1} found && /Device:/{print $2; exit}')
WIFI_IFACE="${WIFI_IFACE:-en0}"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         WiFi PASSWORD VIEWER  v1.0.0                 ║"
    echo "  ║     Reads saved passwords from macOS Keychain        ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${YELLOW}NOTE:${NC} Each password lookup shows a system auth dialog."
    echo -e "  Enter your Mac login password or use Touch ID to approve.\n"
    echo -e "  ${BOLD}[1]${NC}  Show All Saved WiFi Networks  (names only)"
    echo -e "  ${BOLD}[2]${NC}  Show All Passwords  (one auth prompt per network)"
    echo -e "  ${BOLD}[3]${NC}  Look Up a Specific Network Password"
    echo -e "  ${BOLD}[4]${NC}  Show Current WiFi Connection"
    echo -e "  ${BOLD}[5]${NC}  Show WiFi Signal Strength"
    echo -e "  ${BOLD}[6]${NC}  Export Network List  (no passwords) to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

get_ssid_list() {
    networksetup -listpreferredwirelessnetworks "$WIFI_IFACE" 2>/dev/null | \
        grep -v "Preferred Networks\|An error" | sed 's/^[[:space:]]*//'
}

get_password() {
    local ssid="$1"
    security find-generic-password \
        -D "AirPort network password" \
        -a "$ssid" \
        -w 2>/dev/null || echo "(no password stored or access denied)"
}

show_networks_only() {
    clear
    echo -e "${BOLD}${CYAN}  SAVED WiFi NETWORKS${NC}"
    echo -e "  ${DASH}\n"
    local count=0
    while IFS= read -r ssid; do
        [[ -z "$ssid" ]] && continue
        count=$(( count + 1 ))
        printf "  %3d.  %s\n" "$count" "$ssid"
    done < <(get_ssid_list)
    echo
    [[ $count -eq 0 ]] && echo -e "  ${YELLOW}No saved networks found.${NC}"
    echo -e "  Total: ${BOLD}${count}${NC} saved network(s)"
    echo
}

show_all_passwords() {
    clear
    echo -e "${BOLD}${CYAN}  ALL SAVED WiFi PASSWORDS${NC}"
    echo -e "  ${YELLOW}You will be prompted to authenticate for each network.${NC}"
    echo -e "  ${DASH}\n"
    local count=0
    while IFS= read -r ssid; do
        [[ -z "$ssid" ]] && continue
        count=$(( count + 1 ))
        echo -e "  ${BOLD}[$count] ${ssid}${NC}"
        local pw; pw=$(get_password "$ssid")
        printf "  %-20s %s\n" "Password:" "$pw"
        echo
    done < <(get_ssid_list)
    [[ $count -eq 0 ]] && echo -e "  ${YELLOW}No saved networks found.${NC}\n"
    echo -e "  ${RED}SECURITY REMINDER:${NC} Never share WiFi passwords via screenshots or messages."
    echo
}

lookup_one() {
    echo
    printf "  Enter network name (SSID) to look up: "
    read -r target_ssid
    [[ -z "$target_ssid" ]] && echo -e "  ${RED}No name entered.${NC}" && return

    echo
    echo -e "  Looking up: ${BOLD}${target_ssid}${NC}"
    echo -e "  (A system authentication dialog will appear...)"
    echo
    local pw; pw=$(get_password "$target_ssid")
    echo -e "  Network  : $target_ssid"
    echo -e "  Password : $pw"
    echo
}

current_connection() {
    clear
    echo -e "${BOLD}${CYAN}  CURRENT WiFi CONNECTION${NC}"
    echo -e "  ${DASH}\n"
    networksetup -getairportnetwork "$WIFI_IFACE" 2>/dev/null | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Interface Details:${NC}"
    ifconfig "$WIFI_IFACE" 2>/dev/null | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}IP Configuration:${NC}"
    networksetup -getinfo "Wi-Fi" 2>/dev/null | sed 's/^/  /'
    echo
}

signal_strength() {
    clear
    echo -e "${BOLD}${CYAN}  WiFi SIGNAL STRENGTH${NC}"
    echo -e "  ${DASH}\n"
    # airport utility
    local airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    if [[ -x "$airport" ]]; then
        "$airport" -I 2>/dev/null | sed 's/^/  /'
        echo
        echo -e "  ${BOLD}RSSI Guide:${NC}"
        echo "   -30 dBm  Excellent  (very close to router)"
        echo "   -50 dBm  Good       (reliable connection)"
        echo "   -60 dBm  Fair       (usable but slower)"
        echo "   -70 dBm  Weak       (marginal)"
        echo "   -80 dBm  Very Weak  (connection issues likely)"
    else
        echo -e "  ${YELLOW}[INFO]${NC} airport utility not found."
        echo -e "  Try: ${BOLD}system_profiler SPAirPortDataType${NC}"
        system_profiler SPAirPortDataType 2>/dev/null | \
            grep -A5 "Current Network" | sed 's/^/  /'
    fi
    echo
}

export_network_list() {
    local rpt="$HOME/Desktop/WiFi_Networks_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  WiFi SAVED NETWORKS  (NO PASSWORDS — safe to share)"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        networksetup -listpreferredwirelessnetworks "$WIFI_IFACE" 2>/dev/null
        echo
        echo "========================================================"
    } > "$rpt"
    echo -e "\n  ${GREEN}[OK]${NC} Network list saved to Desktop: $(basename "$rpt")"
    echo -e "  ${GREEN}[OK]${NC} Passwords were NOT included in this export."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) show_networks_only;   read -rp "  Press Enter..." ;;
        2) show_all_passwords;   read -rp "  Press Enter..." ;;
        3) lookup_one;           read -rp "  Press Enter..." ;;
        4) current_connection;   read -rp "  Press Enter..." ;;
        5) signal_strength;      read -rp "  Press Enter..." ;;
        6) export_network_list;  read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
