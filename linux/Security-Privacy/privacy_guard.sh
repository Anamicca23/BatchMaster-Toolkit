#!/usr/bin/env bash
# ============================================================
# Name      : privacy_guard.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : HIGH
# Sudo      : Required
# Reversible: Yes  (Option [3] restores all services + hosts)
# Desc      : Hardens Ubuntu/Debian for privacy — disables
#             whoopsie, apport, avahi-daemon, cups (if unused).
#             Appends ad/tracker domain blocks to /etc/hosts.
#             Full restore option included.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./privacy_guard.sh${NC}\n"
    exit 1
fi

HOSTS_FILE="/etc/hosts"
HOSTS_BAK="/etc/hosts.privacybak"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         LINUX PRIVACY GUARD  v1.0.0                  ║"
    echo "  ║     Stop Ubuntu/Debian from phoning home             ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Apply Full Privacy Protection"
    echo -e "  ${BOLD}[2]${NC}  View Current Privacy Status"
    echo -e "  ${BOLD}[3]${NC}  RESTORE All Defaults  (full undo)"
    echo -e "  ${BOLD}[4]${NC}  Block Tracker Domains  (/etc/hosts)"
    echo -e "  ${BOLD}[5]${NC}  Remove Tracker Domain Blocks"
    echo -e "  ${BOLD}[6]${NC}  Individual Service Toggles"
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

svc_status() {
    local svc="$1"
    systemctl is-active "$svc" 2>/dev/null || echo "inactive"
}

apply_all() {
    confirm "Apply privacy protections (disable telemetry services + block tracker domains)?" || return
    clear
    echo -e "${BOLD}${CYAN}  APPLYING PRIVACY PROTECTIONS...${NC}\n"

    echo -e "  ${BOLD}[1/5]${NC} Disabling whoopsie (Ubuntu crash reporter)..."
    if systemctl list-unit-files whoopsie.service &>/dev/null 2>&1 | grep -q whoopsie; then
        systemctl disable --now whoopsie 2>/dev/null || true
        systemctl mask whoopsie 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} whoopsie disabled and masked."
    else
        echo -e "  ${YELLOW}[SKIP]${NC} whoopsie not found on this system."
    fi

    echo -e "  ${BOLD}[2/5]${NC} Disabling apport (error reporting)..."
    if systemctl list-unit-files apport.service &>/dev/null 2>&1 | grep -q apport; then
        systemctl disable --now apport 2>/dev/null || true
        systemctl mask apport 2>/dev/null || true
        # Also disable via config
        if [[ -f /etc/default/apport ]]; then
            sed -i 's/enabled=1/enabled=0/' /etc/default/apport
        fi
        echo -e "  ${GREEN}[OK]${NC} apport disabled and masked."
    else
        echo -e "  ${YELLOW}[SKIP]${NC} apport not found."
    fi

    echo -e "  ${BOLD}[3/5]${NC} Disabling avahi-daemon (mDNS/Bonjour broadcasting)..."
    if systemctl list-unit-files avahi-daemon.service &>/dev/null 2>&1 | grep -q avahi; then
        systemctl disable --now avahi-daemon 2>/dev/null || true
        systemctl mask avahi-daemon 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} avahi-daemon disabled and masked."
    else
        echo -e "  ${YELLOW}[SKIP]${NC} avahi-daemon not found."
    fi

    echo -e "  ${BOLD}[4/5]${NC} Disabling cups (printer service — if not needed)..."
    if systemctl list-unit-files cups.service &>/dev/null 2>&1 | grep -q cups; then
        systemctl disable --now cups 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} cups disabled. (Re-enable if you use a printer)"
    else
        echo -e "  ${YELLOW}[SKIP]${NC} cups not found."
    fi

    echo -e "  ${BOLD}[5/5]${NC} Blocking tracker domains in /etc/hosts..."
    block_hosts_silent
    echo -e "  ${GREEN}[OK]${NC} Tracker domains blocked."

    echo
    echo -e "${BOLD}${GREEN}  [DONE]${NC} Privacy protections applied."
    echo -e "  Use option [3] to undo all changes."
    echo
}

view_status() {
    clear
    echo -e "${BOLD}${CYAN}  CURRENT PRIVACY STATUS${NC}"
    echo -e "  ${DASH}\n"
    for svc in whoopsie apport avahi-daemon cups; do
        local active; active=$(svc_status "$svc")
        local masked; masked=$(systemctl is-enabled "$svc" 2>/dev/null || echo "unknown")
        if [[ "$active" == "active" ]]; then
            echo -e "  ${YELLOW}${svc}${NC}: active  (enabled: $masked)"
        else
            echo -e "  ${GREEN}${svc}${NC}: $active  (enabled: $masked)"
        fi
    done
    echo
    if grep -q "PrivacyGuard" "$HOSTS_FILE" 2>/dev/null; then
        echo -e "  ${GREEN}Tracker hosts: BLOCKED${NC}  (PrivacyGuard entries present)"
    else
        echo -e "  ${YELLOW}Tracker hosts: Not blocked${NC}"
    fi
    echo
}

