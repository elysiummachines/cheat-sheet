#!/bin/bash

# ======================================================= #
#  Script: smart_clean_memory.sh
#  Version: 0.1.0
#  Last Updated: 2026-03-25
#  Logs activity to /var/log/smartclean.log
#
#  Description:
#   - Securely cleans RAM caches, temporary files, user caches,
#     system logs, swap files, and trims SSD storage safely.
#   - Clears pagecache, dentries, inodes, journal logs, and package debris.
#   - Optional --full mode wipes Telegram, Brave, Chrome caches too.
#   - Logs every step into /var/log/smartclean.log with secure ownership.
#   - Automatically adds itself to crontab for scheduled weekly runs.
#
#  Scope:
#   - Systems: Debian-based Linux distributions (Debian, Ubuntu, etc.)
#   - Environments: Personal laptops, developer workstations, lightweight servers.
#
#  Sample Usage:
#   - sudo ./smart_clean_memory.sh
#   - sudo ./smart_clean_memory.sh --full
# ======================================================= #

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "Run this script with sudo." >&2
    exit 1
fi

LOG_FILE="/var/log/smartclean.log"
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR="/home/$REAL_USER"

# Ensure log file exists and is secure
touch "$LOG_FILE"
chown "$REAL_USER":"$REAL_USER" "$LOG_FILE"
chmod 600 "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

trap 'log "Script interrupted or exiting."' EXIT

# ===== Snapshot Before ===== #
DISK_USAGE_BEFORE=$(df / | awk 'NR==2 {print $5}')
SPACE_BEFORE=$(df /      | awk 'NR==2 {print $4}')
log "Disk usage before cleaning: $DISK_USAGE_BEFORE"
log "Starting Smart Clean Memory Routine..."

# ===== RAM Cache ===== #
log "→ Dropping RAM cache..."
sync; echo 3 > /proc/sys/vm/drop_caches

# ===== Swap ===== #
log "→ Restarting swap..."
swapoff -a && swapon -a

# ===== Journal Logs ===== #
log "→ Cleaning old system logs..."
journalctl --vacuum-time=1d

# ===== APT Debris ===== #
log "→ Autoremoving unused APT packages..."
apt-get autoremove -y
apt-get autoclean -y
apt-get clean

# ===== Temp Files ===== #
log "→ Cleaning temporary files..."
find /tmp/     -type f -user "$REAL_USER" -delete 2>/dev/null
find /var/tmp/ -type f -user "$REAL_USER" -delete 2>/dev/null

# ===== User Cache ===== #
log "→ Cleaning user cache..."
rm -rf "$HOME_DIR/.cache/"*

# ===== SSD Trim ===== #
if command -v fstrim &>/dev/null; then
    log "→ Trimming SSD storage..."
    fstrim -v / | tee -a "$LOG_FILE"
else
    log "→ fstrim not available, skipping SSD trim."
fi

# ===== Full Mode ===== #
if [[ "$1" == "--full" ]]; then
    log "Running Full Smart Clean (Extended Wipe)..."

    log "→ Wiping thumbnails..."
    rm -rf "$HOME_DIR/.cache/thumbnails/"*

    log "→ Wiping Telegram cache if exists..."
    rm -rf "$HOME_DIR/.local/share/TelegramDesktop/"*

    if [ -d "$HOME_DIR/.config/BraveSoftware" ]; then
        log "→ Wiping Brave browser cache..."
        rm -rf "$HOME_DIR/.config/BraveSoftware/Brave-Browser/Default/Cache/"*
    fi

    if [ -d "$HOME_DIR/.config/google-chrome" ]; then
        log "→ Wiping Chrome cache..."
        rm -rf "$HOME_DIR/.config/google-chrome/Default/Cache/"*
    fi
fi

# ===== Bash History ===== #
log "→ Clearing bash history..."
cat /dev/null > "$HOME_DIR/.bash_history"
su -c "history -c" "$REAL_USER" 2>/dev/null || true

# ===== Crontab ===== #
CRON_JOB="@weekly sudo bash /scripts/smart_clean_memory.sh --full > /dev/null 2>&1"
if ! crontab -l -u "$REAL_USER" 2>/dev/null | grep -q 'smart_clean_memory.sh'; then
    (crontab -l -u "$REAL_USER" 2>/dev/null; echo "$CRON_JOB") | crontab -u "$REAL_USER" -
    log "→ Added Smart Clean script to crontab (@weekly)."
else
    log "→ Smart Clean script already present in crontab."
fi

# ===== Disk Report ===== #
DISK_USAGE_AFTER=$(df / | awk 'NR==2 {print $5}')
SPACE_AFTER=$(df /      | awk 'NR==2 {print $4}')
FREED=$(( SPACE_AFTER - SPACE_BEFORE ))

log "Disk usage after cleaning: $DISK_USAGE_AFTER"
log "Space freed: $(( FREED / 1024 ))MB"
log "Memory Has Been Moefed & crontab added You Ape"
