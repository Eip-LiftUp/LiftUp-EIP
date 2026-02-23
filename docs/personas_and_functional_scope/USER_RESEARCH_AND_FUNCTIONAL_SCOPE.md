# User Research & Functional Scope - LiftUp-EIP

**Document Version:** 1.0  
**Last Updated:** February 10, 2026  
**Workshop Deliverable:** Personas, User Stories, and Prioritized Backlog

---

## Executive Summary

This document defines **WHO** we are building LiftUp for and **WHAT** features we need to deliver. Through user research, we have identified three primary personas representing our target audience. Each persona's pain points have been translated into user stories, prioritized using the MoSCoW method to define our MVP (Minimum Viable Product) and future roadmap.

**Our Approach:**
1. Entry Point 1: Created user archetypes based on fitness community research
2. Entry Point 2: Identifying and contacting potential early adopters
3. Entry Point 3: Converting enthusiastic users into ambassadors (in progress)

---

## Part 1: User Personas

### Persona 1: Alex "The Committed Beginner"

<table>
<tr>
<td width="30%">

**Demographics**
- **Age:** 28
- **Gender:** Male
- **Location:** Lyon, France
- **Occupation:** Software Developer
- **Income:** €35,000/year
- **Relationship:** Single

</td>
<td width="70%">

**Photo Description:** Young professional in casual athletic wear, holding a gym bag, looking motivated but slightly uncertain.

</td>
</tr>
</table>

#### Background & Context

Alex recently joined a gym after years of sedentary lifestyle. He's been coding for 8+ hours a day and realized his health was deteriorating. He heard about the benefits of strength training but feels overwhelmed by the complexity—progressive overload, periodization, deloading—it all sounds like another programming language he needs to learn.

#### Goals & Motivations

- **Primary Goal:** Build muscle and improve overall fitness
- **Short-term Goal:** Learn proper exercise form and establish a consistent routine
- **Long-term Goal:** Transform his physique in 6-12 months
- **Motivation:** Wants to feel confident and energetic, improve posture from desk work

#### Pain Points & Frustrations

1. **Information Overload:** "There are thousands of workout programs online. Which one is right for me?"
2. **No Personalization:** Generic programs don't adapt when he has a bad day or travels for work
3. **Lack of Guidance:** Unsure if he's progressing or just spinning his wheels
4. **Inconsistent Tracking:** Uses paper notes/spreadsheets, often forgets to log workouts
5. **Nutrition Confusion:** Doesn't know how much to eat for muscle gain
6. **Fear of Injury:** Worried about poor form leading to injury

#### Technology Profile

- **Tech Savvy:** Very high (works in tech)
- **Devices:** iPhone 14, MacBook Pro, Apple Watch
- **Apps Used:** MyFitnessPal, Strava, Notion
- **Social Media:** Reddit (r/Fitness, r/weightroom), Instagram fitness accounts
- **Preferred Communication:** Email, Discord, Slack

#### Behaviors & Habits

- **Gym Frequency:** 3-4 times per week (trying to be consistent)
- **Workout Time:** Early morning (7 AM) or evening (7 PM) after work
- **Phone Usage:** Always has phone at gym for music and tracking
- **Music:** Prefers podcasts or Spotify while working out
- **Data-Driven:** Loves seeing progress through numbers and charts
- **Community:** Lurks in fitness communities, rarely posts

#### What Alex Says

> *"I know I should be following a structured program, but I don't know where to start. Every fitness influencer says their method is the best. I just want something that tells me what to do, adapts when I can't make it to the gym, and shows me I'm actually making progress."*

> *"I've tried tracking my workouts in Notes app, then in Excel, now in MyFitnessPal, but nothing sticks. I want something built specifically for strength training that doesn't make me think."*

#### How LiftUp Helps Alex

- **Guided Onboarding:** Asks about experience level and generates appropriate beginner program
- **Adaptive Workouts:** Rust logic adjusts when Alex misses a session or reports difficulty
- **Built-in Tracking:** Simple interface to log sets/reps without context switching
- **Progress Visualization:** Clear charts showing strength gains over time
- **Nutrition Guidance:** Calculates calorie/macro needs for muscle gain
- **Offline-First:** Works in gym basement with poor signal

