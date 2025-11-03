#!/bin/bash
# =========================================
# Backup Docmost and PostgreSQL Docker volumes
# Author: Maia Viera
# Date: 2025-11-02
# =========================================-------------------------------------------------------

IMPORT_UTILS_FILE="./common-utils.sh"

set -euo pipefail
source "${IMPORT_UTILS_FILE}"

require_root_privilege

#-------------------Config-------------------
envFile=${DOCKER_SERVICES_DIR}/.env
docmostVolume=${DOCKER_DOCMOST_VOLUME}
postgresVolume=${DOCKER_POSTGRES_VOLUME}

log "🚀 Sourcing environment variables from file $envFile..."
set -a
source "$envFile"
set +a
log "✅ Environment variables sourced"

backupDir=${BASH_BACKUP_DIR}
composeFile="$DOCKER_SERVICES_DIR/docker-compose.yml"

DATE=$(date +%F_%H-%M-%S)
backupSubDir="${backupDir}/${DATE}"

mkdir -p "$backupSubDir"

log "📦 Starting volume-based backup at $DATE..."
log "Backup folder: $backupSubDir"

#-------------------Stop containers-------------------
log "🛑 Stopping all running containers before backup..."
docker compose -f "$composeFile" down
log "✅ Containers stopped."

#-------------------Locate volumes-------------------
docmostPath=$(docker volume inspect "$docmostVolume" --format '{{ .Mountpoint }}' 2>/dev/null || true)
postgresPath=$(docker volume inspect "$postgresVolume" --format '{{ .Mountpoint }}' 2>/dev/null || true)

if [[ -z "$docmostPath" || -z "$postgresPath" ]]; then
  log "❌ Could not locate one or more volumes. Make sure they exist."
  log "ℹ️ Available volumes:"
  docker volume ls
  exit 1
fi

log "📁 Docmost volume path: $docmostPath"
log "🐘 PostgreSQL volume path: $postgresPath"

#-------------------Backup Docmost volume-------------------
log "📁 Backing up Docmost volume..."
tar -czf "${backupSubDir}/docmost_volume_${DATE}.tar.gz" -C "$docmostPath" . 2>>"$LOGFILE"
log "✅ Docmost volume archived: ${backupSubDir}/docmost_volume_${DATE}.tar.gz"

#-------------------Backup PostgreSQL volume-------------------
log "🐘 Backing up PostgreSQL volume..."
tar -czf "${backupSubDir}/postgres_volume_${DATE}.tar.gz" -C "$postgresPath" . 2>>"$LOGFILE"
log "✅ PostgreSQL volume archived: ${backupSubDir}/postgres_volume_${DATE}.tar.gz"

#-------------------Restart containers-------------------
log "🚀 Restarting containers..."
docker compose -f "$composeFile" up -d
log "✅ Containers restarted successfully."

#-------------------Done-------------------
log "🎉 Backup completed successfully"
