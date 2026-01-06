# 🧪 TUTORIAL: Pełne Testowanie System Audit

**Data:** 2026-01-06
**Topologia:** 192.168.64.3 (admin) + 192.168.64.4, 192.168.64.5 (klienci)

---

## 📋 PRZYGOTOWANIE

### ✅ Checklist przed rozpoczęciem:

- [ ] 3 VM z Ubuntu Server (świeże lub z istniejącymi instalacjami)
- [ ] Wszystkie VM mają połączenie sieciowe
- [ ] Masz dostęp SSH do wszystkich VM
- [ ] Kod na GitHubie jest zaktualizowany (push)
- [ ] Mac terminal z 4 oknami gotowy

---

## 🚀 KROK 1: PRZYGOTOWANIE HOSTA CENTRALNEGO (192.168.64.3)

**Terminal 1 - Admin Host**

### 1.1. Połącz się z VM Admin
```bash
ssh audit@192.168.64.3
```

### 1.2. Usuń starą instalację (jeśli istnieje)
```bash
# Usuń katalog instalacji
sudo rm -rf /opt/sysaudit

# Usuń stary projekt (jeśli był)
rm -rf ~/projekt_audyt

# Wyczyść crony (jeśli były ustawione)
crontab -r  # UWAGA: usuwa WSZYSTKIE wpisy, jeśli masz inne crony - pomiń to!

# Usuń systemd timer (jeśli był)
sudo systemctl stop sysaudit.timer 2>/dev/null || true
sudo systemctl disable sysaudit.timer 2>/dev/null || true
sudo rm -f /etc/systemd/system/sysaudit.* 2>/dev/null || true
sudo systemctl daemon-reload
```

### 1.3. Sklonuj świeży kod z GitHub
```bash
cd ~
git clone https://github.com/wokapala/projekt_audyt.git
cd projekt_audyt
```

**WAŻNE:** Sprawdź czy masz najnowsze zmiany:
```bash
git log --oneline -3
# Powinien pokazać commit z "Fix: Naprawiono krytyczne błędy"
```

### 1.4. Zainstaluj System Audit
```bash
sudo ./install.sh
```

**Podczas instalacji:**
- Wybierz **opcję 1** (/opt/sysaudit - produkcja)
- Gdy zapyta o SSH - wybierz **N** (skonfigurujemy później)

**Sprawdź czy instalacja się powiodła:**
```bash
# Powinieneś zobaczyć komunikat:
# ✓ Set ownership to: audit:audit
# ✓ All 5 modules found
# Installation Complete!
```

### 1.5. Sprawdź uprawnienia (KRYTYCZNE!)
```bash
ls -ld /opt/sysaudit/logs /opt/sysaudit/reports
```

**Oczekiwany output:**
```
drwxr-xr-x ... audit audit ... /opt/sysaudit/logs
drwxr-xr-x ... audit audit ... /opt/sysaudit/reports
```

**❌ Jeśli widzisz `root root` - instalacja się nie powiodła!**

### 1.6. Utwórz katalog do zbierania raportów
```bash
sudo mkdir -p /opt/sysaudit/central_reports
sudo chown $USER:$USER /opt/sysaudit/central_reports
chmod 755 /opt/sysaudit/central_reports
ls -ld /opt/sysaudit/central_reports
```

**Oczekiwany output:**
```
drwxr-xr-x 2 audit audit 4096 Jan 6 XX:XX /opt/sysaudit/central_reports
```

### 1.7. Dodaj użytkownika do grupy 'adm' (dostęp do auth.log)
```bash
sudo usermod -a -G adm $USER

# Zastosuj grupę bez wylogowania
newgrp adm

# Sprawdź
groups
# Powinno pokazać: audit adm ...
```

### 1.8. TEST: Uruchom pierwszy audyt
```bash
/opt/sysaudit/audyt_main.sh --full
```

