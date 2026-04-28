#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
TG_TOKEN="${1}"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"
LOG_FILE="vps_full_report.log"

# Функция для отправки текста в TG
send_tg_text() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=HTML" -d "text=$1" > /dev/null
}

# Функция для отправки файла в TG
send_tg_file() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F "chat_id=$TG_CHAT_ID" -F "message_thread_id=$TG_THREAD_ID" \
        -F "document=@$1" -F "caption=$2" > /dev/null
}

if [ -z "$TG_TOKEN" ]; then
    echo "Ошибка: Укажите токен бота аргументом!"
    exit 1
fi

# Очистка старого лога
> $LOG_FILE

echo "Запуск полного цикла тестов. Результаты будут отправлены в Telegram..."
send_tg_text "🚀 <b>Запуск полного тестирования VPS</b>%0AHost: <code>$(hostname)</code>%0AIP: <code>$(curl -s ifconfig.me)</code>"

# 1. IP Region
echo ">>> Running: IP region..." | tee -a $LOG_FILE
bash <(wget -qO- https://ipregion.vrnt.xyz) | tee -a $LOG_FILE

# 2. Censorcheck Geoblock
echo -e "\n>>> Running: Censorcheck Geoblock..." | tee -a $LOG_FILE
bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock | tee -a $LOG_FILE

# 3. Censorcheck DPI
echo -e "\n>>> Running: Censorcheck DPI..." | tee -a $LOG_FILE
bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi | tee -a $LOG_FILE

# 4. Russian iPerf3
echo -e "\n>>> Running: Russian iPerf3..." | tee -a $LOG_FILE
bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) | tee -a $LOG_FILE

# 5. YABS
echo -e "\n>>> Running: YABS..." | tee -a $LOG_FILE
curl -sL yabs.sh | bash -s -- -4 | tee -a $LOG_FILE

# 6. IP.Check.Place
echo -e "\n>>> Running: IP.Check.Place..." | tee -a $LOG_FILE
bash <(curl -Ls IP.Check.Place) -l en | tee -a $LOG_FILE

# 7. Bench.sh
echo -e "\n>>> Running: Bench.sh..." | tee -a $LOG_FILE
wget -qO- bench.sh | bash | tee -a $LOG_FILE

# 8. IPQuality
echo -e "\n>>> Running: IPQuality..." | tee -a $LOG_FILE
bash <(curl -Ls https://Check.Place) -EI | tee -a $LOG_FILE

# 9. Sysbench CPU
echo -e "\n>>> Running: Sysbench CPU..." | tee -a $LOG_FILE
sysbench cpu run --threads=1 | tee -a $LOG_FILE

# Финальное действие: отправка полного лога
echo "Тесты завершены. Отправляю лог..."
send_tg_file "$LOG_FILE" "✅ Полный отчет по серверу $(hostname)"
send_tg_text "🏁 <b>Все тесты выполнены.</b> Лог файл прикреплен выше."
