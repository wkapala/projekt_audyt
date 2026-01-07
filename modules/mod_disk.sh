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
check_required_tools df awk || exit 1

echo "-------------------[ DISK AUDIT ]---------------------"
echo ""
echo "Filesystem usage:"
df -h
echo ""

echo "Partitions above ${DISK_WARNING_THRESHOLD}% usage:"
critical=0
# pomijamy nagłówek (NR>1)
while read -r fs size used avail pct mount; do
    use_pct=${pct%%%}   # obetnij %
    if [ "$use_pct" -gt "$DISK_WARNING_THRESHOLD" ]; then
        echo -e "  ${YELLOW}$fs ($mount) - ${BOLD}$pct used${RESET}"
        critical=1
    fi
done < <(df -h | awk 'NR>1')

if [ "$critical" -eq 0 ]; then
    echo -e "  ${GREEN}No critical partitions detected (all below ${DISK_WARNING_THRESHOLD}%).${RESET}"
fi

log_msg "DISK" "Raport dyskowy wygenerowany poprawnie."