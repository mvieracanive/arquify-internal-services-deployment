#!/bin/bash
# =========================================
# Restore Docmost and PostgreSQL Docker volumes
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
docmostContainerName=${DOCMOST_CONTAINER_NAME}
postgresContainerName=${POSTGRES_CONTAINER_NAME}

log "🚀 Sourcing environment variables from file $envFile..."
set -a
source "$envFile"
set +a 
log "✅ Environment variables sourced"

backupDir=${BASH_BACKUP_DIR}
composeFile="$DOCKER_SERVICES_DIR/docker-compose.yml"

#-------------------Select backup-------------------
log "🗂 Searching for available backups..."
if [[ ! -d "$backupDir" ]]; then
  log "❌ Backup directory not found: $backupDir"
  exit 1
fi

echo "🗂 Available backups:"
ls -1t "$backupDir"

read -rp "Enter the DATE folder to restore (e.g., 2025-11-02_14-00-00): " DATE
backupSubDir="$backupDir/$DATE"

docmostBackup="${backupSubDir}/docmost_volume_${DATE}.tar.gz"
postgresBackup="${backupSubDir}/postgres_volume_${DATE}.tar.gz"

if [[ ! -f "$docmostBackup" || ! -f "$postgresBackup" ]]; then
  log "❌ Backup files not found for date $DATE in $backupSubDir."
  exit 1
fi

#-------------------Confirm destructive restore-------------------
echo "⚠️ WARNING: This will ERASE all current Docmost and PostgreSQL data and restore from backup:"
echo "   - Docmost backup: $docmostBackup"
echo "   - PostgreSQL backup: $postgresBackup"
read -rp "Are you absolutely sure you want to continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  log "🛑 Restore cancelled by user."
  exit 0
fi

#-------------------Stop containers-------------------
log "🛑 Stopping containers before restore..."
docker compose -f "$composeFile" down
log "✅ Containers stopped."

#-------------------Locate volumes-------------------
log "🔍 Locating Docker volumes..."
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

#-------------------Restore Docmost volume-------------------
log "📁 Restoring Docmost volume..."
rm -rf "${docmostPath:?}"/* || true
tar -xzf "$docmostBackup" -C "$docmostPath"
log "✅ Docmost volume restored from: $docmostBackup"

#-------------------Restore PostgreSQL volume-------------------
log "🐘 Restoring PostgreSQL volume..."
rm -rf "${postgresPath:?}"/* || true
tar -xzf "$postgresBackup" -C "$postgresPath"
log "✅ PostgreSQL volume restored from: $postgresBackup"

#-------------------Start containers-------------------
log "🚀 Starting containers after restore..."
docker compose -f "$composeFile" up -d
log "✅ Containers started successfully."

#-------------------Health check-------------------
log "🔎 Checking container health..."
sleep 10  # Give them a few seconds to initialize

docmost_status=$(docker compose -f "$composeFile" ps "$docmostContainerName" | grep -c "running" || true)
db_status=$(docker compose -f "$composeFile" ps "$postgresContainerName" | grep -c "running" || true)

if [[ "$docmost_status" -eq 1 && "$db_status" -eq 1 ]]; then
  log "✅ Both Docmost and PostgreSQL containers are running correctly."
else
  log "⚠️ One or more containers are not running properly. Check logs with:"
  log "   docker compose -f \"$composeFile\" logs --tail 50"
fi

#-------------------Done-------------------
log "🎉 Restore completed successfully!"
log "📂 Data restored from: $backupSubDir"
