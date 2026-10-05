# Infra Sentinel-X — stack Docker

Mosquitto (MQTTS 8883 uniquement, auth + ACL) + PostgreSQL/TimescaleDB (réseau interne, non exposé).

## Démarrer (sur n'importe quel PC avec Docker)
```bash
cd infra
cp .env.example .env            # puis changer les mots de passe
./scripts/gen-dev-certs.sh      # CA + cert serveur de DEV (ECDSA P-256)
./scripts/mqtt-users.sh         # comptes esp01 / iot-backend
docker compose up -d
docker compose ps               # postgres doit être "healthy"
```

## Tester MQTT sans l'ESP
Terminal 1 (abonné, joue le backend) :
```bash
docker compose exec mosquitto mosquitto_sub -h localhost -p 8883 --cafile /mosquitto/certs/ca.crt \
  -u iot-backend -P <mdp> -t 'sentinelx/#' -v
```
Terminal 2 (publie, joue l'ESP) :
```bash
docker compose exec mosquitto mosquitto_pub -h localhost -p 8883 --cafile /mosquitto/certs/ca.crt \
  -u esp01 -P <mdp> -t sentinelx/esp01/telemetry -m '{"temp":23.4,"hum":45,"gas":312,"pir":false}'
```

Tests à faire (et à capturer pour le dossier) :
- connexion sans mot de passe → refusée
- port 1883 → fermé (`nc -zv localhost 1883`)
- `esp01` qui publie sur `sentinelx/esp01/cmd` → ignoré (ACL)
- `docker compose exec postgres psql -U sentinel -c '\dt'` → 3 tables

## Sur le PC serveur
Dans `.env` : `BIND_IP=192.168.40.1` → les ports ne sont publiés que sur le Wi-Fi de table
(Docker contourne UFW, d'où ce binding explicite).

## Contrat MQTT
| Topic | Sens | Exemple |
|---|---|---|
| `sentinelx/esp01/telemetry` | ESP → serveur | `{"temp":23.4,"hum":45,"gas":312,"pir":false}` |
| `sentinelx/esp01/alert` | ESP → serveur | `{"type":"pir","value":true}` |
| `sentinelx/esp01/cmd` | serveur → ESP | `{"action":"buzzer","state":"on"}` |
| `sentinelx/esp01/ack` | ESP → serveur | `{"cmd_id":12,"ok":true}` |