**Sprawdź:**
- ✅ Czy wszystkie moduły się uruchomiły
- ✅ Czy nie ma błędów "Permission denied"
- ✅ Czy moduł CPU pokazuje architekturę i liczbę rdzeni
- ✅ Czy moduł Security pokazuje failed logins (lub komunikat o grupie adm)

### 1.9. Sprawdź czy powstał log i raport
```bash
# Log
cat /opt/sysaudit/logs/audyt.log
# Powinien zawierać 5 wpisów (CPU, MEM, DISK, NET, SEC)

# Katalog raportów (póki co pusty - raporty tworzy tylko send_report.sh)
ls -lh /opt/sysaudit/reports/
```

### ✅ CHECKPOINT 1: Admin Host działa poprawnie!

---

## 🖥️ KROK 2: PRZYGOTOWANIE KLIENTA 1 (192.168.64.4)

**Terminal 2 - Client 1**

### 2.1. Połącz się z VM Client 1
```bash
ssh audit@192.168.64.4
```

### 2.2. Usuń starą instalację
```bash
sudo rm -rf /opt/sysaudit
rm -rf ~/projekt_audyt
crontab -r  # lub crontab -e i usuń ręcznie wpisy sysaudit
```

### 2.3. Sklonuj kod
```bash
cd ~
git clone https://github.com/wokapala/projekt_audyt.git
cd projekt_audyt
git log --oneline -3  # sprawdź czy świeże
```

### 2.4. Zainstaluj
```bash
sudo ./install.sh
# Wybierz opcję 1
# SSH: N (skonfigurujemy później)
```

### 2.5. Sprawdź uprawnienia
```bash
ls -ld /opt/sysaudit/logs /opt/sysaudit/reports
# Powinno być: audit audit (NIE root root!)
```

### 2.6. Dodaj do grupy adm
```bash
sudo usermod -a -G adm $USER
newgrp adm
groups
```

### 2.7. TEST lokalny
```bash
/opt/sysaudit/audyt_main.sh --full
```

**Sprawdź:**
- ✅ Działa bez błędów
- ✅ CPU pokazuje architekturę ARM64
- ✅ Log został zapisany

```bash
cat /opt/sysaudit/logs/audyt.log
```

### ✅ CHECKPOINT 2: Client 1 działa lokalnie!

---

## 🖥️ KROK 3: PRZYGOTOWANIE KLIENTA 2 (192.168.64.5)

**Terminal 3 - Client 2**

### 3.1. Połącz się z VM Client 2
```bash
ssh audit@192.168.64.5
```

### 3.2. Powtórz kroki 2.2 - 2.7
```bash
# Usuń starą instalację
sudo rm -rf /opt/sysaudit
rm -rf ~/projekt_audyt
crontab -r

# Sklonuj
cd ~
git clone https://github.com/wokapala/projekt_audyt.git
cd projekt_audyt

# Zainstaluj
sudo ./install.sh  # opcja 1, SSH: N

# Sprawdź uprawnienia
ls -ld /opt/sysaudit/logs /opt/sysaudit/reports

# Grupa adm
sudo usermod -a -G adm $USER
newgrp adm

# Test
/opt/sysaudit/audyt_main.sh --full
cat /opt/sysaudit/logs/audyt.log
```

### ✅ CHECKPOINT 3: Client 2 działa lokalnie!

---

## 🔐 KROK 4: KONFIGURACJA SSH (Klienci → Admin)

Teraz skonfigurujemy SSH aby klienci mogli wysyłać raporty na Admin.

### 4.1. Na CLIENT 1 (192.168.64.4)

**Terminal 2:**
```bash
# Sprawdź czy masz już klucz SSH
ls -la ~/.ssh/id_*

# Jeśli NIE MA klucza, wygeneruj:
ssh-keygen -t ed25519 -C "sysaudit@vm-client1" -N "" -f ~/.ssh/id_ed25519

# Skopiuj klucz do Admin Host
ssh-copy-id audit@192.168.64.3
# Wpisz hasło użytkownika 'audit' na admin host
```

