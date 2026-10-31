#!/bin/bash
# =============================================================================
# CloudNova Technologies — One-Command Deployment Script
# Target: Fresh Ubuntu instance (KillerCoda, Ubuntu Server, WSL)
# Does: install Docker (if missing), configure UFW, build & start stack,
#       install backup script + cron job.
# =============================================================================

set -e

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${CYAN}==>${NC} ${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}!! $*${NC}"; }

# ---- 1. Docker ---------------------------------------------------------------
step "Checking Docker"
if ! command -v docker >/dev/null 2>&1; then
    step "Installing Docker"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER" || true
fi
docker --version
docker compose version

# ---- 2. Env file -------------------------------------------------------------
step "Preparing environment"
if [ ! -f .env ]; then
    cp .env.example .env
    warn "Created .env from example — edit passwords before production!"
fi

# ---- 3. Build & start --------------------------------------------------------
step "Building and starting the stack"
sudo docker compose up -d --build
sleep 5
sudo docker compose ps

# ---- 4. UFW firewall ---------------------------------------------------------
step "Configuring UFW firewall"
if command -v ufw >/dev/null 2>&1; then
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp     comment 'SSH'
    sudo ufw allow 3000/tcp   comment 'CloudNova web'
    sudo ufw --force enable
    sudo ufw status verbose
else
    warn "UFW not installed; skipping firewall step"
fi

# ---- 5. Backup script + cron -------------------------------------------------
step "Installing backup automation"
sudo cp backup.sh /usr/local/bin/cloudnova-backup.sh
sudo chmod +x /usr/local/bin/cloudnova-backup.sh
sudo mkdir -p /var/backups/cloudnova
sudo touch /var/log/cloudnova-backup.log

CRON_LINE="0 2 * * *  /usr/local/bin/cloudnova-backup.sh >> /var/log/cloudnova-backup.log 2>&1"
( sudo crontab -l 2>/dev/null | grep -v cloudnova-backup; echo "$CRON_LINE" ) | sudo crontab -
echo "Installed cron entry:"
sudo crontab -l | grep cloudnova

# ---- 6. Summary --------------------------------------------------------------
step "Deployment complete"
echo "Web UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "Logs:   sudo docker compose logs -f"
echo "Backup: sudo /usr/local/bin/cloudnova-backup.sh"
