# Polaris Relay

Plateforme de contribution vidéo mobile pour **Polaris Experience** — conçue pour
les compétitions EVA, les JAFFA CUP, l'e-sport, les interviews et les captations
extérieures.

Une ou plusieurs caméras Android (**IRL Pro**) transmettent un flux vidéo fiable
en agrégeant Wi-Fi + 4G/5G (**SRTLA**). Le serveur reconstitue le flux et le
redistribue via **MediaMTX**, que **OBS** consomme simplement — sans aucune
ouverture de port sur le PC de stream.

```
 Android (IRL Pro)                 VPS OVH · Debian 12                 PC Stream
 ┌──────────────┐   SRTLA   ┌──────────────────────────────┐   SRT   ┌─────────┐
 │  Wi-Fi + 4G  │ ────────▶ │ srtla_rec → MediaMTX          │ ──────▶ │  OBS    │
 │  bonding     │  udp/5000 │ (SRT / HLS / WebRTC)          │ udp/8890│ Studio  │
 └──────────────┘           │ + Tailscale · Portainer       │         └─────────┘
                            │   Watchtower · Netdata · UFW  │
                            └──────────────────────────────┘
```

## Stack

| Composant     | Rôle                                                        |
|---------------|-------------------------------------------------------------|
| **srtla_rec** | Réception + agrégation SRTLA (BELABOX), conversion vers SRT  |
| **MediaMTX**  | Cœur de distribution : SRT / HLS / WebRTC, auth par clés     |
| **Tailscale** | Administration sécurisée (SSH, Portainer, Netdata) — no ports|
| **UFW**       | Pare-feu : tout fermé sauf les flux vidéo                    |
| **Portainer** | Interface graphique Docker                                  |
| **Watchtower**| Mise à jour automatique des images                          |
| **Netdata**   | Supervision CPU / RAM / réseau / débit                      |

## Installation rapide (VPS Debian 12)

```bash
git clone <votre-repo> polaris-relay && cd polaris-relay
sudo ./install.sh
```

Le script installe Docker + Tailscale, configure le pare-feu, génère les clés de
publication/lecture et démarre tous les services. Voir
[docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md) pour le détail.

## Utilisation

- **Configurer une caméra (IRL Pro)** → [docs/CAMERAS.md](docs/CAMERAS.md)
- **Recevoir dans OBS** → [docs/OBS.md](docs/OBS.md)
- **Maintenance / dépannage** → [docs/MAINTENANCE.md](docs/MAINTENANCE.md)

## Scripts

| Script          | Usage                                                     |
|-----------------|-----------------------------------------------------------|
| `install.sh`    | Installation complète                                     |
| `update.sh`     | Mise à jour manuelle (images + rebuild SRTLA)             |
| `backup.sh`     | Sauvegarde de la configuration (rotation 30 j)            |
| `firewall.sh`   | (Ré)application des règles UFW                            |
| `uninstall.sh`  | Arrêt/suppression (`--purge` pour tout nettoyer)          |
| `scripts/genkeys.sh` | (Re)génération des clés MediaMTX                     |

## Arborescence

```
polaris-relay/
├── install.sh · update.sh · uninstall.sh   # cycle de vie
├── firewall.sh · backup.sh                 # exploitation
├── docker-compose.yml                      # orchestration
├── mediamtx.yml                            # config du cœur de distribution
├── .env.example                            # variables (copié en .env)
├── scripts/
│   ├── lib.sh · genkeys.sh                 # utilitaires
│   └── srtla/                              # image srtla_rec (build)
├── docs/                                   # documentation
├── logs/ · backups/                        # données locales
```

## Sécurité

- Deux clés distinctes : **publication** (caméras) et **lecture** (OBS).
- Interfaces d'administration accessibles **uniquement via Tailscale**.
- Pare-feu fermé par défaut ; seuls SRTLA et SRT sont exposés.
- Aucune ouverture de port côté PC de stream.

## Feuille de route

- **v2** : retour vidéo faible latence, talkback, interface Web Polaris,
  génération automatique des clés, QR Code de connexion, stats par caméra.
- **v3** : multi-VPS, bascule automatique, enregistrement cloud, montage auto.

---
_Polaris Relay — infrastructure de contribution vidéo ouverte, sécurisée et évolutive._
