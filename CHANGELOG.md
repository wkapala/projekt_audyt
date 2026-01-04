# Changelog - System Audit

## Wszystkie zmiany i ulepszenia

---

## [Wersja 2.0] - 2025-01-04

### 🎉 Kompletna modernizacja projektu

#### ✅ FAZA 1: Naprawienie podstaw

**1.1 Plik konfiguracyjny (`config.conf`)**
- ✅ Dynamiczne wykrywanie ścieżek instalacji
- ✅ Centralna konfiguracja wszystkich parametrów
- ✅ Konfigurowalne progi alarmowe (RAM, dysk)
- ✅ Parametry sieci (hosty, timeouty, retry)
- ✅ Definicje kolorów terminala

**1.2 Aktualizacja wszystkich skryptów**
- ✅ Wszystkie skrypty używają `config.conf`
- ✅ Automatyczne tworzenie brakujących katalogów
- ✅ Walidacja obecności plików konfiguracyjnych
- ✅ Usunięcie hardcoded ścieżek `/opt/sysaudit`

**1.3 Skrypt instalacyjny (`install.sh`)**
- ✅ Interaktywny instalator z menu
- ✅ Wykrywanie systemu operacyjnego
- ✅ Sprawdzanie zależności systemowych
- ✅ Wybór lokalizacji: produkcja (`/opt`) vs development
- ✅ Automatyczne tworzenie struktury katalogów
- ✅ Ustawianie uprawnień
- ✅ Pomoc w konfiguracji SSH
- ✅ Test instalacji

**1.4 Naprawiony `send_report.sh`**
- ✅ Retry mechanism (3 próby z 5s opóźnieniem)
- ✅ SSH timeout z konfiguracją
- ✅ Sprawdzanie połączenia przed wysłaniem
- ✅ Graceful failure - raport zapisywany lokalnie przy błędzie
- ✅ Szczegółowe komunikaty o postępie
- ✅ Tworzenie katalogu `reports/` jeśli nie istnieje

---

#### ✅ FAZA 2: Funkcjonalność

**2.1 Hosty w konfiguracji**
- ✅ `PING_TARGETS` w `config.conf`
- ✅ `CENTRAL_HOST`, `CENTRAL_USER`, `CENTRAL_DIR`
- ✅ Łatwa zmiana bez edycji kodu

**2.2 Flagi zgodne z założeniami zadania**
- ✅ `--cpu` / `-c` - audyt CPU
- ✅ `--mem` / `-m` - audyt pamięci
- ✅ `--disk` / `-d` - audyt dysku
- ✅ `--net` / `-n` - audyt sieci
- ✅ `--sec` / `-s` - audyt bezpieczeństwa
- ✅ `--full` / `-f` - pełny audyt
- ✅ `--help` / `-h` - pomoc
- ✅ Możliwość łączenia flag (np. `-c -m -d`)

**2.3 Automatyzacja**
- ✅ `setup_cron.sh` - konfigurator cron z menu
- ✅ `sysaudit.service` - jednostka systemd
- ✅ `sysaudit.timer` - timer systemd (co 6h)
- ✅ `setup_systemd.sh` - instalator systemd
- ✅ Wybór częstotliwości raportów
- ✅ Persistent timer (nadrabia pominięte uruchomienia)

---

#### ✅ FAZA 3: Jakość i dokumentacja

**3.1 Dokumentacja (`README.md`)**
- ✅ Kompletny opis projektu
- ✅ Instrukcje instalacji (auto i manualne)
- ✅ Wszystkie tryby użycia z przykładami
- ✅ Szczegółowa konfiguracja
- ✅ Automatyzacja (cron i systemd)
- ✅ Architektura i diagramy
- ✅ Rozwiązywanie problemów
- ✅ Topologia sieci (3 VM + central host)

**3.2 Kolorowe outputy**
- ✅ Kolorowy header w `audyt_main.sh`
- ✅ Kolorowe menu interaktywne
- ✅ Ostrzeżenia pamięci (czerwone/zielone)
- ✅ Alerty dysku (żółte/zielone)
- ✅ Statusy łączności (✓ zielony / ✗ czerwony)
- ✅ Automatyczne wyłączanie kolorów przy przekierowaniu

