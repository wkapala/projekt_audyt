# Quick Start Guide - System Audit

Szybki przewodnik uruchomienia projektu na 3 maszynach wirtualnych Ubuntu Server.

---

## 📋 Przed rozpoczęciem

**Potrzebujesz:**
- 3 maszyny wirtualne z Ubuntu Server (np. UTM/QEMU)
- 1 host centralny do zbierania raportów
- Sieć łącząca wszystkie maszyny

**Przykładowa konfiguracja:**
```
Central Host:  192.168.64.3 (user: audit)
VM1:           192.168.64.4
VM2:           192.168.64.5
VM3:           192.168.64.6
```

---

## 🚀 Instalacja krok po kroku

### Krok 1: Przygotowanie Central Host (192.168.64.3)

Na hoście centralnym:

```bash
# Utwórz użytkownika audit
sudo useradd -m -s /bin/bash audit
sudo passwd audit

# Utwórz katalog na raporty
sudo mkdir -p /opt/sysaudit/central_reports
sudo chown audit:audit /opt/sysaudit/central_reports
sudo chmod 755 /opt/sysaudit/central_reports
```

---

### Krok 2: Instalacja na VM1, VM2, VM3

Na każdej maszynie wirtualnej wykonaj:

```bash
# 1. Sklonuj projekt
cd ~
git clone <repository-url> projekt_audyt
cd projekt_audyt

# 2. Uruchom instalator
chmod +x install.sh
sudo ./install.sh

# 3. Wybierz opcję 1 (production)
# Instalator:
# - Sprawdzi zależności
# - Stworzy katalogi
# - Skopiuje pliki do /opt/sysaudit
```

---

### Krok 3: Konfiguracja SSH keys

Na każdej VM:

```bash
# Wygeneruj klucz SSH (jeśli nie istnieje)
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# Skopiuj klucz na central host
ssh-copy-id audit@192.168.64.3

# Test połączenia
ssh audit@192.168.64.3 "echo OK"
```

---

### Krok 4: Personalizacja config.conf

Na każdej VM edytuj `/opt/sysaudit/config.conf`:

```bash
sudo nano /opt/sysaudit/config.conf
```

**Zmień:**
```bash
# Hosty do testowania łączności (dostosuj do swojej sieci)
PING_TARGETS=("192.168.64.3" "192.168.64.4" "192.168.64.5")

# Central host (upewnij się że adres jest poprawny)
CENTRAL_HOST="192.168.64.3"
CENTRAL_USER="audit"
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
/opt/sysaudit/send_report.sh
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

## ✅ Weryfikacja

### Sprawdź logi

```bash
# Logi audytu
sudo tail -f /opt/sysaudit/logs/audyt.log

# Logi systemd (jeśli używasz)
sudo journalctl -u sysaudit.service -f
```

### Sprawdź raporty lokalne

```bash
ls -lh /opt/sysaudit/reports/
```

### Sprawdź czy cron działa

```bash
crontab -l
```

### Sprawdź timer systemd

```bash
sudo systemctl status sysaudit.timer
sudo systemctl list-timers sysaudit.timer
```

---

## 🎯 Użycie po instalacji

### Uruchamianie ręczne

```bash
# Tryb interaktywny (menu)
/opt/sysaudit/audyt_main.sh

# Pojedyncze moduły
/opt/sysaudit/audyt_main.sh --cpu
/opt/sysaudit/audyt_main.sh --mem
/opt/sysaudit/audyt_main.sh --disk
/opt/sysaudit/audyt_main.sh --net
/opt/sysaudit/audyt_main.sh --sec

# Wiele modułów
/opt/sysaudit/audyt_main.sh -c -m -d

# Pełny audyt
/opt/sysaudit/audyt_main.sh --full

# Wysłanie raportu
/opt/sysaudit/send_report.sh
```

### Pomoc

```bash
/opt/sysaudit/audyt_main.sh --help
```

---

## 📊 Podgląd raportów na Central Host

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

## 🔧 Rozwiązywanie problemów

### Problem: SCP timeout

```bash
# Sprawdź łączność
ping -c3 192.168.64.3

# Sprawdź SSH
ssh audit@192.168.64.3 "exit"

# Jeśli pyta o hasło - zresetuj SSH key
ssh-copy-id audit@192.168.64.3
```

### Problem: Brak narzędzi

```bash
# Zainstaluj zależności
sudo apt-get update
sudo apt-get install coreutils procps iproute2 iputils-ping openssh-client
```

### Problem: Permission denied dla logów

```bash
# Napraw uprawnienia
sudo chown -R $(whoami):$(whoami) /opt/sysaudit/logs
sudo chmod 755 /opt/sysaudit/logs
```

---

## 📅 Harmonogram (przykład)

**Sugerowana konfiguracja dla 3 VM:**

- **VM1**: Raporty co 6 godzin (0:00, 6:00, 12:00, 18:00)
- **VM2**: Raporty co 6 godzin (1:00, 7:00, 13:00, 19:00)
- **VM3**: Raporty co 6 godzin (2:00, 8:00, 14:00, 20:00)

Dzięki rozłożeniu w czasie unikniesz jednoczesnego obciążenia sieci.

**Cron dla VM1:**
```
0 */6 * * * /opt/sysaudit/send_report.sh
```

**Cron dla VM2:**
```
0 1,7,13,19 * * * /opt/sysaudit/send_report.sh
```

**Cron dla VM3:**
```
0 2,8,14,20 * * * /opt/sysaudit/send_report.sh
```

---

## ✨ Gotowe!

Twój system audytu jest teraz w pełni skonfigurowany i działa automatycznie.

**Co się dzieje teraz:**
1. Każda VM wykonuje audyt w zaplanowanych godzinach
2. Raporty są zapisywane lokalnie w `reports/`
3. Raporty są wysyłane na central host przez SCP
4. Wszystkie operacje są logowane w `logs/audyt.log`

**Sprawdź za 6 godzin czy raporty pojawiają się na central host!**

---

**Potrzebujesz pomocy?** Zobacz `README.md` dla szczegółowej dokumentacji.
