#!/bin/bash
# =============================================================================
# CloudNova Technologies - Automated Disaster Recovery Script
# Purpose : Nightly backup of MySQL database + WordPress files, with rotation
#           and basic health checks. Logs every run for audit trail.
# Author  : Enterprise Cloud Architect
# Schedule: Executed by cron (see operational-manual.md).
# =============================================================================

set -euo pipefail

# ---- CONFIGURATION ----------------------------------------------------------
STACK_DIR="/opt/cloudnova"                 # where docker-compose.yml lives
BACKUP_DIR="/var/backups/cloudnova"        # where backups are stored
LOG_FILE="/var/log/cloudnova-backup.log"
RETENTION_DAYS=7                           # how many days of backups to keep
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DB_CONTAINER="cloudnova_db"
WP_VOLUME="laboratory-10-enterprise-cloud-architect_wp_data"

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

# ---- 1. DATABASE DUMP -------------------------------------------------------
DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
log "Dumping MySQL database to ${DB_FILE}"

# Load env (same file docker-compose uses)
# shellcheck disable=SC1091
source "${STACK_DIR}/.env"

docker exec "$DB_CONTAINER" \
    mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases --single-transaction --quick \
    | gzip > "$DB_FILE"

[[ -s "$DB_FILE" ]] || die "Database dump is empty."

# ---- 2. WORDPRESS FILES ARCHIVE --------------------------------------------
WP_FILE="${BACKUP_DIR}/wp_${TIMESTAMP}.tar.gz"
log "Archiving WordPress volume to ${WP_FILE}"

docker run --rm \
    -v "${WP_VOLUME}:/source:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine:3.20 \
    tar -czf "/backup/wp_${TIMESTAMP}.tar.gz" -C /source .

[[ -s "$WP_FILE" ]] || die "WordPress archive is empty."

# ---- 3. HEALTH CHECK --------------------------------------------------------
if curl -fsS -o /dev/null http://localhost:8080; then
    log "Health check: WordPress is responding on :8080 (OK)"
else
    log "WARNING: WordPress did not respond on :8080"
fi

# ---- 4. ROTATION ------------------------------------------------------------
log "Rotating backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -print -delete \
    | sed 's/^/   deleted: /' | tee -a "$LOG_FILE"

# ---- 5. SUMMARY -------------------------------------------------------------
DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
WP_SIZE=$(du -h "$WP_FILE" | cut -f1)
log "Backup complete. DB=${DB_SIZE}  WP=${WP_SIZE}"
log "=== Finished CloudNova backup run ==="
exit 0
