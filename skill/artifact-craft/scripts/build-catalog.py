#!/usr/bin/env python3
"""Genera el catalogo LOCAL de artifacts.

Uso:  build-catalog.py <destino.html> <host> <template.html>
      Acepta de stdin, indistintamente:
        * el JSON de la API:  {"artifacts":[{slug,title,bytes,updated_at,url,owner}, ...]}
        * lineas "nombre|bytes|mtime_epoch|titulo"   (modo contenedor, lo usa wl-artifact reindex)
"""
import json, sys, time, pathlib


def main():
    if len(sys.argv) != 4:
        sys.exit("uso: build-catalog.py <destino> <host> <template>")
    dest, host, tpl_path = sys.argv[1], sys.argv[2], sys.argv[3]

    raw = sys.stdin.read().strip()
    items = []

    if raw.startswith("{"):
        # JSON de la API
        for a in json.loads(raw).get("artifacts", []):
            name = a.get("slug", a.get("name", ""))
            if not name:
                continue
            items.append({
                "name": name if name.endswith(".html") else name + ".html",
                "title": (a.get("title") or "").strip(),
                "size": int(a.get("bytes", 0)),
                "mtime": int(a.get("updated_at", a.get("mtime", 0))),
                "url": a.get("url") or "https://%s/%s" % (host, name),
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
        return

    for line in raw.splitlines():
        line = line.strip()
        if not line or "|" not in line:
            continue
        parts = line.split("|")
        name, size, mtime = parts[:3]
        title = parts[3].strip() if len(parts) > 3 else ""
        name = name.rsplit("/", 1)[-1]
        if name in ("index.html", "50x.html") or not name:
            continue
        try:
            items.append({
                "name": name,
                "title": title,
                "size": int(size),
                "mtime": int(mtime),
                "url": "https://%s/%s" % (host, name),
            })
        except ValueError:
            continue

    items.sort(key=lambda a: a["mtime"], reverse=True)
    payload = json.dumps({"generated": int(time.time()), "host": host, "items": items})

    tpl = pathlib.Path(tpl_path).read_text(encoding="utf-8")
    if "__DATA__" not in tpl:
        sys.exit("el template no tiene el marcador __DATA__")
    html = (tpl.replace("__DATA__", payload)
               .replace("__HOSTURL__", "https://%s/" % host)
               .replace("__HOST__", host))
    pathlib.Path(dest).write_text(html, encoding="utf-8")
    print("catalogo local: %s (%d artifact(s))" % (dest, len(items)))


if __name__ == "__main__":
    main()
