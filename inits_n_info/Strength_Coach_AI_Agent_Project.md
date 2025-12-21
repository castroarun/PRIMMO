# PRIMMO - Strength Coach AI Agent

**Project Name:** PRIMMO
**Created:** December 4, 2025
**Author:** Arun
**Status:** Planning Complete → Ready for Development

---

## Project Objective

Build an agentic AI coach that:
- Knows my workout routine, body parameters (height, weight, BMI, body fat %), 1RM ranges, training program, routines, and goals
- Communicates via WhatsApp (Phase 1) and Voice Calls (Phase 2)
- Provides personalized, practical, and affordable guidance
- Proactively checks in and motivates during difficult times

---

## Phase Overview

| Phase | Core Capability | Monthly Cost | Timeline |
|-------|----------------|--------------|----------|
| **Phase 1** | WhatsApp AI Coach + Proactive Check-ins | $10-35 | 8-10 weeks |
| **Phase 2** | + Voice Calls (inbound/outbound) | $20-65 | 4-6 weeks |
| **Phase 3** | + Multi-user + Admin Dashboard | $20-90 | 4-6 weeks |

---

## Phase 1: Core Coach + WhatsApp Integration (MVP)

### Features
1. **Two-way WhatsApp messaging** — Send and receive messages via Twilio
2. **Personalized coaching** — Training, nutrition, blood work advice based on my profile
3. **Data logging** — Track workouts, body measurements, progress
4. **Proactive check-ins** — Scheduled messages asking about sessions, protein goals, recovery
5. **Motivational support** — Quotes, science-based tips, mental strategies during tough times
6. **Objective responses** — Time-based plans when asking for clarifications

### Tech Stack

| Component | Tool | Cost | Notes |
|-----------|------|------|-------|
| LLM Brain | Claude API (Haiku 3.5 / Sonnet 4) | $5-20/mo | Start with Haiku, upgrade if needed |
| Database | Supabase Free Tier | $0 | 500MB DB, 1GB storage, 10K MAU |
| WhatsApp | Twilio WhatsApp API | $5-15/mo | ~$0.005-0.08 per message |
| Scheduler | n8n (self-hosted) OR Supabase Edge Functions | $0 | For proactive check-ins |
| **Total** | | **$10-35/mo** | |

### Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Your       │────▶│   Twilio    │────▶│   n8n /     │
│  WhatsApp   │◀────│  WhatsApp   │◀────│  Webhook    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌─────────────┐     ┌──────▼──────┐
                    │  Supabase   │◀───▶│  Claude     │
                    │  (Profile,  │     │  API        │
                    │   Logs)     │     └─────────────┘
                    └─────────────┘
```

### Data Schema (Supabase)

```sql
-- User Profile
CREATE TABLE user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  height_cm NUMERIC,
  weight_kg NUMERIC,
  body_fat_percent NUMERIC,
  bmi NUMERIC,
  goal TEXT, -- e.g., "visible six-pack in 8-12 weeks"
  workout_split TEXT, -- e.g., "3-day split"
  training_months INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 1RM Records
CREATE TABLE one_rep_max (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profile(id),
  exercise TEXT,
  weight_kg NUMERIC,
  recorded_at TIMESTAMP DEFAULT NOW()
);

-- Workout Logs
CREATE TABLE workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profile(id),
  workout_date DATE,
  muscle_group TEXT,
  exercises JSONB, -- [{name, sets, reps, weight}]
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Body Measurements
CREATE TABLE body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profile(id),
  measurement_date DATE,
  weight_kg NUMERIC,
  body_fat_percent NUMERIC,
  waist_cm NUMERIC,
  chest_cm NUMERIC,
  arms_cm NUMERIC,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Conversation History (for context)
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profile(id),
  role TEXT, -- 'user' or 'assistant'
  content TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Phase 2: Voice Calling + Deeper Engagement