**3.3 Walidacja środowiska**
- ✅ Funkcja `check_required_tools()` w bibliotece
- ✅ Funkcja `check_proc_access()` dla plików /proc
- ✅ Walidacja w każdym module przed wykonaniem
- ✅ Przyjazne komunikaty błędów
- ✅ Sugestie instalacji brakujących pakietów

---

### 📁 Nowe pliki

```
projekt_audyt/
├── config.conf              [NOWY]  Plik konfiguracyjny
├── install.sh               [NOWY]  Instalator
├── setup_cron.sh            [NOWY]  Konfigurator cron
├── setup_systemd.sh         [NOWY]  Konfigurator systemd
├── sysaudit.service         [NOWY]  Jednostka systemd
├── sysaudit.timer           [NOWY]  Timer systemd
├── README.md                [NOWY]  Dokumentacja
├── CHANGELOG.md             [NOWY]  Ten plik
├── audyt_main.sh            [ZMIENIONY]
├── audyt_lib.sh             [ZMIENIONY]
├── send_report.sh           [ZMIENIONY]
└── modules/
    ├── mod_cpu.sh           [ZMIENIONY]
    ├── mod_mem.sh           [ZMIENIONY]
    ├── mod_disk.sh          [ZMIENIONY]
    ├── mod_net.sh           [ZMIENIONY]
    └── mod_sec.sh           [ZMIENIONY]
```

---

### 🔧 Zmiany techniczne

#### Bezpieczeństwo i niezawodność
- ✅ Retry mechanism dla SCP (3 próby)
- ✅ SSH timeout zapobiega zawieszeniu
- ✅ BatchMode w SSH (nie czeka na hasło)
- ✅ Walidacja wszystkich narzędzi przed użyciem
- ✅ Sprawdzanie dostępu do /proc
- ✅ Automatyczne tworzenie katalogów

#### Kompatybilność
- ✅ Dynamiczne ścieżki (działa wszędzie)
- ✅ CPU detection dla x86, ARM, Apple Silicon
- ✅ Graceful degradation przy błędach
- ✅ Wykrywanie czy kolory są wspierane

#### Użyteczność
- ✅ Kompletna pomoc (`--help`)
- ✅ Interaktywne instalatory
- ✅ Szczegółowe komunikaty błędów
- ✅ Logi z timestampem i użytkownikiem
- ✅ Przyjazne menu

---

### 📊 Statystyki

- **Plików dodanych**: 7
- **Plików zmienionych**: 8
- **Linii kodu dodanych**: ~800
- **Funkcji dodanych**: 15+
- **Opcji konfiguracyjnych**: 20+

---

### ✨ Spełnienie wymagań

#### Założenia zadania ✅
- ✅ Modularny skrypt w Bash
- ✅ Flagi: `--cpu`, `--mem`, `--disk` (+ więcej)
- ✅ Interakcja z `/proc` (loadavg, meminfo, cpuinfo)
- ✅ Wykorzystanie narzędzi (ps, df, ss, ip)
- ✅ Czytelne raporty

#### Feedback prowadzącego ✅
- ✅ Podział na kilka skryptów (5 modułów)
- ✅ System logowania (kto, kiedy, co)
- ✅ Raporty sieciowe i dostępowe
- ✅ Cykliczność (cron + systemd)
- ✅ Wysyłanie na host centralny
- ✅ Obsługa całej sieci (3 VM + central)

---

### 🚀 Gotowe do użycia

Projekt jest teraz w pełni funkcjonalny i gotowy do wdrożenia na 3 maszynach wirtualnych z Ubuntu Server.

**Następne kroki:**
1. Uruchom `./install.sh` na każdej VM
2. Skonfiguruj SSH keys
3. Edytuj `config.conf` dla każdej maszyny
4. Uruchom `./setup_cron.sh` lub `./setup_systemd.sh`
5. Ciesz się automatycznymi raportami!

---

**Data ukończenia**: 2025-01-04
**Status**: ✅ GOTOWE DO ODDANIA