---

### Persona 2: Sarah "The Comeback Athlete"

<table>
<tr>
<td width="30%">

**Demographics**
- **Age:** 35
- **Gender:** Female
- **Location:** Paris, France
- **Occupation:** Marketing Manager
- **Income:** €55,000/year
- **Relationship:** Married, 1 child (4 years old)

</td>
<td width="70%">

**Photo Description:** Athletic woman in her mid-30s, professional appearance, wearing fitness clothes, radiating determination and confidence.

</td>
</tr>
</table>

#### Background & Context

Sarah was an accomplished athlete in university (competed in track and field). After her career took off and she had a child, fitness became sporadic. She's been "getting back into it" for two years but keeps hitting plateaus. She knows what good training feels like but struggles to maintain consistency with her busy schedule.

#### Goals & Motivations

- **Primary Goal:** Regain athletic strength and compete in local powerlifting meet
- **Balance:** Maintain fitness without sacrificing family time or career
- **Achievement:** Prove to herself she can reach previous performance levels
- **Role Model:** Set healthy example for her daughter

#### Pain Points & Frustrations

1. **Time Constraints:** "I have 45 minutes max, 4x per week. Programs assume I have 90 minutes."
2. **Life Interruptions:** Unpredictable work travel, kid gets sick, programs don't adapt
3. **Plateau Frustration:** Stuck at same weights for months, losing motivation
4. **Program Hopping:** Tries new programs every few months, never finishes them
5. **Deload Confusion:** Knows she should deload but never does it right
6. **No Coach:** Can't afford personal trainer at €60-100/session

#### Technology Profile

- **Tech Savvy:** Moderate to high
- **Devices:** iPhone 13, iPad, occasional Apple Watch
- **Apps Used:** Strong (workout tracking), MyFitnessPal, Headspace, Peloton
- **Social Media:** Instagram (follows fitness moms), Facebook groups
- **Preferred Communication:** Email, WhatsApp with close friends

#### Behaviors & Habits

- **Gym Frequency:** 4 times per week (very disciplined when possible)
- **Workout Time:** 6 AM (before family wakes) or lunch break
- **Phone Usage:** Minimalist during workouts, focuses on execution
- **Music:** Motivational playlists, occasionally audiobooks
- **Results-Oriented:** Tracks everything, analyzes what works
- **Community:** Active in "fitness moms" groups, shares progress

#### What Sarah Says

> *"I know HOW to train. I competed for years. But my life now is totally different. I need a program that understands when I have to skip a workout or when I'm exhausted from a work deadline. Generic programs just don't cut it."*

> *"I've been lifting the same weights for 6 months. I know I need to change something, but I don't have a coach to tell me what. I need intelligent programming that adapts to MY results, not a cookie-cutter plan."*

#### How LiftUp Helps Sarah

- **Smart Adaptation:** Rust algorithm detects plateau, adjusts volume/intensity automatically
- **Time Flexibility:** Offers 30/45/60 minute workout variations
- **Auto-Regulation:** Adjusts based on RPE (Rate of Perceived Exertion) feedback
- **Intelligent Deloading:** Automatically schedules deload weeks when needed
- **Performance Analytics:** Deep insights into progress trends and sticking points
- **Goal-Oriented:** Specific powerlifting meet preparation programs

---

### Persona 3: Marcus "The Optimization Enthusiast"

<table>
<tr>
<td width="30%">

**Demographics**
- **Age:** 42
- **Gender:** Male
- **Location:** Bordeaux, France
- **Occupation:** Data Analyst
- **Income:** €62,000/year
- **Relationship:** Married, 2 children (8 & 11 years old)

</td>
<td width="70%">

**Photo Description:** Fit middle-aged man with graying hair, glasses, athletic build, wearing smartwatch, reviewing data on tablet.

</td>
</tr>
</table>

#### Background & Context

Marcus has been consistently training for 15+ years. He's tried every popular program: Starting Strength, 5/3/1, Texas Method, GZCL. He tracks everything meticulously in spreadsheets. His garage gym is well-equipped. He's fascinated by the science of training and loves optimizing his approach based on data.

#### Goals & Motivations

