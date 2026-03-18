#!/usr/bin/env bash
# ============================================================
# Name      : gatekeeper_check.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required  (some checks need sudo for full results)
# Reversible: Yes  (read-only, no changes made)
# Desc      : Reports Gatekeeper and SIP status. Lists
#             quarantined files via xattr. Shows recently added
#             Launch Agents and Daemons. Checks code signatures
#             on running processes.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         GATEKEEPER CHECK  v1.0.0                     ║"
    echo "  ║     Gatekeeper · SIP · Quarantine · Launch Agents    ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Security Check  (all sections)"
    echo -e "  ${BOLD}[2]${NC}  Gatekeeper Status"
    echo -e "  ${BOLD}[3]${NC}  System Integrity Protection (SIP) Status"
    echo -e "  ${BOLD}[4]${NC}  Quarantined Files"
    echo -e "  ${BOLD}[5]${NC}  Launch Agents and Daemons  (recent additions)"
    echo -e "  ${BOLD}[6]${NC}  Verify an App's Code Signature"
    echo -e "  ${BOLD}[7]${NC}  Export Security Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_gatekeeper() {
    echo -e "\n  ${BOLD}GATEKEEPER STATUS${NC}"
    echo -e "  ${DASH}"
    local state; state=$(spctl --status 2>/dev/null || echo "unknown")
    if echo "$state" | grep -q "enabled"; then
        echo -e "  Gatekeeper: ${GREEN}${BOLD}ENABLED${NC}"
        echo -e "  ${GREEN}[OK]${NC} Only apps from App Store and identified developers are allowed."
    else
        echo -e "  Gatekeeper: ${RED}${BOLD}DISABLED${NC}"
        echo -e "  ${RED}[WARN]${NC} All apps are allowed regardless of source."
        echo -e "  To re-enable: ${BOLD}sudo spctl --master-enable${NC}"
    fi
    echo
    echo -e "  Current assessment policy:"
    spctl --status 2>/dev/null | sed 's/^/  /'
    echo
}

check_sip() {
    echo -e "\n  ${BOLD}SYSTEM INTEGRITY PROTECTION (SIP)${NC}"
    echo -e "  ${DASH}"
    local sip_state; sip_state=$(csrutil status 2>/dev/null || echo "unknown")
    if echo "$sip_state" | grep -q "enabled"; then
        echo -e "  SIP: ${GREEN}${BOLD}ENABLED${NC}"
        echo -e "  ${GREEN}[OK]${NC} System files are protected from modification."
    else
        echo -e "  SIP: ${RED}${BOLD}DISABLED OR PARTIALLY DISABLED${NC}"
        echo -e "  ${RED}[WARN]${NC} System files can be modified. This increases security risk."
        echo -e "  To re-enable: Boot to Recovery Mode > Terminal > ${BOLD}csrutil enable${NC}"
    fi
    echo -e "\n  Full status:"
    echo "$sip_state" | sed 's/^/  /'
    echo
}

