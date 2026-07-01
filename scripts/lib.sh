#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Fonctions communes aux scripts (à sourcer)
# =============================================================================

set -euo pipefail

# Racine du projet (dossier parent de scripts/)
POLARIS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Couleurs ---
if [ -t 1 ]; then
  C_RESET='\033[0m'; C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'
  C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'
else
  C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''
fi

log()   { echo -e "${C_BLUE}[polaris]${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}[polaris] ✓${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}[polaris] !${C_RESET} $*"; }
err()   { echo -e "${C_RED}[polaris] ✗${C_RESET} $*" >&2; }
die()   { err "$*"; exit 1; }

require_root() {
  [ "$(id -u)" -eq 0 ] || die "Ce script doit être lancé en root (sudo)."
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Sélectionne "docker compose" (v2) ou "docker-compose" (v1)
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif need_cmd docker-compose; then
    docker-compose "$@"
  else
    die "Docker Compose introuvable."
  fi
}

# Génère un secret alphanumérique (longueur par défaut 24)
gen_secret() {
  local len="${1:-24}"
  LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$len"
}

# Charge le .env s'il existe.
# set -f désactive le globbing (évite l'expansion de '*' dans une valeur non
# quotée type cron) ; set -a exporte les variables lues.
load_env() {
  if [ -f "${POLARIS_ROOT}/.env" ]; then
    set -a -f
    # shellcheck disable=SC1091
    . "${POLARIS_ROOT}/.env"
    set +a +f
  fi
}
