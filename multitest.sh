#!/bin/bash
# ============================================================
#  Multitest Pro v3.1 — Git & Production Stable
# ============================================================

# --- КОНФИГУРАЦИЯ (через переменные среды) ---
# Токен берется из системы: export MY_TG_TOKEN="содержимое"
TG_TOKEN="${MY_TG_TOKEN}"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# 1. Сбор данных окружения
IP_ADDR=$(curl -s --connect-timeout 5 eth0.me || echo "no_ip")
HOST_NAME=$(hostname)
DATE_NOW=$(date +%Y%m%d_%H%M)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_${DATE_NOW}.log"

# Функция логирования (вывод на экран + запись в файл)
log_run() {
    echo -e "\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;37m  >>> $1\033[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
    
    echo -e "\n>>> $1\n" >> "$LOG_FILE"
    # Запуск. tee позволяет тебе взаимодействовать с меню (нажимать 2, 0 и т.д.)
    eval "$2" 2>&1 | tee -a "$LOG_FILE"
}

# --- ПРОВЕРКА ЗАВИСИМОСТЕЙ ---
clear
echo -e "\033[1;32mSTARTING MULTITEST v3.1 (Git Edition)\033[0m"
echo -e "Target Log: $LOG_FILE\n"

# Снимаем блокировки APT, если они остались от фоновых апдейтов
rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock 2>/dev/null

# --- ЦИКЛ ТЕСТОВ ---

log_run "System Tools" "apt-get update && apt-get install -y curl wget sysbench iperf3"

log_run "IP Region" "bash <(curl -sL https://ipregion.vrnt.xyz)"

log_run "Geoblock Check" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock"

# В ЭТОМ МЕСТЕ НУЖНО БУДЕТ РУКАМИ НАЖАТЬ "2", А ПОТОМ "0"
log_run "IP Quality Check" "bash <(curl -Ls https://Check.Place) -E"

log_run "Hardware Bench" "wget -qO- bench.sh | bash"

log_run "YABS (Disk/Network)" "curl -sL yabs.sh | bash -s -- -4 -i -9"

log_run "iPerf3 Russian Servers" "bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)"

log_run "CPU Performance" "sysbench cpu run --threads=1"

# --- ОТПРАВКА РЕЗУЛЬТАТОВ ---
if [ ! -z "$TG_TOKEN" ]; then
    echo -e "\n\033[0;33mSending report to Telegram...\033[0m"
    
    # Сообщение о завершении
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" \
        -d "text=✅ Test Complete: $HOST_NAME ($IP_ADDR)" > /dev/null
    
    # Отправка лога
    curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_THREAD_ID" \
         -F document=@"$LOG_FILE" \
         "https://api.telegram.org/bot$TG_TOKEN/sendDocument" > /dev/null
    
    echo -e "\033[0;32mDone. Report sent.\033[0m"
else
    echo -e "\n\033[0;31mSkip TG: MY_TG_TOKEN is not set.\033[0m"
fi

echo -e "\n\033[1;32mFINISH! Log saved to: $LOG_FILE\033[0m"
