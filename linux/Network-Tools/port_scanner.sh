#!/usr/bin/env bash
# ============================================================
# Name      : port_scanner.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW  (read-only scan, no changes)
# Sudo      : Not Required  (sudo gives more process info)
# Reversible: Yes
# Desc      : Uses ss -tulnp to list all listening ports with
#             owning processes. Optional nmap scan for service
#             version detection. Distinguishes system ports
#             (<1024) from application ports.
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
    echo "  ║     ss · netstat · nmap — see what's listening       ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  All Listening Ports  (TCP + UDP)"
    echo -e "  ${BOLD}[2]${NC}  TCP Listening Ports Only"
    echo -e "  ${BOLD}[3]${NC}  UDP Ports Only"
    echo -e "  ${BOLD}[4]${NC}  Established TCP Connections"
    echo -e "  ${BOLD}[5]${NC}  Check a Specific Port"
    echo -e "  ${BOLD}[6]${NC}  Scan by Process Name"
    if command -v nmap &>/dev/null; then
        echo -e "  ${BOLD}[7]${NC}  nmap Service Scan  (installed)"
    else
        echo -e "  ${BOLD}[7]${NC}  nmap Service Scan  ${YELLOW}(apt install nmap)${NC}"
    fi
    echo -e "  ${BOLD}[8]${NC}  Common Ports Reference"
    echo -e "  ${BOLD}[9]${NC}  Export Port Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

port_lookup() {
    case "$1" in
        21)    echo "FTP";;        22)    echo "SSH";;
        23)    echo "Telnet";;     25)    echo "SMTP";;
        53)    echo "DNS";;        80)    echo "HTTP";;
        110)   echo "POP3";;       143)   echo "IMAP";;
        443)   echo "HTTPS";;      445)   echo "SMB";;
        3306)  echo "MySQL";;      3389)  echo "RDP";;
        5432)  echo "PostgreSQL";; 5900)  echo "VNC";;
        6379)  echo "Redis";;      8080)  echo "HTTP-alt";;
        8443)  echo "HTTPS-alt";;  27017) echo "MongoDB";;
        9200)  echo "Elasticsearch";; 11211) echo "Memcached";;
        *)     echo "-";;
    esac
}

all_ports() {
    clear
    echo -e "${BOLD}${CYAN}  ALL LISTENING PORTS  (TCP + UDP)${NC}"
    echo -e "  ${DASH}"
    printf "  %-6s %-30s %-25s %s\n" "Proto" "Local Address" "Process" "Service"
    echo -e "  ${DASH}"
    ss -tulnp 2>/dev/null | awk 'NR>1{
        proto=$1; addr=$5; proc=$NF
        n=split(addr,a,":"); port=a[n]
        printf "  %-6s %-30s %-25s\n", proto, addr, proc
    }' | while IFS= read -r line; do
        local port; port=$(echo "$line" | awk '{print $2}' | awk -F: '{print $NF}')
        local svc; svc=$(port_lookup "$port" 2>/dev/null || echo "-")
        echo "$line  $svc"
    done | sort -k2 -t: -n
    echo
    echo -e "  ${YELLOW}Tip:${NC} Run with sudo for full process names."
    echo
}

tcp_ports() {
    clear
    echo -e "${BOLD}${CYAN}  TCP LISTENING PORTS${NC}"
    echo -e "  ${DASH}"
    printf "  %-8s %-30s %-25s %s\n" "Port" "Address" "Process" "Service"
    echo -e "  ${DASH}"
    ss -tlnp 2>/dev/null | awk 'NR>1{
        addr=$4; proc=$NF
        n=split(addr,a,":"); port=a[n]
        printf "  %-8s %-30s %s\n", port, addr, proc
    }' | sort -k1 -n | while IFS= read -r line; do
        local port; port=$(echo "$line" | awk '{print $1}')
        local svc; svc=$(port_lookup "$port" 2>/dev/null || echo "-")
        # Color system ports differently
        if [[ "$port" -lt 1024 ]] 2>/dev/null; then
            echo -e "  ${CYAN}${line}${NC}  ${svc}"
        else
            echo "  ${line}  ${svc}"
        fi
    done
    echo
    echo -e "  ${CYAN}Cyan${NC} = privileged system ports (< 1024)"
    echo
}

udp_ports() {
    clear
    echo -e "${BOLD}${CYAN}  UDP PORTS${NC}"
    echo -e "  ${DASH}\n"
    ss -ulnp 2>/dev/null | sed 's/^/  /'
    echo
}

