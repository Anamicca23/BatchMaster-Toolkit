#!/usr/bin/env bash
# ============================================================
# Name      : firewall_manager.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : HIGH
# Sudo      : Required
# Reversible: Yes  (all settings can be reversed)
# Desc      : Manages the macOS Application Firewall using
#             socketfilterfw. Enable/disable, stealth mode,
#             list and manage app rules, block incoming
#             connections. Prints final ruleset after change.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

FW="/usr/libexec/ApplicationFirewall/socketfilterfw"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./firewall_manager.sh${NC}\n"
    exit 1
fi

if [[ ! -x "$FW" ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} socketfilterfw not found at $FW"
    echo -e "  This script requires macOS 10.5 or later.\n"
    exit 1
fi

get_fw_state() {
    "$FW" --getglobalstate 2>/dev/null | grep -q "enabled" && echo "ENABLED" || echo "DISABLED"
}

get_stealth_state() {
    "$FW" --getstealthmode 2>/dev/null | grep -q "enabled" && echo "ENABLED" || echo "DISABLED"
}

show_menu() {
    local state; state=$(get_fw_state)
    local stealth; stealth=$(get_stealth_state)
    local state_color="$RED"; [[ "$state" == "ENABLED" ]] && state_color="$GREEN"
    local stealth_color="$YELLOW"; [[ "$stealth" == "ENABLED" ]] && stealth_color="$GREEN"

    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         FIREWALL MANAGER  v1.0.0                     ║"
    echo "  ║     macOS Application Firewall control               ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Firewall:     ${state_color}${BOLD}${state}${NC}"
    echo -e "  Stealth Mode: ${stealth_color}${BOLD}${stealth}${NC}"
    echo
    echo -e "  ${BOLD}[1]${NC}  Enable Firewall"
    echo -e "  ${BOLD}[2]${NC}  Disable Firewall"
    echo -e "  ${BOLD}[3]${NC}  Enable Stealth Mode  (blocks ping responses)"
    echo -e "  ${BOLD}[4]${NC}  Disable Stealth Mode"
    echo -e "  ${BOLD}[5]${NC}  List All App Rules"
    echo -e "  ${BOLD}[6]${NC}  Add App Rule  (allow or block an app)"
    echo -e "  ${BOLD}[7]${NC}  Remove App Rule"
    echo -e "  ${BOLD}[8]${NC}  Block All Incoming Connections"
    echo -e "  ${BOLD}[9]${NC}  Allow All Signed Apps"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

print_final_state() {
    echo
    echo -e "  ${BOLD}Current Firewall State:${NC}"
    echo -e "  ${DASH}"
    "$FW" --getglobalstate 2>/dev/null | sed 's/^/  /'
    "$FW" --getstealthmode 2>/dev/null | sed 's/^/  /'
    "$FW" --getblockall    2>/dev/null | sed 's/^/  /'
    echo
}

enable_fw() {
    "$FW" --setglobalstate on 2>/dev/null
    echo -e "  ${GREEN}[DONE]${NC} Firewall ENABLED."
    print_final_state
}

disable_fw() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} Disabling the firewall allows all incoming connections."
    printf "  Disable firewall? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    "$FW" --setglobalstate off 2>/dev/null
    echo -e "  ${YELLOW}[DONE]${NC} Firewall DISABLED."
    print_final_state
}

enable_stealth() {
    "$FW" --setstealthmode on 2>/dev/null
    echo -e "  ${GREEN}[DONE]${NC} Stealth mode ENABLED."
    echo -e "  Your Mac will no longer respond to ping (ICMP) requests."
    echo -e "  This makes your Mac invisible to network scanners."
    print_final_state
}

disable_stealth() {
    "$FW" --setstealthmode off 2>/dev/null
    echo -e "  ${YELLOW}[DONE]${NC} Stealth mode DISABLED."
    print_final_state
}

list_rules() {
    clear
    echo -e "${BOLD}${CYAN}  FIREWALL APP RULES${NC}"
    echo -e "  ${DASH}\n"
    "$FW" --listapps 2>/dev/null | sed 's/^/  /'
    echo
}

add_rule() {
    echo
    echo  "  Enter full application path to add a rule."
    echo  "  Example: /Applications/Safari.app"
    printf "  App path: "; read -r app_path
    [[ -z "$app_path" ]] && echo "  Cancelled." && return
    [[ ! -e "$app_path" ]] && echo -e "  ${RED}[ERROR]${NC} Path not found: $app_path" && return
    echo
    echo -e "  ${BOLD}[A]${NC}  Allow connections for: $app_path"
    echo -e "  ${BOLD}[B]${NC}  Block connections for: $app_path"
    printf "  Choice: "; read -r ab
    case "${ab,,}" in
        a) "$FW" --add "$app_path" 2>/dev/null
           "$FW" --unblockapp "$app_path" 2>/dev/null
           echo -e "  ${GREEN}[DONE]${NC} Added ALLOW rule for: $app_path" ;;
        b) "$FW" --add "$app_path" 2>/dev/null
           "$FW" --blockapp "$app_path" 2>/dev/null
           echo -e "  ${RED}[DONE]${NC} Added BLOCK rule for: $app_path" ;;
        *) echo "  Cancelled." ;;
    esac
    echo
}

remove_rule() {
    echo
    printf "  Enter full app path to remove: "; read -r app_path
    [[ -z "$app_path" ]] && echo "  Cancelled." && return
    "$FW" --remove "$app_path" 2>/dev/null
    echo -e "  ${GREEN}[DONE]${NC} Rule removed for: $app_path"
    echo
}

block_all() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} Block all incoming connections."
    echo -e "  Only software required for basic internet access will be allowed."
    echo -e "  This may break some apps that need incoming connections."
    printf "  Enable block-all? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    "$FW" --setblockall on 2>/dev/null
    echo -e "  ${RED}[DONE]${NC} All incoming connections BLOCKED."
    print_final_state
}

allow_signed() {
    "$FW" --setallowsigned on 2>/dev/null
    "$FW" --setallowsignedapp on 2>/dev/null
    echo -e "  ${GREEN}[DONE]${NC} Signed apps allowed automatically."
    print_final_state
}

while true; do
    show_menu
    case "$choice" in
        1) enable_fw;      read -rp "  Press Enter..." ;;
        2) disable_fw;     read -rp "  Press Enter..." ;;
        3) enable_stealth; read -rp "  Press Enter..." ;;
        4) disable_stealth;read -rp "  Press Enter..." ;;
        5) list_rules;     read -rp "  Press Enter..." ;;
        6) add_rule;       read -rp "  Press Enter..." ;;
        7) remove_rule;    read -rp "  Press Enter..." ;;
        8) block_all;      read -rp "  Press Enter..." ;;
        9) allow_signed;   read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
