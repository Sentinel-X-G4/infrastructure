#!/usr/bin/env bash
# Déchiffre secrets/secrets_sentinel.enc (AES-256-CBC + PBKDF2, fourni par Baptiste)
# et range mosquitto.key au bon endroit. La passphrase est demandée (jamais écrite).
set -euo pipefail
cd "$(dirname "$0")/.."
IN=secrets/secrets_sentinel.enc
OUT=secrets/secrets_sentinel.dec
TMP=secrets/extract

openssl enc -d -aes-256-cbc -pbkdf2 -in "$IN" -out "$OUT"
mkdir -p "$TMP"
if tar -tzf "$OUT" >/dev/null 2>&1; then tar -xzf "$OUT" -C "$TMP"
elif tar -tf "$OUT" >/dev/null 2>&1; then tar -xf "$OUT" -C "$TMP"
else echo "Pas une archive tar : contenu brut dans $OUT (à ouvrir avec cat)"; exit 0
fi
echo "Contenu extrait :"; find "$TMP" -type f

KEY=$(find "$TMP" -name 'mosquitto.key' | head -1)
[ -n "$KEY" ] && cp "$KEY" mosquitto/certs/mosquitto.key && echo "-> mosquitto/certs/mosquitto.key"
PW=$(find "$TMP" -name 'password.txt' | head -1)
[ -n "$PW" ] && echo "password.txt trouvé : $PW (voir README, étape mot de passe)"
rm -f "$OUT"
