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
    /Processor/  {gsub(/^[ \t]+/, "", $2); print $2; exit}
  ' /proc/cpuinfo 2>/dev/null
)

# Jeśli nie znaleziono, spróbuj alternatywnych metod
if [ -z "$MODEL" ]; then
  # Sprawdź architekturę
  ARCH=$(uname -m 2>/dev/null)
  
  # Dla ARM64/aarch64 spróbuj wyciągnąć szczegóły
  if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    MODEL="ARM64/AArch64 CPU"
    
    # Spróbuj wyciągnąć więcej szczegółów
    CPU_IMPLEMENTER=$(awk -F: '/CPU implementer/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_ARCHITECTURE=$(awk -F: '/CPU architecture/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_VARIANT=$(awk -F: '/CPU variant/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    CPU_PART=$(awk -F: '/CPU part/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
    
    if [[ -n "$CPU_IMPLEMENTER" ]] || [[ -n "$CPU_PART" ]]; then
      MODEL="ARM64 (Arch: ${CPU_ARCHITECTURE:-N/A}, Implementer: ${CPU_IMPLEMENTER:-N/A}, Part: ${CPU_PART:-N/A})"
    fi
    
    # Spróbuj lscpu jako fallback
    if command -v lscpu &>/dev/null; then
      LSCPU_MODEL=$(lscpu 2>/dev/null | grep -i "model name" | cut -d: -f2 | xargs)
      if [[ -n "$LSCPU_MODEL" ]]; then
        MODEL="$LSCPU_MODEL"
      fi
    fi
  else
    MODEL="Unknown CPU ($ARCH architecture)"
  fi
fi

# Dodaj liczbę rdzeni
CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "Unknown")

echo "CPU model:"
echo "  $MODEL"
echo "  Cores: $CPU_CORES"
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
