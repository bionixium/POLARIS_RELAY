# Déploiement — VPS OVH Debian 12

## 1. Commander le VPS

- OVH VPS (ou équivalent), **Debian 12**, 2 vCPU / 4 Go RAM minimum.
- Noter l'**IP publique** (utilisée par les caméras et OBS).

## 2. Première connexion

```bash
ssh debian@<IP_PUBLIQUE>      # ou root selon l'offre
sudo apt update && sudo apt -y upgrade
```

## 3. Récupérer Polaris Relay

```bash
git clone <votre-repo> polaris-relay
cd polaris-relay
```

## 4. Lancer l'installation

```bash
sudo ./install.sh
```

Pendant l'exécution :

1. **Docker** et **Tailscale** sont installés.
2. `tailscale up --ssh` affiche une **URL d'authentification** → ouvrez-la dans
   votre navigateur et connectez votre compte Tailscale. L'IP `100.x.y.z` est
   ensuite détectée automatiquement et écrite dans `.env` (`TS_IP`).
3. Les **clés** de publication/lecture sont générées et injectées dans
   `mediamtx.yml`. Elles s'affichent en fin d'installation — **conservez-les**.
4. Le **pare-feu** est appliqué (`firewall.sh`).
5. L'image **srtla_rec** est compilée puis tous les services démarrent.

> Si l'authentification Tailscale n'a pas abouti, relancez
> `sudo tailscale up --ssh` puis `sudo ./install.sh` (idempotent) pour renseigner
> `TS_IP`.

## 5. Vérifier

```bash
docker compose ps            # tous les services "running"
docker compose logs -f srtla mediamtx
```

Depuis une machine du **tailnet** :

- Portainer : `https://<TS_IP>:9443`
- Netdata   : `http://<TS_IP>:19999`

## 6. Ports exposés

| Port        | Proto | Accès      | Usage                                  |
|-------------|-------|------------|----------------------------------------|
| 5000        | UDP   | Public     | SRTLA (caméras IRL Pro)                |
| 8890        | UDP   | Public     | SRT (publication directe + lecture OBS)|
| 8888 / 8889 | TCP   | Option     | HLS / WebRTC (fermés par défaut)       |
| 22          | TCP   | Public*    | SSH (limité, à durcir via Tailscale)   |
| 9443/19999/9997 | TCP | Tailscale | Portainer / Netdata / API MediaMTX     |

\* Une fois Tailscale SSH validé, vous pouvez fermer le SSH public :
`sudo ufw delete limit 22/tcp` (l'accès reste possible via `tailscale ssh`).

## 7. Sauvegarde automatique (recommandé)

Ajouter un cron quotidien :

```bash
sudo crontab -e
# Sauvegarde chaque jour à 03h30
30 3 * * * /chemin/vers/polaris-relay/backup.sh >> /chemin/vers/polaris-relay/logs/backup.log 2>&1
```

## 8. Mise à jour

Automatique via **Watchtower** (04h00). Manuellement :

```bash
sudo ./update.sh
```
