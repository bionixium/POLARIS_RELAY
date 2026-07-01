#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Mise à jour
#  Récupère les dernières images, reconstruit SRTLA et redémarre proprement.
#  (Watchtower le fait automatiquement chaque nuit ; ce script force à la main.)
#
#  Usage :  sudo ./update.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
. "${SCRIPT_DIR}/scripts/lib.sh"

require_root
cd "${SCRIPT_DIR}"

log "Sauvegarde préalable de la configuration…"
bash "${SCRIPT_DIR}/backup.sh" || warn "Sauvegarde échouée — poursuite de la mise à jour."

log "Récupération des dernières images…"
compose pull

log "Reconstruction de l'image SRTLA…"
compose build --pull srtla

log "Redémarrage des services…"
compose up -d

log "Nettoyage des images obsolètes…"
docker image prune -f >/dev/null

ok "Mise à jour terminée."
compose ps
