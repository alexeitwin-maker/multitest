#!/bin/bash
# ============================================================
#  Multitest Pro v2.5 — Zero Interaction Edition
# ============================================================

TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# 1. Глобальные настройки анти-интерактива
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

IP_ADDR=$(curl -s --connect-timeout 5 eth0.me || echo "no_ip")
LOG_FILE="$(hostname)_${IP_ADDR}_$(date +%Y%m%d_%H%M).log"

log() { echo -e "$1" | tee -a "$LOG_FILE"; }

# Улучшенная функция запуска с авто-ответом "Enter"
run() {
    log "\n\033[1;36m>>> $1\033[0m"
    # timeout убивает процесс если он завис на 7 минут
    # printf '\n' подает Enter если скрипт выкинул меню
    timeout 420s bash -c "printf '\n\n\n\n' | $2" 2>&1 | tee -a "$LOG_FILE"
}

# --- ПОДГОТОВКА ---
clear
log "\033[1;32mЗАПУСК v2.5. Все меню будут пройдены автоматически.\033[0m"

# Очистка блокировок APT
systemctl stop unattended-upgrades 2>/dev/null
killall apt apt-get dpkg 2>/dev/null
rm -f /var/lib/dpkg/lock-frontend /etc/apt/sources.list.d/ookla_speedtest-cli.list
dpkg --configure -a

log "Установка инструментов..."
apt-get update -qq || true
apt-get install -y -qq curl wget sysbench iperf3 dnsutils < /dev/null > /dev/null 2>&1

# --- ТЕСТЫ С АВТО-ОТВЕТАМИ ---

# IP Region обычно не просит ввода
run "IP Region" "bash <(curl -sL https://ipregion.vrnt.xyz)"

# Censorcheck - подаем Enter на случай вопросов
run "Censorcheck" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock"

# IP.Check.Place - КРИТИЧНО: добавляем -l en и подаем Enter
run "IP.Check.Place" "bash <(curl -sL IP.Check.Place) -l en"

# IP Quality - используем флаги если они есть
run "IP Quality" "bash <(curl -sL https://Check.Place) -EI"

# Bench.sh - стандартный скрипт
run "Bench.sh" "wget -qO- bench.sh | bash"

# YABS - здесь уже есть флаги -i (игнор) и -9 (пропуск Geobench)
run "YABS" "curl -sL yabs.sh | bash -s -- -4 -i -9"

# iPerf3 RU - подаем Enter
run "iPerf3 RU" "bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)"

# Sysbench - чисто консольная утилита
run "Sysbench CPU" "sysbench cpu run --threads=1"

# --- TG ---
if [ ! -z "$MY_TG_TOKEN" ]; then
    curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" -F document=@"$LOG_FILE" "https://api.telegram.org/bot$MY_TG_TOKEN/sendDocument" > /dev/null
fi

log "\n\033[1;32mГОТОВО! Лог доведен до конца.\033[0m"
