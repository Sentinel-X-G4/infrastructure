#!/usr/bin/env bash
# Certificats de DEV (CA + serveur, ECDSA P-256). Baptiste les remplacera par les définitifs.
set -euo pipefail
export MSYS_NO_PATHCONV=1          # Git Bash (Windows) : ne pas déformer "/CN=..." ni les chemins
cd "$(dirname "$0")/../mosquitto/certs"
HOSTDIR="$(pwd -W 2>/dev/null || pwd)"

openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -x509 -new -key ca.key -sha256 -days 30 -subj "/CN=Sentinel-X DEV CA" -out ca.crt

openssl ecparam -name prime256v1 -genkey -noout -out mosquitto.key
openssl req -new -key mosquitto.key -subj "/CN=mqtt.sentinel.lan" -out mosquitto.csr
printf "subjectAltName=DNS:mqtt.sentinel.lan,DNS:localhost,IP:192.168.40.1,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n" > san.ext
openssl x509 -req -in mosquitto.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 -sha256 \
  -extfile san.ext -out mosquitto.crt
rm -f mosquitto.csr san.ext

# Sur Linux : clé lisible uniquement par l'utilisateur mosquitto (uid 1883). Sans effet sous Windows.
docker run --rm -v "$HOSTDIR":/c alpine sh -c "chown 1883:1883 /c/mosquitto.key && chmod 600 /c/mosquitto.key" 2>/dev/null || true
echo "OK : certificats de DEV générés (remplacés en prod par ceux de Baptiste)"
