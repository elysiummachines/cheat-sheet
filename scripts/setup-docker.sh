#!/bin/bash
# setup-docker.sh + Secure Docker Environment Setup
# Creates proper directory structure with S.B.P

set -e

# ===== LOGGING =====

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ===== PRE-CHECKS =====

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        log_error "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

check_sudo() {
    if ! sudo -v; then
        log_error "User $USER does not have sudo privileges!"
        exit 1
    fi
}

if [[ "$1" == "--install" ]] || [[ "$1" == "-i" ]]; then
    log_info "Installing docker-setup to /usr/local/bin..."
    sudo install -m 755 "$0" /usr/local/bin/docker-setup
    log_success "Installed! Now run: docker-setup"
    exit 0
fi

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Docker Environment Setup"
    echo ""
    echo "Usage:"
    echo "  ./$(basename "$0")            # Run setup directly"
    echo "  ./$(basename "$0") --install  # Install to /usr/local/bin"
    echo "  ./$(basename "$0") --help     # Show this help"
    echo ""
    echo "Features:"
    echo "  • Installs Docker and Docker Compose"
    echo "  • Creates secure directory structure"
    echo "  • Sets proper permissions (security-focused)"
    echo "  • Configures Docker group membership"
    echo "  • Creates example project"
    echo ""
    echo "After installation:"
    echo "  docker-setup               # Run from anywhere"
    exit 0
fi

# ===== INSTALL =====

clear
echo "========================================"
echo "   Docker Environment Setup"
echo "========================================"
echo ""

check_root
check_sudo

log_info "Step 1/7: Installing Docker and Docker Compose..."
sudo apt update
sudo apt install -y docker.io docker-compose

log_info "Step 2/7: Setting up Docker group..."
sudo groupadd -f docker

log_info "Step 3/7: Adding $USER to Docker group..."
sudo usermod -aG docker "$USER"

log_info "Step 4/7: Creating secure directory structure..."
mkdir -p -m 750 ~/docker

log_info "Step 5/7: Setting directory permissions..."
mkdir -p -m 770 ~/docker/volumes
mkdir -p -m 750 ~/docker/compose
mkdir -p -m 750 ~/docker/configs
mkdir -p -m 700 ~/docker/secrets
mkdir -p -m 750 ~/docker/backups

log_info "Step 6/7: Setting ownership..."
sudo chown -R "$USER":docker ~/docker

log_info "Step 7/7: Creating starter files and examples..."

cat > ~/docker/.gitignore << 'EOF'
# Docker Secrets & Data
/secrets/
/volumes/
/backups/
*.env
.env.*
*.secret
docker-compose.override.yml

# IDE/Editor files
.vscode/
.idea/
*.iml
*.sublime-project
*.sublime-workspace
*.swp
*.swo
.DS_Store
EOF

echo ""
echo "🛡️ Installed versions:"
docker --version || echo "Docker: Run after logout"
docker-compose --version || echo "Docker Compose: Check installation"
echo ""

cat > ~/docker/README.md << 'EOF'
# Docker Environment

## Directory Structure:
- `stacks/` - Docker Compose YAML files
- `configs/` - Application configuration files  
- `volumes/` - Persistent container data
- `secrets/` - Sensitive files (passwords, keys) - 700 permissions
- `compose/` - Docker Compose utilities
- `backups/` - Backup files
EOF