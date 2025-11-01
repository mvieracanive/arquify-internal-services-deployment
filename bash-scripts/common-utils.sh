#!/bin/bash
# =========================================
# Bash Utility Library
# Common reusable functions
# Author: Maia Viera
# Date: 2025-11-01
# =========================================

LOGFILE="/var/log/arquify-internal-services-deploy.log"
LOGS_OWNER=maia
LOGS_OWNER_PERMISSIONS=640
LOGS_OWNER_GROUP=adm

log() {
    local logfile="${LOGFILE:?LOGFILE not set}"
    local permissions="${LOGS_OWNER_PERMISSIONS}"

    local logdir
    logdir=$(dirname "$logfile")
    if [[ ! -d "$logdir" ]]; then
        mkdir -p "$logdir" || {
            echo "BASH log -> ❌ Failed to create log directory: $logdir" >&2
            exit 1
        }
    fi

    if [[ ! -f "$logfile" ]]; then
        touch "$logfile" || {
            echo "BASH log -> ❌ Cannot create log file: $logfile" >&2
            exit 1
        }
        chmod "$permissions" "$logfile"
    fi

    echo "[$(date '+%F %T')] $*" | tee -a "$logfile"
}

require_root_privilege() {
    local required="root"

    local required_uid
    if [[ "$required" =~ ^[0-9]+$ ]]; then
        required_uid="$required"
    else
        required_uid=$(id -u "$required" 2>/dev/null) || {
            log "BASH require_root_privilege -> ❌ User '$required' does not exist."
            exit 1
        }
    fi

    if [[ "$EUID" -ne "$required_uid" ]]; then
        log "BASH require_root_privilege -> ❌ Please run this script as user '$required' (UID $required_uid)."
        exit 1
    fi

    log "BASH require_root_privilege -> ✅ Running as required user '$required' (UID $required_uid)."
}


run_and_log() {
    local cmd="$*"
    log "BASH rund and log -> ▶️ Running: $cmd"
    if output=$($cmd 2>&1); then
        log "$output"
    else
        log "BASH rund and log -> ❌ Command failed: $cmd"
        log "BASH rund and log -> $output"
        exit 1
    fi
}
