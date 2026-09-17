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
each format's real construction rules as you build. Paste a list from anywhere, see it priced
in three markets, group it by your own sections or by type in a list or a card grid, draw
sample hands against it, mark what you own and what the rest would cost, and compare any two
saved versions of it. A coach reads the list and says what it is short of, and why.

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

Early on, 153 tests passed and the build was clean — and the app still rendered a blank page
the first time I opened it in a browser.

`vite.config.js` set the base path only when `command === 'build'`, but `vite preview` runs
as a *serve* command. Preview hosted at `/` while the built HTML pointed at
`/mtg-companion/`, which meant the production build couldn't be verified locally at all. Two
more came out of the same session: the coach panel was sticky-positioned and covered the
hand it was telling the player to tap, and two empty battlefields consumed 190px on turn one,
pushing the hand off the bottom of a phone screen.

None of those would ever have failed a unit test. The full 27-beat tutorial is now walked end
to end in a headless browser as part of verification, asserting that each beat actually
advances and that no console errors fire. That became the rule for everything after it: 819
unit tests cover the logic, and nineteen browser specs drive the real interface for the parts
a unit test cannot see.

## Growing it into a real deck builder

The tutorial was the differentiator; the deck builder is where the app has to earn daily
use. It grew in deliberate steps, each one measured before it was called done.

**Import had to work on the first try.** Pasting a 99-card list originally fired 89
sequential requests and stalled. It now goes through Scryfall's collection endpoint in
batches of 75, matches double-faced cards by their front face, and, when a Commander list
arrives without a commander, offers the legendary creatures in it rather than refusing.

**Prices are everywhere, and only from markets that exist.** Scryfall carries three
(TCGplayer, Cardmarket, Cardhoarder), so those are the three shown, on every row, tile,
section and card sheet, with foil and etched fallbacks marked as such. A vendor Scryfall does
not carry is not invented.

**Sections are the person's, not the app's.** A card can live in "Ramp" or "Wincons" rather
than "Creatures"; renaming or dissolving a section moves its cards; the default grouping is
by type with lands last, where people look for them. This was the first change to the saved
schema, so it came with a versioned, additive migration chain and a rule that a newer file is
left alone rather than downgraded.

**Sample hands use the London mulligan** with a seeded generator, so a hand can be
reproduced. The deck must be fully loaded before the first draw; a half-loaded library would
quietly deal from fewer than 99 cards.

**Ownership is keyed by oracle identity,** not by printing, so owning any copy of a card
counts, and a deck reports "N to get · $X" against it.

**History is stored as id-and-quantity lists,** capped at thirty versions with automatic
checkpoints pruned first and the newest never pruned. Any two versions diff to added, removed
and changed cards with a price delta, and removed cards are still named because the diff
resolves every id across every version, not just the current deck.

**Data safety was measured to the byte.** Browsers cap `localStorage` without saying where.
The app measures its own use against the common limit, and when a write is refused it drops
automatic checkpoints one at a time, using the write itself as the oracle, until the save
lands or nothing is left to drop. A file that fails to parse is set aside and offered for
download, never overwritten. The test for this found the browser's real limit by probing.

**Performance was measured, not assumed.** A harness seeds a hundred distinct cards with
real images and twenty-five versions, throttles the CPU four times, and times every screen a
deck can be on, counting main-thread tasks over 50 ms separately. It found that each
keystroke in the version-label box re-rendered the whole history. After the fix, a character
costs 18 ms under throttle rather than 41, and a hundred-row list has 1,393 nodes rather than
2,185. It also showed that memoising rows did nothing measurable for a quantity tap, which
the README says plainly rather than claiming a win.

**Import reads what other sites write.** An Archidekt export puts the printing before
the category, `(soc) 180 [Creature]`, and the first parser only stripped a printing at the
very end of a line, so every name kept its set code and a whole deck crawled through the
fuzzy endpoint one request at a time. Markers are now peeled in any order and each one is
used: the printing goes to Scryfall as a set and collector number, which is exact and
returns the card the person owns; a category they made becomes a section; the commander
marker sets the commander.

**The app knows which build it is.** Every build carries its commit and publish time, and
the app checks for a newer one shortly after load and when the tab comes back into view,
offering a reload. This exists because the fix above was retried on the previous build and
nothing on screen said so.

## A first deck for someone who has never built one

The deck builder assumed you knew what you wanted. The first-deck flow does not. Four
short steps on the Decks tab, also reachable from Learn.

A **colour dial** walks the five colours in wheel order and names the pair between any two,
so "Blue and Black — Dimir" appears as you drag. It is a native range input over a
wheel-coloured strip, which makes it keyboard-driven and screen-reader-readable for free;
the five enemy pairs the strip cannot reach are chips beside it. Each colour has a page —
what it cares about, how it wins, what it is bad at, three cards that sum it up — and the
screen says that writing is the app's own. **Four questions** with two honest answers each
lean the dial toward the colours that play that way, and it can always be dragged back.

**Commanders** come two ways: a recommended list written for this app, two per colour choice
with a one-line reason, marked as a recommendation rather than a ranking and verified against
Scryfall by a script; and the most played list, live from Scryfall's popularity rank for
exactly those colours. Choosing one creates the deck. Then a **starting list by role** —
lands, ramp, draw, removal, "does your thing" — each with a target that adds up to 99, a
progress bar fed by the coach's own classifiers, and popular cards in the deck's colours
under a price cap. "Fill the rest" completes the skeleton and the deck opens in the editor,
legal and complete.

