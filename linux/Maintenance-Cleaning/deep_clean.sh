#!/usr/bin/env bash
# ============================================================
# Name      : deep_clean.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : MEDIUM
# Sudo      : Required
# Reversible: No  (deleted cache/temp/log files not recoverable)
# Desc      : Multi-stage Linux deep clean — apt cache,
#             user cache, /tmp, systemd journal, thumbnail
#             cache, and redundant snap revisions.
#             Reports space reclaimed at every step.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./deep_clean.sh${NC}\n"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
REAL_HOME=$(eval echo "~$REAL_USER")

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           LINUX DEEP CLEAN  v1.0.0                   ║"
    echo "  ║     apt · cache · /tmp · journal · snaps · thumbs    ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Deep Clean  (all steps)"
    echo -e "  ${BOLD}[2]${NC}  APT Cache Cleanup  (autoremove + clean)"
    echo -e "  ${BOLD}[3]${NC}  User Cache  (~/.cache)"
    echo -e "  ${BOLD}[4]${NC}  Temp Files  (/tmp and /var/tmp)"
    echo -e "  ${BOLD}[5]${NC}  Systemd Journal Trim  (vacuum)"
    echo -e "  ${BOLD}[6]${NC}  Thumbnail Cache"
    echo -e "  ${BOLD}[7]${NC}  Old Snap Revisions"
    echo -e "  ${BOLD}[8]${NC}  Preview  (show sizes, no deletion)"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

disk_free_mb() {
    df -m / 2>/dev/null | awk 'NR==2{print $4}' || echo 0
}

folder_mb() {
    [[ -d "$1" ]] && du -sm "$1" 2>/dev/null | awk '{print $1}' || echo 0
}

confirm() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} $1"
    printf "  Proceed? (y/N): "
    read -r ans
    [[ "${ans,,}" == "y" ]] && return 0 || { echo "  Cancelled."; return 1; }
}

step() { echo -e "\n  ${BOLD}${CYAN}[$1/$2]${NC} $3"; }
ok()   { echo -e "  ${GREEN}[DONE]${NC} $1"; }
info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }

# ── APT Cleanup ───────────────────────────────────────────────────────
clean_apt() {
    step "$1" "$2" "APT cache cleanup..."
    local before; before=$(disk_free_mb)
    apt-get autoremove -y 2>&1 | tail -3 | sed 's/^/  /'
    apt-get autoclean  -y 2>&1 | tail -3 | sed 's/^/  /'
    apt-get clean         2>&1 | tail -2 | sed 's/^/  /'
    local after; after=$(disk_free_mb)
    ok "APT cleaned.  Freed: ~$(( after - before )) MB"
}

# ── User Cache ────────────────────────────────────────────────────────
clean_user_cache() {
    step "$1" "$2" "Clearing user cache (~/.cache)..."
    local cache="${REAL_HOME}/.cache"
    local before; before=$(folder_mb "$cache")
    # Preserve active browser profiles and .mozilla
    find "$cache" -mindepth 1 -maxdepth 1 \
        ! -name ".mozilla" ! -name "mozilla" \
        -exec rm -rf {} + 2>/dev/null || true
    local after; after=$(folder_mb "$cache")
    ok "User cache cleared.  Freed: ~$(( before - after )) MB"
}

# ── Temp Files ────────────────────────────────────────────────────────
clean_tmp() {
    step "$1" "$2" "Clearing temp files (/tmp and /var/tmp)..."
    local before; before=$(disk_free_mb)
    find /tmp     -mindepth 1 -atime +3 -delete 2>/dev/null || true
    find /var/tmp -mindepth 1 -atime +7 -delete 2>/dev/null || true
    local after; after=$(disk_free_mb)
    ok "Temp files cleaned.  Freed: ~$(( after - before )) MB"
}

# ── Systemd Journal ───────────────────────────────────────────────────
clean_journal() {
    step "$1" "$2" "Trimming systemd journal (keep last 7 days)..."
    local before; before=$(folder_mb "/var/log/journal")
    journalctl --vacuum-time=7d    2>&1 | tail -3 | sed 's/^/  /'
    journalctl --vacuum-size=100M  2>&1 | tail -3 | sed 's/^/  /'
    local after; after=$(folder_mb "/var/log/journal")
    ok "Journal trimmed.  Freed: ~$(( before - after )) MB"
}

