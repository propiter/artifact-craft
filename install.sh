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
    --token)         HUB_TOKEN="${2:-}"; [ -n "$HUB_TOKEN" ] || die "--token necesita el token"; shift 2 ;;
    --name|--nombre) HUB_NAME="${2:-}"; [ -n "$HUB_NAME" ] || die "--name necesita tu nombre"; shift 2 ;;
    -h|--help)       say "uso: install.sh [--api URL] [--code CODIGO | --token TOKEN] [--name TU-NOMBRE]"; exit 0 ;;
    *)               die "opcion desconocida: $1   (las que hay: --api, --code, --token, --name)" ;;
  esac
done
export HUB_API="${HUB_API:-}" HUB_CODE="${HUB_CODE:-}" HUB_NAME="${HUB_NAME:-}" HUB_TOKEN="${HUB_TOKEN:-}"

# La FORMA de los datos se valida ANTES de bajar e instalar. Un error de tipeo no tiene por que
# dejar el skill y el cliente copiados y la cuenta a medias: eso es justo lo que se quiso evitar.
if [ -n "${HUB_API:-}" ]; then
  case "$HUB_API" in
    https://*|http://*) ;;
    *) die "la URL del hub tiene que empezar con https:// o http:// (recibi: ${HUB_API})" ;;
  esac
fi
if [ -n "${HUB_TOKEN:-}" ]; then
  case "$HUB_TOKEN" in
    wlart_*) ;;
    *) die "el token debería empezar con wlart_ — pedilo a quien administra el hub" ;;
  esac
fi

# Sin terminal no hay quien conteste las preguntas. Si tampoco hay variables ni configuracion
# previa, se frena ACA: antes se instalaba el skill y el cliente, y despues moria sin cuenta.
if [ ! -t 0 ] && [ ! -f "$CFG" ] && [ -z "${HUB_API:-}" ] && [ -z "${HUB_TOKEN:-}" ] && [ -z "${HUB_CODE:-}" ]; then
  die "correr asi no funciona: no puedo preguntar sin terminal.
  Correlo en UN comando, diciendome las tres cosas:
    bash install.sh --api https://artifacts.tu-dominio.com --code EL-CODIGO --name tu-nombre
  (o con un token ya emitido: --api <url> --token wlart_...)
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

# El resto de los agentes lee skills del MISMO formato — una carpeta con un SKILL.md adentro —
# desde su propia raiz. Quien instala no tiene por que saber cual usa, ni cuantos tiene: se
# recorren los que esten en la maquina y se copia a todos. Sumar un agente es una palabra mas.
#
# Dos grupos, y la diferencia importa. El primero son agentes que se sabe que leen <raiz>/skills:
# si la raiz existe se instala, aunque todavia no hayan creado la carpeta. El segundo son agentes
# que PUEDEN leerlas: ahi se instala solo si ya tienen una carpeta skills/, para no dejar basura
# en una aplicacion que no usa skills.
KNOWN_AGENTS=".claude .codex .gemini .cursor .config/opencode"
MAYBE_AGENTS=".opencode .config/goose .config/amp .config/crush .continue .config/continue .config/zed
.config/void .config/windsurf .codeium/windsurf .config/aider .config/qwen .config/cline
.config/kilocode .config/cody .config/roo .config/claude"

where_in_home() { case "$1" in "$HOME"/*) printf '%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }
backup_skill()  {  # $1 = carpeta de skills ya existente
  [ -d "$1/artifact-craft" ] || return 0
  mv "$1/artifact-craft" "$BACKUPS/artifact-craft-$(printf '%s' "$1" | tr '/' '_')-$(date +%Y%m%d-%H%M%S)"
}
install_for_agent() {  # $1 = raiz del agente
  local d="$1/skills"
  backup_skill "$d"
  if mkdir -p "$d" 2>/dev/null && cp -r "$skill_src" "$d/artifact-craft" 2>/dev/null; then
    agents="$agents $(where_in_home "$1")"
    agent_count=$((agent_count + 1))
  else
    say "· salteo $(where_in_home "$1") — no pude escribir en $d"
  fi
}

agents=""; agent_count=0
for rel in $KNOWN_AGENTS; do
  [ -d "$HOME/$rel" ] && install_for_agent "$HOME/$rel"
done
for rel in $MAYBE_AGENTS; do
  [ -d "$HOME/$rel/skills" ] && install_for_agent "$HOME/$rel"
done
# Claude Code y Codex dejan mover su carpeta con una variable (CLAUDE_CONFIG_DIR, CODEX_HOME): si
# esta puesta al instalar, ESA es la que el agente lee, no la de arriba.
for root in "${CLAUDE_CONFIG_DIR:-}" "${CODEX_HOME:-}"; do
  [ -n "$root" ] && [ -d "$root" ] || continue
  case " $agents " in *" $(where_in_home "$root") "*) continue ;; esac   # ya quedo instalado
  install_for_agent "$root"
done

# Un agente que no este en ninguna lista: se le pasa la carpeta de skills a mano, separadas por ':'.
#   ARTIFACT_CRAFT_SKILL_DIRS="$HOME/.mi-agente/skills:/otra/ruta" bash install.sh
if [ -n "${ARTIFACT_CRAFT_SKILL_DIRS:-}" ]; then
  for d in $(printf '%s' "$ARTIFACT_CRAFT_SKILL_DIRS" | tr ':' ' '); do
    [ -n "$d" ] || continue
    backup_skill "$d"
    mkdir -p "$d" 2>/dev/null && cp -r "$skill_src" "$d/artifact-craft" 2>/dev/null && {
      agents="$agents $(where_in_home "$d")"
      agent_count=$((agent_count + 1))
    }
  done
fi

if [ "$agent_count" -gt 0 ]; then
  say "· skill tambien en $agent_count agente(s):$agents"
fi

# El cliente y sus dos archivos van juntos: el script los busca a su lado.
mkdir -p "$BIN"
cp "$SKILL_DST/scripts/wl-artifact"        "$BIN/wl-artifact"
cp "$SKILL_DST/scripts/build-catalog.py"   "$BIN/build-catalog.py"
cp "$SKILL_DST/scripts/make-preview.py"    "$BIN/make-preview.py"
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

  # Token pasado por flag o entorno: es el camino SIN terminal (un agente, un CI, un script).
  # Sin esto, configurar con un token exigia una terminal y no habia forma de automatizarlo.
  if [ -n "${HUB_TOKEN:-}" ]; then
    case "$HUB_TOKEN" in
      wlart_*) ;;
      *) die "el token debería empezar con wlart_ — pedilo a quien administra el hub" ;;
    esac
    "$BIN/wl-artifact" setup "$HUB_TOKEN" "$hub_api" >/dev/null
    say "· token guardado en $CFG (chmod 600)"
  else
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
    [ -t 0 ] || die "sin terminal necesito HUB_API y HUB_CODE (o --token, o configurar con: wl-artifact setup <token> <url>)"
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
fi

say ""
say "  Listo. En cualquiera de tus agentes — Hermes, Claude Code, Codex, Gemini, OpenCode, Cursor…"
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
