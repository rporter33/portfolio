# Hearthkeeper

A local-first field journal for testers in the *World of Warcraft: Forever* (Classic+) beta,
September 17 to October 21, 2026.

**[Open the app →](https://rporter33.github.io/hearthkeeper/)** · works offline, installs as a
PWA, and never sends anything anywhere.

<img src="images/hearthkeeper/dashboard.png" width="450" alt="The Hearthkeeper dashboard during beta phase 1. A card shows the phase 1 level cap of 20, marked announced, with 31 days of beta left and the cap rising to 30 in 11 days. Three tiles read 0 findings logged, 0 open blockers and 0% of reachable content touched. A Next list suggests a zone with no findings and three race and class combinations never rolled. A table of talent tiers shows 11 points testable in phase 1, 16 and 21 points in phase 2, and 31 points not in this beta.">

## At a glance

- **Problem:** a five-week beta with a moving level cap, a game client with no way to take a
  note, and no feedback forum announced. The failure mode isn't finding nothing — it's finding
  three things in a dungeon run and reconstructing one of them an hour later, in a form nobody
  can act on.
- **What I built:** an installable offline app that logs a finding from a title alone, tells a
  tester what the live phase can actually reach, and writes the forum-ready report.
- **Result:** 84 unit tests over a pure logic core, a browser smoke test that cuts the network
  mid-run, tests gating every deploy, and every game fact labelled with where it came from.
- **Source:** public — [github.com/rporter33/hearthkeeper](https://github.com/rporter33/hearthkeeper) · MIT licensed
- **Stack:** React · Vite · PWA (service worker + manifest) · localStorage · Vitest · GitHub Pages

---

## The idea

A beta tester needs three things the game client doesn't do, in this order:

1. **Catch findings before they're lost.** A title is enough to log one; severity, zone, level,
   character, steps and expected/actual can be filled in later. A near-duplicate of something
   already logged in the same place is caught on the way in.
2. **Know what's worth testing right now.** The beta runs at a level 20 cap and then a level 30
   cap, so most of the announced content is out of reach for the whole test.
3. **Write the report.** Findings export as forum-ready markdown, grouped by severity, steps
   renumbered, stamped with the game build they were seen on.

So the app optimizes for capture speed first, report quality second, and planning third.

## The thing most worth computing

Talent points start at level 10, one per level, so the phase 1 cap of 20 is exactly 11
points — the first tier. Forever's **new 16-point tier needs level 25**, which only exists after
the cap rises to 30 in phase 2. A tester who stops at the phase 1 cap never sees the headline
change to the talent system. The app works that out from two numbers and puts it on the
dashboard, with no per-talent data at all.

The same arithmetic runs over content. Of the three announced zones, one is a starting area,
one is barely reachable at the beta's final cap, and one has no announced level range. No raid
is testable. **Coverage is scored against what the live phase can reach, never against the full
patch** — unreachable content is listed with the reason and left out of the denominator, because
a completion number that can only go down is a number people stop reading.

## Decisions I'd defend

**Game data is a versioned pack, not code.** A beta's facts move under you: a phase date lands,
a zone's level range shifts, a dungeon gets named. Content ships as JSON packs stamped with the
game build. The app keeps a snapshot of the last pack it saw and diffs a new one against it, so
an update shows exactly what changed rather than a silently different screen.

**Every fact says where it came from.** During an announcement window most "facts" are
somebody's paraphrase, and a tool that launders a paraphrase into a certainty misleads the person
filing the bug report. Every zone, dungeon, raid, phase and talent tier carries a flag, shown
next to the value rather than in a footnote:

| Flag | Means |
|---|---|
| `announced` | Blizzard said it. |
| `reported` | Coverage said it, or it was paraphrased from a statement. |
| `carried-over` | Assumed unchanged from Classic; not confirmed for Forever. |
| `unconfirmed` | Placeholder. |

Nothing is datamined and nothing is under NDA. Per-talent data is deliberately absent: it isn't
public, it would churn every build, and a tool that guesses at it is worse than one that admits
the gap.

**Unknown is a different state from false.** A new race has one confirmed class per faction and
the rest unannounced, so an unannounced pairing is a *warning* ("that list is incomplete") while
a pairing the game rules out is an *error*. A dungeon with no announced level range is neither
reachable nor unreachable; it's unknown, and it never lands in the untested pile where it would
nag forever.

**Local-first, and honest about the cost.** No accounts, no server, no analytics, no network
calls. The price is no cross-device sync, so the export is built to carry that weight: a JSON
file round-trips the whole journal, imports merge by last edit so a laptop file and a phone file
can be combined, a partially corrupt file restores what's valid and reports what it skipped,
and a refused write (private mode, full storage) is shown to the user rather than swallowed.

## Testing

Every rule the app enforces — which phase is live, what a level cap can reach, whether a
race/class pairing is legal, what a report looks like — is a pure function in a folder that
never imports React. That's what makes **84 unit tests** possible without a DOM, and the suite
runs in about a second. A browser smoke test loads the built app at phone size, logs a finding,
checks the near-duplicate warning, adds a character, reloads, **cuts the network**, confirms
the app and the data are still there, then reruns the dashboard with the clock moved into each
beta phase. Pushing to `main` runs the tests before anything deploys.

The unit suite earned its keep during the build: the backup round-trip test caught an optional
level field being stored as `0` (because `Number(null)` is `0`) and then rejected by its own
validator on the next import — a bug that would have quietly eaten findings on restore.

## Known trade-offs

Carried in the repository's `ARCHITECTURE.md`, each with a trigger for revisiting it. A sample:

| Trade-off | Why it's acceptable now | When to revisit |
|---|---|---|
| No cross-device sync | One tester at one machine with a phone beside it; the export file covers moving between them | If merging exports becomes a weekly chore rather than an occasional one |
| Content hand-compiled from announcements | The beta's data isn't public in any machine-readable form | When Blizzard publishes real patch notes or an API — then packs get generated, not written |
| Phase 2's date is an estimate | It's flagged `reported` everywhere it appears, and only the implied level cap depends on it | The day the date is posted: one line in the pack, and the diff view shows every user what moved |
| Export is markdown, not an API submission | There's no beta feedback API | If a structured feedback endpoint appears, the report module gains a second formatter |

## Legal

An unofficial fan tool, not affiliated with or endorsed by Blizzard Entertainment, and contains
no game assets.
