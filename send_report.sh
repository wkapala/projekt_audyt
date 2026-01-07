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

# Przygotowanie nazw plików
HOSTNAME=$(hostname)
TS=$(date '+%Y%m%d_%H%M%S')
LOCAL_REPORT="${REPORT_DIR}/${HOSTNAME}_${TS}.txt"

# Sprawdź czy katalog raportów istnieje
if [[ ! -d "$REPORT_DIR" ]]; then
    echo "Creating reports directory: $REPORT_DIR"
    mkdir -p "$REPORT_DIR" || {
        echo "ERROR: Cannot create reports directory: $REPORT_DIR" >&2
        exit 1
    }
fi

# 1. Pełny audyt na lokalnym hoście
echo "Running full system audit..."
"${SCRIPT_DIR}/audyt_main.sh" --full > "$LOCAL_REPORT" 2>&1

if [[ ! -f "$LOCAL_REPORT" ]]; then
    echo "ERROR: Report file was not created: $LOCAL_REPORT" >&2
    exit 1
fi

echo "Report generated: $LOCAL_REPORT"

# 2. Wysłanie raportu na host centralny
echo "Sending report to central host: ${CENTRAL_USER}@${CENTRAL_HOST}"

# Funkcja wysyłania z retry mechanism
send_report() {
    local attempt=1
    local max_attempts="$SCP_RETRY_COUNT"

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts..."

        # Sprawdź połączenie SSH przed wysłaniem
        if timeout "$SSH_TIMEOUT" ssh -o ConnectTimeout="$SSH_TIMEOUT" -o BatchMode=yes \
            "${CENTRAL_USER}@${CENTRAL_HOST}" "exit" 2>/dev/null; then

            # Upewnij się że katalog central_reports istnieje na remote (automatycznie utworzy jeśli nie ma)
            ssh -o ConnectTimeout="$SSH_TIMEOUT" -o BatchMode=yes \
                "${CENTRAL_USER}@${CENTRAL_HOST}" "mkdir -p ${CENTRAL_DIR}" 2>/dev/null || true

            # Połączenie działa, wysyłaj raport
            if scp -o ConnectTimeout="$SSH_TIMEOUT" "$LOCAL_REPORT" \
                "${CENTRAL_USER}@${CENTRAL_HOST}:${CENTRAL_DIR}/" 2>/dev/null; then
                echo "Report sent successfully!"
                return 0
            else
                echo "WARNING: SCP failed (attempt $attempt/$max_attempts)"
            fi
        else
            echo "WARNING: Cannot connect to central host (attempt $attempt/$max_attempts)"
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "Retrying in ${SCP_RETRY_DELAY} seconds..."
            sleep "$SCP_RETRY_DELAY"
        fi

        ((attempt++))
    done

    return 1
}

# Próba wysłania
if send_report; then
    echo "SUCCESS: Report delivered to central host"
    exit 0
else
    echo "ERROR: Failed to send report after $SCP_RETRY_COUNT attempts" >&2
    echo "Report saved locally: $LOCAL_REPORT" >&2
    exit 1
fi
