# System Audit - Modularny System Raportowania Zasobów

**Modularny skrypt administracyjny w Bash do analizy i raportowania stanu kluczowych zasobów systemu Linux.**

---

## Spis treści

- [O projekcie](#o-projekcie)
- [Funkcjonalności](#funkcjonalności)
- [Wymagania systemowe](#wymagania-systemowe)
- [Quick Start](#quick-start)
- [Instalacja szczegółowa](#instalacja-szczegółowa)
- [Użycie](#użycie)
- [Konfiguracja](#konfiguracja)
- [Automatyzacja](#automatyzacja)
- [Architektura](#architektura)
- [Demo Commands](#demo-commands)
- [Rozwiązywanie problemów](#rozwiązywanie-problemów)

---

## O projekcie

System Audit to narzędzie stworzone w ramach kursu Systemy Operacyjne. Projekt demonstruje:

- **Interakcję z jądrem Linux** przez wirtualny system plików `/proc`
- **Zarządzanie procesami** i analiza ich stanu
- **Zarządzanie pamięcią** i obliczanie rzeczywistego zużycia RAM/Swap
- **Wykorzystanie narzędzi systemowych** (ps, df, awk, grep, ss, ip)
- **Modularną architekturę** dla łatwego rozszerzania funkcjonalności

Zamiast pisać w C, wykorzystujemy natywny język systemu operacyjnego (Bash) do efektywnej analizy zasobów systemowych.

---

## Funkcjonalności

### Moduły audytowe

1. **CPU (`--cpu`, `-c`)**
   - Średnie obciążenie (load average 1/5/15 min)
   - Model procesora (kompatybilny z x86, ARM, Apple Silicon)
   - Top 5 procesów wg zużycia CPU

2. **Pamięć (`--mem`, `-m`)**
   - Zużycie RAM (całkowita/dostępna/wykorzystana)
   - Ostrzeżenia przy przekroczeniu progu (domyślnie 90%)
   - Stan Swap

3. **Dysk (`--disk`, `-d`)**
   - Użycie wszystkich systemów plików
   - Wykrywanie partycji bliskich zapełnienia
   - Konfigurowalne progi alarmowe

4. **Sieć (`--net`, `-n`)**
   - Konfiguracja interfejsów sieciowych (IPv4)
   - Nasłuchujące porty TCP/UDP
   - Testy łączności (auto-detekcja admin/client)
     - **Admin mode**: Wykrywa klientów z ARP cache (gdy katalog `central_reports` istnieje lokalnie)
     - **Client mode**: Testuje połączenie do `CENTRAL_HOST` przez ping

5. **Bezpieczeństwo (`--sec`, `-s`)**
   - Obecnie zalogowani użytkownicy
   - Nieudane próby logowania (ostatnie 10)
   - Historia logowań

### Tryby pracy

- **Interaktywny** - menu wyboru modułów
- **Parametryzowany** - uruchamianie pojedynczych lub wielu modułów
- **Pełny audyt** - wszystkie moduły jednocześnie
- **Automatyczny** - cykliczne raportowanie przez cron/systemd

### Dodatkowe funkcje

- **Centralizacja raportów** - automatyczne wysyłanie przez SCP na host centralny
- **System logowania** - zapis wszystkich operacji z timestampem i użytkownikiem
- **Retry mechanism** - ponawianie wysyłki raportów przy błędach sieci
- **Plik konfiguracyjny** - łatwa personalizacja bez modyfikacji kodu

---

## Wymagania systemowe

### System operacyjny
- Linux (testowane na Ubuntu Server)
- Bash 4.0 lub nowszy

### Wymagane narzędzia
```bash
bash awk grep sed df ps ping ss ip ssh scp hostname date
```

Na Ubuntu/Debian:
```bash
sudo apt-get install coreutils procps iproute2 iputils-ping openssh-client
```

### Struktura sieci (dla automatycznego raportowania)
- 2 maszyny wirtualne Linux (klienty)
- 1 host centralny (admin) do zbierania raportów
- Skonfigurowane klucze SSH dla bezhasłowego dostępu

---

## Quick Start

Szybki przewodnik uruchomienia projektu na maszynach wirtualnych Ubuntu Server.

### Przed rozpoczęciem

**Potrzebujesz:**
- 2 maszyny wirtualne z Ubuntu Server (klienty)
- 1 host centralny (admin) do zbierania raportów
- Sieć łącząca wszystkie maszyny

**Przykładowa konfiguracja:**
```
Admin (Central):  192.168.64.3 (user: audit)
Client 1:         192.168.64.4
Client 2:         192.168.64.5
```

---

### Krok 1: Przygotowanie Central Host (192.168.64.3)

Na hoście centralnym:

```bash
# 1. Sklonuj projekt
cd ~
git clone <repository-url> projekt_audyt
cd projekt_audyt

# 2. Uruchom instalator
sudo ./install.sh
# Wybierz opcję 1 (production - /opt/sysaudit)

# 3. Utwórz użytkownika audit (jeśli nie istnieje)
sudo useradd -m -s /bin/bash audit
sudo passwd audit

# 4. Dodaj użytkownika do grupy adm (dostęp do logów)
sudo usermod -aG adm audit
```

**Katalog `central_reports` zostanie utworzony automatycznie przy pierwszym wysłaniu raportu przez klienta.**

---

### Krok 2: Instalacja na Client 1, Client 2

Na każdej maszynie wirtualnej wykonaj:

```bash
# 1. Sklonuj projekt
cd ~
git clone <repository-url> projekt_audyt
cd projekt_audyt

# 2. Uruchom instalator
sudo ./install.sh

# 3. Wybierz opcję 1 (production)
# Instalator:
# - Sprawdzi zależności
# - Stworzy katalogi
# - Skopiuje pliki do /opt/sysaudit
```

---

### Krok 3: Konfiguracja SSH keys

**Na każdej VM (klient):**

Instalator pokaże instrukcję SSH. Wykonaj następujące kroki:

```bash
# 1. Wygeneruj klucz SSH
ssh-keygen -t ed25519 -C "sysaudit@$(hostname)"
# Naciśnij Enter 3 razy (domyślna lokalizacja, bez hasła)

# 2. Skopiuj klucz na central host (zaktualizuj IP)
ssh-copy-id audit@192.168.64.3

# 3. Test połączenia
ssh audit@192.168.64.3 'echo SUCCESS'
```

---

### Krok 4: Edycja config.conf

Na każdej VM edytuj `/opt/sysaudit/config.conf`:

```bash
sudo nano /opt/sysaudit/config.conf
```

**Zaktualizuj adres central host:**
```bash
# Konfiguracja centralnego hosta (wysyłanie raportów)
# Connectivity test automatycznie wykrywa:
#  - Admin: pokazuje klientów z ARP cache (którzy wysłali raporty)
#  - Klient: testuje połączenie do CENTRAL_HOST
CENTRAL_HOST="192.168.64.3"    # <-- Twój central host
CENTRAL_USER="audit"
CENTRAL_DIR="/opt/sysaudit/central_reports"
```

Zapisz: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### Krok 5: Test manualny

```bash
# Test pojedynczego modułu
/opt/sysaudit/audyt_main.sh --cpu

# Test pełnego audytu
/opt/sysaudit/audyt_main.sh --full

# Test wysyłania raportu
sudo /opt/sysaudit/send_report.sh
```

**Sprawdź czy raport dotarł:**
```bash
# Na central host
ssh audit@192.168.64.3
ls -lh /opt/sysaudit/central_reports/
```

---

### Krok 6: Automatyzacja (wybierz jedną opcję)

#### Opcja A: Cron (prostsze)

```bash
/opt/sysaudit/setup_cron.sh

# W menu wybierz:
# 1) Every 6 hours
# lub
# 3) Daily at 2:00 AM
```

#### Opcja B: Systemd (nowocześniejsze)

```bash
sudo /opt/sysaudit/setup_systemd.sh

# W menu wybierz:
# 1) Install timer
```

---

### Weryfikacja

#### Sprawdź logi

```bash
# Logi audytu
sudo tail -f /opt/sysaudit/logs/audyt.log

# Logi systemd (jeśli używasz)
sudo journalctl -u sysaudit.service -f
```

#### Sprawdź raporty lokalne

```bash
ls -lh /opt/sysaudit/reports/
```

#### Sprawdź czy cron działa

```bash
crontab -l
```

#### Sprawdź timer systemd

```bash
sudo systemctl status sysaudit.timer
sudo systemctl list-timers sysaudit.timer
```

---

### Podgląd raportów na Central Host

Na hoście centralnym (192.168.64.3):

```bash
# Zaloguj jako audit
ssh audit@192.168.64.3

# Zobacz wszystkie raporty
ls -lh /opt/sysaudit/central_reports/

# Wyświetl najnowszy raport
cat /opt/sysaudit/central_reports/$(ls -t /opt/sysaudit/central_reports/ | head -1)

# Monitoruj na żywo
watch -n 60 'ls -lth /opt/sysaudit/central_reports/ | head -10'
```

---

### Harmonogram (przykład)

**Sugerowana konfiguracja dla 2 klientów:**

- **Client 1**: Raporty co 6 godzin (0:00, 6:00, 12:00, 18:00)
- **Client 2**: Raporty co 6 godzin (1:00, 7:00, 13:00, 19:00)

Dzięki rozłożeniu w czasie unikniesz jednoczesnego obciążenia sieci.

**Cron dla Client 1:**
```
0 */6 * * * /opt/sysaudit/send_report.sh
```

**Cron dla Client 2:**
```
0 1,7,13,19 * * * /opt/sysaudit/send_report.sh
```

---

### Gotowe!

Twój system audytu jest teraz w pełni skonfigurowany i działa automatycznie.

**Co się dzieje teraz:**
1. Każda VM wykonuje audyt w zaplanowanych godzinach
2. Raporty są zapisywane lokalnie w `reports/`
3. Raporty są wysyłane na central host przez SCP
4. Wszystkie operacje są logowane w `logs/audyt.log`

**Sprawdź za 6 godzin czy raporty pojawiają się na central host!**

---

## Instalacja szczegółowa

### Instalacja automatyczna

1. **Pobierz projekt**
   ```bash
   git clone <repository-url> /path/to/projekt_audyt
   cd /path/to/projekt_audyt
   ```

2. **Uruchom instalator**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

3. **Wybierz lokalizację**
   - Opcja 1: `/opt/sysaudit` (produkcja, wymaga sudo)
   - Opcja 2: Bieżący katalog (development)

4. **Skonfiguruj SSH** (opcjonalne)
   - Instalator wyświetli instrukcje 3-etapowego setupu SSH
   - Zobacz [Krok 3: Konfiguracja SSH keys](#krok-3-konfiguracja-ssh-keys) w Quick Start

### Konfiguracja hosta centralnego

**Na hoście centralnym (192.168.64.3):**

1. **Zainstaluj projekt**
   ```bash
   git clone <repository-url> ~/projekt_audyt
   cd ~/projekt_audyt
   sudo ./install.sh
   # Wybierz opcję 1 (/opt/sysaudit)
   ```

2. **Skonfiguruj użytkownika 'audit'** (jeśli nie istnieje)
   ```bash
   # Utwórz użytkownika
   sudo useradd -m -s /bin/bash audit
   sudo passwd audit

   # Dodaj do grupy 'adm' (dostęp do logów systemowych)
   sudo usermod -aG adm audit
   ```

3. **Katalog central_reports**
   - Tworzony **automatycznie** przez `send_report.sh` przy pierwszym raporcie
   - Nie musisz tworzyć go ręcznie
   - **Ważne**: Obecność tego katalogu służy do auto-detekcji trybu admin/client w module sieciowym
     - Jeśli katalog istnieje lokalnie → tryb admin (pokazuje klientów z ARP cache)
     - Jeśli katalog nie istnieje → tryb client (testuje ping do CENTRAL_HOST)

4. **Przygotuj SSH dla klientów**
   - Na każdej maszynie klienckiej (Client 1, Client 2):
   ```bash
   ssh-keygen -t ed25519 -C "sysaudit@$(hostname)"
   ssh-copy-id audit@192.168.64.3
   ```

   - Przetestuj połączenie:
   ```bash
   ssh audit@192.168.64.3 'echo SUCCESS'
   ```

### Instalacja ręczna

```bash
# Utwórz strukturę katalogów
sudo mkdir -p /opt/sysaudit/{modules,logs,reports}

# Skopiuj pliki
sudo cp audyt_main.sh audyt_lib.sh send_report.sh config.conf /opt/sysaudit/
sudo cp modules/*.sh /opt/sysaudit/modules/

# Ustaw uprawnienia
sudo chmod +x /opt/sysaudit/*.sh
sudo chmod +x /opt/sysaudit/modules/*.sh
```

---

## Użycie

### Tryb interaktywny (menu)

```bash
/opt/sysaudit/audyt_main.sh
```

Wyświetli menu wyboru modułów:
```
=== MENU MODUŁÓW ===
1. Audyt CPU
2. Audyt RAM
3. Audyt Dysku
4. Audyt Sieci
5. Audyt Bezpieczeństwa
0. Wyjście
```

### Tryb parametryzowany

```bash
# Pojedynczy moduł
./audyt_main.sh --cpu          # lub -c
./audyt_main.sh --mem          # lub -m
./audyt_main.sh --disk         # lub -d
./audyt_main.sh --net          # lub -n
./audyt_main.sh --sec          # lub -s

# Wiele modułów
./audyt_main.sh --cpu --mem    # CPU i pamięć
./audyt_main.sh -c -m -d       # CPU, pamięć i dysk

# Pełny audyt
./audyt_main.sh --full         # lub -f
```

### Wysyłanie raportu na host centralny

```bash
/opt/sysaudit/send_report.sh
```

Skrypt:
1. Wykonuje pełny audyt (`--full`)
2. Zapisuje raport lokalnie w `reports/`
3. Wysyła raport przez SCP na host centralny
4. Powtarza próby przy błędach (3 razy domyślnie)

### Pomoc

```bash
./audyt_main.sh --help
```

---

## Konfiguracja

### Plik config.conf

Główny plik konfiguracyjny: `/opt/sysaudit/config.conf`

```bash
# Struktura katalogów (automatycznie wykrywana)
INSTALL_DIR="/opt/sysaudit"
MODULE_DIR="${INSTALL_DIR}/modules"
LOG_DIR="${INSTALL_DIR}/logs"
REPORT_DIR="${INSTALL_DIR}/reports"

# Konfiguracja centralnego hosta (wysyłanie raportów)
# Connectivity test automatycznie wykrywa:
#  - Admin: pokazuje klientów z ARP cache (którzy wysłali raporty)
#  - Klient: testuje połączenie do CENTRAL_HOST
CENTRAL_HOST="192.168.64.3"
CENTRAL_USER="audit"
CENTRAL_DIR="/opt/sysaudit/central_reports"

# Timeouty
SSH_TIMEOUT=10
PING_TIMEOUT=1
PING_COUNT=3

# Retry dla SCP
SCP_RETRY_COUNT=3
SCP_RETRY_DELAY=5

# Progi alarmowe
MEM_WARNING_THRESHOLD=90    # procent
DISK_WARNING_THRESHOLD=90   # procent
```

### Personalizacja

1. **Zmiana hosta centralnego**
   ```bash
   CENTRAL_HOST="10.0.1.100"
   CENTRAL_USER="sysadmin"
   CENTRAL_DIR="/var/reports/sysaudit"
   ```

2. **Dostosowanie progów alarmowych**
   ```bash
   MEM_WARNING_THRESHOLD=80    # alarm przy 80% RAM
   DISK_WARNING_THRESHOLD=85   # alarm przy 85% dysku
   ```

---

## Automatyzacja

### Opcja 1: Cron (tradycyjny)

```bash
# Uruchom interaktywny konfigurator
./setup_cron.sh
```

Lub ręcznie:
```bash
# Edytuj crontab
crontab -e

# Dodaj wpis (np. co 6 godzin)
0 */6 * * * /opt/sysaudit/send_report.sh > /dev/null 2>&1
```

Przykłady harmonogramów:
- `0 */6 * * *` - co 6 godzin
- `0 2 * * *` - codziennie o 2:00
- `0 2 * * 1` - w poniedziałki o 2:00

### Opcja 2: Systemd Timer (nowoczesny)

```bash
# Instalacja
sudo ./setup_systemd.sh
# Wybierz opcję 1 (Install timer)

# Sprawdzenie statusu
sudo systemctl status sysaudit.timer

# Lista następnych uruchomień
systemctl list-timers sysaudit.timer

# Logi
journalctl -u sysaudit.service -f
```

Konfiguracja timera: `sysaudit.timer`
- Domyślnie: co 6 godzin
- Randomizacja: ±5 minut (unika skoków obciążenia)
- Persistent: wykonuje przy starcie jeśli pominięto

---

## Architektura

### Struktura projektu

```
projekt_audyt/
├── audyt_main.sh          # Główny skrypt (menu + parsowanie parametrów)
├── audyt_lib.sh           # Biblioteka współdzielona (logowanie, kolory)
├── config.conf            # Plik konfiguracyjny
├── send_report.sh         # Skrypt wysyłający raporty na host centralny
├── install.sh             # Instalator
├── setup_cron.sh          # Konfigurator cron
├── setup_systemd.sh       # Konfigurator systemd
├── sysaudit.service       # Jednostka systemd
├── sysaudit.timer         # Timer systemd
├── README.md              # Dokumentacja
├── modules/               # Moduły audytowe
│   ├── mod_cpu.sh         # Audyt CPU
│   ├── mod_mem.sh         # Audyt pamięci
│   ├── mod_disk.sh        # Audyt dysku
│   ├── mod_net.sh         # Audyt sieci
│   └── mod_sec.sh         # Audyt bezpieczeństwa
├── logs/                  # Logi systemowe
│   └── audyt.log
└── reports/               # Raporty lokalne
    └── hostname_timestamp.txt
```

### Przepływ danych

```
┌─────────────────┐
│  audyt_main.sh  │ ◄── Wywołanie użytkownika (--cpu, --full, etc.)
└────────┬────────┘
         │
         ├─► [Parsowanie parametrów]
         │
         ├─► config.conf        ◄── Załadowanie konfiguracji
         ├─► audyt_lib.sh       ◄── Funkcje pomocnicze
         │
         └─► modules/mod_*.sh   ◄── Uruchomienie wybranych modułów
                  │
                  ├─► /proc/cpuinfo, /proc/meminfo  (odczyt jądra)
                  ├─► ps, df, ss, ip                (narzędzia)
                  │
                  └─► logs/audyt.log                (zapis logów)

┌─────────────────┐
│ send_report.sh  │ ◄── Cron / Systemd / Ręcznie
└────────┬────────┘
         │
         ├─► audyt_main.sh --full  ◄── Pełny audyt
         │
         ├─► reports/hostname_timestamp.txt  ◄── Zapis lokalny
         │
         └─► SCP → Central Host              ◄── Wysłanie (z retry)
```

### Topologia sieci (przykład)

```
┌──────────────────────────────────────────────────┐
│         Admin (Central) - 192.168.64.3           │
│  - Zbiera raporty od klientów                    │
│  - Katalog: /opt/sysaudit/central_reports        │
│  - User: audit (SSH key authentication)          │
└────────────────────┬─────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐   ┌────────────▼──┐
│  Client 1      │   │  Client 2      │
│ (192.168.64.4) │   │ (192.168.64.5) │
│                │   │                │
│ - audyt_main   │   │ - audyt_main   │
│ - cron/systemd │   │ - cron/systemd │
│ - send_report  │   │ - send_report  │
└────────────────┘   └────────────────┘
```

---

## Demo Commands

Szybka ściągawka z najważniejszymi komendami.

### === PODSTAWOWE KOMENDY ===

**1. POMOC**
```bash
/opt/sysaudit/audyt_main.sh --help
```
Output:
```
Usage: audyt_main.sh [OPTION]

System Audit - Modular system resource auditing tool

OPTIONS:
    --full, -f          Run full audit (all modules)
    --cpu,  -c          CPU audit only
    --mem,  -m          Memory audit only
    --disk, -d          Disk audit only
    --net,  -n          Network audit only
    --sec,  -s          Security audit only
    --help, -h          Show this help message

EXAMPLES:
    audyt_main.sh              # Interactive menu
    audyt_main.sh --full       # Full audit
    audyt_main.sh --cpu        # CPU audit only
    audyt_main.sh -m -d        # Memory and disk audit
```

**2. MENU INTERAKTYWNE**
```bash
/opt/sysaudit/audyt_main.sh
```

**3. POJEDYNCZY MODUŁ**
```bash
/opt/sysaudit/audyt_main.sh --cpu
/opt/sysaudit/audyt_main.sh --mem
/opt/sysaudit/audyt_main.sh --disk
/opt/sysaudit/audyt_main.sh --net
/opt/sysaudit/audyt_main.sh --sec
```

**4. WIELE MODUŁÓW**
```bash
/opt/sysaudit/audyt_main.sh -c -m -d
```

**5. PEŁNY AUDYT**
```bash
/opt/sysaudit/audyt_main.sh --full
/opt/sysaudit/audyt_main.sh -f
```

---

### === RAPORTOWANIE ===

**6. WYŚLIJ RAPORT NA CENTRAL HOST**
```bash
/opt/sysaudit/send_report.sh
```

**7. ZOBACZ LOKALNE RAPORTY**
```bash
ls -lh /opt/sysaudit/reports/
cat /opt/sysaudit/reports/$(hostname)_*.txt | head -50
```

**8. ZOBACZ RAPORTY NA ADMIN (tylko na 192.168.64.3)**
```bash
ls -lh /opt/sysaudit/central_reports/
cat /opt/sysaudit/central_reports/vm-client1_*.txt | head -100
```

---

### === LOGI I MONITORING ===

**9. ZOBACZ LOGI**
```bash
tail -20 /opt/sysaudit/logs/audyt.log
tail -f /opt/sysaudit/logs/audyt.log
```

**10. FILTRUJ LOGI PER MODUŁ**
```bash
grep "CPU" /opt/sysaudit/logs/audyt.log | tail -5
grep "MEM" /opt/sysaudit/logs/audyt.log | tail -5
grep "SEC" /opt/sysaudit/logs/audyt.log | tail -5
```

---

### === KONFIGURACJA ===

**11. POKAŻ CONFIG**
```bash
cat /opt/sysaudit/config.conf
```

**12. SPRAWDŹ UPRAWNIENIA**
```bash
ls -ld /opt/sysaudit/logs /opt/sysaudit/reports
```

**13. SPRAWDŹ STRUKTURĘ**
```bash
tree /opt/sysaudit -L 2
# lub
ls -lR /opt/sysaudit/
```

---

### === AUTOMATYZACJA ===

**14. POKAŻ CRON**
```bash
crontab -l
```

**15. EDYTUJ CRON**
```bash
crontab -e
```

**16. SPRAWDŹ STATUS SYSTEMD (jeśli używasz)**
```bash
systemctl status sysaudit.timer
systemctl list-timers sysaudit.timer
```

---

### === SSH I SIEĆ ===

**17. TEST SSH DO ADMIN**
```bash
ssh audit@192.168.64.3 'echo SUCCESS from $(hostname)'
```

**18. TEST ŁĄCZNOŚCI**
```bash
ping -c3 192.168.64.3
```

**19. SPRAWDŹ KLUCZE SSH**
```bash
ls -la ~/.ssh/id_*
```

---

### === TESTY FUNKCJONALNOŚCI ===

**20. TEST CPU NA ARM**
```bash
/opt/sysaudit/audyt_main.sh --cpu | grep -A 3 "CPU model"
# Powinno pokazać: Architecture: aarch64
```

**21. TEST PROGÓW ALARMOWYCH**
```bash
/opt/sysaudit/audyt_main.sh --mem
# Sprawdź czy pokazuje WARNING gdy > 90%
```

**22. TEST RETRY MECHANISM**
```bash
# Wyłącz Admin VM i:
/opt/sysaudit/send_report.sh
# Powinno próbować 3 razy z 5s opóźnieniem
```

**23. TEST AUTH.LOG**
```bash
/opt/sysaudit/audyt_main.sh --sec
# Sprawdź czy pokazuje failed logins lub komunikat o grupie adm
```

---

### === DEBUGGING ===

**24. SPRAWDŹ CZY MODUŁY SĄ EXECUTABLE**
```bash
ls -l /opt/sysaudit/modules/*.sh
```

**25. SPRAWDŹ CZY GŁÓWNE SKRYPTY SĄ EXECUTABLE**
```bash
ls -l /opt/sysaudit/*.sh
```

**26. SPRAWDŹ GRUPĘ ADM**
```bash
groups
# Powinno zawierać 'adm'
```

**27. MANUAL TEST MODUŁU**
```bash
bash /opt/sysaudit/modules/mod_cpu.sh
```

---

### === INSTALACJA (dla przypomnienia) ===

**28. ŚWIEŻA INSTALACJA**
```bash
cd ~/projekt_audyt
git pull origin main
sudo ./install.sh
```

**29. USUŃ INSTALACJĘ**
```bash
sudo rm -rf /opt/sysaudit
crontab -r
```

**30. SETUP SSH**
```bash
ssh-keygen -t ed25519 -C "sysaudit@$(hostname)"
ssh-copy-id audit@192.168.64.3
```

---

### === STATYSTYKI (dla Admin) ===

**31. LICZBA RAPORTÓW**
```bash
ls -1 /opt/sysaudit/central_reports/ | wc -l
```

**32. RAPORTY PER KLIENT**
```bash
ls -1 /opt/sysaudit/central_reports/ | grep client1 | wc -l
ls -1 /opt/sysaudit/central_reports/ | grep client2 | wc -l
```

**33. ROZMIAR RAPORTÓW**
```bash
du -sh /opt/sysaudit/central_reports/
```

**34. NAJNOWSZE RAPORTY**
```bash
ls -lth /opt/sysaudit/central_reports/ | head -10
```

**35. NAJSTARSZE RAPORTY**
```bash
ls -lt /opt/sysaudit/central_reports/ | tail -10
```

---

### === DEMO SCENARIUSZE ===

**SCENARIUSZ 1: Podstawowe funkcje (Client VM)**
```bash
/opt/sysaudit/audyt_main.sh --help
/opt/sysaudit/audyt_main.sh --cpu
/opt/sysaudit/audyt_main.sh --full
```

**SCENARIUSZ 2: Wysyłanie raportów (Client → Admin)**
```bash
# Na Client:
/opt/sysaudit/send_report.sh
# Na Admin:
ls -lh /opt/sysaudit/central_reports/
cat /opt/sysaudit/central_reports/vm-client1_*.txt
```

**SCENARIUSZ 3: Automatyzacja**
```bash
crontab -l
tail -20 /opt/sysaudit/logs/audyt.log
```

**SCENARIUSZ 4: Konfiguracja**
```bash
cat /opt/sysaudit/config.conf
# Pokaż: progi, retry, timeouty
```

---

### === QUICK TIPS ===

- CPU na ARM musi pokazywać: "Architecture: aarch64"
- Logi muszą mieć uprawnienia: audit:audit (NIE root:root!)
- SSH musi działać bezhasłowo: `ssh audit@192.168.64.3 'echo TEST'`
- Cron: `0 */6 * * *` = co 6 godzin
- Retry: 3 próby z 5s opóźnieniem
- Grupa adm: dostęp do /var/log/auth.log
- Connectivity test: auto-detekcja admin/client przez ARP cache

---

### === PRZYKŁADOWA KONFIGURACJA SIECI ===

```
Admin (Central):  192.168.64.3
Client 1:         192.168.64.4
Client 2:         192.168.64.5

Użytkownik:       audit
Katalog:          /opt/sysaudit
Central reports:  /opt/sysaudit/central_reports/ (tylko na admin)
```

---

## Rozwiązywanie problemów

### Problem: "Configuration file not found"

**Rozwiązanie:**
```bash
# Sprawdź czy config.conf istnieje w katalogu instalacji
ls -l /opt/sysaudit/config.conf

# Jeśli nie, uruchom ponownie instalator
sudo ./install.sh
```

### Problem: SCP timeout / Cannot connect to central host

**Rozwiązanie:**
```bash
# 1. Sprawdź łączność sieciową
ping -c3 192.168.64.3

# 2. Sprawdź czy SSH działa
ssh audit@192.168.64.3 "exit"

# 3. Skonfiguruj klucze SSH
ssh-keygen -t ed25519
ssh-copy-id audit@192.168.64.3

# 4. Dostosuj timeout w config.conf
SSH_TIMEOUT=30  # zwiększ wartość
```

### Problem: "Permission denied" przy zapisie logów

**Rozwiązanie:**
```bash
# Sprawdź uprawnienia
ls -ld /opt/sysaudit/logs

# Napraw uprawnienia
sudo chown -R $USER:$USER /opt/sysaudit/logs
sudo chmod 755 /opt/sysaudit/logs
```

### Problem: Moduł nie wyświetla danych

**Rozwiązanie:**
```bash
# Sprawdź zależności
which ps df ss ip

# Ubuntu/Debian
sudo apt-get install procps iproute2 iputils-ping
```

### Problem: "Cannot access /var/log/auth.log" w module Security

**Rozwiązanie:**
```bash
# Dodaj użytkownika do grupy 'adm' (dostęp do logów systemowych)
sudo usermod -aG adm $USER

# Wyloguj się i zaloguj ponownie (lub użyj newgrp)
newgrp adm

# Sprawdź członkostwo w grupach
groups
```

**Uwaga:** Plik `/var/log/auth.log` zawiera wrażliwe informacje bezpieczeństwa i wymaga uprawnień grupy `adm`.

