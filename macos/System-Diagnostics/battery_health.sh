#!/usr/bin/env bash
# ============================================================
# Name      : battery_health.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : macOS 13 Ventura, macOS 14 Sonoma
# Min OS    : macOS 12 Monterey
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (read-only, no changes made)
# Desc      : Reads battery cycle count, condition, max and
#             design capacity from ioreg. Calculates wear %
#             and flags batteries past 20% or 40% wear.
# ============================================================

set -euo pipefail

RED='\033[0;31m';  YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m';      NC='\033[0m'

SEP="════════════════════════════════════════════════════════"
DASH="────────────────────────────────────────────────────────"

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║          BATTERY GUARD  v1.0.0                       ║"
    echo "  ║     Battery health, wear level, and cycle report     ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}[1]${NC}  Full Battery Health Report"
    echo -e "  ${BOLD}[2]${NC}  Quick Status (charge + status)"
    echo -e "  ${BOLD}[3]${NC}  Wear Level Calculator"
    echo -e "  ${BOLD}[4]${NC}  Battery Health History (pmset)"
    echo -e "  ${BOLD}[5]${NC}  Power Source Details"
    echo -e "  ${BOLD}[6]${NC}  Export Report to Desktop"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

check_battery_support() {
    if ! ioreg -rn AppleSmartBattery 2>/dev/null | grep -q "CycleCount"; then
        echo -e "\n  ${YELLOW}[INFO]${NC} No smart battery detected."
        echo -e "  This script is designed for MacBooks."
        echo -e "  Desktop Macs and some external configurations will not show battery data.\n"
        return 1
    fi
    return 0
}

read_battery_data() {
    local raw; raw=$(ioreg -rn AppleSmartBattery 2>/dev/null)
    CYCLE=$(echo "$raw"  | grep '"CycleCount"'                | awk '{print $NF}')
    MAXCAP=$(echo "$raw" | grep '"MaxCapacity"'               | awk '{print $NF}')
    CURCAP=$(echo "$raw" | grep '"CurrentCapacity"'           | awk '{print $NF}')
    DSCAP=$(echo "$raw"  | grep '"DesignCapacity"'            | grep -v Raw | awk '{print $NF}')
    DSVOLTS=$(echo "$raw"| grep '"DesignCycleCount9C"'        | awk '{print $NF}')
    VOLTAGE=$(echo "$raw"| grep '"Voltage"'                   | awk '{print $NF}')
    AMPERAGE=$(echo "$raw"| grep '"Amperage"'                 | awk '{print $NF}')
    CHARGING=$(echo "$raw"| grep '"IsCharging"'               | awk '{print $NF}')
    PLUGGED=$(echo "$raw" | grep '"ExternalConnected"'        | awk '{print $NF}')
    FULLYC=$(echo "$raw"  | grep '"FullyCharged"'             | awk '{print $NF}')
    COND=$(echo "$raw"    | grep '"BatteryInvalidWakeSeconds"' | awk '{print $NF}' || echo "")

    # Charge percentage
    PCT=0
    [[ -n "$MAXCAP" && "$MAXCAP" -gt 0 ]] && PCT=$(( CURCAP * 100 / MAXCAP ))

    # Wear level: how much capacity has been lost vs design
    WEAR=0
    [[ -n "$DSCAP" && "$DSCAP" -gt 0 ]] && WEAR=$(( (DSCAP - MAXCAP) * 100 / DSCAP ))

    # Status
    STATUS="On Battery"
    [[ "$PLUGGED"  == "Yes" || "$PLUGGED"  == "1" ]] && STATUS="Plugged In (AC Power)"
    [[ "$CHARGING" == "Yes" || "$CHARGING" == "1" ]] && STATUS="Charging"
    [[ "$FULLYC"   == "Yes" || "$FULLYC"   == "1" ]] && STATUS="Fully Charged"

    # Health rating
    HEALTH_COLOR="$GREEN"; HEALTH_TEXT="Excellent"
    [[ $WEAR -ge 20 ]] && HEALTH_COLOR="$GREEN"  && HEALTH_TEXT="Good — normal aging"
    [[ $WEAR -ge 30 ]] && HEALTH_COLOR="$YELLOW" && HEALTH_TEXT="Fair — aging noticeably"
    [[ $WEAR -ge 40 ]] && HEALTH_COLOR="$YELLOW" && HEALTH_TEXT="Degraded — consider replacing"
    [[ $WEAR -ge 60 ]] && HEALTH_COLOR="$RED"    && HEALTH_TEXT="Poor — replace soon"
    [[ $WEAR -ge 80 ]] && HEALTH_COLOR="$RED"    && HEALTH_TEXT="Critical — replace immediately"

    # Apple design cycle limit (most MacBooks 1000 cycles)
    CYCLE_HEALTH=""
    if [[ -n "$CYCLE" ]]; then
        local limit=1000
        local cpct=$(( CYCLE * 100 / limit ))
        [[ $cpct -ge 80 ]]  && CYCLE_HEALTH=" ${YELLOW}(${cpct}% of rated life)${NC}"
        [[ $cpct -ge 100 ]] && CYCLE_HEALTH=" ${RED}(exceeded rated cycle limit)${NC}"
    fi
}

full_report() {
    check_battery_support || { read -rp "  Press Enter..."; return; }
    read_battery_data

    # Charge bar
    local bar_len=30 filled=$(( PCT * bar_len / 100 ))
    local bar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $filled ]] && bar+="#" || bar+="."; done

    # Wear bar
    local wear_filled=$(( WEAR * bar_len / 100 ))
    local wbar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $wear_filled ]] && wbar+="#" || wbar+="."; done

    clear
    echo -e "${BOLD}${CYAN}  ${SEP}"
    echo    "  BATTERY HEALTH REPORT"
    echo -e "  ${SEP}${NC}"
    echo
    echo -e "  ${BOLD}CHARGE${NC}"
    echo -e "  ${DASH}"
    printf  "  %-24s %s\n" "Current Charge:"   "${PCT}%"
    echo -e "  Charge Meter:    [${GREEN}${bar}${NC}] ${PCT}%"
    printf  "  %-24s %s\n" "Status:"            "$STATUS"
    echo
    echo -e "  ${BOLD}CAPACITY${NC}"
    echo -e "  ${DASH}"
    printf  "  %-24s %s\n" "Current Capacity:"  "${CURCAP:-N/A} mAh"
    printf  "  %-24s %s\n" "Max (Full Charge):" "${MAXCAP:-N/A} mAh"
    printf  "  %-24s %s\n" "Design Capacity:"   "${DSCAP:-N/A} mAh"
    echo
    echo -e "  ${BOLD}HEALTH & WEAR${NC}"
    echo -e "  ${DASH}"
    printf  "  %-24s %s\n" "Cycle Count:"       "${CYCLE:-N/A}$(eval echo -e \"$CYCLE_HEALTH\")"
    printf  "  %-24s %s%%\n" "Wear Level:"      "$WEAR"
    echo -e "  Wear Meter:      [${RED}${wbar}${NC}] ${WEAR}%"
    echo -e "  Health Rating:   ${HEALTH_COLOR}${HEALTH_TEXT}${NC}"
    echo
    echo -e "  ${BOLD}ELECTRICAL${NC}"
    echo -e "  ${DASH}"
    [[ -n "$VOLTAGE" ]]  && printf "  %-24s %s mV\n"  "Voltage:"   "$VOLTAGE"
    [[ -n "$AMPERAGE" ]] && printf "  %-24s %s mA\n"  "Amperage:"  "$AMPERAGE"
    echo
    echo -e "  ${BOLD}WEAR LEVEL THRESHOLDS${NC}"
    echo -e "  ${DASH}"
    echo -e "   ${GREEN}0%  – 20%${NC}   Excellent  (like new)"
    echo -e "   ${GREEN}20% – 30%${NC}   Good       (normal aging)"
    echo -e "   ${YELLOW}30% – 40%${NC}   Fair       (aging noticeably)"
    echo -e "   ${YELLOW}40% – 60%${NC}   Degraded   (consider replacing)"
    echo -e "   ${RED}60%+${NC}        Poor       (replace soon)"
    echo
    echo -e "  Apple rates most MacBook batteries for ${BOLD}1000 charge cycles${NC}."
    echo
}

