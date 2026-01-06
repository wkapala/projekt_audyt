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
check_required_tools ip ss ping awk || exit 1

echo "------------------[ NETWORK AUDIT ]-------------------"

echo ""
echo "--- INTERFACES (IPv4) ---"
ip -4 addr show | awk '/inet/ {print $2, "dev", $NF}'
echo ""

echo "--- LISTENING PORTS (TCP/UDP) ---"
ss -tuln
echo ""

echo "--- CONNECTIVITY TEST ---"

for H in "${PING_TARGETS[@]}"; do
    if ping -c"$PING_COUNT" -W"$PING_TIMEOUT" "$H" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ OK:${RESET} $H is reachable"
    else
        echo -e "${RED}✗ FAIL:${RESET} Cannot reach $H"
    fi
done

log_msg "NET" "Raport sieciowy wygenerowany poprawnie."