### Additional Features
1. **Outbound calls** — Agent calls you weekly to review progress
2. **Inbound calls** — Call the agent anytime for quick advice
3. **Voice logging** — "Just finished chest day, hit 80kg bench for 8 reps"
4. **Rich discussions** — Health topics, training philosophy, mindset
5. **Separate communication line** — Non-fitness topics handled differently

### Additional Tech Stack

| Component | Tool | Cost |
|-----------|------|------|
| Voice AI | Vapi.ai | $10-30/mo |
| **Phase 2 Total** | | **$20-65/mo** |

---

## Phase 3: Multi-User + Admin Dashboard

### Additional Features
1. **Multi-user support** — Family, friends, or clients
2. **Admin dashboard** — View all users' progress and data
3. **Analytics** — Weight trends, strength progression, consistency charts
4. **User management** — Onboarding, access control

### Additional Tech Stack

| Component | Tool | Cost |
|-----------|------|------|
| Auth | Supabase Auth | $0 (included) |
| Dashboard | React + Recharts | $0 |
| Hosting | Vercel Free | $0 |
| Supabase Pro (if scaling) | — | $25/mo |
| **Phase 3 Total** | | **$20-90/mo** |

---

## Learning Resources (Under 5 min each)

### Claude API
- **Video:** "Claude 3 API for Beginners" by All About AI
- **URL:** https://www.youtube.com/watch?v=Coj72EzmX20
- **Docs:** https://docs.anthropic.com/en/docs/quickstart

### React Native + Expo (if building mobile app later)
- **Video:** "React Native in 100 Seconds" by Fireship (1:40)
- **URL:** https://www.youtube.com/watch?v=gvkqT_Uoahw
- **Video:** "Expo in 100 Seconds" by Fireship (2:30)
- **URL:** https://www.youtube.com/watch?v=vFW_TxKLyrE

### Twilio WhatsApp API
- **Video:** "Getting Started with Twilio API for WhatsApp" (~4 min)
- **URL:** https://www.youtube.com/watch?v=UVez2UyjpFk
- **Docs:** https://www.twilio.com/docs/whatsapp/quickstart

### Vapi.ai (Voice AI)
- **Video:** "Build a Voice Agent in 15 Minutes Using VAPI"
- **URL:** https://www.youtube.com/watch?v=BX8INGWo1mc
- **Docs:** https://docs.vapi.ai/quickstart/introduction

### n8n (Workflow Automation)
- **Video:** "n8n Quick Start - Build Your First Workflow [2025]" (15 min)
- **URL:** https://www.youtube.com/watch?v=1MwSoB0gnM4
- **Docs:** https://docs.n8n.io/try-it-out/tutorial-first-workflow/

### Supabase
- **Already familiar**
- **Docs:** https://supabase.com/docs

---

## Cost Breakdown

### API Pricing Reference

**Claude API (pay-per-use):**
| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Claude Haiku 3.5 | $0.80 | $4.00 |
| Claude Sonnet 4 | $3.00 | $15.00 |
| Claude Opus 4 | $15.00 | $75.00 |

**Estimated per conversation:** $0.01 - $0.05 (using Sonnet)

**Free Tiers Used:**
- Supabase Free: 500MB database, 1GB storage, unlimited auth (10K MAU)
- n8n self-hosted: Free
- Vercel Free: Hosting for dashboard

---

## Development Environment

### Prerequisites
- Node.js (v18+)
- Python 3.10+ (optional, for scripts)
- Git
- VS Code or preferred IDE
- Accounts needed:
  - [ ] Anthropic Console (console.anthropic.com) — Claude API key
  - [ ] Supabase (supabase.com) — Database
  - [ ] Twilio (twilio.com) — WhatsApp API
  - [ ] Vapi.ai (vapi.ai) — Voice AI (Phase 2)

### Project Structure (Recommended)

