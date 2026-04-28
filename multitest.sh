#!/bin/bash

# Чтение аргументов: запуск будет выглядеть так: ./multitest.sh ВАШ_ТОКЕН
TG_TOKEN="${1:-$TG_TOKEN}"  # Берет из первого аргумента или из переменной окружения
TG_CHAT_ID="-1002350577710"
TG_THREAD_ID="2122"

# --- Сбор данных ---
hostname=$(hostname)
ip_address=$(curl -s https://api.ipify.org)
# Собираем данные о локации
geo_data=$(curl -s ipapi.co/json/)
location=$(echo "$geo_data" | jq -r '"\(.country_name), \(.city)"')
isp=$(echo "$geo_data" | jq -r '.org')

echo -e "Запуск тестов для $hostname ($ip_address)..."

# [Тут идет ваш основной блок тестов: sysbench, iperf3 и т.д.]
# Допустим, мы сохранили важные цифры в переменные:
# cpu_score, speed_msk, ping_msk

# --- Формирование сообщения ---
# Используем HTML парсинг, он стабильнее Markdown при наличии спецсимволов в именах провайдеров
MESSAGE="<b>🚀 VPS VPN REPORT</b>
<b>------------------------------</b>
<b>🖥 Host:</b> <code>$hostname</code>
<b>🌐 IP:</b> <code>$ip_address</code>
<b>📍 Loc:</b> $location
<b>🏢 ISP:</b> $isp

<b>⚡ Speed (MSK):</b> $speed_msk Mbps
<b>⏱ Ping:</b> ${ping_msk}ms
<b>🧠 CPU Power:</b> $cpu_score ev/s

<b>📊 Verdict:</b> $VERDICT
<b>------------------------------</b>"

# --- Отправка в Telegram ---
if [ -n "$TG_TOKEN" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "message_thread_id=$TG_THREAD_ID" \
        -d "parse_mode=HTML" \
        -d "text=$MESSAGE" > /dev/null
    echo "Отчет отправлен в Telegram (Topic ID: $TG_THREAD_ID)"
else
    echo "Ошибка: TG_TOKEN не найден. Запустите: ./multitest.sh ВАШ_ТОКЕН"
fi
