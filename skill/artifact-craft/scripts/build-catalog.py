#!/usr/bin/env python3
"""Genera el catalogo LOCAL de artifacts.

Uso:  build-catalog.py <destino.html> <host> <template.html>
      Lee de stdin el JSON de la API:  {"artifacts":[{slug,title,bytes,updated_at,url,owner}, ...]}

      Es el unico formato que existe. Hubo un "modo contenedor" (lineas nombre|bytes|mtime|titulo)
      que decia usar `wl-artifact reindex` — un comando que nunca existio — y armaba las URLs sin
      el `/a/<usuario>/` del hub, o sea links rotos. Si algun dia hace falta, que sea contra la API.
"""
import json, sys, time, pathlib


def main():
    if len(sys.argv) != 4:
        sys.exit("uso: build-catalog.py <destino> <host> <template>")
    dest, host, tpl_path = sys.argv[1], sys.argv[2], sys.argv[3]

    raw = sys.stdin.read().strip()
    if not raw.startswith("{"):
        sys.exit("build-catalog.py espera el JSON de la API en stdin (¿fabrica?): %.80s" % raw)

    items = []
    for a in json.loads(raw).get("artifacts", []):
        name = a.get("slug", a.get("name", ""))
        if not name:
            continue
        items.append({
            "name": name if name.endswith(".html") else name + ".html",
            "title": (a.get("title") or "").strip(),
            "size": int(a.get("bytes", 0)),
            "mtime": int(a.get("updated_at", a.get("mtime", 0))),
            "url": a.get("url") or "https://%s/a/%s/%s" % (host, a.get("owner", ""), name),
        })
    items.sort(key=lambda x: x["mtime"], reverse=True)

    payload = json.dumps({"generated": int(time.time()), "host": host, "items": items})
    tpl = pathlib.Path(tpl_path).read_text(encoding="utf-8")
    if "__DATA__" not in tpl:
        sys.exit("el template no tiene el marcador __DATA__")
    html = (tpl.replace("__DATA__", payload)
               .replace("__HOSTURL__", host.rstrip("/") + "/")
               .replace("__HOST__", host.split("//")[-1]))
    pathlib.Path(dest).write_text(html, encoding="utf-8")
    print("catalogo local: %s (%d artifact(s))" % (dest, len(items)))


if __name__ == "__main__":
    main()
