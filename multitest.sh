#!/bin/bash

# --- КОНФИГУРАЦИЯ TELEGRAM ---
TG_TOKEN="${1}"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# Цвета для терминала
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   VPN Node Professional Analyzer v2.1              ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Установка инструментов
echo -e "\n${CYAN}>>> Установка зависимостей...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget sysbench iperf3 bc jq > /dev/null 2>&1

# 2. Сбор системной информации
hostname=$(hostname)
ip_address=$(curl -s https://api.ipify.org)
geo_data=$(curl -s https://ipapi.co/json/ -H "User-Agent: curl/7.64.1")
location=$(echo "$geo_data" | jq -r '"\(.country_name), \(.city)"')
isp=$(echo "$geo_data" | jq -r '.org')

# 3. Тест производительности CPU
echo -e "\n${CYAN}>>> Тестирование CPU...${NC}"
cpu_val=$(sysbench cpu --cpu-max-prime=10000 run | grep "events per second:" | awk '{print $4}')

# 4. Тест сетевых каналов (iperf3)
echo -e "\n${CYAN}>>> Тестирование скорости (MSK)...${NC}"
# Запускаем iperf3 и сохраняем результат в переменную
iperf_json=$(iperf3 -c moscow.iperf.itdog.info -t 5 -R --json)

# Если Москва недоступна, пробуем Питер
if [[ -z "$iperf_json" || "$iperf_json" == *"error"* ]]; then
    iperf_json=$(iperf3 -c spb.iperf.itdog.info -t 5 -R --json)
fi

# Извлекаем данные из JSON
speed_bps=$(echo "$iperf_json" | jq '.end.sum_received.bits_per_second // 0')
speed_msk=$(echo "scale=2; $speed_bps / 1024 / 1024" | bc)
ping_msk=$(echo "$iperf_json" | jq '.start.connected[0].seconds // 0' | awk '{print $1*1000}')

# 5. Проверка репутации IP
google_status=$(curl -sL --max-time 5 "https://www.google.com/search?q=test" -A "Mozilla/5.0" | grep -c "detected unusual traffic")
if [ "$google_status" -gt 0 ]; then
    ip_rep="🔴 Bad (Proxy/Captcha)"
    ip_label="Bad"
else
    ip_rep="🟢 Clean"
    ip_label="Clean"
fi

# 6. Вердикт
if (( $(echo "$cpu_val > 4500" | bc -l) )) && (( $(echo "$speed_msk > 400" | bc -l) )) && [ "$ip_label" == "Clean" ]; then
    VERDICT="⭐ TOP TIER (Commercial Ready)"
    EMOJI="💎"
elif (( $(echo "$cpu_val > 2000" | bc -l) )); then
    VERDICT="✅ GOOD (Stable Private)"
    EMOJI="🛡️"
else
    VERDICT="⚠️ POOR (Not for business)"
    EMOJI="🚫"
fi

# 7. Отправка в Telegram
if [ -n "$TG_TOKEN" ]; then
    echo -e "${CYAN}>>> Отправка отчета в Telegram...${NC}"
    
    # Формируем текст сообщения
    MESSAGE="<b>$EMOJI VPN NODE REPORT $EMOJI</b>
<b>------------------------------</b>
<b>🖥 Host:</b> <code>$hostname</code>
<b>🌐 IP:</b> <code>$ip_address</code>
<b>📍 Loc:</b> $location
<b>🏢 ISP:</b> $isp

<b>⚡ Speed (MSK):</b> $speed_msk Mbps
<b>⏱ Ping:</b> ${ping_msk}ms
<b>🧠 CPU Power:</b> $cpu_val ev/s
<b>🛡 IP Status:</b> $ip_rep

<b>📊 Verdict:</b> $VERDICT
<b>------------------------------</b>"

    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=HTML" \
        -d "text=$MESSAGE" > /dev/null
else
    echo -e "${RED}Ошибка: Токен не указан!${NC}"
fi

# 8. Финальный вывод в консоль для красоты
echo -e "Speed: $speed_msk Mbps"
echo -e "CPU:   $cpu_val ev/s"
echo -e "Готово!"