quick_status() {
    check_battery_support || { read -rp "  Press Enter..."; return; }
    read_battery_data
    clear
    echo -e "\n  ${BOLD}Battery Quick Status${NC}"
    echo -e "  ${DASH}"
    echo    "  Charge  : ${PCT}%"
    echo    "  Status  : ${STATUS}"
    echo    "  Cycles  : ${CYCLE:-N/A}"
    echo    "  Health  : ${HEALTH_TEXT} (wear: ${WEAR}%)"
    echo
}

wear_calculator() {
    clear
    echo -e "\n  ${BOLD}Wear Level Calculator${NC}"
    echo -e "  ${DASH}"
    echo    "  Enter your battery's MaxCapacity (from ioreg or coconutBattery):"
    printf  "  MaxCapacity (mAh): "; read -r mc
    echo    "  Enter DesignCapacity:"
    printf  "  DesignCapacity (mAh): "; read -r dc
    if [[ "$mc" =~ ^[0-9]+$ && "$dc" =~ ^[0-9]+$ && "$dc" -gt 0 ]]; then
        local w=$(( (dc - mc) * 100 / dc ))
        local remaining=$(( mc * 100 / dc ))
        echo
        echo    "  Wear Level    : ${w}%"
        echo    "  Remaining Cap : ${remaining}%  of original design"
        [[ $w -ge 40 ]] && echo -e "  ${YELLOW}Recommendation: Consider battery replacement.${NC}"
        [[ $w -lt 40 ]] && echo -e "  ${GREEN}Battery is within normal range.${NC}"
    else
        echo -e "  ${RED}Invalid input. Please enter numbers only.${NC}"
    fi
    echo
}

