# Hearthkeeper

A local-first field companion for the **World of Warcraft: Forever** (Classic+) beta —
September 17 to October 21, 2026.

It does three things a beta tester actually needs and the game client does not do:

1. **Catches findings before you lose them.** A title is enough to log one; severity, zone,
   level, character, steps and expected/actual are optional and can be filled in later.
2. **Tells you what is worth testing right now.** The beta runs at a level 20 cap and then a
   level 30 cap, so most of the announced content is out of reach for the whole test. Coverage
   is scored against what the live phase can actually reach, never against the full patch.
3. **Writes the report for you.** Findings export as forum-ready markdown, grouped by severity,
   stamped with the build they were seen on.

Everything runs in the browser. No accounts, no server, no analytics, no network calls at all.
Your journal is a JSON file you export and own.

## Running it

```bash
npm install
npm run dev      # local dev server
npm test         # 84 unit tests over the core logic
npm run build    # static build in dist/, deployable to any static host

npm run smoke    # end-to-end browser checks against dist/ (needs: npm i -D playwright)
```

## Layout

```
src/core/     pure logic, no React — schedule, talents, journal, coverage, report, storage
src/ui/       the views: dashboard, journal, roster, coverage, data
src/data/     versioned content packs (game facts, each row carrying a confidence flag)
scripts/      end-to-end smoke test
```

The split matters: every rule the app enforces — which phase is live, what a level cap can
reach, whether a race/class pairing is legal, what a report looks like — is a pure function
under `src/core/` and is unit-tested without mounting a component.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the decisions and the standing trade-offs.

## On the game data

Every zone, dungeon, raid, phase and talent tier in `src/data/` carries a confidence flag:

| Flag | Means |
| --- | --- |
| `announced` | Blizzard said it. |
| `reported` | Coverage said it, or it was paraphrased from a statement. |
| `carried-over` | Assumed unchanged from Classic; not confirmed for Forever. |
| `unconfirmed` | Placeholder. |

Nothing here is datamined and nothing is under NDA — it is compiled from the BlizzCon 2026
announcement and public coverage. Per-talent data is deliberately absent: it is not public, it
would churn every build, and a companion that guesses at it is worse than one that admits the
gap.

Hearthkeeper is an unofficial fan tool, not affiliated with or endorsed by Blizzard
Entertainment.
