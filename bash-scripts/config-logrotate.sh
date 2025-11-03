#!/bin/bash
# ===================================================================
# Setup logrotate rule for Arquify internal services deploy logs
# File: /var/log/arquify-internal-services-deploy.log
# Author: Maia Viera
# Date: 2025-11-01
# ===================================================================
IMPORT_UTILS_FILE="./common-utils.sh"

set -euo pipefail
source "${IMPORT_UTILS_FILE}"

filename=$(basename "$LOGFILE" .log)
CONF_FILE="/etc/logrotate.d/${filename}"
ROTATE_SIZE="10M"      # Rotate when log is bigger than 10 MB
ROTATE_COUNT=2         # Keep 2 old versions
USER="${LOGS_OWNER}"
PERMISSIONS="${LOGS_OWNER_PERMISSIONS}"
GROUP="${LOGS_OWNER_GROUP}"

log "🚀 Starting Logrotate configuration..."
require_root_privilege

if [[ -f "$CONF_FILE" ]]; then
    log "ℹ️ Logrotate configuration already exists: $CONF_FILE"
else
    log "📝 Creating logrotate configuration for $LOGFILE..."

    cat > "$CONF_FILE" <<EOF
$LOGFILE {
    size $ROTATE_SIZE
    rotate $ROTATE_COUNT
    compress
    missingok
    notifempty
    create $PERMISSIONS $USER $GROUP
    su $USER $GROUP
    sharedscripts
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF

    log "✅ Logrotate configuration created at: $CONF_FILE"
fi

# --- Validate configuration syntax ---
if logrotate --debug "$CONF_FILE" >/dev/null 2>&1; then
    log "✅ Logrotate configuration validated successfully."
else
    log "⚠️ Warning: logrotate validation failed. Check $CONF_FILE."
fi

log "🎉 Log rotation setup complete. Logs will rotate automatically when > $ROTATE_SIZE."
