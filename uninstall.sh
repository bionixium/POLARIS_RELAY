#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Désinstallation
#  Arrête et supprime les conteneurs/volumes Polaris. N'enlève NI Docker,
#  NI Tailscale, NI le pare-feu (choix laissé à l'opérateur).
#
#  Usage :  sudo ./uninstall.sh [--purge]
#           --purge : supprime aussi volumes, images et .env
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
. "${SCRIPT_DIR}/scripts/lib.sh"

require_root
cd "${SCRIPT_DIR}"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

log "Sauvegarde de sécurité avant désinstallation…"
bash "${SCRIPT_DIR}/backup.sh" || warn "Sauvegarde échouée — poursuite."

if [ "${PURGE}" -eq 1 ]; then
  warn "Mode --purge : suppression des conteneurs, volumes et images."
  compose down -v --rmi local || true
  rm -f "${SCRIPT_DIR}/.env"
  ok "Configuration locale purgée (.env supprimé). Les sauvegardes sont conservées."
else
  log "Arrêt et suppression des conteneurs (volumes conservés)…"
  compose down || true
  ok "Services arrêtés. Volumes et .env conservés (relancez ./install.sh pour repartir)."
fi

echo
log "Pour retirer aussi le pare-feu   : sudo ufw --force reset"
log "Pour retirer Tailscale           : sudo tailscale down && sudo apt-get remove tailscale"
