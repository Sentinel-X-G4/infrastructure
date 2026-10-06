# Infra Sentinel-X — stack Docker

| Service | Rôle | Exposé |
|---|---|---|
| `sentinel-reverse-proxy` | Nginx, HTTPS forcé, rate limiting, version masquée | `443` (+`80` → redirection) |
| `sentinel-mosquitto` | Broker MQTT, TLS obligatoire, auth + ACL | `8883` |
| `sentinel-db` | PostgreSQL/TimescaleDB | non (réseau interne) |
| `sentinel-backend` / `sentinel-frontend` | DEV (à décommenter) | via le proxy uniquement |

Réseaux : `sentinel-front` (proxy ↔ appli), `sentinel-back` (backend ↔ MQTT), `sentinel-data` (backend ↔ base, `internal`).
Les ports ne sont publiés que sur `BIND_IP` (`192.168.40.1` sur le serveur) : Docker contourne UFW.

## Arborescence
```
infra/
├── docker-compose.yml
├── .env                    # secrets locaux (non commité) ← .env.example
├── nginx/
│   ├── nginx.conf
│   └── certs/              # proxy.crt, proxy.key, dhparam.pem   (Baptiste, non commités)
├── mosquitto/
│   ├── config/             # mosquitto.conf, acl, password.txt (généré, non commité)
│   └── certs/              # ca.crt, mosquitto.crt, mosquitto.key (Baptiste, non commités)
├── postgres/init/          # schéma SQL
├── secrets/                # secrets_sentinel.enc (non commité)
└── scripts/
```

## Installation
```bash
cd infra
cp .env.example .env                       # remplir les mots de passe
# 1. Certificats publics de Baptiste
cp ca.crt mosquitto.crt  mosquitto/certs/
cp proxy.crt proxy.key dhparam.pem nginx/certs/
# 2. Clé privée Mosquitto (passphrase demandée à Baptiste, de vive voix)
cp secrets_sentinel.enc secrets/
./scripts/decrypt-secrets.sh
# 3. Comptes MQTT hashés (sentinel_iot = ESP, iot-backend = backend)
./scripts/mqtt-users.sh
# 4. Lancement
docker compose up -d && docker compose ps
```

## Tests (captures pour le dossier)
```bash
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
| Topic | Sens | Exemple |
|---|---|---|
| `sentinelx/esp01/telemetry` | ESP → serveur | `{"temp":23.4,"hum":45,"gas":312,"pir":false}` |
| `sentinelx/esp01/alert` | ESP → serveur | `{"type":"pir","value":true}` |
| `sentinelx/esp01/cmd` | serveur → ESP | `{"action":"buzzer","state":"on"}` |
| `sentinelx/esp01/ack` | ESP → serveur | `{"cmd_id":12,"ok":true}` |
