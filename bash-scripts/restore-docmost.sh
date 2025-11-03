#!/bin/bash
# =========================================
# Restore Docmost and PostgreSQL (pg_dump + volume restore)
# Author: Maia Viera
# Date: 2025-11-02
# =========================================

IMPORT_UTILS_FILE="./common-utils.sh"

set -euo pipefail
source "${IMPORT_UTILS_FILE}"

require_root_privilege

#-------------------Config-------------------
envFile=${DOCKER_SERVICES_DIR}/.env
composeFile="$DOCKER_SERVICES_DIR/docker-compose.yml"
docmostVolume=${DOCKER_DOCMOST_VOLUME}
postgresVolume=${DOCKER_POSTGRES_VOLUME}
postgresContainerName=${POSTGRES_CONTAINER_NAME:-db}
postgresDbName=${POSTGRES_DB:-docmost}

log "🚀 Sourcing environment variables from file $envFile..."
set -a
source "$envFile"
set +a
log "✅ Environment variables sourced"

backupDir=${BASH_BACKUP_DIR}

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

docmostBackup=$(find "$backupSubDir" -type f -name "docmost_volume_${DATE}.tar.gz" | head -n 1)
postgresDump=$(find "$backupSubDir" -type f -name "postgres_dump_${DATE}.sql.gz" | head -n 1)

#-------------------Sanity checks before restore-------------------
if [[ ! -f "$docmostBackup" ]]; then
  log "❌ Missing Docmost backup file: expected ${backupSubDir}/docmost_volume_${DATE}.tar.gz"
  exit 1
fi

if [[ ! -f "$postgresDump" ]]; then
  log "❌ Missing PostgreSQL dump file: expected ${backupSubDir}/postgres_dump_${DATE}.sql.gz"
  exit 1
fi

log "✅ Found both backup files:"
log "   - Docmost: $docmostBackup"
log "   - PostgreSQL: $postgresDump"

#-------------------Confirm destructive restore-------------------
echo "⚠️ WARNING: This will ERASE all current Docmost and PostgreSQL data and restore from backup:"
echo "   - Docmost volume: $docmostBackup"
echo "   - PostgreSQL dump: $postgresDump"
read -rp "Are you absolutely sure you want to continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  log "🛑 Restore cancelled by user."
  exit 0
fi

#-------------------Stop containers-------------------
log "🛑 Stopping containers before restore..."
docker compose -f "$composeFile" down
log "✅ Containers stopped."

#-------------------Restore Docmost volume-------------------
log "📁 Restoring Docmost volume..."
docmostPath=$(docker volume inspect "$docmostVolume" --format '{{ .Mountpoint }}' 2>/dev/null || true)

if [[ -z "$docmostPath" ]]; then
  log "❌ Docmost volume ($docmostVolume) not found. Creating it..."
  docker volume create "$docmostVolume" >/dev/null
  docmostPath=$(docker volume inspect "$docmostVolume" --format '{{ .Mountpoint }}')
fi

rm -rf "${docmostPath:?}"/* || true
tar -xzf "$docmostBackup" -C "$docmostPath"
log "✅ Docmost volume restored from: $docmostBackup"

#-------------------Erase PostgreSQL volume and restore DB-------------------
log "🐘 Restoring PostgreSQL database from dump..."

postgresPath=$(docker volume inspect "$postgresVolume" --format '{{ .Mountpoint }}' 2>/dev/null || true)
if [[ -z "$postgresPath" ]]; then
  log "❌ PostgreSQL volume ($postgresVolume) not found. Creating it..."
  docker volume create "$postgresVolume" >/dev/null
  postgresPath=$(docker volume inspect "$postgresVolume" --format '{{ .Mountpoint }}')
fi

log "🧹 Erasing PostgreSQL volume contents..."
rm -rf "${postgresPath:?}"/* || true

: "${POSTGRES_USER:?Missing POSTGRES_USER in .env}"
: "${POSTGRES_PASSWORD:?Missing POSTGRES_PASSWORD in .env}"

log "🚀 Starting PostgreSQL container..."
docker compose -f "$composeFile" up -d "$postgresContainerName"
sleep 10

container_id=$(docker compose -f "$composeFile" ps -q "$postgresContainerName")
if [[ -z "$container_id" ]]; then
  log "❌ Could not find running PostgreSQL container. Exiting."
  exit 1
fi

log "📥 Importing SQL dump into new PostgreSQL instance..."
gunzip -c "$postgresDump" | docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" "$container_id" \
  psql -U "${POSTGRES_USER}" -d "$postgresDbName"

log "✅ PostgreSQL database restored successfully from: $postgresDump"

#-------------------Start containers-------------------
log "🚀 Starting all containers after restore..."
docker compose -f "$composeFile" up -d
log "✅ Containers started successfully."

#-------------------Health check-------------------
log "🔎 Checking container health..."
sleep 10

docmost_status=$(docker compose -f "$composeFile" ps | grep -c "docmost.*running" || true)
db_status=$(docker compose -f "$composeFile" ps | grep -c "$postgresContainerName.*running" || true)

if [[ "$docmost_status" -ge 1 && "$db_status" -ge 1 ]]; then
  log "✅ Both Docmost and PostgreSQL containers are running correctly."
else
  log "⚠️ One or more containers may not be healthy. Check logs with:"
  log "   docker compose -f \"$composeFile\" logs --tail 50"
fi

#-------------------Done-------------------
log "🎉 Restore completed successfully!"
log "📂 Data restored from: $backupSubDir"