Nothing in it is invented. The staples come from Scryfall by the same oracle tags the coach's
classifiers were scored against, with a plainer fallback per role in case a tag slug changes.
The result is a deck the coach would call sensible rather than one anyone would call
optimised, and the screen says the numbers are a guide, not a rule.

**Adding cards shows the value of a pick before it is added.** The in-deck search listed
names alphabetically with a mana cost and nothing else. It now sorts by how played each card
is unless asked otherwise, because Scryfall carries its EDHREC rank on every card and "what do
people run in these colours" is the question a builder is asking; price, mana value, name and
release date are a select away. Every row carries its price in the deck's market, its type,
whether it is already in the deck and how many you own, and the results line totals what is
shown. Quick chips for type and price write into the query the box shows, so nothing hidden
is filtering; "Not in deck" and "Owned" are applied to what came back, and the line says how
many they hid. A strip above the box says where the deck stands by role, in the coach's own
counts, and pressing a role searches for it in the coach's own wording, so a chip and the
coach never disagree.

## A visual system with a paper trail

Two references were written for the app and now live in its repository: a universe and design
reference, and a set reference for *Reality Fracture*, with an original asset pack built from
them. The shell became the references' core theme, charcoal and parchment with restrained
antique gold, in five self-hosted open fonts under the SIL Open Font License. The references'
tokens sit in the stylesheet verbatim under their own names and the app's semantic tokens map
onto them, so a script can diff the documents against the stylesheet and say where they
disagree. Every emblem and ornament is the pack's own interface design, never an official
glyph, and every emblem is shown with a text label beside it, as both references require.

*Reality Fracture* is the first curated set theme: an indigo and silver shell with cyan as the
one accent, the set's own illustration and voice on the banner, and Hexhaven's five schools,
which are the five allied colour pairs, beside the colours in the first-deck flow with their
disciplines, virtues and horrors. It applies app-wide while the set is the season's focus and
retires by itself when the season moves on. The banner says the colours and lore are the app's
reading of public previews rather than official, and the set's alias is accepted as input and
never shown. A browser spec drives both shells on a desktop and a phone and fails if any asset
request does.

## Preparing for accounts without building them

The next step for this app is a version people sign in to. Two things had to change first,
and both were cheap now and expensive later.

**Where you are is in the address bar.** Navigation lived in React state: a deck had no link,
the back button did nothing useful, a reload lost the screen. Hash routes fix that with no
server, which is what GitHub Pages offers. A deck's analysis tab is `#/decks/<id>/analysis`,
a search is `#/cards?q=…`, and the card sheet is `?card=<id>` on any of them, as an overlay:
opening it pushes a history entry so the back button closes it. The parse and build
functions are pure and round-trip every shape; the browser spec drives the real address bar
through open, reload, back, forward, deep links and junk.

**Each deck is a document of its own.** The store was one blob rewritten whole on every
quantity tap, and last-write-wins on a single document is exactly what a sync backend cannot
reconcile. Now a root document holds the small whole-app things and each deck sits under its
own key with its own `updatedAt`. A save writes the one deck that changed; a corrupt root no
longer takes the decks with it; the old blob is split on first read and only rewritten once
every deck has landed. The backup file's shape is unchanged. The backend interface is a keyed
string store, so a server is one swap and carries the timestamps with it.

**Then the structure caught up with the features.** The browser suite, which had caught every
real regression, ran only by hand; it now gates the deploy in CI, in a real Chromium against
the built app. The 726-line editor became a 240-line editor and a folder of view components
with one row contract. The rarer deck screens became their own chunks, prefetched on idle so
the offline guarantee holds, and the Decks chunk halved. The coach's checks and the
first-deck flow's targets, two descriptions of the same sensible deck, became one skeleton
module with a test that says so. And a stepper, a section header and a chip became shared
components, with named layout modifiers replacing 104 of 165 inline style props; what is
left inline is data.

The routing change found a real bug on its first run through the existing specs: React
flushes a route change synchronously while a state update from the same effect is still
batched, so one render saw the new URL with the old deck list and sent every new deck
straight back to the list. The check now reads storage, not state.

The through-line is the same as the tutorial's: the coach's card classifiers are scored
against Scryfall's own tags rather than trusted; the accessibility sweep treats a state it
cannot reach as a failure, not a skip; and the perf harness reports the number that did not
move alongside the ones that did.

## Known trade-offs

Carried in `ARCHITECTURE.md` with a *when to revisit* column, as with the other projects here.

| Trade-off | Why |
|---|---|
| No synergy or "cards like this" recommendations | Doing it well means EDHREC-quality data, which has no public API. Scryfall-search heuristics would look authoritative while being mediocre. |
| No cross-device sync | No accounts means no server, no data to breach, no hosting cost. Export/import is the escape hatch. |
| Tutorial covers one matchup | One well-taught game teaches the fundamentals; more scenarios are content, not architecture. |
| Prices are Scryfall's daily aggregate | Live pricing needs a commercial feed. Daily is right for "is this deck expensive". |
| Three price markets, not every vendor | Only markets Scryfall carries are shown. Showing a vendor's name over a guessed number would look authoritative while being wrong. |
| Saved data lives in one browser's storage | A few megabytes, with the actual cap unknown until a write fails. The app measures use, recovers from a refused save, and nudges toward a backup rather than pretending the limit is not there. |

## Legal

Unofficial Fan Content permitted under the Wizards of the Coast Fan Content Policy.
Non-commercial, not approved or endorsed by Wizards. Card names, rules text, images and mana
symbols are the property of Wizards of the Coast LLC.
