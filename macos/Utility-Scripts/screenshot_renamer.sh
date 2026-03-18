#!/usr/bin/env bash
# ============================================================
# Name      : screenshot_renamer.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (files are renamed, originals preserved)
# Desc      : Watches ~/Desktop (or configured Screenshots
#             folder) and auto-renames new screenshots from
#             "Screenshot YYYY-MM-DD at HH.MM.SS.png" format
#             to clean YYYYMMDD_HHMMSS_screenshot.png format.
#             Also archives screenshots to ~/Pictures/Screenshots.
#             Requires fswatch (brew install fswatch).
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

# Default screenshot location (macOS default is Desktop)
WATCH_DIR="$HOME/Desktop"
ARCHIVE_DIR="$HOME/Pictures/Screenshots"
DAEMON_PID_FILE="$HOME/.screenshot_renamer.pid"
DAEMON_LOG="$HOME/.screenshot_renamer.log"

show_menu() {
    local status="STOPPED"
    local status_color="$RED"
    if [[ -f "$DAEMON_PID_FILE" ]]; then
        local pid; pid=$(cat "$DAEMON_PID_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            status="RUNNING  (PID: $pid)"
            status_color="$GREEN"
        fi
    fi

    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       SCREENSHOT RENAMER  v1.0.0                     ║"
    echo "  ║     Auto-rename + archive macOS screenshots          ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Daemon Status: ${status_color}${BOLD}${status}${NC}"
    echo -e "  Watch Folder:  ${WATCH_DIR}"
    echo -e "  Archive Folder: ${ARCHIVE_DIR}"
    echo
    echo -e "  ${BOLD}[1]${NC}  Start Daemon  (background watcher)"
    echo -e "  ${BOLD}[2]${NC}  Stop Daemon"
    echo -e "  ${BOLD}[3]${NC}  Rename Existing Screenshots Now  (one-time batch)"
    echo -e "  ${BOLD}[4]${NC}  Archive Screenshots to ~/Pictures/Screenshots"
    echo -e "  ${BOLD}[5]${NC}  Change Watch Folder"
    echo -e "  ${BOLD}[6]${NC}  View Daemon Log"
    echo -e "  ${BOLD}[7]${NC}  Change macOS Screenshot Save Location"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_fswatch() {
    if ! command -v fswatch &>/dev/null; then
        echo -e "\n  ${YELLOW}[INFO]${NC} fswatch is required for the daemon."
        echo -e "  Install with: ${BOLD}brew install fswatch${NC}"
        echo
        return 1
    fi
    return 0
}

rename_screenshot() {
    local filepath="$1"
    local filename; filename=$(basename "$filepath")
    local dir; dir=$(dirname "$filepath")

    # Match: Screenshot YYYY-MM-DD at HH.MM.SS.png or .jpg
    if [[ "$filename" =~ ^Screenshot\ ([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]{2}\.[0-9]{2}\.[0-9]{2})\.(png|jpg|jpeg)$ ]]; then
        local date_part="${BASH_REMATCH[1]//\-/}"
        local time_part="${BASH_REMATCH[2]//\./}"
        local ext="${BASH_REMATCH[3]}"
        local newname="${date_part}_${time_part}_screenshot.${ext}"
        local newpath="${dir}/${newname}"

        if [[ ! -f "$newpath" ]]; then
            mv "$filepath" "$newpath" 2>/dev/null
            echo "[$(date '+%H:%M:%S')] Renamed: $filename --> $newname" >> "$DAEMON_LOG"
            echo -e "  ${GREEN}[RENAMED]${NC} $filename  →  $newname"
        fi
    fi
}

start_daemon() {
    check_fswatch || { read -rp "  Press Enter..."; return; }

    # Check if already running
    if [[ -f "$DAEMON_PID_FILE" ]]; then
        local pid; pid=$(cat "$DAEMON_PID_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "\n  ${YELLOW}[INFO]${NC} Daemon is already running (PID: $pid)"
            read -rp "  Press Enter..."; return
        fi
    fi

    echo -e "\n  Starting screenshot watcher daemon..."
    mkdir -p "$ARCHIVE_DIR" 2>/dev/null

    # Write daemon script to temp file
    local daemon_script; daemon_script=$(mktemp /tmp/screenshot_daemon_XXXXXX.sh)
    cat > "$daemon_script" << DAEMON_BODY
#!/usr/bin/env bash
WATCH_DIR="$WATCH_DIR"
ARCHIVE_DIR="$ARCHIVE_DIR"
DAEMON_LOG="$DAEMON_LOG"
echo "[$(date)] Screenshot Renamer daemon started. Watching: \$WATCH_DIR" >> "\$DAEMON_LOG"
fswatch -0 -e ".*" -i "Screenshot.*\\.png\$" -i "Screenshot.*\\.jpg\$" "\$WATCH_DIR" 2>/dev/null | \
    while IFS= read -r -d "" filepath; do
        filename=\$(basename "\$filepath")
        dir=\$(dirname "\$filepath")
        if [[ "\$filename" =~ ^Screenshot[[:space:]]([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]at[[:space:]]([0-9]{2}\.[0-9]{2}\.[0-9]{2})\.(png|jpg|jpeg)$ ]]; then
            date_part=\${BASH_REMATCH[1]//\-/}
            time_part=\${BASH_REMATCH[2]//\./}
            ext=\${BASH_REMATCH[3]}
            newname="\${date_part}_\${time_part}_screenshot.\${ext}"
            newpath="\${dir}/\${newname}"
            [[ ! -f "\$newpath" ]] && mv "\$filepath" "\$newpath" 2>/dev/null && \
                echo "[\$(date '+%H:%M:%S')] \$filename --> \$newname" >> "\$DAEMON_LOG"
        fi
        sleep 0.5
    done
DAEMON_BODY
    chmod +x "$daemon_script"

    nohup bash "$daemon_script" >> "$DAEMON_LOG" 2>&1 &
    local dpid=$!
    echo "$dpid" > "$DAEMON_PID_FILE"
    rm -f "$daemon_script"

    sleep 1
    if kill -0 "$dpid" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC} Daemon started (PID: $dpid)"
        echo -e "  Watching: $WATCH_DIR"
        echo -e "  Log file: $DAEMON_LOG"
    else
        echo -e "  ${RED}[ERROR]${NC} Daemon failed to start. Check: $DAEMON_LOG"
    fi
    echo
}

stop_daemon() {
    if [[ ! -f "$DAEMON_PID_FILE" ]]; then
        echo -e "\n  ${YELLOW}[INFO]${NC} No daemon PID file found."; echo; return
    fi
    local pid; pid=$(cat "$DAEMON_PID_FILE")
    if kill "$pid" 2>/dev/null; then
        echo -e "\n  ${GREEN}[OK]${NC} Daemon (PID: $pid) stopped."
        echo "[$(date)] Daemon stopped." >> "$DAEMON_LOG"
    else
        echo -e "\n  ${YELLOW}[INFO]${NC} Process $pid was not running."
    fi
    rm -f "$DAEMON_PID_FILE"
    echo
}

batch_rename() {
    echo -e "\n  Scanning $WATCH_DIR for screenshots to rename...\n"
    local count=0
    while IFS= read -r f; do
        rename_screenshot "$f"
        count=$(( count + 1 ))
    done < <(find "$WATCH_DIR" -maxdepth 1 -name "Screenshot *.png" -o \
             -name "Screenshot *.jpg" 2>/dev/null)

    if [[ $count -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} No unrenmed screenshots found."
    else
        echo -e "\n  ${GREEN}[DONE]${NC} Processed $count screenshot(s)."
    fi
    echo
}

archive_screenshots() {
    mkdir -p "$ARCHIVE_DIR"
    echo -e "\n  Archiving renamed screenshots to: $ARCHIVE_DIR\n"
    local count=0
    while IFS= read -r f; do
        local fname; fname=$(basename "$f")
        local dest="$ARCHIVE_DIR/$fname"
        if [[ ! -f "$dest" ]]; then
            cp "$f" "$dest" && echo -e "  ${GREEN}[COPIED]${NC} $fname" && count=$(( count + 1 ))
        else
            echo -e "  ${YELLOW}[EXISTS]${NC} $fname (skipped)"
        fi
    done < <(find "$WATCH_DIR" -maxdepth 1 -name "*_screenshot.png" -o \
             -name "*_screenshot.jpg" 2>/dev/null)

    echo
    [[ $count -eq 0 ]] && echo -e "  ${YELLOW}No new screenshots to archive.${NC}" || \
        echo -e "  ${GREEN}[DONE]${NC} Archived $count screenshot(s) to $ARCHIVE_DIR"
    echo
}

change_watch_folder() {
    echo
    printf "  Enter new watch folder path: "
    read -r new_path
    [[ ! -d "$new_path" ]] && echo -e "  ${RED}[ERROR]${NC} Folder not found." && return
    WATCH_DIR="$new_path"
    echo -e "  ${GREEN}[OK]${NC} Watch folder changed to: $WATCH_DIR"
    echo -e "  Restart the daemon for changes to take effect."
    echo
}

view_log() {
    clear
    echo -e "${BOLD}${CYAN}  DAEMON LOG${NC}"
    echo -e "  ${DASH}\n"
    if [[ -f "$DAEMON_LOG" ]]; then
        tail -40 "$DAEMON_LOG" | sed 's/^/  /'
    else
        echo -e "  ${YELLOW}No log file found.${NC}"
        echo -e "  Start the daemon first to generate a log."
    fi
    echo
}

change_screenshot_location() {
    clear
    echo -e "${BOLD}${CYAN}  CHANGE macOS SCREENSHOT SAVE LOCATION${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  Current setting:"
    defaults read com.apple.screencapture location 2>/dev/null | sed 's/^/  /' || \
        echo "  (default: ~/Desktop)"
    echo
    printf "  Enter new save path (or press Enter to reset to Desktop): "
    read -r new_loc
    if [[ -z "$new_loc" ]]; then
        defaults delete com.apple.screencapture location 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} Reset to default (~/Desktop)"
    elif [[ -d "$new_loc" ]]; then
        defaults write com.apple.screencapture location "$new_loc"
        killall SystemUIServer 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} Screenshot location changed to: $new_loc"
    else
        echo -e "  ${RED}[ERROR]${NC} Folder not found: $new_loc"
    fi
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) start_daemon;               read -rp "  Press Enter..." ;;
        2) stop_daemon;                read -rp "  Press Enter..." ;;
        3) batch_rename;               read -rp "  Press Enter..." ;;
        4) archive_screenshots;        read -rp "  Press Enter..." ;;
        5) change_watch_folder;        read -rp "  Press Enter..." ;;
        6) view_log;                   read -rp "  Press Enter..." ;;
        7) change_screenshot_location; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
