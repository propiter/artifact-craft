---
name: artifact-craft
description: "Use when about to deliver anything visual, interactive or page-shaped in Hermes. Decides render-vs-file-vs-deploy and holds the verified page contract."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [artifact, widget, preview, dashboard, html, desktop, delivery, page-contract, claude]
    related_skills: [claude-design, popular-web-designs, design-md, app-craft, hermes-agent]
---

# Artifact Craft

How to make an artifact in Hermes behave like a Claude artifact, and when NOT to make one.

**Load this BEFORE writing any `::preview` target, dashboard, chart, diagram, mockup or "page"
for the user.** `claude-design` owns design TASTE; this skill owns the delivery decision and the
render contract. Load both when the artifact deserves real design effort.

## 1. The Gate — decide before you build

An artifact is a **product the user will operate**, never a way to hand over a file.

Render one ONLY when it is at least one of:

- **Interactive** — the user will click, type, drag, toggle, sort, filter.
- **Visual** — a chart, dashboard, diagram, layout, mockup, game, deck: the shape IS the answer.
- **A page they will USE rather than only read** — collecting input, tracking changes, live data.
- **Explicitly asked for** — "an artifact", "a dashboard", "an HTML page", "a landing".

Answer INLINE in the chat, and render nothing, when the content is:

- A report, analysis, list, plan, summary, verdict or explanation. Chat carries it, and it stays
  searchable. If they ALSO want it on disk, that is a second, separate deliverable: a file via
  `MEDIA:/abs/path` (`.md`, `.xlsx`, `.pdf`) — which is **not an artifact**.
- Claude's own verdict with no named reader ("should we ship this?") → answer inline, then offer
  the page in ONE line. Do not build it uninvited.
- A link to something already deployed → the deployed URL in the preview pane, not an HTML file
  pretending to have a backend.
- Anything with a secret in it. An API key, token or password NEVER goes into page source.

**The failure this skill exists to kill:** creating `.md` / `.txt` / link "artifacts" as a
transport mechanism. A `.md` is a file, not an artifact. If the answer is text, the answer is
text. Volume is not value — one artifact per topic, not one per reply.

**Never render** a page that impersonates a real person or organisation, fabricated records,
receipts or reviews passed off as genuine, or a form that collects credentials or payment details
under false pretences. Those are files (or nothing) and the user decides about sharing. Claude's
own rule, and it is a good one.

## 2. The desktop auto-promotes fences — do not fight it, aim it

The Hermes desktop has its OWN artifact detector (`lib/artifact-detect.ts`), independent of
anything you decide. It promotes a fenced block in your message into an artifact CARD:

| Fence | Promoted when |
|---|---|
| `html` | has `<!doctype html>`/`<html>`/`<head>`/`<body>` **and** ≥160 chars — or is a fragment ≥1200 chars with any tag |
| `svg` | ≥2000 chars |
| any other language | ≥48 lines **or** ≥3000 chars, and not prose |

**Never promoted** (the excluded set): `md` · `markdown` · `txt` · `text` · `plain` · `log` · `logs`
· `console` · `output` · `stdout` · `shell-session` · `diff` · `patch` · `listing` · `mermaid` ·
no language at all.

This is the real source of "too many artifacts that make no sense". A 60-line code dump the user
never asked for becomes a card in the right rail, competing with the one artifact that mattered.

**How to aim it:**

- A report, a listing, a diff, terminal output, or prose → fence it with NO language or `text`.
  Excluded by design, so it stays inline where it belongs.
- A snippet the user reads in passing → keep it under 48 lines / 3000 chars.
- A code file the user will actually take away → a `code` fence is fine; the card is a feature.
- A page or widget → write a FILE and use `::preview{file="…"}`. That is ONE artifact, live and
  interactive, instead of a static promoted block. **This is the preferred form.**

