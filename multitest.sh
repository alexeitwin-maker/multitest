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

# Настройка логирования
exec > >(tee -a "$LOG_FILE") 2>&1

# ... (тут все остальные функции из версии 1.4: run_yabs, run_iperf3 и т.д.) ...
# [Я пропущу их для краткости, оставь их в своем файле]

send_to_telegram() {
    echo -e "\n\033[1;33mОтправка отчета в Telegram...\033[0m"
    
    local message="📊 *Новый отчет Multitest* v$SCRIPT_VERSION%0A🖥 *Сервер:* $(hostname)%0A🌐 *IP:* $(curl -s eth0.me)%0A📅 *Дата:* $(date '+%Y-%m-%d %H:%M')"
    
    # Отправка текста
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
    
    echo -e "\033[0;32m✔ Отчет успешно отправлен в Telegram!\033[0m"
}

run_all_automatic() {
    # ... (вызов всех тестов) ...
    
    # В самом конце запускаем отправку
    send_to_telegram
}

run_all_automatic
