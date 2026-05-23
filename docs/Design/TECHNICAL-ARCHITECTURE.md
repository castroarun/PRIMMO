# PRIMMO Technical Architecture

**Version:** 2.0
**Date:** 2025-12-29
**Status:** Approved
**Based on:** APP_PRD v1.0, RESPONSE-TIERING-DESIGN v1.0

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
                         USER CHANNELS
    ┌─────────────────────────────────────────────────────┐
    │   WhatsApp (Twilio)     │     Voice (Vapi.ai)       │
    └────────────┬────────────┴──────────────┬────────────┘
                 │                           │
                 ▼                           ▼
    ┌─────────────────────────────────────────────────────┐
    │                n8n ORCHESTRATION                     │
    │                 (Railway $5/mo)                      │
    │  ┌───────────────────────────────────────────────┐  │
    │  │            4-TIER RESPONSE ROUTER              │  │
    │  │                                                │  │
    │  │  Tier 1: Keyword Match ──────────── $0, 0ms    │  │
    │  │  Tier 2: Semantic Search ─────────── $0, 100ms │  │
    │  │  Tier 3: Calculated (BMR/TDEE) ──── $0, 10ms   │  │
    │  │  Tier 4: Claude API ────────────── $$, 2s      │  │
    │  │           ↓                                    │  │
    │  │    [Log to claude_queries]                     │  │
    │  │    [Daily Digest Alert]                        │  │
    │  └───────────────────────────────────────────────┘  │
    └────────────────────────────┬────────────────────────┘
                                 │
                                 ▼
    ┌─────────────────────────────────────────────────────┐
    │              SUPABASE (Free Tier)                    │
    │                                                      │
    │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │
    │  │ Knowledge   │  │ User Data    │  │ Analytics  │  │
    │  │ Hub         │  │              │  │            │  │
    │  │             │  │              │  │            │  │
    │  │ faq_entries │  │ primmo_users │  │ claude_    │  │
    │  │ embeddings  │  │ profiles     │  │ queries    │  │
    │  │             │  │ conversations│  │            │  │
    │  └─────────────┘  └──────────────┘  └────────────┘  │
    │                                                      │
    │  ┌─────────────────────────────────────────────┐    │
    │  │ REPPIT Integration (Read-Only, Optional)    │    │
    │  └─────────────────────────────────────────────┘    │
    └─────────────────────────────────────────────────────┘
                                 │
                                 ▼
    ┌─────────────────────────────────────────────────────┐
    │              ADMIN DASHBOARD (Vercel)                │
    │                                                      │
    │  • Natural Language FAQ Entry                        │
    │  • Claude Query Review                               │
    │  • Usage Analytics                                   │
    └─────────────────────────────────────────────────────┘
```

### 1.2 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Orchestration | n8n (Railway) | Visual workflows, no execution costs, easy debugging |
| Database | Supabase | Free tier, pgvector, RLS, REPPIT integration ready |
| Knowledge Hub | Supabase (not Airtable) | One platform, no API limits, direct SQL |
| Embeddings | Supabase pgvector | Local, $0 cost, good enough quality |
| WhatsApp | Twilio | Reliable, good sandbox for testing |
| Voice (Phase 2) | Vapi.ai | Built for voice AI, low latency |
| Admin UI | Next.js on Vercel | Free hosting, familiar stack |

---

## 2. Database Schema

### 2.1 Knowledge Hub Tables

```sql
-- ============================================
-- KNOWLEDGE HUB (Your Coaching Database)
-- ============================================

-- Main FAQ entries table
CREATE TABLE faq_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Categorization
  category TEXT NOT NULL CHECK (category IN (
    'training', 'nutrition', 'recovery', 'motivation', 'general'
  )),

  -- Matching
  question TEXT NOT NULL,              -- Primary question
  keywords TEXT[] NOT NULL DEFAULT '{}', -- Trigger words for Tier 1

  -- Responses
  response_whatsapp TEXT NOT NULL,     -- Markdown formatted
  response_voice TEXT,                 -- Conversational, no markdown

  -- Personalization
  variables TEXT[] DEFAULT '{}',       -- ['{weight}', '{protein_min}']
  requires_profile BOOLEAN DEFAULT false,

  -- Management
  priority INT DEFAULT 0,              -- Higher = checked first
  active BOOLEAN DEFAULT true,
  usage_count INT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Embeddings for semantic search (Tier 2)
