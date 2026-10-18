# LiftUp — Comparison of Candidate ML Approaches

> Companion to [ML_APPROACH.md](ML_APPROACH.md), which states the decision. This document
> is the reasoning: what we compared, against which criteria, and why the alternatives
> lost. Keep it updated when a decision is revisited — a comparison that does not record
> rejected options is not a comparison.

**Scoring legend.** `+++` strong / `++` good / `+` acceptable / `−` weak / `−−` disqualifying.
Dev effort and cost are rated for *this* team on *this* timeline: a small student team
where the ML side is one person, with no GPU budget assumed.

---

## 1. Context constraints that decide most of this

Before any table: four constraints eliminate more options than any accuracy argument.

| # | Constraint | Consequence |
| --- | --- | --- |
| C1 | **We have ~0 labelled in-domain data today.** | Any approach needing 10⁴+ labelled samples is not a v1 option. |
| C2 | **The team's ML capacity is one person, part-time, on an EIP schedule.** | Approaches whose *failure mode is silent* (deep nets that train but learn the wrong thing) cost more than their accuracy gains. |
| C3 | **Feedback must be explainable.** | "Score 72" is not a product. The approach must localise a fault to a joint and a time. |
| C4 | **Wrong safety advice is the worst outcome.** | Precision > recall; a rule-based floor must remain. |

---

## 2. WS-1 — Form analysis: modelling approach

Candidates, all consuming MediaPipe pose output except E which consumes pixels:

| | A. Rule-based geometry *(status quo)* | B. Gradient boosting on per-rep features | C. Temporal NN on pose sequence (1D-CNN / LSTM / small transformer) | D. Pose-based graph NN (ST-GCN) | E. Video CNN end-to-end (I3D / VideoMAE) |
| --- | --- | --- | --- | --- | --- |
| Accuracy potential | + | ++ | +++ | +++ | +++ |
| Labelled data needed | none | ~100 reps / fault | ~500–1 000 reps / fault | ~2 000+ | ~10 000+ clips |
| Dev effort | done | low | medium | high | high |
| Training cost | none | minutes, CPU | ~1 h, 1 GPU | GPU days | GPU weeks / rental |
| Inference latency (10 s clip) | ~pose cost only | ~pose cost + ms | pose + ~50 ms | pose + ~100 ms | 2–10 s, GPU-dependent |
| Explainability | +++ (the rule *is* the explanation) | ++ (SHAP → "knee angle drove this") | − (needs attention/saliency work) | − | −− |
| Handles novel faults | − (must be hand-coded) | ++ | +++ | +++ | +++ |
| Robust to camera angle | − (thresholds are view-specific) | + (view as a feature) | ++ | ++ | ++ |
| Team skill fit | +++ | +++ | ++ | + | + |
| Debuggability when wrong | +++ | ++ | + | − | −− |
| Cold-start (works on day 1) | +++ | + | − | −− | −− |
| **Verdict** | **Keep as baseline + safety net** | **Chosen for v1** | **Planned v2** | Rejected for now | **Deferred** |

**Why B wins v1.** It is the only option that converts the small, expensive label set
we can realistically produce (C1) into a measurable gain over the existing rules, while
keeping per-feature attribution that maps onto a coaching sentence (C3). Gradient
boosting on ~40 engineered geometric features per rep trains in minutes on a laptop,
makes overfitting visible rather than silent (C2), and degrades to the rule baseline by
construction if a fault head underperforms its precision floor (C4).

**Why not C yet.** A temporal model is the right end state — form faults *are* temporal
patterns, and hand-engineering per-rep aggregates throws away sequence information.
It is a v2 item purely for data reasons, not architectural ones. Promote it the moment
any fault label has ~500 annotated reps.

**Why E (I3D) is deferred despite being already scaffolded.** The repo contains a full
I3D implementation in [`server/app/services/i3d_analyzer.py`](../../server/app/services/i3d_analyzer.py) with no trained
weights. Finishing it would require Kinetics-pretrained weights plus fine-tuning on
thousands of labelled clips, GPU time we do not have, and — decisively — it predicts a
clip-level quality score, which is the one output shape the product cannot use (C3): it
cannot say *which joint*, on *which rep*. The honest options are to keep it as a
documented experiment or delete it; it should not be presented as working. **Recommendation:
keep the file, mark it experimental in its docstring, exclude it from the v1 serving path.**

