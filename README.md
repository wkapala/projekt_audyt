# System Audit - Modularny System Raportowania Zasobów

**Modularny skrypt administracyjny w Bash do analizy i raportowania stanu kluczowych zasobów systemu Linux.**

---

## 📋 Spis treści

- [O projekcie](#o-projekcie)
- [Funkcjonalności](#funkcjonalności)
- [Wymagania systemowe](#wymagania-systemowe)
- [Instalacja](#instalacja)
- [Użycie](#użycie)
- [Konfiguracja](#konfiguracja)
- [Automatyzacja](#automatyzacja)
- [Architektura](#architektura)
- [Przykłady](#przykłady)

---

## 🎯 O projekcie

System Audit to narzędzie stworzone w ramach kursu Systemy Operacyjne. Projekt demonstruje:

- **Interakcję z jądrem Linux** przez wirtualny system plików `/proc`
- **Zarządzanie procesami** i analiza ich stanu
- **Zarządzanie pamięcią** i obliczanie rzeczywistego zużycia RAM/Swap
- **Wykorzystanie narzędzi systemowych** (ps, df, awk, grep, ss, ip)
- **Modularną architekturę** dla łatwego rozszerzania funkcjonalności

Zamiast pisać w C, wykorzystujemy natywny język systemu operacyjnego (Bash) do efektywnej analizy zasobów systemowych.

---

## ✨ Funkcjonalności

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
   - Testy łączności do określonych hostów

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

## 📦 Wymagania systemowe

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
- 3 maszyny wirtualne Linux (klienty)
- 1 host centralny do zbierania raportów
- Skonfigurowane klucze SSH dla bezhasłowego dostępu

---

## 🚀 Instalacja

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
   - Instalator pomoże wygenerować klucz SSH
   - Następnie uruchom: `ssh-copy-id audit@192.168.64.3`

### Konfiguracja hosta centralnego

**Na hoście centralnym (192.168.64.3):**

1. **Zainstaluj projekt**
   ```bash
   git clone <repository-url> ~/projekt_audyt
   cd ~/projekt_audyt
   sudo ./install.sh
   # Wybierz opcję 1 (/opt/sysaudit)
   ```

2. **Utwórz katalog do zbierania raportów**
   ```bash
   mkdir -p /opt/sysaudit/central_reports
   chmod 755 /opt/sysaudit/central_reports
   ```

3. **Skonfiguruj użytkownika 'audit'** (jeśli nie istnieje)
   ```bash
   # Utwórz użytkownika
   sudo useradd -m -s /bin/bash audit
   sudo passwd audit

   # Dodaj do grupy 'adm' (dostęp do logów systemowych)
   sudo usermod -a -G adm audit
   ```

4. **Przygotuj SSH dla klientów**
   - Na każdej maszynie klienckiej (VM1, VM2, VM3):
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

## 💻 Użycie

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

## ⚙️ Konfiguracja

### Plik config.conf

Główny plik konfiguracyjny: `/opt/sysaudit/config.conf`

```bash
# Struktura katalogów (automatycznie wykrywana)
INSTALL_DIR="/opt/sysaudit"
MODULE_DIR="${INSTALL_DIR}/modules"
LOG_DIR="${INSTALL_DIR}/logs"
REPORT_DIR="${INSTALL_DIR}/reports"

# Konfiguracja sieci
PING_TARGETS=("192.168.64.3" "192.168.64.4" "192.168.64.5")
CENTRAL_HOST="192.168.64.3"
CENTRAL_USER="audit"
CENTRAL_DIR="/opt/sysaudit/central_reports"

# Timeouty
SSH_TIMEOUT=10
PING_TIMEOUT=1

# Retry dla SCP
SCP_RETRY_COUNT=3
SCP_RETRY_DELAY=5

# Progi alarmowe
MEM_WARNING_THRESHOLD=90    # procent
DISK_WARNING_THRESHOLD=90   # procent
```

### Personalizacja

1. **Zmiana hostów do testowania**
   ```bash
   PING_TARGETS=("10.0.0.1" "10.0.0.2" "google.com")
   ```

2. **Zmiana hosta centralnego**
   ```bash
   CENTRAL_HOST="10.0.1.100"
   CENTRAL_USER="sysadmin"
   CENTRAL_DIR="/var/reports/sysaudit"
   ```

3. **Dostosowanie progów alarmowych**
   ```bash
   MEM_WARNING_THRESHOLD=80    # alarm przy 80% RAM
   DISK_WARNING_THRESHOLD=85   # alarm przy 85% dysku
   ```

---

## ⏰ Automatyzacja

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

## 🏗️ Architektura

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
│              Central Host (192.168.64.3)         │
│  - Zbiera raporty od wszystkich VM               │
│  - Katalog: /opt/sysaudit/central_reports        │
│  - User: audit (SSH key authentication)          │
└────────────────────┬─────────────────────────────┘
                     │
        ┌────────────┴────────────┬────────────┐
        │                         │            │
┌───────▼────────┐   ┌────────────▼──┐   ┌────▼─────────┐
│  VM1           │   │  VM2           │   │  VM3         │
│ (192.168.64.4) │   │ (192.168.64.5) │   │ (...)        │
│                │   │                │   │              │
│ - audyt_main   │   │ - audyt_main   │   │ - audyt_main │
│ - cron/systemd │   │ - cron/systemd │   │ - cron/systemd│
│ - send_report  │   │ - send_report  │   │ - send_report│
└────────────────┘   └────────────────┘   └──────────────┘
```

---

## 📊 Przykłady

### Przykład 1: Audyt CPU

```bash
$ ./audyt_main.sh --cpu

==========================================
          SYSTEM AUDIT REPORT
  Host:      ubuntu-vm-01
  Generated: 2025-01-04 14:30:00
==========================================

--------------------[ CPU AUDIT ]---------------------
Load average:
  1 min : 0.45
  5 min : 0.52
 15 min : 0.48

CPU model:
  Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz

Top 5 processes by CPU usage:
  PID COMMAND         %CPU
  1234 firefox         15.2
  5678 python3         8.1
  9012 node            3.4
  ...
```

### Przykład 2: Audyt pamięci z ostrzeżeniem

```bash
$ ./audyt_main.sh --mem

------------------[ MEMORY AUDIT ]--------------------
Total RAM:      16384 MB
Available RAM:  1024 MB
Used RAM:       15360 MB (93%)

WARNING: Memory usage above 90%!

Swap total:     8192 MB
Swap free:      7890 MB
```

### Przykład 3: Wiele modułów

```bash
$ ./audyt_main.sh -c -m -d

# Wyświetli kolejno: CPU, Memory, Disk
```

### Przykład 4: Wysłanie raportu

```bash
$ ./send_report.sh

Running full system audit...
Report generated: /opt/sysaudit/reports/ubuntu-vm-01_20250104_143000.txt
Sending report to central host: audit@192.168.64.3
Attempt 1/3...
Report sent successfully!
SUCCESS: Report delivered to central host
```

### Przykład 5: Plik logu

```bash
$ cat /opt/sysaudit/logs/audyt.log

[2025-01-04 14:30:15] [admin@ubuntu-vm-01] [CPU] -> Raport CPU wygenerowany poprawnie.
[2025-01-04 14:30:16] [admin@ubuntu-vm-01] [MEM] -> Raport pamięci RAM wygenerowany poprawnie.
[2025-01-04 14:30:17] [admin@ubuntu-vm-01] [DISK] -> Raport dyskowy wygenerowany poprawnie.
```

---

## 🔧 Rozwiązywanie problemów

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
sudo usermod -a -G adm $USER

# Wyloguj się i zaloguj ponownie (lub użyj newgrp)
newgrp adm

# Sprawdź członkostwo w grupach
groups
```

**Uwaga:** Plik `/var/log/auth.log` zawiera wrażliwe informacje bezpieczeństwa i wymaga uprawnień grupy `adm`.

---

## 📝 Autor

Projekt stworzony w ramach kursu **Systemy Operacyjne**.

---

## 📄 Licencja

Projekt edukacyjny - wolne użycie w celach akademickich.
# projekt_audyt
