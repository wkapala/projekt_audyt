#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="${SCRIPT_DIR}/../audyt_lib.sh"

if [[ ! -f "$LIB_FILE" ]]; then
    echo "ERROR: Library file not found: $LIB_FILE" >&2
    exit 1
fi

source "$LIB_FILE"

check_required_tools ps awk || exit 1

echo "--------------------[ CPU AUDIT ]---------------------"

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

ARCH=$(uname -m)

if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    # ARM: używamy CPU implementer i CPU part
    MODEL="ARM64/AArch64 CPU"
    CPU_IMPLEMENTER=$(awk -F: '/CPU implementer/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_PART=$(awk -F: '/CPU part/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_VARIANT=$(awk -F: '/CPU variant/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_REVISION=$(awk -F: '/CPU revision/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')

    if [[ -n "$CPU_IMPLEMENTER" ]] && [[ -n "$CPU_PART" ]]; then
        MODEL="ARM64 (Implementer: $CPU_IMPLEMENTER, Part: $CPU_PART"
        [[ -n "$CPU_VARIANT" ]] && MODEL="$MODEL, Variant: $CPU_VARIANT"
        [[ -n "$CPU_REVISION" ]] && MODEL="$MODEL, Revision: $CPU_REVISION"
        MODEL="$MODEL)"
    fi

    # Sprawdź czy jest "Hardware" (niektóre ARM mają to pole)
    HARDWARE=$(awk -F: '/^Hardware/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null)
    if [[ -n "$HARDWARE" ]]; then
        MODEL="$MODEL - $HARDWARE"
    fi
else
    # x86/x64: standardowe "model name"
    MODEL=$(awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null)

    if [[ -z "$MODEL" ]]; then
        MODEL="Unknown CPU model"
    fi
fi

CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "Unknown")

echo "CPU model:"
echo "  $MODEL"
echo "  Architecture: $ARCH"
echo "  CPU cores: $CPU_CORES"
echo ""

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
