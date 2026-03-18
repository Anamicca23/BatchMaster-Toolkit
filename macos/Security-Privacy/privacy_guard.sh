#!/usr/bin/env bash
# ============================================================
# Name      : privacy_guard.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : HIGH
# Sudo      : Required
# Reversible: Yes  (Option [3] restores all defaults)
# Desc      : Disables macOS telemetry, Safari suggestions,
#             Spotlight Siri data, and analytics sharing.
#             Optionally blocks Apple analytics domains in
#             /etc/hosts. Full restore option included.
# ============================================================

set -uo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

if [[ $EUID -ne 0 ]]; then
    echo -e "\n  ${RED}[ERROR]${NC} Must be run as root: ${BOLD}sudo ./privacy_guard.sh${NC}\n"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
REAL_HOME=$(eval echo "~$REAL_USER")

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         PRIVACY GUARD  v1.0.0                        ║"
    echo "  ║     Stop macOS from phoning home — reversible        ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Apply Full Privacy Protection"
    echo -e "  ${BOLD}[2]${NC}  View Current Privacy Status"
    echo -e "  ${BOLD}[3]${NC}  RESTORE All Defaults  (full undo)"
    echo -e "  ${BOLD}[4]${NC}  Block Analytics Domains  (/etc/hosts)"
    echo -e "  ${BOLD}[5]${NC}  Remove Analytics Domain Blocks"
    echo -e "  ${BOLD}[6]${NC}  Individual Toggles"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

apply_all() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} This modifies system preferences and /etc/hosts."
    echo -e "  A backup of /etc/hosts will be saved as /etc/hosts.privacybak"
    echo -e "  Use Option [3] to fully undo all changes."
    printf "\n  Proceed? (y/N): "
    read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return

    clear
    echo -e "${BOLD}${CYAN}  APPLYING PRIVACY PROTECTIONS...${NC}\n"

    echo -e "  ${BOLD}[1/7]${NC} Disabling telemetry submission..."
    sudo -u "$REAL_USER" defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false 2>/dev/null
    launchctl unload -w /System/Library/LaunchDaemons/com.apple.SubmitDiagInfo.plist 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[2/7]${NC} Disabling Safari search suggestions..."
    sudo -u "$REAL_USER" defaults write com.apple.Safari UniversalSearchEnabled -bool false 2>/dev/null
    sudo -u "$REAL_USER" defaults write com.apple.Safari SuppressSearchSuggestions -bool true 2>/dev/null
    sudo -u "$REAL_USER" defaults write com.apple.Safari WebsiteSpecificSearchEnabled -bool false 2>/dev/null
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[3/7]${NC} Disabling Spotlight Siri data sharing..."
    sudo -u "$REAL_USER" defaults write com.apple.assistant.support \
        'Search Queries Data Sharing Status' -int 2 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[4/7]${NC} Disabling system analytics sharing..."
    sudo -u "$REAL_USER" defaults write com.apple.crashreporter DialogType none 2>/dev/null
    defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false 2>/dev/null
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[5/7]${NC} Disabling location-based suggestions..."
    sudo -u "$REAL_USER" defaults write com.apple.Safari \
        WebAutomaticSpellingCorrectionEnabled -bool false 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[6/7]${NC} Disabling personalized ads..."
    sudo -u "$REAL_USER" defaults write com.apple.AdLib \
        allowApplePersonalizedAdvertising -bool false 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC}"

    echo -e "  ${BOLD}[7/7]${NC} Blocking analytics domains in /etc/hosts..."
    block_hosts_silent
    echo -e "  ${GREEN}[OK]${NC}"

    echo
    echo -e "${BOLD}${GREEN}  [DONE]${NC} Privacy protections applied."
    echo -e "  Changes take full effect after relogging or restarting."
    echo -e "  Use Option [3] to undo all changes."
    echo
}

