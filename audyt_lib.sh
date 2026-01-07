#!/bin/bash
set -euo pipefail

# Załaduj konfigurację
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

source "$CONFIG_FILE"

# Bezpieczne ustalenie użytkownika (działa też w cronie)
AUDIT_USER="${USER:-$(whoami 2>/dev/null || echo unknown)}"

# Funkcja logowania
log_msg() {
    local module="$1"
    shift
    local msg="$*"

    # Sprawdź czy katalog logów istnieje
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "WARNING: Cannot create log directory: $LOG_DIR" >&2
            return 1
        }
    fi

    printf '[%s] [%s@%s] [%s] -> %s\n' \
        "$(date '+%F %T')" "$AUDIT_USER" "$(hostname)" "$module" "$msg" >> "$LOGFILE"
}

# Funkcja sprawdzania wymaganych narzędzi
check_required_tools() {
    local missing_tools=()
    local tools=("$@")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}ERROR: Missing required tools: ${missing_tools[*]}${RESET}" >&2
        echo "" >&2
        echo "On Ubuntu/Debian, install with:" >&2
        echo "  sudo apt-get install coreutils procps iproute2 iputils-ping" >&2
        echo "" >&2
        return 1
    fi

    return 0
}

# Funkcja sprawdzania dostępu do plików /proc
check_proc_access() {
    local proc_file="$1"

    if [[ ! -r "$proc_file" ]]; then
        echo -e "${YELLOW}WARNING: Cannot read $proc_file${RESET}" >&2
        return 1
    fi

    return 0
}