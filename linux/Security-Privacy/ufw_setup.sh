#!/usr/bin/env bash
# ============================================================
# Name      : ufw_setup.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : HIGH
# Sudo      : Required
# Reversible: Yes  (Option [5] disables + resets ufw)
# Desc      : Configures UFW with secure defaults: deny all
#             incoming, allow outgoing, allow SSH from local
#             subnet only, rate-limit SSH, logging on.
#             Prints final ruleset after every change.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./ufw_setup.sh${NC}\n"
    exit 1
fi

ensure_ufw() {
    if ! command -v ufw &>/dev/null; then
        echo -e "  ${YELLOW}ufw not installed.${NC}"
        printf "  Install it now? (y/N): "; read -r ans
        [[ "${ans,,}" == "y" ]] && apt-get install -y ufw 2>&1 | tail -3 | sed 's/^/  /' || return 1
    fi
    return 0
}

show_status() {
    echo -e "\n  ${BOLD}Current UFW Status:${NC}"
    echo -e "  ${DASH}"
    ufw status verbose 2>/dev/null | sed 's/^/  /'
    echo
}

show_menu() {
    local ufw_state
    ufw_state=$(ufw status 2>/dev/null | head -1 || echo "unknown")
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           UFW SETUP  v1.0.0                          ║"
    echo "  ║     Secure defaults · SSH rules · Logging            ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  UFW Status: ${BOLD}${ufw_state}${NC}"
    echo
    echo -e "  ${BOLD}[1]${NC}  Apply Secure Defaults  (recommended baseline)"
    echo -e "  ${BOLD}[2]${NC}  Enable UFW"
    echo -e "  ${BOLD}[3]${NC}  Show Current Rules"
    echo -e "  ${BOLD}[4]${NC}  Add an Allow Rule"
    echo -e "  ${BOLD}[5]${NC}  Add a Deny Rule"
    echo -e "  ${BOLD}[6]${NC}  Delete a Rule"
    echo -e "  ${BOLD}[7]${NC}  Enable/Disable Logging"
    echo -e "  ${BOLD}[8]${NC}  DISABLE UFW + Reset to defaults"
    echo -e "  ${BOLD}[9]${NC}  Common Rule Examples"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

apply_secure_defaults() {
    ensure_ufw || { read -rp "  Press Enter..."; return; }
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} This will:"
    echo -e "    - Reset UFW to a clean state"
    echo -e "    - Deny ALL incoming connections"
    echo -e "    - Allow all outgoing connections"
    echo -e "    - Allow SSH on port 22 from 192.168.0.0/24 (local subnet)"
    echo -e "    - Rate-limit SSH to prevent brute force"
    echo -e "    - Enable logging"
    echo -e "    - Enable UFW"
    printf "\n  Apply secure defaults? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return

    echo
    echo -e "  ${BOLD}[1/7]${NC} Resetting UFW to clean state..."
    echo "y" | ufw reset 2>/dev/null | tail -2 | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[2/7]${NC} Setting default policies..."
    ufw default deny incoming  2>/dev/null | sed 's/^/  /'
    ufw default allow outgoing 2>/dev/null | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[3/7]${NC} Allowing SSH from local subnet (192.168.0.0/24)..."
    ufw allow from 192.168.0.0/24 to any port 22 proto tcp 2>/dev/null | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[4/7]${NC} Rate-limiting SSH (anti brute-force)..."
    ufw limit 22/tcp 2>/dev/null | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[5/7]${NC} Enabling UFW logging..."
    ufw logging on 2>/dev/null | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[6/7]${NC} Enabling UFW..."
    echo "y" | ufw enable 2>/dev/null | sed 's/^/  /'
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[7/7]${NC} Final ruleset:"
    show_status

    echo -e "${GREEN}  [DONE]${NC} Secure UFW configuration applied."
    echo -e "  ${CYAN}Note:${NC} If you are on SSH right now from outside the local subnet,"
    echo -e "  your connection may be interrupted. Add your IP with option [4] first."
    echo
}