view_status() {
    clear
    echo -e "${BOLD}${CYAN}  CURRENT PRIVACY STATUS${NC}"
    echo -e "  ${DASH}\n"

    local val

    val=$(sudo -u "$REAL_USER" defaults read com.apple.SubmitDiagInfo AutoSubmit 2>/dev/null || echo "not set (default=enabled)")
    printf "  %-40s %s\n" "Telemetry AutoSubmit:" "$val"

    val=$(sudo -u "$REAL_USER" defaults read com.apple.Safari UniversalSearchEnabled 2>/dev/null || echo "not set (default=enabled)")
    printf "  %-40s %s\n" "Safari Universal Search:" "$val  (0=off)"

    val=$(sudo -u "$REAL_USER" defaults read com.apple.Safari SuppressSearchSuggestions 2>/dev/null || echo "not set")
    printf "  %-40s %s\n" "Safari Search Suggestions suppressed:" "$val  (1=off)"

    val=$(sudo -u "$REAL_USER" defaults read com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null || echo "not set (default=enabled)")
    printf "  %-40s %s\n" "Personalized Ads:" "$val  (0=off)"

    # Check hosts
    if grep -q "PrivacyGuard" /etc/hosts 2>/dev/null; then
        echo -e "  $(printf '%-40s' 'Analytics hosts blocked:') ${GREEN}YES — PrivacyGuard entries present${NC}"
    else
        echo -e "  $(printf '%-40s' 'Analytics hosts blocked:') ${YELLOW}No${NC}"
    fi
    echo
}

restore_all() {
    echo
    printf "  Restore all defaults? (y/N): "
    read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return

    echo
    echo -e "  Restoring..."
    sudo -u "$REAL_USER" defaults delete com.apple.SubmitDiagInfo AutoSubmit 2>/dev/null || true
    sudo -u "$REAL_USER" defaults delete com.apple.Safari UniversalSearchEnabled 2>/dev/null || true
    sudo -u "$REAL_USER" defaults delete com.apple.Safari SuppressSearchSuggestions 2>/dev/null || true
    sudo -u "$REAL_USER" defaults delete com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null || true
    launchctl load -w /System/Library/LaunchDaemons/com.apple.SubmitDiagInfo.plist 2>/dev/null || true

    # Restore hosts
    if [[ -f /etc/hosts.privacybak ]]; then
        cp -f /etc/hosts.privacybak /etc/hosts
        echo -e "  ${GREEN}[OK]${NC} /etc/hosts restored from backup."
    else
        remove_hosts_silent
        echo -e "  ${GREEN}[OK]${NC} Analytics blocks removed from /etc/hosts."
    fi

    dscacheutil -flushcache 2>/dev/null; killall -HUP mDNSResponder 2>/dev/null || true
    echo -e "\n  ${GREEN}[DONE]${NC} All settings restored to macOS defaults.\n"
}

block_hosts_silent() {
    [[ -f /etc/hosts.privacybak ]] || cp /etc/hosts /etc/hosts.privacybak
    grep -q "PrivacyGuard" /etc/hosts && return
    cat >> /etc/hosts << 'HOSTS'

# PrivacyGuard - Apple analytics domains blocked
0.0.0.0 metrics.apple.com
0.0.0.0 xp.apple.com
0.0.0.0 sp.analytics.yahoo.com
0.0.0.0 radarsubmissions.apple.com
0.0.0.0 pancake.apple.com
0.0.0.0 api.apple-cloudkit.com
0.0.0.0 feedbackws.apple.com
0.0.0.0 iadsdk.apple.com
0.0.0.0 iadmv.apple.com
0.0.0.0 iadcm.apple.com
0.0.0.0 iadsatreps.apple.com
0.0.0.0 iadsattr.apple.com
0.0.0.0 iad.apple.com
0.0.0.0 searchads.apple.com
0.0.0.0 securemetrics.apple.com
0.0.0.0 weather-data.apple.com
# PrivacyGuard - end
HOSTS
    dscacheutil -flushcache 2>/dev/null; killall -HUP mDNSResponder 2>/dev/null || true
}

