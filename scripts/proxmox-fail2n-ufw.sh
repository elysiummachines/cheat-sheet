#!/bin/bash
# ===== Proxmox Host Hardening Script ===== #
# ===== Run as root ===== #
# ===== NOTE: Skips SSH hardening ===== #
# ===== Proxmox cluster requires ===== #
# ===== root SSH + port 22 intact  ===== #

set -euo pipefail
export PATH=$PATH:/usr/sbin:/sbin

# ===== COLOR OUTPUT ===== #
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ===== MUST RUN AS ROOT ===== #
[[ $EUID -ne 0 ]] && err "Run this script as root (sudo)."

# ===== INSTALL REQUIRED PACKAGES ===== #
log "Installing required packages..."
apt update -qq
apt install -y ufw fail2ban unattended-upgrades
log "Packages installed."

# ===== UFW FIREWALL ===== #
log "Configuring UFW..."
ufw --force reset

# Allow internal networks 
ufw allow from 10.0.0.0/8
ufw allow from 172.16.0.0/12
ufw allow from 192.168.0.0/16

# SSH
ufw allow 22/tcp                    # SSH default - required for cluster
ufw allow 3100/tcp                  # SSH custom port

# Proxmox Web UI and API
ufw allow 8006/tcp                  # Web UI
ufw allow 3128/tcp                  # backup server / proxy
ufw allow 3052/tcp                  # SPICE proxy
ufw allow 2003/tcp                  # Graphite/Carbon metrics

# Proxmox Cluster Communication
ufw allow 5404/udp                  # Corosync cluster traffic
ufw allow 5405/udp                  # Corosync cluster traffic

# RPC / NFS
ufw allow 111/tcp
ufw allow 111/udp
ufw allow 2049/tcp
ufw allow 2049/udp

# SNMP
ufw allow 162/udp

# HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

ufw default deny incoming
ufw default allow outgoing
ufw default deny forward
ufw logging on
ufw --force enable
log "UFW configured."

# ===== SYSCTL HARDENING ===== #
log "Applying sysctl hardening..."
cat <<EOF > /etc/sysctl.d/99-hardening.conf
# IP Spoofing / Source routing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore ICMP redirects (prevents MITM)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Ignore ping broadcasts (Smurf attacks)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log suspicious (Martian) packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Keep IP forwarding ENABLED - required for Proxmox VM networking
net.ipv4.ip_forward = 1

# Protect against time-wait assassination
net.ipv4.tcp_rfc1337 = 1

# Restrict dmesg to root
kernel.dmesg_restrict = 1

# Hide kernel pointers
kernel.kptr_restrict = 2

# Restrict ptrace (limits process inspection)
kernel.yama.ptrace_scope = 1
EOF
sysctl --system
log "Sysctl hardening applied."

# ===== PREVENT IP SPOOFING VIA /etc/host.conf ===== #
log "Hardening /etc/host.conf..."
cp /etc/host.conf /etc/host.conf.bak
cat <<EOF > /etc/host.conf
order bind,hosts
multi on
EOF

# ===== FAIL2BAN ===== #
log "Configuring fail2ban..."
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
port    = 22,PORT #incase you have more than one port
logpath = %(sshd_log)s

[proxmox]
enabled  = true
port     = https,http,8006
filter   = proxmox
logpath  = /var/log/daemon.log
maxretry = 3
bantime  = 1h
EOF

# ===== PROXMOX FAIL2BAN FILTER ===== #
cat <<EOF > /etc/fail2ban/filter.d/proxmox.conf
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
EOF

systemctl enable --now fail2ban
log "Fail2ban enabled and started."

# ===== DISABLE UNUSED SERVICES ===== #
log "Disabling unnecessary services..."
for svc in avahi-daemon cups; do
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    systemctl disable --now "$svc"
    warn "Disabled: $svc"
  fi
done

# ===== AUTOMATIC SECURITY UPDATES ===== #
log "Enabling automatic security updates..."
dpkg-reconfigure --priority=low unattended-upgrades
log "Automatic security updates enabled."

# ===== SUMMARY ===== #
log "Hardening complete. Listening ports:"
ss -tunlp

log "UFW Status:"
ufw status verbose

log "Fail2ban Status:"
systemctl status fail2ban
