# LiftUp — Machine Learning Approach

> **Status:** groundwork / design document. No model training or application code is
> described as "done" here — this document fixes *what* we build and *how we will
> judge it*, so that implementation can start from a decided target.
>
> **Scope owner:** AI / learning-model side of the team.
> **Companion documents:** [ML_APPROACH_COMPARISON.md](ML_APPROACH_COMPARISON.md) (why these approaches
> and not the alternatives).

---

## 1. What LiftUp is, and where ML sits in it

LiftUp is a mobile weight-training coaching app (Flutter client, Rust/Axum backend,
PostgreSQL, plus a Python ML service under [`server/`](../../server)). It promises
*personalised* training rather than a static program: it reacts to the loads, reps and
difficulty the user actually logs.

Three of the core user stories in
[INNOVATION_TRACK_ACTION_PLAN.md](../INNOVATION_TRACK_ACTION_PLAN.md) are ML-bearing:

1. *"I can generate a personalised training program and get dietary suggestions."*
2. *"I can film myself (or import a video), get a full analysis of my movement and advice to improve it."*
3. *"I can photograph my meal and get an estimate of calories and macronutrients."*

Everything else in the app (auth, session tracking, dashboards) is deterministic
product code and is explicitly **not** an ML problem.

### 1.1 What already exists in the repo

This matters because it sets the baseline the models must beat:

| Component | Path | What it currently does |
| --- | --- | --- |
| Pose extraction | [`server/app/services/pose_estimator.py`](../../server/app/services/pose_estimator.py), [`skeleton_analysis.py`](../../skeleton_analysis.py) | MediaPipe Pose, 33 landmarks per frame, exported as CSV (`frame, timestamp, keypoint_id, x, y, z, visibility`) — see [SKELETON_ANALYSIS.md](../../SKELETON_ANALYSIS.md) |
| Form scoring | [`server/app/services/pose_analyzer.py`](../../server/app/services/pose_analyzer.py) | **Rule-based**: joint-angle geometry → `depth`, `alignment`, `stability`, `tempo`, `range_of_motion` sub-scores + annotated output video |
| Exercise detection | `PoseAnalyzer._detect_exercise` | Heuristic on the angle-history signature |
| Coaching text | [`server/app/services/form_analyzer.py`](../../server/app/services/form_analyzer.py) | Hand-written per-exercise guidelines, mistakes and safety tips for 8 exercises |
| Deep-learning scaffold | [`server/app/services/i3d_analyzer.py`](../../server/app/services/i3d_analyzer.py) | I3D (Inflated 3D CNN) architecture, present but **untrained** — no weights in `data/models/` |
| Training-data collection | [`server/app/scraping/`](../../server/app/scraping) | yt-dlp based video scraper + PyTorch `Dataset`/`DataLoader` pipeline |
| Program adaptation | [`back/src/`](../../back/src) | Rust logic engine; progression rules, no learned model |

So today LiftUp is **100 % rules, 0 % learned parameters**, plus one empty deep-learning
slot. That is a perfectly good starting point and this document treats it as the
reference baseline rather than as something to throw away.

---

## 2. The ML problems, framed

We define three workstreams. They are deliberately ordered: **WS-1 is the EIP's
differentiator and the priority**; WS-2 is the one the product markets as
"the AI coach"; WS-3 is a convenience feature that should be bought, not built.

### WS-1 — Movement / form analysis from video *(primary)*

**Product question:** "Was that rep good, and what exactly should I change?"

**ML framing — two stacked tasks:**

