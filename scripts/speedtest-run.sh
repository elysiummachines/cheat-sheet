#!/bin/bash


# SERVER_ID=
RUNS=3
LOG_DIR="/var/log/speedtest"
LOG_FILE="$LOG_DIR/speedtest-$(date +%Y-%m-%d_%H-%M-%S).log"

# ===== create log dir if missing ===== #
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
fi

# ===== helper ===== #
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# ===== install speedtest if missing ===== #
if ! command -v speedtest &> /dev/null; then
    echo "[INFO] speedtest not found, installing..."
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt install speedtest -y

    # ===== check install succeeded ===== #
    if ! command -v speedtest &> /dev/null; then
        echo "[ERROR] install failed, exiting."
        exit 1
    fi

    echo "[INFO] speedtest installed successfully."
fi

# ===== version ===== #
log "========================================"
log " $(speedtest --version)"
log "========================================"
log ""

# ===== header ===== #
log "========================================"
log " Speedtest Results"
log " Date : $(date)"
log "========================================"
log ""

# ===== runs ===== #
for i in $(seq 1 $RUNS); do
    log "--- Run #$i ---"
    speedtest --accept-license | tee -a "$LOG_FILE"
    log ""

    # ===== don't sleep after last run ===== #
    if [ "$i" -lt "$RUNS" ]; then
        sleep 5
    fi
done

# ===== done ===== #
log "========================================"
log " Done! Results saved to: $LOG_FILE"
log "========================================"