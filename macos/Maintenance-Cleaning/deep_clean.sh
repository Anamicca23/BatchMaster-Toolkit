#!/usr/bin/env bash
# ============================================================
# Name      : deep_clean.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : MEDIUM
# Sudo      : Required
# Reversible: No  (deleted cache/temp files cannot be recovered)
# Desc      : Multi-step macOS deep clean — user cache,
#             DNS flush, Spotlight rebuild, Homebrew cleanup,
#             crash logs, memory purge, and Trash empty.
#             Reports space reclaimed at each step.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

# ── Sudo check ───────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} This script must be run as root."
    echo -e "  Run with: ${BOLD}sudo ./deep_clean.sh${NC}\n"
    exit 1
fi

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           macOS DEEP CLEAN  v1.0.0                   ║"
    echo "  ║     Cache, DNS, Spotlight, Brew, Logs, Trash          ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Deep Clean  (all steps)"
    echo -e "  ${BOLD}[2]${NC}  User Cache Only  (~/Library/Caches)"
    echo -e "  ${BOLD}[3]${NC}  Flush DNS Cache"
    echo -e "  ${BOLD}[4]${NC}  Homebrew Cleanup  (if installed)"
    echo -e "  ${BOLD}[5]${NC}  Clear Crash Logs"
    echo -e "  ${BOLD}[6]${NC}  Purge RAM"
    echo -e "  ${BOLD}[7]${NC}  Empty Trash"
    echo -e "  ${BOLD}[8]${NC}  Preview — Show What Will Be Cleaned"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

# ── Utility: get folder size in MB ───────────────────────────────────
folder_mb() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sm "$path" 2>/dev/null | awk '{print $1}' || echo 0
    else
        echo 0
    fi
}

confirm() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} $1"
    echo -e "  This action cannot be undone."
    printf "  Proceed? (y/N): "
    read -r ans
    [[ "${ans,,}" == "y" ]] && return 0 || return 1
}

step() { echo -e "\n  ${BOLD}${CYAN}[$1/$2]${NC} $3"; }
ok()   { echo -e "  ${GREEN}[DONE]${NC} $1"; }
skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; }
info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }

