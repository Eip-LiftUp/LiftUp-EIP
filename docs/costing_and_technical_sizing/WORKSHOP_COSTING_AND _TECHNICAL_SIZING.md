# Workshop Costing & Technical Sizing - LiftUp 🏋️

> **Epitech Block 1 Compliance - RCNP C4**  
> Financial analysis of production and operating costs with resource optimization and multiple scenarios based on benchmarks.

---

## 📋 Table of Contents

1. [Workshop Objectives](#workshop-objectives)
2. [Part 1: Resource Identification](#part-1-resource-identification)
3. [Part 2: Financial Benchmark](#part-2-financial-benchmark)
4. [Part 3: CAPEX & OPEX Budget](#part-3-capex--opex-budget)
5. [Viability Analysis](#viability-analysis)
6. [Deliverables](#deliverables)

---

## 🎯 Workshop Objectives

This workshop aims to demonstrate the **economic viability of LiftUp's technical architecture** by answering two fundamental questions:

1. **What resources** (hardware and software) are strictly necessary to run the project?
2. **How much does it really cost** to operate the service (MVP) and scale it?

---

## 📦 Part 1: Resource Identification

### Infrastructure & Cloud Services

#### Compute & Backend

- **Backend API**: Rust server (Actix-web/Axum) for data synchronization
- **Containerization**: Docker containers for deployment
- **Orchestration**: Managed service (ECS, Cloud Run, or equivalent)
- **Serverless Functions**: For asynchronous tasks (report generation, emails)

#### Storage & Database

- **Main Database**: Managed PostgreSQL for user data, training history
- **Object Storage**: Profile images, data exports storage
- **Cache**: Redis for sessions and frequently accessed data
- **Backups**: Automated daily backups (30-day retention)

#### Network & Security

- **Load Balancer**: Traffic distribution
- **CDN**: Static assets delivery (images, documentation)
- **SSL/TLS Certificates**: Let's Encrypt or managed certificate
- **Domain Name**: 1 main domain (.com) + subdomains

#### External APIs

- **Authentication**: Auth0 or Firebase Auth for identity management
- **Email Service**: SendGrid or AWS SES for notifications (confirmation, password reset)
- **Analytics**: Mixpanel or PostHog for usage tracking
- **Error Tracking**: Sentry for error monitoring
- **Push Notifications**: Firebase Cloud Messaging (FCM) + Apple Push Notification Service (APNS)

#### DevOps & Tooling

- **CI/CD**: GitHub Actions or GitLab CI
- **Monitoring**: Datadog, New Relic, or Grafana Cloud
- **App Store Accounts**: Apple Developer Program ($99/year) + Google Play Console ($25 one-time)
- **Code Repository**: GitHub Pro/Team if extended collaboration

### Mobile Development

#### Development Tools

- **Flutter/React Native**: Cross-platform framework
- **Rust Mobile Bindings**: FFI to integrate Rust decision engine
- **Testing Devices**: 2-3 physical iOS + Android devices for testing

### ⚠️ Hidden Costs Identified

> **Important**: Don't forget these often underestimated costs

- **Data Egress**: Data transfer out of cloud (mobile synchronization)
- **API Rate Limiting**: Quota overages (push notifications, emails)
- **Storage Incremental**: User data growth over time
- **VAT**: 20% on European services

---

## 💰 Part 2: Financial Benchmark

### 2.1 Backend Hosting

| Criteria | AWS | DigitalOcean | Render |
|----------|-----|--------------|--------|
| **Compute (2 vCPU, 4GB RAM)** | ECS Fargate: ~€50-70/month | App Platform: ~€24/month | Standard: ~€25/month |
| **Database (PostgreSQL)** | RDS db.t3.small: ~€30/month | Managed DB: ~€15/month | Included: €0 |
| **Object Storage (10GB)** | S3: ~€0.30/month | Spaces: ~€5/month (250GB min) | Included: €0 |
| **Bandwidth (100GB/month)** | ~€9/month | Included | Included |
| **Redis Cache** | ElastiCache: ~€15/month | ~€15/month | Add-on: ~€10/month |
| **Total MVP** | **~€104-124/month** | **~€59/month** | **~€35/month** |
| **Scaling (1000 users)** | ~€150-200/month | ~€100/month | ~€100/month |
| **Scaling (10000 users)** | ~€400-600/month | ~€250-300/month | ~€250-350/month |
| **Advantages** | Complete ecosystem, maximum scalability, GDPR compliance (eu-west) | Simplicity, predictable pricing, good support | Ultra-simple deployment, generous free tier |
| **Disadvantages** | Complexity, unpredictable costs, learning curve | Fewer managed services | Less infrastructure control |

#### 🎯 Recommendations

- **MVP**: **Render** for simplicity and minimal initial cost
- **Production**: **DigitalOcean** for price/performance balance

---

### 2.2 Authentication Services

| Criteria | Auth0 | Firebase Auth | Supabase Auth |
|----------|-------|---------------|---------------|
| **Pricing MVP (<1000 users)** | Free tier (7000 MAU) | Free unlimited | Free 50k MAU |
| **Pricing Scale (10k users)** | ~€25/month | Free | Free |
| **Social Logins** | ✅ Unlimited | ✅ Included | ✅ Included |
| **MFA** | ✅ | ✅ | ✅ |
| **GDPR Compliance** | ✅ EU hosting | ⚠️ US-based | ✅ EU hosting |

#### 🎯 Recommendation

**Supabase Auth** (free + GDPR compliant + can replace PostgreSQL)

---

### 2.3 Push Notifications

| Criteria | Firebase (FCM + APNS) | OneSignal | Pusher |
|----------|----------------------|-----------|--------|
| **MVP Pricing** | Free | Free up to 10k subs | ~€9/month |
| **10k users Pricing** | Free | Free | ~€49/month |
| **Segmentation** | ✅ | ✅ Advanced | ✅ Basic |
| **Analytics** | Basic | ✅ Detailed | Basic |

#### 🎯 Recommendation

**Firebase** (free + native mobile integration)

---

### 2.4 Email Service

| Criteria | SendGrid | AWS SES | Resend |
|----------|----------|---------|--------|
| **Free Tier** | 100 emails/day | €0.10/1000 emails | 3000 emails/month |
| **Pricing 10k emails/month** | Free | ~€1 | Free |
| **Pricing 100k emails/month** | ~€15 | ~€10 | ~€20 |
| **Deliverability** | Excellent | Excellent | Excellent |
| **Templates** | ✅ | ⚠️ Basic | ✅ React Email |

#### 🎯 Recommendation

**Resend** for MVP, **AWS SES** for high volume

---

## 📊 Part 3: CAPEX & OPEX Budget

### 3.1 CAPEX (Capital Expenditure)

| Item | Details | Unit Cost | Quantity | Total |
|------|---------|-----------|----------|-------|
| **iOS Test Devices** | iPhone 14/15 refurbished | €600 | 2 | €1,200 |
| **Android Test Devices** | Samsung Galaxy A54 | €350 | 2 | €700 |
| **Apple Developer Account** | Annual license | €99 | 1 | €99 |
| **Google Play Console** | One-time fee | €25 | 1 | €25 |
| **Domain Name** | .com (1 year) | €12 | 1 | €12 |
| **Design Tools** | Figma Pro (1 year) | €144 | 1 | €144 |
| | | | **TOTAL CAPEX** | **€2,180** |

---

### 3.2 OPEX (Recurring Monthly Costs)

#### Scenario 1: MVP / Alpha (50-100 users)

| Item | Service | Monthly Cost |
|------|---------|--------------|
| **Hosting** | Render (Backend + DB + Storage) | €35 |
| **Authentication** | Supabase Auth | €0 (free tier) |
| **Push Notifications** | Firebase FCM/APNS | €0 |
| **Email Service** | Resend | €0 (free tier) |
| **Error Tracking** | Sentry Developer | €0 (free tier) |
| **Monitoring** | UptimeRobot | €0 (free tier) |
| **CI/CD** | GitHub Actions | €0 (2000 min/month) |
| | **TOTAL OPEX MVP** | **€35/month** |
| | **Annual OPEX MVP** | **€420/year** |

---

#### Scenario 2: Production (1,000 active users)

| Item | Service | Monthly Cost |
|------|---------|--------------|
| **Hosting** | DigitalOcean (App + DB + Redis) | €59 |
| **Object Storage** | DO Spaces | €5 |
| **CDN** | Cloudflare Pro | €20 |
| **Authentication** | Supabase Auth | €0 |
| **Push Notifications** | Firebase | €0 |
| **Email Service** | Resend | €0 |
| **Error Tracking** | Sentry Team | €26 |
| **Monitoring** | Grafana Cloud | €15 |
| **Analytics** | PostHog | €0 (1M events/month) |
| | **TOTAL OPEX 1k users** | **€125/month** |
| | **Annual OPEX** | **€1,500/year** |

---

#### Scenario 3: Scale (10,000 active users)

| Item | Service | Monthly Cost |
|------|---------|--------------|
| **Hosting** | DigitalOcean (App scaled + DB) | €100 |
| **Object Storage** | DO Spaces (50GB) | €5 |
| **CDN** | Cloudflare Pro | €20 |
| **Redis Cache** | DigitalOcean Managed | €15 |
| **Authentication** | Supabase Auth | €0 |
| **Push Notifications** | Firebase | €0 |
| **Email Service** | AWS SES (~50k emails) | €5 |
| **Error Tracking** | Sentry Business | €80 |
| **Monitoring** | Grafana Cloud | €49 |
| **Analytics** | PostHog | €0 |
| **Backups** | Automated + snapshots | €20 |
| | **TOTAL OPEX 10k users** | **€294/month** |
| | **Annual OPEX** | **€3,528/year** |

---

#### Scenario 4: Aggressive Scale (50,000 users)

| Item | Service | Estimated Cost |
|------|---------|----------------|
| **Infrastructure** | AWS migration (HA, multi-region) | €800-1200/month |
| **Database** | RDS Multi-AZ + Read Replicas | €200/month |
| **CDN + Bandwidth** | CloudFront | €100/month |
| **Email** | SES (200k emails) | €20/month |
| **Monitoring & Logs** | Datadog | €200/month |
| | **TOTAL 50k users** | **~€1,320-1,720/month** |

---

### 3.3 Total First Year Costs

| Scenario | CAPEX | OPEX (12 months) | **TOTAL Year 1** |
|----------|-------|------------------|------------------|
| **MVP** | €2,180 | €420 | **€2,600** |
| **1k users** | €2,180 | €1,500 | **€3,680** |
| **10k users** | €2,180 | €3,528 | **€5,708** |

---

## 📈 Viability Analysis

### ✅ Financial Strengths

- **Offline-first architecture** drastically reduces API and bandwidth costs
- **Rust engine** = high performance with minimal resources
- **Generous free tiers** for critical services (auth, notifications, analytics)
- **Predictable linear scaling** up to 10k users

### ⚠️ Points of Attention

- **Data Egress**: If frequent synchronization (>100GB/month), additional costs of €50-100/month
- **Storage Growth**: Training history grows linearly (~10MB/user/year)
- **Apple Developer Account**: Mandatory annual renewal (€99)
- **Customer Support**: Not included in this budget (consider Intercom/Zendesk if needed: +€50-100/month)

### 🎯 Possible Optimizations

1. **Rust Monolith** instead of microservices = -30% infrastructure costs
2. **Self-hosted monitoring** (Grafana OSS + Prometheus) = -€60/month
3. **Aggressive compression** of historical data = -40% storage
4. **Intelligent rate limiting** to prevent API abuse = overage protection

---

## 📋 Deliverables

### ✅ Cost & Sizing Table

Provided above with clear CAPEX/OPEX distinction and optimization against budget constraints.

### ✅ Comparative Study (Benchmark)

4 detailed comparisons justifying technical choices through economic analysis:
- Backend Hosting (AWS vs DigitalOcean vs Render)
- Authentication Services (Auth0 vs Firebase vs Supabase)
- Push Notifications (Firebase vs OneSignal vs Pusher)
- Email Service (SendGrid vs AWS SES vs Resend)

### ✅ Multiple Scenarios

4 scaling scenarios with financial analysis:
- MVP (50-100 users): €35/month
- Production (1k users): €125/month
- Scale (10k users): €294/month
- Aggressive Scale (50k users): €1,320-1,720/month

### ✅ Budget Optimization

Concrete recommendations to reduce costs by 30-40% depending on project phase.

---

## 🎓 Epitech Block 1 Compliance

This workshop meets **RCNP C4** requirements by presenting:

- ✅ A comprehensive financial analysis of production and operating costs
- ✅ Resource optimization against budget constraints
- ✅ Multiple scenarios based on conducted benchmarks
- ✅ Technical and economic justification of infrastructure choices

---

**Date**: February 2026  
**Project**: LiftUp - Adaptive Weight Training Coach  
**Author**: [Your Name]
