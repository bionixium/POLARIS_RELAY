#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Installation (Debian 12)
#  Installe Docker, Tailscale, configure le pare-feu, génère les clés et
#  démarre l'ensemble des services.
#
#  Usage :  sudo ./install.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
. "${SCRIPT_DIR}/scripts/lib.sh"

require_root

banner() {
  echo -e "${C_BLUE}"
  echo "  ____       _            _        ____      _             "
  echo " |  _ \\ ___ | | __ _ _ __(_)___   |  _ \\ ___| | __ _ _   _ "
  echo " | |_) / _ \\| |/ _\` | '__| / __|  | |_) / _ \\ |/ _\` | | | |"
  echo " |  __/ (_) | | (_| | |  | \\__ \\  |  _ <  __/ | (_| | |_| |"
  echo " |_|   \\___/|_|\\__,_|_|  |_|___/  |_| \\_\\___|_|\\__,_|\\__, |"
  echo "                                                     |___/ "
  echo -e "  Contribution vidéo mobile · SRTLA → MediaMTX → OBS${C_RESET}"
  echo
}

banner

# -----------------------------------------------------------------------------
# 1. Prérequis système
# -----------------------------------------------------------------------------
log "Mise à jour des paquets et prérequis…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release ufw jq >/dev/null
ok "Prérequis installés."

# -----------------------------------------------------------------------------
# 2. Docker + Compose
# -----------------------------------------------------------------------------
if need_cmd docker; then
  ok "Docker déjà présent ($(docker --version))."
else
  log "Installation de Docker…"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin >/dev/null
  systemctl enable --now docker >/dev/null 2>&1 || true
  ok "Docker installé ($(docker --version))."
fi

# -----------------------------------------------------------------------------
# 3. Tailscale (administration sécurisée)
# -----------------------------------------------------------------------------
if need_cmd tailscale; then
  ok "Tailscale déjà présent."
else
  log "Installation de Tailscale…"
  curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1
  ok "Tailscale installé."
fi

log "Activation de Tailscale (authentifiez-vous via l'URL affichée si demandé)…"
tailscale up --ssh || warn "tailscale up n'a pas abouti — relancez 'sudo tailscale up --ssh' plus tard."

TS_IP="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
if [ -n "${TS_IP}" ]; then
  ok "IP Tailscale détectée : ${TS_IP}"
else
  warn "IP Tailscale non détectée. Les interfaces admin retomberont sur 127.0.0.1."
  warn "Relancez ce script (ou éditez TS_IP dans .env) une fois Tailscale connecté."
fi

# -----------------------------------------------------------------------------
# 4. Fichier .env
# -----------------------------------------------------------------------------
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
  ok "Fichier .env créé depuis le modèle."
else
  ok "Fichier .env existant conservé."
fi

# Injecte / met à jour l'IP Tailscale
if [ -n "${TS_IP}" ]; then
  if grep -qE '^TS_IP=' "${SCRIPT_DIR}/.env"; then
    sed -i "s|^TS_IP=.*|TS_IP=${TS_IP}|" "${SCRIPT_DIR}/.env"
  else
    echo "TS_IP=${TS_IP}" >>"${SCRIPT_DIR}/.env"
  fi
fi

# -----------------------------------------------------------------------------
# 5. Clés (publication / lecture) + injection dans mediamtx.yml
# -----------------------------------------------------------------------------
log "Génération des clés MediaMTX…"
bash "${SCRIPT_DIR}/scripts/genkeys.sh"

# -----------------------------------------------------------------------------
# 6. Pare-feu UFW
# -----------------------------------------------------------------------------
log "Configuration du pare-feu…"
bash "${SCRIPT_DIR}/firewall.sh" || warn "Configuration UFW incomplète — vérifiez firewall.sh."

# -----------------------------------------------------------------------------
# 7. Build & démarrage
# -----------------------------------------------------------------------------
log "Construction de l'image SRTLA et démarrage des services…"
cd "${SCRIPT_DIR}"
compose build
compose up -d

echo
ok "Installation terminée."
echo
load_env
cat <<INFO
${C_GREEN}=== Polaris Relay est opérationnel ===${C_RESET}

  Entrée caméras (IRL Pro)  : SRTLA  udp/${SRTLA_PORT:-5000}
  Flux SRT (publish/lecture): SRT    udp/${SRT_PORT:-8890}

  Publication (streamid IRL Pro) :
    publish:camera1:${MTX_PUBLISH_USER:-polaris}:${MTX_PUBLISH_PASS:-<voir .env>}

  Lecture OBS (source média SRT) :
    srt://<IP_PUBLIQUE>:${SRT_PORT:-8890}?streamid=read:camera1:${MTX_READ_USER:-obs}:${MTX_READ_PASS:-<voir .env>}

  Admin (via Tailscale uniquement) :
    Portainer : https://${TS_IP:-127.0.0.1}:9443
    Netdata   : http://${TS_IP:-127.0.0.1}:19999
    API MTX   : http://${TS_IP:-127.0.0.1}:9997

  Détails caméras/OBS : voir docs/CAMERAS.md et docs/OBS.md
INFO
