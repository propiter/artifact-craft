# artifact-craft

**El skill que hace que Hermes entregue artifacts, no archivos sueltos.**

En vez de un `.md` o un `.pdf` que el otro no puede abrir, Hermes construye un **artifact**: una
página HTML autocontenida — una propuesta, un tablero, un comparador, una calculadora, un informe
visual — la **publica** y te devuelve un **link para compartir**.

> **La regla que importa:** si el artifact es para alguien, se publica y se entrega la **URL
> pública**. Una ruta local (`/home/vos/artifacts/x.html`) no es un entregable: funciona en una sola
> computadora y se muere con ella.

Este repo es **sólo el skill**. El servicio que aloja los artifacts vive en
[`propiter/artifacts-hub`](https://github.com/propiter/artifacts-hub).

## Instalar

```bash
curl -fsSL https://raw.githubusercontent.com/propiter/artifact-craft/main/install.sh | bash
```

Baja el skill, deja el cliente en tu `PATH` y pide dos datos: **la URL del hub** y **tu token**. Los
dos te los da quien administra el hub.

Después, en tu Hermes:

> *hacé un artifact con el resumen de esta reunión*

…y te devuelve el link. También podés publicar a mano:

```bash
wl-artifact publish ~/artifacts/informe.html informe-auditoria   # una página
wl-artifact deploy  ~/proyectos/mi-app mi-app                    # una app (html+js+css+imagenes)
wl-artifact ls                                                   # lo tuyo
wl-artifact catalog                                              # tu galería
wl-artifact whoami                                               # usuario, cupo y uso
wl-artifact rm <slug>                                            # revoca (mata los links)
```

### Por Hermes (alternativa)

```bash
hermes skills install propiter/artifact-craft/skill/artifact-craft
```

Y el cliente, que son tres archivos sueltos:

```bash
mkdir -p ~/.local/bin
cp skill/artifact-craft/scripts/wl-artifact            ~/.local/bin/
cp skill/artifact-craft/scripts/build-catalog.py       ~/.local/bin/
cp skill/artifact-craft/templates/catalog-template.html ~/.local/bin/
```

## Qué te da el skill

- **Cuándo** construir un artifact en vez de un `.md`, un `.pdf` o una respuesta larga.
- **Cómo** escribirlo para que se vea bien en el marco de Hermes (tema, altura medida, phone-first,
  sin almacenamiento del navegador) — el contrato completo, verificado contra el código.
- **Cómo entregarlo**: publicar y dar la URL. Siempre.
- **Editar es un ciclo**: mismo archivo, mismo slug, republicar — el link que ya compartiste sigue
  funcionando y muestra la versión nueva.

## Reglas del hub que conviene tener presentes

- **El link ES la credencial.** Quien lo tenga, entra. No hay login en el artifact ni forma de
  "des-compartir": mandalo a la persona, no al grupo.
- **Cada uno escribe sólo lo suyo.** El servidor saca el dueño del token.
- **`rm` revoca de verdad**: todo link que hayas compartido deja de funcionar.
- **Tu token no va en el artifact, ni en un repo, ni en un chat.** Vive en
  `~/.config/wl-artifact/config` con permisos 600.

## Estructura

| Ruta | Qué es |
|---|---|
| `skill/artifact-craft/SKILL.md` | el skill: el criterio, el contrato de render y la regla de la URL |
| `skill/artifact-craft/scripts/wl-artifact` | el cliente |
| `skill/artifact-craft/scripts/build-catalog.py` | arma tu galería local |
| `skill/artifact-craft/templates/` | el artifact de arranque, la galería y la landing |
| `install.sh` | el instalador |

## Licencia

Apache-2.0.
