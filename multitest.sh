#!/bin/bash

# ============================================================
#  Multitest Pro v1.5 — TG Edition
# ============================================================

# --- НАСТРОЙКИ TELEGRAM ---
TG_TOKEN="8407248621:AAHFbhxfPgWCkytsSF4RhYMkNYhjGZZptFQ"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"             # Оставь пустым, если нет веток (топиков)
# --------------------------

SCRIPT_VERSION="1.5-TG"
LOG_FILE="report_$(date +%Y%m%d_%H%M).log"
# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Настройка логирования
exec > >(tee -a "$LOG_FILE") 2>&1

print_header() {
    clear
    local bbr_status=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    echo -e "${CYAN}${BOLD}>>> ЗАПУСК MULTITEST v${SCRIPT_VERSION} <<<${NC}"
    echo -e "${YELLOW}TCP BBR:${NC} ${GREEN}${bbr_status}${NC}"
}

print_separator() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  >>> $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

install_deps() {
    echo -e "${CYAN}Установка зависимостей...${NC}"
    DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl wget sysbench iperf3 &>/dev/null
}

# --- БЛОК ТЕСТОВ ---
run_ip_region() { print_separator "IP Region"; bash <(wget -qO- https://ipregion.vrnt.xyz) </dev/null; }
run_censorcheck() { print_separator "Censorcheck"; bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock </dev/null; }
run_iperf3_ru() { print_separator "iPerf3 RU"; bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) </dev/null; }
run_yabs() { print_separator "YABS"; curl -sL yabs.sh | bash -s -- -4 -i </dev/null; }
run_ip_check() { print_separator "IP Check Place"; bash <(curl -Ls IP.Check.Place) -l en -c </dev/null; }
run_sysbench() { print_separator "Sysbench CPU"; sysbench cpu run --threads=1; }

# --- ОТПРАВКА В TELEGRAM ---
send_to_telegram() {
    echo -e "\n${YELLOW}Отправка отчета в Telegram (ветка $TG_THREAD_ID)...${NC}"
    
    local ip_addr=$(curl -s eth0.me)
    local host_name=$(hostname)
    local message="📊 *Отчет Multitest*%0A🖥 *Сервер:* $host_name%0A🌐 *IP:* $ip_addr%0A📅 *Дата:* $(date '+%Y-%m-%d %H:%M')"
    
    # Сообщение в чат
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=Markdown" \
        -d "text=$message" > /dev/null

    # Отправка файла лога
    curl -s -F chat_id="$TG_CHAT_ID" \
         -F message_thread_id="$TG_THREAD_ID" \
         -F document=@"$LOG_FILE" \
         "https://api.telegram.org/bot$TG_TOKEN/sendDocument" > /dev/null
    
    echo -e "${GREEN}✔ Отчет отправлен!${NC}"
}

# --- ЗАПУСК ВСЕГО ---
run_all() {
    print_header
    install_deps
    
    run_ip_region
    run_censorcheck
    run_iperf3_ru
    run_yabs
    run_ip_check
    run_sysbench
    
    send_to_telegram
}

run_all
