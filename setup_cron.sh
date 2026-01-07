#!/bin/bash
# =============================================================================
# Skrypt do konfiguracji cron job dla automatycznych raportów
# =============================================================================

set -euo pipefail

# Kolory
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

print_step() {
    echo -e "${CYAN}${BOLD}==>${RESET} ${BOLD}$*${RESET}"
}

print_success() {
    echo -e "${GREEN}${BOLD}✓${RESET} $*"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}⚠${RESET} $*"
}

# Wykryj lokalizację instalacji
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$SCRIPT_DIR" == *"/opt/sysaudit"* ]]; then
    INSTALL_DIR="/opt/sysaudit"
else
    INSTALL_DIR="$SCRIPT_DIR"
fi

SEND_REPORT_SCRIPT="${INSTALL_DIR}/send_report.sh"

# Sprawdź czy skrypt send_report istnieje
if [[ ! -f "$SEND_REPORT_SCRIPT" ]]; then
    echo "ERROR: send_report.sh not found at: $SEND_REPORT_SCRIPT"
    exit 1
fi

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "  System Audit - Cron Setup"
echo "=========================================="
echo -e "${RESET}"
echo ""
echo "This script will configure automatic system audits using cron."
echo ""
echo "Script location: $SEND_REPORT_SCRIPT"
echo ""

# Menu wyboru częstotliwości
echo "Select audit frequency:"
echo ""
echo "  1) Every 6 hours"
echo "  2) Every 12 hours"
echo "  3) Daily at 2:00 AM"
echo "  4) Daily at specific time"
echo "  5) Weekly (Monday at 2:00 AM)"
echo "  6) Custom cron expression"
echo "  7) Show current cron jobs (no changes)"
echo "  0) Cancel"
echo ""

read -p "Choice [0-7]: " choice

case "$choice" in
    1)
        CRON_EXPR="0 */6 * * *"
        CRON_DESC="every 6 hours"
        ;;
    2)
        CRON_EXPR="0 */12 * * *"
        CRON_DESC="every 12 hours"
        ;;
    3)
        CRON_EXPR="0 2 * * *"
        CRON_DESC="daily at 2:00 AM"
        ;;
    4)
        read -p "Enter hour (0-23): " hour
        if [[ ! "$hour" =~ ^[0-9]+$ ]] || [[ $hour -lt 0 ]] || [[ $hour -gt 23 ]]; then
            echo "ERROR: Invalid hour"
            exit 1
        fi
        CRON_EXPR="0 $hour * * *"
        CRON_DESC="daily at ${hour}:00"
        ;;
    5)
        CRON_EXPR="0 2 * * 1"
        CRON_DESC="weekly on Monday at 2:00 AM"
        ;;
    6)
        read -p "Enter cron expression: " CRON_EXPR
        CRON_DESC="custom schedule"
        ;;
    7)
        print_step "Current cron jobs for $(whoami):"
        echo ""
        crontab -l 2>/dev/null || echo "No cron jobs configured"
        echo ""
        exit 0
        ;;
    0)
        echo "Cancelled."
        exit 0
        ;;
    *)
        echo "ERROR: Invalid choice"
        exit 1
        ;;
esac

echo ""
print_step "Configuration:"
echo "  Schedule: $CRON_DESC"
echo "  Cron expr: $CRON_EXPR"
echo "  Command: $SEND_REPORT_SCRIPT"
echo ""

read -p "Proceed with installation? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Dodaj do crona
CRON_LINE="$CRON_EXPR $SEND_REPORT_SCRIPT > /dev/null 2>&1"

# Pobierz obecny crontab
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Sprawdź czy już istnieje podobny wpis
if grep -qF "$SEND_REPORT_SCRIPT" "$TEMP_CRON" 2>/dev/null; then
    print_warning "Found existing cron job for this script"
    echo ""
    grep -F "$SEND_REPORT_SCRIPT" "$TEMP_CRON"
    echo ""
    read -p "Replace it? [y/N]: " replace

    if [[ "$replace" =~ ^[Yy]$ ]]; then
        # Usuń stare wpisy
        grep -vF "$SEND_REPORT_SCRIPT" "$TEMP_CRON" > "${TEMP_CRON}.new" || true
        mv "${TEMP_CRON}.new" "$TEMP_CRON"
    else
        echo "Keeping existing cron job. Cancelled."
        rm -f "$TEMP_CRON"
        exit 0
    fi
fi

# Dodaj nowy wpis
echo "# System Audit - Automatic reporting ($CRON_DESC)" >> "$TEMP_CRON"
echo "$CRON_LINE" >> "$TEMP_CRON"

# Zainstaluj nowy crontab
if crontab "$TEMP_CRON"; then
    print_success "Cron job installed successfully!"
    echo ""
    echo "Schedule: $CRON_DESC"
    echo ""
    echo "To view all cron jobs: crontab -l"
    echo "To remove this job: crontab -e"
    echo ""
else
    echo "ERROR: Failed to install cron job"
    rm -f "$TEMP_CRON"
    exit 1
fi

rm -f "$TEMP_CRON"

echo ""
print_warning "Note: Ensure SSH keys are configured for automatic report sending"
print_warning "Test manually first: $SEND_REPORT_SCRIPT"
echo ""
