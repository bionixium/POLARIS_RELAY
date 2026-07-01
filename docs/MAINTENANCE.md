# Maintenance & exploitation

## Commandes utiles

```bash
cd polaris-relay

docker compose ps                 # état des services
docker compose logs -f srtla      # logs du récepteur SRTLA
docker compose logs -f mediamtx   # logs de la distribution
docker compose restart mediamtx   # redémarrer un service
docker compose up -d              # appliquer une modif de config
```

## Journaux

Les conteneurs utilisent le driver `json-file` (rotation 10 Mo × 5). Pour un
suivi terrain, ils permettent d'identifier : pertes de connexion, pertes de
paquets, reconnexions, débit moyen.

```bash
# Dernières reconnexions / erreurs SRTLA
docker compose logs --since 1h srtla | grep -iE 'connect|drop|nak|reconnect'
```

Netdata (`http://<TS_IP>:19999`) fournit CPU, RAM, réseau, débit et charge en
temps réel.

## Sauvegardes

```bash
sudo ./backup.sh                  # sauvegarde manuelle (rotation 30 j)
ls -lt backups/                   # archives disponibles
```

Contenu sauvegardé : `docker-compose.yml`, `mediamtx.yml`, `.env` (clés),
`firewall.sh`, `scripts/`, `docs/`.

### Restauration

```bash
tar -xzf backups/polaris-YYYYMMDD-HHMMSS.tar.gz -C polaris-relay/
sudo ./install.sh                 # ou : docker compose up -d
```

## Mise à jour

- **Automatique** : Watchtower vérifie et applique les nouvelles images chaque
  nuit (04h00, réglable via `WATCHTOWER_SCHEDULE` dans `.env`).
- **Manuelle** : `sudo ./update.sh` (sauvegarde + pull + rebuild + restart).

## Rotation / régénération des clés

```bash
# Éditer .env pour vider MTX_PUBLISH_PASS / MTX_READ_PASS, restaurer les
# placeholders dans mediamtx.yml, puis :
sudo bash scripts/genkeys.sh
docker compose up -d mediamtx
```

Pensez à redistribuer les nouvelles clés aux caméras (IRL Pro) et à OBS.

## Pare-feu

```bash
sudo ufw status verbose           # règles actives
sudo ./firewall.sh                # réappliquer la politique
sudo ufw delete limit 22/tcp      # fermer le SSH public (accès via Tailscale)
```

## Dépannage

| Problème                                   | Action                                                        |
|--------------------------------------------|---------------------------------------------------------------|
| `srtla` redémarre en boucle                | Vérifier que `mediamtx` est up ; `docker compose logs srtla`  |
| Caméra ne publie pas                       | streamid `m=publish` + bonne clé ; port 5000/udp ouvert       |
| OBS ne lit pas                             | streamid `m=request` + clé de lecture ; port 8890/udp ouvert  |
| Admin injoignable                          | `tailscale status` ; vérifier `TS_IP` dans `.env`             |
| `TS_IP` vide après install                 | `sudo tailscale up --ssh` puis relancer `sudo ./install.sh`   |
| Image SRTLA ne compile pas                 | `docker compose build --no-cache srtla`                       |

## Santé via l'API MediaMTX (tailnet)

```bash
curl -s http://<TS_IP>:9997/v3/paths/list | jq
curl -s http://<TS_IP>:9997/v3/srtconns/list | jq
```
