#!/usr/bin/env bash
# =============================================================================
#  Polaris Relay - Génération des clés (publication / lecture)
#  - Génère les mots de passe s'ils sont absents du .env
#  - Injecte les identifiants dans mediamtx.yml (remplace les placeholders)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

ENV_FILE="${POLARIS_ROOT}/.env"
MTX_FILE="${POLARIS_ROOT}/mediamtx.yml"

[ -f "${ENV_FILE}" ] || die ".env introuvable. Lancez d'abord install.sh."
[ -f "${MTX_FILE}" ] || die "mediamtx.yml introuvable."

load_env

# --- Génère les secrets manquants ---
upsert_env() {
  local key="$1" val="$2"
  if grep -qE "^${key}=" "${ENV_FILE}"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "${ENV_FILE}"
  else
    echo "${key}=${val}" >>"${ENV_FILE}"
  fi
}

MTX_PUBLISH_USER="${MTX_PUBLISH_USER:-polaris}"
MTX_READ_USER="${MTX_READ_USER:-obs}"

if [ -z "${MTX_PUBLISH_PASS:-}" ]; then
  MTX_PUBLISH_PASS="$(gen_secret 28)"
  ok "Clé de publication générée."
fi
if [ -z "${MTX_READ_PASS:-}" ]; then
  MTX_READ_PASS="$(gen_secret 28)"
  ok "Clé de lecture générée."
fi

upsert_env MTX_PUBLISH_USER "${MTX_PUBLISH_USER}"
upsert_env MTX_PUBLISH_PASS "${MTX_PUBLISH_PASS}"
upsert_env MTX_READ_USER   "${MTX_READ_USER}"
upsert_env MTX_READ_PASS   "${MTX_READ_PASS}"

# --- Injecte dans mediamtx.yml (remplace placeholders OU valeurs déjà posées) ---
# On repart toujours des placeholders : si le fichier a déjà été rempli, on ne
# retouche pas (idempotent). On ne remplace que si les placeholders existent.
if grep -q '__PUBLISH_USER__' "${MTX_FILE}"; then
  sed -i \
    -e "s|__PUBLISH_USER__|${MTX_PUBLISH_USER}|g" \
    -e "s|__PUBLISH_PASS__|${MTX_PUBLISH_PASS}|g" \
    -e "s|__READ_USER__|${MTX_READ_USER}|g" \
    -e "s|__READ_PASS__|${MTX_READ_PASS}|g" \
    "${MTX_FILE}"
  ok "Identifiants injectés dans mediamtx.yml"
else
  warn "mediamtx.yml semble déjà configuré (placeholders absents) — inchangé."
  warn "Pour régénérer : restaurez les placeholders ou éditez mediamtx.yml à la main."
fi

echo
log "Récapitulatif des clés (à conserver précieusement) :"
echo "  Publication : user=${MTX_PUBLISH_USER}  pass=${MTX_PUBLISH_PASS}"
echo "  Lecture     : user=${MTX_READ_USER}  pass=${MTX_READ_PASS}"
