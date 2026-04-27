#!/bin/bash
# ============================================================
#  Multitest Pro v1.8 — Extreme Fix (No Hangs)
# ============================================================

export DEBIAN_FRONTEND=noninteractive

# Данные для лога
IP_ADDR=$(curl -s --connect-timeout 5 eth0.me || echo "unknown_ip")
HOST_NAME=$(hostname)
DATE_NOW=$(date +%Y%m%d_%H%M)
LOG_FILE="${HOST_NAME}_${IP_ADDR}_${DATE_NOW}.log"

# Настройка вывода (без tee в начале, чтобы не блокировать ввод)
echo -e "\033[0;36m>>> Запуск v1.8. Лог: $LOG_FILE <<<\033[0m"

# Быстрая установка БЕЗ полного апдейта системы
apt-get install -y -qq curl wget sysbench iperf3 < /dev/null > /dev/null 2>&1

# Теперь направляем всё в лог
exec > >(tee -a "$LOG_FILE") 2>&1

# Функция-обертка для запуска без зависаний
run_safe() {
    echo -e "\n\033[1;36m>>> $1\033[0m"
    timeout 300s bash -c "$2" < /dev/null || echo -e "\033[0;31mОшибка или Таймаут\033[0m"
}

# --- ЦИКЛ ТЕСТОВ ---

run_safe "IP Region" "bash <(curl -sL https://ipregion.vrnt.xyz)"

run_safe "Censorcheck (Geoblock)" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock"

run_safe "Censorcheck (DPI)" "bash <(curl -sL https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi"

run_safe "IP.Check.Place" "bash <(curl -sL IP.Check.Place) -l en"

run_safe "IP Quality Check" "bash <(curl -sL https://Check.Place) -EI"

run_safe "Bench.sh" "wget -qO- bench.sh | bash"

run_safe "YABS (Disk/Net)" "curl -sL yabs.sh | bash -s -- -4 -i -9"

run_safe "iPerf3 Speedtest (RU)" "bash <(curl -sL https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)"

run_safe "Sysbench CPU" "sysbench cpu run --threads=1"

# --- TELEGRAM ---
if [ ! -z "$MY_TG_TOKEN" ]; then
    echo -e "\nОтправка в TG..."
    TG_URL="https://api.telegram.org/bot$MY_TG_TOKEN"
    curl -s -X POST "$TG_URL/sendMessage" -d "chat_id=-1002350577710" -d "message_thread_id=2122" -d "text=✅ Готов: $HOST_NAME ($IP_ADDR)" > /dev/null
    curl -s -F chat_id="-1002350577710" -F message_thread_id="2122" -F document=@"$LOG_FILE" "$TG_URL/sendDocument" > /dev/null
fi

echo -e "\n\033[0;32mЗавершено! Файл: $LOG_FILE\033[0m"
