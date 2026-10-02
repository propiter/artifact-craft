# Claude's Artifact contract — extracted, not remembered

Source: the Artifact tool prompt inside the installed Claude Code bundle
(`~/.local/share/claude/versions/<ver>`, an ELF build; `strings -n 8` then grep). Extracted
2026-09-20 from 2.1.278. Then re-read the tool prompt before quoting it as current — it ships
with the CLI and changes.

Skill constants found in the same bundle, verbatim:

```js
AN="artifact-design", P1e="artifact-diagramming", Py="artifact-capabilities",
xhe="workshop", BKr="whiteboard", jKr="prototype", rVt="dataviz", z1="code-review"
```

So Claude's page contract lives in a skill named **`artifact-design`**, with
`artifact-capabilities` for the runtime (`window.claude.*`) layer and `artifact-diagramming` for
diagrams. That naming is the model this skill's structure follows.

## When Claude publishes (the gate)

- "when a page would be clearer than terminal text, or when the person or their team would **use**
  the page rather than only read it, such as collecting input, tracking what people change, or
  showing live data."
- Claude **may publish without being asked** because artifacts start private — but see the
  exception: content that "could mislead or cause harm if shared further: anything that imitates a
  real organization, person or record, and anything the person presented as sensitive" is built as
  **files**, with the person deciding whether it gets a URL.
- Finished work meant for other people is **not finished** while it exists only in terminal
  scrollback or a local file → publish it, and publish **even when the request is phrased as a
  question** ("can you write up the plan?").
- A write-up headed for a channel or a thread still gets a page so the post can carry the link.
- **Counter-case:** "the person asks only for Claude's own verdict, such as 'should we ship
  this?', and names no one else who will read it" → answer in the terminal, offer the page in one
  line, do not publish.
- Verdict/advice the person will act on themselves, right away, in their own code → not a page.
- Apps, sites, dashboards and games → always a page.

## Safety line

Never publish: impersonation of a real person or organisation (name, branding, byline, domain);
fabricated records, receipts or reviews presented as genuine; forms or flows collecting
credentials or payment details under false pretences; content targeting a private individual.
Refused whether Claude wrote it or the person supplied it, whatever purpose is claimed. If
publishing is refused, Claude does not suggest other ways to host or share.

Also: **never publish a file Claude did not write without reading it in full.** "A request for
privacy is a reason to read before publishing, not an exemption."

## The page contract

- `<title>`: two to four words. Never `"Name: explainer"`. The explanation goes in `description`.
- Colours as tokens on `:root`; dark mode under `@media (prefers-color-scheme: dark)` guarded by
  `:root:not([data-theme="light"])`, and again under `:root[data-theme="dark"]`. `body` gets an
  explicit background.
- Layout works at phone width: 16px side gutter, no horizontal page scroll.
- **Format**: always `.html`. `.md` only when a loaded skill explicitly asks. A Markdown document
  supplied by the person becomes a **designed page** — "rather than transcribing the Markdown one
  to one".
- **Size**: rendered page ≤ 16 MB (`_d = 16777216`); embedded `data:` URIs count.
- **Thumbnail** (optional): `<link rel="artifact-thumbnail" href="thumb.png">` within the first
  8 KB of the file, next to `<title>`; PNG/JPEG about 1200×630, ≤ 1 MB, referenced by relative
  path. A second tag with `media="(prefers-color-scheme: dark)"` sets the dark variant. Without
  it, a screenshot is used.

### External resources — Claude's CSP

Scripts **only** from:

- `https://cdnjs.cloudflare.com` (preferred)
- `https://cdn.jsdelivr.net/npm/`
- `https://cdn.tailwindcss.com`
- `https://code.jquery.com`

Stylesheets only from `https://fonts.googleapis.com`, font files from `https://fonts.gstatic.com`.

**Everything else is blocked with no visible error** — unpkg and esm.sh included, any stylesheet
or image from those four hosts included, and every `fetch`/`XHR`/`WebSocket` to an outside host,
a library's own runtime fetches included. So: inline all other CSS and JS, embed assets as `data:`
URIs. A library loads as a UMD build pinned to an exact version, placed **before** any inline
script that uses it:

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/react/18.3.1/umd/react.production.min.js"></script>
```

The sandbox also **blocks downloads the page starts itself** (`<a download>`, `data:` and `blob:`
links, script-driven saves) — "Claude never offers a file through a plain link." To give someone a
file, use a runtime capability or a real download host.

Mermaid renders natively from ```` ```mermaid ```` fences or `<pre class="mermaid">` — no library.

### Browser storage — where Claude and Hermes diverge

Claude: "`localStorage`, `sessionStorage` and IndexedDB **work**, but each artifact has its own
origin… It can come back empty, or the accessor can throw… so Claude wraps every read and write in
try/catch and makes the page render correctly without it." Used only for per-viewer conveniences —
a remembered tab, a collapsed section, an unsent draft — never for state that must persist
reliably, be shared, or be read back.

Hermes: **all of it throws, unconditionally** (opaque origin — see
`references/hermes-render-contract.md`). Do not port a Claude page's storage calls. Any state that
must survive is tier 3.

### Versioning, updates, publishing

- Same **file path** → same URL, republished in place. A different path creates a new artifact.
- An update must first `read` (or have published) the artifact in this session; publishing blind is
  refused.
- A republish reaches already-open views, carrying page state where possible. A save made *from the
  page* makes the local file stale → the next publish **conflicts**, and Claude re-reads, merges,
  republishes.
- After publishing: the app shows a card with the title and link. "Claude says in one sentence
  what the page is, or what changed on a republish. Claude does not paste the URL unless the person
  asks."

### Runtime capabilities (the tier-3 layer)

Depending on what is enabled, a published page can read the person's live or connected data,
remember what people do on it, keep state viewers share, know who is viewing, ask Claude a
question, store files people add, or hand the viewer a file to save. Declared via `capabilities`,
implemented as `window.claude.*`, documented in the `artifact-capabilities` skill. **State that
must persist, be shared, or be read back belongs here, not in browser storage.**

There is also an artifact database: a published page's code can keep a small shared DB read and
written through a skill action instead of republishing the page to change records.

## What Hermes has no equivalent for

These are the real gaps, and they are why tier 3 exists:

| Claude | Hermes |
|---|---|
| Hosted URL per artifact, private by default | no URL — a local file |
| Share menu / access levels (private, org, anyone-with-link) | nothing; sharing = deploying |
| Version history, conflict detection on republish | edit the file in place, no versions |
| Comments on a page, wake-on-republish, watch | nothing |
| `window.claude.*` runtime capabilities + shared DB | nothing; a deployed service instead |
| Asset store, multi-file artifacts, server-side asset copy | single file; inline or CDN |
| `type_url` artifact types (deck, document, design system) | nothing; build from scratch |

Reproducing those is a server decision (`dokploy` skill), not a rendering one. Everything the
*rendering* contract needs — single file, tokens, phone width, no hidden downloads, one-sentence
hand-off — is reproducible today and is what `artifact-craft` enforces.