**Identity and limits**, worth knowing before regenerating something: one artifact = one
`(session, slug)` pair, slug = `kind:language:title` — so rewriting "the dashboard" three times is
ONE artifact with three versions, not three cards (max 20 versions, 24 artifacts per session, 40
sessions). The registry is **memory-only**: the transcript is the durable copy and cards
re-register as they render, so a promoted artifact cannot be durably deleted from the app — only
by removing the fence from the transcript.

## 3. Pick the tier

| Tier | When | Mechanism | Needs a server? |
|---|---|---|---|
| **1 · Widget** | Interactive/visual, data you already have | single-file HTML + `::preview{file="..."}` | NO |
| **2 · File** | Report, spreadsheet, PDF, downloadable | `MEDIA:/abs/path` | NO |
| **3 · Deployed app** | State must persist, be shared, or be read back; secrets; real APIs; auth; a link others open | a deployed URL (`dokploy` skill) + the preview pane | YES |

Tier 3 is the exception, never the default. A server buys persistence, secrets, real data,
webhooks and a shareable link — and costs latency, ops, auth surface and portability. Most
artifacts never need it. **Never fake a backend in tier 1**: an HTML file with a hardcoded
`fetch` to nowhere is worse than the plain answer.

### The store — already deployed, publish to it, do NOT redeploy

Tier 3 has exactly ONE destination. It exists; do not build another:

**https://artifacts.lab.whitelabel.lat** — el hub del equipo (API con token, cuentas, cupos y galeria)

| | |
|---|---|
| server | `vanguardistas` (SSH) — 177.7.42.143, Dokploy, appName `pedro-artifactshub-i94jv7` |
| artifacts | `https://artifacts.lab.whitelabel.lat/a/<usuario>/<slug>.html` · apps: `/a/<usuario>/<slug>/` |
| interfaz | `https://app.artifacts.lab.whitelabel.lat` — galeria, cuentas, `/admin` |
| cuenta | `wl-artifact join <codigo-de-equipo> --name <usuario> --api <url>` (o el `install.sh` del repo `propiter/artifact-craft`) |
| publish | `wl-artifact publish <file.html> [slug]` — el token vive en `~/.config/wl-artifact/config` (600) |
| list / remove | `wl-artifact ls` · `wl-artifact rm <name.html>` · `wl-artifact gallery` (abre la galeria) |

**La interfaz web usa un hostname SEPARADO a proposito, y no es estetica:** los artifacts son HTML
de terceros. Si la galeria (que lleva la cookie de sesion) compartiera origen con ellos, el JS de un
artifact podria leer la sesion de quien lo mira. Por eso el host de la app NO sirve `/a/` (da 404).
Nunca juntes los dos hostnames.

**El link de un solo uso no se puede verificar sin gastarlo.** `wl-artifact gallery` da una URL que
vence en 10 min y sirve UNA vez: si la abris con `curl` para comprobarla, la gastas y el navegador del
usuario recibe 410. Comprobala con otro link, o pedi uno nuevo al final. Y `ARTIFACTS_OPEN=0` desactiva
la apertura del navegador: comparalo contra `0|false|no|off`, nunca con `[ -n "$VAR" ]` ("0" NO es vacio).

**Store viejo, en retirada:** `https://artifacts.2.24.216.175.sslip.io` (`daniel`, appName
`artifacts-store-i2xhsw`, publica por SSH con `~/Projets/artifacts-service/wl-artifact`). Sigue vivo y sin
listado en la raiz, pero **no publiques ahi: el destino es el hub**.

```bash
wl-artifact publish ~/artifacts/informe.html informe-auditoria
# → https://<hub>/a/<your-user>/informe-auditoria.html
```

**A whole app — HTML + JS + CSS + images — is one command** when one page is not enough (a
dashboard that pulls a chart library, a small tool with assets, anything multi-file):

```bash
wl-artifact deploy ~/proyectos/mi-app mi-app
# → https://<hub>/a/<your-user>/mi-app/     (sirve su index.html, y los assets al lado)
```