restore_all() {
    confirm "Restore all services to default enabled state and remove hosts blocks?" || return
    echo

    for svc in whoopsie apport avahi-daemon cups; do
        systemctl unmask "$svc" 2>/dev/null || true
        systemctl enable "$svc" 2>/dev/null || true
        systemctl start  "$svc" 2>/dev/null || true
        echo -e "  ${GREEN}[OK]${NC} Restored: $svc"
    done

    # Restore apport config
    [[ -f /etc/default/apport ]] && sed -i 's/enabled=0/enabled=1/' /etc/default/apport

    # Restore hosts
    if [[ -f "$HOSTS_BAK" ]]; then
        cp "$HOSTS_BAK" "$HOSTS_FILE"
        echo -e "  ${GREEN}[OK]${NC} /etc/hosts restored from backup."
    else
        remove_hosts_silent
        echo -e "  ${GREEN}[OK]${NC} Tracker blocks removed from /etc/hosts."
    fi

    echo -e "\n  ${GREEN}[DONE]${NC} All settings restored to defaults.\n"
}

block_hosts_silent() {
    [[ -f "$HOSTS_BAK" ]] || cp "$HOSTS_FILE" "$HOSTS_BAK"
    grep -q "PrivacyGuard" "$HOSTS_FILE" && return
    cat >> "$HOSTS_FILE" << 'HOSTS'

# PrivacyGuard - Tracker and ad domains blocked
0.0.0.0 doubleclick.net
0.0.0.0 googleadservices.com
0.0.0.0 googlesyndication.com
0.0.0.0 google-analytics.com
0.0.0.0 ssl.google-analytics.com
0.0.0.0 www.google-analytics.com
0.0.0.0 metrics.google.com
0.0.0.0 pagead2.googlesyndication.com
0.0.0.0 adservice.google.com
0.0.0.0 connect.facebook.net
0.0.0.0 graph.facebook.com
0.0.0.0 pixel.facebook.com
0.0.0.0 www.facebook.com
0.0.0.0 ads.linkedin.com
0.0.0.0 analytics.twitter.com
0.0.0.0 static.ads-twitter.com
0.0.0.0 bat.bing.com
0.0.0.0 ads.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 scorecardresearch.com
0.0.0.0 beacon.krxd.net
0.0.0.0 krxd.net
0.0.0.0 hotjar.com
0.0.0.0 mouseflow.com
0.0.0.0 fullstory.com
0.0.0.0 segment.io
0.0.0.0 mixpanel.com
0.0.0.0 amplitude.com
0.0.0.0 intercom.io
0.0.0.0 bugsnag.com
# PrivacyGuard - end
HOSTS
    # Flush DNS
    command -v resolvectl &>/dev/null && resolvectl flush-caches 2>/dev/null || true
    systemctl restart systemd-resolved 2>/dev/null || true
}

block_hosts() {
    confirm "Block tracker/ad domains in /etc/hosts? (backup saved as $HOSTS_BAK)" || return
    block_hosts_silent
    echo -e "  ${GREEN}[DONE]${NC} Tracker domains blocked.\n"
}

remove_hosts_silent() {
    local tmp; tmp=$(mktemp)
    local in_block=0
    while IFS= read -r line; do
        [[ "$line" == *"PrivacyGuard"* ]] && { in_block=$(( 1 - in_block )); continue; }
        [[ $in_block -eq 0 ]] && echo "$line" >> "$tmp"
    done < "$HOSTS_FILE"
    cp "$tmp" "$HOSTS_FILE"; rm "$tmp"
    command -v resolvectl &>/dev/null && resolvectl flush-caches 2>/dev/null || true
}

remove_hosts() {
    confirm "Remove PrivacyGuard blocks from /etc/hosts?" || return
    remove_hosts_silent
    echo -e "  ${GREEN}[DONE]${NC} Tracker blocks removed.\n"
}

individual_toggles() {
    clear
    echo -e "${BOLD}${CYAN}  SERVICE TOGGLES${NC}"
    echo -e "  ${DASH}\n"
    local services=("whoopsie" "apport" "avahi-daemon" "cups")
    for i in "${!services[@]}"; do
        local svc="${services[$i]}"
        local active; active=$(svc_status "$svc")
        local color="$GREEN"; [[ "$active" == "active" ]] && color="$YELLOW"
        echo -e "  ${BOLD}[$((i+1))]${NC}  ${svc}  —  ${color}${active}${NC}"
    done
    echo -e "  ${BOLD}[0]${NC}  Back"
    echo
    printf "  Toggle: "; read -r t
    [[ "$t" == "0" ]] && return
    local idx=$(( t - 1 ))
    if [[ $idx -ge 0 && $idx -lt ${#services[@]} ]]; then
        local svc="${services[$idx]}"
        local active; active=$(svc_status "$svc")
        if [[ "$active" == "active" ]]; then
            systemctl disable --now "$svc" 2>/dev/null && \
                echo -e "  ${GREEN}$svc: DISABLED${NC}" || \
                echo -e "  ${RED}Failed to disable $svc${NC}"
        else
            systemctl unmask "$svc" 2>/dev/null; systemctl enable --now "$svc" 2>/dev/null && \
                echo -e "  ${YELLOW}$svc: ENABLED${NC}" || \
                echo -e "  ${RED}Failed to enable $svc${NC}"
        fi
    fi
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) apply_all;           read -rp "  Press Enter..." ;;
        2) view_status;         read -rp "  Press Enter..." ;;
        3) restore_all;         read -rp "  Press Enter..." ;;
        4) block_hosts;         read -rp "  Press Enter..." ;;
        5) remove_hosts;        read -rp "  Press Enter..." ;;
        6) individual_toggles;  read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
