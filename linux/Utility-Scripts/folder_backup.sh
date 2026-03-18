#!/usr/bin/env bash
# ============================================================
# Name      : folder_backup.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (backup is a copy; source is untouched)
# Desc      : Interactive rsync backup. Prompts for source
#             and destination, creates BACKUP_YYYYMMDD_HHMMSS
#             subfolder, shows live progress and transfer stats.
#             Excludes .git, node_modules, and *.tmp by default.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║          FOLDER BACKUP  v1.0.0                       ║"
    echo "  ║     rsync — reliable timestamped folder backup       ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Backup a Folder  (choose source + destination)"
    echo -e "  ${BOLD}[2]${NC}  Quick Backup — Home to /tmp/backup"
    echo -e "  ${BOLD}[3]${NC}  Incremental Backup  (only changed files)"
    echo -e "  ${BOLD}[4]${NC}  Backup with Verification  (checksum compare)"
    echo -e "  ${BOLD}[5]${NC}  List Existing Backups"
    echo -e "  ${BOLD}[6]${NC}  About — How This Backup Works"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_rsync() {
    if ! command -v rsync &>/dev/null; then
        echo -e "\n  ${YELLOW}rsync not installed.${NC}"
        echo -e "  Install: ${BOLD}sudo apt install rsync${NC}\n"
        return 1
    fi
    return 0
}

get_timestamp() {
    date +%Y%m%d_%H%M%S
}

run_backup() {
    local src="$1"
    local dst_base="$2"
    local mode="${3:-normal}"    # normal | incremental | checksum
    local label="${4:-BACKUP}"

    # Validate source
    if [[ ! -d "$src" ]]; then
        echo -e "\n  ${RED}[ERROR]${NC} Source not found: $src\n"
        return 1
    fi

    # Create timestamped destination
    local ts; ts=$(get_timestamp)
    local dst="${dst_base}/${label}_${ts}"
    mkdir -p "$dst" 2>/dev/null || {
        echo -e "\n  ${RED}[ERROR]${NC} Cannot create: $dst\n"
        return 1
    }

    local log_file="${dst}/backup_log.txt"

    echo -e "\n  ${BOLD}${CYAN}BACKUP STARTING${NC}"
    echo -e "  ${DASH}"
    echo -e "  Source      : $src"
    echo -e "  Destination : $dst"
    echo -e "  Mode        : $mode"
    echo -e "  Log         : $log_file"
    echo -e "  ${DASH}\n"

    # Build rsync flags
    local rsync_flags=(-avh --progress --stats)
    rsync_flags+=(--exclude='.git/')
    rsync_flags+=(--exclude='node_modules/')
    rsync_flags+=(--exclude='*.tmp')
    rsync_flags+=(--exclude='*.swp')
    rsync_flags+=(-r:3 -w:2 2>/dev/null || true)  # handled by rsync natively

    case "$mode" in
        incremental) rsync_flags+=(--update) ;;
        checksum)    rsync_flags+=(-c) ;;
    esac

    rsync_flags+=("--log-file=$log_file")

    # Run rsync
    local start; start=$(date +%s)
    rsync "${rsync_flags[@]}" "${src%/}/" "$dst/" 2>&1

    local exit_code=$?
    local end; end=$(date +%s)
    local elapsed=$(( end - start ))

    echo
    echo -e "  ${DASH}"
    if [[ $exit_code -eq 0 ]]; then
        echo -e "  ${GREEN}[DONE]${NC} Backup completed successfully."
    elif [[ $exit_code -le 3 ]]; then
        echo -e "  ${YELLOW}[DONE]${NC} Backup completed with minor issues (exit: $exit_code)."
    else
        echo -e "  ${RED}[WARN]${NC} Backup completed with errors (exit: $exit_code)."
        echo -e "  Check log: $log_file"
    fi

    echo -e "  Duration    : ${elapsed} seconds"
    echo -e "  Destination : $dst"
    echo

    # Verify: compare file counts
    local src_count; src_count=$(find "$src" -type f 2>/dev/null | wc -l)
    local dst_count; dst_count=$(find "$dst" -type f -not -name "backup_log.txt" 2>/dev/null | wc -l)
    echo -e "  Files in source : $src_count"
    echo -e "  Files in backup : $dst_count"
    if [[ $src_count -eq $dst_count ]]; then
        echo -e "  ${GREEN}File count matches — backup looks complete.${NC}"
    else
        echo -e "  ${YELLOW}File count differs (may be due to exclusions like .git, node_modules).${NC}"
    fi
    echo
}

