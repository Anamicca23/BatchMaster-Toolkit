#!/usr/bin/env bash
# ============================================================
# Name      : port_scanner.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW  (read-only scan, no changes made)
# Sudo      : Not Required
# Reversible: Yes
# Desc      : Scans localhost for open TCP/UDP ports using
#             lsof. Uses nmap for full scan if installed.
#             Maps ports to owning processes. Includes common
#             port reference table.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           PORT SCANNER  v1.0.0                       ║"
    echo "  ║     See what services are listening on your Mac      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Show All Listening Ports  (lsof)"
    echo -e "  ${BOLD}[2]${NC}  Show TCP Listening Ports Only"
    echo -e "  ${BOLD}[3]${NC}  Show UDP Listening Ports Only"
    echo -e "  ${BOLD}[4]${NC}  Show Established Connections"
    echo -e "  ${BOLD}[5]${NC}  Check a Specific Port"
    echo -e "  ${BOLD}[6]${NC}  Scan by Process Name"
    if command -v nmap &>/dev/null; then
        echo -e "  ${BOLD}[7]${NC}  nmap Full Scan  (installed)"
    else
        echo -e "  ${BOLD}[7]${NC}  nmap Full Scan  ${YELLOW}(brew install nmap)${NC}"
    fi
    echo -e "  ${BOLD}[8]${NC}  Common Ports Reference"
    echo -e "  ${BOLD}[9]${NC}  Export Port Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

port_lookup() {
    local p="$1"
    case "$p" in
        20|21)  echo "FTP";;       22)   echo "SSH";;
        23)     echo "Telnet";;    25)   echo "SMTP";;
        53)     echo "DNS";;       67|68) echo "DHCP";;
        80)     echo "HTTP";;      110)  echo "POP3";;
        143)    echo "IMAP";;      443)  echo "HTTPS";;
        445)    echo "SMB";;       3306) echo "MySQL";;
        3389)   echo "RDP";;       5432) echo "PostgreSQL";;
        5900)   echo "VNC";;       6379) echo "Redis";;
        8080)   echo "HTTP-alt";;  8443) echo "HTTPS-alt";;
        27017)  echo "MongoDB";;   *)    echo "-";;
    esac
}

show_all_ports() {
    clear
    echo -e "${BOLD}${CYAN}  ALL LISTENING PORTS${NC}"
    echo -e "  ${DASH}"
    printf "  %-8s %-22s %-10s %-20s %s\n" "Proto" "Address:Port" "Port#" "Process (PID)" "Service"
    echo -e "  ${DASH}"
    lsof -nP -iTCP -iUDP -sTCP:LISTEN 2>/dev/null | awk 'NR>1' | \
        while read -r cmd pid _user _fd proto _dev _sz _node name _rest; do
            local port; port=$(echo "$name" | awk -F: '{print $NF}')
            local svc;  svc=$(port_lookup "$port")
            printf "  %-8s %-22s %-10s %-20s %s\n" \
                "$proto" "$name" "$port" "${cmd}(${pid})" "$svc"
        done | sort -k3 -n
    echo
}

show_tcp() {
    clear
    echo -e "${BOLD}${CYAN}  TCP LISTENING PORTS${NC}"
    echo -e "  ${DASH}"
    printf "  %-22s %-8s %-20s %s\n" "Address:Port" "Port" "Process (PID)" "Service"
    echo -e "  ${DASH}"
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1{
        n=split($9,a,":");port=a[length(a)]
        printf "  %-22s %-8s %-20s\n",$9,port,$1"("$2")"
    }' | sort -k2 -n
    echo
}

show_udp() {
    clear
    echo -e "${BOLD}${CYAN}  UDP PORTS${NC}"
    echo -e "  ${DASH}"
    lsof -nP -iUDP 2>/dev/null | awk 'NR>1' | \
        awk '{printf "  %-22s %-20s\n", $9, $1"("$2")"}' | sort -u | head -40
    echo
}

show_established() {
    clear
    echo -e "${BOLD}${CYAN}  ESTABLISHED TCP CONNECTIONS${NC}"
    echo -e "  ${DASH}"
    printf "  %-22s %-22s %-20s\n" "Local" "Remote" "Process (PID)"
    echo -e "  ${DASH}"
    lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR>1{
        printf "  %-22s %-22s %-20s\n",$8,$9,$1"("$2")"
    }' | head -40
    echo
}