pmset_history() {
    clear
    echo -e "\n  ${BOLD}Battery Health History (pmset)${NC}"
    echo -e "  ${DASH}"
    pmset -g batt 2>/dev/null
    echo
    echo -e "  ${BOLD}Recent Battery Assertions:${NC}"
    pmset -g assertions 2>/dev/null | head -20
    echo
}

power_source_details() {
    clear
    echo -e "\n  ${BOLD}Power Source Details${NC}"
    echo -e "  ${DASH}"
    system_profiler SPPowerDataType 2>/dev/null
    echo
}

export_report() {
    check_battery_support || { read -rp "  Press Enter..."; return; }
    read_battery_data
    local rpt="$HOME/Desktop/BatteryReport_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "========================================================"
        echo "  BATTERY HEALTH REPORT"
        echo "  Generated: $(date)"
        echo "  Host:      $(hostname)"
        echo "========================================================"
        echo
        echo "Charge:            ${PCT}%"
        echo "Status:            ${STATUS}"
        echo "Cycle Count:       ${CYCLE:-N/A}"
        echo "Max Capacity:      ${MAXCAP:-N/A} mAh"
        echo "Design Capacity:   ${DSCAP:-N/A} mAh"
        echo "Wear Level:        ${WEAR}%"
        echo "Health Rating:     ${HEALTH_TEXT}"
        echo "Voltage:           ${VOLTAGE:-N/A} mV"
        echo "Amperage:          ${AMPERAGE:-N/A} mA"
        echo
        echo "[RAW IOREG DATA]"
        ioreg -rn AppleSmartBattery 2>/dev/null
        echo
        echo "[PMSET BATTERY STATUS]"
        pmset -g batt 2>/dev/null
        echo
        echo "========================================================"
        echo "  END OF REPORT"
        echo "========================================================"
    } > "$rpt" 2>/dev/null
    echo -e "\n  ${GREEN}[OK]${NC} Report saved to Desktop: $(basename "$rpt")"
}

while true; do
    show_menu
    case "$choice" in
        1) full_report;           read -rp "  Press Enter..." ;;
        2) quick_status;          read -rp "  Press Enter..." ;;
        3) wear_calculator;       read -rp "  Press Enter..." ;;
        4) pmset_history;         read -rp "  Press Enter..." ;;
        5) power_source_details;  read -rp "  Press Enter..." ;;
        6) export_report;         read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
