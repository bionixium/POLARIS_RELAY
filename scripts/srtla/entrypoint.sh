#!/bin/sh
# Polaris Relay - Point d'entrée du récepteur SRTLA
# srtla_rec agrège les liens réseau (Wi-Fi + 4G/5G) et reforward le flux SRT
# reconstitué vers MediaMTX (qui joue le rôle de serveur SRT en écoute).
#
# Usage srtla_rec : srtla_rec <port_ecoute> <hote_srt> <port_srt>

set -eu

SRTLA_PORT="${SRTLA_PORT:-5000}"
SRT_HOST="${SRT_HOST:-mediamtx}"
SRT_PORT="${SRT_PORT:-8890}"

echo "[polaris-srtla] Écoute SRTLA sur :${SRTLA_PORT}/udp"
echo "[polaris-srtla] Reforward SRT vers ${SRT_HOST}:${SRT_PORT}"

exec srtla_rec "${SRTLA_PORT}" "${SRT_HOST}" "${SRT_PORT}"
