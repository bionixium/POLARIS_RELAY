#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Pare-feu UFW
#  Politique : tout fermé par défaut. Seuls les ports des flux vidéo sont
#  ouverts sur Internet. L'administration passe exclusivement par Tailscale.
#
#  Note : les services admin (Portainer, Netdata, API MediaMTX) sont bindés
#  sur l'IP Tailscale dans docker-compose.yml. Ils sont donc déjà injoignables
#  depuis Internet, indépendamment d'UFW (Docker contourne UFW pour les ports
#  publiés). UFW protège ici l'hôte lui-même (SSH, services système).
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
. "${SCRIPT_DIR}/scripts/lib.sh"

require_root
load_env

need_cmd ufw || die "UFW non installé (apt-get install ufw)."

SRTLA_PORT="${SRTLA_PORT:-5000}"
SRT_PORT="${SRT_PORT:-8890}"
HLS_PORT="${HLS_PORT:-8888}"
WEBRTC_PORT="${WEBRTC_PORT:-8889}"

log "Réinitialisation des règles UFW…"
ufw --force reset >/dev/null

# --- Politique par défaut ---
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null

# --- Tailscale : administration (tout autorisé sur l'interface tailscale0) ---
ufw allow in on tailscale0 comment 'Polaris - admin via Tailscale' >/dev/null

# --- SSH ---
# Conservé en public + limité (anti-bruteforce) pour éviter tout lock-out.
# Une fois Tailscale/SSH validé, vous pouvez durcir : 'ufw delete limit 22/tcp'
ufw limit 22/tcp comment 'SSH (limité)' >/dev/null

# --- Flux vidéo publics ---
ufw allow "${SRTLA_PORT}/udp" comment 'Polaris - SRTLA (IRL Pro)'      >/dev/null
ufw allow "${SRT_PORT}/udp"   comment 'Polaris - SRT (publish/lecture)' >/dev/null

# --- Options (décommenter si diffusion HLS/WebRTC publique souhaitée) ---
# ufw allow "${HLS_PORT}/tcp"     comment 'Polaris - HLS'    >/dev/null
# ufw allow "${WEBRTC_PORT}/tcp"  comment 'Polaris - WebRTC' >/dev/null
# ufw allow "${WEBRTC_PORT}/udp"  comment 'Polaris - WebRTC ICE' >/dev/null

log "Activation d'UFW…"
ufw --force enable >/dev/null

ok "Pare-feu configuré :"
ufw status verbose
