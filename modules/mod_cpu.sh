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
check_required_tools ps awk || exit 1

echo "--------------------[ CPU AUDIT ]---------------------"

# Średnie obciążenie
if check_proc_access "/proc/loadavg"; then
    read load1 load5 load15 _ < /proc/loadavg
else
    echo "ERROR: Cannot access /proc/loadavg"
    exit 1
fi
echo "Load average:"
echo "  1 min : $load1"
echo "  5 min : $load5"
echo " 15 min : $load15"
echo ""

# Model procesora – wersja odporna na różne /proc/cpuinfo (x86, ARM, Apple Silicon itd.)
MODEL=$(
  awk -F: '
    /model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}
    /Model/      {gsub(/^[ \t]+/, "", $2); print $2; exit}
    /Hardware/   {gsub(/^[ \t]+/, "", $2); print $2; exit}
  ' /proc/cpuinfo 2>/dev/null
)

if [ -z "$MODEL" ]; then
  MODEL="Unknown (no recognizable model field in /proc/cpuinfo)"
fi

echo "CPU model:"
echo "  $MODEL"
echo ""

# Top 5 procesów wg CPU – zdejmujemy na chwilę pipefail/set -e żeby SIGPIPE nas nie zabił
set +e
echo "Top 5 processes by CPU usage:"
ps -eo pid,comm,%cpu --sort=-%cpu 2>/dev/null | head -n 6
ps_status=$?
set -e

if [ $ps_status -ne 0 ]; then
  echo "  (unable to list processes)"
fi

echo ""

log_msg "CPU" "Raport CPU wygenerowany poprawnie."