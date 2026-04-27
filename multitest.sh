#!/bin/bash

# ============================================================
#  Multitest Pro v1.7 — Anti-Freeze Edition
# ============================================================

# Настройки TG
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# 1. Формируем имя лога
IP_ADDR=$(curl -s --connect-timeout 5 https://ipinfo.io/ip || echo "no-ip")
HOST_NAME=$(hostname)
DATE_NOW=$(date +%Y%m%d_%H%M)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_${DATE_NOW}.log"

# 2. Проверка токена
if [ -z "$MY_TG_TOKEN" ]; then
    echo -e "Введите токен бота (или Enter для пропуска):"
    read -t 10 -p "Token: " MY_TG_TOKEN # Таймаут 10 сек на ввод
fi

# Настройка логирования
exec > >(tee -a "$LOG_FILE") 2>&1

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

print_separator() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  >>> $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# --- ИСПРАВЛЕННЫЕ ФУНКЦИИ ---

install_deps() {
    print_separator "Установка зависимостей (Safe Mode)"
    # Убираем зависания apt
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -o Acquire::ForceIPv4=true -o APT::Get::List-Cleanup=0 -qq || true
    apt-get install -y -qq curl wget sysbench iperf3 dnsutils < /dev/null
}

run_ip_region() {
    print_separator "IP Region"
    bash <(curl -sL https://ipregion.vrnt.xyz) </dev/null || echo "Ошибка теста"
}

run_censorcheck() {
    print_separator "Censorcheck"
    bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock </dev/null
    bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi </dev/null
}

run_ip_check_place() {
    print_separator "IP.Check.Place"
    # Добавляем таймаут и неинтерактивность
    bash <(curl -sL IP.Check.Place) -l en < /dev/null || echo "Пропущено"
}

run_ip_quality() {
    print_separator "IP Quality Check"
    bash <(curl -sL https://Check.Place) -EI < /dev/null || echo "Пропущено"
}

run_bench_sh() {
    print_separator "Bench.sh"
    wget -qO- bench.sh | bash < /dev/null || echo "Пропущено"
}

run_yabs() {
    print_separator "YABS (Disk & Network)"
    # Флаги -i (игнор подтверждений) и -9 (пропуск Geobench если тормозит)
    curl -sL yabs.sh | bash -s -- -4 -i -9 < /dev/null
}

run_iperf3_ru() {
    print_separator "iPerf3 RU"
    bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) < /dev/null
}

run_sysbench() {
    print_separator "Sysbench CPU"
    sysbench cpu run --threads=1 | grep -E "events per second|avg:"
}

send_to_telegram() {
    if [ ! -z "$MY_TG_TOKEN" ]; then
        print_separator "Отправка в Telegram"
        curl -s -X POST "https://api.telegram.org/bot$MY_TG_TOKEN/sendMessage" \
            -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" \
            -d "parse_mode=Markdown" -d "text=✅ Отчет готов: *$HOST_NAME* ($IP_ADDR)" > /dev/null
        
        curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" \
             -F document=@"$LOG_FILE" \
             "https://api.telegram.org/bot$MY_TG_TOKEN/sendDocument" > /dev/null
    fi
}

# --- ЗАПУСК ---
echo -e "${CYAN}>>> Скрипт запущен. Ожидайте завершения...<<<${NC}"
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

echo -e "\n${GREEN}Готово! Лог: $LOG_FILE${NC}"
