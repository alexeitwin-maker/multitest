#!/bin/bash

# --- НАСТРОЙКИ TG ---
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"
# --------------------

# 1. Подготовка окружения
export DEBIAN_FRONTEND=noninteractive
IP_ADDR=$(curl -s --connect-timeout 5 eth0.me || echo "no_ip")
HOST_NAME=$(hostname)
DATE_NOW=$(date +%Y%m%d_%H%M)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_${DATE_NOW}.log"

# Функция для логирования (пишет и в консоль, и в файл)
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Функция-обертка для запуска тестов (универсальная)
run() {
    log "\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    log "\033[1;37m  >>> $1\033[0m"
    log "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
    # Запуск
    eval "$2" 2>&1 | tee -a "$LOG_FILE"
}

# --- СТАРТ ---
clear
echo -e "\033[1;32mЗапуск Multitest v2.0. Лог будет сохранен в: $LOG_FILE\033[0m"
echo "Скрипт работает, пожалуйста, подождите..."

# Тихая установка зависимостей
apt-get update -qq && apt-get install -y -qq curl wget sysbench iperf3 < /dev/null > /dev/null 2>&1

# --- СПИСОК ТЕСТОВ ---

run "IP Region" "bash <(curl -sL https://ipregion.vrnt.xyz)"

run "Censorcheck (Geoblock)" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock"

run "Censorcheck (DPI)" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi"

run "IP.Check.Place" "bash <(curl -sL IP.Check.Place) -l en"

run "IP Quality Check" "bash <(curl -sL https://Check.Place) -EI"

run "Bench.sh (Global)" "wget -qO- bench.sh | bash"

run "YABS (Disk/Network)" "curl -sL yabs.sh | bash -s -- -4 -i -9"

run "iPerf3 Speedtest (RU)" "bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)"

run "Sysbench CPU" "sysbench cpu run --threads=1"

# --- ОТПРАВКА В TG ---
if [ ! -z "$MY_TG_TOKEN" ]; then
    log "\n\033[0;33mОтправка отчета в Telegram...\033[0m"
    curl -s -X POST "https://api.telegram.org/bot$MY_TG_TOKEN/sendMessage" -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" -d "text=✅ Тест завершен: $HOST_NAME ($IP_ADDR)" > /dev/null
    curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" -F document=@"$LOG_FILE" "https://api.telegram.org/bot$MY_TG_TOKEN/sendDocument" > /dev/null
    log "\033[1;32m✔ Отправлено успешно!\033[0m"
fi

log "\n\033[1;32mГОТОВО! Результаты в файле: $LOG_FILE\033[0m"
