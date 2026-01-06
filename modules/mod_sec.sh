#!/bin/bash

# Załaduj bibliotekę (która automatycznie załaduje config.conf)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="${SCRIPT_DIR}/../audyt_lib.sh"

if [[ ! -f "$LIB_FILE" ]]; then
    echo "ERROR: Library file not found: $LIB_FILE" >&2
    exit 1
fi

source "$LIB_FILE"

# Walidacja wymaganych narzędzi
check_required_tools who grep tail last || exit 1

echo "----------------[ SECURITY AUDIT ]--------------------"

echo ""
echo "--- LOGGED USERS ---"
who
echo ""

echo "--- FAILED LOGIN ATTEMPTS (last 10) ---"
if [[ -r /var/log/auth.log ]]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 10)
    if [[ -n "$FAILED_LOGINS" ]]; then
        echo "$FAILED_LOGINS"
    else
        echo "  No failed login attempts found."
    fi
else
    echo -e "  ${YELLOW}(Cannot access /var/log/auth.log - requires 'adm' group membership)${RESET}"
    echo "  Run: sudo usermod -a -G adm \$USER"
fi
echo ""

echo "--- RECENT LOGINS (last 10) ---"
last | head -n 10

log_msg "SEC" "Raport bezpieczeństwa wygenerowany poprawnie."