# PRIMMO Unified Voice + WhatsApp Architecture

**Version:** 1.0
**Date:** 2025-12-21
**Purpose:** Integrated design for multi-channel AI coaching with FAQ management

---

## 1. Executive Summary

This document outlines a unified architecture where:
- **WhatsApp** (Twilio) and **Voice** (Vapi.ai) share the same brain
- **FAQ Knowledge Base** handles common questions without hitting Claude API
- **n8n** orchestrates workflows and provides admin interface
- **Airtable** serves as the human-friendly FAQ management layer

---

## 2. Voice Platform Comparison

Based on research from [Lindy's 2025 Voice Agent Rankings](https://www.lindy.ai/blog/ai-voice-agents) and [Softcery's Platform Comparison](https://softcery.com/lab/choosing-the-right-voice-agent-platform-in-2025):

| Platform | Best For | Latency | Pricing | Our Use Case Fit |
|----------|----------|---------|---------|------------------|
| **Vapi.ai** | Developer flexibility, customization | <500ms | $0.05/min + providers | **Best fit** |
| **Retell** | Compliance (HIPAA, SOC2), healthcare | ~600ms | $0.07/min flat | Overkill for fitness |
| **Bland.ai** | Enterprise, high-volume outbound | Good | Custom (expensive) | Too enterprise |

### Recommendation: **Vapi.ai**

**Why Vapi for PRIMMO:**
- Open-source, API-first architecture ([Vapi Docs](https://docs.vapi.ai/quickstart/introduction))
- Direct n8n integration via webhooks ([Vapi + n8n Guide](https://vapi.ai/library/how-to-connect-vapi-to-n8n-ai-agents-in-9-minutes))
- Can use Claude as the LLM backend
- Sub-500ms voice-to-voice latency
- Bring-your-own telephony (Twilio) for unified billing
- $0.05/min orchestration + provider costs (~$0.10-0.15/min total)

---

## 3. Unified Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER CHANNELS                                      │
├─────────────────────────────┬───────────────────────────────────────────────┤
│                             │                                                │
│     📱 WhatsApp             │     📞 Voice Call                              │
│     (Twilio API)            │     (Vapi.ai + Twilio)                        │
│           │                 │           │                                    │
│           ▼                 │           ▼                                    │
│   ┌───────────────┐         │   ┌───────────────┐                           │
│   │ Twilio        │         │   │ Vapi.ai       │                           │
│   │ Webhook       │         │   │ Orchestrator  │                           │
│   └───────┬───────┘         │   └───────┬───────┘                           │
│           │                 │           │                                    │
└───────────┼─────────────────┴───────────┼────────────────────────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           n8n ORCHESTRATION                                  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    UNIFIED MESSAGE ROUTER                            │   │
│  │                                                                      │   │
│  │   channel: 'whatsapp' | 'voice'                                     │   │
│  │   user_id: string                                                    │   │
│  │   message: string (transcribed for voice)                           │   │
│  │   context: { profile, history, reppit_data }                        │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    RESPONSE TIER ROUTER                              │   │
│  │                                                                      │   │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │   │
│  │   │ TIER 1      │  │ TIER 2      │  │ TIER 3      │  │ TIER 4    │ │   │
│  │   │ FAQ Match   │→ │ Semantic    │→ │ Calculated  │→ │ Claude    │ │   │
│  │   │ (Airtable)  │  │ (Embeddings)│  │ (Formulas)  │  │ API       │ │   │
│  │   └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    RESPONSE FORMATTER                                │   │
│  │                                                                      │   │
│  │   WhatsApp: Markdown text, emojis OK                                │   │
│  │   Voice: Conversational, no markdown, SSML tags                     │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                           │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   AIRTABLE      │  │   SUPABASE      │  │   REPPIT (if connected)     │ │
│  │   (FAQ Admin)   │  │   (Core Data)   │  │                             │ │
│  │                 │  │                 │  │  • profiles                 │ │
│  │  • FAQ entries  │  │  • primmo_users │  │  • workout_sessions         │ │
│  │  • Categories   │  │  • conversations│  │  • exercise_ratings         │ │
│  │  • Templates    │  │  • user_prefs   │  │                             │ │
│  │  • Analytics    │  │  • embeddings   │  │                             │ │
│  │                 │  │                 │  │                             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. FAQ Management with Airtable

### 4.1 Why Airtable for FAQs?

| Requirement | Airtable Advantage |
|-------------|-------------------|
| **Non-technical editing** | Spreadsheet-like interface you already know |
| **Real-time sync** | Changes reflect immediately via n8n |
| **Version history** | Built-in revision tracking |
| **Collaboration** | Share with team, add comments |
| **API access** | Native n8n integration ([n8n Airtable Docs](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.airtable/)) |

### 4.2 Airtable Base Structure

#### Table: `FAQ_Entries`

| Field | Type | Description |
|-------|------|-------------|
| `ID` | Auto Number | Unique identifier |
| `Category` | Single Select | training, nutrition, recovery, motivation, general |
| `Question` | Long Text | Primary question text |
| `Question_Variants` | Long Text | Other ways to ask (one per line) |
| `Keywords` | Multi-Select | Trigger words: reps, sets, protein, etc. |
| `Response_Text` | Long Text | WhatsApp/text response (markdown OK) |
| `Response_Voice` | Long Text | Voice-optimized response (conversational) |
| `Requires_Profile` | Checkbox | Needs user data for personalization? |
| `Variables` | Multi-Select | {weight}, {protein_min}, {tdee}, etc. |
| `Priority` | Number | Higher = checked first (0-100) |
| `Active` | Checkbox | Enable/disable without deleting |
| `Usage_Count` | Number | Auto-updated by n8n |
| `Last_Used` | Date | Auto-updated |
| `Created` | Created Time | |
| `Modified` | Last Modified Time | |

#### Table: `Categories`

| Field | Type | Description |
|-------|------|-------------|
| `Name` | Single Line | training, nutrition, etc. |
| `Icon` | Single Line | Emoji for category |
| `Description` | Long Text | What belongs here |
| `FAQ_Count` | Count | Linked to FAQ_Entries |

#### Table: `Response_Templates`

| Field | Type | Description |
|-------|------|-------------|
| `Variable` | Single Line | {protein_min}, {tdee}, etc. |
| `Formula` | Long Text | How to calculate |
| `Example_Output` | Single Line | "120-165g" |
| `Requires` | Multi-Select | profile.weight, profile.height, etc. |

#### Table: `Usage_Analytics`

| Field | Type | Description |
|-------|------|-------------|
| `Date` | Date | |
| `FAQ_Entry` | Link | Which FAQ was used |
| `Channel` | Single Select | whatsapp, voice |
| `Response_Tier` | Single Select | exact, semantic, calculated, claude |
| `User_Rating` | Rating | 1-5 if collected |
| `Response_Time_ms` | Number | Latency tracking |

### 4.3 Airtable Views for Management

```
�� FAQ_Entries Base
├── 📋 All FAQs (Grid view - default)
├── 📋 By Category (Grouped by Category)
├── 📋 Most Used (Sorted by Usage_Count DESC)
├── 📋 Needs Review (Filter: Modified < 30 days ago)
├── 📋 Inactive (Filter: Active = false)
├── 📋 Missing Voice (Filter: Response_Voice is empty)
└── 📊 Usage Dashboard (Gallery view with charts)
```

### 4.4 Sample FAQ Entries in Airtable

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Category: training | Priority: 90 | Active: ✓                          │
├─────────────────────────────────────────────────────────────────────────┤
│ Question: How many reps should I do?                                    │
│                                                                         │
│ Question_Variants:                                                      │
│   What rep range is best?                                               │
│   How many repetitions per set?                                         │
│   Reps for muscle growth?                                               │
│                                                                         │
│ Keywords: [reps] [repetitions] [rep range]                             │
│                                                                         │
│ Response_Text:                                                          │
│   For muscle growth (hypertrophy): **8-12 reps** per set               │
│   For strength: **3-6 reps** with heavier weight                       │
│   For endurance: **15-20 reps** with lighter weight                    │
│                                                                         │
│   Most effective for most people: **8-10 reps** at a weight where      │
│   the last 2 reps are challenging but form stays solid.                │
│                                                                         │
│ Response_Voice:                                                         │
│   For muscle growth, aim for 8 to 12 reps per set.                     │
│   For pure strength, go heavier with 3 to 6 reps.                      │
│   For most people, 8 to 10 reps works great. Make sure the last       │
│   couple reps feel challenging, but keep your form solid.              │
│                                                                         │
│ Requires_Profile: ☐ | Variables: (none)                                │
│ Usage_Count: 342 | Last_Used: 2025-12-20                               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ Category: nutrition | Priority: 85 | Active: ✓                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Question: How much protein should I eat?                                │
│                                                                         │
│ Keywords: [protein] [protein intake] [how much protein]                │
│                                                                         │
│ Response_Text:                                                          │
│   **Target: 1.6-2.2g protein per kg bodyweight**                       │
│                                                                         │
│   {{#if profile.weight}}                                               │
│   For you at {weight}kg: **{protein_min}-{protein_max}g per day**      │
│   {{/if}}                                                               │
│                                                                         │
│   Spread across 4-5 meals for optimal absorption.                      │
│   Good sources: chicken, fish, eggs, Greek yogurt, legumes, tofu.      │
│                                                                         │
│ Response_Voice:                                                         │
│   You should aim for about 1.6 to 2.2 grams of protein per kilogram    │
│   of body weight.                                                       │
│   {{#if profile.weight}}                                               │
│   For you, that's around {protein_min} to {protein_max} grams daily.   │
│   {{/if}}                                                               │
│   Try to spread it across 4 to 5 meals throughout the day.             │
│                                                                         │
│ Requires_Profile: ✓ | Variables: [weight] [protein_min] [protein_max] │
│ Usage_Count: 289 | Last_Used: 2025-12-21                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. n8n Workflow Architecture

Based on [n8n's AI Agent capabilities](https://n8n.io/integrations/agent/) and [Vapi integration patterns](https://n8n.io/workflows/3427-automate-call-scheduling-with-voice-ai-receptionist-using-vapi-google-calendar-and-airtable/):

### 5.1 Core Workflows

```
📁 n8n Workflows
│
├── 🔄 01_WhatsApp_Inbound
│   └── Twilio Webhook → Message Router → Response Handler → Twilio Send
│
├── 🔄 02_Voice_Inbound
│   └── Vapi Webhook → Message Router → Response Handler → Vapi Response
│
├── 🔄 03_Message_Router (shared)
│   ├── Tier 1: Airtable FAQ Lookup
│   ├── Tier 2: Supabase Embedding Search
│   ├── Tier 3: Calculate Node (formulas)
│   └── Tier 4: Claude API Call
│
├── 🔄 04_FAQ_Sync
│   └── Airtable Trigger → Transform → Supabase Upsert → Generate Embeddings
│
├── 🔄 05_Proactive_Checkins
│   └── Cron Trigger → Check Schedule → Build Message → Send (WhatsApp/Voice)
│
├── 🔄 06_Analytics_Logger
│   └── Any Response → Log to Airtable Analytics → Update Usage Counts
│
└── 🔄 07_REPPIT_Sync
    └── Webhook Trigger → Fetch REPPIT Data → Cache in Supabase
```

### 5.2 Message Router Workflow (Detailed)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     03_Message_Router Workflow                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐                                                           │
│  │   START      │ ← Receives: { channel, user_id, message, context }        │
│  └──────┬───────┘                                                           │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 1. NORMALIZE MESSAGE                                                  │  │
│  │    • Lowercase                                                        │  │
│  │    • Remove punctuation                                               │  │
│  │    • Extract keywords                                                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 2. TIER 1: AIRTABLE FAQ LOOKUP                                        │  │
│  │    • Query: FAQ_Entries WHERE Active = true                           │  │
│  │    • Match: Keywords contains any(message_keywords)                   │  │
│  │    • OR: Question_Variants contains message                           │  │
│  │                                                                       │  │
│  │    IF match found with Priority > 50:                                 │  │
│  │       → Set tier = "exact"                                            │  │
│  │       → Continue to Step 6                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │ No match                                                          │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 3. TIER 2: SEMANTIC SEARCH                                            │  │
│  │    • Generate embedding for message (OpenAI ada-002)                  │  │
│  │    • Query Supabase: match_faq_embeddings(embedding, 0.85)           │  │
│  │                                                                       │  │
│  │    IF similarity > 0.85:                                              │  │
│  │       → Set tier = "semantic"                                         │  │
│  │       → Fetch FAQ by ID from Airtable                                 │  │
│  │       → Continue to Step 6                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │ No match                                                          │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 4. TIER 3: CALCULATED RESPONSE                                        │  │
│  │    • Check if message matches calculation patterns:                   │  │
│  │      - "my tdee", "my calories", "my protein", "my macros"           │  │
│  │      - "what should i weigh", "my bmr"                                │  │
│  │                                                                       │  │
│  │    IF calculation pattern AND user has profile:                       │  │
│  │       → Calculate values (BMR, TDEE, protein, etc.)                   │  │
│  │       → Build response from template                                  │  │
│  │       → Set tier = "calculated"                                       │  │
│  │       → Continue to Step 6                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │ No match                                                          │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 5. TIER 4: CLAUDE API                                                 │  │
│  │    • Build system prompt with:                                        │  │
│  │      - Base coach persona                                             │  │
│  │      - User profile (PRIMMO or REPPIT)                               │  │
│  │      - Recent conversation history                                    │  │
│  │      - REPPIT data if connected                                       │  │
│  │    • Call Claude API (Haiku for simple, Sonnet for complex)          │  │
│  │    • Set tier = "claude"                                              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 6. PROCESS TEMPLATE VARIABLES                                         │  │
│  │    • Replace {weight}, {protein_min}, {tdee}, etc.                   │  │
│  │    • Process conditionals: {{#if profile.weight}}...{{/if}}          │  │
│  │    • Handle missing data gracefully                                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 7. FORMAT FOR CHANNEL                                                 │  │
│  │                                                                       │  │
│  │    IF channel == "whatsapp":                                         │  │
│  │       → Use Response_Text (markdown OK)                               │  │
│  │       → Add emojis if appropriate                                     │  │
│  │                                                                       │  │
│  │    IF channel == "voice":                                            │  │
│  │       → Use Response_Voice (conversational)                           │  │
│  │       → Strip markdown, convert to spoken form                        │  │
│  │       → Add SSML pauses if needed                                     │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ 8. LOG & RETURN                                                       │  │
│  │    • Log to Analytics (tier, response_time, faq_id)                  │  │
│  │    • Update FAQ usage count in Airtable                              │  │
│  │    • Save to conversation history                                     │  │
│  │    • Return: { response, tier, response_time_ms }                    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Vapi + n8n Integration

Based on [Vapi's n8n integration guide](https://vapi.ai/library/how-to-connect-vapi-to-n8n-ai-agents-in-9-minutes):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VAPI + N8N VOICE FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHONE CALL INCOMING                                                        │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ VAPI ASSISTANT                                                        │  │
│  │                                                                       │  │
│  │ Model: Claude 3.5 Haiku (via Vapi)                                   │  │
│  │ Voice: ElevenLabs "Rachel" or PlayHT                                 │  │
│  │                                                                       │  │
│  │ System Prompt:                                                        │  │
│  │ "You are PRIMMO, a friendly AI fitness coach. When the user asks    │  │
│  │  a question, use the 'query_knowledge_base' tool to check for       │  │
│  │  answers before generating your own response."                       │  │
│  │                                                                       │  │
│  │ Tools:                                                                │  │
│  │  - query_knowledge_base (→ n8n webhook)                              │  │
│  │  - get_user_profile (→ n8n webhook)                                  │  │
│  │  - log_workout (→ n8n webhook)                                       │  │
│  │  - end_call                                                           │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         │ Tool Call: query_knowledge_base                                   │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ N8N WEBHOOK: /vapi/knowledge                                          │  │
│  │                                                                       │  │
│  │ Input: { "query": "how many reps should I do" }                      │  │
│  │                                                                       │  │
│  │ Process:                                                              │  │
│  │  1. Tier 1: Check Airtable FAQs                                      │  │
│  │  2. Tier 2: Semantic search if no exact match                        │  │
│  │  3. Return FAQ response OR { "use_llm": true }                       │  │
│  │                                                                       │  │
│  │ Output: {                                                             │  │
│  │   "found": true,                                                      │  │
│  │   "response": "For muscle growth, aim for 8 to 12 reps...",         │  │
│  │   "source": "faq",                                                    │  │
│  │   "faq_id": "rec123abc"                                               │  │
│  │ }                                                                     │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ VAPI SPEAKS RESPONSE                                                  │  │
│  │                                                                       │  │
│  │ If found: Speaks the FAQ response (already voice-optimized)          │  │
│  │ If not found: Uses Claude to generate response                       │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.4 Vapi Assistant Configuration

```json
{
  "name": "PRIMMO Voice Coach",
  "model": {
    "provider": "anthropic",
    "model": "claude-3-haiku-20240307",
    "temperature": 0.7,
    "systemPrompt": "You are PRIMMO, a friendly and knowledgeable AI fitness coach. You speak naturally and conversationally. Before answering fitness questions, always use the query_knowledge_base tool to check for established answers. Only generate your own response if the knowledge base doesn't have a relevant answer. Keep responses concise - this is a phone call, not a text message."
  },
  "voice": {
    "provider": "elevenlabs",
    "voiceId": "21m00Tcm4TlvDq8ikWAM",
    "stability": 0.5,
    "similarityBoost": 0.75
  },
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "query_knowledge_base",
        "description": "Search the PRIMMO knowledge base for answers to fitness questions. Always use this before generating your own answer.",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "The user's question to search for"
            }
          },
          "required": ["query"]
        }
      },
      "server": {
        "url": "https://your-n8n-instance.com/webhook/vapi/knowledge"
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_user_stats",
        "description": "Get the user's profile information and recent workout stats",
        "parameters": {
          "type": "object",
          "properties": {
            "phone_number": {
              "type": "string",
              "description": "The caller's phone number"
            }
          }
        }
      },
      "server": {
        "url": "https://your-n8n-instance.com/webhook/vapi/user-stats"
      }
    }
  ],
  "firstMessage": "Hey! This is PRIMMO, your AI fitness coach. How can I help you today?",
  "endCallMessage": "Great talking with you! Keep crushing those workouts. Bye!",
  "serverUrl": "https://your-n8n-instance.com/webhook/vapi/events",
  "serverUrlSecret": "your-secret-key"
}
```

---

## 6. FAQ Admin Interface Options

### 6.1 Option A: Airtable Interface (Recommended for Start)

**Pros:**
- Zero development needed
- Familiar spreadsheet interface
- Real-time collaboration
- Built-in forms for adding FAQs
- Mobile app for on-the-go edits

**Setup:**
1. Create Airtable base with tables above
2. Set up n8n sync workflow
3. Share base with team members

**Editing Flow:**
```
You open Airtable → Edit FAQ → Save
         ↓
n8n Trigger: "Record Updated"
         ↓
Update Supabase cache
         ↓
Regenerate embeddings if question changed
         ↓
Changes live in ~10 seconds
```

### 6.2 Option B: Custom Admin Dashboard (Phase 3)

Build a simple Next.js admin panel:

```typescript
// pages/admin/faqs.tsx - Future enhancement

interface FAQAdminProps {
  faqs: FAQ[]
}

export default function FAQAdmin({ faqs }: FAQAdminProps) {
  return (
    <div className="p-8">
      <h1>PRIMMO FAQ Management</h1>

      {/* Category filters */}
      <CategoryTabs categories={['training', 'nutrition', 'recovery', 'motivation']} />

      {/* FAQ list */}
      <FAQTable
        faqs={faqs}
        onEdit={(faq) => openEditor(faq)}
        onToggleActive={(faq) => toggleActive(faq.id)}
        onViewStats={(faq) => openStats(faq.id)}
      />

      {/* Quick add form */}
      <QuickAddFAQ onSubmit={createFAQ} />

      {/* Analytics sidebar */}
      <AnalyticsSidebar
        totalQueries={1234}
        faqHitRate={0.65}
        topFAQs={topFAQs}
        uncachedQuestions={uncachedQuestions}
      />
    </div>
  )
}
```

### 6.3 Option C: n8n Form + Airtable Hybrid

Create n8n forms for non-technical users:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    N8N FAQ MANAGEMENT FORM                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Add New FAQ Entry                                                          │
│  ─────────────────                                                          │
│                                                                              │
│  Category: [Training ▼]                                                     │
│                                                                              │
│  Primary Question:                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ How many reps should I do per set?                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Alternative Phrasings (one per line):                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ What rep range is best?                                             │   │
│  │ How many repetitions per set?                                       │   │
│  │ Reps for muscle growth?                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Keywords (comma-separated):                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ reps, repetitions, rep range                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Response (Text/WhatsApp):                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ For muscle growth: **8-12 reps** per set                            │   │
│  │ For strength: **3-6 reps** with heavier weight                      │   │
│  │ ...                                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Response (Voice - conversational):                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ For muscle growth, aim for 8 to 12 reps per set. For pure          │   │
│  │ strength, go heavier with 3 to 6 reps...                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Priority: [85    ] (0-100, higher = checked first)                        │
│                                                                              │
│  [x] Active                                                                 │
│  [ ] Requires user profile data                                             │
│                                                                              │
│                              [Cancel]  [Save FAQ]                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Voice vs Text Response Formatting

### 7.1 Why Separate Responses?

| Aspect | WhatsApp (Text) | Voice Call |
|--------|-----------------|------------|
| **Reading speed** | User controls | Agent controls |
| **Formatting** | Markdown, bullets, bold | Must be spoken naturally |
| **Length** | Can be longer, user skims | Must be concise |
| **Numbers** | "8-12 reps" | "eight to twelve reps" |
| **Emphasis** | **bold**, *italic* | Vocal stress, pauses |

### 7.2 Conversion Examples

```
TEXT VERSION:
"For muscle growth (hypertrophy): **8-12 reps** per set
For strength: **3-6 reps** with heavier weight

Most effective for most people: **8-10 reps** at a weight where
the last 2 reps are challenging but form stays solid."

VOICE VERSION:
"For muscle growth, aim for eight to twelve reps per set.
<break time="300ms"/>
For pure strength, go heavier with three to six reps.
<break time="500ms"/>
For most people, eight to ten reps works great.
Just make sure the last couple reps feel challenging,
but keep your form solid."
```

### 7.3 Auto-Conversion Rules (if Voice field empty)

```typescript
function textToVoice(textResponse: string): string {
  return textResponse
    // Remove markdown formatting
    .replace(/\*\*/g, '')
    .replace(/\*/g, '')
    .replace(/`/g, '')

    // Convert bullet points to spoken list
    .replace(/^[-•]\s*/gm, '')
    .replace(/^\d+\.\s*/gm, '')

    // Convert number ranges to spoken form
    .replace(/(\d+)-(\d+)/g, '$1 to $2')

    // Add pauses after sentences
    .replace(/\.\s+/g, '. <break time="300ms"/> ')

    // Soften imperatives
    .replace(/^Do /gm, 'You should ')
    .replace(/^Make sure/gm, 'Just make sure')

    // Truncate if too long (voice should be <30 seconds)
    .slice(0, 500)
}
```

---

## 8. Cost Analysis

### 8.1 Per-Interaction Cost Breakdown

| Tier | WhatsApp Cost | Voice Cost | Notes |
|------|---------------|------------|-------|
| **Tier 1 (FAQ)** | $0.005 (Twilio) | $0.05/min (Vapi base) | FAQ free |
| **Tier 2 (Semantic)** | $0.005 + $0.0001 | $0.05/min + $0.0001 | Embedding cost |
| **Tier 3 (Calculated)** | $0.005 | $0.05/min | Formulas free |
| **Tier 4 (Claude)** | $0.005 + $0.01-0.03 | $0.05/min + $0.01-0.03 | LLM cost |

### 8.2 Monthly Projection (1000 interactions)

| Scenario | WhatsApp Only | Voice Only | 70/30 Split |
|----------|---------------|------------|-------------|
| All Claude | $15-35 | $80-120 | $35-60 |
| With Tiering (65% cached) | $8-15 | $55-75 | $22-35 |
| **Savings** | **47-57%** | **31-38%** | **40-42%** |

### 8.3 Voice Call Cost Breakdown

```
1-minute voice call with Vapi:

Orchestration (Vapi):     $0.05
Transcription (Whisper):  $0.01
LLM (Claude Haiku):       $0.01-0.02 (if needed)
TTS (ElevenLabs):         $0.03
─────────────────────────────────
Total:                    $0.10-0.11/minute

With FAQ caching (no LLM):
Total:                    $0.09/minute (10% savings)
```

---

## 9. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Set up Airtable base with FAQ structure
- [ ] Create 30 initial FAQ entries (training, nutrition, recovery)
- [ ] Set up n8n cloud or self-hosted instance
- [ ] Create Airtable → Supabase sync workflow

### Phase 2: WhatsApp Integration (Weeks 3-4)
- [ ] Build WhatsApp inbound workflow in n8n
- [ ] Implement Tier 1 (FAQ matching)
- [ ] Implement Tier 3 (calculations)
- [ ] Connect Tier 4 (Claude fallback)

### Phase 3: Voice Integration (Weeks 5-6)
- [ ] Set up Vapi.ai account and assistant
- [ ] Configure Vapi → n8n tool webhooks
- [ ] Add Voice-optimized responses to FAQs
- [ ] Test end-to-end voice calls

### Phase 4: Semantic Search (Weeks 7-8)
- [ ] Generate embeddings for FAQ variants
- [ ] Implement Tier 2 semantic matching
- [ ] Tune similarity threshold
- [ ] Monitor and optimize

### Phase 5: Analytics & Optimization (Ongoing)
- [ ] Build usage analytics dashboard
- [ ] Identify FAQ candidates from uncached queries
- [ ] A/B test response formats
- [ ] Expand FAQ database based on patterns

---

## 10. Key Resources

### Documentation
- [Vapi.ai Documentation](https://docs.vapi.ai/quickstart/introduction)
- [n8n Supabase Integration](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/)
- [n8n Airtable Integration](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.airtable/)
- [Vapi + n8n Connection Guide](https://vapi.ai/library/how-to-connect-vapi-to-n8n-ai-agents-in-9-minutes)

### Templates
- [n8n Voice AI Receptionist with Vapi](https://n8n.io/workflows/3427-automate-call-scheduling-with-voice-ai-receptionist-using-vapi-google-calendar-and-airtable/)
- [n8n AI Voice Chatbot](https://n8n.io/workflows/2846-ai-voice-chatbot-with-elevenlabs-and-openai-for-customer-service-and-restaurants/)

### Comparison Articles
- [Voice Agent Platform Comparison 2025](https://softcery.com/lab/choosing-the-right-voice-agent-platform-in-2025)
- [Vapi AI Review 2025](https://www.lindy.ai/blog/vapi-ai)

---

**Document Version:** 1.0
**Created:** 2025-12-21
**Author:** PRIMMO Design Team