**TEST połączenia:**
```bash
ssh audit@192.168.64.3 'echo SUCCESS from $(hostname)'
```

**Oczekiwany output:**
```
SUCCESS from vm-admin  # (lub nazwa twojego admin host)
```

**❌ Jeśli pyta o hasło - znaczy że klucz nie został poprawnie skopiowany!**

### 4.2. Na CLIENT 2 (192.168.64.5)

**Terminal 3:**
```bash
# Wygeneruj klucz (jeśli nie ma)
ssh-keygen -t ed25519 -C "sysaudit@vm-client2" -N "" -f ~/.ssh/id_ed25519

# Skopiuj do Admin
ssh-copy-id audit@192.168.64.3

# TEST
ssh audit@192.168.64.3 'echo SUCCESS from $(hostname)'
```

### ✅ CHECKPOINT 4: SSH działa bezhasłowo!

---

## 📤 KROK 5: TEST WYSYŁANIA RAPORTÓW

### 5.1. Test z CLIENT 1 (192.168.64.4)

**Terminal 2:**
```bash
/opt/sysaudit/send_report.sh
```

**Oczekiwany output:**
```
Running full system audit...
Report generated: /opt/sysaudit/reports/vm-client1_20260106_HHMMSS.txt
Sending report to central host: audit@192.168.64.3
Attempt 1/3...
Report sent successfully!
SUCCESS: Report delivered to central host
```

**❌ Możliwe problemy:**
- `Cannot connect to central host` - SSH nie działa, sprawdź krok 4.1
- `Permission denied` - katalog reports/ ma złe uprawnienia, sprawdź krok 2.5

### 5.2. Test z CLIENT 2 (192.168.64.5)

**Terminal 3:**
```bash
/opt/sysaudit/send_report.sh
```

**Powinno zadziałać tak samo jak w 5.1**

### 5.3. Weryfikacja na ADMIN HOST (192.168.64.3)

**Terminal 1:**
```bash
ls -lh /opt/sysaudit/central_reports/
```

**Oczekiwany output:**
```
-rw-r--r-- 1 audit audit 2.1K Jan  6 XX:XX vm-client1_20260106_HHMMSS.txt
-rw-r--r-- 1 audit audit 2.1K Jan  6 XX:XX vm-client2_20260106_HHMMSS.txt
```

**Zobacz zawartość raportu:**
```bash
cat /opt/sysaudit/central_reports/vm-client1_*.txt
```

**Powinieneś zobaczyć:**
- Header z nazwą hosta i datą
- CPU AUDIT (z architekturą ARM64)
- MEMORY AUDIT
- DISK AUDIT
- NETWORK AUDIT
- SECURITY AUDIT

### ✅ CHECKPOINT 5: Wysyłanie raportów działa!

---

## ⏰ KROK 6: KONFIGURACJA AUTOMATYZACJI (CRON)

Ustawimy crona aby raporty były wysyłane automatycznie co 6 godzin.

### 6.1. Na CLIENT 1 (192.168.64.4)

**Terminal 2:**
```bash
cd ~/projekt_audyt
./setup_cron.sh
```

**Podczas konfiguracji:**
1. Wybierz **opcję 1** (Install cron job)
2. Wybierz **opcję 2** (Every 6 hours) lub **opcję 6** (Custom) dla testów

**Dla DEMO/TESTÓW - ustaw na co 5 minut:**
```
[6] Custom interval

Enter custom cron expression: */5 * * * *
```

**Dla PRODUKCJI - ustaw na co 6 godzin:**
```
[2] Every 6 hours (0 */6 * * *)
```

**Sprawdź czy cron został dodany:**
```bash
crontab -l
```

**Powinno pokazać:**
```
# System Audit - Automatic report sending
*/5 * * * * /opt/sysaudit/send_report.sh > /dev/null 2>&1
```

### 6.2. Na CLIENT 2 (192.168.64.5)

**Terminal 3:**
```bash
cd ~/projekt_audyt
./setup_cron.sh
# Wybierz opcję 1, potem */5 * * * * (co 5 minut dla testów)

# Sprawdź
crontab -l
```

