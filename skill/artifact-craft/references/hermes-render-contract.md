# The Hermes render contract — verified

Everything here was verified against the source tree and a live browser probe on 2026-09-20,
Hermes v0.21.3 (git `3d0bdce9`), Claude Code bundle 2.1.278. Source paths are given so a future
session can re-verify cheaply instead of re-deriving.

## Two render paths, two different security postures

| Mechanism | What it is | Security |
|---|---|---|
| `::preview{file="..."}` | sandboxed `<iframe srcdoc>` inside the assistant message | `sandbox="allow-scripts"`, opaque origin, scripts live |
| Preview pane | Electron `<webview>` on the `persist:hermes-preview` partition | real browser, own cookie jar, no `allowpopups` |
| Remote / non-HTML target | sanitised + CSP, or the preview-attachment card | script-disabled |

Source: `apps/desktop/src/components/assistant-ui/inline-preview-directive.tsx` (the
`::preview` directive) and `apps/desktop/src/app/chat/right-rail/preview-artifact.tsx`
(`composeArtifactHtml`, fragment → minimal document shell).

For a **local HTML file** the directive builds a document and injects it via `srcdoc` into
`<iframe sandbox="allow-scripts">` — deliberately **no** `allow-same-origin`.

For **remote HTML** (`data:text/html;base64,...`) the app sanitises with DOMPurify
(`FORBID_TAGS: script, template, iframe, frame, object, embed`), strips `href`/`action`/`target`,
and prepends a CSP:

```
default-src 'none'; base-uri 'none'; form-action 'none';
img-src data:; media-src data:; font-src data:; style-src 'unsafe-inline'
```

No `script-src` at all — remote HTML is **inert**. This is why a widget that works locally can
arrive as a plain card through a remote gateway. Never make a widget the only path to the answer.
Source: `apps/desktop/src/lib/local-preview.ts`.

## What the sandbox actually allows — probe results

Probe: a `sandbox="allow-scripts"` iframe fed by `srcdoc`, exactly like the directive. Run with
headless Chrome; reproducible with any real browser.

```
origin        "null"                     ← opaque origin: the whole story
localStorage  THROW SecurityError: The document is sandboxed
              and lacks the 'allow-same-origin' flag
sessionStorage THROW SecurityError
indexedDB     THROW SecurityError
document.cookie THROW SecurityError
parent.postMessage  works               ← how hermes.send reaches the app
CDN <script src="cdnjs...">  LOADED     ← no CSP host whitelist
```

**Consequences, in order of how often they bite:**

1. **No browser storage.** Not "unreliable" — it throws, on first access, and takes the page with
   it. JS memory only.
2. **Relative sibling assets do not resolve.** The base URI is the app's, not the user's file, so
   `./app.js` and `./data.json` are dead. Inline everything; use absolute URLs for CDNs.
3. **No CSP whitelist.** Unlike Claude, any CDN host works. Cheaper to stay on cdnjs /
   jsdelivr / Google Fonts anyway: portable, cached, and immune to whatever a future release
   tightens.

## The theme prelude

The frame injects, before the page's own styles:

- the app's resolved theme tokens under friendly names — `--foreground`, `--muted-foreground`,
  `--accent`, `--border`, `--card`;
- the app font;
- `body` margin/padding 0 and a transparent background.

The page's own styles override all of it. So:

- **Widget** → use `var(--card)`, `var(--foreground)`, `var(--border)`. Dark/light and re-skins
  come free, and the artifact reads as part of the app.
- **Full page / poster / game** → override freely, but then you own contrast in BOTH schemes and
  must give `body` an explicit background.

Re-skinning the app repaints the frame, so never assume a fixed palette.

## Sizing

Measured from content, live. Constants, source `inline-preview-directive.tsx`:

```
MIN_HEIGHT 120 · MAX_HEIGHT 1200 · DEFAULT_HEIGHT 280
MAX_COLUMN_WIDTH 640 (max-w-160 = 40rem) · RESIZE_TOLERANCE 4
```

`height=N` in the directive only sets a **starting** height; measurement wins. Practical
consequences:

- Design for a 640px column at phone width. No horizontal page scroll — an overflowing widget is
  a layout failure, not a scrollbar.
- Lay content flush left with no centring wrapper, or width measurement measures the viewport.
- A `vh`-sized page will oscillate; the 4px tolerance only absorbs sub-pixel churn.

## Talking back

Documented source shape:

```html
<button data-hermes-send="get the price of ETH">ETH</button>
```

```js
window.hermes.send("now sort by date descending")
```

Both route through the composer's send path as a user turn with `display_kind=hidden`: the agent
wakes, the durable row exists (context, resume, audit in the DB), and **no bubble renders** — the
widget updating is the visible response. Caps: 500 chars per intent, one intent per frame per
second, token-gated. Prompt length is capped, so send a sentence, not a payload.

## `::preview` directive mechanics

- Parsed from the transcript; `::name{key="value"}` with `name` matching `[a-z][a-z0-9-]{0,63}`.
- Non-HTML targets and remote gateways fall back to the **preview-attachment card**, not a broken
  frame. That fallback is why local file access matters.
- The preview pane (`<webview>`) runs on the **user's own machine**, never the gateway host — so
  `localhost:PORT` inside it means the user's machine. Against a remote gateway that is usually
  nothing, or someone else's service. Say which machine you mean.

## Verification recipe

To re-check any of this later:

```bash
cd ~/.hermes/hermes-agent
grep -n "sandbox=" apps/desktop/src/components/assistant-ui/inline-preview-directive.tsx
grep -n "default-src" apps/desktop/src/lib/local-preview.ts
grep -n "MIN_HEIGHT\|MAX_HEIGHT\|MAX_COLUMN_WIDTH" apps/desktop/src/components/assistant-ui/inline-preview-directive.tsx
```

For a live probe of the sandbox, build a page that creates
`<iframe sandbox="allow-scripts" srcdoc="...">`, runs the storage/CDN tests inside it, and reports
via `parent.postMessage`; then read it with headless Chrome:

```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --user-data-dir=/tmp/probe-profile --virtual-time-budget=9000 --dump-dom \
  "file:///abs/path/probe.html"
```

Caveat: `--virtual-time-budget` starves real network waits — async `fetch` results can be missing
from the dump while `<script src>` loads are reported correctly (script loading is what the dump
waits on). Do not conclude "fetch is blocked" from a missing key; check CORS and the code instead.