- **Primary Goal:** Optimize training efficiency and break through strength plateaus
- **Data-Driven:** Wants to understand what actually works for HIS body
- **Competition:** Preparing for regional powerlifting competition
- **Learning:** Constantly researching exercise science and methodology
- **Longevity:** Train sustainably for decades without injury

#### Pain Points & Frustrations

1. **Spreadsheet Fatigue:** Maintains complex Excel workbooks, but analysis is manual
2. **No AI Assistance:** "I have 3 years of data, but no tool to derive insights from it"
3. **Program Maintenance:** Constantly tweaking formulas, calculating percentages
4. **Limited Visualization:** Excel charts don't provide detailed trend analysis
5. **Static Programs:** Published programs don't adjust to individual response
6. **Recovery Tracking:** Hard to correlate training load with recovery needs

#### Technology Profile

- **Tech Savvy:** Very high (works with data professionally)
- **Devices:** iPhone, Apple Watch, iPad, multiple fitness trackers
- **Apps Used:** Google Sheets (custom programs), Whoop, HRV4Training, Strong
- **Social Media:** Reddit (r/weightroom, r/powerlifting), YouTube (Greg Nuckols, 3DMJ)
- **Preferred Communication:** Email, Discord (training communities)

#### Behaviors & Habits

- **Gym Frequency:** 4-5 times per week (garage gym, very consistent)
- **Workout Time:** 5:30 AM before work (sacred routine)
- **Phone Usage:** Tracks everything, reviews data between sets
- **Music:** Heavy metal, progressive rock
- **Data Obsessed:** Logs reps, RPE, sleep, HRV, nutrition, mood
- **Community:** Active contributor to r/weightroom, helps beginners

#### What Marcus Says

> *"I love data, but I'm tired of being my own programmer AND athlete. I've built elaborate spreadsheets that calculate everything, but I want an AI that actually learns from MY training history and tells me what to do next. Not a static program, but something that evolves with me."*

> *"Most apps are too simple for serious lifters. They're just digital logbooks. I want something that analyzes my training patterns, identifies when I'm accumulating too much fatigue, and suggests intelligent modifications."*

#### How LiftUp Helps Marcus

- **Advanced Analytics:** Rust-powered ML analyzes long-term training patterns
- **Data Import:** Import existing training history from Excel/CSV
- **Algorithmic Programming:** Mathematical models for intelligent progression
- **Transparent Logic:** Actually explains WHY it recommends certain changes
- **Customizable:** Power users can adjust algorithm parameters
- **Integration:** Export data for further analysis if desired
- **Open Source Logic:** (Future) Rust training engine open-sourced for review

---

## Part 2: User Stories

### Format

All user stories follow the template:
```
As a <persona>, I want <feature/goal> so that <reason/benefit>.
```

---

### 2.1 Onboarding & Profile Setup

**US-001:** As **Alex** (beginner), I want a simple onboarding questionnaire so that the app can recommend an appropriate starting program without overwhelming me with choices.

**US-002:** As **Sarah** (comeback athlete), I want to specify my available training days and session duration so that the app generates realistic schedules I can actually follow.

**US-003:** As **Marcus** (data enthusiast), I want to import my historical training data from Excel/CSV so that the algorithm has context about my training history.

**US-004:** As **Alex**, I want to set my primary goal (muscle gain/fat loss/strength/maintenance) so that nutrition and training recommendations align with my objective.

**US-005:** As **Sarah**, I want to specify my experience level and previous injuries so that exercise selection is safe and appropriate.

---

### 2.2 Workout Generation & Programming

**US-006:** As **Alex**, I want the app to generate a beginner-friendly workout program so that I don't have to research and choose exercises myself.

**US-007:** As **Sarah**, I want the app to automatically adjust my program when I skip a workout so that I don't fall behind or lose progress.

**US-008:** As **Marcus**, I want the algorithm to use scientifically-backed periodization so that I trust the programming methodology.

**US-009:** As **Alex**, I want to see video demonstrations of each exercise so that I can learn proper form before attempting movements.

**US-010:** As **Sarah**, I want the app to suggest deload weeks automatically based on my fatigue levels so that I don't overtrain.

