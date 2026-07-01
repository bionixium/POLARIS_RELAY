# Réception dans OBS

OBS **ne se connecte jamais** au relais SRTLA. Il lit uniquement les flux
redistribués par MediaMTX. Avantages : reconnexion automatique, plusieurs
consommateurs simultanés, stabilité, aucun port à ouvrir sur le PC de stream.

## Option A — Source média SRT (recommandé)

1. OBS → **Sources** → **+** → **Source média** (*Media Source*).
2. Décochez **Fichier local**.
3. Dans **Entrée** (*Input*), collez :

```
srt://<IP_PUBLIQUE>:8890?streamid=read:camera1:<READ_USER>:<READ_PASS>&latency=2000
```

Remplacez :
- `<IP_PUBLIQUE>` : IP publique du VPS ;
- `camera1` : nom du flux à recevoir ;
- `<READ_USER>` / `<READ_PASS>` : **clé de lecture** (`.env` →
  `MTX_READ_USER` / `MTX_READ_PASS`).

4. **Format d'entrée** (*Input Format*) : `mpegts`.
5. Cochez **Reconnecter automatiquement** et réglez un délai court (1–2 s).

> Une **Source média** par caméra : dupliquez la source en changeant le nom de
> flux (`camera1`, `camera2`, `interview`…).

### Forme alternative du streamid (syntaxe standard SRT)

```
srt://<IP_PUBLIQUE>:8890?streamid=#!::r=camera1,m=request,u=<READ_USER>,p=<READ_PASS>&latency=2000
```

## Option B — Lecture navigateur (contrôle / preview)

MediaMTX expose aussi (si activé et port ouvert) :

- **HLS**  : `http://<IP_PUBLIQUE>:8888/camera1/` (latence ~2–4 s)
- **WebRTC** : `http://<IP_PUBLIQUE>:8889/camera1/` (faible latence)

Ces ports sont **fermés par défaut** dans le pare-feu. Pour les ouvrir,
décommentez les règles correspondantes dans `firewall.sh` puis relancez-le.

## Latence

- La latence SRT côté OBS **doit être ≥** à celle réglée sur la caméra.
- Réglage terrain typique : caméra `2000 ms`, OBS `2000 ms`.
- Réseau mobile difficile : montez les deux à `3000–4000 ms`.

## Dépannage rapide

| Symptôme                         | Piste                                                |
|----------------------------------|------------------------------------------------------|
| Image noire / pas de flux        | La caméra publie-t-elle ? (voir docs/CAMERAS.md)     |
| « Authentication failed »        | Clé de lecture erronée (`m=request`, pas `m=publish`)|
| Saccades / gel                   | Augmenter la latence SRT (caméra **et** OBS)         |
| Reconnexions fréquentes          | Vérifier la couverture 4G/5G ; débit min trop haut   |
