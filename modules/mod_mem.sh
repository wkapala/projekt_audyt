#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="${SCRIPT_DIR}/../audyt_lib.sh"

if [[ ! -f "$LIB_FILE" ]]; then
    echo "ERROR: Library file not found: $LIB_FILE" >&2
    exit 1
fi

source "$LIB_FILE"

check_required_tools grep awk || exit 1

echo "------------------[ MEMORY AUDIT ]--------------------"

if ! check_proc_access "/proc/meminfo"; then
    echo "ERROR: Cannot access /proc/meminfo"
    exit 1
fi

MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
SWAP_FREE=$(grep SwapFree /proc/meminfo | awk '{print $2}')

MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))

echo "Total RAM:      $((MEM_TOTAL/1024)) MB"
echo "Available RAM:  $((MEM_AVAIL/1024)) MB"
echo "Used RAM:       $((MEM_USED/1024)) MB (${MEM_PCT}%)"
echo ""

if [ "$MEM_PCT" -gt "$MEM_WARNING_THRESHOLD" ]; then
    echo -e "${RED}${BOLD}WARNING: Memory usage above ${MEM_WARNING_THRESHOLD}%!${RESET}"
else
    echo -e "${GREEN}Memory usage is within normal range.${RESET}"
fi

echo ""
echo "Swap total:     $((SWAP_TOTAL/1024)) MB"
echo "Swap free:      $((SWAP_FREE/1024)) MB"

log_msg "MEM" "Raport pamięci RAM wygenerowany poprawnie."