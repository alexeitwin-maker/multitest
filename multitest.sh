#!/bin/bash

# ============================================================
#  Multitest Pro v1.5 — Safe TG Edition
# ============================================================

# --- НАСТРОЙКИ КАНАЛА ---
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"
# --------------------------

# Проверка наличия токена (из переменной или ввод вручную)
if [ -z "$MY_TG_TOKEN" ]; then
    echo -e "\e[1;33mДля отправки отчета в Telegram введите токен бота:\e[0m"
    read -p "Token: " MY_TG_TOKEN
    clear
fi

TG_TOKEN="$MY_TG_TOKEN"
SCRIPT_VERSION="1.5-SafeTG"
LOG_FILE="report_$(date +%Y%m%d_%H%M).log"

# Цвета
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Настройка логирования
exec > >(tee -a "$LOG_FILE") 2>&1

print_header() {
    echo -e "${CYAN}${BOLD}>>> ЗАПУСК MULTITEST v${SCRIPT_VERSION} <<<${NC}"
    echo -e "${YELLOW}Цель в TG:${NC} Чат $TG_CHAT_ID | Ветка $TG_THREAD_ID\n"
}

print_separator() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  >>> $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# --- ФУНКЦИИ ТЕСТОВ (кратко) ---
install_deps() { echo -e "${CYAN}Установка зависимостей...${NC}"; apt-get update -qq && apt-get install -y -qq curl wget sysbench iperf3 &>/dev/null; }
run_ip_region() { print_separator "IP Region"; bash <(wget -qO- https://ipregion.vrnt.xyz) </dev/null; }
run_censorcheck() { print_separator "Censorcheck"; bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock </dev/null; }
run_iperf3_ru() { print_separator "iPerf3 RU"; bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) </dev/null; }
run_yabs() { print_separator "YABS"; curl -sL yabs.sh | bash -s -- -4 -i </dev/null; }
run_sysbench() { print_separator "Sysbench CPU"; sysbench cpu run --threads=1; }

# --- ОТПРАВКА В TELEGRAM ---
send_to_telegram() {
    echo -e "\n${YELLOW}Отправка данных в Telegram...${NC}"
    local ip_addr=$(curl -s eth0.me)
    local host_name=$(hostname)
    local message="📊 *Отчет Multitest*%0A🖥 *Сервер:* $host_name%0A🌐 *IP:* $ip_addr"

    # Текст
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=Markdown" -d "text=$message" > /dev/null

    # Лог-файл
    curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" \
         -F document=@"$LOG_FILE" \
         "https://api.telegram.org/bot$TG_TOKEN/sendDocument" > /dev/null
    
    echo -e "${GREEN}✔ Отчет успешно отправлен в ветку $TG_THREAD_ID!${NC}"
}

# --- ГЛАВНЫЙ ЦИКЛ ---
run_all() {
    print_header
    install_deps
    run_ip_region
    run_censorcheck
    run_iperf3_ru
    run_yabs
    run_sysbench
    send_to_telegram
}

run_all
