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

### Tier 3 — publishing to the artifacts hub

Ask whoever administers the hub for a **token**. One-time setup on this machine:

```bash
wl-artifact setup wlart_...       # writes ~/.config/wl-artifact/config, chmod 600
```

After that, publishing is one command:

```bash
wl-artifact publish ~/artifacts/informe.html informe-auditoria
# → https://<hub>/a/<your-user>/informe-auditoria.html
```

Read these before you hand a link to anyone:

- **The link IS the credential.** Whoever holds the URL opens it — no login, no un-sharing.
  Send it to the person, not to the room.
- **You write only your own namespace.** The server takes the owner FROM THE TOKEN: you cannot
  choose another user in the request, and you cannot touch their artifacts. Same slug by two
  people is two different artifacts, not a collision.
- **Updating keeps the link.** Publish the same slug again and the SAME url serves the new
  version; the previous ones stay at `-v<N>.html`, immutable. Do NOT invent a new slug to "fix"
  something: that is a new artifact and the link you already shared goes stale.
- **`rm` genuinely revokes.** It deletes the canonical file and every version, so every link you
  shared dies. There is no undo — treat it as revocation, not tidying.
- **The token never goes in the artifact, in a repo, or in a chat.** It belongs in
  `~/.config/wl-artifact/config` (600) and nowhere else. An API key in client HTML is a leak.
- **Your own catalog is local:** `wl-artifact catalog` builds a gallery on YOUR disk with a live
  cropped preview of each artifact, its REAL `<title>` (read from the artifact, not the filename),
  size, relative date, search, sort and copy-URL. It is generated by `scripts/build-catalog.py`
  from `templates/catalog-template.html`.
- **Never build a listing into the artifact, and never ask the hub to enumerate.** A page that
  lists what else exists turns one shared link into the whole collection. That was a real leak,
  not a hypothetical: an index regenerated on every publish handed anyone given one artifact
  access to all of them. The catalog belongs with the publisher, never in the document root.

**Admin-side notes** (you only need these if you run the hub): the stack is
`store` (nginx: landing, artifacts, reverse proxy to `/api/`) plus `api` (tokens, quotas,
versions, audit; stdlib + sqlite, no dependencies). The root is a STATIC landing
(`templates/store-landing.html`) written once and never regenerated from the file list. Every
location repeats its own `add_header` on purpose: `add_header` set at `server` level is DISCARDED
for any request handled by a `location` that declares its own, so a `X-Robots-Tag` up there
silently does nothing. Prove headers with `curl -sI`; a config that SAYS `noindex` is not a
header that ARRIVES. The api container must seed the landing into the shared volume, because
Docker copies an image's `/usr/share/nginx/html` contents into any empty volume mounted there —
without that step the site serves nginx's welcome page instead of the landing.

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

Say in ONE sentence what the page is, or what changed on an update. Do not paste the file path or
narrate the mechanics — the frame is already on screen. If the artifact replaced a plain answer,
that is fine; if the user wanted both, the file goes via `MEDIA:`.

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