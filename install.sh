#!/usr/bin/env bash
# artifact-craft — instalador del skill y del cliente.
#
#   curl -fsSL https://raw.githubusercontent.com/propiter/artifact-craft/main/install.sh | bash
#
# Hace tres cosas: instala el skill en tu Hermes, deja el cliente en tu PATH y guarda
# la URL del hub + tu token en ~/.config/wl-artifact/config (chmod 600).
# Es idempotente: correrlo de nuevo actualiza.
set -euo pipefail

REPO="${ARTIFACT_CRAFT_REPO:-propiter/artifact-craft}"
BRANCH="${ARTIFACT_CRAFT_BRANCH:-main}"
TARBALL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

HERMES_DIR="${HERMES_HOME:-$HOME/.hermes}"
SKILL_DST="$HERMES_DIR/skills/creative/artifact-craft"
BIN="${HOME}/.local/bin"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/wl-artifact/config"

say() { printf '%s\n' "$*"; }
die() { printf '\nerror: %s\n' "$*" >&2; exit 1; }

say ""
say "  artifact-craft — artifacts publicados y compartibles"
say "  ---------------------------------------------------"

command -v curl    >/dev/null 2>&1 || die "hace falta curl"
command -v tar     >/dev/null 2>&1 || die "hace falta tar"
command -v python3 >/dev/null 2>&1 || die "hace falta python3 (Hermes ya lo requiere)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "· bajando el skill desde github.com/${REPO}"
curl -fsSL "$TARBALL" | tar -xz -C "$tmp" || die "no pude bajar el repo"

# El layout puede cambiar: busco el SKILL.md donde sea que este dentro del paquete,
# en vez de asumir una profundidad (asumirla fue justo lo que rompio esto).
skill_md="$(find "$tmp" -maxdepth 5 -type f -name 'SKILL.md' 2>/dev/null | head -1)"
[ -n "$skill_md" ] || die "no encontre el SKILL.md dentro del paquete"
skill_src="$(dirname "$skill_md")"

# Instalar el skill. Si ya habia uno, se guarda una copia: nunca se borra a ciegas.
mkdir -p "$(dirname "$SKILL_DST")"
if [ -d "$SKILL_DST" ]; then
  backup="${SKILL_DST}.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$SKILL_DST" "$backup"
  say "· habia un skill instalado: copia guardada en $backup"
fi
cp -r "$skill_src" "$SKILL_DST"
say "· skill instalado en $SKILL_DST"

# El cliente y sus dos archivos van juntos: el script los busca a su lado.
mkdir -p "$BIN"
cp "$SKILL_DST/scripts/wl-artifact"        "$BIN/wl-artifact"
cp "$SKILL_DST/scripts/build-catalog.py"   "$BIN/build-catalog.py"
cp "$SKILL_DST/templates/catalog-template.html" "$BIN/catalog-template.html"
chmod +x "$BIN/wl-artifact"
say "· cliente instalado en $BIN/wl-artifact"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    say ""
    say "  AVISO: $BIN no esta en tu PATH. Agregalo a tu shell:"
    say "     echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && exec bash"
    ;;
esac

say ""
if [ -f "$CFG" ]; then
  say "· ya tenias configuracion en $CFG — la dejo como esta"
  say "  (para cambiarla: wl-artifact setup <token>)"
else
  printf 'URL del hub (ej. https://artifacts.ejemplo.com): '
  read -r hub_api
  [ -n "$hub_api" ] || die "sin URL del hub no puedo configurar el cliente"
  printf 'tu token (no se muestra al escribir): '
  read -rs hub_token
  printf '\n'
  case "$hub_token" in
    wlart_*) ;;
    *) die "el token deberia empezar con wlart_ — pedilo a quien administra el hub" ;;
  esac
  "$BIN/wl-artifact" setup "$hub_token" "$hub_api" >/dev/null
  say "· token guardado en $CFG (chmod 600)"
fi

say ""
say "  Listo. En tu Hermes pedile un artifact y te va a dar el link."
say ""
say "     wl-artifact publish <archivo.html> [slug]   una pagina"
say "     wl-artifact deploy  <carpeta> [slug]        una app (html+js+css+imagenes)"
say "     wl-artifact ls / catalog / whoami / rm"
say ""

if [ -x "$BIN/wl-artifact" ]; then
  say "  Probando tu token..."
  "$BIN/wl-artifact" whoami 2>&1 | sed 's/^/     /' || true
  say ""
fi