### 6.3. TEST CRONA (opcjonalnie)

**Metoda 1: Czekaj 5 minut i sprawdź**

**Terminal 1 (Admin Host):**
```bash
# Co minutę sprawdzaj czy pojawiają się nowe raporty
watch -n 60 'ls -lh /opt/sysaudit/central_reports/ | tail -5'
```

Po 5-10 minutach powinny pojawić się nowe raporty.

**Metoda 2: Wymuś ręcznie (test czy cron działa)**

**Terminal 2 (Client 1):**
```bash
# Zobacz kiedy był ostatni run
ls -lth /opt/sysaudit/reports/ | head -5

# Poczekaj 5-6 minut i sprawdź ponownie
# Powinien pojawić się nowy plik z aktualnym timestampem
```

### 6.4. ADMIN HOST - Opcjonalnie ustaw cleaning raporty

Na admin host możesz ustawić automatyczne czyszczenie starych raportów (np. starszych niż 30 dni):

**Terminal 1:**
```bash
crontab -e
```

**Dodaj na końcu:**
```cron
# Clean old reports (older than 30 days)
0 3 * * * find /opt/sysaudit/central_reports -name "*.txt" -mtime +30 -delete
```

### ✅ CHECKPOINT 6: Automatyzacja działa!

---

## 🧪 KROK 7: TESTOWANIE WSZYSTKICH FUNKCJONALNOŚCI

### 7.1. Test menu interaktywnego

**Terminal 2 (Client 1):**
```bash
/opt/sysaudit/audyt_main.sh
```

**Test:**
1. Wybierz **1** (Audyt CPU) - sprawdź czy pokazuje ARM64
2. ENTER - powrót do menu
3. Wybierz **2** (Audyt RAM) - sprawdź progi
4. ENTER
5. Wybierz **5** (Audyt Bezpieczeństwa) - sprawdź auth.log
6. ENTER
7. Wybierz **0** (Wyjście)

### 7.2. Test flag CLI

**Terminal 2:**
```bash
# Pomoc
/opt/sysaudit/audyt_main.sh --help

# Pojedynczy moduł
/opt/sysaudit/audyt_main.sh --cpu
/opt/sysaudit/audyt_main.sh --mem

# Wiele modułów
/opt/sysaudit/audyt_main.sh -c -m -d

# Wszystkie moduły
/opt/sysaudit/audyt_main.sh --full

# Krótkie wersje
/opt/sysaudit/audyt_main.sh -f
```

### 7.3. Test progów alarmowych

**Edytuj config.conf aby obniżyć progi:**

**Terminal 2:**
```bash
sudo nano /opt/sysaudit/config.conf
```

**Zmień:**
```bash
MEM_WARNING_THRESHOLD=10   # było 90
DISK_WARNING_THRESHOLD=10  # było 90
```

**Zapisz (Ctrl+O, ENTER, Ctrl+X)**

**Test:**
```bash
/opt/sysaudit/audyt_main.sh --mem
```

**Powinno pokazać:**
```
WARNING: Memory usage above 10%!  # czerwony tekst
```

```bash
/opt/sysaudit/audyt_main.sh --disk
```

**Powinno pokazać partycje powyżej 10%:**
```
Partitions above 10% usage:
  /dev/sda1 (/) - 45% used  # żółty tekst
```

**Przywróć normalne wartości:**
```bash
sudo nano /opt/sysaudit/config.conf
# MEM_WARNING_THRESHOLD=90
# DISK_WARNING_THRESHOLD=90
```

### 7.4. Test retry mechanism

**Symuluj problem z siecią - wyłącz Admin Host:**

**Terminal 1 (Admin):**
```bash
sudo poweroff
```

**Terminal 2 (Client 1):**
```bash
/opt/sysaudit/send_report.sh
```

