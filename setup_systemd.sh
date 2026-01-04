#!/bin/bash
# =============================================================================
# Skrypt do konfiguracji systemd timer dla automatycznych raportów
# =============================================================================

set -euo pipefail

# Kolory
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
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

print_error() {
    echo -e "${RED}${BOLD}✗${RESET} $*" >&2
}

# Sprawdź czy uruchomione jako root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (systemd requires it)"
    echo "Please run: sudo $0"
    exit 1
fi

# Sprawdź czy systemd jest dostępny
if ! command -v systemctl &>/dev/null; then
    print_error "systemd is not available on this system"
    echo "Use setup_cron.sh instead"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="${SCRIPT_DIR}/sysaudit.service"
TIMER_FILE="${SCRIPT_DIR}/sysaudit.timer"

SYSTEMD_DIR="/etc/systemd/system"

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "  System Audit - Systemd Timer Setup"
echo "=========================================="
echo -e "${RESET}"
echo ""

# Sprawdź czy pliki istnieją
if [[ ! -f "$SERVICE_FILE" ]] || [[ ! -f "$TIMER_FILE" ]]; then
    print_error "Service or timer file not found"
    echo "Expected files:"
    echo "  $SERVICE_FILE"
    echo "  $TIMER_FILE"
    exit 1
fi

print_step "Current configuration:"
echo ""
echo "Service: sysaudit.service"
echo "Timer: sysaudit.timer (every 6 hours)"
echo ""

# Menu wyboru akcji
echo "Select action:"
echo ""
echo "  1) Install timer (enable automatic audits)"
echo "  2) Uninstall timer"
echo "  3) Show timer status"
echo "  4) Test service manually"
echo "  0) Cancel"
echo ""

read -p "Choice [0-4]: " choice

case "$choice" in
    1)
        print_step "Installing systemd timer..."

        # Kopiuj pliki
        cp "$SERVICE_FILE" "$SYSTEMD_DIR/"
        cp "$TIMER_FILE" "$SYSTEMD_DIR/"
        print_success "Files copied to $SYSTEMD_DIR"

        # Przeładuj systemd
        systemctl daemon-reload
        print_success "Systemd daemon reloaded"

        # Włącz i uruchom timer
        systemctl enable sysaudit.timer
        systemctl start sysaudit.timer
        print_success "Timer enabled and started"

        echo ""
        print_success "Installation complete!"
        echo ""
        echo "Timer status:"
        systemctl status sysaudit.timer --no-pager || true
        echo ""
        echo "Next scheduled run:"
        systemctl list-timers sysaudit.timer --no-pager || true
        echo ""
        ;;

    2)
        print_step "Uninstalling systemd timer..."

        # Zatrzymaj i wyłącz
        systemctl stop sysaudit.timer 2>/dev/null || true
        systemctl disable sysaudit.timer 2>/dev/null || true
        print_success "Timer stopped and disabled"

        # Usuń pliki
        rm -f "$SYSTEMD_DIR/sysaudit.service"
        rm -f "$SYSTEMD_DIR/sysaudit.timer"
        print_success "Files removed"

        # Przeładuj
        systemctl daemon-reload
        print_success "Systemd daemon reloaded"

        echo ""
        print_success "Uninstallation complete!"
        echo ""
        ;;

    3)
        print_step "Timer status:"
        echo ""
        if systemctl is-active sysaudit.timer &>/dev/null; then
            systemctl status sysaudit.timer --no-pager
            echo ""
            print_step "Next scheduled run:"
            systemctl list-timers sysaudit.timer --no-pager
        else
            print_warning "Timer is not active"
            echo "Run option 1 to install and enable it"
        fi
        echo ""
        ;;

    4)
        print_step "Running service manually (for testing)..."
        echo ""
        systemctl start sysaudit.service
        echo ""
        print_step "Service output:"
        journalctl -u sysaudit.service -n 50 --no-pager
        echo ""
        ;;

    0)
        echo "Cancelled."
        exit 0
        ;;

    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_warning "Useful commands:"
echo "  View logs:        journalctl -u sysaudit.service -f"
echo "  Timer status:     systemctl status sysaudit.timer"
echo "  List all timers:  systemctl list-timers"
echo "  Stop timer:       sudo systemctl stop sysaudit.timer"
echo ""
