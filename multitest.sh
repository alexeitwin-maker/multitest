#!/bin/bash

# ============================================================
#  Multitest Pro v1.6 — Ultimate Edition
# ============================================================

# --- НАСТРОЙКИ TG (Опционально) ---
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"
# --------------------------

# 1. Сбор базовой информации для имени лога
IP_ADDR=$(curl -s https://ipinfo.io/ip || curl -s eth0.me)
HOST_NAME=$(hostname)
DATE_NOW=$(date +%Y%m%d_%H%M)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_${DATE_NOW}.log"

# 2. Проверка токена
if [ -z "$MY_TG_TOKEN" ] && [ ! -z "$1" ]; then
    MY_TG_TOKEN="$1"
elif [ -z "$MY_TG_TOKEN" ]; then
    echo -e "\e[1;33mВведите токен бота (или оставьте пустым для пропуска TG):\e[0m"
    read -p "Token: " MY_TG_TOKEN
fi

# Настройка логирования (дублируем всё в файл)
exec > >(tee -a "$LOG_FILE") 2>&1

# Цвета для вывода в консоль
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}${BOLD}>>> ЗАПУСК MULTITEST v1.6-ULTIMATE <<<${NC}"
    echo -e "${YELLOW}Лог-файл:${NC} $LOG_FILE\n"
}

print_separator() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  >>> $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# --- БЛОКИ ТЕСТОВ ---

install_deps() {
    echo -e "${CYAN}Установка зависимостей...${NC}"
    apt-get update -qq && apt-get install -y -qq curl wget sysbench iperf3 &>/dev/null
}

run_ip_region() {
    print_separator "IP Region & ASN"
    bash <(wget -qO- https://ipregion.vrnt.xyz) </dev/null
}

run_censorcheck() {
    print_separator "Censorcheck (Geoblock & DPI)"
    echo "--- Geoblock Test ---"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock </dev/null
    echo -e "\n--- DPI Test ---"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi </dev/null
}

run_iperf3_ru() {
    print_separator "iPerf3 Speedtest (RU Servers)"
    bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) </dev/null
}

run_yabs() {
    print_separator "YABS (Disk & Network)"
    # Флаг -i отключает интерактивность, -4 только IPv4
    curl -sL yabs.sh | bash -s -- -4 -i </dev/null
}

run_ip_check_place() {
    print_separator "IP.Check.Place (Global Blocks)"
    bash <(curl -Ls IP.Check.Place) -l en </dev/null
}

run_bench_sh() {
    print_separator "Bench.sh (Hardware & Global Speed)"
    wget -qO- bench.sh | bash </dev/null
}

run_ip_quality() {
    print_separator "IP Quality Check (Check.Place)"
    bash <(curl -Ls https://Check.Place) -EI </dev/null
}

run_sysbench() {
    print_separator "Sysbench CPU (Single-thread)"
    sysbench cpu run --threads=1
}

send_to_telegram() {
    if [ ! -z "$MY_TG_TOKEN" ]; then
        echo -e "\n${YELLOW}Отправка данных в Telegram...${NC}"
        local message="📊 *Отчет Multitest Pro*%0A🖥 *Host:* $HOST_NAME%0A🌐 *IP:* $IP_ADDR"
        
        curl -s -X POST "https://api.telegram.org/bot$MY_TG_TOKEN/sendMessage" \
            -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" \
            -d "parse_mode=Markdown" -d "text=$message" > /dev/null

        curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" \
             -F document=@"$LOG_FILE" \
             "https://api.telegram.org/bot$MY_TG_TOKEN/sendDocument" > /dev/null
        echo -e "${GREEN}✔ Отчет отправлен!${NC}"
    fi
}

# --- ЗАПУСК ---
run_all() {
    print_header
    install_deps
    run_ip_region
    run_censorcheck
    run_ip_check_place
    run_ip_quality
    run_bench_sh
    run_yabs
    run_iperf3_ru
    run_sysbench
    send_to_telegram
    echo -e "\n${GREEN}${BOLD}Все тесты завершены. Лог сохранен в: $LOG_FILE${NC}"
}

run_all
