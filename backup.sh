#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Sauvegarde
#  Archive la configuration (docker-compose, YAML, clés, .env) dans backups/.
#  Conservation : 30 jours (rotation automatique).
#
#  Usage :  sudo ./backup.sh   (idéal en cron quotidien)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
. "${SCRIPT_DIR}/scripts/lib.sh"

BACKUP_DIR="${POLARIS_ROOT}/backups"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="${BACKUP_DIR}/polaris-${STAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

log "Création de la sauvegarde ${ARCHIVE}…"
tar -czf "${ARCHIVE}" \
  -C "${POLARIS_ROOT}" \
  --exclude='./backups' \
  --exclude='./logs' \
  --exclude='./.git' \
  docker-compose.yml \
  mediamtx.yml \
  .env \
  firewall.sh \
  scripts \
  docs \
  2>/dev/null || die "Échec de la création de l'archive."

ok "Sauvegarde créée : $(du -h "${ARCHIVE}" | cut -f1) — ${ARCHIVE}"

# --- Rotation : supprime les archives de plus de RETENTION_DAYS jours ---
DELETED="$(find "${BACKUP_DIR}" -name 'polaris-*.tar.gz' -mtime "+${RETENTION_DAYS}" -print -delete | wc -l)"
[ "${DELETED}" -gt 0 ] && log "Rotation : ${DELETED} ancienne(s) sauvegarde(s) supprimée(s)."

ok "Sauvegardes disponibles :"
ls -1t "${BACKUP_DIR}"/polaris-*.tar.gz 2>/dev/null | head -n 5
