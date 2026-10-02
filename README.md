# artifact-craft

**Artefactos, publicados y compartibles — sin depender de tu PC.**

Un *artifact* es una página HTML autocontenida: una propuesta, un tablero, un comparador, una
calculadora, un informe visual. Se ve y se usa, en vez de ser un `.md` o un `.pdf` que el otro no
puede abrir. Este repo trae dos cosas:

1. **`artifact-craft`** — el skill que le enseña a Hermes **cuándo** construir un artifact en vez
   de un archivo suelto, y **cómo** entregarlo.
2. **`artifacts-hub`** — el servicio que los aloja y comparte: cada persona publica desde su Hermes
   y recibe una URL pública. Con token propio, versiones, cupos y auditoría.

> **La regla que importa:** si el artifact es para alguien, se **publica** y se entrega la **URL
> pública**. Una ruta local (`/home/vos/artifacts/x.html`) no es un entregable: funciona en una sola
> computadora y se muere con ella.

## Instalar

```bash
curl -fsSL https://raw.githubusercontent.com/propiter/artifact-craft/main/install.sh | bash
```

Baja el skill, deja el cliente en tu `PATH` y te pide dos datos: la URL del hub y tu token. Después,
en tu Hermes:

> *hacé un artifact con el resumen de esta reunión*

…y te devuelve un link para compartir. También podés publicar a mano:

```bash
wl-artifact publish ~/artifacts/informe.html informe-auditoria   # una página
wl-artifact deploy  ~/proyectos/mi-app mi-app                    # una app (html+js+css+imagenes)
wl-artifact ls                                                   # lo tuyo
wl-artifact catalog                                              # tu galería, en tu disco
wl-artifact whoami                                               # usuario, cupo y uso
wl-artifact rm <slug>                                            # revoca (mata los links)
```

### Por Hermes (alternativa)

```bash
hermes skills install propiter/artifact-craft/skill/artifact-craft
```

Y el cliente, que es un script suelto:

```bash
mkdir -p ~/.local/bin
cp skill/artifact-craft/scripts/wl-artifact            ~/.local/bin/
cp skill/artifact-craft/scripts/build-catalog.py       ~/.local/bin/
cp skill/artifact-craft/templates/catalog-template.html ~/.local/bin/
```

## Cómo funciona

```
                 ┌──────────────── servidor ─────────────────┐
  Hermes ──HTTPS │  nginx:  /            landing, no enumera  │
  wl-artifact    │          /a/<user>/…  los artifacts        │
                 │          /api/…    → api (tokens, cupos)   │
                 └───────────────────────────────────────────┘
                              un solo volumen compartido
```

- **store** — nginx: sirve la landing, los artifacts y hace de proxy hacia la API.
- **api** — tokens, cupos, versiones y auditoría. **Sin dependencias**: stdlib de Python + sqlite.
  Un archivo, un volumen, un proceso.
- Los dos comparten el volumen: la API escribe en `/data`, nginx lo sirve como docroot.

### Modelo de acceso

| | |
|---|---|
| Leer | **el link es la credencial** — sin login, sin catálogo público, y no se puede "des-compartir" |
| Escribir | un **token por persona**; el dueño sale del token, nunca del pedido |
| Aislar | cada uno escribe **sólo su namespace**; nadie toca artifacts ajenos |
| Versiones | el slug da una URL estable; cada versión queda inmutable en `-vN` |
| Revocar | `rm` borra la canónica y todas las versiones: los links compartidos mueren |
| Limitar | tamaño por artifact, cantidad por persona, ritmo de escritura |
| Auditar | quién publicó o borró qué; **nunca** se guarda el token |

## Correrlo vos

```bash
python3 tests/test_api.py                    # 53 tests, sin instalar nada
docker compose -f docker-compose.yml up -d   # en http://127.0.0.1:18080
```

Administración:

```bash
docker compose exec api python3 admin.py user add ana --admin
docker compose exec api python3 admin.py token add ana --label laptop --days 90   # se muestra UNA vez
docker compose exec api python3 admin.py token list
docker compose exec api python3 admin.py token revoke tok_abc123
docker compose exec api python3 admin.py events --limit 20
docker compose exec api python3 admin.py stats
```

El token se muestra una sola vez y en la base queda **sólo su sha256**. Si alguien lo pierde, se
revoca y se emite otro.

## Estructura

| Ruta | Qué es |
|---|---|
| `api/app.py` | el servicio: auth, publicación (página y app), versiones, borrado, auditoría |
| `api/admin.py` | CLI: usuarios, tokens, eventos, stats |
| `api/Dockerfile` + `entrypoint.sh` | imagen (corre como uid 10001, no root) |
| `client/wl-artifact` | el cliente que usa cada persona |
| `client/build-catalog.py` + `catalog-template.html` | la galería local |
| `store/default.conf` | nginx: `/`, `/a/`, `/api/`, `/healthz` |
| `store/www/` | semillas del docroot (landing + 50x) |
| `skill/artifact-craft/` | el skill instalable (SKILL.md + scripts + templates) |
| `deploy/` | generador de los SQL de Dokploy (`gen-deploy-sql.py`) |
| `tests/test_api.py` | 53 tests: auth, cupos, aislamiento, apps, auditoría, recursos |

## Decisiones de diseño (y sus límites)

- **stdlib en vez de FastAPI**: para decenas de personas a este ritmo da lo mismo, con **cero
  dependencias** — nada que auditar ni parchear.
- **sqlite en vez de Postgres**: un archivo, sin servicio extra.
- **La galería es local, no una web autenticada**: evita poner un token en un navegador y en una
  URL, donde termina en logs. Se arma desde la API con el cliente.
- **El límite de ritmo vive en memoria del proceso**: alcanza con una réplica; con varias hay que
  moverlo.
- **Los artifacts son HTML de los usuarios y se sirven desde el mismo origen que la API**: por eso
  el token **nunca** se usa desde un navegador. Una galería web autenticada iría en **otro dominio**.
- **Los artifacts no se ejecutan en el servidor**: nginx los sirve como estáticos.

## Licencia

Apache-2.0.
