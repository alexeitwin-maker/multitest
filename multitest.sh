#!/bin/bash

# --- КОНФИГУРАЦИЯ TELEGRAM ---
# Токен передается первым аргументом при запуске: bash multitest.sh TOKEN
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
echo -e "${BLUE}   VPN Node Professional Analyzer v2.0              ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Установка необходимых инструментов
echo -e "\n${CYAN}>>> Установка зависимостей...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget sysbench iperf3 bc jq > /dev/null 2>&1

# Исправленная установка Speedtest (Ookla)
if ! command -v speedtest &> /dev/null; then
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash > /dev/null 2>&1
    apt-get install -y speedtest > /dev/null 2>&1
fi

# 2. Сбор системной информации
hostname=$(hostname)
ip_address=$(curl -s https://api.ipify.org)
geo_data=$(curl -s https://ipapi.co/json/)
location=$(echo "$geo_data" | jq -r '"\(.country_name), \(.city)"')
isp=$(echo "$geo_data" | jq -r '.org')

echo -e "Host: ${YELLOW}$hostname${NC}"
echo -e "IP:   ${YELLOW}$ip_address${NC}"
echo -e "Loc:  ${YELLOW}$location${NC}"

# 3. Тест производительности CPU (Критично для VPN)
echo -e "\n${CYAN}>>> Тестирование CPU (Crypto performance)...${NC}"
cpu_val=$(sysbench cpu --cpu-max-prime=10000 run | grep "events per second:" | awk '{print $4}')
echo -e "Score: ${YELLOW}$cpu_val ev/s${NC}"

# 4. Тест сетевых каналов (Россия)
echo -e "\n${CYAN}>>> Тестирование скорости (РФ, iperf3)...${NC}"
# Пробуем Москву (itdoginfo)
iperf_res=$(iperf3 -c moscow.iperf.itdog.info -t 5 -R --json)
if [[ -z "$iperf_res" ]]; then
    # Резервный сервер, если основной недоступен
    iperf_res=$(iperf3 -c spb.iperf.itdog.info -t 5 -R --json)
fi

speed_bps=$(echo "$iperf_res" | jq '.end.sum_received.bits_per_second // 0')
speed_msk=$(echo "scale=2; $speed_bps / 1024 / 1024" | bc)
ping_msk=$(echo "$iperf_res" | jq '.start.connected[0].seconds // 0' | awk '{print $1*1000}')

echo -e "Speed: ${YELLOW}$speed_msk Mbps${NC}"
echo -e "Ping:  ${YELLOW}${ping_msk}ms${NC}"

# 5. Проверка репутации IP (Google Captcha Test)
google_status=$(curl -sL --max-time 5 "https://www.google.com/search?q=test" -A "Mozilla/5.0" | grep -c "detected unusual traffic")
if [ "$google_status" -gt 0 ]; then
    ip_rep="🔴 Bad (High Fraud Score)"
    ip_label="Bad"
else
    ip_rep="🟢 Clean (Low Risk)"
    ip_label="Clean"
fi

# 6. Итоговый вердикт (Commercial Grade)
if (( $(echo "$cpu_val > 4500" | bc -l) )) && (( $(echo "$speed_msk > 400" | bc -l) )) && [ "$ip_label" == "Clean" ]; then
    VERDICT="⭐ TOP TIER (Commercial Ready)"
    EMOJI="💎"
elif (( $(echo "$cpu_val > 2500" | bc -l) )); then
    VERDICT="✅ GOOD (Stable Private)"
    EMOJI="🛡️"
else
    VERDICT="⚠️ POOR (Not for business)"
    EMOJI="🚫"
fi

# 7. Отправка отчета в Telegram
if [ -n "$TG_TOKEN" ]; then
    echo -e "\n${CYAN}>>> Отправка отчета в Telegram...${NC}"
    
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
    
    echo -e "${GREEN}Готово! Отчет отправлен в ветку $TG_THREAD_ID${NC}"
else
    echo -e "\n${YELLOW}Внимание: TG_TOKEN не указан. Отчет только в терминале.${NC}"
fi

# 8. Запуск доп. проверок (стриминг и т.д.)
echo -e "\n${CYAN}>>> Расширенная проверка регионов...${NC}"
bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionCheck/main/check.sh)

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}          Тестирование завершено!                   ${NC}"
echo -e "${BLUE}====================================================${NC}"