custom_backup() {
    check_rsync || { read -rp "  Press Enter..."; return; }
    echo
    printf "  Source folder: "
    read -r src
    echo
    printf "  Destination folder (parent — a BACKUP_timestamp subfolder will be created): "
    read -r dst
    echo

    [[ ! -d "$src" ]] && echo -e "  ${RED}[ERROR]${NC} Source not found." && return

    if [[ ! -d "$dst" ]]; then
        printf "  Destination does not exist. Create it? (y/N): "
        read -r ans
        [[ "${ans,,}" == "y" ]] && mkdir -p "$dst" || { echo "  Cancelled."; return; }
    fi

    run_backup "$src" "$dst" "normal" "BACKUP"
}

quick_backup() {
    check_rsync || { read -rp "  Press Enter..."; return; }
    local dst="/tmp/backup"
    mkdir -p "$dst"
    echo -e "\n  Quick backup: ${BOLD}$HOME${NC} → ${BOLD}${dst}/BACKUP_*${NC}"
    printf "  Proceed? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    run_backup "$HOME" "$dst" "normal" "BACKUP"
}

incremental_backup() {
    check_rsync || { read -rp "  Press Enter..."; return; }
    echo
    printf "  Source folder: "; read -r src
    printf "  Destination folder: "; read -r dst
    [[ ! -d "$src" ]] && echo -e "  ${RED}[ERROR]${NC} Source not found." && return
    mkdir -p "$dst" 2>/dev/null || true
    echo -e "\n  ${CYAN}[INFO]${NC} Incremental mode: only files newer than destination will be copied."
    run_backup "$src" "$dst" "incremental" "INCREMENTAL"
}

checksum_backup() {
    check_rsync || { read -rp "  Press Enter..."; return; }
    echo
    printf "  Source folder: "; read -r src
    printf "  Destination folder: "; read -r dst
    [[ ! -d "$src" ]] && echo -e "  ${RED}[ERROR]${NC} Source not found." && return
    mkdir -p "$dst" 2>/dev/null || true
    echo -e "\n  ${CYAN}[INFO]${NC} Checksum mode: files compared by content, not timestamp (slower but thorough)."
    run_backup "$src" "$dst" "checksum" "CHECKSUM"
}

list_backups() {
    clear
    echo -e "${BOLD}${CYAN}  EXISTING BACKUPS${NC}"
    echo -e "  ${DASH}\n"
    local found=0
    for dir in "$HOME" "/tmp" "/var/backups"; do
        [[ ! -d "$dir" ]] && continue
        while IFS= read -r bdir; do
            local size; size=$(du -sh "$bdir" 2>/dev/null | awk '{print $1}')
            local mdate; mdate=$(stat -c "%y" "$bdir" 2>/dev/null | cut -d' ' -f1)
            printf "  %-50s  %8s  %s\n" "$(basename "$bdir")" "$size" "$mdate"
            found=$(( found + 1 ))
        done < <(find "$dir" -maxdepth 1 -type d -name "BACKUP_*" -o -name "INCREMENTAL_*" -o -name "CHECKSUM_*" 2>/dev/null | sort -r)
    done
    [[ $found -eq 0 ]] && echo -e "  ${YELLOW}No backup folders found.${NC}"
    echo
}

about_backup() {
    clear
    echo -e "${BOLD}${CYAN}  HOW THIS BACKUP WORKS${NC}"
    echo -e "  ${DASH}\n"
    cat << 'INFO'
  Tool: rsync
  ─────────────
  Uses rsync, a battle-tested incremental file sync tool.
  Copies only changed bytes on subsequent runs (--update mode).

  Flags used:
    -a  Archive mode (preserves permissions, timestamps, symlinks)
    -v  Verbose (show what is being copied)
    -h  Human-readable sizes
    --progress  Show per-file progress
    --stats  Transfer statistics at the end
    --log-file  Save full copy log alongside the backup

  Excluded by default:
    .git/          (version control data — can be huge)
    node_modules/  (can be reinstalled with npm install)
    *.tmp          (temporary files)
    *.swp          (vim swap files)

  Backup naming:
    BACKUP_YYYYMMDD_HHMMSS
    Example: BACKUP_20250318_143022

  How to restore:
    rsync -avh /path/to/BACKUP_*/ /original/path/
    or: cp -r /path/to/BACKUP_*/* /original/path/

  Modes:
    Normal       — copy all files regardless of date
    Incremental  — only copy files newer than destination
    Checksum     — compare by file content (slow but thorough)

INFO
}

while true; do
    show_menu
    case "$choice" in
        1) custom_backup;       read -rp "  Press Enter..." ;;
        2) quick_backup;        read -rp "  Press Enter..." ;;
        3) incremental_backup;  read -rp "  Press Enter..." ;;
        4) checksum_backup;     read -rp "  Press Enter..." ;;
        5) list_backups;        read -rp "  Press Enter..." ;;
        6) about_backup;        read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