established() {
    clear
    echo -e "${BOLD}${CYAN}  ESTABLISHED TCP CONNECTIONS${NC}"
    echo -e "  ${DASH}"
    printf "  %-30s %-30s %-20s\n" "Local" "Remote" "Process"
    echo -e "  ${DASH}"
    ss -tnp state established 2>/dev/null | awk 'NR>1{
        printf "  %-30s %-30s %s\n", $4, $5, $NF
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
    local result; result=$(ss -tulnp 2>/dev/null | grep ":${pnum}\b")
    if [[ -z "$result" ]]; then
        echo -e "  ${GREEN}Port $pnum is not in use.${NC}"
    else
        echo -e "  ${YELLOW}Port $pnum is IN USE:${NC}\n"
        echo "$result" | sed 's/^/  /'
    fi
    echo
    echo -e "  Known service: $(port_lookup "$pnum")"
    # Try to connect
    if command -v nc &>/dev/null; then
        nc -z -w 1 localhost "$pnum" 2>/dev/null && \
            echo -e "  ${GREEN}Connection test: OPEN${NC}" || \
            echo -e "  ${YELLOW}Connection test: CLOSED or filtered${NC}"
    fi
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
    local result; result=$(ss -tulnp 2>/dev/null | grep -i "$proc")
    if [[ -z "$result" ]]; then
        echo -e "  ${YELLOW}No ports found for '$proc'${NC}"
        echo -e "  Also checking with netstat..."
        netstat -tulnp 2>/dev/null | grep -i "$proc" | sed 's/^/  /' || true
    else
        echo "$result" | sed 's/^/  /'
    fi
    echo
}

nmap_scan() {
    clear
    echo -e "${BOLD}${CYAN}  NMAP SERVICE SCAN — localhost${NC}"
    echo -e "  ${DASH}\n"
    if ! command -v nmap &>/dev/null; then
        echo -e "  ${YELLOW}nmap not installed.${NC}"
        echo -e "  Install: ${BOLD}sudo apt install nmap${NC}"
        echo; return
    fi
    echo -e "  Running: nmap -sV -p 1-1024 localhost"
    echo -e "  ${YELLOW}May take 30-60 seconds...${NC}\n"
    nmap -sV -p 1-1024 localhost 2>/dev/null | sed 's/^/  /'
    echo
}

common_ports_ref() {
    clear
    echo -e "${BOLD}${CYAN}  COMMON PORTS REFERENCE${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-10s %-12s %s\n" "Port" "Protocol" "Service"
    echo -e "  ${DASH}"
    while IFS="|" read -r p pr s; do
        printf "  %-10s %-12s %s\n" "$p" "$pr" "$s"
    done << 'TABLE'
21|TCP|FTP — File Transfer
22|TCP|SSH — Secure Shell
23|TCP|Telnet (avoid — unencrypted)
25|TCP|SMTP — Email sending
53|TCP/UDP|DNS — Name resolution
80|TCP|HTTP — Web traffic
110|TCP|POP3 — Email receive
143|TCP|IMAP — Email
443|TCP|HTTPS — Secure web
445|TCP|SMB — File sharing
3306|TCP|MySQL database
3389|TCP|RDP — Remote Desktop
5432|TCP|PostgreSQL
5900|TCP|VNC — Remote desktop
6379|TCP|Redis cache
8080|TCP|HTTP alternate / app servers
8443|TCP|HTTPS alternate
9200|TCP|Elasticsearch
27017|TCP|MongoDB
11211|TCP/UDP|Memcached
TABLE
    echo
    echo -e "  ${CYAN}< 1024${NC}   Privileged / system ports"
    echo -e "  1024-49151  Registered application ports"
    echo -e "  49152-65535 Ephemeral / dynamic ports"
    echo
}

export_report() {
    local rpt="$HOME/Desktop/PortScan_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$HOME/Desktop" 2>/dev/null
    {
        echo "========================================================"
        echo "  PORT SCAN REPORT — $(hostname)"
        echo "  Generated: $(date)"
        echo "========================================================"
        echo; echo "[ss -tulnp]"; ss -tulnp 2>/dev/null
        echo; echo "[ESTABLISHED]"; ss -tnp state established 2>/dev/null
        command -v nmap &>/dev/null && { echo; echo "[nmap localhost]"; nmap -sV localhost 2>/dev/null; }
        echo; echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved: $rpt\n"
}

while true; do
    show_menu
    case "$choice" in
        1) all_ports;         read -rp "  Press Enter..." ;;
        2) tcp_ports;         read -rp "  Press Enter..." ;;
        3) udp_ports;         read -rp "  Press Enter..." ;;
        4) established;       read -rp "  Press Enter..." ;;
        5) check_port;        read -rp "  Press Enter..." ;;
        6) scan_by_process;   read -rp "  Press Enter..." ;;
        7) nmap_scan;         read -rp "  Press Enter..." ;;
        8) common_ports_ref;  read -rp "  Press Enter..." ;;
        9) export_report;     read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