**Why pose-based beats pixel-based generally, for us.** MediaPipe has already solved the
hard perception problem and is permissively licensed, maintained, and fast. Starting
from 33 landmarks instead of pixels cuts the data requirement by orders of magnitude,
removes most appearance bias (lighting, clothing, skin tone, gym background), and
means the model cannot learn a shortcut like "this person looks experienced". That last
point is a fairness argument, not just an accuracy one.

### 2.1 Rule-based vs learned: the hybrid actually shipped

The decision is not "rules *or* ML". The serving path is:

```
video → MediaPipe pose → geometric features
                              ├── rule engine  → always runs, always shown
                              └── GBT per-fault → shown only where precision ≥ 0.80
                                                   and clamped by rule-engine sanity checks
```

Rules give day-one coverage, a fallback when pose confidence is low, and a defensible
answer for every fault we have not yet labelled. The learned heads add the faults rules
cannot express (coordination, asymmetry, tempo degradation across a set). Neither is
redundant.

---

## 3. WS-2 — Program personalisation: recommender approach

| | A. Rule-based progression *(double progression / %1RM)* | B. Content-based (user & exercise attributes) | C. Collaborative filtering (MF / ALS) | D. Hybrid (content + CF) | E. Gradient-boosted regression on history | F. Reinforcement learning |
| --- | --- | --- | --- | --- | --- | --- |
| Accuracy potential | + | ++ | ++ | +++ | +++ | +++ (theoretical) |
| Data needed | none | small | **many users × items** | many | ~10 sessions × ~100 users | an environment we do not have |
| Cold start (new user) | +++ | ++ | −− | ++ | + (needs own history) | −− |
| Dev effort | done | low | medium | high | low–medium | very high |
| Latency | µs | ms | ms (precomputed) | ms | ms | — |
| Infra cost | none | negligible | periodic retrain | retrain + serving | negligible | — |
| Explainability | +++ | ++ | − | + | ++ (SHAP) | −− |
| Safety / clampability | +++ | ++ | + | + | ++ | −− |
| Team skill fit | +++ | +++ | ++ | + | +++ | − |
| **Verdict** | **v0, and the permanent safety envelope** | Useful for *exercise choice* | Rejected for v1 (C1) | v2+ | **Chosen for load prediction** | **Rejected** |

**Note on the problem shape.** The load-progression question is a *time-series
regression per user*, not a recommendation problem — which is why E beats the
recommender family on the thing users notice most. Collaborative filtering only earns
its place for *exercise selection* ("users like you also do Romanian deadlifts"), and
it cannot work until the user base is large; with 20 beta testers it has nothing to
collaborate on. Content-based selection gets us the same feature with no cold-start
problem, so it is the v1 answer if exercise selection is in scope at all.

**On RL.** [TECHNICAL_STATE_OF_THE_ART.md](../context_audit_and_compliance/TECHNICAL_STATE_OF_THE_ART.md) §2.3
identifies RL as a candidate, and conceptually it is the best fit: sequential
decisions, delayed reward, per-user adaptation. It is rejected because the exploration
step would mean deliberately prescribing suboptimal or unsafe loads to real people to
learn from the outcome. No simulator exists, offline RL from 20 users' logs would be
noise, and the evaluation problem alone exceeds the project timeline. This is a
correctness/ethics rejection, not a difficulty one.

---

## 4. Framework and tooling

| | scikit-learn / LightGBM / XGBoost | PyTorch | TensorFlow / Keras | Off-the-shelf API | Rust-native (`smartcore`, `linfa`) |
| --- | --- | --- | --- | --- | --- |
| Fit for engineered tabular features | +++ | + | + | n/a | ++ |
| Fit for temporal / deep models | − | +++ | +++ | n/a | −− |
| Training speed on CPU | +++ | + | + | n/a | ++ |
| Ecosystem / examples / debugging | +++ | +++ | ++ | n/a | − |
| Already a project dependency | partly (`server/requirements.txt`) | **yes** (PyTorch 2.1.2) | no | no | mentioned in SOTA doc §, unused |
| Deployment weight | light | heavy (~2 GB image) | heavy | none | lightest |
| Team skill fit | +++ | ++ | + | +++ | − |
| **Verdict** | **v1 workhorse** | **keep for v2 temporal model** | Rejected — no reason to add a third stack | WS-3 only | Rejected — avoid splitting ML across two languages |

**Decision:** LightGBM (or scikit-learn's `HistGradientBoostingClassifier`, to avoid a
dependency) for v1; PyTorch stays for the v2 temporal model and is already pinned.
Keeping all ML in Python behind the FastAPI service — with Rust owning product logic and
the safety envelope — matches the architecture the team already documented, and avoids
reimplementing models in a language with a thin ML ecosystem.

