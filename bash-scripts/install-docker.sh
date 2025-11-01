#!/bin/bash
# ===================================================================
# Install Script for
#   - Docker (Ubuntu)
# Author: Maia Viera
# Date: 2025-11-01
# ===================================================================

UBUNTU_CODENAME=
IMPORT_UTILS_FILE="./common-utils.sh"

set -euo pipefail
source "${IMPORT_UTILS_FILE}"

log "🚀 Starting Docker installation..."
require_root_privilege

run_and_log apt-get update -y
run_and_log apt-get install -y ca-certificates curl

# --- Add Docker’s official GPG key ---
log "🔑 Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# --- Add Docker repository ---
source /etc/os-release
UBUNTU_CODENAME=${UBUNTU_CODENAME:-$VERSION_CODENAME}
log "🧩 Detected Ubuntu codename: ${UBUNTU_CODENAME}"

echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable' > /etc/apt/sources.list.d/docker.list

# --- Install Docker ---
run_and_log apt-get update -y

run_and_log apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- Verify installation ---
log "🔍 Verifying Docker installation..."
run_and_log docker --version
run_and_log systemctl enable docker --now

log "✅ Docker installation completed successfully."
