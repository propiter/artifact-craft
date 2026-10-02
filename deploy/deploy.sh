#!/usr/bin/env bash
# Ayudas para desplegar. Uso:  bash deploy/deploy.sh [files|build|push|all]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"

[ -f "$HERE/deploy.env" ] || { echo "falta deploy/deploy.env (copialo de deploy.env.example)"; exit 1; }
# shellcheck disable=SC1091
. "$HERE/deploy.env"
: "${APP:?falta APP}"; : "${IMAGE:?falta IMAGE}"; : "${SERVER:?falta SERVER en deploy.env}"

FILES_DIR="$HERE/files"
REMOTE="/etc/dokploy/compose/$APP/files"

prep() {
  mkdir -p "$FILES_DIR/store" "$FILES_DIR/www"
  cp "$ROOT/store/default.conf" "$FILES_DIR/store/default.conf"
  cp "$ROOT/store/www/"*        "$FILES_DIR/www/"
}

build() { docker build --platform linux/amd64 -t "$IMAGE" "$ROOT/api"; }

push()  { docker push "$IMAGE"; }

# ESTE es el paso que se olvida: la fila del mount NO escribe el archivo. Si no lo subis,
# Docker crea un directorio con ese nombre y el contenedor muere con ExitCode 127.
files() {
  prep
  ssh "$SERVER" "mkdir -p $REMOTE/store $REMOTE/www"
  for f in store/default.conf www/index.html www/50x.html; do
    ssh "$SERVER" "cat > $REMOTE/$f" < "$FILES_DIR/$f"
    echo "subido: $f"
  done
  echo "--- verificacion (los hashes tienen que coincidir) ---"
  for f in store/default.conf www/index.html www/50x.html; do
    r="$(ssh "$SERVER" sha256sum "$REMOTE/$f" | cut -d" " -f1)"
    l="$(sha256sum "$FILES_DIR/$f" | cut -d" " -f1)"
    if [ "$r" = "$l" ]; then echo "  OK    $f"; else echo "  DIFIERE $f"; exit 1; fi
  done
}

case "${1:-all}" in
  files) files ;;
  build) build ;;
  push)  push ;;
  prep)  prep; echo "listo en $FILES_DIR" ;;
  all)   prep; files ;;
  *) echo "uso: bash deploy/deploy.sh [files|build|push|prep|all]"; exit 1 ;;
esac
