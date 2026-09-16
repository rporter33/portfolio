# MTG Companion

A local-first Magic: The Gathering companion — card reference, format-aware deck builder,
play companion, and an interactive guide that teaches the game by playing it.

**Source:** [github.com/rporter33/mtg-companion](https://github.com/rporter33/mtg-companion)

**Stack:** React · Vite · PWA (service worker + manifest) · IndexedDB · localStorage · Scryfall API · Vitest · GitHub Pages

---

## The idea

Magic has excellent tools for people who already play. Scryfall is a superb card database.
Archidekt and Moxfield are strong deck builders. There are a dozen competent life counters.

What none of them do is get a new player to their first game. The official tutorial is a
video. The rulebook is 280 pages. The usual advice is "find someone to teach you", which is
fine if you know someone and useless if you don't.

So the differentiator here isn't the card search — it's the guided first game. Everything
else is the utility layer a player needs once they're actually playing.

## Four pillars

**Learn.** A 27-beat guided game against a scripted opponent. The player makes every play —
plays the land, chooses the block, casts the combat trick — with a coach explaining each
step. Behind it sit twelve lesson modules across four tracks (never played a card game,
Arena player new to paper, coming from another TCG, returning after years away) and a
44-term glossary wired through the entire app as tappable dotted underlines.

**Cards.** Search using Scryfall's own query syntax, so anything a player already knows
works unchanged. Full oracle text, official rulings, legality across ten formats, every
printing, prices.

**Decks.** Ten formats — six constructed, four in the Commander family — validated against
each format's real construction rules as you build.

**Play.** A life counter for games with physical cards. One to six players, commander damage
per source, poison and other counters, phase tracker, full undo, works entirely offline.

## The decision I'd most want to defend

The deck builder recommends a land count. The obvious way to compute one is to ask: how many
lands do I need to never miss a land drop?

I built that, then measured it against decks that demonstrably work:

| Deck | Lands | Makes the land drop |
|---|---|---|
| 60-card constructed | 17 | **49.9%** by turn 3 |
| 60-card constructed | 24 | **78.9%** by turn 3 |
| 100-card Commander | 37 | **54.5%** by turn 4 |

Nobody builds toward "never miss a land drop", because nobody can. A recommender aimed at it
asks for 27 lands in a 60-card deck, which no deck in the game plays. The intuitive objective
was simply wrong, and it was only visibly wrong because I checked it against reality instead
of shipping a principled-looking formula.

The objective that *does* describe how decks are built is narrower: have at least two mana
sources in your opening seven. Solving that hypergeometrically at an 85% threshold reproduces
the accepted ratios — **24 sources for 60 cards, 16 for 40, 40 for 100** — against the deck's
real size rather than a table lookup. Those three numbers are pinned as tests, so a future
change that looks more rigorous but stops matching real decks fails the suite.

Colour-source advice works the same way: rather than reproducing a published table, the app
solves the same question the table answers, for this deck's actual size.

## Ban lists are deliberately not in the repository

Banned and restricted status is read from Scryfall's per-card `legalities` object at
validation time, never from a copy in the codebase.

Ban lists change on a rolling announcement schedule. A hardcoded copy would be wrong within
weeks — and wrong *silently*, confidently passing a deck that a judge would disqualify. What
is encoded is only the structure that doesn't move: deck sizes, copy limits, singleton,
commander requirements, starting life. When Scryfall has no legality data for a format, the
validator reports `unknown` rather than passing.

Validation reports specific violations rather than a pass/fail:

> Commander decks must be exactly 100 cards. This deck has 99 — 1 short.
> Counterspell is outside your commander's colour identity (U).
> Vintage restricts Power Card to one copy, but this deck has 2.

The rules that are easy to get subtly wrong all have tests: the four-copy limit applies
across maindeck *and* sideboard combined, "a deck can have any number of cards named…" keeps
Relentless Rats legal in a singleton format, the commander counts toward the 100, and
colour identity includes mana symbols in the rules text, not just the mana cost.

## The tutorial is scripted, not simulated

Every beat declares its exact board state. The tutorial cannot desync, cannot present an
illegal board, and needs no network — its card data is bundled and its cards render in CSS.

The alternative is a rules engine. Covering even ten cards correctly is a multi-year project
— Forge and XMage are the evidence — and it would not teach any better. The trade-off is
recorded explicitly: the thing a real engine would unlock is free play, which this
deliberately does not offer.

Narrative continuity is enforced by tests rather than by re-reading:

- graveyards never shrink between beats
- life totals never rise (no card in the script gains life)
- no more than one land is played per turn — the tutorial teaches that rule, so it had
  better not break it
- every beat's click target actually exists in the zone it names

The graveyard and life invariants each caught a real authoring slip where dead creatures
silently vanished from the opponent's graveyard mid-lesson.

## Offline is a case, not a fallback

Cards referenced by a saved deck are **pinned** in IndexedDB and never evicted, so a deck
built at home opens on a phone with no signal at a game store — which is exactly where a life
counter and a decklist are needed and exactly where the wifi is worst.

Every cache read is best-effort: private browsing, disabled storage or a quota error degrades
to a cache miss, never to a broken app. The service worker caches the shell and card images
but deliberately does **not** intercept the Scryfall API, because the app's own cache layer
understands pinning and staleness in a way a blind HTTP cache cannot. The guide and life
counter never touch the network at all.

Card faces render in CSS from card data as well as loading Scryfall's images. That isn't a
placeholder — it's a fully readable card, it's what the tutorial renders from, and it's more
legible to a beginner than a 200-pixel scan. Cards measure themselves with container queries
and shed detail as they narrow rather than ellipsing "Grizzly Bears" down to "Gri…".

## Treating a free API as a guest

Scryfall is volunteer-funded and asks clients to be gentle. Every request in the app goes
through a single serial queue enforcing 100ms spacing regardless of how many components fetch
at once. 429 and 5xx retry with exponential backoff; 4xx doesn't, because it's a real answer.
A search matching nothing returns 404 and is surfaced as zero results, not an error. A
rejected request can't stall the queue behind it — there's a test for that specifically.

One requirement can't be met: Scryfall asks for a descriptive `User-Agent`, and browsers
forbid scripts from setting that header. That's documented rather than quietly ignored.

## What running it found that the tests didn't

153 tests pass, and the build is clean — and the app still rendered a blank page the first
time I opened it in a browser.

`vite.config.js` set the base path only when `command === 'build'`, but `vite preview` runs
as a *serve* command. Preview hosted at `/` while the built HTML pointed at
`/mtg-companion/`, which meant the production build couldn't be verified locally at all. Two
more came out of the same session: the coach panel was sticky-positioned and covered the
hand it was telling the player to tap, and two empty battlefields consumed 190px on turn one,
pushing the hand off the bottom of a phone screen.

None of those would ever have failed a unit test. The full 27-beat tutorial is now walked end
to end in a headless browser as part of verification, asserting that each beat actually
advances and that no console errors fire.

## Known trade-offs

Carried in `ARCHITECTURE.md` with a *when to revisit* column, as with the other projects here.

| Trade-off | Why |
|---|---|
| No synergy or "cards like this" recommendations | Doing it well means EDHREC-quality data, which has no public API. Scryfall-search heuristics would look authoritative while being mediocre. |
| No cross-device sync | No accounts means no server, no data to breach, no hosting cost. Export/import is the escape hatch. |
| Tutorial covers one matchup | One well-taught game teaches the fundamentals; more scenarios are content, not architecture. |
| Prices are Scryfall's daily aggregate | Live pricing needs a commercial feed. Daily is right for "is this deck expensive". |

## Legal

Unofficial Fan Content permitted under the Wizards of the Coast Fan Content Policy.
Non-commercial, not approved or endorsed by Wizards. Card names, rules text, images and mana
symbols are the property of Wizards of the Coast LLC.
