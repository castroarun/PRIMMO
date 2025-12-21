# PRIMMO - Product Requirements Document

**Status:** Approved for Development
**Version:** 1.0
**Last Updated:** 2025-12-21
**Author:** Arun

---

## 1. Objective

### 1.1 Problem Statement
Fitness enthusiasts lack a personal, always-available AI coach that:
- Knows their complete workout history, body parameters, and goals
- Communicates through convenient channels (WhatsApp, Voice)
- Provides proactive motivation during difficult times
- Delivers personalized, science-based advice affordably

### 1.2 Vision Statement
Build an agentic AI strength coach that communicates via WhatsApp and Voice calls, providing personalized training, nutrition, and motivational support based on the user's complete fitness profile.

### 1.3 Success Metrics
- [ ] 90% of FAQ questions answered without Claude API call
- [ ] < 2 second response time for WhatsApp messages
- [ ] < 500ms voice-to-voice latency
- [ ] Monthly cost under $35 for Phase 1
- [ ] User engagement: 3+ interactions per week

---

## 2. Features

### 2.1 Phase 1: Core Coach + WhatsApp (MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| **WhatsApp Messaging** | Two-way messaging via Twilio WhatsApp API | P0 |
| **FAQ Knowledge Base** | Pre-built responses for common questions (reps, sets, protein, etc.) | P0 |
| **Personalized Coaching** | Training, nutrition advice based on user profile | P0 |
| **Workout Logging** | Log workouts via WhatsApp messages | P1 |
| **Proactive Check-ins** | Scheduled messages for motivation, reminders | P1 |
| **REPPIT Integration** | Optional sync with REPPIT app for workout data | P1 |
| **Body Measurements** | Track weight, body fat, measurements | P2 |

### 2.2 Phase 2: Voice Integration

| Feature | Description | Priority |
|---------|-------------|----------|
| **Inbound Voice Calls** | Call PRIMMO anytime for quick advice | P0 |
| **Outbound Voice Calls** | Weekly progress review calls | P1 |
| **Voice Workout Logging** | "Just finished chest day, hit 80kg bench for 8 reps" | P1 |
| **Rich Discussions** | Training philosophy, mindset, health topics | P2 |

### 2.3 Phase 3: Multi-User + Dashboard

| Feature | Description | Priority |
|---------|-------------|----------|
| **Multi-user Support** | Family, friends, or clients | P0 |
| **Admin Dashboard** | View all users' progress | P1 |
| **Analytics** | Weight trends, strength progression charts | P1 |
| **User Management** | Onboarding, access control | P2 |

---

## 3. User Stories

### 3.1 Phase 1 Stories

| ID | As a... | I want to... | So that... | Priority |
|----|---------|--------------|------------|----------|
| US-001 | User | Message PRIMMO on WhatsApp | I can get fitness advice anytime | P0 |
| US-002 | User | Ask common questions (reps, protein) | I get instant answers without waiting | P0 |
| US-003 | User | Log my workout via message | My progress is tracked automatically | P1 |
| US-004 | User | Receive morning motivation messages | I stay consistent with training | P1 |
| US-005 | User | Connect my REPPIT account | PRIMMO knows my complete workout history | P1 |
| US-006 | User | Get personalized calorie recommendations | I know exactly what to eat for my goals | P1 |
| US-007 | User | Ask about my progress | I understand how I'm improving | P2 |

### 3.2 Phase 2 Stories

| ID | As a... | I want to... | So that... | Priority |
|----|---------|--------------|------------|----------|
| US-008 | User | Call PRIMMO for quick advice | I get answers while at the gym | P0 |
| US-009 | User | Receive weekly check-in calls | I stay accountable to my goals | P1 |
| US-010 | User | Log workouts by voice | I don't have to type after a session | P1 |

---

## 4. Data Model

### 4.1 Core Entities

| Entity | Description | Key Fields |
|--------|-------------|------------|
| `primmo_users` | WhatsApp user identity | id, whatsapp_phone, display_name, timezone |
| `user_connections` | Links PRIMMO to REPPIT accounts | primmo_user_id, reppit_user_id, connection_code, status |
| `conversations` | Chat history for Claude context | primmo_user_id, role, content, channel |
| `faq_responses` | Cached FAQ knowledge base | category, keywords, response_text, response_voice |
| `proactive_checkins` | Scheduled messages | user_id, checkin_type, scheduled_at, status |
| `primmo_user_profile` | Standalone user profile data | height, weight, goal, workout_split |
| `primmo_one_rep_max` | PR records for standalone users | exercise, weight_kg, recorded_at |

### 4.2 Entity Relationships

```
primmo_users 1:1 primmo_user_profile
primmo_users 1:N conversations
primmo_users 1:N proactive_checkins
primmo_users 1:1 user_connections
user_connections N:1 reppit.users
user_connections N:1 reppit.profiles
```