| | Task A — Exercise & rep segmentation | Task B — Form fault detection |
| --- | --- | --- |
| Framing | Multi-class **classification** over a pose sequence (which exercise) + **change-point / peak detection** over the primary joint angle (rep boundaries) | **Multi-label classification** per rep — each fault is an independent yes/no |
| Supervision | Supervised (video-level label from the user's logged exercise, so labels are nearly free) | Supervised, weakly at first; labels come from annotation of scraped + consented user videos |
| Unit of prediction | One video clip | One repetition |
| Labels | `squat`, `deadlift`, `bench_press`, `shoulder_press`, `bicep_curl`, `lunge`, `plank`, `pushup` (the set already in `FormAnalyzer.supported_exercises`) | Per exercise, from `common_mistakes` in `form_analyzer.py`. Squat example: `knee_valgus`, `insufficient_depth`, `excessive_forward_lean`, `heel_rise` |

**Why multi-label and not "a form score":** a single 0–100 number is not coachable. The
user cannot act on "72". They can act on "your knees collapse inward on reps 4–6". The
overall score stays in the UI as a summary, but it is **derived** from the fault
predictions, not the model's output.

**Inputs / features.** We do *not* feed raw pixels to the model. The pose extractor is
the feature extractor, and the learned model consumes its output:

- **Per frame:** 33 landmarks × (x, y, z, visibility) from MediaPipe.
- **Derived geometric features** (scale- and position-invariant, so they generalise
  across body sizes, camera distance and framing):
  - joint angles: knee, hip, elbow, shoulder, ankle, trunk-vs-vertical;
  - left/right **symmetry** deltas on each of those angles;
  - normalised segment ratios (shoulder width as the unit of length);
  - per-rep **temporal** features: concentric / eccentric duration, pause at the
    bottom, tempo variance, velocity and acceleration of the primary joint;
  - **stability**: variance of the centre-of-mass proxy (hip midpoint) over the rep.
- **Context from the backend** (available, cheap, and it disambiguates): the logged
  `exercise_name`, `weight`, `reps` and `sets_data` from the `exercises` table, plus the
  user's `fitness_level`.

**Normalisation is load-bearing.** Camera angle is the dominant nuisance variable in
amateur gym footage. Mitigations, in order of preference: rely on angles rather than
raw coordinates; use MediaPipe's `z` to reject clips filmed too far off the sagittal /
frontal plane; and record the detected view as a feature so the model can learn
view-conditioned thresholds.

**Outputs.**
```
{
  "exercise": "squat", "exercise_confidence": 0.94,
  "reps": [
    { "index": 1, "t_start": 2.10, "t_end": 4.35,
      "faults": [ { "label": "knee_valgus", "p": 0.81, "frames": [78, 91] } ],
      "metrics": { "depth_deg": 104, "tempo_s": 2.25, "symmetry_delta_deg": 7.4 } }
  ],
  "summary_score": 78.5
}
```
This is a superset of what `/api/v1/video/analyze` already returns, so the Flutter
client's existing results page stays compatible.

**Success metrics.**

| Level | Metric | Target for v1 | Why this target |
| --- | --- | --- | --- |
| Task A | Exercise classification accuracy | ≥ 0.92 | Below this, the wrong rule-set is applied and feedback is nonsense |
| Task A | Rep count exact-match rate | ≥ 0.95 | Users verify this instantly; being wrong destroys trust |
| Task B | **Per-fault precision** | ≥ 0.80 | A false "your back is rounding" is worse than silence — see below |
| Task B | Per-fault recall | ≥ 0.60 | Acceptable to miss faults in v1; not acceptable to invent them |
| Task B | Macro-averaged F1 across faults | ≥ 0.70 | Keeps rare faults from being ignored |
| System | p95 latency, 10 s clip, server-side | ≤ 8 s | Must feel like "processing", not "a job" |
| Product | Agreement with a human coach on a held-out set of 100 reps | ≥ 75 % | The only metric that actually means "is the coaching good" |

**Precision is weighted above recall on purpose.** Telling a lifter their form is
dangerous when it is not makes them distrust the app and, worse, change a safe
movement pattern. Silence is the safe failure mode. Every fault prediction below the
precision threshold is suppressed in the UI rather than shown with a hedge.

**Non-goals for v1:** real-time (per-frame, in-session) feedback; injury prediction or
any diagnostic claim; exercises outside the 8 supported ones; multi-person video.

---

### WS-2 — Program personalisation & load progression

**Product question:** "What should I lift next session, and how much?"

**ML framing — explicitly staged, because the data does not exist yet:**

| Stage | Framing | Needs |
| --- | --- | --- |
| **v0 (ship first)** | Deterministic progression rules: double progression + 1RM-percentage targets, as sketched in [TECHNICAL_STATE_OF_THE_ART.md](../context_audit_and_compliance/TECHNICAL_STATE_OF_THE_ART.md) §2.2 | Nothing. Already implementable in the Rust engine |
| **v1** | **Supervised regression** — predict next-session load per (user, exercise): `ŷ = weight for target reps at target RPE` | ~10 sessions per user; a few hundred users |
| **v1** | **Binary classification** — will the user complete the prescribed set? (`p(success)`), used to pick a load at a chosen risk level | Same data |
| **v2 (optional)** | Ranking / recommendation for *exercise selection* (content-based first, hybrid later) | Many users × many exercises |

**Features** (all already in the schema — `users`, `workouts`, `exercises`,
`exercises.sets_data`):
user `fitness_level`, age from `birth_date`, `height_cm`, `weight_kg`, `fitness_goals`;
per exercise, the trailing history of load × reps × completion; estimated 1RM (Epley)
and its trend; session frequency and days since the last session for that muscle group;
accumulated volume over 7 / 28 days; self-reported difficulty.

**Outputs:** recommended load, rep target, and set count per exercise, each with a
confidence; plus an explanation string ("+2.5 kg — you completed 3×10 at 50 kg last
session with reps in reserve").

**Success metrics:** MAE on next-session load ≤ 2.5 kg (upper body) / 5 kg (lower
body) — i.e. inside one plate increment; Brier score on set-completion better than the
v0 rule baseline; and the product metric that actually matters, **adherence** (fraction
of prescribed sessions completed) measured against the rule baseline in an A/B split.

**Hard constraint — the model never prescribes unsupervised.** Learned load
recommendations are clamped by the rule engine: no jump above +10 % session-over-session,
no deload deeper than −20 %, and absolute caps by `fitness_level`. The model moves
within a safety envelope the rules define. This is non-negotiable for a product that
tells beginners how much weight to put on a bar.

**Non-goal:** reinforcement learning. It is the theoretically elegant fit for
progression (see the state-of-the-art doc §2.3) and it is unusable here: we cannot
explore on human bodies, we have no simulator, and an EIP timeline does not survive an
off-policy evaluation problem.

---

### WS-3 — Meal photo → calories & macros

**Product question:** "How many calories is this plate?"

**ML framing:** fine-grained food classification + portion/volume estimation →
nutrient lookup. **Recommendation: do not train this.** Use a third-party API
(Nutritionix, LogMeal, FoodVisor, or USDA FoodData Central for the nutrient database)
behind a thin adapter in the Python service. Rationale and the comparison that leads
there are in [ML_APPROACH_COMPARISON.md](ML_APPROACH_COMPARISON.md) §5.

Portion estimation from a single uncalibrated photo is the genuinely hard part and is
an unsolved problem at consumer accuracy; the honest product design is an estimate the
user corrects, with the correction stored. **If** those corrections accumulate into a
real dataset, revisit. In v1 the UI must present this as an estimate, not a
measurement.

---

## 3. Data requirements

| Source | Volume needed for v1 | Status | Notes |
| --- | --- | --- | --- |
| Scraped exercise videos | ~500–1 000 clips across 8 exercises | Tooling exists ([`app/scraping/`](../../server/app/scraping)) | Licence-checked only; see §4.3 |
| Annotated fault labels | ~100 reps per fault label, min. 2 annotators | **Not started — the critical path** | Needs an annotation protocol before any labelling |
| Beta-tester videos (consented) | Whatever 20 beta testers produce | Beta plan exists ([BETA_TEST_PLAN.md](../BETA_TEST_PLAN.md)) | The only *in-distribution* data we will have |
| Logged training data | ≥ 10 sessions × ≥ 100 users | Schema ready, data accumulating | WS-1 labels come free from here |
| Coach ground truth | 100 reps double-scored | Not started | Defines the ceiling for "is the coaching good" |

**The bottleneck is labels, not models.** Both WS-1 tasks are small-model problems; the
work is annotation. The roadmap therefore front-loads an annotation protocol and an
inter-annotator agreement check (Cohen's κ ≥ 0.6 per fault label before that label is
trusted) — a fault two experienced annotators cannot agree on is a fault we should not
ship.

**Scraped video is out-of-distribution.** YouTube tutorials are well-lit, well-framed
and performed by people with good form. Real users film vertically, in a dim gym, from
a bad angle, with bad form. A model validated only on scraped data will look excellent
and fail in production. Mitigation: scraped data for pre-training and for the *rare*
fault classes; **beta-tester data for validation**; and the held-out test set must be
real user video only.

---

## 4. Privacy, GDPR and ethics

Workout video is biometric data and training logs are health-adjacent, so both fall
under GDPR Art. 9 "special category" data — explicit consent, data minimisation,
erasure, portability. The project's [SECURITY_AND_LEGAL_AUDIT.md](../context_audit_and_compliance/SECURITY_AND_LEGAL_AUDIT.md)
covers the general posture; the ML-specific commitments are:

**4.1 Video.** Separate, explicit, opt-in consent for (a) analysing a video and
(b) retaining it for model training — two checkboxes, never one, and (b) defaults to
off. Analysis-only videos are deleted after the analysis returns; what persists is the
**pose keypoints and derived features**, not the footage. Keypoints are far less
identifying than video and are all the model needs. Retention: raw video for training
only with consent (b), max 24 months, deletable on request; the annotated output video
`pose_analyzer` currently writes to `data/output/` must inherit the same lifecycle —
*note that annotated MP4s are currently committed on the `feat/machine-learning`
branch, which should be corrected before any user video flows through that path.*

**4.2 Training data.** Pseudonymised: the training store keys on a per-user salted ID,
not `users.id`, with no email, display name or birth date. Erasure requests must be
honourable, so we keep a user-ID → sample-ID map in a separate store, and rows are
excluded from the next training run rather than requiring a retrain on request
(documented to the user as such).

**4.3 Scraped data.** Only Creative Commons / explicitly reusable sources, logged with
URL, licence and retrieval date; no re-publication of the footage; derived keypoints
only in any released artefact. A scraping tool that is easy to point at all of YouTube
needs this rule written down before it is used.

**4.4 No medical claims.** Output is coaching, not diagnosis. No injury-risk score, no
"you may be injured", no physiotherapeutic advice. Model-written feedback is drawn from
the reviewed phrase bank in `form_analyzer.py` rather than generated freely — the model
chooses *which* fault to report, humans wrote *what is said* about it.

**4.5 Bias and representativeness.** Scraped video skews young, male, able-bodied and
lean. Form thresholds derived from it may misjudge other body types (hip anatomy
genuinely changes safe squat depth; limb-length ratios change safe bar paths). We
record body-proportion features from the pose itself, report metrics sliced by body
proportion and sex where known, and treat an unexplained gap between slices as a
release blocker rather than a footnote. Accessibility intent is already stated in
[ACCESSIBILITY_STRATEGY.md](../context_audit_and_compliance/ACCESSIBILITY_STRATEGY.md); for ML this means seated or
adapted variants are **out of scope and must be declared out of scope in the UI**,
not silently scored as bad form.

---

## 5. Decision summary

| Workstream | Decided approach for v1 | Serving |
| --- | --- | --- |
| WS-1 form analysis | MediaPipe pose → geometric features → **gradient-boosted trees** per fault label, with the existing rule engine as both baseline and safety net; temporal model (1D-CNN / small LSTM on the angle sequence) evaluated as a v2 upgrade; I3D deferred | **Server-side**, FastAPI in [`server/`](../../server) |
| WS-2 progression | Rule engine v0 → **gradient-boosted regression + completion classifier** inside a rule-defined safety envelope | Server-side (Rust engine calls the Python service) |
| WS-3 nutrition | **Third-party API**, no in-house model | Server-side adapter |

Full justification, alternatives and trade-off tables: [ML_APPROACH_COMPARISON.md](ML_APPROACH_COMPARISON.md).

**The one-line version:** LiftUp's ML is *pose-based supervised learning on engineered
geometric features*, deliberately small, server-side, explainable, and bounded by rules
it is not allowed to override.
