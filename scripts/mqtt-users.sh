#!/usr/bin/env bash
# Génère mosquitto/config/password.txt (mots de passe hashés) à partir du .env
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
set -a; source <(tr -d '\r' < .env); set +a
CONF="$(cd mosquitto/config && (pwd -W 2>/dev/null || pwd))"
rm -f mosquitto/config/password.txt
docker run --rm -v "$CONF":/c eclipse-mosquitto:2 sh -c "
  touch /c/password.txt &&
  mosquitto_passwd -b /c/password.txt sentinel_iot '$MQTT_ESP_PASSWORD' &&
  mosquitto_passwd -b /c/password.txt iot-backend '$MQTT_BACKEND_PASSWORD' &&
  mosquitto_passwd -b /c/password.txt vision '$MQTT_VISION_PASSWORD' &&
  mosquitto_passwd -b /c/password.txt detection '$MQTT_DETECTION_PASSWORD' &&
  if [ -n '${MQTT_SIMULATOR_PASSWORD:-}' ]; then mosquitto_passwd -b /c/password.txt simulator '${MQTT_SIMULATOR_PASSWORD:-}'; fi &&
  (chown 1883:1883 /c/password.txt && chmod 600 /c/password.txt || true)"
echo "OK : comptes MQTT sentinel_iot, iot-backend, vision, detection${MQTT_SIMULATOR_PASSWORD:+, simulator} créés"
