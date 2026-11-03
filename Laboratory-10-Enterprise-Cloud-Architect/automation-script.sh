#!/bin/bash
# =============================================================================
# CloudNova Technologies - Automated Disaster Recovery Script
# Purpose : Nightly backup of PostgreSQL database + Ghost content, with rotation
#           and basic health checks. Logs every run for audit trail.
# Author  : Enterprise Cloud Architect
# Schedule: Executed by cron (see operational-manual.md).
# =============================================================================

set -euo pipefail

# ---- CONFIGURATION ----------------------------------------------------------
STACK_DIR="/opt/cloudnova"
BACKUP_DIR="/var/backups/cloudnova"
LOG_FILE="/var/log/cloudnova-backup.log"
RETENTION_DAYS=7
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DB_CONTAINER="cloudnova_db"
GHOST_VOLUME="laboratory-10-enterprise-cloud-architect_ghost_content"

# ---- HELPERS ----------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# ---- PRECHECKS --------------------------------------------------------------
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"
log "=== Starting CloudNova backup run ==="

command -v docker >/dev/null 2>&1 || die "Docker is not installed."

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    die "Database container '${DB_CONTAINER}' is not running."
fi

# Load env (same file docker-compose uses)
# shellcheck disable=SC1091
source "${STACK_DIR}/.env"

# ---- 1. POSTGRES DUMP -------------------------------------------------------
DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
log "Dumping PostgreSQL database to ${DB_FILE}"

docker exec "$DB_CONTAINER" \
    pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
    | gzip > "$DB_FILE"

[[ -s "$DB_FILE" ]] || die "Database dump is empty."

# ---- 2. GHOST CONTENT ARCHIVE -----------------------------------------------
GHOST_FILE="${BACKUP_DIR}/ghost_${TIMESTAMP}.tar.gz"
log "Archiving Ghost content volume to ${GHOST_FILE}"

docker run --rm \
    -v "${GHOST_VOLUME}:/source:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine:3.20 \
    tar -czf "/backup/ghost_${TIMESTAMP}.tar.gz" -C /source .

[[ -s "$GHOST_FILE" ]] || die "Ghost content archive is empty."

# ---- 3. HEALTH CHECK --------------------------------------------------------
if curl -fsS -o /dev/null http://localhost:3000; then
    log "Health check: Ghost is responding on :3000 (OK)"
else
    log "WARNING: Ghost did not respond on :3000"
fi

# ---- 4. ROTATION ------------------------------------------------------------
log "Rotating backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -print -delete \
    | sed 's/^/   deleted: /' | tee -a "$LOG_FILE" || true

# ---- 5. SUMMARY -------------------------------------------------------------
DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
GHOST_SIZE=$(du -h "$GHOST_FILE" | cut -f1)
log "Backup complete. DB=${DB_SIZE}  Ghost=${GHOST_SIZE}"
log "=== Finished CloudNova backup run ==="
exit 0
