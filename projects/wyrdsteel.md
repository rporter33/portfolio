# Wyrdsteel

A browser action RPG in which the gods of the north are soldiers rebuilt by machine, at the end
of an age-long winter. It is a spiritual successor to *Too Human* (Xbox 360, 2008): it keeps that
game's premise, loot and class depth, and fixes, one review complaint at a time, what its
critics faulted.

**[Play it →](https://rporter33.github.io/wyrdsteel/)** · desktop browser, keyboard and mouse or a
gamepad · works offline after the first visit and installs as a PWA.

<img src="images/wyrdsteel/boss-fight.jpg" width="640" alt="A boss fight in a rock-walled cavern, seen from above at the High preset. At the top, a wide health bar reads Hrungnir, the Stone-Hearted, with a state line beneath: plated, break the stone or stop the mending, then a smaller bar for his clay guardian, Mökkurkálfi. The stone giant winds up a sweep, shown as a wide red sector with a bright rim on the floor, and the player in pale blue plate stands inside it with a sword drawn. The clay guardian stands to the left.">

## At a glance

- **Problem:** *Too Human* had a premise worth a trilogy and a list of complaints critics
  agreed on: melee that steered itself, a camera that fought you, a 30-second unskippable death
  scene, bosses that one-shot you, and no sequel to fix any of it.
- **What I built:** one complete chapter (a hub, three zones, a three-phase boss, an ending and
  an endgame) with two classes, Diablo-style loot and a Human/Cyber aspect system, running on a
  deterministic simulation built from the start to support co-op.
- **Result:** 556 unit tests, golden replays, and a bot that plays the real controls. On every
  push the bot fights the boss forty times, clears every zone with both classes, and plays the
  whole chapter from a fresh level-1 character. The browser tests gate every deploy, one of them
  with the network turned off.
- **Source:** public — [github.com/rporter33/wyrdsteel](https://github.com/rporter33/wyrdsteel) · MIT licensed
- **Stack:** TypeScript · three.js (WebGL2, PBR, glTF) · Preact + signals · Web Audio · Vite · Vitest · Playwright · GitHub Pages

---

## The idea

I started from the reviews, not from a feature list. GameSpot, Eurogamer, Edge and others
agreed on a set of specific complaints, and each one became a design rule:

| Reviewed in *Too Human* | Wyrdsteel's answer |
|---|---|
| Melee on the right stick slid you toward the nearest enemy | Light, heavy, launcher and dodge on their own buttons; melee goes where you aim, with an adjustable soft-target assist and a hard lock that overrides it |
| A camera that fought you | A fixed 3/4 camera that never moves on its own; walls in the way fade |
| A 30-second death scene, and enemies that respawned | A 2.5 s Valkyrie, skippable after 0.3 s; cleared rooms stay cleared |
| Bosses that one-shot you | Every hit on a player is capped at a share of max HP, and content that breaks the cap fails validation |
| Bosses tougher, not smarter | A boss that watches how you fight and answers it |
| Seeing the other alignment meant a second playthrough | Swap aspects at a well, with separate skill points for each |

## The boss that reads you

Hrungnir watches his target in five-second spans: time spent close, time spent far away, and
dodges. At the end of each span he settles on a read (hugging, kiting, dodging or neither),
says it out loud, and weights the patterns that punish it fourfold. A player hugging his knees
gets shockwaves and a leap back into a boulder volley. A player kiting gets charges and summoned
shield-bearers. A pattern never runs three times in a row. The adaptation is meant to be
noticed and answered, so it reads broad habits rather than individual inputs.

Fairness is enforced in data rather than left to tuning. Each phase ends at an HP floor that no
blow, burn or vent can push past, and the change of phase is a two-second invulnerable roar, so
burst damage can't skip a phase. Every boss blow is telegraphed at least 800 ms ahead, and a
blow allowed to take more than 35% of max HP needs 900 ms. The pack validation test refuses
content that breaks either rule.

## Decisions I'd defend

**A deterministic simulation, before any content.** One function, `step(world, frame, db)`,
advances the game at 60 Hz. The core bans `Math.sin`, `Math.random`, `Date`, browser globals and
`Map`/`Set`, and a test scans the source to keep it that way. Randomness comes from named
streams: combat, AI, level, and one per player for loot. So adding a loot roll never changes how
an enemy behaves, and in co-op nobody fights over a drop. This was built first, in the second
milestone of eleven, because a simulation that drifts by one bit between browsers makes lockstep
co-op impossible and is miserable to fix later. The same property gives replays with hash
checkpoints, golden tests that pin outcomes, and a bot that plays the exact game a person plays.

**Balance is asserted, not hoped for.** The bot plays only through the same input frames a
controller produces, using a tactical policy, a button-mashing policy and a kiting policy. CI
asserts the boss contract on every push:
- The tactical bot wins 10 of 10 at the intended level, wearing gear of the quality a player
  actually finds.
- Each win takes 3–8 minutes.
- Holding attack wins none.
- No hit exceeds its cap.

The suite earned its keep. It found a cannon shell hitting its target twice, once directly and
once in its own blast. It found burn dealing a share of max HP, which against a boss was 160
damage a second on its own. It found enemy lobs aimed at where the player moved to rather than
where the warning was drawn. And it found a large body squeezed between pits being pushed out of
the room entirely.

**The bot plays the whole chapter, from level 1.** Balancing against a prepared character hid a
real problem. When I let the bot play from a fresh start, spending points and wearing its finds
as a player would, it reached the boss at level 14 still holding its level-2 starting blades.
Enemies dropped items too rarely, and the bot never walked over loot, just as a hurried player
might not. Raising the drop rate, scaling XP so each zone ends at the next one's level, and
softening the boss's first phase came out of that run, not out of guesswork. The run is now a
CI test for both classes, and the same bot can drive the real build in a browser through a
debug hook. That is how I played the full chapter end to end, including saving, reloading and
continuing.

**Forty enemies, a handful of draw calls.** Every copy of a model shares one instanced mesh
per material. Each copy is posed through an invisible proxy skeleton, and its bone matrices go
into a float texture, one row per copy. The vertex shader then skins each vertex by up to four of
those bones. Forty skinned, animated thralls cost the same draw calls as one. The first version
did this with rigid parts and took the busiest rooms from about 125 draw calls to 9–23. When the
characters became real skinned bodies, the same texture simply gained bone weights. A 40-enemy
brawl simulates in about 0.7 ms a step, against a budget of 1.5 ms.

**Animation that follows the simulation, not the other way round.** Characters use a CC0 clip
library on one shared skeleton, but clips are never played at their own pace. Each attack's
progress is mapped onto its clip so that the clip's moment of impact lands on the exact tick the
simulation deals the hit, whatever the attack's length. The game stays deterministic and the
animation always agrees with the damage numbers. Locomotion blends walk, jog and sprint by speed;
aiming and firing take over the upper body while the legs keep their stride. A unit test holds the
blend weights to one per half of the body, and it caught layers being dropped after they were
counted.

**Graphics raised to a console look, without losing the laptop.** The first release built every
mesh from primitives with toon shading and shipped no art at all. After it shipped I set a higher
bar: the look of an average Xbox One game. The renderer is now physically based, with per-zone
light, HDR image-based lighting, shadow maps, ambient occlusion, bloom, and torches and lava that
cast light. Rooms use CC0 texture sets and are sculpted per zone: masonry and banners in the
citadel, snow-laden spruce in the Iron Wood, rusted plate and furnace grates in the foundry,
broken rock and crystal in the roots. Four presets choose how much of that runs. Low keeps the
original budget and is what the browser tests run under software rendering, so the old guarantees
still hold. The art (about 13 MB) is fetched by preset and cached for offline play as it is seen;
it never enters the initial download, which stays at 262 KB of gzipped JavaScript.

**Generated characters without a rigging step.** Enemy bodies are meant to come from a text-to-3D
service. Its rigs would need every clip retargeted, so the asset build binds a generated T-posed
body to the game's own skeleton instead. It scales the body to the mannequin's height, refits the
skeleton's arms to the body's span, and copies bone weights from the nearest points of the
mannequin's skinned surface. Every clip then plays on every body. The binder was proven on a CC0
body before any credits were spent, and the generation script prints its cost and stops at a
credit cap. Until the bodies are generated, enemies are a tinted mannequin wearing armour built in
code.

## Testing

| Layer | What it covers |
|---|---|
| **556 unit tests** in Node | Damage, caps, statuses, juggles, the attack director, the boss's phases, reads and patterns, 100,000-roll loot distributions, skill trees, saves (including damaged files), zones, hazards and trials, animation timing and blending, plus source scans for determinism and IP hygiene |
| **Golden replays** | Committed hash checkpoints for scripted runs, the boss's opening among them. An outcome that changes fails until it is rebaselined on purpose |
| **16 balance tests** | The boss contract for both classes; every zone with each class; Wyrd Trials tiers; the whole chapter from level 1 |
| **2 browser specs** (Playwright) | The built game in Chromium at the Low preset: boot, keyboard and gamepad, combat, loot, menus by gamepad, death and respawn, save and reload, the refused-write toast and the draw-call budget; then installing it, cutting the network and playing offline |

Screenshot review caught what the tests didn't. Telegraph decals faded on wall-clock time while
the simulation slows when frames drop, so on a slow machine a warning could disappear before its
blow landed. They now run on simulation ticks. Cone warnings were also drawn narrower than the
blows they warned of, by as much as 100 degrees; they now draw the sector the hit really covers.

## Known trade-offs

Carried in the repository's `ARCHITECTURE.md`, each with a trigger for revisiting it. A sample:

| Trade-off | Why it's acceptable now | When to revisit |
|---|---|---|
| Balance verified by a bot, not by people | Every balance claim is tested on every push, so regressions show the same day | When real players arrive: the bot reads telegraphs perfectly, so human win rates will be lower and the boss may want softening |
| CC0 bodies and clips, with armour built in code | A large step up from boxes with no licensing risk, and every body shares one skeleton and one clip set | When generated or commissioned bodies arrive: they replace the bodies only, bound to the same skeleton |
| More than 120 draw calls at High | High is for discrete GPUs, where the extra shadow and ambient-occlusion passes cost little; Low keeps the old budget, asserted by the browser test | If a High-preset GPU misses 60 fps: merge static room meshes across materials with a texture atlas |
| Instancing through a patched stock shader | Draw calls stay flat as crowds grow | On a three.js upgrade that changes the shader chunks it patches; the draw-call test and screenshots are the alarm |
| Two of five classes; no co-op yet | A complete, tested chapter came first, and the session seam keeps co-op an addition rather than a rewrite | Next: lockstep co-op over WebRTC, then the Defender class |

## Legal

Unofficial fan work, not affiliated with or endorsed by Microsoft or Silicon Knights. *Too Human*
is named only to describe the inspiration; no names, levels, enemy designs or text from it are
used, and a test fails the build if the original's title or studio appear in game data. Gods,
places and creatures are named from Norse myth, which is public domain. All art is CC0
(Quaternius, ambientCG, Poly Haven, credited in the repository's `CREDITS.md`), and sound and
music are synthesized in the browser.
