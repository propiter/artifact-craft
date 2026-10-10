# Design — every artifact gets a point of view

A generated page has a look everyone recognises: centred cards on a grey background, one purple
gradient, Inter at every size, emoji as bullets, identical boxes in a grid. Nobody chose it; it is
what appears when nobody decides. This file is how you decide.

**The method, in order. Do not write CSS before step 4.**

1. **Read the brief.** Who opens this, on what (phone first), to do what? A client deciding on a
   quote, a team voting at lunch, a manager scanning a dashboard at 8 am: three different pages.
2. **Find the taste — in this order of authority:**
   1. What the user told you they like, now or before (your memory of them — see "Remembering
      taste"). It beats everything below.
   2. The project's own identity: a `DESIGN.md`, brand colours, a logo, an existing site or app.
      Match it; an artifact for a brand speaks that brand.
   3. The content. No preference and no brand → pick the direction below that fits what it is.
3. **Commit to ONE direction** from the eight below (or a deliberate blend of two, named). Say it
   in one line in your reply when it is not obvious: "Editorial, warm paper, serif headings".
4. **Write the tokens first**: the `:root` block with palette (light AND dark), type, radius,
   spacing, shadow. Everything after uses only those variables.
5. **Apply it all the way**: hierarchy, rhythm, the signature detail, empty/loading/error states,
   focus states, motion. Half a direction looks worse than none.
6. **Look at it**, at 390, 768 and 1366 px (`references/responsive.md` measures; a screenshot is
   what you judge). Fix what a designer would fix, then publish.

If your agent has a design skill — `impeccable` (any agent; `npx impeccable install` adds it to a
project), `claude-design` in Hermes — load it for anything client-facing or ambitious: it goes
deeper than this file. This file is the floor that holds when there is nothing else.

---

## Remembering taste

When the user reacts to a design — "too dark", "I love this one", "more sober", "use our green",
"no emojis" — that is a **standing preference**, not a one-off. Save it in your persistent memory
(whatever your agent offers) as a fact about them: "Prefers sober, editorial layouts; dislikes
emojis and gradients; brand green #0F9F74". Next artifact, step 2.1 finds it.

For a project, offer to write the direction down as `DESIGN.md` at its root (tokens + three lines
of intent) so every future page — by you or another agent — speaks the same language.

When the user has no opinion yet and the stakes are high (a client deliverable, a landing), build
the page in your chosen direction and offer, in one line, the closest alternative: "Want it
lighter and more playful instead?". Do not make them pick from a menu before they have seen
anything.

---

## The eight directions

Each one is complete: copy its tokens, then build. System font stacks only — they load instantly,
work offline, and look intentional when paired well. A web font is allowed when the direction
needs it (pinned Google Fonts URL, `display=swap`, the stack below as fallback).

Shared stacks:

```css
--sans:  ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
--serif: "Iowan Old Style", "Palatino Linotype", Palatino, Charter, "Bitstream Charter", Georgia, serif;
--mono:  ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace;
--grotesk: "Helvetica Neue", Helvetica, Arial, "Nimbus Sans", sans-serif;
```

### 1 · Editorial — reports, analyses, investigations, long reads

Feels like a good magazine: confident, calm, made to be read.

```css
:root { --bg:#faf7f2; --surface:#ffffff; --text:#1d1a16; --muted:#6b645a; --line:#e7e0d4;
        --accent:#b4441f; --accent-soft:#f6e6dd;
        --font-head: var(--serif); --font-body: var(--sans); --radius: 6px; --measure: 68ch; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#16140f; --surface:#1e1b16; --text:#efe9df; --muted:#a39a8c; --line:#332e26;
        --accent:#e2774f; --accent-soft:#3a251b; } }
```

Serif headings at large sizes (`clamp(32px, 6vw, 56px)`, weight 600, tight leading 1.05), sans
body at 17–18px, line-height 1.6, text column capped at `--measure`. Signature: a small-caps
kicker above the title, a drop of accent colour in pull quotes and key numbers, generous whitespace
between sections, thin rules instead of boxes. Avoid: cards everywhere, more than one accent.

### 2 · Swiss / precise — plans, specs, comparisons, decisions

Feels engineered: a grid, a hierarchy you can see, no decoration.

```css
:root { --bg:#ffffff; --surface:#f4f4f2; --text:#111111; --muted:#5f5f5f; --line:#dcdcd8;
        --accent:#e63312; --accent-soft:#fde8e3;
        --font-head: var(--grotesk); --font-body: var(--grotesk); --radius: 0; --measure: 72ch; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#0e0e0e; --surface:#181818; --text:#f2f2f2; --muted:#9a9a9a; --line:#2c2c2c;
        --accent:#ff5a3c; --accent-soft:#2e1510; } }
```

Bold grotesk headings, tight tracking (-0.02em), numbered sections (`01`, `02`) in the margin, a
visible 12-column grid on desktop that collapses cleanly, tables with hairlines only. One signal
colour used for exactly one meaning (the recommendation, the risk). Avoid: rounded corners,
shadows, gradients.

### 3 · Control room — dashboards, monitoring, metrics, live boards

Feels like an instrument: dark, dense, every number legible at a glance.

```css
:root { --bg:#0b0d14; --surface:#141826; --text:#e8ecf6; --muted:#8b94ad; --line:#252b3d;
        --accent:#7cf0c4; --accent-2:#8fa8ff; --warn:#ffcb6b; --bad:#ff7a90;
        --font-head: var(--sans); --font-body: var(--sans); --font-num: var(--mono); --radius: 14px; }
@media (prefers-color-scheme: light) { :root:not([data-theme="dark"]) {
        --bg:#f3f5fb; --surface:#ffffff; --text:#151a2b; --muted:#5b6480; --line:#dfe3ee;
        --accent:#0f9f74; --accent-2:#3a5bd9; --warn:#b7791f; --bad:#d1335b; } }
```

KPI tiles with the number huge (`font-variant-numeric: tabular-nums`, mono), the label small and
uppercase, a delta chip in green/red with an arrow AND a sign (not colour alone). Sparklines in
inline SVG. Status uses shape + colour. Signature: a soft glow on the one live element. Avoid:
more than six KPIs above the fold, pie charts, 3D.

### 4 · Warm product — landings, onboarding, consumer pages, invitations

Feels friendly and finished, like a good app's marketing site.

```css
:root { --bg:#fffaf5; --surface:#ffffff; --text:#2a2320; --muted:#7a6e66; --line:#f0e6dc;
        --accent:#ff6b4a; --accent-2:#3d7bff; --accent-soft:#ffe9e2;
        --font-head: var(--sans); --font-body: var(--sans); --radius: 20px;
        --shadow: 0 1px 2px rgba(42,35,32,.06), 0 12px 32px -12px rgba(42,35,32,.18); }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#17130f; --surface:#211b16; --text:#f6ede6; --muted:#b3a59a; --line:#352b23;
        --accent:#ff8a6e; --accent-2:#7aa2ff; --accent-soft:#3b231b; } }
```

Big rounded surfaces with soft layered shadows, a hero with one clear sentence and one button,
illustrations as inline SVG shapes in the two accents, pill buttons. Signature: one section on a
full-bleed tinted band. Avoid: stock-photo placeholders, more than two button styles.

### 5 · Quiet luxury — client proposals, quotes, premium offers, invitations to something formal

Feels expensive by restraint: space, contrast, few words.

```css
:root { --bg:#f7f5f0; --surface:#ffffff; --text:#14130f; --muted:#77736a; --line:#e3ded3;
        --accent:#8a6a2f; --accent-soft:#efe7d6;
        --font-head: var(--serif); --font-body: var(--sans); --radius: 2px; --measure: 60ch; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#0f0e0c; --surface:#171612; --text:#f1ede4; --muted:#a29c8f; --line:#2b2822;
        --accent:#c9a45c; --accent-soft:#2a2316; } }
```

Display serif at very large size and light weight (400), wide letter-spacing on small uppercase
labels (0.18em), hairline rules, prices set in the serif with old-style figures. Double the
whitespace you think you need. Signature: one thin accent rule under the title. Avoid: icons,
bright colours, anything bouncy.

### 6 · Playful — games, polls, events, quizzes, celebrations

Feels like fun was the point.

```css
:root { --bg:#fff8e7; --surface:#ffffff; --text:#1b1b3a; --muted:#5e5e86; --line:#1b1b3a;
        --accent:#ff4f79; --accent-2:#3dd6d0; --accent-3:#ffd23f;
        --font-head: var(--sans); --font-body: var(--sans); --radius: 18px;
        --shadow: 4px 4px 0 var(--line); }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#14142b; --surface:#1f1f3d; --text:#fdf6e3; --muted:#b4b4d6; --line:#fdf6e3;
        --accent:#ff6f91; --accent-2:#4fe0da; --accent-3:#ffd84d; } }
```

Thick outlines and offset hard shadows (`--shadow`), chunky headings (weight 800), colour blocks
from the three accents, buttons that press down on `:active` (translate 2px, shadow shrinks),
celebratory micro-motion on success. Signature: the result screen is a moment — big number, a
burst. Avoid: thin type, greys, long text.

### 7 · Technical — incident timelines, dev reports, logs, architecture notes

Feels like a well-kept terminal: precise, scannable, monospaced where it matters.

```css
:root { --bg:#0d1117; --surface:#161b22; --text:#e6edf3; --muted:#8b949e; --line:#30363d;
        --accent:#3fb950; --accent-2:#d29922; --bad:#f85149;
        --font-head: var(--sans); --font-body: var(--sans); --font-code: var(--mono); --radius: 8px; }
@media (prefers-color-scheme: light) { :root:not([data-theme="dark"]) {
        --bg:#ffffff; --surface:#f6f8fa; --text:#1f2328; --muted:#59636e; --line:#d1d9e0;
        --accent:#1a7f37; --accent-2:#9a6700; --bad:#cf222e; } }
```

Timestamps and identifiers in mono, a vertical timeline with dots on a 2px rail, status pills
(`resolved`, `investigating`) with text, code blocks with a filename header. Signature: a summary
box at the top with what happened / impact / fix in three lines. Avoid: decoration of any kind.

### 8 · Bold / poster — announcements, manifestos, one big idea, creative pieces

Feels like a poster on a wall: huge type, high contrast, a strong opinion.

```css
:root { --bg:#f2ede4; --surface:#f2ede4; --text:#0a0a0a; --muted:#3a3a3a; --line:#0a0a0a;
        --accent:#1f3cff; --accent-2:#ff3b1f;
        --font-head: var(--grotesk); --font-body: var(--sans); --radius: 0; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
        --bg:#0a0a0a; --surface:#0a0a0a; --text:#f2ede4; --muted:#c9c4ba; --line:#f2ede4;
        --accent:#6b80ff; --accent-2:#ff6a4f; } }
```

Headlines at `clamp(48px, 12vw, 140px)`, weight 900, uppercase, line-height 0.9, allowed to break
the grid; 2px black rules; a colour field behind one word. Signature: one element rotated or
oversized on purpose. Avoid: using it for anything that must be read carefully.

---

## Layout by kind of artifact

| Artifact | Default direction | Shape that works |
|---|---|---|
| Report / analysis | Editorial | Title + one-sentence verdict up top, a "key findings" block of 3–5, then sections; evidence in tables; what is still unknown, visible |
| Dashboard | Control room | KPI row (≤6) → the one chart that answers the main question → details below; filters at the top, sticky on desktop |
| Comparison / decision | Swiss | The recommendation first, then a comparison table with the winner column tinted, then the reasoning; on phone the table becomes one card per option |
| Plan / roadmap / timeline | Swiss or Technical | Phases as a horizontal track on desktop, vertical on phone; owners and dates in mono; the current phase highlighted |
| Proposal / quote | Quiet luxury | Cover (client, date, one line), scope in numbered sections, price block that stands alone, terms small, approval buttons per section with live data |
| Landing | Warm product | Hero (one sentence + one button) → three benefits → proof → the button again |
| Game / quiz | Playful | The play area is the hero; score and timer pinned; the result screen is designed as carefully as the game |
| Poll / form / RSVP | Playful or Warm | One question per screen on phone, big touch targets (≥44px), live results appear after voting |
| Incident / postmortem | Technical | Summary box → timeline → root cause → actions with owners |
| Announcement | Bold / poster | One message, set huge; details small below |

---

## Craft that separates designed from generated

- **Type scale**: pick 4–5 sizes and use only those. Headings with `clamp()`; body 16–18px; never
  below 11px anywhere (12px for anything a phone user must read). Line length 60–75 characters.
- **Spacing scale**: multiples of 4 (4, 8, 12, 16, 24, 32, 48, 64, 96). Space between sections is
  at least twice the space inside them — that is what makes groups readable.
- **Hierarchy by size and weight first, colour last.** If everything is bold or coloured, nothing is.
- **Numbers**: `font-variant-numeric: tabular-nums` in tables and KPIs; units smaller than the
  value; thousands separators in the reader's locale (`toLocaleString`).
- **Colour**: one accent with one meaning. Text contrast at least 4.5:1 (3:1 for large text).
  Never meaning by colour alone — add an icon, a sign or a word.
- **Dark mode is designed, not inverted**: surfaces lighten with elevation, shadows become borders,
  accents get lighter and less saturated.
- **States**: every live or interactive part has empty ("No votes yet — be the first"), loading,
  error ("Could not save — try again") and success states, written as sentences a person would say.
- **Focus and touch**: visible `:focus-visible` rings in the accent; touch targets ≥44px; nothing
  that only works on hover.
- **Motion**: 150–250 ms, ease-out, for feedback (press, appear, success). Respect
  `prefers-reduced-motion`. Motion that does not tell the user something is decoration — cut it.
- **Images and icons**: inline SVG drawn for this page, or none. No emoji as bullets or icons in
  serious work; no stock-photo placeholders ever.
- **Copy is design**: specific headings ("Revenue fell 12% in March" beats "Overview"), buttons
  that say what happens ("Approve section", not "Submit").

## The generated look — never ship it

Purple-to-blue gradients by default · every section a centred white card on grey · Inter or
system-ui at one weight for everything · emoji bullets · a grid of identical feature boxes with an
icon on top · glassmorphism with no reason · `box-shadow` on everything · lorem ipsum or "Sample
data" · a title like "Dashboard" or "Report" · more than two accent colours · centred body text.

## Before you publish

- [ ] The direction is named and every value comes from the tokens.
- [ ] Light and dark both look intentional.
- [ ] At 390 px: no horizontal scroll, nothing under 11px, targets ≥44px (`references/responsive.md`).
- [ ] The first screen answers "what is this and what do I do here" without scrolling.
- [ ] Empty, error and loading states exist and read like a person wrote them.
- [ ] You looked at a screenshot, not just the code.
