#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
LIB_FILE="${SCRIPT_DIR}/audyt_lib.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

if [[ ! -f "$LIB_FILE" ]]; then
    echo "ERROR: Library file not found: $LIB_FILE" >&2
    exit 1
fi

source "$CONFIG_FILE"
source "$LIB_FILE"

header() {
    echo -e "${CYAN}${BOLD}=========================================="
    echo "          SYSTEM AUDIT REPORT"
    echo -e "${RESET}  Host:      ${BOLD}$(hostname)${RESET}"
    echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${CYAN}${BOLD}==========================================${RESET}"
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTION]

System Audit - Modular system resource auditing tool

OPTIONS:
    --full, -f          Run full audit (all modules)
    --cpu,  -c          CPU audit only
    --mem,  -m          Memory audit only
    --disk, -d          Disk audit only
    --net,  -n          Network audit only
    --sec,  -s          Security audit only
    --help, -h          Show this help message

EXAMPLES:
    $(basename "$0")              # Interactive menu
    $(basename "$0") --full       # Full audit
    $(basename "$0") --cpu        # CPU audit only
    $(basename "$0") -m -d        # Memory and disk audit

EOF
    exit 0
}

run_modules=()

if [[ $# -eq 0 ]]; then
    INTERACTIVE_MODE=1
else
    INTERACTIVE_MODE=0

    for arg in "$@"; do
        case "$arg" in
            --full|-f)
                run_modules=(cpu mem disk net sec)
                break
                ;;
            --cpu|-c)
                run_modules+=(cpu)
                ;;
            --mem|-m)
                run_modules+=(mem)
                ;;
            --disk|-d)
                run_modules+=(disk)
                ;;
            --net|-n)
                run_modules+=(net)
                ;;
            --sec|-s)
                run_modules+=(sec)
                ;;
            --help|-h)
                show_help
                ;;
            *)
                echo "ERROR: Unknown option: $arg" >&2
                echo "Try '$(basename "$0") --help' for more information." >&2
                exit 1
                ;;
        esac
    done
fi

if [[ $INTERACTIVE_MODE -eq 0 ]]; then
    if [[ ${#run_modules[@]} -eq 0 ]]; then
        echo "ERROR: No modules selected" >&2
        exit 1
    fi

    header
    echo ""

    for module in "${run_modules[@]}"; do
        bash "$MODULE_DIR/mod_${module}.sh"
        echo ""
    done

    echo -e "${GREEN}${BOLD}Audit completed.${RESET}"
    exit 0
fi

while true; do
    header
    echo ""
    echo -e "${BOLD}=== MENU MODUŁÓW ===${RESET}"
    echo -e "1. ${CYAN}Audyt CPU${RESET}"
    echo -e "2. ${CYAN}Audyt RAM${RESET}"
    echo -e "3. ${CYAN}Audyt Dysku${RESET}"
    echo -e "4. ${CYAN}Audyt Sieci${RESET}"
    echo -e "5. ${CYAN}Audyt Bezpieczeństwa${RESET}"
    echo -e "0. ${YELLOW}Wyjście${RESET}"
    echo ""
    read -p "Wybierz moduł: " choice

    case "$choice" in
        1) bash "$MODULE_DIR/mod_cpu.sh" ;;
        2) bash "$MODULE_DIR/mod_mem.sh" ;;
        3) bash "$MODULE_DIR/mod_disk.sh" ;;
        4) bash "$MODULE_DIR/mod_net.sh" ;;
        5) bash "$MODULE_DIR/mod_sec.sh" ;;
        0) exit 0 ;;
        *) echo "Nieprawidłowy wybór!";;
    esac

    echo ""
    read -p "Wciśnij ENTER, aby wrócić do menu..." _
done