**Oczekiwany output:**
```
Running full system audit...
Report generated: /opt/sysaudit/reports/vm-client1_....txt
Sending report to central host: audit@192.168.64.3
Attempt 1/3...
WARNING: Cannot connect to central host (attempt 1/3)
Retrying in 5 seconds...
Attempt 2/3...
WARNING: Cannot connect to central host (attempt 2/3)
Retrying in 5 seconds...
Attempt 3/3...
WARNING: Cannot connect to central host (attempt 3/3)
ERROR: Failed to send report after 3 attempts
Report saved locally: /opt/sysaudit/reports/vm-client1_....txt
```

**✅ Retry mechanism działa!**

**Uruchom ponownie Admin Host i przetestuj czy teraz działa:**

```bash
# Uruchom Admin VM w UTM
# Poczekaj aż się zabootuje
# Na Client 1:
/opt/sysaudit/send_report.sh
# Powinno teraz zadziałać: SUCCESS
```

### 7.5. Test kolorów

**Terminal 2:**
```bash
/opt/sysaudit/audyt_main.sh --net
```

**Sprawdź:**
- ✅ Zielony checkmark przy osiągalnych hostach
- ❌ Czerwony X przy nieosiągalnych (jeśli jakiś host nie działa)

### 7.6. Test logowania

**Terminal 2:**
```bash
# Sprawdź logi
tail -20 /opt/sysaudit/logs/audyt.log
```

**Każdy wpis powinien zawierać:**
```
[YYYY-MM-DD HH:MM:SS] [audit@hostname] [MODULE] -> Message
```

**Sprawdź czy wszystkie moduły się logują:**
```bash
grep "CPU" /opt/sysaudit/logs/audyt.log | tail -3
grep "MEM" /opt/sysaudit/logs/audyt.log | tail -3
grep "DISK" /opt/sysaudit/logs/audyt.log | tail -3
grep "NET" /opt/sysaudit/logs/audyt.log | tail -3
grep "SEC" /opt/sysaudit/logs/audyt.log | tail -3
```

### ✅ CHECKPOINT 7: Wszystkie funkcje przetestowane!

---

## 📊 KROK 8: WERYFIKACJA FINALNA

### 8.1. Sprawdź strukturę plików na wszystkich VM

**Terminal 1, 2, 3 (wszystkie VM):**
```bash
tree /opt/sysaudit -L 2
# lub
ls -lR /opt/sysaudit/
```

**Oczekiwana struktura:**
```
/opt/sysaudit/
├── audyt_lib.sh
├── audyt_main.sh
├── config.conf
├── send_report.sh
├── modules/
│   ├── mod_cpu.sh
│   ├── mod_disk.sh
│   ├── mod_mem.sh
│   ├── mod_net.sh
│   └── mod_sec.sh
├── logs/
│   └── audyt.log
├── reports/
│   └── [pliki raportów na klientach]
└── central_reports/  [tylko na admin]
    └── [raporty od wszystkich klientów]
```

### 8.2. Sprawdź crony

**Terminal 2, 3 (klienci):**
```bash
crontab -l
```

**Powinno być:**
```
# System Audit - Automatic report sending
*/5 * * * * /opt/sysaudit/send_report.sh > /dev/null 2>&1
```

### 8.3. Statystyki raportów na Admin

**Terminal 1 (Admin):**
```bash
cd /opt/sysaudit/central_reports/

# Liczba raportów
ls -1 | wc -l

# Raporty per host
echo "Client 1 reports:"; ls -1 | grep client1 | wc -l
echo "Client 2 reports:"; ls -1 | grep client2 | wc -l

# Rozmiar
du -sh .

# Najnowsze raporty
ls -lth | head -10
```

### 8.4. Test dokumentacji

**Terminal 4 (Mac, lokalnie):**
```bash
cd ~/Documents/projekt_audyt

# Sprawdź czy wszystkie pliki dokumentacji są aktualne
cat README.md | grep "Konfiguracja hosta centralnego"
cat CHECKLIST_PRZED_ODDANIEM.md | head -20
cat TUTORIAL_TESTOWANIA.md | head -10

# Sprawdź CHANGELOG
cat CHANGELOG.md
```

