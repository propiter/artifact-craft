---
name: artifact-craft
description: "Use when delivering a page, dashboard, report, chart, mockup, widget or app in Hermes, or when a result has to reach someone else as a link. Decides render-vs-file-vs-publish and holds the verified render contract."
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [artifact, widget, preview, dashboard, html, publish, delivery, page-contract, claude]
    related_skills: [claude-design, popular-web-designs, design-md, app-craft, hermes-agent]
---

# Artifact Craft

Make an artifact behave like a Claude artifact — and know when NOT to make one.

**Load this BEFORE writing any `::preview` target, dashboard, chart, diagram, mockup or "page",
and before handing over any deliverable that is meant to be looked at rather than read.** You do not
need to be asked for "an artifact": if the shape of the answer is a page, this is the skill that
governs it. `claude-design` owns design TASTE; this skill owns the delivery decision and the render
contract. Load both when the artifact deserves real design effort.

## 1. The gate — decide before you build

An artifact is a **product the user will operate**, never a way to hand over a file.

Render one when it is at least one of:

- **Interactive** — the user will click, type, drag, toggle, sort, filter.
- **Visual** — a chart, dashboard, diagram, layout, mockup, game, deck: the shape IS the answer.
- **A page they will USE rather than only read** — collecting input, tracking changes, live data.
- **A deliverable for someone else** — an investigation, a report, an analysis, a plan, a
  comparison or a board. Designed, and where it helps, interactive. The deliverable is the
  **published artifact with its public URL**; the chat carries two or three lines (what it is, and
  the link).
- **Explicitly asked for** — "an artifact", "a dashboard", "an HTML page", "a landing".

Answer INLINE in the chat, and render nothing, when the content is:

- a one-line answer, a clarification, a question, a stray fact;
- a verdict with **no named reader** ("should we ship this?") → answer in the chat and offer the
  page in ONE line; do not build it uninvited;
- a link to something already deployed → the deployed URL in the preview pane, not an HTML file
  pretending to have a backend;
- anything with a secret in it. An API key, token or password NEVER goes into page source.

Turning those into artifacts fills the gallery with cards nobody asked for — and then the artifact
that mattered competes with noise. One artifact per topic, not one per reply.

**The failure this skill exists to kill:** creating `.md` / `.txt` / link "artifacts" as a transport
mechanism. A `.md` is a file, not an artifact. If the answer is text, the answer is text.

**Never render** a page that impersonates a real person or organisation, fabricated records,
receipts or reviews passed off as genuine, or a form that collects credentials or payment details
under false pretences. Those are files (or nothing) and the user decides about sharing.

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
| **3 · Published page or app** | A link others open; state must persist, be shared or read back; real APIs; auth | publish to the artifact hub, and give back the URL | it already exists |

Tier 3 is the exception, never the default. A server buys persistence, secrets, real data, webhooks
and a shareable link — and costs latency, ops, auth surface and portability. Most artifacts never
need it. **Never fake a backend in tier 1**: an HTML file with a hardcoded `fetch` to nowhere is
worse than the plain answer.

### The store — publish to the hub you are configured for

For a page or an app that must be seen by someone, there is ONE destination: **your artifact hub**.
It is not something you deploy for each artifact — it already runs. You publish to it and hand back
the public URL.

The client keeps your hub URL and your token in `~/.config/wl-artifact/config` (mode 600). Read them
from there. **Never hardcode a hub URL or a token into a page, a repo or a chat.** To see who you
are, your quota and your usage:

```bash
wl-artifact whoami
```

| | |
|---|---|
| a page | `wl-artifact publish <file.html> [slug]` → `https://<hub>/a/<user>/<slug>.html` |
| a whole app | `wl-artifact deploy <dir> [slug]` → `https://<hub>/a/<user>/<slug>/` |
| list / remove | `wl-artifact ls` · `wl-artifact rm <slug>` (kills every link you handed out) |
| open the gallery | `wl-artifact gallery` (prints a one-time login link) |
| your local catalog | `wl-artifact catalog` |

#### Getting in — the team code, or a token

Two ways, both over HTTPS. **Neither needs SSH, nor anything installed on the server.**

- **Team code.** Whoever operates the hub hands you a code and the hub URL. One command creates your
  account and stores your token:
  ```bash
  wl-artifact join <team-code> --name <your-name> --api <hub-url>
  ```
