#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
TG_TOKEN="${1}"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"
LOG_FILE="vps_full_report.log"

# Цвета
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Исправление репозиториев и установка
echo -e "${CYAN}>>> Подготовка системы...${NC}"
# Удаляем проблемный репозиторий speedtest, если он есть
rm -f /etc/apt/sources.list.d/ookla_speedtest-cli.list
apt-get update -qq && apt-get install -y -qq curl jq sysbench iperf3 bc wget > /dev/null 2>&1

# 2. Сбор базовых данных
hostname=$(hostname)
ip_addr=$(curl -s ifconfig.me)
echo "Запуск тестов на сервере $hostname ($ip_addr)..."

# Очистка лога
> $LOG_FILE

# 3. ВЫПОЛНЕНИЕ ВСЕХ 9 ТЕСТОВ
{
    echo "=== ОТЧЕТ ПО VPS: $hostname ($ip_addr) ==="
    echo "Дата: $(date)"
    echo -e "\n1. IP REGION:"
    bash <(wget -qO- https://ipregion.vrnt.xyz)
    
    echo -e "\n2. CENSORCHECK (GEOBLOCK):"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock
    
    echo -e "\n3. CENSORCHECK (DPI):"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi
    
    echo -e "\n4. RUSSIAN IPERF3 SERVERS:"
    bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh)
    
    echo -e "\n5. YABS:"
    curl -sL yabs.sh | bash -s -- -4
    
    echo -e "\n6. IP.CHECK.PLACE (GLOBAL):"
    bash <(curl -Ls IP.Check.Place) -l en
    
    echo -e "\n7. BENCH.SH:"
    wget -qO- bench.sh | bash
    
    echo -e "\n8. IPQUALITY / CHECK.PLACE:"
    bash <(curl -Ls https://Check.Place) -EI
    
    echo -e "\n9. CPU TEST (SYSBENCH):"
    sysbench cpu run --threads=1
} | tee -a $LOG_FILE

# 4. ОТПРАВКА В TELEGRAM
if [ -n "$TG_TOKEN" ]; then
    echo "Отправка результатов в Telegram..."
    
    # Отправляем файл лога
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F "chat_id=$TG_CHAT_ID" \
        -F "message_thread_id=$TG_THREAD_ID" \
        -F "document=@$LOG_FILE" \
        -F "caption=📄 Полный технический отчет: $hostname ($ip_addr)" > /dev/null

    # Отправляем краткое резюме текстом
    cpu_score=$(grep "events per second:" $LOG_FILE | tail -1 | awk '{print $4}')
    speed_msk=$(grep -A 5 "Server" $LOG_FILE | grep "Moscow" | awk '{print $2, $3}' | head -1)
    
    MESSAGE="<b>✅ Тестирование завершено</b>
<b>🖥 Host:</b> <code>$hostname</code>
<b>🧠 CPU:</b> $cpu_score ev/s
<b>🚀 Скорость MSK:</b> $speed_msk
<i>Полный лог прикреплен выше файлом.</i>"

    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=HTML" \
        -d "text=$MESSAGE" > /dev/null
fi

echo "Все тесты завершены. Лог сохранен в $LOG_FILE"
