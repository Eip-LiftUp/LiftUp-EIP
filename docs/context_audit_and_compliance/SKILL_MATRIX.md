# LiftUp — Team Skills Matrix (Context / Audit / Compliance)

This skills matrix provides a clear view of the team’s strengths, gaps, and the plan to address missing skills (training, recruiting, or scope adjustment). [file:2]

## Scale

- 0 = None
- 1 = Basic
- 2 = Intermediate
- 3 = Advanced
- 4 = Expert

## Team context

- Team size: 5
- Stack: Flutter (front), Rust (back), Python (AI)
- DevOps strength: 3–4 (mostly one person); most other areas are currently low

## Skills matrix (with gap analysis + action plan)

| Domain | Skill | Required | Current | Gap | Action plan |
|---|---|---:|---:|---:|---|
| Frontend (Mobile) | Flutter (UI, state mgmt, navigation) | 3 | 1 | 2 | Assign 2 devs to Flutter; deliver 1 vertical slice in Week 1 (login → home → API call); choose one state mgmt approach (Riverpod/Bloc) and document conventions. |
| Frontend (Mobile) | Dart language | 3 | 1 | 2 | 1-week ramp-up; enforce `flutter analyze` and formatting; add basic widget tests in CI. |
| Backend | Rust fundamentals (ownership, lifetimes, errors) | 4 | 0 | 4 | Highest priority: 2–3 weeks focused ramp-up; pair programming; daily small exercises; start with a minimal service before adding features. |
| Backend | Rust web framework (Axum/Actix) | 3 | 0 | 3 | Pick framework early; define routing conventions, error model, logging; add rate limiting and request validation. |
| Backend | API design & contracts (OpenAPI, versioning) | 3 | 1 | 2 | Contract-first: write OpenAPI then implement; add contract tests to keep Flutter and Rust aligned. |
| Backend | Database & migrations (schema, indexes) | 3 | 1 | 2 | Create ERD; choose DB + migration tool; implement backups early (even for MVP). |
| AI | Python for production (packaging, service structure) | 3 | 1 | 2 | Assign 1 dev as AI owner; structure as a real service (e.g., FastAPI); standardize lint/test; keep training reproducible. |
| AI | Model evaluation (metrics, test set, drift) | 3 | 0 | 3 | Define metrics + acceptance thresholds; build a minimal evaluation pipeline; produce a short “model report” per iteration. |
| AI + Backend | AI integration (latency, batching, failure modes) | 3 | 0 | 3 | Decide integration (Rust → Python HTTP/gRPC, or async jobs); define timeouts/retries; plan a degraded mode if AI is down. |
| DevOps | CI/CD (multi-stack: Flutter + Rust + Python) | 4 | 4 | 0 | Keep as strength; add a second person as backup to reduce bus factor; pipeline should run Rust fmt/clippy/test, Flutter analyze/test, Python lint/test. |
| DevOps | Deployment & runtime (containers, secrets, monitoring) | 4 | 3 | 1 | Define staging environment; centralize logs/metrics; write a runbook so someone else can deploy/rollback. |
| Security & compliance | GDPR fundamentals (data inventory, retention, deletion) | 3 | 1 | 2 | Create a data inventory (what LiftUp collects, why, where stored); define retention/deletion; assign a “privacy owner”. |
| Accessibility | WCAG/RGAA awareness for Flutter UI | 2 | 1 | 1 | Set an accessibility target; add an a11y checklist to UI PR reviews (labels, focus order, contrast). |
| Project execution | Documentation & knowledge sharing | 3 | 1 | 2 | Weekly 30-min internal tech sharing; onboarding docs per stack; require doc updates for major PRs. |


