#!/usr/bin/env python3
"""Genera la vista previa (1200x630) de un artifact.

Es la imagen que despues va como `og:image`: sin ella, pegar el link en un chat no muestra
nada. Usa un navegador headless en modo captura — NO habla CDP ni necesita ninguna libreria,
porque el cliente del hub es bash + python3 y nada mas.

Uso:  make-preview.py <archivo.html> <salida.png> [ancho] [alto]

Sale 0 si la genero y 3 si en esta maquina no hay navegador. El 3 NO es un error: el artifact
se publica igual, sin vista previa. Degradar bien es parte del contrato.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.parse

# En orden de preferencia. Chrome/Chromium comparten los flags de captura; Edge y Brave son
# el mismo motor y suelen estar donde uno no mira.
CANDIDATES = ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser",
              "chrome", "microsoft-edge", "microsoft-edge-stable", "brave-browser", "brave")
MAC_PATHS = ("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
             "/Applications/Chromium.app/Contents/MacOS/Chromium",
             "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge")


def find_browser():
    for name in CANDIDATES:
        path = shutil.which(name)
        if path:
            return path
    for path in MAC_PATHS:
        if os.path.exists(path):
            return path
    return None


def main():
    if len(sys.argv) < 3:
        sys.exit("uso: make-preview.py <archivo.html> <salida.png> [ancho] [alto]")
    src, out = sys.argv[1], sys.argv[2]
    w = sys.argv[3] if len(sys.argv) > 3 else "1200"
    h = sys.argv[4] if len(sys.argv) > 4 else "630"
    if not os.path.isfile(src):
        sys.exit("no existe %s" % src)

    browser = find_browser()
    if not browser:
        print("no hay navegador headless en esta maquina: se publica igual, sin vista previa",
              file=sys.stderr)
        return 3

    out = os.path.abspath(out)
    url = "file://" + urllib.parse.quote(os.path.abspath(src))
    profile = tempfile.mkdtemp(prefix="wl-preview-")
    base = [browser, "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
            "--force-device-scale-factor=1", "--window-size=%s,%s" % (w, h),
            "--user-data-dir=" + profile, "--screenshot=" + out, url]
    try:
        for mode in ("--headless=new", "--headless"):     # el viejo no entiende el nuevo
            if os.path.exists(out):
                os.remove(out)
            try:
                subprocess.run([base[0], mode] + base[1:],
                               capture_output=True, timeout=90)
            except subprocess.TimeoutExpired:
                continue
            if os.path.exists(out) and os.path.getsize(out) > 1000:
                return 0
        print("no pude generar la vista previa", file=sys.stderr)
        return 1
    finally:
        shutil.rmtree(profile, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())