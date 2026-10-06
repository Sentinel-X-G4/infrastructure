# Infra Sentinel-X — configuration durcie

Ce dépôt ne contient que la **configuration** (Nginx, Mosquitto, ACL, scripts, emplacement
des certificats). Les conteneurs sont déclarés dans le **seul** `docker-compose.yml` du dépôt
[`main`](https://github.com/Sentinel-X-G4/main), qui monte ces fichiers. La base de données
est le dépôt [`backend_db`](https://github.com/Sentinel-X-G4/backend_db).

| Service (compose de `main`) | Rôle | Exposé |
|---|---|---|
| `sentinel-reverse-proxy` | Nginx, HTTPS forcé, rate limiting, version masquée | `443` (+`80` → redirection) |
| `sentinel-mosquitto` | Broker MQTT, TLS obligatoire, auth + ACL | `8883` |

Réseaux : `sentinel-front` (proxy ↔ appli), `sentinel-back` (backend ↔ MQTT), `sentinel-data` (backend ↔ base, `internal`).
Les ports ne sont publiés que sur `BIND_IP` (`192.168.40.1` sur le serveur) : Docker contourne UFW.

## Arborescence
```
infra/
├── .env                    # lien vers le .env de main (make init), non commité
├── nginx/
│   ├── nginx.conf
│   └── certs/              # proxy.crt, proxy.key, dhparam.pem   (Baptiste, non commités)
├── mosquitto/
│   ├── config/             # mosquitto.conf, acl, password.txt (généré, non commité)
│   └── certs/              # ca.crt, mosquitto.crt, mosquitto.key (Baptiste, non commités)
├── secrets/                # secrets_sentinel.enc (non commité)
└── scripts/
```

## Installation (depuis `main/`)
```bash
make init        # .env de main, relié ici en infra/.env
make certs       # PKI de Baptiste (main/secrets/ → make pki), sinon certificats de DEV
make users       # comptes MQTT hashés (scripts/mqtt-users.sh)
make up
```
Sans `main/secrets/`, la clé privée Mosquitto peut aussi venir de l'archive chiffrée de
Baptiste : `cp secrets_sentinel.enc secrets/ && ./scripts/decrypt-secrets.sh`.

## Tests (captures pour le dossier)
```bash
# depuis main/
export MSYS_NO_PATHCONV=1; source <(tr -d '\r' < .env)
# abonné (fenêtre 1)
docker compose exec sentinel-mosquitto mosquitto_sub -h localhost -p 8883 --cafile /mosquitto/certs/ca.crt \
  -u iot-backend -P "$MQTT_BACKEND_PASSWORD" -t 'sentinelx/#' -v
# ESP simulé (fenêtre 2)
docker compose exec sentinel-mosquitto mosquitto_pub -h localhost -p 8883 --cafile /mosquitto/certs/ca.crt \
  -u sentinel_iot -P "$MQTT_ESP_PASSWORD" -t sentinelx/esp01/telemetry -m '{"temp":23.4,"gas":312}'
# proxy
curl -k -I https://localhost        # en-têtes de sécurité, pas de version nginx
```

## Contrat MQTT
| Topic | Sens | Compte | Exemple |
|---|---|---|---|
| `sentinelx/esp01/telemetry` | ESP → serveur (~5 msg/s) | `sentinel_iot` | `{"temp":23.4,"hum":45,"pir":0,"gas_raw":312,"gas_do":1}` |
| `sentinelx/esp01/alert` | ESP → serveur | `sentinel_iot` | `{"type":"pir","value":true}` |
| `sentinelx/esp01/cmd` | serveur → ESP | `iot-backend` | `{"action":"buzzer","state":"on"}` |
| `sentinelx/esp01/ack` | ESP → serveur | `sentinel_iot` | `{"cmd_id":12,"ok":true}` |
| `sentinelx/esp01/camera` | IA vision → serveur (~1 msg/s) | `vision` | `{"person":true}` |
| `sentinelx/esp01/detection` | détection → backend | `detection` | statut `feu`/`fuite_gaz`/`presence`/`aucune` + alertes + métriques |

Détail des champs `telemetry`, `camera` et `detection` : `backend-iot-alerts/detection-service/docs/`
(`MQTT_CONTRACT.md` et `BACKEND_CONTRACT.md`). `pir` et `gas_raw` (ADC brut 0–1023, `gas` accepté)
sont obligatoires dans `telemetry`.