check_quarantine() {
    echo -e "\n  ${BOLD}QUARANTINED FILES${NC}"
    echo -e "  ${DASH}"
    echo -e "  Scanning ~/Downloads and ~/Desktop for quarantine flags..."
    echo -e "  (Files downloaded from the internet are quarantined by default)\n"

    local count=0
    for dir in "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents"; do
        [[ ! -d "$dir" ]] && continue
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local qval; qval=$(xattr -p com.apple.quarantine "$file" 2>/dev/null || echo "")
            if [[ -n "$qval" ]]; then
                count=$(( count + 1 ))
                local modified; modified=$(stat -f "%Sm" -t "%Y-%m-%d" "$file" 2>/dev/null || echo "N/A")
                printf "  %-12s %s\n" "[$modified]" "$file"
            fi
        done < <(find "$dir" -maxdepth 2 -type f 2>/dev/null)
    done

    echo
    if [[ $count -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} No quarantined files found in common locations."
    else
        echo -e "  Found ${BOLD}${count}${NC} quarantined file(s)."
        echo -e "  ${CYAN}Tip:${NC} Quarantine is normal for downloaded files."
        echo -e "  Only investigate if you see unexpected or unfamiliar files."
    fi
    echo
}

check_launch_agents() {
    echo -e "\n  ${BOLD}LAUNCH AGENTS AND DAEMONS${NC}"
    echo -e "  ${DASH}"
    echo -e "  Showing items added or modified in the last 30 days:\n"

    local locations=(
        "$HOME/Library/LaunchAgents"
        "/Library/LaunchAgents"
        "/Library/LaunchDaemons"
        "/System/Library/LaunchAgents"
        "/System/Library/LaunchDaemons"
    )

    local found_recent=0
    for loc in "${locations[@]}"; do
        [[ ! -d "$loc" ]] && continue
        local recent_items
        recent_items=$(find "$loc" -name "*.plist" -mtime -30 2>/dev/null | head -20)
        if [[ -n "$recent_items" ]]; then
            echo -e "  ${BOLD}$loc${NC}"
            echo "$recent_items" | while read -r item; do
                local mod; mod=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$item" 2>/dev/null || echo "")
                printf "  %-22s %s\n" "[$mod]" "$(basename "$item")"
                found_recent=1
            done
            echo
        fi
    done

    echo -e "\n  ${BOLD}ALL USER LAUNCH AGENTS:${NC}"
    ls -la "$HOME/Library/LaunchAgents" 2>/dev/null | awk 'NR>1{print "  "$0}' | head -20
    echo
    echo -e "  ${BOLD}ALL SYSTEM LAUNCH AGENTS:${NC}"
    ls /Library/LaunchAgents 2>/dev/null | sed 's/^/  /' | head -20
    echo
    echo -e "  ${CYAN}Tip:${NC} Any Launch Agent/Daemon added by unknown software should be investigated."
    echo -e "  Legitimate macOS apps install these in /Library or ~/Library/LaunchAgents."
    echo
}

verify_signature() {
    echo
    printf "  Enter app path to verify (e.g. /Applications/Safari.app): "
    read -r app_path
    [[ -z "$app_path" ]] && return
    [[ ! -e "$app_path" ]] && echo -e "  ${RED}[ERROR]${NC} Path not found." && return

    echo
    echo -e "  ${BOLD}Code Signature:${NC}"
    codesign --verify --verbose=4 "$app_path" 2>&1 | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Gatekeeper Assessment:${NC}"
    spctl --assess --verbose "$app_path" 2>&1 | sed 's/^/  /'
    echo
    echo -e "  ${BOLD}Signing Details:${NC}"
    codesign -dv "$app_path" 2>&1 | sed 's/^/  /'
    echo
}

full_check() {
    clear
    echo -e "${BOLD}${CYAN}  FULL SECURITY CHECK${NC}"
    echo -e "  ${DASH}"
    check_gatekeeper
    check_sip
    check_quarantine
    check_launch_agents
}

export_report() {
    local rpt="$HOME/Desktop/SecurityCheck_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  GATEKEEPER SECURITY CHECK REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        echo "[GATEKEEPER]"
        spctl --status 2>/dev/null
        echo
        echo "[SIP]"
        csrutil status 2>/dev/null
        echo
        echo "[LAUNCH AGENTS - User]"
        ls -la "$HOME/Library/LaunchAgents" 2>/dev/null
        echo
        echo "[LAUNCH AGENTS - System]"
        ls -la /Library/LaunchAgents 2>/dev/null
        echo
        echo "[LAUNCH DAEMONS - System]"
        ls -la /Library/LaunchDaemons 2>/dev/null
        echo
        echo "[RUNNING PROCESSES - code sign check sample]"
        ps -axo pid,comm | head -30 | while read -r pid cmd; do
            [[ -z "$cmd" ]] && continue
            local sig; sig=$(codesign -d "$cmd" 2>/dev/null | grep "Authority" | head -1 || echo "no signature")
            printf "PID %-8s %-40s %s\n" "$pid" "$cmd" "$sig"
        done
        echo
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved to Desktop: $(basename "$rpt")"
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) full_check;         read -rp "  Press Enter..." ;;
        2) check_gatekeeper;   read -rp "  Press Enter..." ;;
        3) check_sip;          read -rp "  Press Enter..." ;;
        4) check_quarantine;   read -rp "  Press Enter..." ;;
        5) check_launch_agents;read -rp "  Press Enter..." ;;
        6) verify_signature;   read -rp "  Press Enter..." ;;
        7) export_report;      read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