### 4.3 REPPIT Integration (Read-Only)

When connected, PRIMMO reads from REPPIT:
- `profiles` - User body stats, goals, exercise ratings
- `workout_sessions` - Historical workout data
- `user_preferences` - Theme, units

---

## 5. Architecture

### 5.1 System Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER CHANNELS                                │
├───────────────────────────────┬─────────────────────────────────────┤
│   WhatsApp (Twilio)           │   Voice (Vapi.ai + Twilio)          │
└───────────────┬───────────────┴──────────────────┬──────────────────┘
                │                                  │
                ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      n8n ORCHESTRATION                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 RESPONSE TIER ROUTER                         │   │
│  │   Tier 1: FAQ Match (Airtable) ───────────────── $0          │   │
│  │   Tier 2: Semantic Search (Embeddings) ───────── $0          │   │
│  │   Tier 3: Calculated (BMR, TDEE, etc.) ───────── $0          │   │
│  │   Tier 4: Claude API (Complex queries) ───────── $$          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
                │                                  │
                ▼                                  ▼
┌──────────────────────────┐    ┌──────────────────────────────────────┐
│   AIRTABLE (FAQ Admin)   │    │          SUPABASE (Core Data)        │
│   - FAQ entries          │    │   - primmo_users                     │
│   - Categories           │    │   - conversations                    │
│   - Usage analytics      │    │   - embeddings                       │
└──────────────────────────┘    │   - REPPIT data (if connected)       │
                                └──────────────────────────────────────┘
```

### 5.2 Tech Stack

| Component | Technology | Cost |
|-----------|------------|------|
| **LLM Brain** | Claude API (Haiku 3.5 / Sonnet 4) | $5-20/mo |
| **Database** | Supabase Free Tier | $0 |
| **WhatsApp** | Twilio WhatsApp API | $5-15/mo |
| **Voice** | Vapi.ai + Twilio | $10-30/mo |
| **Orchestration** | n8n (self-hosted or cloud) | $0-20/mo |
| **FAQ Admin** | Airtable | $0 (free tier) |
| **Embeddings** | OpenAI ada-002 or local | $0-2/mo |
| **Hosting** | Vercel (dashboard) | $0 |

### 5.3 Response Tiering (Cost Optimization)

| Tier | Source | Latency | Cost | % of Queries |
|------|--------|---------|------|--------------|
| 1 | FAQ Match (Airtable) | 0ms | $0 | ~30% |
| 2 | Semantic Search | ~100ms | $0 | ~20% |
| 3 | Calculated (formulas) | ~10ms | $0 | ~15% |
| 4 | Claude API | ~2s | $0.01-0.03 | ~35% |

**Expected savings:** 65% of queries answered without Claude API

---

## 6. FAQ Knowledge Base

### 6.1 Categories

| Category | Examples | Count |
|----------|----------|-------|
| **Training** | Reps, sets, frequency, rest times, form | ~15 |
| **Nutrition** | Protein, calories, macros, meal timing | ~10 |
| **Recovery** | Sleep, rest days, stretching, deload | ~8 |
| **Motivation** | Pre-written motivational snippets | ~10 |
| **General** | App help, connection issues | ~5 |

### 6.2 FAQ Structure (Airtable)

| Field | Type | Purpose |
|-------|------|---------|
| Question | Text | Primary question |
| Question_Variants | Text | Alternative phrasings |
| Keywords | Multi-select | Trigger words |
| Response_Text | Long text | WhatsApp response (markdown OK) |
| Response_Voice | Long text | Voice response (conversational) |
| Requires_Profile | Checkbox | Needs user data? |
| Variables | Multi-select | {weight}, {protein_min}, etc. |
| Priority | Number | Higher = checked first |
| Active | Checkbox | Enable/disable |

### 6.3 Sample FAQs

**Training:**
- How many reps should I do?
- How many sets per exercise?
- How often should I train?
- How long should I rest between sets?

**Nutrition:**
- How much protein should I eat?
- What's my calorie target?
- What should I eat before/after workout?

**Calculated Responses:**
- My BMR/TDEE (from profile data)
- My protein range (weight × 1.6-2.2)
- My strength standards (from REPPIT exercise data)

---

## 7. REPPIT Integration

### 7.1 Connection Flow

1. User messages PRIMMO: "Connect my REPPIT account"
2. PRIMMO generates 6-character code (e.g., "ABC123")
3. User enters code in REPPIT Settings
4. Connection activated - PRIMMO can read REPPIT data

### 7.2 Data Synced from REPPIT

| Data | Frequency | Purpose |
|------|-----------|---------|
| Profile (weight, height, sex, goal) | On connect + daily | Personalization |
| Exercise Ratings (levels) | Hourly | Level-aware coaching |
| Workout Sessions (30 days) | Hourly | Context for advice |
| Personal Records | Computed | Celebration, targets |

### 7.3 Enhanced System Prompt (Connected User)

```
USER PROFILE:
- Name: Arun
- Weight: 75 kg
- Goal: Cutting (visible six-pack)
- Overall Level: Intermediate

