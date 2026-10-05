#!/usr/bin/env bash
# Génère le fichier de mots de passe Mosquitto (hashé) à partir du .env
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
set -a; source <(tr -d '\r' < .env); set +a
CONF="$(cd mosquitto/config && (pwd -W 2>/dev/null || pwd))"
rm -f mosquitto/config/passwd
docker run --rm -v "$CONF":/c eclipse-mosquitto:2 sh -c "
  touch /c/passwd &&
  mosquitto_passwd -b /c/passwd esp01 '$MQTT_ESP01_PASSWORD' &&
  mosquitto_passwd -b /c/passwd iot-backend '$MQTT_BACKEND_PASSWORD' &&
  (chown 1883:1883 /c/passwd && chmod 600 /c/passwd || true)"
echo "OK : comptes MQTT esp01 et iot-backend créés"