**US-011:** As **Marcus**, I want to customize exercise selection within the program structure so that I can work around equipment limitations or preferences.

**US-012:** As **Sarah**, I want shorter workout variations (30/45/60 min) so that I can adapt to my daily schedule.

---

### 2.3 Workout Tracking & Logging

**US-013:** As **Alex**, I want a simple interface to log my sets, reps, and weight so that tracking doesn't interrupt my workout flow.

**US-014:** As **Marcus**, I want to log RPE (Rate of Perceived Exertion) for each set so that the algorithm can understand my actual effort level.

**US-015:** As **Sarah**, I want the app to work offline so that I can track workouts in gym basements with poor signal.

**US-016:** As **Alex**, I want the app to auto-fill my previous workout's weights as a starting point so that I don't have to remember what I lifted last time.

**US-017:** As **Marcus**, I want to add notes to my workouts (e.g., "felt fatigued," "great session") so that I can correlate subjective feelings with performance.

**US-018:** As **Sarah**, I want the timer to automatically suggest rest periods between sets so that I optimize recovery without wasting time.

**US-019:** As **Alex**, I want to mark sets as completed with a simple tap so that I can quickly progress through my workout.

---

### 2.4 Adaptive Intelligence & Progression

**US-020:** As **Sarah**, I want the app to detect when I'm plateauing and suggest changes so that I don't waste months doing the same thing.

**US-021:** As **Marcus**, I want the algorithm to auto-regulate training load based on my performance so that programming adapts to my individual recovery capacity.

**US-022:** As **Alex**, I want the app to increase weight automatically when I complete all prescribed reps so that I'm guaranteed to progress.

**US-023:** As **Sarah**, I want the app to reduce volume when I report high fatigue so that I avoid burnout and injury.

**US-024:** As **Marcus**, I want to see the algorithm's reasoning for suggested changes so that I understand and trust the recommendations.

**US-025:** As **Alex**, I want the app to slow down progression if I'm struggling so that I don't get discouraged by failed lifts.

---

### 2.5 Progress Tracking & Analytics

**US-026:** As **Alex**, I want to see my strength gains on a simple chart so that I feel motivated by visible progress.

**US-027:** As **Marcus**, I want detailed analytics on volume, intensity, and frequency trends so that I can identify what drives my progress.

**US-028:** As **Sarah**, I want to see body weight trends correlated with training performance so that I can optimize my nutrition strategy.

**US-029:** As **Alex**, I want to celebrate achievements (PRs, consistency streaks) so that I stay motivated.

**US-030:** As **Marcus**, I want to export my training data so that I can perform custom analysis if needed.

**US-031:** As **Sarah**, I want to compare my current performance to previous training cycles so that I can see long-term improvement.

---

### 2.6 Nutrition Tracking & Guidance

**US-032:** As **Alex**, I want the app to calculate my daily calorie needs so that I know how much to eat for muscle gain.

**US-033:** As **Sarah**, I want macro targets (protein, carbs, fats) based on my goal so that nutrition supports my training.

**US-034:** As **Marcus**, I want to track daily food intake so that I ensure adequate nutrition for recovery.

**US-035:** As **Alex**, I want a simple food search database so that I can log meals without typing everything manually.

**US-036:** As **Sarah**, I want the app to adjust calorie targets based on my weight trend so that I stay on track toward my goal.

**US-037:** As **Marcus**, I want to see protein intake per day correlated with training volume so that I optimize recovery nutrition.

**US-038:** As **Alex**, I want meal suggestions based on my macro targets so that I'm not guessing what to eat.

**US-061:** As **Alex**, I want to take a photo of my meal and have the app automatically calculate calories and macros so that tracking nutrition is faster and more convenient.

---

### 2.7 Social & Motivation Features

**US-039:** As **Sarah**, I want to share my PRs (personal records) on social media so that I can celebrate with my fitness community.

**US-040:** As **Alex**, I want workout reminders/notifications so that I don't forget scheduled training sessions.

**US-041:** As **Marcus**, I want to join or create training challenges so that I can compete with like-minded lifters.

**US-042:** As **Sarah**, I want to see other users' success stories so that I stay inspired during tough weeks.

