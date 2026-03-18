#!/usr/bin/env bash
# ============================================================
# Name      : thermal_monitor.sh
# Version   : 1.0.0
# Author    : Anamicca23
# Tested    : Ubuntu 22.04 LTS, Debian 12 Bookworm
# Min OS    : Ubuntu 20.04 / Debian 11
# Risk      : LOW
# Sudo      : Not Required
# Reversible: Yes  (read-only monitoring)
# Desc      : Live 5-second refresh CPU temperature monitor.
#             Reads /sys/class/thermal and lm-sensors if
#             installed. Color-coded: warn >=80°C, crit >=90°C.
#             Press CTRL+C to stop the live loop.
# ============================================================

set -uo pipefail

RED='\033[0;31m';   YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m';  BOLD='\033[1m';      NC='\033[0m'
DASH="────────────────────────────────────────────────────────"

WARN_THRESH=80
CRIT_THRESH=90

show_menu() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         THERMAL MONITOR  v1.0.0                      ║"
    echo "  ║     Live CPU temperature with color alerts           ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Warn threshold : ${YELLOW}${WARN_THRESH}°C${NC}"
    echo -e "  Crit threshold : ${RED}${CRIT_THRESH}°C${NC}"
    echo
    echo -e "  ${BOLD}[1]${NC}  Start Live Monitor  (5-second refresh)"
    echo -e "  ${BOLD}[2]${NC}  Single Temperature Snapshot"
    echo -e "  ${BOLD}[3]${NC}  Change Thresholds"
    echo -e "  ${BOLD}[4]${NC}  About Thermal Monitoring"
    echo -e "  ${BOLD}[5]${NC}  Install lm-sensors"
    echo -e "  ${BOLD}[0]${NC}  Exit"
    echo
    printf "  Enter Option: "
    read -r choice
}

read_sys_temps() {
    local found=0
    for zone in /sys/class/thermal/thermal_zone*/; do
        [[ ! -f "${zone}temp" ]] && continue
        local raw; raw=$(cat "${zone}temp" 2>/dev/null || echo 0)
        local celsius=$(( raw / 1000 ))
        local zname; zname=$(cat "${zone}type" 2>/dev/null || basename "$zone")

        local color="$GREEN" status="NORMAL"
        if   [[ $celsius -ge $CRIT_THRESH ]]; then color="$RED";    status="CRITICAL"
        elif [[ $celsius -ge $WARN_THRESH  ]]; then color="$YELLOW"; status="WARNING "
        fi

        # Bar (max 60°C shown as full for visual clarity)
        local bar_len=20 filled=$(( celsius < 100 ? celsius * bar_len / 100 : bar_len ))
        local bar=""; for((i=0;i<bar_len;i++)); do [[ $i -lt $filled ]] && bar+="#" || bar+="."; done

        printf "  %-22s ${color}%3d°C${NC}  [${color}%s${NC}]  %s\n" \
            "${zname}:" "$celsius" "$bar" "$status"
        found=$(( found + 1 ))
    done
    echo "$found"
}

read_sensors() {
    if ! command -v sensors &>/dev/null; then
        echo -e "  ${YELLOW}lm-sensors not installed.${NC}"
        echo -e "  Install: ${BOLD}sudo apt install lm-sensors && sudo sensors-detect${NC}"
        return 1
    fi
    echo -e "  ${BOLD}lm-sensors output:${NC}\n"
    sensors 2>/dev/null | while IFS= read -r line; do
        # Colorize temperature lines
        if echo "$line" | grep -qE "[0-9]+\.[0-9]+.C"; then
            local temp; temp=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+" | head -1)
            local temp_int; temp_int=$(echo "$temp" | cut -d. -f1)
            if   [[ $temp_int -ge $CRIT_THRESH ]]; then echo -e "  ${RED}${line}${NC}"
            elif [[ $temp_int -ge $WARN_THRESH  ]]; then echo -e "  ${YELLOW}${line}${NC}"
            else echo -e "  ${GREEN}${line}${NC}"; fi
        else
            echo "  $line"
        fi
    done
    return 0
}

snapshot() {
    clear
    echo -e "${BOLD}${CYAN}  TEMPERATURE SNAPSHOT — $(date '+%H:%M:%S')${NC}"
    echo -e "  ${DASH}\n"

    local sys_count; sys_count=$(read_sys_temps)
    echo
    if [[ "$sys_count" -eq 0 ]]; then
        echo -e "  ${YELLOW}No /sys/class/thermal zones found.${NC}"
    fi

    echo -e "  ${BOLD}lm-sensors:${NC}"
    read_sensors || true
    echo
    echo -e "  ${BOLD}CPU Load:${NC}"
    cat /proc/loadavg 2>/dev/null | awk '{printf "  1min: %s   5min: %s   15min: %s\n", $1,$2,$3}'
    echo
}

live_monitor() {
    echo -e "\n  Starting live monitor. ${BOLD}Press CTRL+C to stop.${NC}"
    echo -e "  Refresh: every 5 seconds\n"
    sleep 1
    trap 'echo -e "\n\n  ${GREEN}Monitor stopped.${NC}\n"; return' INT
    while true; do
        clear
        echo -e "${BOLD}${CYAN}  THERMAL MONITOR  —  Live  —  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "  ${YELLOW}Press CTRL+C to stop${NC}"
        echo -e "  ${DASH}\n"
        echo -e "  ${BOLD}Thermal Zones (/sys/class/thermal):${NC}\n"
        local count; count=$(read_sys_temps)
        echo
        if command -v sensors &>/dev/null; then
            echo -e "  ${BOLD}lm-sensors:${NC}\n"
            sensors 2>/dev/null | grep -E "°C|Core|temp|Package" | while IFS= read -r line; do
                local temp; temp=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+" | head -1 || echo "0")
                local ti; ti=$(echo "$temp" | cut -d. -f1 || echo "0")
                if   [[ ${ti:-0} -ge $CRIT_THRESH ]]; then echo -e "  ${RED}${line}${NC}"
                elif [[ ${ti:-0} -ge $WARN_THRESH  ]]; then echo -e "  ${YELLOW}${line}${NC}"
                else echo -e "  ${GREEN}${line}${NC}"; fi
            done
        fi
        echo
        echo -e "  ${BOLD}Load:${NC} $(cat /proc/loadavg 2>/dev/null | awk '{print $1,$2,$3}')"
        echo -e "  ${DASH}"
        echo -e "  ${GREEN}< ${WARN_THRESH}°C Normal${NC}   ${YELLOW}>= ${WARN_THRESH}°C Warning${NC}   ${RED}>= ${CRIT_THRESH}°C Critical${NC}"
        sleep 5
    done
    trap - INT
}

change_thresholds() {
    echo
    printf "  New warn threshold in °C (current: ${WARN_THRESH}): "
    read -r w
    printf "  New crit threshold in °C (current: ${CRIT_THRESH}): "
    read -r c
    [[ "$w" =~ ^[0-9]+$ ]] && WARN_THRESH=$w
    [[ "$c" =~ ^[0-9]+$ ]] && CRIT_THRESH=$c
    echo -e "  ${GREEN}[OK]${NC} Thresholds updated: warn=${WARN_THRESH}°C  crit=${CRIT_THRESH}°C"
    echo
}

about_thermal() {
    clear
    echo -e "${BOLD}${CYAN}  ABOUT THERMAL MONITORING${NC}"
    echo -e "  ${DASH}\n"
    cat << 'INFO'
  Data Sources:
  ─────────────
  /sys/class/thermal/thermal_zone*/temp
    Raw value in millidegrees Celsius (divide by 1000 for °C).
    Available on most modern Linux systems without any packages.

  lm-sensors (sensors command)
    Reads hardware sensor chips via kernel modules.
    Install: sudo apt install lm-sensors
    Config:  sudo sensors-detect  (auto-detect sensor chips)

  Safe Temperature Ranges:
  ────────────────────────
    CPU Idle   : 30–50°C    (optimal)
    CPU Load   : 60–80°C    (normal under load)
    CPU Warn   : 80–90°C    (thermal throttling may begin)
    CPU Crit   : 90°C+      (emergency throttle / shutdown risk)
    SSD        : 0–70°C     (most SSDs rated to 70°C)
    HDD        : 25–55°C    (hard drives prefer cooler temps)

  Thermal Throttling:
  ───────────────────
    When the CPU approaches its maximum safe temperature,
    the kernel (or CPU hardware) automatically reduces clock
    speed to lower heat output. This shows as sudden CPU
    performance drops during heavy workloads.

INFO
}

install_lmsensors() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "\n  ${YELLOW}[INFO]${NC} Run as root to install: ${BOLD}sudo apt install lm-sensors${NC}\n"
        return
    fi
    apt-get install -y lm-sensors 2>&1 | tail -5 | sed 's/^/  /'
    echo -e "\n  ${GREEN}[OK]${NC} lm-sensors installed."
    echo -e "  Run ${BOLD}sudo sensors-detect${NC} to configure sensor modules."
    echo
}

while true; do
    show_menu
    case "$choice" in
        1) live_monitor ;;
        2) snapshot;           read -rp "  Press Enter..." ;;
        3) change_thresholds;  read -rp "  Press Enter..." ;;
        4) about_thermal;      read -rp "  Press Enter..." ;;
        5) install_lmsensors;  read -rp "  Press Enter..." ;;
        0) echo -e "\n  Goodbye!\n"; exit 0 ;;
        *) echo -e "  ${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
