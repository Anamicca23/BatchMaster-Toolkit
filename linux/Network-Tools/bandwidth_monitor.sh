#!/usr/bin/env bash
# ============================================================
# Name      : bandwidth_monitor.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW  (read-only monitoring)
# Sudo      : Required  (nethogs needs root)
# Reversible: Yes
# Desc      : Real-time bandwidth monitor. Uses nethogs,
#             iftop, or vnstat in preference order. Falls back
#             to /proc/net/dev polling if none are installed.
#             Offers to install nethogs if missing.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./bandwidth_monitor.sh${NC}\n"
    exit 1
fi

get_active_iface() {
    ip route 2>/dev/null | grep "^default" | awk '{print $5}' | head -1
}

show_menu() {
    local iface; iface=$(get_active_iface)
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         BANDWIDTH MONITOR  v1.0.0                    ║"
    echo "  ║     nethogs · iftop · vnstat · /proc/net/dev         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Active interface: ${BOLD}${iface:-none}${NC}"
    echo
    echo -e "  ${BOLD}[1]${NC}  Live Monitor  (auto-selects best available tool)"
    echo -e "  ${BOLD}[2]${NC}  nethogs  (per-process bandwidth)"
    echo -e "  ${BOLD}[3]${NC}  iftop  (per-connection bandwidth)"
    echo -e "  ${BOLD}[4]${NC}  vnstat  (historical daily/monthly stats)"
    echo -e "  ${BOLD}[5]${NC}  /proc/net/dev Poll  (built-in, no extra tools)"
    echo -e "  ${BOLD}[6]${NC}  Interface Statistics  (rx/tx totals since boot)"
    echo -e "  ${BOLD}[7]${NC}  Install nethogs"
    echo -e "  ${BOLD}[8]${NC}  Install vnstat + start service"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

human_bytes() {
    local bytes="$1"
    if   [[ $bytes -ge 1073741824 ]]; then printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc 2>/dev/null || echo 0)"
    elif [[ $bytes -ge 1048576    ]]; then printf "%.2f MB" "$(echo "scale=2; $bytes/1048576"    | bc 2>/dev/null || echo 0)"
    elif [[ $bytes -ge 1024       ]]; then printf "%.2f KB" "$(echo "scale=2; $bytes/1024"       | bc 2>/dev/null || echo 0)"
    else printf "%d B" "$bytes"; fi
}

# ── /proc/net/dev polling ─────────────────────────────────────────────
proc_monitor() {
    local iface="${1:-$(get_active_iface)}"
    [[ -z "$iface" ]] && echo -e "  ${RED}No interface detected.${NC}" && return

    echo -e "\n  ${CYAN}Polling /proc/net/dev every 1 second on ${iface}${NC}"
    echo -e "  Press CTRL+C to stop.\n"
    echo -e "  ${DASH}"
    printf "  %-12s  %-15s  %-15s  %-15s  %-15s\n" "Time" "RX/s" "TX/s" "RX Total" "TX Total"
    echo -e "  ${DASH}"

    trap 'echo -e "\n\n  ${GREEN}Monitor stopped.${NC}\n"; return' INT

    local prev_rx=0 prev_tx=0
    while true; do
        local rx tx
        rx=$(grep "^\s*${iface}:" /proc/net/dev 2>/dev/null | awk '{print $2}' || echo 0)
        tx=$(grep "^\s*${iface}:" /proc/net/dev 2>/dev/null | awk '{print $10}' || echo 0)

        if [[ $prev_rx -gt 0 ]]; then
            local drx=$(( rx - prev_rx ))
            local dtx=$(( tx - prev_tx ))
            [[ $drx -lt 0 ]] && drx=0
            [[ $dtx -lt 0 ]] && dtx=0
            printf "  %-12s  %-15s  %-15s  %-15s  %-15s\n" \
                "$(date '+%H:%M:%S')" \
                "$(human_bytes $drx)/s" \
                "$(human_bytes $dtx)/s" \
                "$(human_bytes $rx)" \
                "$(human_bytes $tx)"
        fi
        prev_rx=$rx
        prev_tx=$tx
        sleep 1
    done
    trap - INT
}