PERSONAL RECORDS:
- Bench Press: 85kg
- Squat: 100kg
- Deadlift: 120kg

RECENT WORKOUTS:
- Dec 20: Chest (Bench 80kg×8, Incline 60kg×10)
- Dec 18: Back (Deadlift 110kg×5, Rows 70kg×8)

LAST WORKOUT: 1 day ago
```

---

## 8. Voice Integration (Phase 2)

### 8.1 Vapi.ai Configuration

| Setting | Value |
|---------|-------|
| **LLM** | Claude 3.5 Haiku |
| **Voice** | ElevenLabs "Rachel" |
| **Latency** | < 500ms |
| **Tools** | query_knowledge_base, get_user_stats, log_workout |

### 8.2 Voice-Specific Responses

FAQ entries have separate `Response_Voice` field:
- Conversational tone
- No markdown formatting
- Numbers spelled out ("eight to twelve")
- SSML pauses for natural speech

---

## 9. Proactive Check-ins

### 9.1 Check-in Types

| Type | Trigger | Example Message |
|------|---------|-----------------|
| **Workout Reminder** | Morning on training days | "Ready to crush legs today?" |
| **Progress Check** | 3 days since last workout | "Haven't heard from you - everything OK?" |
| **Weekly Summary** | Sunday evening | "Great week! 4 workouts logged..." |
| **Motivation** | Random (2-3x/week) | Quote + encouragement |
| **Rest Day** | After 3 consecutive training days | "Recovery is growth. Take it easy today." |

### 9.2 Scheduling

Managed via n8n cron workflows → Supabase → Twilio/Vapi

---

## 10. Security & Privacy

### 10.1 Data Protection

| Concern | Mitigation |
|---------|------------|
| WhatsApp numbers | Encrypted at rest (pgcrypto) |
| REPPIT data scope | Explicit opt-in connection |
| Conversations | Stored separately, pruned after 90 days |
| Revocation | User can disconnect anytime |

### 10.2 Row Level Security

All PRIMMO tables have RLS enabled:
- Service role access for n8n backend
- REPPIT users can view/revoke their connections

---

## 11. Implementation Phases

### Phase 1: MVP (Weeks 1-10)

| Week | Focus | Deliverables |
|------|-------|--------------|
| 1-2 | Setup | Supabase schema, Airtable FAQ base, n8n instance |
| 3-4 | WhatsApp | Twilio integration, message routing |
| 5-6 | FAQ System | Tier 1-3 responses, template processing |
| 7-8 | Claude | Tier 4 integration, conversation history |
| 9-10 | Proactive | Check-in scheduling, REPPIT sync |

### Phase 2: Voice (Weeks 11-16)

| Week | Focus | Deliverables |
|------|-------|--------------|
| 11-12 | Vapi Setup | Assistant config, tool webhooks |
| 13-14 | Voice FAQs | Voice-optimized responses |
| 15-16 | Testing | End-to-end voice flows |

### Phase 3: Dashboard (Weeks 17-22)

| Week | Focus | Deliverables |
|------|-------|--------------|
| 17-18 | Multi-user | User management, profiles |
| 19-20 | Dashboard UI | Next.js admin panel |
| 21-22 | Analytics | Charts, reports |

---

## 12. Cost Projections

### 12.1 Phase 1 Monthly Cost

| Component | Low Usage | High Usage |
|-----------|-----------|------------|
| Claude API | $5 | $20 |
| Twilio WhatsApp | $5 | $15 |
| Supabase | $0 | $0 |
| n8n (self-hosted) | $0 | $0 |
| **Total** | **$10** | **$35** |

### 12.2 With Voice (Phase 2)

| Component | Additional Cost |
|-----------|-----------------|
| Vapi.ai | $10-30/mo |
| **Phase 2 Total** | **$20-65/mo** |

---

## 13. Related Documents

- [REPPIT-INTEGRATION-DESIGN.md](./REPPIT-INTEGRATION-DESIGN.md) - Technical integration design
- [UNIFIED-VOICE-WHATSAPP-DESIGN.md](./UNIFIED-VOICE-WHATSAPP-DESIGN.md) - Multi-channel architecture
- [RESPONSE-TIERING-DESIGN.md](./RESPONSE-TIERING-DESIGN.md) - FAQ & cost optimization
- [Strength_Coach_AI_Agent_Project.md](../inits_n_info/Strength_Coach_AI_Agent_Project.md) - Original project spec

---

## 14. Approval

- [x] PRD reviewed by stakeholder
- [x] Ready for development

**Approved by:** Arun
**Approval Date:** 2025-12-21