```
strength-coach-agent/
├── src/
│   ├── api/
│   │   ├── claude.js          # Claude API integration
│   │   ├── twilio.js          # Twilio WhatsApp handlers
│   │   └── supabase.js        # Database operations
│   ├── handlers/
│   │   ├── message.js         # Incoming message handler
│   │   └── webhook.js         # Twilio webhook handler
│   ├── prompts/
│   │   └── coach-system.txt   # System prompt for coach personality
│   ├── scheduler/
│   │   └── checkins.js        # Proactive check-in logic
│   └── utils/
│       └── helpers.js
├── n8n/
│   └── workflows/             # n8n workflow exports
├── supabase/
│   └── migrations/            # Database migrations
├── .env.example
├── package.json
└── README.md
```

---

## System Prompt (Draft)

```
You are a dedicated strength and fitness coach for Arun. You have access to his complete profile:

PROFILE:
- Training experience: 20+ months consistent
- Current phase: Cutting (targeting visible six-pack in 8-12 weeks)
- Workout split: 3-day split
- Current body parameters: [Pulled from database]
- 1RM records: [Pulled from database]
- Goals: [Pulled from database]

YOUR ROLE:
1. Provide practical, science-based training advice
2. Give nutrition guidance that's affordable and realistic
3. Help interpret blood work results
4. Be encouraging during tough times — share quotes from greats, recovery tips, mental strategies
5. Give objective, time-based plans when asked for clarification
6. Track progress and celebrate wins

COMMUNICATION STYLE:
- Direct and actionable
- Use data when available
- Motivational but not preachy
- Acknowledge struggles honestly
- Remind of long-term vision when motivation is low

When Arun logs a workout, acknowledge it and provide brief feedback.
When asked about nutrition, consider affordability and practicality.
When motivation is low, share relevant stories or science-based mental tips.
```

---

## Phase 1 Implementation Checklist

### Week 1-2: Setup & Foundations
- [ ] Create Anthropic API account and get API key
- [ ] Create Supabase project
- [ ] Set up database tables (schema above)
- [ ] Create Twilio account and activate WhatsApp Sandbox
- [ ] Test sending/receiving WhatsApp messages manually

### Week 3-4: Core Integration
- [ ] Build Claude API integration (basic chat)
- [ ] Build Twilio webhook handler for incoming messages
- [ ] Connect incoming messages → Claude → response → WhatsApp
- [ ] Add conversation history storage in Supabase

### Week 5-6: Personalization
- [ ] Create user profile in database with your data
- [ ] Build context loader (pull profile before each Claude call)
- [ ] Implement workout logging via WhatsApp commands
- [ ] Implement body measurement logging

### Week 7-8: Proactive Features
- [ ] Set up n8n (self-hosted) or Supabase Edge Functions
- [ ] Create scheduled check-in workflows
- [ ] Add motivational message templates
- [ ] Test end-to-end proactive messaging

### Week 9-10: Polish & Testing
- [ ] Refine system prompt based on real conversations
- [ ] Add error handling and fallbacks
- [ ] Test edge cases
- [ ] Document setup for future reference

---

## Key Links

- **Claude API Docs:** https://docs.anthropic.com
- **Supabase Docs:** https://supabase.com/docs
- **Twilio WhatsApp Docs:** https://www.twilio.com/docs/whatsapp
- **Vapi.ai Docs:** https://docs.vapi.ai
- **n8n Docs:** https://docs.n8n.io

---

## Notes for Claude Code

When resuming this project in Claude Code:

1. **Start with:** "I'm building a Strength Coach AI Agent. Read the project spec in this file."

2. **Phase 1 priority order:**
   - Twilio WhatsApp webhook setup
   - Claude API integration
   - Supabase connection
   - Basic conversation flow
   - Then add scheduling

3. **My context:**
   - I know Supabase already
   - New to: Claude API, Twilio, Vapi, n8n, React Native
   - Work background: Technology Architect at Infosys, Oracle/SQL experience
   - Have Claude Max subscription ($100/mo) but API is separate billing

4. **Personal fitness context:**
   - 20+ months training
   - 3-day workout split
   - Currently in cutting phase targeting six-pack
   - Want practical, affordable advice

---

## Last Updated

December 4, 2025 — Initial project specification created