check_port() {
    echo
    printf "  Enter port number to check: "
    read -r pnum
    [[ ! "$pnum" =~ ^[0-9]+$ ]] && echo -e "  ${RED}Invalid.${NC}" && return
    clear
    echo -e "${BOLD}${CYAN}  PORT $pnum STATUS${NC}"
    echo -e "  ${DASH}\n"
    local result; result=$(lsof -nP -i:"$pnum" 2>/dev/null | awk 'NR>1')
    if [[ -z "$result" ]]; then
        echo -e "  ${GREEN}Port $pnum is not in use.${NC}"
    else
        echo -e "  ${YELLOW}Port $pnum is IN USE:${NC}\n"
        printf "  %-20s %-8s %-20s %s\n" "Command" "PID" "Proto:Address" "State"
        echo -e "  ${DASH}"
        echo "$result" | awk '{printf "  %-20s %-8s %-20s %s\n",$1,$2,$8,$10}'
    fi
    echo
    echo -e "  Known service: $(port_lookup "$pnum")"
    echo
}

scan_by_process() {
    echo
    printf "  Enter process name to find its ports: "
    read -r proc
    [[ -z "$proc" ]] && return
    clear
    echo -e "${BOLD}${CYAN}  PORTS USED BY: $proc${NC}"
    echo -e "  ${DASH}\n"
    local result; result=$(lsof -nP -i -a -c "$proc" 2>/dev/null | awk 'NR>1')
    if [[ -z "$result" ]]; then
        echo -e "  ${YELLOW}No network connections found for '$proc'${NC}"
    else
        echo "$result" | awk '{printf "  %-20s %-8s %-22s %s\n",$1,$2,$9,$10}' | head -30
    fi
    echo
}

nmap_scan() {
    clear
    echo -e "${BOLD}${CYAN}  NMAP SCAN — localhost${NC}"
    echo -e "  ${DASH}\n"
    if ! command -v nmap &>/dev/null; then
        echo -e "  ${YELLOW}[INFO]${NC} nmap is not installed."
        echo -e "  Install with: ${BOLD}brew install nmap${NC}"
        echo
        return
    fi
    echo -e "  Running: nmap -sV -p 1-1024 localhost"
    echo -e "  ${YELLOW}This may take 30-60 seconds...${NC}\n"
    nmap -sV -p 1-1024 localhost 2>/dev/null | sed 's/^/  /'
    echo
}

common_ports_ref() {
    clear
    echo -e "${BOLD}${CYAN}  COMMON PORTS REFERENCE${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-8s %-12s %s\n" "Port" "Proto" "Service"
    echo -e "  ${DASH}"
    while IFS="|" read -r port proto svc; do
        printf "  %-8s %-12s %s\n" "$port" "$proto" "$svc"
    done << 'TABLE'
21|TCP|FTP — File Transfer
22|TCP|SSH — Secure Shell
23|TCP|Telnet (insecure)
25|TCP|SMTP — Email sending
53|TCP/UDP|DNS — Domain Name System
67/68|UDP|DHCP — IP addressing
80|TCP|HTTP — Web traffic
110|TCP|POP3 — Email receive
143|TCP|IMAP — Email
443|TCP|HTTPS — Secure web
445|TCP|SMB — File sharing
3306|TCP|MySQL database
3389|TCP|RDP — Remote Desktop
5432|TCP|PostgreSQL database
5900|TCP|VNC — Remote desktop
8080|TCP|HTTP alternate / dev
8443|TCP|HTTPS alternate
27017|TCP|MongoDB
TABLE
    echo
    echo -e "  Ports < 1024  = Privileged (system) ports"
    echo -e "  1024-49151    = Registered application ports"
    echo -e "  49152-65535   = Dynamic / ephemeral ports"
    echo
}

export_report() {
    local rpt="$HOME/Desktop/PortScan_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  PORT SCAN REPORT — $(hostname)"
        echo "  Generated: $(date)"
        echo "========================================================"
        echo
        echo "[LISTENING PORTS (lsof)]"
        lsof -nP -iTCP -iUDP -sTCP:LISTEN 2>/dev/null
        echo
        echo "[ESTABLISHED CONNECTIONS]"
        lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null
        echo
        if command -v nmap &>/dev/null; then
            echo "[NMAP SCAN]"
            nmap -sV -p 1-1024 localhost 2>/dev/null
        fi
        echo
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved to Desktop: $(basename "$rpt")"
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) show_all_ports;     read -rp "  Press Enter..." ;;
        2) show_tcp;           read -rp "  Press Enter..." ;;
        3) show_udp;           read -rp "  Press Enter..." ;;
        4) show_established;   read -rp "  Press Enter..." ;;
        5) check_port;         read -rp "  Press Enter..." ;;
        6) scan_by_process;    read -rp "  Press Enter..." ;;
        7) nmap_scan;          read -rp "  Press Enter..." ;;
        8) common_ports_ref;   read -rp "  Press Enter..." ;;
        9) export_report;      read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