### ✅ CHECKPOINT 8: System w pełni działający!

---

## 🎬 KROK 9: PRZYGOTOWANIE DO DEMO/OBRONY

### 9.1. Zmień cron z testowego (*/5) na produkcyjny (co 6h)

**Terminal 2, 3 (klienci):**
```bash
crontab -e
```

**Zmień:**
```cron
# BYŁO:
*/5 * * * * /opt/sysaudit/send_report.sh > /dev/null 2>&1

# MA BYĆ:
0 */6 * * * /opt/sysaudit/send_report.sh > /dev/null 2>&1
```

**Zapisz i sprawdź:**
```bash
crontab -l
```

### 9.2. Wygeneruj przykładowe raporty do pokazania

**Terminal 2 (Client 1):**
```bash
# Wygeneruj kilka raportów w odstępach 10 sekund
for i in {1..3}; do
  /opt/sysaudit/send_report.sh
  echo "Report $i sent"
  sleep 10
done
```

**Terminal 3 (Client 2):**
```bash
# To samo
for i in {1..3}; do
  /opt/sysaudit/send_report.sh
  echo "Report $i sent"
  sleep 10
done
```

### 9.3. Przygotuj "cheat sheet" dla obrony

**Terminal 4 (Mac):**
```bash
cd ~/Documents/projekt_audyt
cat > DEMO_COMMANDS.txt << 'EOF'
=== DEMO COMMANDS dla obrony ===

# 1. MENU INTERAKTYWNE
/opt/sysaudit/audyt_main.sh

# 2. POJEDYNCZY MODUŁ
/opt/sysaudit/audyt_main.sh --cpu

# 3. PEŁNY AUDYT
/opt/sysaudit/audyt_main.sh --full

# 4. WIELE MODUŁÓW
/opt/sysaudit/audyt_main.sh -c -m -d

# 5. WYSŁANIE RAPORTU
/opt/sysaudit/send_report.sh

# 6. ZOBACZ LOGI
tail -20 /opt/sysaudit/logs/audyt.log

# 7. ZOBACZ RAPORTY (Admin)
ls -lh /opt/sysaudit/central_reports/
cat /opt/sysaudit/central_reports/vm-client1_*.txt | head -50

# 8. ZOBACZ CRON
crontab -l

# 9. CONFIG
cat /opt/sysaudit/config.conf

# 10. HELP
/opt/sysaudit/audyt_main.sh --help
EOF

cat DEMO_COMMANDS.txt
```

### 9.4. Zrób snapshot wszystkich VM

W UTM:
1. Kliknij prawym na każdą VM
2. Wybierz "Create Snapshot"
3. Nazwij: "System Audit - Ready for Demo - 2026-01-06"

**To pozwoli wrócić do tego stanu przed obroną!**

### ✅ CHECKPOINT 9: Gotowe do demo!

---

## 📝 CHECKLIST FINALNA PRZED OBRONĄ

### Na wszystkich VM (Admin + 2 Clients):

- [ ] System Audit zainstalowany w `/opt/sysaudit`
- [ ] Uprawnienia `logs/` i `reports/` = `audit:audit` (NIE root!)
- [ ] Użytkownik w grupie `adm` (dostęp do auth.log)
- [ ] Wszystkie moduły działają bez błędów
- [ ] Moduł CPU pokazuje ARM64 + architekturę + cores
- [ ] Moduł Security pokazuje failed logins (lub komunikat o adm)

### Na klientach (64.4, 64.5):

- [ ] SSH do Admin działa bezhasłowo
- [ ] `send_report.sh` wysyła raporty bez błędów
- [ ] Cron ustawiony na `0 */6 * * *` (co 6h)
- [ ] Logi zawierają wpisy ze wszystkich modułów

### Na admin (64.3):

- [ ] Katalog `/opt/sysaudit/central_reports/` istnieje
- [ ] Raporty od klientów są odbierane
- [ ] Można otworzyć i przeczytać raporty