The folder needs an `index.html` at its root. Extensions allowed inside: html, css, js, mjs, json,
svg, png, jpg, gif, webp, avif, ico, woff/woff2/ttf/otf, txt, md, csv, wasm, map, mp3/mp4/webm/vtt,
xml. Packages are validated member by member: a path that climbs out (`../`), an absolute path, a
symlink or a disallowed extension is rejected outright, so a bundle cannot write outside its own
folder. Redeploying replaces the tree atomically and the URL does not change.

The name carries a content hash, so republishing the same file keeps the SAME url. It is one
nginx container plus one named volume: no API, no DB, no upload endpoint — publishing is an SSH
write into the volume. **Public with an unguessable URL by default**; there is an `auth_basic`
block in the mount for client material (read the README before putting anything of a client's
up). No versioning, no comments, no shared DB — that is a product, not a store.

Deploy record, rollback, the disk-write step everyone forgets: `~/Projets/artifacts-service/README.md`.
Server inventory and Dokploy mechanics: the `dokploy` skill. **Do not point a tier-3 URL at
`daniel.whitelabel.lat`** — that host resolves to the wrong server (the wildcard goes to
`proyectos`).

**The root MUST NOT enumerate.** The store's root is a STATIC landing page
(`templates/store-landing.html`) that explains there is no catalog: it is written once and
NEVER regenerated from the artifact list. An index rebuilt on every publish was a real leak —
anyone given one artifact link could strip the filename and read the whole collection — so the
catalog lives with the publisher (`wl-artifact catalog`, local) and never enters the document
root. A listing page that is *generated* from the files is the bug, not the listing itself.

**nginx gotcha that cost a silent no-op:** `add_header` declared at `server` level is DISCARDED
for any request handled by a `location` that declares its own `add_header` — the child context
replaces the parent's inherited set instead of merging. `X-Robots-Tag` at server level returned
nothing while `location /` had its own `Cache-Control`/`X-Content-Type-Options`. Put the header
inside the location, and prove it with `curl -sI` rather than trusting the config text: the file
saying `noindex` is not the header arriving.

**Your own catalog is local and pretty:** `wl-artifact catalog` regenerates a gallery with a live
cropped preview of each artifact, its REAL `<title>` (read out of the artifact, not the filename),
size, relative date, search, sort and copy-URL — built by `build-catalog.py` from
`templates/catalog-template.html`. It never touches the docroot: the publisher's catalog and the
public store are two different things, and conflating them is what caused the leak.

**Publish footgun:** the slug defaults to the FILE's basename, so `publish x/foo.html` and
`publish x/foo.html bar` produce two different URLs for the same bytes — a duplicate artifact.
Pass the slug explicitly every time, or never; do not mix.

## 4. The render contract (verified against the Hermes desktop source)

Full detail, evidence and failure modes: `references/hermes-render-contract.md`.
The short list you must not violate:

1. **Single file.** One self-contained `.html`. Relative sibling assets do NOT resolve — inline
   everything or use absolute CDN URLs.
2. **No browser storage.** `localStorage`, `sessionStorage`, `IndexedDB` and cookies all THROW
   `SecurityError` (the frame is a sandboxed opaque origin). Keep state in JS memory. State that
   must survive belongs in tier 3.
3. **Locally reachable.** The frame renders a LOCAL file. Against a remote gateway the HTML takes
   a sanitised, script-disabled path or falls back to a plain card — so never make the widget the
   only way to get the information.
4. **Theme with the app's tokens**, do not hardcode: `--foreground`, `--muted-foreground`,
   `--accent`, `--border`, `--card`. Use `var(--x)` with a sane fallback. The frame injects the
   LIVE theme, so dark/light comes free — see `templates/artifact.html`.
5. **Design for a ~640px column at phone width**, no horizontal scroll. Height is MEASURED from
   content (min 120, max 1200); `height=N` only sets a starting height. Lay content flush left —
   centring wrappers break width measurement.