# ── Thumbnail Cache ───────────────────────────────────────────────────
clean_thumbs() {
    step "$1" "$2" "Clearing thumbnail cache..."
    local thumb="${REAL_HOME}/.cache/thumbnails"
    local before; before=$(folder_mb "$thumb")
    rm -rf "${thumb:?}"/* 2>/dev/null || true
    ok "Thumbnails cleared.  Freed: ~${before} MB"
}

# ── Old Snap Revisions ────────────────────────────────────────────────
clean_snaps() {
    step "$1" "$2" "Removing old snap revisions (keeps 2 latest)..."
    if ! command -v snap &>/dev/null; then
        info "Snap not installed — skipping."
        return
    fi
    local before; before=$(disk_free_mb)
    snap list --all 2>/dev/null | awk '/disabled/{print $1" --revision "$3}' | \
        while read -r snapargs; do
            snap remove $snapargs 2>/dev/null || true
        done
    local after; after=$(disk_free_mb)
    ok "Old snaps removed.  Freed: ~$(( after - before )) MB"
}

# ── Full Clean ────────────────────────────────────────────────────────
full_clean() {
    confirm "Full deep clean will remove cache, temp files, journal, and old snaps." || return
    local d_before; d_before=$(disk_free_mb)
    clear
    echo -e "${BOLD}${CYAN}  RUNNING FULL DEEP CLEAN...${NC}\n"
    clean_apt      1 7
    clean_user_cache 2 7
    clean_tmp      3 7
    clean_journal  4 7
    clean_thumbs   5 7
    clean_snaps    6 7
    step 7 7 "Updating file locate database..."
    updatedb 2>/dev/null || true
    ok "locate DB updated."
    local d_after; d_after=$(disk_free_mb)
    echo
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  DEEP CLEAN COMPLETE                                  ║"
    printf "  ║  %-52s  ║\n" "Approx. disk space reclaimed: ~$(( d_after - d_before )) MB"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ── Preview ───────────────────────────────────────────────────────────
preview() {
    clear
    echo -e "${BOLD}${CYAN}  PREVIEW — Sizes before cleaning${NC}"
    echo -e "  ${DASH}\n"
    printf "  %-45s %s\n" "Target" "Size (MB)"
    echo -e "  ${DASH}"
    for t in "${REAL_HOME}/.cache" "/tmp" "/var/tmp" "${REAL_HOME}/.cache/thumbnails"; do
        printf "  %-45s %s MB\n" "$t" "$(folder_mb "$t")"
    done
    local apt_mb; apt_mb=$(du -sm /var/cache/apt/archives 2>/dev/null | awk '{print $1}' || echo 0)
    printf "  %-45s %s MB\n" "/var/cache/apt/archives" "$apt_mb"
    local jrnl_mb; jrnl_mb=$(folder_mb "/var/log/journal")
    printf "  %-45s %s MB\n" "/var/log/journal" "$jrnl_mb"
    echo -e "  ${DASH}"
    echo -e "  Current disk free on /: $(df -h / 2>/dev/null | awk 'NR==2{print $4}') available"
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_clean ;;
        2) confirm "Run apt autoremove + clean?" && clean_apt 1 1; echo; read -rp "  Press Enter..." ;;
        3) confirm "Clear ~/.cache?" && clean_user_cache 1 1; echo; read -rp "  Press Enter..." ;;
        4) confirm "Delete temp files older than 3 days?" && clean_tmp 1 1; echo; read -rp "  Press Enter..." ;;
        5) confirm "Vacuum systemd journal?" && clean_journal 1 1; echo; read -rp "  Press Enter..." ;;
        6) confirm "Delete thumbnail cache?" && clean_thumbs 1 1; echo; read -rp "  Press Enter..." ;;
        7) confirm "Remove old snap revisions?" && clean_snaps 1 1; echo; read -rp "  Press Enter..." ;;
        8) preview; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
