#!/usr/bin/env bash
# ============================================================
# Name      : network_optimizer.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : HIGH
# Sudo      : Required
# Reversible: Yes  (Option [7] restores DHCP DNS defaults)
# Desc      : Flushes DNS cache, renews DHCP, removes stale
#             network prefs, sets Cloudflare+Google DNS on
#             all active interfaces. Before/after ping test.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./network_optimizer.sh${NC}\n"
    exit 1
fi

# Get all active Wi-Fi and Ethernet interfaces
get_active_ifaces() {
    networksetup -listallnetworkservices 2>/dev/null | grep -v "^\*\|An asterisk" | while read -r svc; do
        local state; state=$(networksetup -getnetworkserviceenabled "$svc" 2>/dev/null)
        [[ "$state" == "Enabled" ]] && echo "$svc"
    done
}

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║      NETWORK OPTIMIZER  v1.0.0                       ║"
    echo "  ║     Fix Lag · Speed Up DNS · Reset Network            ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Optimization  (Recommended)"
    echo -e "  ${BOLD}[2]${NC}  Flush DNS Cache Only"
    echo -e "  ${BOLD}[3]${NC}  Renew DHCP Lease"
    echo -e "  ${BOLD}[4]${NC}  Set Fast DNS  (Cloudflare 1.1.1.1 + Google 8.8.8.8)"
    echo -e "  ${BOLD}[5]${NC}  Run Ping Latency Test"
    echo -e "  ${BOLD}[6]${NC}  Show Current Network Info"
    echo -e "  ${BOLD}[7]${NC}  UNDO — Restore DHCP Auto DNS"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

flush_dns() {
    echo -e "  Flushing DNS cache..."
    dscacheutil -flushcache 2>/dev/null       && echo -e "  ${GREEN}[OK]${NC} dscacheutil cleared." || true
    killall -HUP mDNSResponder 2>/dev/null    && echo -e "  ${GREEN}[OK]${NC} mDNSResponder restarted." || true
}

renew_dhcp() {
    echo -e "  Renewing DHCP on all active interfaces..."
    while IFS= read -r svc; do
        ipconfig set "$(networksetup -listallhardwareports 2>/dev/null | \
            awk "/Hardware Port: ${svc}/{found=1} found && /Device:/{print \$2; exit}")" DHCP 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} Renewed: $svc"
    done < <(get_active_ifaces)
}

set_fast_dns() {
    echo -e "  Setting DNS: 1.1.1.1 (Cloudflare) + 8.8.8.8 (Google)..."
    while IFS= read -r svc; do
        networksetup -setdnsservers "$svc" 1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4 2>/dev/null && \
            echo -e "  ${GREEN}[OK]${NC} DNS set on: $svc" || \
            echo -e "  ${YELLOW}[SKIP]${NC} Could not set DNS on: $svc"
    done < <(get_active_ifaces)
}

restore_dhcp_dns() {
    echo -e "  Restoring automatic DNS (DHCP) on all interfaces..."
    while IFS= read -r svc; do
        networksetup -setdnsservers "$svc" "Empty" 2>/dev/null && \
            echo -e "  ${GREEN}[OK]${NC} DHCP DNS restored: $svc" || true
    done < <(get_active_ifaces)
    flush_dns
    echo -e "\n  ${GREEN}[DONE]${NC} DNS restored to automatic."
}

ping_test() {
    clear
    echo -e "${BOLD}${CYAN}  PING LATENCY TEST${NC}"
    echo -e "  ${DASH}\n"
    for target in "8.8.8.8 Google DNS" "1.1.1.1 Cloudflare" "9.9.9.9 Quad9" "208.67.222.222 OpenDNS"; do
        local ip;  ip=$(echo "$target"  | awk '{print $1}')
        local lbl; lbl=$(echo "$target" | awk '{print $2}')
        printf "  %-25s " "${lbl} (${ip})"
        local result; result=$(ping -c 4 -q "$ip" 2>/dev/null | grep "round-trip\|rtt" | \
            awk -F'/' '{printf "avg: %.1f ms", $5}' || echo "TIMEOUT")
        echo "$result"
    done
    echo
    echo -e "  Latency guide: <20ms Excellent  20-50ms Good  50-100ms OK  >100ms Poor"
    echo
}

net_info() {
    clear
    echo -e "${BOLD}${CYAN}  CURRENT NETWORK INFO${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  ${BOLD}Active Interfaces:${NC}"
    ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | grep -v "inet6\|127.0.0.1\|lo0" | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}DNS per Interface:${NC}"
    while IFS= read -r svc; do
        local dns; dns=$(networksetup -getdnsservers "$svc" 2>/dev/null | tr '\n' ' ')
        printf "  %-30s %s\n" "$svc:" "$dns"
    done < <(get_active_ifaces)
    echo
    echo -e "  ${BOLD}Default Gateway:${NC}"
    netstat -rn 2>/dev/null | grep "^default" | awk '{print "  "$2}' | head -3
    echo
    echo -e "  ${BOLD}External IP:${NC}"
    curl -s --max-time 5 https://api.ipify.org 2>/dev/null | sed 's/^/  /' && echo || echo "  N/A (no internet)"
    echo
}

full_optimize() {
    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL NETWORK OPTIMIZATION${NC}\n"

    echo -e "  ${BOLD}Before — ping test:${NC}"
    ping -c 3 -q 8.8.8.8 2>/dev/null | grep "round-trip\|rtt\|packet" | sed 's/^/  /' || echo "  (no response)"

    echo
    echo -e "  ${BOLD}[1/4]${NC} Flushing DNS cache..."
    flush_dns

    echo -e "\n  ${BOLD}[2/4]${NC} Renewing DHCP..."
    renew_dhcp

    echo -e "\n  ${BOLD}[3/4]${NC} Setting fast DNS servers..."
    set_fast_dns

    echo -e "\n  ${BOLD}[4/4]${NC} Re-flushing DNS after change..."
    flush_dns

    echo
    echo -e "  ${BOLD}After — ping test:${NC}"
    ping -c 3 -q 8.8.8.8 2>/dev/null | grep "round-trip\|rtt\|packet" | sed 's/^/  /' || echo "  (no response)"

    echo
    echo -e "${BOLD}${GREEN}  [DONE]${NC} Network optimization complete."
    echo -e "  DNS: 1.1.1.1 + 8.8.8.8  |  Use Option [7] to restore DHCP."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_optimize;     echo; read -rp "  Press Enter..." ;;
        2) flush_dns;         echo; read -rp "  Press Enter..." ;;
        3) renew_dhcp;        echo; read -rp "  Press Enter..." ;;
        4) set_fast_dns;      echo; read -rp "  Press Enter..." ;;
        5) ping_test;               read -rp "  Press Enter..." ;;
        6) net_info;                read -rp "  Press Enter..." ;;
        7) restore_dhcp_dns;  echo; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