6. **Let it talk back** when interaction means work: `data-hermes-send="prompt"` on any clickable
   element, or `window.hermes.send("prompt")`. Capped at 500 chars and throttled to 1/second — one
   clear intent per click, at human speed. The prompt arrives as a hidden user turn; the widget
   updating IS the visible reply.
7. **Iterate in place.** Same file path, edited — not a new file per answer. One artifact per
   topic. Different path = a different artifact to the user.
8. **Dependencies: prefer none.** Inline SVG, vanilla JS, CSS. If you must, pin an exact version
   from `cdnjs.cloudflare.com`, `cdn.jsdelivr.net/npm/` or Google Fonts, and place the script tag
   BEFORE any inline script that uses it. Hermes applies no CSP host whitelist (unlike Claude), so
   any host works — but staying on that shortlist keeps the artifact portable and cache-friendly.

## 5. The page contract (for full pages, not widgets)

Claude's authoring rules — adopted because they are sound, not because they are Claude's:

- `<title>`: two to four words. Never `"Name: explainer"`. Put the explanation in one sentence
  next to your link.
- Define colours as tokens on `:root`, redefine for dark mode under
  `@media (prefers-color-scheme: dark)` guarded by `:root:not([data-theme="light"])` and again
  under `:root[data-theme="dark"]`; give `body` an explicit background.
- Phone-first layout, 16px side gutter, no horizontal page scroll.
- Always author `.html`. A Markdown document is a source, not a deliverable: when asked to turn one
  into an artifact, **build a designed page from its content** — never transcribe the Markdown.

## 6. After you deliver

**The rule that matters most: if the artifact is meant for someone — or for the user on another
machine — it is PUBLISHED, and what you give back is the PUBLIC URL. Never a local path.**
`/home/you/artifacts/x.html` is not a deliverable: it works on exactly one computer and dies
with it. If you made a page and did not publish it, you have not finished: run the publish step
and hand over the link. The only local path you may ever mention is when the user explicitly
asked for a file on disk.

Say in ONE sentence what the page is, or what changed on an update, and include the URL. Do not
narrate the mechanics — the frame is already on screen. If the artifact replaced a plain answer,
that is fine; if the user wanted both, the file goes via `MEDIA:`.

**Editing is a loop, not a new artifact.** Keep the SAME file path and the SAME slug, change the
file, publish again: the URL you already shared keeps working and now shows the new version
(the old one stays at `-v<N>.html`). Never "fix" something by inventing a new slug — that orphans
every link you gave out. Re-publishing identical content changes nothing at all.

## 7. Anti-patterns

- A `.md`/`.txt`/link dressed up as an artifact → it is a file; use `MEDIA:` or inline it.
- A giant fenced code block for something the user only needs to READ → the desktop promotes it
  into a card. Fence it as `text` (excluded) or keep it under 48 lines / 3000 chars.
- Pasting a whole HTML page into a fence instead of writing a file + `::preview`.
- A new file per reply instead of editing the one artifact.
- A dashboard for data the user never asked to explore.
- `localStorage.setItem(...)` → throws. Guaranteed broken page.
- `./script.js` next to the HTML → does not resolve. Broken page.
- Hardcoded `#fff`/`#000` on a widget → looks foreign in the app's theme.
- A "shareable link" that is a local file path → tier 3, or it does not exist.

## References

- `references/hermes-render-contract.md` — what the Hermes frame really supports, with the source
  evidence and a working probe (read this before debugging a blank frame).
- `references/claude-artifact-contract.md` — Claude's own Artifact tool prompt, extracted from the
  installed Claude Code bundle. Use it when matching Claude's behaviour precisely.
- `templates/artifact.html` — the starting file: theme tokens, dark mode, phone-safe layout,
  measured height, `hermes.send` bridge. Copy it, then delete what you do not use.