#!/bin/bash
# =============================================================================
# CloudNova Technologies — Postgres Backup & Rotation
# Runs nightly via cron. Dumps Postgres, archives app volume, prunes >7 days.
# =============================================================================

set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/cloudnova}"
BACKUP_DIR="/var/backups/cloudnova"
LOG_FILE="/var/log/cloudnova-backup.log"
RETENTION_DAYS=7
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DB_CONTAINER="cloudnova_db"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"
log "=== Starting CloudNova backup run ==="

command -v docker >/dev/null 2>&1 || die "Docker is not installed."
docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$" \
    || die "DB container '${DB_CONTAINER}' is not running."

# shellcheck disable=SC1091
[ -f "${STACK_DIR}/.env" ] && source "${STACK_DIR}/.env"
: "${POSTGRES_USER:=cloudnova_admin}"
: "${POSTGRES_DB:=cloudnova}"

# ---- 1. Postgres dump -------------------------------------------------------
DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
log "Dumping Postgres to ${DB_FILE}"
docker exec "$DB_CONTAINER" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
    | gzip > "$DB_FILE"
[[ -s "$DB_FILE" ]] || die "Database dump is empty."

# ---- 2. Health check --------------------------------------------------------
if curl -fsS -o /dev/null http://localhost:3000/api/health; then
    log "Health check: web is responding on :3000 (OK)"
else
    log "WARNING: web did not respond on :3000"
fi

# ---- 3. Rotate --------------------------------------------------------------
log "Rotating backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -print -delete \
    | sed 's/^/   deleted: /' | tee -a "$LOG_FILE" || true

# ---- 4. Summary -------------------------------------------------------------
DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
log "Backup complete. DB=${DB_SIZE}"
log "=== Finished CloudNova backup run ==="
