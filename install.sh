#!/bin/bash
# =============================================================================
# Skrypt instalacyjny dla System Audit
# =============================================================================

set -euo pipefail

# Kolory
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# Funkcje pomocnicze
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

# Sprawdź czy skrypt uruchomiony jako root (opcjonalne dla /opt)
check_root() {
    if [[ "$INSTALL_TARGET" == "/opt/sysaudit" ]] && [[ $EUID -ne 0 ]]; then
        print_error "Installation to /opt/sysaudit requires root privileges"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Wykryj system operacyjny
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi
}

# Sprawdź wymagane narzędzia
check_dependencies() {
    print_step "Checking system dependencies..."

    local missing_deps=()
    local all_deps=(bash awk grep sed df ps ping ss ip ssh scp hostname date)

    for cmd in "${all_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
            print_warning "Missing: $cmd"
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "On Ubuntu/Debian, install with:"
        echo "  sudo apt-get install coreutils procps iproute2 iputils-ping openssh-client"
        echo ""
        return 1
    else
        print_success "All dependencies found"
        return 0
    fi
}

# Tworzenie struktury katalogów
create_directories() {
    print_step "Creating directory structure..."

    local dirs=("$INSTALL_TARGET" "$INSTALL_TARGET/modules" "$INSTALL_TARGET/logs" "$INSTALL_TARGET/reports")

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
        else
            print_warning "Already exists: $dir"
        fi
    done

    # NOWE: Ustaw poprawne uprawnienia dla użytkownika
    if [[ "$INSTALL_TARGET" == "/opt/sysaudit" ]]; then
        # W trybie production, upewnij się że user może pisać do logs i reports
        print_step "Setting permissions for logs and reports..."
        
        # Jeśli uruchomione przez sudo, daj uprawnienia prawdziwemu userowi
        if [[ -n "${SUDO_USER}" ]]; then
            chown -R "${SUDO_USER}:${SUDO_USER}" "$INSTALL_TARGET/logs"
            chown -R "${SUDO_USER}:${SUDO_USER}" "$INSTALL_TARGET/reports"
            print_success "Ownership set to: ${SUDO_USER}"
        else
            chown -R "$USER:$USER" "$INSTALL_TARGET/logs"
            chown -R "$USER:$USER" "$INSTALL_TARGET/reports"
            print_success "Ownership set to: $USER"
        fi
        
        chmod 755 "$INSTALL_TARGET/logs"
        chmod 755 "$INSTALL_TARGET/reports"
        print_success "Permissions set: 755"
    else
        # W trybie development
        chmod 755 "$INSTALL_TARGET/logs"
        chmod 755 "$INSTALL_TARGET/reports"
    fi
}

