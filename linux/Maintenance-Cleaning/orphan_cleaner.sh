#!/usr/bin/env bash
# ============================================================
# Name      : orphan_cleaner.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : HIGH
# Sudo      : Required
# Reversible: No  (apt purge is permanent)
# Desc      : Finds and removes orphaned packages via deborphan.
#             Lists all installed kernels, keeps current + 1
#             prior, removes the rest. Scans /usr/local for
#             broken symlinks. User reviews before any removal.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./orphan_cleaner.sh${NC}\n"
    exit 1
fi

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           ORPHAN CLEANER  v1.0.0                     ║"
    echo "  ║     Orphaned pkgs · Old kernels · Broken symlinks    ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Orphan Clean  (all steps with review)"
    echo -e "  ${BOLD}[2]${NC}  Find + Remove Orphaned Packages  (deborphan)"
    echo -e "  ${BOLD}[3]${NC}  Find + Remove Old Kernels  (keep current+1)"
    echo -e "  ${BOLD}[4]${NC}  Find Broken Symlinks in /usr/local  (list only)"
    echo -e "  ${BOLD}[5]${NC}  Remove Broken Symlinks  (after review)"
    echo -e "  ${BOLD}[6]${NC}  Show Autoremovable Packages"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

confirm() {
    echo; echo -e "  ${YELLOW}[WARNING]${NC} $1"
    printf "  Proceed? (y/N): "; read -r ans
    [[ "${ans,,}" == "y" ]] && return 0 || { echo "  Cancelled."; return 1; }
}

ensure_deborphan() {
    if ! command -v deborphan &>/dev/null; then
        echo -e "  ${YELLOW}deborphan not installed.${NC}"
        printf "  Install it now? (y/N): "; read -r ans
        if [[ "${ans,,}" == "y" ]]; then
            apt-get install -y deborphan 2>&1 | tail -3 | sed 's/^/  /'
        else
            echo -e "  ${YELLOW}Skipping orphan check.${NC}"; return 1
        fi
    fi
    return 0
}

clean_orphans() {
    echo -e "\n  ${BOLD}ORPHANED PACKAGES${NC}"
    echo -e "  ${DASH}"
    ensure_deborphan || return

    local orphans; orphans=$(deborphan 2>/dev/null)
    if [[ -z "$orphans" ]]; then
        echo -e "  ${GREEN}[OK]${NC} No orphaned packages found."
        return
    fi

    local count; count=$(echo "$orphans" | wc -l)
    echo -e "  Found ${BOLD}${count}${NC} orphaned package(s):\n"
    echo "$orphans" | sed 's/^/    /'
    echo

    confirm "Remove these $count orphaned packages with apt purge?" || return
    echo "$orphans" | xargs apt-get purge -y 2>&1 | tail -5 | sed 's/^/  /'
    apt-get autoremove -y 2>&1 | tail -3 | sed 's/^/  /'
    echo -e "  ${GREEN}[DONE]${NC} Orphaned packages removed."
}

