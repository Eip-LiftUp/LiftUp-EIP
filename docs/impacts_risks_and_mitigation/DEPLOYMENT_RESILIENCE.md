## Part 3: Deployment & Resilience

Developing on `localhost` is easy. Running in production is hard. We explain how LiftUp will live, evolve, and resist failures.

### Deployment & Migration Strategy

#### CI/CD Pipeline Architecture

**Continuous Integration Flow:**

1. **Trigger**: Git push to branch (feature/*, develop, main)
2. **GitHub Actions**: Workflow starts (.github/workflows)
3. **Parallel Checks**:
   - **Code Quality**: cargo clippy, rustfmt, coverage check (>80%)
   - **Build & Test**: cargo test, integration tests, E2E tests
   - **Security**: cargo audit, dependabot, SAST scan
4. **Validation**: All checks must pass
5. **Continuous Deployment**: Branch-based deployment

**Deployment Strategy:**
- `develop` branch → Staging (automatic)
- `main` branch → Production (manual approval required)

---

#### CI/CD Implementation Details

**1. Code Quality Checks** (on every PR)

```yaml
# .github/workflows/ci.yml
- name: Rust Linting
  run: cargo clippy -- -D warnings

- name: Rust Formatting
  run: cargo fmt --check

- name: Test Coverage
  run: |
    cargo tarpaulin --out Xml
    # Fail if coverage below 80%
```

**2. Automated Testing Pyramid**

| Test Type | Count | Execution Time | Purpose |
|-----------|-------|----------------|----------|
| **Unit Tests** | 150+ | <30s | Test individual functions (Rust engine logic) |
| **Integration Tests** | 50+ | <2min | Test API endpoints, DB interactions |
| **E2E Tests** | 10+ | <5min | Test critical user flows (login, workout, sync) |

**3. Deployment Environments**

**Staging Environment:**
- Trigger: Automatic on merge to develop
- Infrastructure: Identical to production (same OS, dependencies)
- Data: Synthetic test data (1000 fake users)
- Purpose: QA validation before production release

**Production Environment:**
- Trigger: Manual approval on merge to main
- Strategy: Blue-Green deployment
- Traffic Shift: Gradual (0% → 25% → 50% → 100%)
- Auto-Rollback: If error rate >1%

**4. Rollback Procedures**

| Scenario | Detection Time | Rollback Method | Recovery Time |
|----------|----------------|-----------------|---------------|
| **Failed health checks** | Immediate | Automatic (Docker/K8s) | <2 min |
| **High error rate (>5%)** | <1 min | Manual rollback | <5 min |
| **Database migration issue** | <5 min | Restore snapshot | <15 min |
| **Feature bug** | Variable | Feature flag disable | <1 min |

---

### Database Migration Strategy

#### Zero-Downtime Migration Process

**Philosophy**: Backward-compatible changes only. Support both old and new schema during transition.

**Migration Phases:**

**Phase 1: Preparation (Week N)**
- Write migration script (up and down)
- Test on staging with production data copy
- Create rollback script
- Document expected impacts

**Phase 2: Deployment (Week N+1)**
- Step 1: Automated database backup
- Step 2: Deploy NEW code (supports both schemas)
- Step 3: Run additive migration (add columns/tables)
- Step 4: Monitor for 24 hours
- Step 5: Mark as successful

**Phase 3: Data Migration (Week N+2)**
- Step 6: Backfill new columns (batch job, off-peak)
- Step 7: Validate data integrity
- Step 8: Switch application to new schema

**Phase 4: Cleanup (Week N+4)**
- Step 9: Remove old code paths
- Step 10: Drop old columns/tables
- Step 11: Update documentation

---

#### Example Migration: Adding "Workout Notes" Feature

```sql
-- Migration V1.2_add_workout_notes.sql
-- Phase 1: Additive (backward compatible)

BEGIN;

ALTER TABLE workout_logs 
ADD COLUMN notes TEXT NULL DEFAULT NULL;

ALTER TABLE workout_logs 
ADD COLUMN notes_created_at TIMESTAMP NULL DEFAULT NULL;

-- Create index for performance
CREATE INDEX idx_workout_logs_notes 
ON workout_logs(notes_created_at) 
WHERE notes IS NOT NULL;

COMMIT;

-- Application V1.2 handles NULL notes gracefully
-- Old app versions still work (ignore new column)
-- New app versions can write notes
```

**Rollback Script:**

```sql
-- Rollback if migration fails
BEGIN;

DROP INDEX IF EXISTS idx_workout_logs_notes;
ALTER TABLE workout_logs DROP COLUMN IF EXISTS notes_created_at;
ALTER TABLE workout_logs DROP COLUMN IF EXISTS notes;

COMMIT;
```

---

### Resilience & Continuity

#### Single Points of Failure (SPOF) Analysis

| Component | Current State | Risk Level | Impact if Failed | Mitigation | Status |
|-----------|---------------|------------|------------------|------------|--------|
| **Backend API** | Single server (MVP) | HIGH | Complete outage | Load balancer + 2 instances, auto-scaling | DONE |
| **Database** | Managed PostgreSQL | MEDIUM | Data unavailable | DO Managed DB with failover, daily backups | DONE |
| **Redis Cache** | Single instance | LOW | Degraded performance | Cache miss = DB query. Redis Sentinel at 10k+ users | PLANNED |
| **Mobile App** | Internet Dependent | LOW | Banner | Require connection | DONE |
| **CDN** | Cloudflare | LOW | Slower delivery | 200+ global PoPs, origin fallback | DONE |
| **Authentication** | Supabase Auth | MEDIUM | Cannot login (new users) | JWT valid 7 days, local auth fallback planned | WARNING |
| **Push Notifications** | Firebase | LOW | Delayed alerts | Not critical, in-app fallback | DONE |
| **Email Service** | Resend | LOW | Delayed emails | 48h retry queue | DONE |

**Overall Resilience Score**: 8/10

---

#### Backup Strategy

**1. Database Backups**

| Type | Frequency | Retention | Location | Tested |
|------|-----------|-----------|----------|--------|
| **Automated Snapshots** | Daily (3:00 AM UTC) | 7 days | DO Frankfurt (separate volume) | Monthly |
| **Weekly Backups** | Sunday 2:00 AM | 4 weeks | DO Frankfurt + AWS S3 | Quarterly |
| **Monthly Archives** | 1st of month | 12 months | AWS S3 Glacier (Ireland) | Annually |
| **Pre-Migration** | Before each migration | 7 days | DO Frankfurt | Always |

**Recovery Objectives:**
- RTO (Recovery Time Objective): <30 minutes
- RPO (Recovery Point Objective): <24 hours
- Critical RTO: <15 minutes (pre-migration backups)

**Backup Testing Protocol (Monthly Drill - 3rd Tuesday):**
1. Restore latest daily backup to staging DB
2. Verify data integrity (row counts, checksums)
3. Run application test suite against restored DB
4. Validate backup size and completion time
5. Document results in ops log

---

**2. Application State Backups**

| Asset | Versioning | Retention | Purpose |
|-------|------------|-----------|---------|
| **Docker Images** | Git SHA tags | Indefinite (prod tags) | Instant rollback |
| **Infrastructure as Code** | Git (Terraform) | All commits | Recreate infrastructure |
| **Configuration Files** | Git (encrypted) | All commits | Environment configs |
| **Secrets** | HashiCorp Vault | Versioned | API keys, certificates |

---

**3. User Data Backups (Mobile)**

| Location | Data | Recovery Method |
|----------|------|-----------------|
| **User Device** | Complete workout history (SQLite) | Primary source of truth |
| **Cloud Server** | Synced subset (last 2 years) | Backup + cross-device sync |
| **User Export** | JSON/CSV download feature | User-controlled backup |

**Data Loss Recovery Scenarios:**

| Scenario | Recovery Method | Data Loss |
|----------|-----------------|-----------|
| **Server DB lost** | Restore from daily backup | <24h of syncs |
| **User loses device** | Login on new device, sync from cloud | 0 (if recently synced) |
| **Both server + device lost** | User export restoration | Depends on last export |

---

#### Degraded Mode & Graceful Failures

**Scenario 1: API Server Down**

**Symptoms:**
- Mobile app cannot reach backend API
- Sync operations timing out
- Login/signup unavailable

**Degraded Mode Behavior:**
- App notifies user of network error
- Workouts cannot be recorded locally
- Recommendations unavailable
- Retry option provided
- Cannot create new account (requires API)
- Cross-device sync unavailable
- UI Banner: "No internet connection - features unavailable"

**Auto-Recovery:**
- Exponential backoff retry (5s → 10s → 30s → 1min → 5min)
- Background sync when connectivity restored
- No user intervention required

**User Impact**: Low (95% functionality maintained)

---

**Scenario 2: Database Performance Degradation**

**Symptoms:**
- API response times >1000ms (target: <200ms)
- Increased DB connection pool usage
- Timeout errors appearing

**Degraded Mode Actions:**
1. Increase Redis cache TTL (1h → 6h)
2. Serve stale data for non-critical endpoints
3. Disable analytics/leaderboard endpoints (save resources)
4. Enable read-replica routing for GET requests
5. Activate circuit breaker (prevent cascade failures)
6. Alert on-call engineer (PagerDuty)

**Recovery Steps:**
- Identify slow queries (pg_stat_statements)
- Add missing indexes
- Kill long-running queries
- Consider vertical scaling of DB

**User Impact**: Medium (slower, but functional)

---

**Scenario 3: Recommendation Engine Failure**

**Symptoms:**
- Rust decision engine crashing
- Infinite loop or panic in algorithm
- Cannot generate new workout recommendations

**Degraded Mode Behavior:**
- Serve last known good workout plan (cached)
- Allow manual workout creation
- Historical data viewing unaffected
- No adaptive recommendations until fixed
- UI Message: "Using your previous program - manual adjustments available"

**Error Handling:**
- Sentry captures panic stacktrace
- Automatic rollback to previous engine version
- Feature flag to disable recommendation generation
- Manual workout mode as fallback

**User Impact**: Medium (core feature unavailable, workaround exists)

---

**Scenario 4: Third-Party Service Outage**

| Service Down | Impact | Degraded Mode | User Impact |
|--------------|--------|---------------|-------------|
| **Email (Resend)** | No transactional emails | Queue 48h, retry exponentially | Low (in-app notifications) |
| **Push Notifications** | No push alerts | In-app banner instead | Low (see on app open) |
| **Auth (Supabase)** | Cannot login (new sessions) | Existing JWTs valid 7 days | Medium (existing users OK) |
| **CDN (Cloudflare)** | Slower assets | Origin serves directly | Low (slightly slower) |

---

#### Monitoring & Alerting

**Observability Stack Layers:**

**Layer 1: Infrastructure Monitoring (Grafana Cloud)**
- CPU, Memory, Disk, Network metrics
- Droplet health checks
- Database performance (connections, query times)

**Layer 2: Application Monitoring (Sentry)**
- Error tracking (exceptions, panics)
- Performance monitoring (transaction traces)
- Release tracking (version deployments)
- User impact (affected users per issue)

**Layer 3: Uptime Monitoring (UptimeRobot)**
- External health checks (every 5 minutes)
- API endpoint availability
- DNS/SSL certificate expiry

**Layer 4: Business Metrics (PostHog)**
- User engagement (DAU, MAU)
- Feature adoption rates
- Funnel conversion tracking

**Layer 5: Custom Alerts (Prometheus + Alertmanager)**
- SLA violations (uptime <99.5%)
- Anomaly detection (sudden traffic spikes)
- Resource exhaustion prediction

---

**Key Metrics & Alert Thresholds:**

| Metric | Target | Warning | Critical | Action |
|--------|--------|---------|----------|--------|
| **API Uptime** | 99.9% | <99.5% | <99% | PagerDuty → On-call |
| **Response Time (P95)** | <200ms | >500ms | >1000ms | Investigate immediately |
| **Error Rate** | <0.1% | >1% | >5% | Rollback deployment |
| **DB Connections** | <50% | >80% | >95% | Scale up DB |
| **Disk Usage** | <70% | >85% | >95% | Cleanup + alert |
| **Memory Usage** | <80% | >90% | >95% | Restart service |
| **Failed Logins** | <10/h | >100/h | >1000/h | Rate limit (attack) |
| **Sync Queue Size** | <100 | >10,000 | >50,000 | Backend scaling issue |
| **Certificate Expiry** | >30 days | <14 days | <7 days | Renew immediately |

---

**Incident Response Workflow:**

**1. DETECTION (Automated)**
- Alert triggered by monitoring system
- Context: affected service, severity, metrics

**2. NOTIFICATION (Automated)**
- PagerDuty notifies on-call engineer
- Slack #incidents channel message
- Status page auto-updated (status.liftup.app)

**3. TRIAGE (Human, <5 minutes)**
- Assess severity (P1-P4)
- Check runbook for common issues
- Gather context (logs, metrics)

**4. COMMUNICATION (Human, <15 minutes)**
- Update status page with user-friendly message
- Notify stakeholders (product, support)
- Set resolution time expectations

**5. RESOLUTION (Human, variable)**
- Follow runbook procedures
- Implement fix or rollback
- Verify with monitoring

**6. POST-INCIDENT (Human, within 48h)**
- Blameless post-mortem document
- Root cause analysis (5 Whys)
- Action items to prevent recurrence
- Share learnings with team

---

**Incident Severity Levels:**

| Priority | Definition | Response Time | Examples |
|----------|------------|---------------|----------|
| **P1 - Critical** | Complete service outage | <15 minutes | API down, DB unreachable |
| **P2 - High** | Major feature unavailable | <1 hour | Recommendations failing, sync broken |
| **P3 - Medium** | Degraded performance | <4 hours | Slow API, minor UI bugs |
| **P4 - Low** | Minor issue, no impact | <24 hours | UI typo, analytics gap |

---

## Deliverables

### 1. Risk Matrix

**Comprehensive risk analysis covering:**
- 6 Technical Risks (mobile OS changes, performance, vendor pricing, auth downtime, migrations, app store)
- 4 Operational Risks (key person dependency, burnout, testing gaps, monitoring)
- 5 Security Risks (data breach, insecure storage, MITM, malicious injection, dependencies)
- 2 Business Continuity Risks (datacenter outage, service degradation)

**Total: 17 identified risks** with probability, impact, criticality scores, and detailed mitigation strategies.

---

### 2. GreenIT Strategy

**Environmental impact analysis including:**
- Hosting Optimization: EU datacenter, future Nordic migration (-87% carbon)
- Data Transfer Reduction: Compression, efficient JSON serialization
- Compute Efficiency: Rust engine (50x faster, 10x lower memory)
- Mobile Optimization: Battery savings, dark mode, 5+ year device support
- Carbon Footprint: 0.223 kg CO2eq/user/year (equivalent to driving 1 km)
- Eco-Score: 41/50 (8.2/10) with improvement roadmap

**Key Achievement**: LiftUp is 5x more eco-friendly than drinking one coffee per year

---

### 3. Resilience Plan

**Production readiness strategy covering:**
- CI/CD Pipeline: 200+ automated tests, staging environment, blue-green deployment
- Zero-Downtime Migrations: Backward-compatible changes, pre-migration backups
- SPOF Analysis: 8 components analyzed, 2 medium risks, mitigation strategies
- Backup Strategy: Daily DB snapshots, 7-day retention, 30-min RTO, monthly drills
- Degraded Mode: 4 failure scenarios with graceful handling
- Monitoring: 9 key metrics, automated alerting, <15min incident response

**Resilience Score**: 8/10 (production-ready with acceptable MVP trade-offs)

---

## Epitech Block 1 Compliance

This workshop meets RCNP C2 & C5 requirements:

### RCNP C2 - Technical & Security Audit
- Comprehensive security risk analysis (5 risks with mitigation)
- Operational environment constraints identified (SPOFs, dependencies)
- Technical opportunities leveraged (Rust efficiency)
- Methodological approach documented (risk matrix, monitoring)

### RCNP C5 - Evolution & Migration Strategy
- Prospective study of evolution paths (MVP to 50k users)
- Migration strategy based on technical audit
- Clear deployment and upgrade processes
- Long-term resilience considerations

### Additional Compliance
- Risk management methodology (17 risks, mitigation plans)
- Environmental responsibility (GreenIT 8.2/10)
- Production continuity planning (backup, incident response)
- Documentation for oral presentation (summaries, comparisons)

---

**Date**: February 2026  
**Project**: LiftUp - Adaptive Weight Training Coach  
**Version**: 1.0  