# ── STEP: User Cache ──────────────────────────────────────────────────
clean_user_cache() {
    local cache="$HOME/Library/Caches"
    local before; before=$(folder_mb "$cache")
    step "$1" "$2" "Cleaning user cache: $cache"
    rm -rf "${cache:?}"/* 2>/dev/null || true
    local after; after=$(folder_mb "$cache")
    local freed=$(( before - after ))
    ok "User cache cleared.  Freed: ~${freed} MB  (was: ${before} MB)"
}

# ── STEP: System Cache ────────────────────────────────────────────────
clean_system_cache() {
    local scache="/Library/Caches"
    local before; before=$(folder_mb "$scache")
    step "$1" "$2" "Cleaning system cache: $scache"
    rm -rf "${scache:?}"/* 2>/dev/null || true
    local after; after=$(folder_mb "$scache")
    ok "System cache cleared.  Freed: ~$(( before - after )) MB"
}

# ── STEP: DNS Flush ───────────────────────────────────────────────────
flush_dns() {
    step "$1" "$2" "Flushing DNS cache..."
    dscacheutil -flushcache 2>/dev/null && ok "dscacheutil flushed." || skip "dscacheutil unavailable."
    killall -HUP mDNSResponder 2>/dev/null && ok "mDNSResponder restarted." || skip "mDNSResponder not running."
}

# ── STEP: Spotlight Rebuild ───────────────────────────────────────────
rebuild_spotlight() {
    step "$1" "$2" "Rebuilding Spotlight index (runs in background)..."
    mdutil -E / 2>/dev/null && ok "Spotlight index rebuild scheduled." || skip "mdutil not available."
}

# ── STEP: Homebrew ────────────────────────────────────────────────────
brew_cleanup() {
    step "$1" "$2" "Running Homebrew cleanup..."
    if command -v brew &>/dev/null; then
        local before; before=$(df -m / 2>/dev/null | awk 'NR==2{print $3}')
        brew cleanup --prune=all 2>/dev/null | tail -5 | sed 's/^/  /'
        brew autoremove 2>/dev/null | tail -3 | sed 's/^/  /'
        local after; after=$(df -m / 2>/dev/null | awk 'NR==2{print $3}')
        ok "Homebrew cleanup done.  Freed: ~$(( before - after )) MB"
    else
        skip "Homebrew not installed — skipping."
    fi
}

# ── STEP: Crash Logs ──────────────────────────────────────────────────
clean_crash_logs() {
    step "$1" "$2" "Removing crash and diagnostic logs..."
    local dirs=("$HOME/Library/Logs" "/Library/Logs" "/var/log")
    local total=0
    for d in "${dirs[@]}"; do
        if [[ -d "$d" ]]; then
            local before; before=$(folder_mb "$d")
            find "$d" -name "*.crash" -o -name "*.diag" -o -name "*.ips" 2>/dev/null | \
                xargs rm -f 2>/dev/null || true
            local after; after=$(folder_mb "$d")
            total=$(( total + before - after ))
        fi
    done
    ok "Crash logs removed.  Freed: ~${total} MB"
}

# ── STEP: Purge RAM ───────────────────────────────────────────────────
purge_ram() {
    step "$1" "$2" "Purging inactive memory..."
    local before; before=$(vm_stat 2>/dev/null | grep "Pages free" | awk '{print $3}' | tr -d '.')
    purge 2>/dev/null && ok "Memory purged." || skip "purge command unavailable."
}

# ── STEP: Empty Trash ─────────────────────────────────────────────────
empty_trash() {
    step "$1" "$2" "Emptying Trash..."
    local trash="$HOME/.Trash"
    local before; before=$(folder_mb "$trash")
    rm -rf "${trash:?}"/* 2>/dev/null || true
    ok "Trash emptied.  Freed: ~${before} MB"
}

# ── Full Clean ────────────────────────────────────────────────────────
full_clean() {
    confirm "Full deep clean will remove caches, logs, and trash contents." || {
        echo -e "  Cancelled."; read -rp "  Press Enter..."; return
    }

    local disk_before; disk_before=$(df -m / 2>/dev/null | awk 'NR==2{print $3}')

    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL DEEP CLEAN...${NC}\n"

    clean_user_cache   1 8
    clean_system_cache 2 8
    flush_dns          3 8
    rebuild_spotlight  4 8
    brew_cleanup       5 8
    clean_crash_logs   6 8
    purge_ram          7 8
    empty_trash        8 8

    local disk_after; disk_after=$(df -m / 2>/dev/null | awk 'NR==2{print $3}')
    local freed=$(( disk_before - disk_after ))
    [[ $freed -lt 0 ]] && freed=0

    echo
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  DEEP CLEAN COMPLETE                                  ║"
    printf "  ║  %-52s  ║\n" "Total disk space freed: ~${freed} MB"
    echo "  ║  Restart recommended for full effect.                 ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ── Preview ───────────────────────────────────────────────────────────
preview() {
    clear
    echo -e "${BOLD}${CYAN}  PREVIEW — What will be cleaned${NC}"
    echo -e "  ${DASH}\n"

    local targets=(
        "$HOME/Library/Caches"
        "/Library/Caches"
        "$HOME/Library/Logs"
        "/Library/Logs"
        "$HOME/.Trash"
    )

    printf "  %-50s %s\n" "Target" "Size"
    echo -e "  ${DASH}"
    local total=0
    for t in "${targets[@]}"; do
        if [[ -d "$t" ]]; then
            local sz; sz=$(folder_mb "$t")
            total=$(( total + sz ))
            printf "  %-50s %s MB\n" "$t" "$sz"
        fi
    done
    echo -e "  ${DASH}"
    printf "  %-50s %s MB\n" "Estimated total reclaimable:" "$total"
    echo
    info "DNS flush and Spotlight rebuild have no disk size impact."
    command -v brew &>/dev/null && info "Homebrew cleanup will also run (size varies)." || info "Homebrew not installed — that step will be skipped."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_clean ;;
        2) confirm "Clear ~/Library/Caches?" && clean_user_cache 1 1; echo; read -rp "  Press Enter..." ;;
        3) flush_dns 1 1; echo; read -rp "  Press Enter..." ;;
        4) brew_cleanup 1 1; echo; read -rp "  Press Enter..." ;;
        5) confirm "Remove crash and diagnostic log files?" && clean_crash_logs 1 1; echo; read -rp "  Press Enter..." ;;
        6) purge_ram 1 1; echo; read -rp "  Press Enter..." ;;
        7) confirm "Empty the Trash? This is permanent." && empty_trash 1 1; echo; read -rp "  Press Enter..." ;;
        8) preview; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