---

## 5. WS-3 — Nutrition: build vs buy

| | A. Train our own food classifier | B. Fine-tune a pretrained vision model | C. Third-party nutrition API | D. Manual entry + food database only |
| --- | --- | --- | --- | --- |
| Accuracy potential | − (with our data) | ++ | ++ | +++ (user-entered) |
| Data needed | 10⁵ labelled food images | 10³–10⁴ | none | none |
| Dev effort | very high | high | **low** | lowest |
| Recurring cost | none | none | **per call** | none |
| Portion estimation | unsolved either way | unsolved either way | vendor's problem | user states it |
| Differentiates LiftUp | no | no | no | no |
| **Verdict** | Rejected | Rejected | **Chosen** | **Required fallback** |

Food recognition is a solved, commoditised capability and not what this EIP is being
judged on; spending the team's only ML capacity there instead of on movement analysis
would be a strategic error. Buy C, behind an adapter interface so the vendor is
swappable, and always ship D as the fallback — because portion estimation from one
uncalibrated photo is unreliable regardless of vendor, and the user correcting an
estimate is the design, not a failure of it. Cost control: cache by image hash, cap
calls per user per day, degrade to D on quota exhaustion.

---

## 6. On-device vs server-side inference

| | Server-side (FastAPI) | On-device (TFLite / MediaPipe in Flutter) | Hybrid: pose on device, model on server |
| --- | --- | --- | --- |
| Latency for post-hoc video analysis | ++ (network + compute) | +++ | ++ |
| Feasibility of real-time in-session feedback | − | +++ | + |
| Model size limits | none | strict | none |
| Upload cost / mobile data | − (video upload, up to 100 MB) | +++ (nothing leaves) | ++ (keypoints only, ~KB) |
| **Privacy** | − (video leaves the device) | +++ | ++ (no video leaves) |
| Update / retrain cadence | +++ (instant) | − (app-store release) | ++ |
| Cross-platform effort | +++ (one target) | − (iOS + Android, per-device perf) | + |
| Server cost | − (GPU/CPU per request) | +++ (zero) | ++ |
| Debuggability, logging, metrics | +++ | − | ++ |
| Team skill fit | +++ | + | ++ |
| **Verdict** | **v1** | v2+ for real-time | **The right end state** |

**v1 is server-side** — the project is explicitly "100 % online"
([INNOVATION_TRACK_ACTION_PLAN.md](../INNOVATION_TRACK_ACTION_PLAN.md) §1), the FastAPI service and
`/api/v1/video/analyze` endpoint already exist, and iterating on a model without
shipping an app release is worth more than milliseconds during a feature's first weeks.

**The hybrid is where this should end up**, and it is worth saying why clearly: running
MediaPipe on-device and uploading only keypoints removes video from the network
entirely. That is simultaneously the cheapest option (no 100 MB uploads, no video
storage), the fastest, and by far the best privacy posture — it turns a GDPR
special-category data flow into a stream of anonymous coordinates. It is deferred only
because it needs the Flutter side to own pose extraction, not because it is the weaker
design. Real-time in-session feedback is impossible without it.

---

## 7. Recommendation

1. **Form analysis (WS-1):** MediaPipe pose → engineered geometric features →
   **per-fault gradient-boosted classifiers**, served from the existing Python service,
   with the current rule engine kept as baseline, fallback and safety clamp. Report only
   faults meeting a precision floor. Target the temporal model (PyTorch) as v2.
2. **Progression (WS-2):** ship the **rule engine** now; add **gradient-boosted load
   regression + a set-completion classifier** once ~100 users × ~10 sessions exist,
   always inside the rule-defined safety envelope. No RL. No collaborative filtering
   until the user base justifies it.
3. **Nutrition (WS-3):** **buy** a nutrition API behind a swappable adapter, with manual
   entry as the permanent fallback. Build nothing.
4. **Serving:** **server-side for v1**; plan the migration to **on-device pose +
   server-side model** as the privacy and cost end state.
5. **Deprecate in place:** mark the untrained I3D analyzer experimental and keep it off
   the v1 path.

**The through-line:** every choice above trades peak accuracy for *data efficiency,
explainability and a safe failure mode*, because the binding constraints are labels,
one person's time, and the fact that bad form advice can hurt someone. A smaller model
we can debug, explain and bound is worth more here than a larger one we cannot.