CREATE TABLE knowledge_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  faq_id UUID REFERENCES faq_entries(id) ON DELETE CASCADE,
  content TEXT NOT NULL,               -- Question + variants combined
  embedding VECTOR(384),               -- all-MiniLM-L6-v2 dimensions
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast keyword search
CREATE INDEX idx_faq_keywords ON faq_entries USING GIN(keywords);
CREATE INDEX idx_faq_category ON faq_entries(category);
CREATE INDEX idx_faq_active ON faq_entries(active) WHERE active = true;

-- Index for vector similarity search
CREATE INDEX idx_embedding_vector ON knowledge_embeddings
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### 2.2 Claude Query Logging (Alert System)

```sql
-- ============================================
-- CLAUDE QUERY LOG (Your Alert Source)
-- ============================================

CREATE TABLE claude_queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User context
  user_id UUID REFERENCES primmo_users(id),
  user_phone TEXT,                     -- For quick reference

  -- Query details
  user_message TEXT NOT NULL,          -- What they asked
  claude_response TEXT,                -- What Claude said

  -- Cost tracking
  model_used TEXT CHECK (model_used IN ('haiku', 'sonnet')),
  tokens_in INT,
  tokens_out INT,
  cost_usd DECIMAL(10,6),
  latency_ms INT,

  -- Review workflow
  reviewed BOOLEAN DEFAULT false,      -- You've seen it
  added_to_faq BOOLEAN DEFAULT false,  -- You added to knowledge hub
  review_notes TEXT,                   -- Your notes

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- Index for unreviewed queries (your daily digest)
CREATE INDEX idx_claude_unreviewed ON claude_queries(created_at)
  WHERE reviewed = false;

-- View: FAQ Candidates (questions asked 3+ times)
CREATE VIEW faq_candidates AS
SELECT
  user_message,
  COUNT(*) as times_asked,
  MAX(claude_response) as sample_response,
  SUM(cost_usd) as total_cost,
  MAX(created_at) as last_asked
FROM claude_queries
WHERE added_to_faq = false
GROUP BY user_message
HAVING COUNT(*) >= 3
ORDER BY times_asked DESC;
```

### 2.3 User & Conversation Tables