clean_old_kernels() {
    echo -e "\n  ${BOLD}OLD KERNEL CLEANUP${NC}"
    echo -e "  ${DASH}"

    local current_kernel; current_kernel=$(uname -r)
    echo -e "  Running kernel: ${BOLD}${current_kernel}${NC}"

    # List all installed kernel image packages
    local all_kernels; all_kernels=$(dpkg --list 'linux-image-*' 2>/dev/null | \
        grep "^ii" | awk '{print $2}' | grep -v "$current_kernel" | sort -V)

    if [[ -z "$all_kernels" ]]; then
        echo -e "  ${GREEN}[OK]${NC} No extra kernels to remove."
        return
    fi

    # Keep the one immediately prior to current (highest version)
    local all_array; mapfile -t all_array <<< "$all_kernels"
    local total=${#all_array[@]}

    if [[ $total -le 1 ]]; then
        echo -e "  ${GREEN}[OK]${NC} Only one other kernel installed (keeping as fallback)."
        echo -e "  Keeping: ${all_array[*]}"
        return
    fi

    # Keep last one (most recent non-current), remove the rest
    local keep="${all_array[$((total-1))]}"
    local to_remove=("${all_array[@]:0:$((total-1))}")

    echo -e "  Currently installed kernels:"
    for k in "${all_array[@]}"; do
        if [[ "$k" == "$keep" ]]; then
            echo -e "    ${GREEN}KEEP${NC}   $k  (fallback)"
        else
            echo -e "    ${RED}REMOVE${NC} $k"
        fi
    done
    echo -e "    ${GREEN}KEEP${NC}   linux-image-${current_kernel}  (running)"
    echo

    if [[ ${#to_remove[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} Nothing to remove."
        return
    fi

    confirm "Remove ${#to_remove[@]} old kernel(s)?" || return

    for k in "${to_remove[@]}"; do
        echo -e "  Removing: $k"
        apt-get purge -y "$k" 2>&1 | tail -2 | sed 's/^/    /'
        # Also remove related headers
        local hdr="${k/linux-image/linux-headers}"
        dpkg -l "$hdr" &>/dev/null && apt-get purge -y "$hdr" 2>&1 | tail -2 | sed 's/^/    /' || true
    done
    apt-get autoremove -y 2>&1 | tail -3 | sed 's/^/  /'
    update-grub 2>/dev/null | tail -3 | sed 's/^/  /' || true
    echo -e "  ${GREEN}[DONE]${NC} Old kernels removed and GRUB updated."
}

find_broken_symlinks() {
    echo -e "\n  ${BOLD}BROKEN SYMLINKS in /usr/local${NC}"
    echo -e "  ${DASH}"
    echo -e "  Scanning /usr/local for broken symlinks...\n"

    local found=0
    while IFS= read -r link; do
        echo -e "  ${RED}BROKEN${NC} $link"
        found=$(( found + 1 ))
    done < <(find /usr/local -xtype l 2>/dev/null)

    if [[ $found -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} No broken symlinks found in /usr/local."
    else
        echo
        echo -e "  Found ${BOLD}${found}${NC} broken symlink(s)."
        echo -e "  Use option [5] to remove them after review."
    fi
    echo
}

remove_broken_symlinks() {
    echo -e "\n  Finding broken symlinks in /usr/local..."
    local links; links=$(find /usr/local -xtype l 2>/dev/null)

    if [[ -z "$links" ]]; then
        echo -e "  ${GREEN}[OK]${NC} No broken symlinks found."; echo; return
    fi

    local count; count=$(echo "$links" | wc -l)
    echo -e "\n  ${BOLD}Broken symlinks to remove:${NC}"
    echo "$links" | sed 's/^/    /'
    echo

    confirm "Remove $count broken symlink(s)?" || return
    echo "$links" | xargs rm -f 2>/dev/null
    echo -e "  ${GREEN}[DONE]${NC} $count broken symlink(s) removed."
    echo
}

show_autoremovable() {
    clear
    echo -e "${BOLD}${CYAN}  AUTOREMOVABLE PACKAGES${NC}"
    echo -e "  ${DASH}\n"
    apt-get --dry-run autoremove 2>/dev/null | grep "^Remov" | sed 's/^/  /'
    echo
    echo -e "  Run ${BOLD}sudo apt autoremove${NC} to remove these packages."
    echo
}

full_clean() {
    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL ORPHAN CLEAN (with review at each step)...${NC}\n"
    clean_orphans
    echo; clean_old_kernels
    echo; find_broken_symlinks
    echo -e "  ${GREEN}[DONE]${NC} All clean steps completed."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_clean;                read -rp "  Press Enter..." ;;
        2) clean_orphans;             echo; read -rp "  Press Enter..." ;;
        3) clean_old_kernels;         echo; read -rp "  Press Enter..." ;;
        4) find_broken_symlinks;      read -rp "  Press Enter..." ;;
        5) remove_broken_symlinks;    read -rp "  Press Enter..." ;;
        6) show_autoremovable;        read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
