# Sourcing Engines

Two Python pipelines built for my own recruiting practice. The first finds candidates who
don't have a LinkedIn profile. The second reads a candidate's materials and scores their
fit for a specific role — without touching anything a hiring process is legally forbidden
to consider.

**Stack:** Python · Claude API · Socrata open data · structured LLM output · corpus calibration

---

## Part 1 — Licensed-trades discovery

Recruiting for skilled trades has a structural problem: the best electricians and plumbers
are working, not job-hunting, and many have no meaningful online professional presence. The
standard sourcing playbook finds nothing because it searches a surface these people aren't on.

Colorado, however, licenses tradespeople individually, and publishes the registry as public
open data.

The pipeline pulls every **active** skilled-trade license from the state's DORA dataset via
the Socrata API — about **27,000 individuals** across four license classes: journeyman
electrician, journeyman plumber, master plumber, and mechanical/HVAC.

Details that mattered:

**Company licenses are excluded on purpose.** Electrical Contractor and Plumbing Contractor
licenses are issued to businesses and carry no individual's name. Including them would have
padded the candidate list with entries that can't be recruited. They're deliberately dropped
here and reserved for a separate employer-signal pass.

**Paging is ordered, not just offset.** Requests sort by license number so that a dataset
mutating mid-crawl can't cause the pager to skip or duplicate records — the failure mode
that silently corrupts a bulk extract and is nearly impossible to notice afterward.

**Retries back off exponentially** (2s → 4s → 8s → 16s) across four attempts, and the
optional Socrata app token is handled as an optional rate-limit improvement rather than a
hard dependency.

**Snapshots are timestamped, and runs are diffed.** Each execution writes a dated CSV, and a
separate detection step compares it against the previous snapshot to surface *newly licensed*
individuals. Someone who just earned a journeyman card is a person whose career is in motion
— which is a materially better moment to make contact than a cold approach to someone
settled. The delta is the actual product; the full snapshot is just how you compute it.

The dataset is limited by design to license metadata — name, city, ZIP, license type, status,
issue date. No phone numbers, no email, no protected characteristics.

---

## Part 2 — Role-fit scoring

The second engine takes one candidate's text — a resume, an inbound application, a summary —
and returns a structured assessment: an overall fit score, 0–5 ratings on each job-relevant
signal, prose evidence quoting the source, a one-line summary, flags for human review, a
failure-mode tag when it's a pass, and a routing recommendation. It also returns token
counts, so cost per run is observable rather than assumed.

It runs on Claude Haiku — classification and scoring don't need a frontier model, and keeping
per-run cost in cents is what makes it usable across a whole inbound pipeline.

### The compliance posture is the design, not a disclaimer

Screening humans with an LLM is a real legal exposure if handled carelessly. The constraints
are written into the rubric the model receives on every call, not appended as a warning:

- The tool is **advisory only**. It ranks candidates for a human to review and is instructed
  never to speak as though it is deciding.
- It scores **only job-relevant signals**. Age, "recent grad" phrasing, gender, race, national
  origin, and financial, credit, marital, or family proxies are explicitly excluded.
- "Stability" — a criterion that slides into age and family-status discrimination if left
  vague — is operationalized as a specific observable behavior: does the person complete a
  full sales cycle and finish what they start.

During the corpus analysis phase, protected or financial details appeared in **41 of 104**
interview records. Each was recorded as a yes/no presence flag and **never copied into any
scored field**.

### Calibrating against reality

The interesting part wasn't building the scorer. It was discovering the rubric was wrong.

The initial version treated *no commission history* as a heavy negative — the intuitive read
for a commission-only sales role. So I structured the client's real interview history into a
job-relevant corpus: **104 interviews**, comprising all 28 hires and offers read in full with
transcripts, all 24 substantive shortlist candidates, and a 52-candidate sample of rejections
spanning the failure types.

The data said the opposite:

| Outcome | n | commission proven | **willing** | **averse** | unclear |
|---|:--:|:--:|:--:|:--:|:--:|
| Hired + offered | 28 | 18% | **50%** | **0%** | 32% |
| Shortlist | 24 | 42% | 21% | 33% | 1% |
| Rejected (sample) | 52 | 21% | 38% | 23% | 9% |

Half of all actual hires had **no** commission track record. Only about one in five did. But
**zero** hires were commission-*averse* — candidates who wanted a base salary or declined
full-commission pay.

The predictive signal wasn't experience. It was aversion. This employer trains the
salesperson, so inexperience is trainable and reluctance is disqualifying — two things that
look similar in a resume and are opposite in outcome. The rubric was rebuilt to separate them.

A second finding fell out of the same pass: the most common failure across the pipeline
wasn't skill at all. Reliability problems — no-shows, ghosting after a tentative yes, fading
across follow-ups — were flagged in **41 of 104** interviews, making it the single largest
practical drain on the funnel and worth its own detection signal.

### Blind re-validation

Recalibrating a scorer on a corpus and then evaluating it on that same corpus proves nothing.
So the scorer was re-run against the corpus with **outcome, recruiter verdict, and the
reliability field stripped out** — scoring only on background, compensation evidence, drive,
follow-through, and quotes:

| Check | Result |
|---|---|
| Commission-averse candidates correctly gated | **20 / 20 (100%)** |
| Real hires scored viable | **18 / 19 (95%)** |
| Score separation | hires avg **66** vs. comp-averse avg **30** |

The single apparent miss was not a miss. The one offer-stage candidate the scorer declined
to route to the primary role was routed to canvassing instead — which is what actually
happened to that person in reality.

### One conclusion I had to write down against my own interest

**Outcome ≠ fit.** A large share of "rejected" candidates were rejected for logistics — they
took another job, moved out of state, had a life event. Those are not fit failures, and a
scorer that learned to reproduce the pipeline's Status field would be learning the wrong
target. The tool rates fit. It should not be graded on reproducing outcomes, and I'd rather
state that limitation plainly than quote a cleaner accuracy number.

---

## Note

All figures here are aggregate. The per-candidate records, interview transcripts, outreach
drafts, and license extracts are gitignored in the private repositories and are not
reproduced in this write-up.
