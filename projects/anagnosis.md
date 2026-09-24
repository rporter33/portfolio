# Anagnosis · ἀνάγνωσις

A self-contained path from your first Greek letter to reading Homer, Plato, the tragedians,
and the New Testament.

## At a glance

- **Problem:** Greek learning tools stop at the vocabulary drill; the gap that stalls learners
  is between knowing words and reading a real passage.
- **What I built:** an installable, offline reader that runs from the alphabet, with
  handwriting recognition, through a 72-word core deck and spaced repetition to a 19-passage
  graded reader.
- **Result:** no accounts, no server, nothing to breach — learners own their progress as a
  JSON file that restores across two entirely different runtimes.
- **Source:** private — happy to walk through it.
- **Stack:** React · Vite · PWA (service worker + manifest) · localStorage · no backend

---

## The idea

Most Ancient Greek learning tools stop at the vocabulary drill. The gap that actually stalls
learners is between *knowing 300 words* and *reading a real passage* — where you meet
unfamiliar syntax, no glosses, and no context for why the sentence is shaped that way.

Anagnosis is built to close that gap specifically. It contains:

- The 24 letters, with handwriting recognition for stroke practice
- A core frequency deck of 72 high-value words
- A **19-passage graded reader** with historical context alongside each text
- Pattern-adaptive spaced repetition
- Audio support

## Local-first, and that's the interesting constraint

**All learner data lives in the browser.** No accounts, no server, no database, nothing to
breach and nothing to lose when a service shuts down.

That's a real architectural position, not a shortcut. It has a cost — no cross-device sync —
and the design pays that cost deliberately rather than pretending it away:

**Portability is the export story.** Learners back up and restore their progress as a JSON
file from the Vocabulary tab. They own their progress as a *file*. Backups from the original
Claude-artifact version of the app restore into this build unchanged, and vice versa — the
format is stable across two entirely different runtimes, which is the property that makes
the export a genuine escape hatch rather than a checkbox.

**Storage is behind an adapter.** The app uses a host-provided per-user store when one exists
and falls back to `localStorage` otherwise. Swapping to IndexedDB if a learner's data ever
outgrows localStorage limits is a single adapter change, and it's noted as a known limit
rather than discovered later.

**It genuinely works offline.** The service worker and manifest make it installable on a
phone, and letters, writing practice, lessons, the full 19-passage reader, the core deck, and
review all run with no network. This matters for the actual use case — studying on a train,
on a plane, in a library with hostile wifi.

## Optional AI, structured so it can't leak a key

A "Live Analyze" feature lets a learner paste or photograph a passage for AI analysis. The
default posture is that this is *optional* and the rest of the app never depends on it.

Two ways to supply credentials, in descending order of how much I'd recommend them:

1. A proxy endpoint (`VITE_ANTHROPIC_PROXY_URL` or `VITE_OPENAI_PROXY_URL`) that accepts the
   provider's request body and attaches the key server-side. This is the recommended path for
   any public deployment.
2. An in-app key field storing a learner's own key in their browser only — convenient for
   personal use, and documented as *worse* than the proxy rather than presented as equivalent.

The model can also be set at build time for accounts with different model availability, and
the provider is swappable between Anthropic and OpenAI at runtime.

## Engineering notes

Pure logic is extracted into `anagnosis-core.js`, separate from the React layer in `App.jsx`,
so the rules — spacing intervals, scheduling, scoring — are unit-testable without mounting a
component tree. Vite is configured with `base: "./"` so the built output works under a subpath
without modification, which is what makes it deployable to GitHub Pages or Cloudflare Pages
with no config changes.

## Roadmap

Recorded audio for the 24 letters, 72 core words, and 19 passages, to replace browser speech
synthesis — the current text-to-speech is serviceable but wrong about pitch accent, which
matters for a language people read aloud. IndexedDB storage adapter if learner data ever
approaches localStorage limits.