### Dokumentacja:

- [ ] `README.md` - kompletny i aktualny
- [ ] `CHECKLIST_PRZED_ODDANIEM.md` - stworzony
- [ ] `TUTORIAL_TESTOWANIA.md` - stworzony (ten plik)
- [ ] `CHANGELOG.md` - zaktualizowany
- [ ] `QUICKSTART.md` - istnieje

### GitHub:

- [ ] Wszystkie zmiany zpushowane
- [ ] Ostatni commit: "Fix: Naprawiono krytyczne błędy przed obroną"
- [ ] Repository publiczne lub prowadzący ma dostęp

---

## 🎯 SCENARIUSZ DEMO DLA PROWADZĄCEGO

### Scenariusz 1: Podstawowe funkcje (5 minut)

**Terminal Client 1:**
```bash
# 1. Pokaż help
/opt/sysaudit/audyt_main.sh --help

# 2. Pojedynczy moduł
/opt/sysaudit/audyt_main.sh --cpu
# Zwróć uwagę: Architecture: aarch64, CPU cores: X

# 3. Pełny audyt
/opt/sysaudit/audyt_main.sh --full
```

### Scenariusz 2: Centralne raportowanie (3 minuty)

**Terminal Client 1:**
```bash
# Wyślij raport
/opt/sysaudit/send_report.sh
```

**Terminal Admin:**
```bash
# Pokaż odebrane raporty
ls -lh /opt/sysaudit/central_reports/

# Wyświetl raport
cat /opt/sysaudit/central_reports/vm-client1_*.txt | head -100
```

### Scenariusz 3: Automatyzacja (2 minuty)

**Terminal Client 1:**
```bash
# Pokaż cron
crontab -l

# Pokaż logi
tail -20 /opt/sysaudit/logs/audyt.log
```

### Scenariusz 4: Konfiguracja (2 minuty)

**Terminal Client 1:**
```bash
# Pokaż config
cat /opt/sysaudit/config.conf

# Wyjaśnij:
# - Progi alarmowe (MEM_WARNING_THRESHOLD, DISK_WARNING_THRESHOLD)
# - Retry mechanism (SCP_RETRY_COUNT=3)
# - Hosty do testowania (PING_TARGETS)
```

---

## 🐛 TROUBLESHOOTING

### Problem: Permission denied przy zapisie logów

```bash
ls -ld /opt/sysaudit/logs
# Jeśli pokazuje root:root - napraw:
sudo chown -R $USER:$USER /opt/sysaudit/logs /opt/sysaudit/reports
sudo chmod 755 /opt/sysaudit/logs /opt/sysaudit/reports
```

### Problem: CPU pokazuje "Unknown"

```bash
# Sprawdź czy masz najnowszą wersję mod_cpu.sh
grep "ARCH=\$(uname -m)" /opt/sysaudit/modules/mod_cpu.sh
# Jeśli NIE MA tej linii - update z GitHub!
```

### Problem: send_report.sh timeout

```bash
# Sprawdź SSH
ssh audit@192.168.64.3 'echo TEST'

# Sprawdź ping
ping -c3 192.168.64.3

# Sprawdź czy central_reports istnieje na admin
ssh audit@192.168.64.3 'ls -ld /opt/sysaudit/central_reports'
```

### Problem: Cron nie działa

```bash
# Sprawdź logi cron
grep CRON /var/log/syslog | tail -20

# Test ręczny
/opt/sysaudit/send_report.sh
# Jeśli działa ręcznie ale nie przez cron - sprawdź ścieżki w crontab
```

---

## ✅ KONIEC TUTORIALA

**Gratulacje! System Audit jest w pełni działający i gotowy do obrony!** 🎉

**Następne kroki:**
1. Zrób backup/snapshot wszystkich VM
2. Przejrzyj dokumentację (README.md, CHECKLIST)
3. Przećwicz scenariusze demo
4. Powodzenia na obronie! 🚀
