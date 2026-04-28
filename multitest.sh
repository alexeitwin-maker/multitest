#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
TG_TOKEN="${1}"
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# 1. Установка инструментов (нужны для сбора данных)
apt-get update -qq && apt-get install -y -qq curl jq sysbench iperf3 bc > /dev/null 2>&1

echo "Начинаю сбор данных..."

# 2. Сбор системной инфо
hostname=$(hostname)
ip_address=$(curl -s https://api.ipify.org)
geo_data=$(curl -s https://ipapi.co/json/)
location=$(echo "$geo_data" | jq -r '"\(.country_name), \(.city)"')
isp=$(echo "$geo_data" | jq -r '.org')

# 3. ТЕСТЫ (Сначала считаем, потом отправляем)
echo "Тестирую CPU..."
cpu_val=$(sysbench cpu --cpu-max-prime=10000 run | grep "events per second:" | awk '{print $4}')

echo "Тестирую скорость (это займет 10 сек)..."
iperf_res=$(iperf3 -c moscow.iperf.itdog.info -t 5 -R --json)
speed_bps=$(echo "$iperf_res" | jq '.end.sum_received.bits_per_second // 0')
speed_msk=$(echo "scale=2; $speed_bps / 1024 / 1024" | bc)
ping_msk=$(echo "$iperf_res" | jq '.start.connected[0].seconds // 0' | awk '{print $1*1000}')

# 4. Проверка IP
google_status=$(curl -sL --max-time 5 "https://www.google.com/search?q=test" -A "Mozilla/5.0" | grep -c "detected unusual traffic")
[ "$google_status" -gt 0 ] && ip_rep="🔴 Bad" || ip_rep="🟢 Clean"

# 5. Определение вердикта
if (( $(echo "$cpu_val > 4000" | bc -l) )) && (( $(echo "$speed_msk > 400" | bc -l) )); then
    VERDICT="⭐ Commercial Ready"
    EMOJI="💎"
else
    VERDICT="✅ Private Use"
    EMOJI="🛡️"
fi

# 6. ОТПРАВКА В TELEGRAM (Теперь все переменные заполнены)
if [ -n "$TG_TOKEN" ]; then
    MESSAGE="<b>$EMOJI VPS VPN REPORT $EMOJI</b>
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
    echo "Отчет отправлен!"
fi

# 7. В конце запускаем визуальные тесты для консоли
bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionCheck/main/check.sh)
