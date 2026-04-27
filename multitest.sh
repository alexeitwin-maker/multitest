#!/bin/bash

# ============================================================
#  Multitest Pro v1.4 — Ultimate Automation
# ============================================================

SCRIPT_VERSION="1.4-FINAL"
LOG_FILE="multitest_report_$(date +%Y%m%d_%H%M%S).log"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Настройка логирования
exec > >(tee -a "$LOG_FILE") 2>&1

# ============================================================
#  Вспомогательные функции
# ============================================================

print_header() {
    clear
    local bbr_status=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║          MULTITEST v${SCRIPT_VERSION}              ║"
    echo "  ║    Автоматический отчет и диагностика    ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Лог:${NC} ${BOLD}$LOG_FILE${NC}"
    echo -e "${YELLOW}TCP Congestion Control:${NC} ${GREEN}${BOLD}${bbr_status}${NC}\n"
}

print_separator() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  >>> $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================
#  Установка зависимостей (Полная тишина)
# ============================================================

install_deps() {
    echo -e "${CYAN}Проверка зависимостей...${NC}"
    local deps=(curl wget sysbench iperf3)
    
    if command -v apt-get &>/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" "${deps[@]}" &>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf install -y -q "${deps[@]}" &>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y -q "${deps[@]}" &>/dev/null
    fi
    echo -e "${GREEN}Зависимости в порядке.${NC}\n"
}

# ============================================================
#  Блок тестов (Никаких GUI и вопросов)
# ============================================================

run_ip_region() {
    print_separator "IP Region"
    bash <(wget -qO- https://ipregion.vrnt.xyz) </dev/null
}

run_censorcheck_geoblock() {
    print_separator "Censorcheck — Geoblock"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode geoblock </dev/null
}

run_censorcheck_dpi() {
    print_separator "Censorcheck — DPI"
    bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi </dev/null
}

run_iperf3_ru() {
    print_separator "iPerf3 — RU Servers"
    # Запуск теста скорости до проверенных узлов в РФ
    bash <(wget -qO- https://github.com/itdoginfo/russian-iperf3-servers/raw/main/speedtest.sh) </dev/null
}

run_yabs() {
    print_separator "YABS Benchmark"
    # -i выключает интерактивный режим, -4 форсирует IPv4
    curl -sL yabs.sh | bash -s -- -4 -i </dev/null
}

run_ip_check_place() {
    print_separator "IP Check Place (CLI Mode)"
    # -c включает консольный режим без отрисовки окон
    bash <(curl -Ls IP.Check.Place) -l en -c </dev/null
}

run_bench_sh() {
    print_separator "bench.sh"
    wget -qO- bench.sh | bash </dev/null
}

run_ip_quality() {
    print_separator "IP Quality Check (Silent Mode)"
    # -u отключает меню выбора, делает всё по дефолту
    bash <(curl -Ls https://Check.Place) -u </dev/null
}

run_sysbench_cpu() {
    print_separator "sysbench CPU"
    sysbench cpu run --threads=1
}

# ============================================================
#  Логика запуска
# ============================================================

run_all_automatic() {
    print_header
    install_deps

    local tests=(
        run_ip_region run_censorcheck_geoblock run_censorcheck_dpi 
        run_iperf3_ru run_yabs run_ip_check_place 
        run_bench_sh run_ip_quality run_sysbench_cpu
    )

    for i in "${!tests[@]}"; do
        local test_name="${tests[$i]}"
        echo -e "${CYAN}[$((i+1))/${#tests[@]}] Выполняю: $test_name...${NC}"
        $test_name
        echo -e "${GREEN}✔ Успешно завершено${NC}"
        echo "--------------------------------------------------" >> "$LOG_FILE"
    done

    echo -e "\n${GREEN}${BOLD}Диагностика завершена!${NC}"
    echo -e "${GREEN}Полный отчет доступен здесь: ${BOLD}$LOG_FILE${NC}"
}

# Автоматический запуск при вызове
run_all_automatic