- **Token.** If you are given a token instead (`wlart_…`):
  ```bash
  wl-artifact setup <token> <hub-url>
  ```

**The team code is a credential, and wider than it looks.** With the code and the URL, anyone can
create an account and publish. But `join` reuses a user **by name**, so whoever holds the code can
also claim a name that already exists and write in that space. Treat it as a team secret, and rotate
it when it leaks.

#### If the client is not installed

`wl-artifact` is one bash script plus `python3`. If it is missing, install it in a single command —
which also drops this skill into every agent on the machine (Hermes, OpenCode, Claude Code, Cursor):

```bash
curl -fsSL https://raw.githubusercontent.com/propiter/artifact-craft/main/install.sh | bash
```

With no terminal to answer questions, pass the answers up front:

```bash
bash install.sh --api <hub-url> --code <team-code> --name <your-name>   # or --token wlart_…
```

#### What the hub does, in one paragraph

Publishing is an **HTTPS call with your token** — one file for a page, one folder for an app (needs
an `index.html` at its root). The URL is stable: it carries a content hash, so republishing the same
file keeps the SAME url, and identical bytes are a no-op (`sin cambios`), not a new version. Every
previous version stays immutable at `-vN`. There are per-person tokens, quotas and an audit log, and
**no catalog**: the link IS the credential, unguessable by default. There are no comments.

An app folder is validated member by member: html, css, js, mjs, json, svg, png, jpg, gif, webp,
avif, ico, woff/woff2/ttf/otf, txt, md, csv, wasm, map, mp3/mp4/webm/vtt, xml. A path that climbs
out (`../`), an absolute path, a symlink or a disallowed extension is rejected outright, so a bundle
cannot write outside its own folder. Redeploying replaces the tree atomically.

Anything belonging to a client is client material: check with them before it gets a URL.

**Your own catalog is local and pretty.** `wl-artifact catalog` regenerates a gallery with a live
cropped preview of each artifact, its REAL `<title>` (read out of the artifact, not the filename),
size, relative date, search, sort and copy-URL — built by `scripts/build-catalog.py` from
`templates/catalog-template.html`. It is a file on your disk: it never touches anyone's public
server, because a listing on the server is exactly the leak described below.

#### Three footguns worth one line each

- **The slug defaults to the file's basename**, so `publish x/foo.html` and `publish x/foo.html bar`
  produce two different URLs for the same bytes — a duplicate. Pass the slug explicitly every time,
  or never; do not mix.
- **A one-time link cannot be checked without spending it.** `wl-artifact gallery` prints a URL that
  expires in 10 minutes and serves ONCE: opening it with `curl` to test it burns it and the user's
  browser gets a 410. Check with a different one, or ask for a fresh one at the end.
- **`ARTIFACTS_OPEN=0` disables opening the browser.** Compare it against `0|false|no|off`, never
  with `[ -n "$VAR" ]` — `"0"` is NOT empty, so the naive test opens the browser and burns the
  one-time link.

#### If you also operate the hub