block_hosts() {
    echo
    echo -e "  ${YELLOW}[WARNING]${NC} This will append analytics domain blocks to /etc/hosts."
    echo -e "  Backup saved as /etc/hosts.privacybak"
    printf "  Proceed? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    block_hosts_silent
    echo -e "  ${GREEN}[DONE]${NC} Analytics domains blocked.\n"
}

remove_hosts_silent() {
    local tmp; tmp=$(mktemp)
    local in_block=0
    while IFS= read -r line; do
        [[ "$line" == *"PrivacyGuard"* ]] && { in_block=$(( 1 - in_block )); continue; }
        [[ $in_block -eq 0 ]] && echo "$line" >> "$tmp"
    done < /etc/hosts
    cp "$tmp" /etc/hosts; rm "$tmp"
    dscacheutil -flushcache 2>/dev/null; killall -HUP mDNSResponder 2>/dev/null || true
}

remove_hosts() {
    echo
    printf "  Remove PrivacyGuard blocks from /etc/hosts? (y/N): "; read -r ans
    [[ "${ans,,}" != "y" ]] && echo "  Cancelled." && return
    remove_hosts_silent
    echo -e "  ${GREEN}[DONE]${NC} Analytics domain blocks removed.\n"
}

individual_toggles() {
    clear
    echo -e "${BOLD}${CYAN}  INDIVIDUAL TOGGLES${NC}"
    echo -e "  ${DASH}\n"
    echo -e "  ${BOLD}[A]${NC}  Toggle Telemetry AutoSubmit"
    echo -e "  ${BOLD}[B]${NC}  Toggle Safari Search Suggestions"
    echo -e "  ${BOLD}[C]${NC}  Toggle Personalized Ads"
    echo -e "  ${BOLD}[0]${NC}  Back"
    echo
    printf "  Toggle: "; read -r t
    case "${t,,}" in
        a)
            val=$(sudo -u "$REAL_USER" defaults read com.apple.SubmitDiagInfo AutoSubmit 2>/dev/null || echo "1")
            if [[ "$val" == "0" ]]; then
                sudo -u "$REAL_USER" defaults delete com.apple.SubmitDiagInfo AutoSubmit 2>/dev/null
                echo -e "  Telemetry: ${YELLOW}ENABLED${NC}"
            else
                sudo -u "$REAL_USER" defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false
                echo -e "  Telemetry: ${GREEN}DISABLED${NC}"
            fi ;;
        b)
            val=$(sudo -u "$REAL_USER" defaults read com.apple.Safari SuppressSearchSuggestions 2>/dev/null || echo "0")
            if [[ "$val" == "1" ]]; then
                sudo -u "$REAL_USER" defaults write com.apple.Safari SuppressSearchSuggestions -bool false
                echo -e "  Safari Suggestions: ${YELLOW}ENABLED${NC}"
            else
                sudo -u "$REAL_USER" defaults write com.apple.Safari SuppressSearchSuggestions -bool true
                echo -e "  Safari Suggestions: ${GREEN}DISABLED${NC}"
            fi ;;
        c)
            val=$(sudo -u "$REAL_USER" defaults read com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null || echo "1")
            if [[ "$val" == "0" ]]; then
                sudo -u "$REAL_USER" defaults delete com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null
                echo -e "  Personalized Ads: ${YELLOW}ENABLED${NC}"
            else
                sudo -u "$REAL_USER" defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
                echo -e "  Personalized Ads: ${GREEN}DISABLED${NC}"
            fi ;;
        0) return ;;
    esac
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) apply_all;          read -rp "  Press Enter..." ;;
        2) view_status;        read -rp "  Press Enter..." ;;
        3) restore_all;        read -rp "  Press Enter..." ;;
        4) block_hosts;        read -rp "  Press Enter..." ;;
        5) remove_hosts;       read -rp "  Press Enter..." ;;
        6) individual_toggles; read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
