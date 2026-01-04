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
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 10 || echo "No failed attempts found."
echo ""

echo "--- RECENT LOGINS (last 10) ---"
last | head -n 10

log_msg "SEC" "Raport bezpieczeństwa wygenerowany poprawnie."