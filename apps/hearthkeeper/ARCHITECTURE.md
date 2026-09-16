# Hearthkeeper — architecture

## What this is solving

A five-week beta with a moving level cap, a game client with no way to take a note, and no
beta feedback forum announced. The failure mode is not "no bugs found" — it is finding three
things during a dungeon run and reconstructing one of them an hour later, in a form nobody can
act on.

So the app optimizes for capture speed first, report quality second, and planning third.

## Shape

```
src/core/   pure functions, no React import anywhere
src/ui/     views; they read state and call actions, and hold no rules of their own
src/state.js  the one hook: load → act → persist
src/data/   content packs
```

`core/` never imports from `ui/`, and `ui/` holds no logic worth testing. That is what makes
84 unit tests possible without a DOM, and it is why the whole test suite runs in about a
second.

## Decisions

**Game data is a versioned pack, not code.** A beta's facts move under you — a phase date
lands, a zone's level range shifts, a dungeon gets named. Packs are JSON with a `packVersion`
and a `gameBuild` stamp; the app keeps a snapshot of the pack it last saw and can diff a new
one against it, so a tester opening the app after an update sees exactly what changed rather
than a silently different UI. Findings keep the build stamp they were logged under.

**Every data row carries provenance.** `announced` / `reported` / `carried-over` /
`unconfirmed`, surfaced inline next to the value, not buried in a footnote. During an
announcement window most "facts" are somebody's paraphrase, and a companion app that launders
a paraphrase into a certainty is actively harmful to the person filing the bug report. The
phase 2 date is the live example: "a couple of weeks" is an estimate, and the app says so
everywhere it uses it.

**Unknown is a distinct state from false.** The Skyborne Elves have one confirmed class per
faction and the rest unannounced, so a Skyborne Hunter is a *warning* ("that list is
incomplete") while a Tauren Mage is an *error*. A dungeon with no announced level range is
neither reachable nor unreachable — it is unknown, and it never lands in the untested pile
where it would nag forever.

**Coverage is scored against reach, not against the patch.** Only two of the three announced
zones are reachable even at the beta's final cap, and no raid is testable at all. Scoring a
tester against content nobody can enter produces a number that only ever goes down, so
unreachable content is listed with the reason and excluded from the denominator.

**The talent model stops at tiers.** Forever adds a 16-point talent milestone to the existing
11/21/31. Points start at level 10 at one per level, so 16 points is level 25 — which is above
the phase 1 cap of 20 and reachable only in phase 2. That arithmetic is the single most useful
thing this app computes, and it needs no per-talent data at all. Builds are stored as points
per tree, which is the part of the data that is actually public.

**Storage is the browser, behind an adapter.** Same position as my other local-first work: no
accounts, no server, nothing to breach, nothing to lose when a service shuts down. The cost is
no cross-device sync, and it is paid rather than hidden — a JSON export/import round-trips the
whole journal, imports merge by last-edit-wins so a laptop file and a phone file can be
combined, and a partially corrupt file restores the valid part and reports what it skipped.
A refused write (private mode, full quota) is surfaced to the user, not swallowed.

## Known trade-offs

| Trade-off | Why it is acceptable now | When to revisit |
| --- | --- | --- |
| No cross-device sync | The use case is one tester at one machine with a phone beside it; the export file covers moving between them | If merging exports becomes a routine weekly chore rather than an occasional one |
| Content pack is hand-compiled from announcements | The beta's data is not public in any machine-readable form, and no datamined source can be used responsibly here | When Blizzard publishes real patch notes or an API for the build — then packs get generated, not written |
| No per-talent data | It is unpublished and would be wrong within a week; the tier arithmetic delivers most of the value without it | Once trees are public and stable — the tree-points model already leaves room for it |
| `localStorage`, not IndexedDB | A five-week journal is kilobytes; quota failures are detected and surfaced | If a tester's journal approaches the ~5MB limit, or screenshots get attached to findings |
| Phase 2's date is an estimate | It is flagged `reported` everywhere it appears, and the app still works if it is wrong — the cap it implies is the only thing derived from it | The day Blizzard posts the date: change one line in the pack, and the diff view shows every user what moved |
| Export is markdown, not an API submission | There is no beta feedback API, and no forum was announced at beta start | If a structured feedback endpoint appears, the report module gains a second formatter |
| No test for the React layer | The views hold no rules; the smoke test covers the paths that matter end to end in a real browser | If a view starts making decisions instead of rendering them — that is the signal the logic leaked upward |

## Testing

- **84 unit tests** over `src/core/` — schedule resolution across every beta state, talent
  arithmetic against the phase caps, journal validation and near-duplicate detection, roster
  rules including the deliberately-unknown Skyborne case, coverage bucketing, report rendering,
  backup round-trips and merges, and the storage adapter's failure modes.
- **A browser smoke test** (`npm run smoke`) that loads the built app on a phone-sized
  viewport, logs a finding, checks the near-duplicate warning, adds a character, reloads, cuts
  the network, and confirms the app and the data are still there — then reruns the dashboard
  with the clock moved into each beta phase.

The unit suite earned its keep during the build: the round-trip test caught that an optional
level field was being stored as `0` (because `Number(null)` is `0`) and then rejected by its
own validator on the next import — a bug that would have quietly eaten findings on restore.