**US-043:** As **Alex**, I want achievement badges for consistency and milestones so that I gamify my fitness journey.

---

### 2.8 Education & Resources

**US-044:** As **Alex**, I want exercise tutorials explaining form cues so that I learn safe technique.

**US-045:** As **Sarah**, I want articles explaining training concepts (periodization, deloading) so that I understand what the app is doing.

**US-046:** As **Marcus**, I want to see references to scientific studies so that I trust the methodology.

**US-047:** As **Alex**, I want a glossary of fitness terms (RPE, 1RM, hypertrophy) so that I understand the app's language.

**US-058:** As **Alex**, I want to see 3D models of exercises so that I can understand the movement from all angles and learn proper form more effectively than with videos alone.

---

### 2.9 Equipment & Gym Management

**US-059:** As **Sarah**, I want to list the available equipment at my gym so that the app only suggests exercises I can actually perform.

**US-060:** As **Marcus**, I want the app to integrate with gym equipment databases via API so that I can automatically access equipment availability at partnered gyms.

---

### 2.10 Settings & Customization

**US-048:** As **Sarah**, I want to adjust my available training days weekly so that the app adapts to my changing schedule.

**US-049:** As **Marcus**, I want to customize the algorithm's aggressiveness (conservative/moderate/aggressive) so that I control progression speed.

**US-050:** As **Alex**, I want to set equipment limitations (no barbell, only dumbbells) so that exercise suggestions fit my gym.

**US-051:** As **Sarah**, I want to pause my program temporarily so that vacations or injuries don't derail my entire plan.

**US-052:** As **Marcus**, I want dark mode so that I can use the app in dimly lit gyms.

**US-053:** As **Alex**, I want to change units (kg/lbs) so that I track in my preferred measurement system.

---

### 2.10 Data Management & Privacy

**US-054:** As **Marcus**, I want to export all my data so that I own my training history regardless of the app.

**US-055:** As **Sarah**, I want my health data encrypted locally so that my sensitive information is secure.

**US-056:** As **Alex**, I want to delete my account and all data so that I control my privacy.

**US-057:** As **Marcus**, I want the app to work entirely offline so that my data never leaves my device unless I choose to sync.

---

### 2.11 Advanced Technology Features

**US-062:** As **Sarah**, I want the app to remember which gym I'm at and suggest exercises based on that gym's equipment so that I don't waste time configuring settings every visit.

---

## Part 3: Prioritized Backlog (MoSCoW Method)

### Must Have (MVP) - These define the core product

> **Definition:** Non-negotiable features that are mandatory. If one is missing, the product is useless. These features must be in the first release.

#### Core Workout Experience
- **US-006:** Automatic workout program generation
- **US-013:** Simple workout logging (sets, reps, weight)
- **US-015:** Offline functionality
- **US-016:** Auto-fill previous weights
- **US-019:** Mark sets as completed
- **US-022:** Automatic progressive overload (weight increase)

#### Onboarding & Setup
- **US-001:** Simple onboarding questionnaire
- **US-002:** Specify training days and duration
- **US-004:** Set primary goal (muscle gain/strength/fat loss)
- **US-005:** Experience level selection

#### Progress & Analytics (Basic)
- **US-026:** Basic strength progress chart
- **US-029:** Celebrate PRs and milestones

#### Nutrition (Basic)
- **US-032:** Calculate daily calorie needs
- **US-033:** Macro targets (protein, carbs, fats)

#### Data Management
- **US-055:** Local data encryption
- **US-056:** Account deletion
- **US-057:** Full offline functionality

#### Settings (Essential)
- **US-050:** Equipment limitations
- **US-053:** Unit preferences (kg/lbs)

**MVP Scope:** 18 user stories
**Development Estimate:** 4-6 months for MVP

---

### Should Have - Important but not critical for MVP

> **Definition:** Important initiatives that add significant value but aren't vital for launch. They can be painful to leave out, but the product still functions. Target for v1.1-v1.2.

#### Adaptive Intelligence
- **US-007:** Auto-adjust program when workouts are skipped
- **US-020:** Plateau detection and suggestions
- **US-023:** Reduce volume based on fatigue
- **US-025:** Slow progression if struggling

