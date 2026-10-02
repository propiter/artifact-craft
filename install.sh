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

# Opciones. Existen ademas de las variables de entorno porque `--name juan` se lee, y
# `HUB_NAME=juan` hay que saberlo: la primera forma te dice QUE es cada cosa.
while [ $# -gt 0 ]; do
  case "$1" in
    --api)           HUB_API="${2:-}";  [ -n "$HUB_API" ]  || die "--api necesita la URL del hub"; shift 2 ;;
    --code)          HUB_CODE="${2:-}"; [ -n "$HUB_CODE" ] || die "--code necesita el codigo de equipo"; shift 2 ;;
    --name|--nombre) HUB_NAME="${2:-}"; [ -n "$HUB_NAME" ] || die "--name necesita tu nombre"; shift 2 ;;
    -h|--help)       say "uso: install.sh [--api URL] [--code CODIGO] [--name TU-NOMBRE]"; exit 0 ;;
    *)               die "opcion desconocida: $1   (las que hay: --api, --code, --name)" ;;
  esac
done
export HUB_API="${HUB_API:-}" HUB_CODE="${HUB_CODE:-}" HUB_NAME="${HUB_NAME:-}"

# Sin terminal no hay quien conteste las preguntas. Si tampoco hay variables ni configuracion
# previa, se frena ACA: antes se instalaba el skill y el cliente, y despues moria sin cuenta.
if [ ! -t 0 ] && [ ! -f "$CFG" ] && [ -z "${HUB_API:-}" ]; then
  die "correr asi no funciona: no puedo preguntar sin terminal.
  Correlo en UN comando, diciendome las tres cosas:
    bash install.sh --api https://artifacts.lab.whitelabel.lat --code EL-CODIGO --name tu-nombre
  (o solo para actualizar el skill, si ya tenias cuenta: bash install.sh)"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "· bajando el skill desde github.com/${REPO}"
curl -fsSL "$TARBALL" | tar -xz -C "$tmp" || die "no pude bajar el repo"

# El layout puede cambiar: busco el SKILL.md donde sea que este dentro del paquete,
# en vez de asumir una profundidad (asumirla fue justo lo que rompio esto).
skill_md="$(find "$tmp" -maxdepth 5 -type f -name 'SKILL.md' 2>/dev/null | head -1)"
[ -n "$skill_md" ] || die "no encontre el SKILL.md dentro del paquete"
skill_src="$(dirname "$skill_md")"

BACKUPS="$HERMES_DIR/skill-backups"
mkdir -p "$BACKUPS"

# Instalar el skill. Si ya habia uno, se guarda una copia: nunca se borra a ciegas.
# El respaldo va FUERA del arbol de skills a proposito: adentro quedaba un segundo SKILL.md
# declarando el mismo `name:`, y el cargador de skills se niega a cargar un nombre ambiguo.
mkdir -p "$(dirname "$SKILL_DST")"
if [ -d "$SKILL_DST" ]; then
  backup="$BACKUPS/artifact-craft-$(date +%Y%m%d-%H%M%S)"
  mv "$SKILL_DST" "$backup"
  say "· habia un skill instalado: copia guardada en $backup"
fi
cp -r "$skill_src" "$SKILL_DST"
say "· skill instalado en $SKILL_DST"

# Otros agentes (OpenCode, Claude Code, Cursor) leen skills del MISMO formato desde su propia
# carpeta. Quien instala no tiene por que saber cual usa: si la carpeta existe, va tambien ahi.
for d in "$HOME/.config/opencode/skills" "$HOME/.claude/skills" "$HOME/.cursor/skills"; do
  [ -d "$d" ] || continue
  [ -d "$d/artifact-craft" ] && mv "$d/artifact-craft" \
    "$BACKUPS/artifact-craft-$(printf '%s' "$d" | tr '/' '_')-$(date +%Y%m%d-%H%M%S)"
  cp -r "$skill_src" "$d/artifact-craft"
  say "· skill tambien en $d/artifact-craft"
done

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
  # Las tres respuestas pueden venir por variables de entorno. Es la unica forma de que un AGENTE
  # (OpenCode, Claude Code, Hermes, el que sea) complete esto en UN comando: si corre el instalador
  # solo, no hay quien conteste las preguntas, y antes eso terminaba con el skill y el cliente
  # instalados pero SIN cuenta -- a medias y en silencio.
  hub_api="${HUB_API:-}"
  if [ -z "$hub_api" ]; then
    [ -t 0 ] || die "esto no puede preguntar sin terminal. Correlo asi, en un solo comando:
      HUB_API=<url-del-hub> HUB_CODE=<codigo-de-equipo> HUB_NAME=<tu-nombre> bash install.sh"
    printf 'URL del hub (ej. https://artifacts.ejemplo.com): '
    read -r hub_api
  fi
  [ -n "$hub_api" ] || die "sin URL del hub no puedo configurar el cliente"

  if [ -z "${HUB_CODE:-}" ] && [ -t 0 ]; then
    say ""
    say "  ¿Tenés un CODIGO DE EQUIPO? Es lo más fácil: crea tu cuenta, guarda tu token"
    say "  en esta máquina y te deja la galería abierta. No copiás ningún token a mano."
    printf 'Código de equipo (pegalo, o Enter si preferís usar un token): '
    read -r hub_code
  fi
  hub_code="${HUB_CODE:-}"
  if [ -n "$hub_code" ]; then
    say ""
    # El nombre con el que va a aparecer en el hub: si no, quedaria el usuario del sistema
    hub_name="${HUB_NAME:-}"
    if [ -z "$hub_name" ] && [ -t 0 ]; then
      printf '¿Con qué nombre querés aparecer? (ej. juan, en minúsculas): '
      read -r hub_name
    fi
    [ -n "$hub_name" ] || die "sin nombre no puedo crear tu espacio: pasalo en HUB_NAME=<nombre>"
    "$BIN/wl-artifact" join "$hub_code" --name "$hub_name" --api "$hub_api" || die "no pude crear la cuenta"
  else
    [ -t 0 ] || die "sin terminal necesito HUB_API y HUB_CODE (o configurar con: wl-artifact setup <token> <url>)"
    printf 'tu token (no se muestra al escribir): '
    read -rs hub_token
    printf '\n'
    case "$hub_token" in
      wlart_*) ;;
      *) die "el token debería empezar con wlart_ — pedilo a quien administra el hub" ;;
    esac
    "$BIN/wl-artifact" setup "$hub_token" "$hub_api" >/dev/null
    say "· token guardado en $CFG (chmod 600)"
  fi
fi

say ""
say "  Listo. En tu Hermes (o en OpenCode / Claude Code / Cursor, si los usas)"
say "  pedile un artifact y te va a dar el link."
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