# Kopiowanie plików
copy_files() {
    print_step "Copying files..."

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Główne skrypty
    cp "$script_dir/audyt_main.sh" "$INSTALL_TARGET/"
    cp "$script_dir/audyt_lib.sh" "$INSTALL_TARGET/"
    cp "$script_dir/send_report.sh" "$INSTALL_TARGET/"
    cp "$script_dir/config.conf" "$INSTALL_TARGET/"
    print_success "Copied main scripts"

    # Moduły
    cp "$script_dir/modules"/*.sh "$INSTALL_TARGET/modules/"
    print_success "Copied modules"

    # Ustaw uprawnienia wykonywania
    chmod +x "$INSTALL_TARGET"/*.sh
    chmod +x "$INSTALL_TARGET/modules"/*.sh
    print_success "Set executable permissions"

    # Ustaw właściciela całego katalogu /opt/sysaudit (fix permission issue)
    if [[ "$INSTALL_TARGET" == "/opt/sysaudit" ]]; then
        print_step "Setting ownership for /opt/sysaudit..."
        if [[ -n "${SUDO_USER}" ]]; then
            chown -R "${SUDO_USER}:${SUDO_USER}" "$INSTALL_TARGET"
            print_success "Set ownership to: ${SUDO_USER}:${SUDO_USER}"
        else
            chown -R "$USER:$USER" "$INSTALL_TARGET"
            print_success "Set ownership to: $USER:$USER"
        fi
        chmod 755 "$INSTALL_TARGET"
        chmod 755 "$INSTALL_TARGET/logs"
        chmod 755 "$INSTALL_TARGET/reports"
        chmod 755 "$INSTALL_TARGET/modules"
        print_success "Set correct permissions (755)"
    fi
}

# Aktualizacja ścieżek w config.conf dla instalacji w /opt
update_config() {
    if [[ "$INSTALL_TARGET" != "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ]]; then
        print_step "Updating configuration paths..."

        # W zainstalowanej wersji używamy bezpośrednio INSTALL_TARGET
        sed -i.bak "s|^INSTALL_DIR=.*|INSTALL_DIR=\"$INSTALL_TARGET\"|" "$INSTALL_TARGET/config.conf"
        rm -f "$INSTALL_TARGET/config.conf.bak"

        print_success "Configuration updated for $INSTALL_TARGET"
    fi
}

# Konfiguracja SSH dla central host (opcjonalne)
configure_ssh() {
    print_step "SSH Configuration (optional)"

    echo ""
    echo "For automatic report sending, you need to configure SSH key authentication"
    echo "to the central host specified in config.conf"
    echo ""
    echo "Current central host: 192.168.64.3 (audit@192.168.64.3)"
    echo ""

    read -p "Do you want to setup SSH key now? [y/N]: " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ ! -f ~/.ssh/id_rsa ]] && [[ ! -f ~/.ssh/id_ed25519 ]]; then
            print_step "Generating SSH key..."
            ssh-keygen -t ed25519 -C "sysaudit@$(hostname)" -N "" -f ~/.ssh/id_ed25519
            print_success "SSH key generated: ~/.ssh/id_ed25519"
        fi

        echo ""
        echo "Now copy the SSH key to central host:"
        echo "  ssh-copy-id audit@192.168.64.3"
        echo ""
    else
        print_warning "Skipped SSH configuration"
        print_warning "Configure it later for automatic report sending"
    fi
}

# Test instalacji
test_installation() {
    print_step "Testing installation..."

    # Test czy główny skrypt działa
    if "$INSTALL_TARGET/audyt_main.sh" --help &>/dev/null; then
        print_success "Main script is working (--help responds)"
    else
        print_error "Main script test failed"
        return 1
    fi

    # Test czy moduły są dostępne
    local module_count=$(ls -1 "$INSTALL_TARGET/modules"/*.sh 2>/dev/null | wc -l)
    if [[ $module_count -eq 5 ]]; then
        print_success "All 5 modules found"
    else
        print_error "Expected 5 modules, found $module_count"
        return 1
    fi

    return 0
}

# Wyświetl podsumowanie
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}=========================================="
    echo "  Installation Complete!"
    echo -e "==========================================${RESET}"
    echo ""
    echo "Installation directory: $INSTALL_TARGET"
    echo ""
    echo "Usage:"
    echo "  Interactive menu:    $INSTALL_TARGET/audyt_main.sh"
    echo "  Full audit:          $INSTALL_TARGET/audyt_main.sh --full"
    echo "  Send report:         $INSTALL_TARGET/send_report.sh"
    echo ""
    echo "Configuration file: $INSTALL_TARGET/config.conf"
    echo "Log file:           $INSTALL_TARGET/logs/audyt.log"
    echo "Reports:            $INSTALL_TARGET/reports/"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $INSTALL_TARGET/config.conf to customize settings"
    echo "  2. Configure SSH key for central host (if needed)"
    echo "  3. Run test: $INSTALL_TARGET/audyt_main.sh --full"
    echo "  4. Setup cron job for automatic reporting (optional)"
    echo ""
}

# =============================================================================
# Main Installation
# =============================================================================

main() {
    echo -e "${CYAN}${BOLD}"
    echo "=========================================="
    echo "  System Audit - Installation Script"
    echo "=========================================="
    echo -e "${RESET}"

    # Wykryj system
    detect_os
    print_step "Detected OS: $OS_NAME $OS_VERSION"

    # Wybór lokalizacji instalacji
    echo ""
    echo "Select installation location:"
    echo "  1) /opt/sysaudit (production, requires sudo)"
    echo "  2) Current directory (development)"
    echo ""
    read -p "Choice [1-2]: " -n 1 -r choice
    echo ""

    case "$choice" in
        1)
            INSTALL_TARGET="/opt/sysaudit"
            check_root
            ;;
        2)
            INSTALL_TARGET="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            print_warning "Installing in development mode: $INSTALL_TARGET"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    echo ""

    # Sprawdź zależności
    if ! check_dependencies; then
        exit 1
    fi

    echo ""

    # Twórz katalogi
    create_directories

    echo ""

    # Kopiuj pliki (jeśli nie instalujemy w bieżącym katalogu)
    if [[ "$INSTALL_TARGET" != "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ]]; then
        copy_files
        update_config
    else
        print_step "Development mode - using files in place"
        # Upewnij się że katalogi istnieją
        mkdir -p logs reports
    fi

    echo ""

    # Test
    if test_installation; then
        echo ""

        # Opcjonalna konfiguracja SSH
        configure_ssh

        echo ""

        # Podsumowanie
        show_summary

        exit 0
    else
        print_error "Installation test failed"
        exit 1
    fi
}

# Uruchom instalację
main "$@"
