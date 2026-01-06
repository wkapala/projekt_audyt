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

# Connectivity test - auto-detect: admin mode vs client mode
echo "--- CONNECTIVITY TEST ---"

# Wykryj czy to admin (ma central_reports) czy klient
if [[ -d "$CENTRAL_DIR" ]]; then
    # ADMIN MODE: Pokaż klientów z ARP cache (którzy wysłali raporty)
    REACHABLE_CLIENTS=$(ip neigh show | grep REACHABLE | awk '{print $1}' | grep -v "^127\." | grep -v "^169\.254\.")

    if [[ -z "$REACHABLE_CLIENTS" ]]; then
        echo "  (no clients detected - waiting for first report submission)"
    else
        for CLIENT in $REACHABLE_CLIENTS; do
            echo -e "${GREEN}✓ OK:${RESET} $CLIENT (client)"
        done
    fi
else
    # CLIENT MODE: Sprawdź połączenie do centrali
    if [[ -n "$CENTRAL_HOST" ]]; then
        if ping -c"$PING_COUNT" -W"$PING_TIMEOUT" "$CENTRAL_HOST" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ OK:${RESET} Central host ($CENTRAL_HOST) is reachable"
        else
            echo -e "${RED}✗ FAIL:${RESET} Cannot reach central host ($CENTRAL_HOST)"
        fi
    else
        echo "  (central host not configured)"
    fi
fi

echo ""

log_msg "NET" "Raport sieciowy wygenerowany poprawnie."