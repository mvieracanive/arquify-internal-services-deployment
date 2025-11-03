#!/bin/bash
# ===================================================================
# Update Script for
#   - Ubuntu System
#   - Docker 
# Author: Maia Viera
# Date: 2025-11-01
# ===================================================================

set -euo pipefail

# --- Config ---
DOCKER_SERVICE="docker"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# --- Main ---
require_root

log "=== Starting system patch ==="

# 1. Update system packages
log "→ Updating APT package lists..."
apt-get update -y | tee -a "$LOGFILE"

log "→ Upgrading packages..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y | tee -a "$LOGFILE"

log "→ Running dist-upgrade (kernel & dependencies)..."
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y | tee -a "$LOGFILE"

# 2. Check if Docker is installed
if command -v docker >/dev/null 2>&1; then
    log "→ Docker is installed. Checking version..."
    docker --version | tee -a "$LOGFILE"

    log "→ Ensuring latest Docker Engine and CLI are installed..."
    apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | tee -a "$LOGFILE"

    log "→ Checking Docker Compose plugin..."
    docker compose version | tee -a "$LOGFILE"

    # 3. Restart Docker safely
    log "→ Restarting Docker service..."
    systemctl restart "$DOCKER_SERVICE"
    systemctl status "$DOCKER_SERVICE" --no-pager | tee -a "$LOGFILE"

    # 4. Optional: Restart running containers gracefully
    log "→ Restarting running containers..."
    docker ps -q | xargs -r docker restart | tee -a "$LOGFILE"

    # 5. Cleanup
    log "→ Cleaning unused Docker data..."
    docker system prune -af | tee -a "$LOGFILE"
else
    log "⚠️  Docker is not installed. Skipping Docker upgrade."
fi

# 6. Final cleanup
log "→ Cleaning APT cache..."
apt-get autoremove -y && apt-get autoclean -y | tee -a "$LOGFILE"

log "✅ System and Docker update completed successfully!"
log "Log saved at: $LOGFILE"