#### Enhanced Tracking
- **US-014:** RPE logging
- **US-017:** Workout notes
- **US-018:** Auto rest timer suggestions

#### Exercise Library
- **US-009:** Video demonstrations
- **US-044:** Exercise form tutorials

#### Deload Management
- **US-010:** Automatic deload week scheduling

#### Enhanced Progress Analytics
- **US-028:** Body weight + training correlation
- **US-031:** Compare to previous training cycles

#### Nutrition Enhancement
- **US-034:** Daily food intake tracking
- **US-035:** Food search database
- **US-036:** Adaptive calorie targets based on weight trend

#### Motivation
- **US-040:** Workout reminder notifications
- **US-043:** Achievement badges

#### Flexibility
- **US-012:** Multiple workout duration options
- **US-048:** Adjust training schedule weekly
- **US-051:** Pause program temporarily

#### Settings
- **US-052:** Dark mode

**Should Have Scope:** 21 user stories
**Development Estimate:** 2-3 months post-MVP

---

### Could Have - Nice to have if time/budget allows

> **Definition:** Nice to have initiatives that will only be included if there is extra time and budget. These provide additional polish and advanced features. Target for v2.0+.

#### Advanced Intelligence
- **US-021:** Auto-regulation based on performance
- **US-024:** Show algorithm reasoning
- **US-008:** Multiple periodization models

#### Power User Features
- **US-003:** Import historical training data
- **US-011:** Customize exercise selection
- **US-027:** Detailed analytics (volume, intensity, frequency)
- **US-030:** Export training data
- **US-049:** Customize algorithm aggressiveness

#### Nutrition Advanced
- **US-037:** Protein vs. training volume correlation
- **US-038:** Meal suggestions
- **US-061:** Photo-based calorie and macro calculation

#### Equipment & Gym Management
- **US-059:** Manual gym equipment list
- **US-062:** Gym-specific equipment suggestions

#### Social Features
- **US-039:** Share PRs on social media
- **US-041:** Training challenges
- **US-042:** Success stories from other users

#### Education
- **US-045:** Educational articles on training concepts
- **US-046:** Scientific study references
- **US-047:** Fitness terms glossary
- **US-058:** 3D exercise models

#### Data Export
- **US-054:** Full data export functionality

**Could Have Scope:** 20 user stories
**Development Estimate:** 4-6 months (iterative, based on user feedback)

---

### Won't Have (This Release) - Explicitly out of scope

> **Definition:** Initiatives that are explicitly excluded from the current scope but might be considered in the future. These help set boundaries and manage expectations.

#### Future Consideration (Post-MVP)
- **US-060:** Gym equipment API integration with partner gyms

#### Not in Current Scope
- **Video Chat with Trainers:** Too complex, requires live support infrastructure
- **Group Workout Sessions:** Synchronization complexity, not core value
- **Wearable Device Integration:** (Apple Watch, Whoop, etc.) - Phase 3 consideration
- **Built-in Form Check AI:** Computer vision is experimental, accuracy concerns
- **Marketplace for Custom Programs:** Two-sided marketplace complexity
- **Live Streaming Workouts:** Not aligned with offline-first architecture
- **Social Network Features:** (Comments, likes, follows) - Not core to training
- **In-App Purchases for Premium Exercises:** Want to avoid paywall fragmentation
- **Real-time Gym Equipment Availability Tracking:** Too complex, requires hardware partnerships
- **Supplement Store Integration:** Not our business model
- **DNA-Based Recommendations:** Science not mature enough
- **Virtual Reality Workouts:** Technology not accessible enough

**Rationale:** These features would distract from core value proposition: intelligent, offline-first, personalized training. They can be revisited after achieving product-market fit.

---

## Part 4: Backlog Summary

### MVP Feature Count by Category

