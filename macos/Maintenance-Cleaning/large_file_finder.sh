#!/usr/bin/env bash
# ============================================================
# Name      : large_file_finder.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW  (read-only scan, no files deleted)
# Sudo      : Not Required
# Reversible: Yes
# Desc      : Finds files over a size threshold on the
#             filesystem. Excludes /System, /dev, and VM.
#             Sorted by descending size. Saves report to
#             Desktop optionally.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

LAST_RESULTS=""

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         LARGE FILE FINDER  v1.0.0                    ║"
    echo "  ║     Find space hogs on your Mac                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Find files over 500 MB  (Home folder)"
    echo -e "  ${BOLD}[2]${NC}  Find files over 1 GB    (Home folder)"
    echo -e "  ${BOLD}[3]${NC}  Find files over 500 MB  (Full filesystem)"
    echo -e "  ${BOLD}[4]${NC}  Find files over 1 GB    (Full filesystem)"
    echo -e "  ${BOLD}[5]${NC}  Custom size and path scan"
    echo -e "  ${BOLD}[6]${NC}  Find Large Folders  (top 15 by size)"
    echo -e "  ${BOLD}[7]${NC}  Save Last Results to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

run_scan() {
    local path="$1"
    local min_mb="$2"
    local label="$3"

    clear
    echo -e "${BOLD}${CYAN}  SCANNING: $path${NC}"
    echo -e "  Threshold: ${min_mb} MB  |  This may take a minute..."
    echo -e "  ${DASH}\n"

    local tmp; tmp=$(mktemp /tmp/lff_XXXXXX.txt)
    local min_bytes=$(( min_mb * 1048576 ))

    # Excluded paths
    local excludes=(
        "/System"
        "/dev"
        "/private/var/vm"
        "/private/var/folders"
        "/Library/Developer"
        "/.Spotlight-V100"
        "/.fseventsd"
        "/.DocumentRevisions-V100"
    )

    local prune_args=()
    for ex in "${excludes[@]}"; do
        prune_args+=( -path "$ex" -prune -o )
    done

    find "$path" "${prune_args[@]}" \
        -type f -size +"${min_mb}M" -print 2>/dev/null | \
        while IFS= read -r f; do
            local sz; sz=$(stat -f%z "$f" 2>/dev/null || echo 0)
            local mb=$(( sz / 1048576 ))
            printf "%06d MB  %s\n" "$mb" "$f"
        done | sort -rn > "$tmp"

    local count; count=$(wc -l < "$tmp" | tr -d ' ')

    if [[ "$count" -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} No files over ${min_mb} MB found in $path"
    else
        echo -e "  Found ${BOLD}${count}${NC} file(s) over ${min_mb} MB:\n"
        printf "  %-12s %s\n" "Size" "Path"
        echo -e "  ${DASH}"
        head -50 "$tmp" | while IFS= read -r line; do
            echo "  $line"
        done
        [[ $count -gt 50 ]] && echo -e "\n  ${YELLOW}... and $(( count - 50 )) more. Save results to see all.${NC}"
    fi

    LAST_RESULTS="$tmp"
    echo
    echo -e "  ${CYAN}Tip:${NC} Use option [7] to save full results to Desktop."
    echo
}

large_folders() {
    clear
    echo -e "${BOLD}${CYAN}  TOP 15 LARGEST FOLDERS — Home Directory${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  Calculating... (may take a moment)\n"
    du -sm "$HOME"/*/ 2>/dev/null | sort -rn | head -15 | \
        awk '{printf "  %6s MB   %s\n", $1, $2}'
    echo
    echo -e "  ${BOLD}Top folders system-wide (excluding /System /dev):${NC}"
    du -sm /Applications /Library /usr/local 2>/dev/null | sort -rn | \
        awk '{printf "  %6s MB   %s\n", $1, $2}'
    echo
}

custom_scan() {
    echo
    printf "  Enter folder to scan (e.g. /Users/%s or /): " "$(whoami)"
    read -r scan_path
    [[ ! -d "$scan_path" ]] && echo -e "  ${RED}[ERROR]${NC} Path not found." && return
    printf "  Minimum file size in MB (e.g. 100 500 1024): "
    read -r min_mb
    [[ ! "$min_mb" =~ ^[0-9]+$ ]] && echo -e "  ${RED}[ERROR]${NC} Enter a number." && return
    run_scan "$scan_path" "$min_mb" "Custom"
}

save_results() {
    if [[ -z "$LAST_RESULTS" || ! -f "$LAST_RESULTS" ]]; then
        echo -e "\n  ${YELLOW}[INFO]${NC} No scan results to save. Run a scan first."
        echo; return
    fi
    local rpt="$HOME/Desktop/LargeFiles_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  LARGE FILE FINDER RESULTS"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        cat "$LAST_RESULTS"
        echo
        echo "========================================================"
        echo "  END"
        echo "========================================================"
    } > "$rpt"
    echo -e "\n  ${GREEN}[OK]${NC} Results saved to Desktop: $(basename "$rpt")"
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) run_scan "$HOME"  500 "500MB Home"; read -rp "  Press Enter..." ;;
        2) run_scan "$HOME" 1024 "1GB Home";   read -rp "  Press Enter..." ;;
        3) run_scan "/"      500 "500MB Root"; read -rp "  Press Enter..." ;;
        4) run_scan "/"     1024 "1GB Root";   read -rp "  Press Enter..." ;;
        5) custom_scan;                         read -rp "  Press Enter..." ;;
        6) large_folders;                       read -rp "  Press Enter..." ;;
        7) save_results;                        read -rp "  Press Enter..." ;;
        0) [[ -n "$LAST_RESULTS" ]] && rm -f "$LAST_RESULTS" 2>/dev/null; echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
