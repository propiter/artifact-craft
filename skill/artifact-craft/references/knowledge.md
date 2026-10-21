# Projects and their documents — pages that KNOW something

A project groups the pages and the documents of one topic and belongs to the whole team. Pages
published into it answer from its **public** documents (`A.ask`, `A.docs`, `knowledge: true`); the
team (in the app) and agents (`wl-artifact ask`) consult **all** of them. API table and rules:
"A page that KNOWS" in SKILL.md. The AI recipes and helpers (`explain`, `busy`, the not-live
branch) in `references/ai.md` apply here unchanged.

## 1. The workflow — from "here are the docs" to a page

1. **Is there a project?** `wl-artifact projects`. If the topic has one, use it — even if the user
   did not mention it. A second project for the same topic splits what the team knows.
2. **No project, and the topic will have more than one page or documents?** Create it with a
   short slug (it goes in commands) and a title people recognise.
3. **Choose the documents** (section 2) and upload them: `wl-artifact docs add <p> <files|dirs>`
   (internal) and `… --public` for what visitors may learn. Supported: md, txt, html, csv, tsv,
   json, yaml, rst, pdf, docx. Folders are walked; hidden folders, `.git` and `node_modules`
   skipped; `--as <path>` names the folder inside the project.
4. **Read it before writing.** `wl-artifact ask <p> "…"` for facts; `wl-artifact search <p> "…"`
   for the passages. The page you write is built FROM them: real names, real figures, real
   modules — not your general knowledge of the topic.
5. **Build the page** — designed content first; add `A.ask` / grounded AI only where the reader's
   own input matters (SKILL.md, "Decide what the page NEEDS").
6. **Publish into the project**: `wl-artifact publish page.html <slug> --project <p>` (or
   `move <slug> <p>` for an existing page — the link does not change).
7. **Prove it on the URL**: ask the live page something only the public documents answer, and
   something only an internal one does — the second must come back as "not in the documentation".
8. **Tell the user** in two lines: the link, the project, and which documents you made public.

## 2. Choosing what is public

Ask of every document: *would I put this on the product's website?*

| Public | Internal (default) | Never upload |
|---|---|---|
| what it is, what it does, modules, plans with list prices, how it works, integrations, brand and voice, FAQs, published case studies | meetings, decisions, roadmap debates, prices quoted to a client, proposals, client names and numbers, team, metrics, contracts, chat exports | credentials, `.env`, exports with passwords or tokens, personal data that has no reason to be there |

- Upload the **curated** material first (a docs folder, a product overview) — it answers better
  than a raw chat dump, and a page's answer is only as good as its top passages.
- A raw export (Discord, WhatsApp, Slack) is internal at most, and often better left out: it is
  long, noisy and full of credentials. If the user wants it, upload it internal and say so.
- When the client refuses a file for credentials it prints the file and line. **Report it to the
  user**: those secrets are in their notes in plain text, and if they are real they should be
  rotated. Do not "fix" it by deleting lines from their files yourself.
- Visibility is per document and reversible: `wl-artifact docs public <p> <path|folder/>`,
  `docs internal …`, `docs rm …`.

## 3. Recipes

All of them assume the helpers from `references/ai.md` and a `live` check. Each shows the sources
— that is what makes an answer trustworthy.

### Sources line — reuse it

```js
function showSources(el, sources) {
  el.replaceChildren();
  (sources || []).slice(0, 3).forEach(s => {
    const li = document.createElement("li");
    li.textContent = s.title + (s.heading && s.heading !== s.title ? " › " + s.heading.split(" › ").pop() : "");
    el.appendChild(li);
  });
  el.hidden = !(sources && sources.length);
}
```

### Ask the product — an assistant inside a product page

The section of a product, pitch or onboarding page where a reader asks anything.

```js
const r = await busy(askBtn, "Buscando…", () => A.ask(question.value, {
  system: "Respondé en español, en 2 a 4 frases, como un especialista del producto. " +
          "Si no está en la documentación, decilo y sugerí hablar con el equipo.",
  onText: (piece, sofar) => A.md(answer, sofar),
}));
A.md(answer, r.text);
showSources(sourcesList, r.sources);
```

Offer three example questions as buttons (the ones prospects really ask) — an empty box gets few
questions. One call per click.

### A pitch adapted to each client, grounded in the product

The team reuses ONE page for every prospect: they type company, sector and main pain, and the page
rewrites its key sections. Everything else on the page is static and designed.

```js
const o = await busy(btn, "Preparando…", () => A.ai.json({
  system: "Sos un estratega comercial. Usá SOLO lo que dicen los documentos sobre el producto. " +
          "No inventes cifras, clientes ni precios. Español, frases cortas.",
  prompt: "Empresa: " + company + "\nRubro: " + sector + "\nDolor principal: " + pain +
          "\nDevolvé JSON {headline, problem, how: [3 frases], proof, next_step}.",
  knowledge: true,
}));
headline.textContent = o.headline;          // textContent: the model's text is data
```

The hub finds the passages from the prompt, so put the topic words in it (sector, pain). Keep a
"Restore original" button.

### Objection helper — for the person presenting

```js
const r = await A.ask("Objeción del cliente: \"" + objection + "\". ¿Cómo la respondo?", {
  system: "Dame una respuesta para decir en voz alta (máx. 60 palabras) y, aparte, el dato " +
          "de la documentación que la respalda. Si no hay respaldo, decilo.",
});
```

### FAQ / search box — no AI, no quota

```js
const hits = await A.docs.search(q.value, 5);
results.replaceChildren(...hits.map(h => {
  const art = document.createElement("article");
  const t = document.createElement("h3"); t.textContent = h.heading || h.title;
  const p = document.createElement("p"); p.textContent = h.text.slice(0, 280) + "…";
  art.append(t, p); return art;
}));
```

Instant and free: right for "find in the documentation", a glossary, or as the fallback when
`ai_rate_limited` arrives.

### A chat that knows the product

```js
const chat = A.ai.chat({ system: "Sos el asistente de <producto>. Español, breve.", knowledge: true, keep: 12 });
const text = await chat.send(msg, (p, sofar) => A.md(bubble, sofar));
showSources(bubbleSources, chat.sources);
```

The hub searches with the LAST user message, so a follow-up like "¿y cuánto cuesta?" searches
"cuánto cuesta" — fine for most chats; for long sessions, nudge users to ask complete questions.

### Internal tools are NOT pages

"Ask everything we know, meetings included" is for the team: it already exists as the project's
chat in the app (`wl-artifact gallery` → Proyectos → the project) and as `wl-artifact ask`. Do not
build a public page over internal documents — a page cannot see them, by design.

## 4. Checks before you hand it over

- `wl-artifact project <p> | grep PUBLICO` lists exactly the documents you chose — no more.
  Anyone on the team can flip visibility from the app, and a page answers from whatever is public
  at the moment it is asked; check at the end, not only when you uploaded.
- `(await A.ai.info()).project` is your project, and `public_docs` is the number you expect.
- A question answered by a public document returns it in `sources`.
- A question only an internal document answers comes back as "not in the documentation".
- The page works with the AI parts disabled (`ai_off`, quota) — the designed content still reads.