iface_stats() {
    clear
    echo -e "${BOLD}${CYAN}  INTERFACE STATISTICS  (since boot)${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-15s  %-15s  %-15s  %-15s  %s\n" "Interface" "RX Total" "TX Total" "RX Packets" "TX Packets"
    echo -e "  ${DASH}"
    while IFS= read -r line; do
        [[ "$line" =~ ^\s*([a-z][^:]+):\s*([0-9]+)\s+([0-9]+)\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+([0-9]+)\s+([0-9]+) ]] || continue
        local iface="${BASH_REMATCH[1]}"
        local rx_bytes="${BASH_REMATCH[2]}"
        local rx_pkts="${BASH_REMATCH[3]}"
        local tx_bytes="${BASH_REMATCH[4]}"
        local tx_pkts="${BASH_REMATCH[5]}"
        printf "  %-15s  %-15s  %-15s  %-15s  %s\n" \
            "$iface" \
            "$(human_bytes "$rx_bytes")" \
            "$(human_bytes "$tx_bytes")" \
            "$rx_pkts" \
            "$tx_pkts"
    done < /proc/net/dev
    echo
}

auto_monitor() {
    if command -v nethogs &>/dev/null; then
        echo -e "\n  ${GREEN}Using nethogs (per-process)${NC}"
        sleep 1
        nethogs "$(get_active_iface)" 2>/dev/null
    elif command -v iftop &>/dev/null; then
        echo -e "\n  ${GREEN}Using iftop (per-connection)${NC}"
        sleep 1
        iftop -i "$(get_active_iface)" 2>/dev/null
    elif command -v vnstat &>/dev/null; then
        echo -e "\n  ${GREEN}Using vnstat (historical stats)${NC}"
        sleep 1
        vnstat 2>/dev/null | sed 's/^/  /'
        echo; read -rp "  Press Enter..."
    else
        echo -e "\n  ${YELLOW}No advanced tool found. Using /proc/net/dev polling.${NC}"
        sleep 1
        proc_monitor
    fi
}

install_nethogs() {
    echo
    apt-get install -y nethogs 2>&1 | tail -5 | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC} nethogs installed. Run option [2] to use it."
    echo
}

install_vnstat() {
    echo
    apt-get install -y vnstat 2>&1 | tail -5 | sed 's/^/  /'
    systemctl enable vnstat 2>/dev/null; systemctl start vnstat 2>/dev/null
    echo -e "  ${GREEN}[OK]${NC} vnstat installed and started."
    echo -e "  ${CYAN}Note:${NC} vnstat needs a few hours to accumulate traffic data."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) auto_monitor ;;
        2)
            if command -v nethogs &>/dev/null; then
                nethogs "$(get_active_iface)" 2>/dev/null
            else
                echo -e "\n  ${YELLOW}nethogs not installed.${NC} Install with option [7]."
                read -rp "  Press Enter..."
            fi ;;
        3)
            if command -v iftop &>/dev/null; then
                iftop -i "$(get_active_iface)" 2>/dev/null
            else
                echo -e "\n  ${YELLOW}iftop not installed.${NC} Install: apt install iftop"
                read -rp "  Press Enter..."
            fi ;;
        4)
            if command -v vnstat &>/dev/null; then
                clear; vnstat 2>/dev/null | sed 's/^/  /'; echo; read -rp "  Press Enter..."
            else
                echo -e "\n  ${YELLOW}vnstat not installed.${NC} Install with option [8]."
                read -rp "  Press Enter..."
            fi ;;
        5) proc_monitor ;;
        6) iface_stats;   read -rp "  Press Enter..." ;;
        7) install_nethogs; read -rp "  Press Enter..." ;;
        8) install_vnstat;  read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
