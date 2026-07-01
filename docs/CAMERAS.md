# Configuration des caméras — IRL Pro (Android)

Chaque smartphone Android exécute **IRL Pro** et publie un flux nommé
(`camera1`, `camera2`, `interview`, `backstage`, `drone`…). Le serveur route
automatiquement le flux vers le bon chemin MediaMTX grâce au `streamid`.

## Profil vidéo recommandé

| Paramètre               | Valeur       |
|-------------------------|--------------|
| Codec                   | H.264        |
| Résolution              | 1920 × 1080  |
| Images / s              | 30 fps       |
| Débit max               | 5000 kb/s    |
| Débit min               | 2000 kb/s    |
| Bitrate adaptatif       | Activé       |
| Intervalle images clés  | 2 s          |
| Audio                   | AAC 128 kb/s |
| Bonding                 | Wi-Fi + données mobiles |

## Paramètres SRTLA dans IRL Pro

Dans IRL Pro → **Settings → Streaming** :

- **Protocol / Type** : `SRTLA`
- **SRTLA server / Host** : `<IP_PUBLIQUE_DU_VPS>`
- **SRTLA port** : `5000`
- **Latency** : `2000` ms (2000–4000 en réseau mobile difficile)
- **Stream ID (streamid)** :

```
publish:camera1:<PUBLISH_USER>:<PUBLISH_PASS>
```

Remplacez :
- `camera1` par le nom de la caméra (`camera2`, `interview`, `backstage`, `drone`…) ;
- `<PUBLISH_USER>` / `<PUBLISH_PASS>` par la **clé de publication** (voir `.env`
  → `MTX_PUBLISH_USER` / `MTX_PUBLISH_PASS`, affichée en fin d'installation).

> **Bonding** : activez à la fois le Wi-Fi et les données mobiles dans Android.
> IRL Pro / SRTLA agrège automatiquement les deux liens.

### Forme alternative du streamid (syntaxe standard SRT)

Si le champ n'accepte pas la forme simplifiée, utilisez :

```
#!::r=camera1,m=publish,u=<PUBLISH_USER>,p=<PUBLISH_PASS>
```

## Ajouter une nouvelle caméra

1. Choisir un nom de flux (ex. `camera3`).
2. L'ajouter dans `mediamtx.yml` sous `paths:` :
   ```yaml
   paths:
     camera3:
   ```
   *(ou laisser `all_others:` actif pour accepter tout nom sans édition).*
3. Appliquer : `docker compose up -d mediamtx`
4. Sur le téléphone, régler le `streamid` sur `publish:camera3:...`.

## Correspondance caméras ↔ flux (exemple d'événement)

| Caméra     | Nom de flux | streamid publication                         |
|------------|-------------|----------------------------------------------|
| Caméra 1   | `camera1`   | `publish:camera1:<user>:<pass>`              |
| Caméra 2   | `camera2`   | `publish:camera2:<user>:<pass>`              |
| Interview  | `interview` | `publish:interview:<user>:<pass>`            |
| Backstage  | `backstage` | `publish:backstage:<user>:<pass>`            |
| Drone      | `drone`     | `publish:drone:<user>:<pass>`                |

## Vérifier qu'une caméra publie bien

Depuis le tailnet :

```bash
curl -s http://<TS_IP>:9997/v3/paths/list | jq '.items[] | {name, ready, source}'
```

Un flux actif apparaît avec `"ready": true`.