That is a server, not this skill — but three things cost real debugging and belong written down:
the **document root must never enumerate** (a listing rebuilt on every publish leaked the whole
collection: anyone given one artifact link could strip the filename and read everything), so a
static landing page is written once and never regenerated from the artifact list — see
`templates/store-landing.html`; an nginx `add_header` declared at `server` level is **discarded**
for any request handled by a `location` that declares its own `add_header` (the child context
replaces the parent's set instead of merging), which is how a `X-Robots-Tag: noindex` silently stops
arriving — put it inside the location and prove it with `curl -sI`, because the config text saying
`noindex` is not the header arriving; and artifacts are other people's HTML, so **any authenticated
interface must live on a SEPARATE hostname** from the one serving them. Sharing an origin would let
an artifact's JavaScript read the session cookie of whoever is looking at the gallery. Keep the two
apart, and have the interface host refuse `/a/` outright.

## 4. The render contract (verified against the Hermes desktop source)

**This section is Hermes-only.** In another agent (OpenCode, Claude Code, Cursor) there is no preview
pane, no artifact cards, no `hermes.send` and no app-injected theme tokens. There the deliverable is
the **published URL** and nothing else: write the `.html`, publish it, hand over the link. Do not try
to port the render mechanisms — they do not exist on the other side.

What does NOT change between agents: the quality bar (section 5) and the rule of publishing with a
public URL (section 6). The `wl-artifact` client is one bash script with `python3`: it behaves the
same from anywhere.

Full detail, evidence and failure modes: `references/hermes-render-contract.md`. The short list you
must not violate:

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

- `<title>`: two to four words. Never `"Name: explainer"`. Put the explanation in one sentence
  next to your link.
- Define colours as tokens on `:root`, redefine for dark mode under
  `@media (prefers-color-scheme: dark)` guarded by `:root:not([data-theme="light"])` and again
  under `:root[data-theme="dark"]`; give `body` an explicit background.
- Phone-first layout, 16px side gutter, no horizontal page scroll.
- Always author `.html`. A Markdown document is a source, not a deliverable: when asked to turn one
  into an artifact, **build a designed page from its content** — never transcribe the Markdown.

### The quality bar

An artifact is not delivered until it passes this. It is not aspirational: it is the list you check
before sending the link.

- **Real data, from the source.** If the number lives in a file, an API or a database, it comes from
  there. If it is estimated, say so. No sample figures, no placeholders.
- **Designed, not dumped.** Hierarchy, sections, tables and visualisations where a bare number does
  not explain itself. A wall of text, or transcribed markdown, is not an artifact.
- **Self-contained.** One `.html`, no external dependencies. Same served from the hub as opened on
  a phone.
- **Readable on a phone.** The most common case and the one that breaks most: tested at ~430px, no
  horizontal scroll, multi-column tables stacked. Measured, not eyeballed: 390 / 768 / 1366 px with
  `scrollWidth === innerWidth` and no text below 11px. The four usual causes (missing `viewport`,
  fixed-width SVG with text, wide tables, `pt` sizes) and the script that measures it:
  `references/responsive.md`. If the page also prints, put everything screen-only in `@media screen`.
- **Nothing hidden.** What is still unconfirmed is visible on the page. Do not hide or disguise it:
  the reader has to be able to tell what is firm from what is missing.
- **Iterable.** When correcting, the SAME slug: the URL you already shared keeps working and shows
  the new version (`-vN.html` keeps the old one). A new slug orphans every link you handed out.

## 6. After you deliver

**The rule that matters most: if the artifact is meant for someone — or for the user on another
machine — it is PUBLISHED, and what you give back is the PUBLIC URL. Never a local path.**
`/home/you/artifacts/x.html` is not a deliverable: it works on exactly one computer and dies with
it. If you made a page and did not publish it, you have not finished: run the publish step and hand
over the link. The only local path you may ever mention is when the user explicitly asked for a file
on disk.

Say in ONE sentence what the page is, or what changed on an update, and include the URL. Do not
narrate the mechanics — the frame is already on screen. If the artifact replaced a plain answer,
that is fine; if the user wanted both, the file goes via `MEDIA:`.

**Editing is a loop, not a new artifact.** Keep the SAME file path and the SAME slug, change the
file, publish again: the URL you already shared keeps working and now shows the new version (the old
one stays at `-v<N>.html`). Never "fix" something by inventing a new slug — that orphans every link
you gave out. Re-publishing identical content changes nothing at all.

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
- A "shareable link" that is a local file path → publish it, or it does not exist.
- A hub URL or a token pasted into a page, a repo or a chat → it lives in
  `~/.config/wl-artifact/config`, mode 600.

## References

- `references/hermes-render-contract.md` — what the Hermes frame really supports, with the source
  evidence and a working probe (read this before debugging a blank frame).
- `references/responsive.md` — making a page read well on phone, tablet and desktop (including pages
  generated by a print/PDF engine), and the measuring script that proves it.
- `references/claude-artifact-contract.md` — Claude's own Artifact tool prompt, extracted from the
  installed Claude Code bundle. Use it when matching Claude's behaviour precisely.
- `templates/artifact.html` — the starting file: theme tokens, dark mode, phone-safe layout,
  measured height, `hermes.send` bridge. Copy it, then delete what you do not use.
- `templates/store-landing.html` — the static landing for a hub's document root (see "If you also
  operate the hub"). It is written once and never regenerated.