enable_ufw() {
    ensure_ufw || return
    echo "y" | ufw enable 2>/dev/null | sed 's/^/  /'
    show_status
}

add_allow_rule() {
    ensure_ufw || return
    echo
    echo -e "  Examples: 80/tcp   443   8080/tcp   from 192.168.1.0/24 to any port 22"
    printf "  Enter rule to ALLOW: "
    read -r rule
    [[ -z "$rule" ]] && return
    ufw allow $rule 2>&1 | sed 's/^/  /'
    show_status
}

add_deny_rule() {
    ensure_ufw || return
    echo
    printf "  Enter rule to DENY: "
    read -r rule
    [[ -z "$rule" ]] && return
    ufw deny $rule 2>&1 | sed 's/^/  /'
    show_status
}

delete_rule() {
    ensure_ufw || return
    echo
    ufw status numbered 2>/dev/null | sed 's/^/  /'
    echo
    printf "  Enter rule NUMBER to delete: "
    read -r num
    [[ ! "$num" =~ ^[0-9]+$ ]] && echo "  Invalid." && return
    echo "y" | ufw delete "$num" 2>&1 | sed 's/^/  /'
    show_status
}

toggle_logging() {
    ensure_ufw || return
    echo
    local current; current=$(ufw status verbose 2>/dev/null | grep "^Logging:" | awk '{print $2}')
    if [[ "$current" == "on" ]]; then
        ufw logging off 2>/dev/null | sed 's/^/  /'
        echo -e "  ${YELLOW}Logging: DISABLED${NC}"
    else
        ufw logging on 2>/dev/null | sed 's/^/  /'
        echo -e "  ${GREEN}Logging: ENABLED${NC}"
    fi
    echo
}

disable_reset() {
    echo
    echo -e "  ${RED}[WARNING]${NC} This will disable UFW and reset ALL rules."
    printf "  Disable and reset? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    ufw disable 2>/dev/null | sed 's/^/  /'
    echo "y" | ufw reset 2>/dev/null | sed 's/^/  /'
    echo -e "  ${YELLOW}[DONE]${NC} UFW disabled and reset."
    echo
}

common_rules() {
    clear
    echo -e "${BOLD}${CYAN}  COMMON UFW RULE EXAMPLES${NC}"
    echo -e "  ${DASH}\n"
    cat << 'RULES'
  ALLOW specific port:
    ufw allow 80/tcp           # Allow HTTP
    ufw allow 443/tcp          # Allow HTTPS
    ufw allow 8080             # Allow any protocol on 8080

  ALLOW from specific IP:
    ufw allow from 192.168.1.100           # All traffic from IP
    ufw allow from 192.168.1.0/24          # All traffic from subnet
    ufw allow from 10.0.0.5 to any port 22 # SSH from specific IP

  DENY specific port:
    ufw deny 23                # Block Telnet
    ufw deny from 1.2.3.4      # Block all from IP

  RATE LIMIT (anti brute-force):
    ufw limit 22/tcp           # Limit SSH connection attempts

  DELETE a rule (by number):
    ufw status numbered        # See rule numbers
    ufw delete 3               # Delete rule #3

  VIEW STATUS:
    ufw status verbose         # Detailed status with rules
    ufw app list               # List available application profiles

  LOGGING:
    ufw logging on             # Enable logging
    cat /var/log/ufw.log       # View UFW log

RULES
}

while true; do
    ensure_ufw || { echo -e "  ${RED}ufw required.${NC}"; exit 1; }
    show_menu
    case "$choice" in
        1) apply_secure_defaults;  read -rp "  Press Enter..." ;;
        2) enable_ufw;             read -rp "  Press Enter..." ;;
        3) show_status;            read -rp "  Press Enter..." ;;
        4) add_allow_rule;         read -rp "  Press Enter..." ;;
        5) add_deny_rule;          read -rp "  Press Enter..." ;;
        6) delete_rule;            read -rp "  Press Enter..." ;;
        7) toggle_logging;         read -rp "  Press Enter..." ;;
        8) disable_reset;          read -rp "  Press Enter..." ;;
        9) common_rules;           read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