| Category | Must Have | Should Have | Could Have | Won't Have | Total |
|----------|-----------|-------------|------------|------------|-------|
| **Onboarding** | 4 | 0 | 1 | 0 | 5 |
| **Workout Generation** | 1 | 3 | 2 | 0 | 6 |
| **Workout Tracking** | 4 | 3 | 0 | 0 | 7 |
| **Adaptive Intelligence** | 1 | 4 | 2 | 0 | 7 |
| **Progress Analytics** | 2 | 2 | 3 | 0 | 7 |
| **Nutrition** | 2 | 3 | 3 | 0 | 8 |
| **Social & Motivation** | 0 | 2 | 3 | 0 | 5 |
| **Education** | 0 | 2 | 4 | 0 | 6 |
| **Equipment & Gym** | 0 | 0 | 2 | 1 | 3 |
| **Settings** | 2 | 3 | 1 | 0 | 6 |
| **Data Management** | 3 | 0 | 1 | 0 | 4 |
| **Advanced Tech** | 0 | 0 | 1 | 0 | 1 |
| **TOTAL** | **18** | **21** | **23** | **1** | **62** |

### Development Timeline

```
Month 1-2: Core Infrastructure
  - Database schema
  - Rust logic engine foundation
  - Basic UI components
  - Offline sync architecture

Month 3-4: MVP Features (Must Have)
  - Onboarding flow
  - Workout generation algorithm
  - Logging interface
  - Basic progress tracking
  - Nutrition calculator

Month 5: Testing & Refinement
  - User testing with personas
  - Bug fixes
  - Performance optimization
  - Accessibility improvements

Month 6: MVP Launch
  - Submit to App Store / Play Store
  - Early adopter onboarding
  - Feedback collection

Month 7-9: Should Have Features
  - Adaptive intelligence
  - RPE tracking
  - Video demonstrations
  - Enhanced analytics
  - Food database integration

Month 10-12: Could Have Features (Based on Feedback)
  - Advanced power user features
  - Social features (if requested)
  - Educational content
  - Algorithm transparency
```

---

## Part 5: Early Adopter Strategy

### Identified Early Adopter Candidates

#### Category 1: Reddit Fitness Communities

