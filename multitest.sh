#!/bin/bash
# ============================================================
#  Multitest Pro v2.1 — Force Run & Clean Fix
# ============================================================

TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# 1. Принудительная разблокировка APT
fix_apt() {
    echo -e "\033[0;33mСнимаю блокировки системных обновлений...\033[0m"
    systemctl stop unattended-upgrades 2>/dev/null
    killall apt apt-get dpkg 2>/dev/null
    rm -rf /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock
    dpkg --configure -a
}

# 2. Переменные
export DEBIAN_FRONTEND=noninteractive
IP_ADDR=$(curl -s --connect-timeout 5 eth0.me || echo "no_ip")
HOST_NAME=$(hostname)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_$(date +%Y%m%d_%H%M).log"

log() { echo -e "$1" | tee -a "$LOG_FILE"; }

run() {
    log "\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    log "\033[1;37m  >>> $1\033[0m"
    log "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
    eval "$2" 2>&1 | tee -a "$LOG_FILE"
}

# --- СТАРТ ---
clear
echo -e "\033[1;32mЗапуск Multitest v2.1. Лог: $LOG_FILE\033[0m"

fix_apt

log "\033[0;33mУстановка зависимостей...\033[0m"
apt-get update -qq && apt-get install -y -qq curl wget sysbench iperf3 < /dev/null > /dev/null 2>&1

# --- ТЕСТЫ ---
run "IP Region" "bash <(curl -sL https://ipregion.vrnt.xyz)"
run "Censorcheck" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock && bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi"
run "IP.Check.Place" "bash <(curl -sL IP.Check.Place) -l en"
run "IP Quality Check" "bash <(curl -sL https://Check.Place) -EI"
run "Bench.sh" "wget -qO- bench.sh | bash"
run "YABS" "curl -sL yabs.sh | bash -s -- -4 -i -9"
run "iPerf3 Speedtest (RU)" "bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)"
run "Sysbench CPU" "sysbench cpu run --threads=1"

# --- TG ---
if [ ! -z "$MY_TG_TOKEN" ]; then
    log "\n\033[0;33mОтправка в Telegram...\033[0m"
    curl -s -X POST "https://api.telegram.org/bot$MY_TG_TOKEN/sendMessage" -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" -d "text=✅ Готов: $HOST_NAME ($IP_ADDR)" > /dev/null
    curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" -F document=@"$LOG_FILE" "https://api.telegram.org/bot$MY_TG_TOKEN/sendDocument" > /dev/null
fi

log "\n\033[1;32mГОТОВО!\033[0m"
