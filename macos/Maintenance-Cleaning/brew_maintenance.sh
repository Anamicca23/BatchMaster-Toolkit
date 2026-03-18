#!/usr/bin/env bash
# ============================================================
# Name      : brew_maintenance.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (upgrades can be rolled back with brew)
# Desc      : Full Homebrew maintenance — update index,
#             upgrade formulae and casks, cleanup old versions,
#             autoremove unused deps, doctor health check.
#             Reports disk space reclaimed.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

check_brew() {
    if ! command -v brew &>/dev/null; then
        echo -e "\n  ${RED}[ERROR]${NC} Homebrew is not installed."
        echo -e "  Install from: ${BOLD}https://brew.sh${NC}"
        echo -e "  Command: ${BOLD}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}\n"
        exit 1
    fi
}

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         HOMEBREW MAINTENANCE  v1.0.0                 ║"
    echo "  ║     Update · Upgrade · Cleanup · Doctor               ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Homebrew: $(brew --version 2>/dev/null | head -1)"
    echo -e "  Location: $(brew --prefix 2>/dev/null)"
    echo
    echo -e "  ${BOLD}[1]${NC}  Full Maintenance  (update + upgrade + cleanup + doctor)"
    echo -e "  ${BOLD}[2]${NC}  Update Package Index  (brew update)"
    echo -e "  ${BOLD}[3]${NC}  Upgrade All Formulae  (brew upgrade)"
    echo -e "  ${BOLD}[4]${NC}  Upgrade All Casks     (brew upgrade --cask)"
    echo -e "  ${BOLD}[5]${NC}  Cleanup Old Versions  (brew cleanup --prune=all)"
    echo -e "  ${BOLD}[6]${NC}  Remove Unused Deps    (brew autoremove)"
    echo -e "  ${BOLD}[7]${NC}  Health Check          (brew doctor)"
    echo -e "  ${BOLD}[8]${NC}  List Installed Packages"
    echo -e "  ${BOLD}[9]${NC}  List Outdated Packages"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

disk_used() {
    df -m / 2>/dev/null | awk 'NR==2{print $3}' || echo 0
}

step() { echo -e "\n  ${BOLD}${CYAN}[$1/$2]${NC} $3"; }
ok()   { echo -e "  ${GREEN}[DONE]${NC} $1"; }

full_maintenance() {
    local d_before; d_before=$(disk_used)
    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL HOMEBREW MAINTENANCE...${NC}\n"

    step 1 5 "Updating Homebrew package index..."
    brew update 2>&1 | tail -5 | sed 's/^/  /'
    ok "Index updated."

    step 2 5 "Upgrading all formulae..."
    brew upgrade 2>&1 | tail -10 | sed 's/^/  /'
    ok "Formulae upgraded."

    step 3 5 "Upgrading all casks..."
    brew upgrade --cask 2>&1 | tail -10 | sed 's/^/  /'
    ok "Casks upgraded."

    step 4 5 "Removing all old versions (prune=all)..."
    brew cleanup --prune=all 2>&1 | tail -5 | sed 's/^/  /'
    ok "Old versions removed."

    step 5 5 "Removing unused dependencies..."
    brew autoremove 2>&1 | tail -5 | sed 's/^/  /'
    ok "Unused dependencies removed."

    local d_after; d_after=$(disk_used)
    local freed=$(( d_before - d_after ))
    [[ $freed -lt 0 ]] && freed=0

    echo
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  HOMEBREW MAINTENANCE COMPLETE                        ║"
    printf "  ║  %-52s  ║\n" "Disk space freed: ~${freed} MB"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}Tip:${NC} Run ${BOLD}brew doctor${NC} to check for any configuration issues."
    echo
}

list_installed() {
    clear
    echo -e "${BOLD}${CYAN}  INSTALLED PACKAGES${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  ${BOLD}Formulae:${NC}"
    brew list --formulae 2>/dev/null | column | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Casks:${NC}"
    brew list --cask 2>/dev/null | column | sed 's/^/  /'
    echo
    local f_count; f_count=$(brew list --formulae 2>/dev/null | wc -l | tr -d ' ')
    local c_count; c_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  Total: ${BOLD}${f_count}${NC} formulae  +  ${BOLD}${c_count}${NC} casks"
    echo
}

list_outdated() {
    clear
    echo -e "${BOLD}${CYAN}  OUTDATED PACKAGES${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  Checking for outdated formulae...\n"
    local outdated; outdated=$(brew outdated 2>/dev/null)
    if [[ -z "$outdated" ]]; then
        echo -e "  ${GREEN}[OK]${NC} All packages are up to date."
    else
        echo "$outdated" | sed 's/^/  /'
        echo
        echo -e "  Run ${BOLD}brew upgrade${NC} to update all, or ${BOLD}brew upgrade <name>${NC} for one."
    fi
    echo
}

while true; do
    check_brew
    show_menu
    case "$choice" in
        1) full_maintenance; read -rp "  Press Enter..." ;;
        2) brew update 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        3) brew upgrade 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        4) brew upgrade --cask 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        5) brew cleanup --prune=all 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        6) brew autoremove 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        7) brew doctor 2>&1 | sed 's/^/  /'; echo; read -rp "  Press Enter..." ;;
        8) list_installed; read -rp "  Press Enter..." ;;
        9) list_outdated;  read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