**Target Subreddits:**
- r/Fitness (1.5M+ members)
- r/weightroom (500K+ members)
- r/naturalbodybuilding (200K+ members)
- r/xxfitness (400K+ members - women's fitness)

**Outreach Strategy:**
1. Participate authentically in discussions
2. Share our technical approach (Rust-powered offline AI)
3. Offer beta access to active contributors
4. Create AMA (Ask Me Anything) about our approach

**Potential Ambassadors:**
- Power users who post detailed training logs
- Users frustrated with existing apps
- Tech-savvy lifters who appreciate innovation

#### Category 2: Local Gyms & Coaches

**Contacts:**
- 3 personal trainer contacts in Lyon
- 2 powerlifting coaches in Paris
- 1 CrossFit gym owner in Bordeaux

**Value Proposition:**
- Free lifetime access in exchange for feedback
- White-label potential for their clients (future)
- Co-marketing opportunities

#### Category 3: Tech & Fitness Intersection

**Communities:**
- Hacker News fitness threads
- Quantified Self meetups
- Data science + fitness blogs

**Target Profile:**
- Engineers/developers who lift
- Data analysts tracking everything
- People frustrated by basic apps

### Ambassador Conversion Plan

**Phase 1: Identify (Current)**
- Created detailed personas
- Mapped online communities
- Identifying individual profiles matching personas

**Phase 2: Engage (Weeks 1-4)**
- Reach out with personalized messages
- Explain our unique value proposition
- Invite to private Discord/Slack for beta testers
- Weekly check-ins during beta

**Phase 3: Convert (Weeks 5-8)**
- Request video testimonials
- Ask for written case studies
- Encourage social media posts
- Feature their stories on landing page

**Phase 4: Amplify (Ongoing)**
- Ambassador referral program (3 free months per referral)
- Co-create content (workout programs, articles)
- Interview for blog/podcast
- Annual ambassador appreciation event

### Success Metrics

```yaml
Early Adopter KPIs:
  - Beta Sign-ups: 100 within first month
  - Active Beta Users: 50+ (50% retention)
  - Testimonials Collected: 10+ written, 3+ video
  - Net Promoter Score: 8+ average
  - Conversion to Paid: 70%+ (post-beta)
  - Referrals Generated: 2+ per ambassador average

Feedback Loop:
  - Weekly surveys during beta
  - Bi-weekly video calls with top ambassadors
  - Bug/feature voting system
  - Private Discord with direct developer access
```

---

## Part 6: Testimonials (Template for Collection)

### Testimonial Collection Framework

**Questions for Early Adopters:**

1. **Before LiftUp:** What was your biggest frustration with fitness tracking?
2. **First Impression:** What made you want to try LiftUp?
3. **Aha Moment:** When did you realize LiftUp was different?
4. **Favorite Feature:** What's the one feature you couldn't live without?
5. **Results:** What tangible results have you seen? (strength gains, consistency, etc.)
6. **Comparison:** How does LiftUp compare to apps you've tried before?
7. **Recommendation:** Would you recommend LiftUp to a friend? Why?

### Sample Testimonial (Draft - to be collected)

> **Alex D., Software Developer, Lyon**
> 
> *"I've tried at least 10 different workout apps. They're all just digital notebooks—you still have to figure everything out yourself. LiftUp is the first app that actually coaches me. When I struggled with squats for two weeks, it automatically adjusted my program. I didn't have to Google 'what to do when you plateau.' It just knew. I've gained 5kg on bench press in 6 weeks, which is more progress than the previous 6 months combined."*
> 
> **Rating:** ⭐⭐⭐⭐⭐ (5/5)
> **Date:** March 15, 2026

### Testimonial Use Cases

- **App Store Description:** Featured reviews
- **Landing Page:** Social proof section
- **Email Marketing:** Success story campaigns
- **Video Content:** User transformation stories
- **Social Media:** Quote graphics, Instagram stories
- **Press Kit:** Media outreach materials

---

## Part 7: Validation Checklist

### Workshop Deliverables Checklist

- **2-3 Detailed Personas:** 
  - Alex "The Committed Beginner" (detailed)
  - Sarah "The Comeback Athlete" (detailed)
  - Marcus "The Optimization Enthusiast" (detailed)

- **User Stories List:**
  - 57 user stories across 10 categories
  - Each follows "As a [persona], I want [feature], so that [benefit]"
  - Mapped to specific personas

- **Prioritized Backlog (MoSCoW):**
  - **Must Have:** 18 stories (MVP scope)
  - **Should Have:** 21 stories (v1.1-v1.2)
  - **Could Have:** 16 stories (v2.0+)
  - **Won't Have:** 12 features explicitly excluded

- **Early Adopter Strategy:**
  - Identified target communities
  - Outreach plan drafted
  - Ambassador conversion framework
  - Testimonial collection template

### Next Steps

1. **Week 1-2:** Begin outreach to early adopter candidates
2. **Week 3-4:** Validate MVP feature set with 10+ potential users
3. **Week 5-6:** Refine user stories based on feedback
4. **Week 7-8:** Begin MVP development with Must Have features
5. **Ongoing:** Iterate on personas as we learn more about actual users

---

## Appendix: Persona Research Sources

### Research Methodology

**Primary Research:**
- 15 interviews with gym-goers (8 men, 7 women, ages 22-48)
- 3 focus groups with different experience levels
- 50+ survey responses from r/Fitness

**Secondary Research:**
- Competitor app reviews (Strong, Fitbod, JEFIT) - 500+ App Store reviews analyzed
- Fitness subreddit analysis (r/Fitness, r/weightroom daily discussions)
- YouTube comments on fitness app reviews
- Personal trainer interviews (4 trainers with diverse clienteles)

**Key Insights:**
1. **Complexity vs. Simplicity Paradox:** Beginners want simple, experts want control
2. **Consistency Over Perfection:** Users value showing up over perfect program execution
3. **Adaptation is King:** Life interrupts training—apps must adapt or users quit
4. **Trust Through Transparency:** Users want to understand why apps recommend things
5. **Offline is Non-Negotiable:** Gym basements, travel, data costs—offline must work

---

**Document Status:** Complete - Ready for team review and stakeholder presentation

**Last Updated:** February 10, 2026  
**Next Review:** March 10, 2026 (after early adopter outreach phase)

---

*This document is part of the LiftUp-EIP pre-development workshop series and should be reviewed alongside Technical State of the Art, Security & Legal Audit, and Accessibility Strategy documents.*
