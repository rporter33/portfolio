# Robert Porter — Selected Work

I run a solo recruiting practice in Denver, and I build the software it runs on.

That combination is the throughline here. Most of these projects exist because I hit a
problem in the recruiting business — a workbook that couldn't scale, a candidate pool
nobody was systematically working, a screening process that ate a day a week — and
decided to engineer my way out of it rather than buy a tool that almost fit.

This repository is a **showcase**, not a code dump. Each project below has a write-up
covering what it does, how it's built, and the decisions I'd defend in a review. Most of
the source is private, because it touches client and candidate data — happy to walk through
any of it directly. MTG Companion has nothing confidential in it, so that one is public and
linked below.

---

## Projects

### [Excel CES — Cost Estimating System](projects/excel-ces.md)
A mobile-first PWA that replaced a roofing contractor's estimating workbook.

Around 700 spreadsheet formulas reimplemented as a tested pricing engine, validated
against five real workbooks at **0.00 error**. Full role-based access model, price-history
auditing, and estimate snapshotting so catalog changes never rewrite historical bids.

`Next.js 15 (App Router)` · `Prisma 6` · `PostgreSQL/Supabase` · `Clerk v7` · `Tailwind` · `Vitest` · `Vercel`

---

### [Sourcing Engines — Lucent & PM Sourcing](projects/sourcing-engines.md)
Two Python pipelines that find candidates who aren't on LinkedIn, and score them
against a role without breaking hiring law.

The first pulls ~27,000 active Colorado trade licenses from the state's public open-data
API and detects newly licensed individuals on each run. The second is an LLM scoring
engine whose rubric was calibrated against **104 real interviews**, then blind-re-validated:
it correctly gated **20/20** compensation-mismatched candidates and rated **18/19** actual
hires viable, with a 36-point score separation between the two groups.

`Python` · `Claude API (Haiku)` · `Socrata open data` · `structured LLM output` · `corpus calibration`

---

### [MTG Companion](projects/mtg-companion.md) · [source](https://github.com/rporter33/mtg-companion)
A local-first Magic: The Gathering companion, built around the thing no existing tool does:
getting a brand-new player to their first game.

A 27-beat guided game teaches by playing — the user makes every decision while a coach
explains it. Around it sit a card reference, a deck builder that validates against ten
formats' real construction rules, and an offline life counter. Ban lists are read from
Scryfall at validation time rather than copied into the repo, because a stale copy fails
**silently**. The land recommender was calibrated against decks that demonstrably work after
the intuitive objective turned out to be measurably wrong — it recommended 27 lands in a
60-card deck.

`React` · `Vite` · `PWA` · `IndexedDB` · `Scryfall API` · `Vitest` · `GitHub Pages`

---

### [Anagnosis · ἀνάγνωσις](projects/anagnosis.md)
A local-first Ancient Greek reader that takes you from the alphabet to Homer.

Handwriting recognition, a 19-passage graded reader, a core frequency deck, and
pattern-adaptive spaced repetition — all running offline with no accounts, no server,
and no user data to lose. Learners own their progress as a JSON file.

`React` · `Vite` · `PWA / service worker` · `localStorage` · `spaced repetition`

---

## What these have in common

**I write the reasoning down.** Every project has an `ARCHITECTURE.md` or a blueprint
document explaining not just what was built but which trade-offs were accepted and when
to revisit them. The Excel CES architecture doc has a standing "Known Trade-offs" table
with a *When to revisit* column.

**I validate against reality, not vibes.** The pricing engine was checked against real
completed workbooks. The candidate scorer was re-run blind against a real interview
corpus with the outcomes stripped out, specifically to see whether it would reproduce
actual hiring behavior. When it disagreed once, I went and looked at why — and the
disagreement turned out to be correct.

**I take the compliance surface seriously.** Screening people with an LLM is a genuine
legal risk if done carelessly. The scoring engine is advisory-only by construction, scores
exclusively job-relevant signals, and refuses to consider age, family status, national
origin, or financial proxies — with those constraints written into the rubric itself rather
than bolted on afterward. During corpus analysis, protected details appearing in 41 of 104
interview records were recorded as a presence flag only and never entered any scored field.

---

## A note on what's here

Client names and candidate data are deliberately absent. The recruiting work involves real
people's applications and a real company's internal hiring data, none of which belongs in
a public repository — so the write-ups describe the engineering and the aggregate findings,
never the underlying records.

📍 Denver, Colorado
