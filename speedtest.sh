#!/bin/bash

# --- 1. Style & Config ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

DL_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
UP_URL="https://speed.cloudflare.com/__up"
UA="Mozilla/5.0 (X11; Linux x86_64)"

# --- 2. Intern's Spinner ---
spinner() {
    local delay=0.1; local spinstr='|/-\'
    while true; do
        printf " [${GREEN}%c${NC}]  " "$spinstr"
        local temp=${spinstr#?}; spinstr=$temp${spinstr%"$temp"}
        sleep $delay; printf "\b\b\b\b\b\b"
    done
}

cleanup() {
    [ ! -z "$SPINNER_PID" ] && kill "$SPINNER_PID" > /dev/null 2>&1
    kill $(jobs -p) 2>/dev/null
    rm -f /tmp/st_payload
    exit
}
trap cleanup SIGINT SIGTERM

echo -e "${GREEN}🚀 SpeedTest${NC}"
echo "-------------------------------------------"

# --- 3. Interface Detection & Stats Setup ---
INTF=$(ip route | grep default | awk '{print $5}' | head -n1)
LINK_SPEED=$(cat /sys/class/net/$INTF/speed 2>/dev/null)
RX_PATH="/sys/class/net/$INTF/statistics/rx_bytes"
TX_PATH="/sys/class/net/$INTF/statistics/tx_bytes"

echo -e "  🔗 ${CYAN}Interface:${NC} $INTF ($LINK_SPEED Mbps link)"

# --- 4. Download Test (Kernel-Counter Method) ---
echo -n "  📥 Testing Download... "

# Capture initial bytes and time
start_bytes=$(cat "$RX_PATH")
start_time=$(date +%s%N)

spinner &
SPINNER_PID=$!

(
    # 10 streams to saturate the 1000Mbps link
    for i in {1..10}; do
        curl -L -sk -H "User-Agent: $UA" "$DL_URL" -o /dev/null &
    done
    wait
)

kill $SPINNER_PID > /dev/null 2>&1
printf "\b\b\b\b\b\b"

end_bytes=$(cat "$RX_PATH")
end_time=$(date +%s%N)

# Logic: (End Bytes - Start Bytes) * 8 bits / seconds
diff_bytes=$((end_bytes - start_bytes))
duration_s=$(echo "scale=9; ($end_time - $start_time) / 1000000000" | bc)
dl_mbps=$(echo "scale=2; ($diff_bytes * 8) / $duration_s / 1000000" | bc)

echo -e "${GREEN}$dl_mbps Mbps${NC}"

# --- 5. Upload Test (Kernel-Counter Method) ---
echo -n "  📤 Testing Upload...   "

payload="/dev/shm/st_payload"
[ ! -f "$payload" ] && head -c 25M /dev/urandom > "$payload"

start_bytes_tx=$(cat "$TX_PATH")
start_time_up=$(date +%s%N)

spinner &
SPINNER_PID=$!

(
    for i in {1..6}; do
        curl -sk -H "User-Agent: $UA" -T "$payload" "$UP_URL" -o /dev/null &
    done
    wait
)

kill $SPINNER_PID > /dev/null 2>&1
printf "\b\b\b\b\b\b"

end_bytes_tx=$(cat "$TX_PATH")
end_time_up=$(date +%s%N)

diff_bytes_tx=$((end_bytes_tx - start_bytes_tx))
duration_s_up=$(echo "scale=9; ($end_time_up - $start_time_up) / 1000000000" | bc)
up_mbps=$(echo "scale=2; ($diff_bytes_tx * 8) / $duration_s_up / 1000000" | bc)

echo -e "${GREEN}$up_mbps Mbps${NC}"

# Final Cleanup
rm -f "$payload"
echo "-------------------------------------------"