```sql
-- ============================================
-- USER MANAGEMENT
-- ============================================

CREATE TABLE primmo_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  whatsapp_phone TEXT UNIQUE NOT NULL,
  display_name TEXT,
  timezone TEXT DEFAULT 'UTC',
  preferred_channel TEXT DEFAULT 'whatsapp',
  onboarded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Standalone user profiles (not connected to REPPIT)
CREATE TABLE primmo_user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,

  -- Body stats
  weight_kg DECIMAL(5,2),
  height_cm DECIMAL(5,2),
  age INT,
  sex TEXT CHECK (sex IN ('male', 'female')),

  -- Goals & preferences
  goal TEXT CHECK (goal IN ('lose', 'maintain', 'gain', 'recomp')),
  activity_level TEXT DEFAULT 'moderate',
  workout_split TEXT,

  -- Computed values (cached)
  bmr INT,
  tdee INT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Conversation history (for Claude context)
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,

  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  channel TEXT DEFAULT 'whatsapp',

  -- Routing metadata
  tier_used TEXT CHECK (tier_used IN ('exact', 'semantic', 'calculated', 'claude')),
  faq_id UUID REFERENCES faq_entries(id),

  created_at TIMESTAMPTZ DEFAULT now()
);

-- REPPIT connection (optional)
CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id),
  reppit_user_id UUID,
  connection_code TEXT UNIQUE,
  status TEXT DEFAULT 'pending',
  connected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Proactive check-ins
CREATE TABLE proactive_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id),
  checkin_type TEXT NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  sent_at TIMESTAMPTZ,
  message_content TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 2.4 Supabase Functions

```sql
-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Semantic search function
CREATE OR REPLACE FUNCTION match_knowledge(
  query_embedding VECTOR(384),
  match_threshold FLOAT DEFAULT 0.75,
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  faq_id UUID,
  question TEXT,
  response_whatsapp TEXT,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    fe.faq_id,
    f.question,
    f.response_whatsapp,
    1 - (fe.embedding <=> query_embedding) AS similarity
  FROM knowledge_embeddings fe
  JOIN faq_entries f ON f.id = fe.faq_id
  WHERE f.active = true
    AND 1 - (fe.embedding <=> query_embedding) > match_threshold
  ORDER BY fe.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Get unreviewed Claude queries for digest
CREATE OR REPLACE FUNCTION get_claude_digest(
  since_hours INT DEFAULT 24
)
RETURNS TABLE (
  id UUID,
  user_message TEXT,
  claude_response TEXT,
  cost_usd DECIMAL,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
AS $$
  SELECT id, user_message, claude_response, cost_usd, created_at
  FROM claude_queries
  WHERE reviewed = false
    AND created_at > now() - (since_hours || ' hours')::INTERVAL
  ORDER BY created_at DESC;
$$;
```

---

## 3. n8n Workflow Diagrams

### 3.1 Main Message Handler

```
┌─────────────────────────────────────────────────────────────────────┐
│                     WHATSAPP MESSAGE HANDLER                         │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐
│   Twilio     │────▶│  Parse       │────▶│  Get/Create User         │
│   Webhook    │     │  Message     │     │  (Supabase)              │
└──────────────┘     └──────────────┘     └────────────┬─────────────┘
                                                        │
                                                        ▼
                                          ┌──────────────────────────┐
                                          │  TIER 1: Keyword Match   │
                                          │  (Supabase Query)        │
                                          └────────────┬─────────────┘
                                                       │
                                    ┌──────────────────┴──────────────────┐
                                    │                                     │
                               [MATCH]                               [NO MATCH]
                                    │                                     │
                                    ▼                                     ▼
                     ┌──────────────────────────┐      ┌──────────────────────────┐
                     │  Process Template        │      │  TIER 2: Semantic Search │
                     │  (Replace variables)     │      │  (pgvector similarity)   │
                     └────────────┬─────────────┘      └────────────┬─────────────┘
                                  │                                 │
                                  │                  ┌──────────────┴──────────────┐
                                  │                  │                             │
                                  │             [MATCH >0.75]               [NO MATCH]
                                  │                  │                             │
                                  │                  ▼                             ▼
                                  │   ┌──────────────────────────┐  ┌──────────────────────────┐
                                  │   │  Process Template        │  │  TIER 3: Calculated?     │
                                  │   └────────────┬─────────────┘  │  (BMR/TDEE/Protein)      │
                                  │                │                └────────────┬─────────────┘
                                  │                │                             │
                                  │                │              ┌──────────────┴──────────────┐
                                  │                │              │                             │
                                  │                │         [CALC MATCH]                 [NO MATCH]
                                  │                │              │                             │
                                  │                │              ▼                             ▼
                                  │                │ ┌────────────────────────┐  ┌──────────────────────────┐
                                  │                │ │ Run Calculation        │  │  TIER 4: Claude API      │
                                  │                │ └───────────┬────────────┘  └────────────┬─────────────┘
                                  │                │             │                            │
                                  │                │             │                            ▼
                                  │                │             │               ┌──────────────────────────┐
                                  │                │             │               │  Log to claude_queries   │
                                  │                │             │               └────────────┬─────────────┘
                                  │                │             │                            │
                                  ▼                ▼             ▼                            ▼
                              ┌───────────────────────────────────────────────────────────────────┐
                              │                      SEND RESPONSE                                 │
                              │                   (Twilio WhatsApp)                                │
                              └───────────────────────────────────────────────────────────────────┘
                                                        │
                                                        ▼
                              ┌───────────────────────────────────────────────────────────────────┐
                              │                   LOG CONVERSATION                                 │
                              │                     (Supabase)                                     │
                              └───────────────────────────────────────────────────────────────────┘
```

### 3.2 Daily Digest Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DAILY DIGEST (9:00 AM)                            │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌────────────────────────────┐     ┌─────────────────────┐
│   Cron       │────▶│  Query claude_queries      │────▶│  Count > 0?         │
│   9:00 AM    │     │  WHERE reviewed = false    │     │                     │
└──────────────┘     │  AND created_at > -24h     │     └──────────┬──────────┘
                     └────────────────────────────┘                │
                                                        ┌──────────┴──────────┐
                                                        │                     │
                                                    [YES]                  [NO]
                                                        │                     │
                                                        ▼                     ▼
                                         ┌─────────────────────────┐    ┌─────────┐
                                         │  Format Digest Message  │    │  END    │
                                         │                         │    └─────────┘
                                         │  📊 PRIMMO Daily Report │
                                         │  5 Claude Calls         │
                                         │                         │
                                         │  1. "How do I fix..."   │
                                         │  2. "What's the best.." │
                                         └───────────┬─────────────┘
                                                     │
                                                     ▼
                                         ┌─────────────────────────┐
                                         │  Send WhatsApp to Admin │
                                         │  (Your Number)          │
                                         └─────────────────────────┘
```

### 3.3 FAQ Entry via Natural Language

```
┌─────────────────────────────────────────────────────────────────────┐
│                 NATURAL LANGUAGE FAQ ENTRY                           │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌────────────────────────────┐
│  Admin UI    │────▶│  User types naturally:     │
│  Submit      │     │                            │
└──────────────┘     │  "When someone asks about  │
                     │  rest times, tell them     │
                     │  60-90s for hypertrophy,   │
                     │  2-3min for strength"      │
                     └───────────┬────────────────┘
                                 │
                                 ▼
                     ┌────────────────────────────┐
                     │  Claude API (Haiku)        │
                     │  Extract:                  │
                     │  - Question                │
                     │  - Keywords                │
                     │  - Category                │
                     │  - WhatsApp Response       │
                     │  - Voice Response          │
                     └───────────┬────────────────┘
                                 │
                                 ▼
                     ┌────────────────────────────┐
                     │  Show Preview to Admin     │
                     │  [Edit] [Save] [Cancel]    │
                     └───────────┬────────────────┘
                                 │
                            [SAVE]
                                 │
                                 ▼
                     ┌────────────────────────────┐
                     │  Insert into faq_entries   │
                     └───────────┬────────────────┘
                                 │
                                 ▼
                     ┌────────────────────────────┐
                     │  Generate Embedding        │
                     │  Insert into               │
                     │  knowledge_embeddings      │
                     └────────────────────────────┘
```

---

## 4. Admin UI Mockups

### 4.1 Knowledge Hub Dashboard

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PRIMMO Admin                                    [Dashboard] [FAQ] [Alerts] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📊 Today's Stats                                                    │   │
│  │                                                                      │   │
│  │   Messages: 47    │  Tier 1: 18 (38%)  │  Claude Calls: 12 (26%)    │   │
│  │   Users: 3        │  Tier 2: 9 (19%)   │  Cost: $0.04               │   │
│  │                   │  Tier 3: 8 (17%)   │                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  💬 Add Coaching Knowledge                                           │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │ When someone asks about progressive overload, explain that    │  │   │
│  │  │ they should add weight or reps each week. Even 1 rep more    │  │   │
│  │  │ counts as progress. If stuck for 3 weeks, try deloading.     │  │   │
│  │  │                                                         ▊     │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                               [Add to Knowledge Hub] │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ⚡ Unreviewed Claude Queries (5)                          [View All] │   │
│  │                                                                      │   │
│  │  "How do I fix elbow pain from skull crushers?"                     │   │
│  │  → Training/Form                              [Add to FAQ] [Dismiss] │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │  "Best protein powder for lactose intolerant people?"               │   │
│  │  → Nutrition/Supplements                      [Add to FAQ] [Dismiss] │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │  "I gained 2kg this week, is that too fast?"                        │   │
│  │  → Nutrition/Progress                         [Add to FAQ] [Dismiss] │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Natural Language Entry with Preview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Add Knowledge Entry                                               [Cancel] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  💬 Describe the coaching knowledge naturally:                       │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │ When someone asks about rest times between sets, tell them    │  │   │
│  │  │ 60-90 seconds for muscle building, 2-3 minutes for strength,  │  │   │
│  │  │ and 3-5 minutes for heavy compound lifts like squats and      │  │   │
│  │  │ deadlifts.                                                    │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                    [Generate Preview] │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📋 AI-Extracted Preview                                    [Edit]   │   │
│  │                                                                      │   │
│  │  Category:    [Training ▼]                                          │   │
│  │                                                                      │   │
│  │  Question:    How long should I rest between sets?                  │   │
│  │                                                                      │   │
│  │  Keywords:    rest, between sets, rest time, how long, recovery     │   │
│  │               [+ Add keyword]                                        │   │
│  │                                                                      │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │                                                                      │   │
│  │  WhatsApp Response:                                                  │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │ **Rest times by goal:**                                       │  │   │
│  │  │                                                               │  │   │
│  │  │ 💪 Muscle building: 60-90 seconds                            │  │   │
│  │  │ 🏋️ Strength: 2-3 minutes                                     │  │   │
│  │  │ ⚡ Heavy compounds: 3-5 minutes                               │  │   │
│  │  │                                                               │  │   │
│  │  │ Pro tip: Longer rest for big lifts, shorter for isolations.  │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                                      │   │
│  │  Voice Response:                                                     │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │ Rest times depend on your goal. For muscle building, rest    │  │   │
│  │  │ sixty to ninety seconds. For strength, two to three minutes. │  │   │
│  │  │ For heavy compound lifts like squats, take three to five     │  │   │
│  │  │ minutes.                                                      │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                                                [Cancel]  [Save to Hub ✓]   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Claude Query Review

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Review Claude Queries                                 [All] [Unreviewed]   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📨 User Asked:                                         2 hours ago  │   │
│  │  "How do I fix elbow pain from skull crushers?"                      │   │
│  │                                                                      │   │
│  │  🤖 Claude Responded:                                                │   │
│  │  "Elbow pain during skull crushers is common. Try these fixes:       │   │
│  │   1. Use an EZ-bar instead of straight bar                          │   │
│  │   2. Don't lock out fully at the top                                │   │
│  │   3. Try overhead tricep extensions instead                          │   │
│  │   4. Ice after workout if inflamed..."                              │   │
│  │                                                                      │   │
│  │  Cost: $0.003  │  Model: Haiku  │  Tokens: 245                      │   │
│  │                                                                      │   │
│  │  ───────────────────────────────────────────────────────────────    │   │
│  │                                                                      │   │
│  │  [Add to Knowledge Hub]  [Dismiss]  [Flag for Review]               │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📨 User Asked:                                         5 hours ago  │   │
│  │  "I'm feeling really unmotivated after my breakup"                   │   │
│  │                                                                      │   │
│  │  🤖 Claude Responded:                                                │   │
│  │  "I'm sorry you're going through this. Breakups are tough..."        │   │
│  │                                                                      │   │
│  │  Cost: $0.004  │  Model: Sonnet  │  Tokens: 312                     │   │
│  │                                                                      │   │
│  │  ───────────────────────────────────────────────────────────────    │   │
│  │                                                                      │   │
│  │  💡 Recommendation: Keep as Claude (personal/emotional)             │   │
│  │                                                                      │   │
│  │  [Dismiss - Keep for Claude]  [Flag for Review]                     │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Cost Model

### 5.1 Monthly Cost Breakdown

| Component | Low (1-3 users) | Medium (5-10 users) | High (20+ users) |
|-----------|-----------------|---------------------|------------------|
| **n8n (Railway)** | $5 | $5 | $5-10 |
| **Twilio WhatsApp** | $4 | $8 | $15 |
| **Claude API** | $0.20 | $2 | $8 |
| **Supabase** | $0 | $0 | $0-25 |
| **Vercel** | $0 | $0 | $0 |
| **Total** | **~$10** | **~$15** | **~$30-60** |

### 5.2 Claude API Cost Optimization

| Strategy | Impact |
|----------|--------|
| 4-tier system | 65-75% queries avoid Claude |
| Haiku first | 80% of Claude calls use Haiku ($0.0004/call) |
| Knowledge hub growth | Each FAQ entry saves $0.10+/month |
| Daily digest reviews | Convert Claude queries to FAQ entries |

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1-2)

| Task | Deliverable |
|------|-------------|
| Supabase setup | All tables created, RLS enabled |
| n8n on Railway | Instance running, webhook URLs |
| Twilio sandbox | WhatsApp test number working |
| Seed FAQs | 20-30 initial FAQ entries |

### Phase 2: Message Pipeline (Week 3-4)

| Task | Deliverable |
|------|-------------|
| Twilio webhook | Messages received in n8n |
| Tier 1 routing | Keyword matching working |
| Tier 2 routing | Semantic search working |
| Response sending | WhatsApp replies working |

### Phase 3: Intelligence (Week 5-6)

| Task | Deliverable |
|------|-------------|
| Tier 3 calculators | BMR, TDEE, protein working |
| Claude integration | Tier 4 responses working |
| Query logging | All Claude calls logged |
| Daily digest | Admin WhatsApp notifications |

### Phase 4: Admin UI (Week 7-8)

| Task | Deliverable |
|------|-------------|
| Next.js app | Deployed on Vercel |
| Natural language entry | FAQ creation working |
| Query review UI | One-click FAQ addition |
| Usage dashboard | Stats visible |

### Phase 5: Polish (Week 9-10)

| Task | Deliverable |
|------|-------------|
| REPPIT integration | Connection flow working |
| Proactive check-ins | Scheduled messages working |
| Edge cases | Error handling complete |
| Documentation | Setup guide complete |

---

## 7. Related Documents

- [APP_PRD.md](./APP_PRD.md) - Product requirements
- [RESPONSE-TIERING-DESIGN.md](./RESPONSE-TIERING-DESIGN.md) - Tier system details
- [REPPIT-INTEGRATION-DESIGN.md](./REPPIT-INTEGRATION-DESIGN.md) - REPPIT sync
- [UNIFIED-VOICE-WHATSAPP-DESIGN.md](./UNIFIED-VOICE-WHATSAPP-DESIGN.md) - Multi-channel

---

## 8. Approval

- [x] Architecture reviewed
- [x] Cost model approved
- [x] Ready for implementation

**Approved by:** Arun
**Date:** 2025-12-29