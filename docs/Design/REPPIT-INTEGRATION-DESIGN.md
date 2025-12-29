# PRIMMO-REPPIT Integration Design

**Version:** 2.0
**Date:** 2025-12-21
**Status:** Design Complete - Ready for Development

---

## 1. Executive Summary

This document outlines the integration strategy between PRIMMO (AI Strength Coach) and REPPIT (Strength Profile Tracker mobile app). PRIMMO provides multi-channel communication (WhatsApp + Voice) with intelligent response tiering and scheduled proactive outreach.

**Key Design Principles:**
- **Multi-channel:** WhatsApp (Twilio) + Voice (Vapi.ai) share the same brain
- **Cost-optimized:** 4-tier response system minimizes Claude API calls
- **Optional REPPIT integration:** Works standalone or connected
- **Proactive scheduling:** Automated check-ins via n8n
- **REPPIT as source of truth** for connected users
- **Security-first** with proper data isolation

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [APP_PRD.md](./APP_PRD.md) | Product requirements |
| [UNIFIED-VOICE-WHATSAPP-DESIGN.md](./UNIFIED-VOICE-WHATSAPP-DESIGN.md) | Multi-channel architecture |
| [RESPONSE-TIERING-DESIGN.md](./RESPONSE-TIERING-DESIGN.md) | FAQ & cost optimization |

---

## 2. Integration Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                              │
├────────────────────────────┬────────────────────────────────────────┤
│      WhatsApp (PRIMMO)     │         Mobile App (REPPIT)            │
│                            │                                         │
│  ┌──────────────────────┐  │  ┌────────────────────────────────┐   │
│  │  Twilio WhatsApp API │  │  │  PWA / Capacitor Android App   │   │
│  └──────────┬───────────┘  │  └───────────────┬────────────────┘   │
│             │              │                  │                     │
│             ▼              │                  ▼                     │
│  ┌──────────────────────┐  │  ┌────────────────────────────────┐   │
│  │    n8n / Webhook     │  │  │      localStorage + Sync       │   │
│  │      Handler         │  │  │         Queue                  │   │
│  └──────────┬───────────┘  │  └───────────────┬────────────────┘   │
│             │              │                  │                     │
└─────────────┼──────────────┴──────────────────┼─────────────────────┘
              │                                 │
              ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SUPABASE (Shared)                            │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │
│  │   primmo_users  │  │  reppit_users   │  │  user_connections   │ │
│  │ (WhatsApp IDs)  │  │ (Google OAuth)  │  │ (links both)        │ │
│  └────────┬────────┘  └────────┬────────┘  └──────────┬──────────┘ │
│           │                    │                      │             │
│           └────────────────────┼──────────────────────┘             │
│                                │                                     │
│  ┌─────────────────────────────┼─────────────────────────────────┐  │
│  │                   Shared Data Layer                            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │ profiles │  │ workouts │  │ body_meas.  │  │ 1rm_records│  │  │
│  │  └──────────┘  └──────────┘  └─────────────┘  └────────────┘  │  │
│  │                                                                │  │
│  │  ┌─────────────────────┐  ┌───────────────────────────────┐   │  │
│  │  │   conversations     │  │   proactive_checkins          │   │  │
│  │  │   (PRIMMO only)     │  │   (PRIMMO only)                │   │  │
│  │  └─────────────────────┘  └───────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Claude API Integration                      │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │  System Prompt Builder (includes REPPIT context if       │  │  │
│  │  │  connected)                                              │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Integration Modes

| Mode | Description | User Experience |
|------|-------------|-----------------|
| **Standalone PRIMMO** | User has not connected REPPIT | Full coaching via WhatsApp, manual data entry |
| **Connected Mode** | User linked WhatsApp to REPPIT account | Rich data-driven coaching using REPPIT history |
| **Transitional** | User starts standalone, later connects | Historical data from both sources merged |

---

## 3. Unified Schema Design

### 3.1 Schema Strategy

Rather than modifying REPPIT's existing schema, we extend it with PRIMMO-specific tables while creating a linking layer.

### 3.2 New Tables (PRIMMO-specific)

```sql
-- PRIMMO WhatsApp Users (separate from REPPIT's Google OAuth users)
CREATE TABLE primmo_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  whatsapp_phone TEXT UNIQUE NOT NULL,  -- E.164 format: +1234567890
  display_name TEXT,
  first_message_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  timezone TEXT DEFAULT 'UTC',
  preferred_language TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Links PRIMMO users to REPPIT accounts (optional connection)
CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  reppit_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  connection_code TEXT UNIQUE,  -- Short code for linking: "ABC123"
  connection_status TEXT CHECK (connection_status IN ('pending', 'active', 'revoked')) DEFAULT 'pending',
  connected_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(primmo_user_id),  -- One PRIMMO user can only connect to one REPPIT account
  UNIQUE(reppit_user_id)   -- One REPPIT account can only be connected to one PRIMMO user
);

-- Conversation history for Claude context
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user', 'assistant', 'system')) NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',  -- text, image, voice_transcript
  twilio_message_sid TEXT,  -- For tracking
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Proactive check-in scheduling
CREATE TABLE proactive_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  checkin_type TEXT CHECK (checkin_type IN (
    'workout_reminder', 'progress_check', 'motivation',
    'rest_day_reminder', 'weekly_summary', 'nutrition_reminder'
  )) NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  sent_at TIMESTAMPTZ,
  message_content TEXT,
  status TEXT CHECK (status IN ('scheduled', 'sent', 'failed', 'cancelled')) DEFAULT 'scheduled',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1RM Records (standalone PRIMMO users who don't use REPPIT)
CREATE TABLE primmo_one_rep_max (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  exercise TEXT NOT NULL,  -- Can be freeform text for flexibility
  weight_kg NUMERIC(5,1) NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  source TEXT DEFAULT 'whatsapp',  -- 'whatsapp' or 'synced_from_reppit'
  UNIQUE(primmo_user_id, exercise)  -- Only keep latest per exercise
);

-- Body measurements for standalone PRIMMO users
CREATE TABLE primmo_body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  measurement_date DATE NOT NULL,
  weight_kg NUMERIC(5,1),
  body_fat_percent NUMERIC(4,1),
  waist_cm NUMERIC(5,1),
  chest_cm NUMERIC(5,1),
  arms_cm NUMERIC(5,1),
  source TEXT DEFAULT 'whatsapp',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PRIMMO-specific profile (for standalone users or to extend REPPIT profile)
CREATE TABLE primmo_user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE UNIQUE,
  height_cm NUMERIC(5,1),
  weight_kg NUMERIC(5,1),
  body_fat_percent NUMERIC(4,1),
  bmi NUMERIC(4,1),
  goal TEXT,  -- Free text: "visible six-pack in 8-12 weeks"
  workout_split TEXT,  -- "3-day split", "PPL", "Upper/Lower"
  training_months INTEGER,
  diet_notes TEXT,  -- Any dietary restrictions or preferences
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_conversations_user ON conversations(primmo_user_id, created_at DESC);
CREATE INDEX idx_checkins_scheduled ON proactive_checkins(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX idx_connections_code ON user_connections(connection_code) WHERE connection_status = 'pending';
```

### 3.3 Schema Mapping (REPPIT to PRIMMO)

| REPPIT Field | PRIMMO Equivalent | Notes |
|-------------|-------------------|-------|
| `profiles.name` | `primmo_user_profile.display_name` | PRIMMO uses WhatsApp name initially |
| `profiles.weight` | `primmo_user_profile.weight_kg` | Same unit (kg) |
| `profiles.height` | `primmo_user_profile.height_cm` | Same unit (cm) |
| `profiles.sex` | (derived) | Used for multiplier selection |
| `profiles.goal` | `primmo_user_profile.goal` | REPPIT: lose/maintain/gain; PRIMMO: freeform |
| `profiles.exercise_ratings` | Computed from workout history | REPPIT stores levels; PRIMMO computes from PRs |
| `workout_sessions.sets` | `primmo_one_rep_max` (derived) | PRIMMO extracts max weight per exercise |

### 3.4 Row Level Security for PRIMMO Tables

```sql
-- Enable RLS
ALTER TABLE primmo_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE proactive_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE primmo_one_rep_max ENABLE ROW LEVEL SECURITY;
ALTER TABLE primmo_body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE primmo_user_profile ENABLE ROW LEVEL SECURITY;

-- REPPIT users can view their connected PRIMMO data
CREATE POLICY "REPPIT users view connected PRIMMO data" ON user_connections
  FOR SELECT USING (reppit_user_id = auth.uid());

-- REPPIT users can revoke connection
CREATE POLICY "REPPIT users can update connection" ON user_connections
  FOR UPDATE USING (reppit_user_id = auth.uid());
```

---

## 4. User Linking Strategy

### 4.1 Linking Flow

```
┌───────────────────────────────────────────────────────────────────┐
│                    USER LINKING FLOW                               │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. User asks PRIMMO: "Connect my REPPIT account"                  │
│     ▼                                                              │
│  2. PRIMMO generates unique 6-char code (e.g., "ABC123")           │
│     - Stored in user_connections with status='pending'             │
│     - Expires after 15 minutes                                     │
│     ▼                                                              │
│  3. PRIMMO responds via WhatsApp:                                  │
│     "Open REPPIT app and go to Settings > Connect to PRIMMO.       │
│      Enter this code: ABC123 (expires in 15 min)"                  │
│     ▼                                                              │
│  4. User opens REPPIT app, navigates to Settings                   │
│     ▼                                                              │
│  5. User enters code in REPPIT                                     │
│     ▼                                                              │
│  6. REPPIT validates code:                                         │
│     - Check code exists and status='pending'                       │
│     - Check not expired                                            │
│     - Update connection: reppit_user_id, status='active'           │
│     ▼                                                              │
│  7. REPPIT shows: "Connected! PRIMMO can now see your workouts."   │
│     ▼                                                              │
│  8. PRIMMO sends confirmation:                                     │
│     "Great! I can now see your REPPIT profile and workout history. │
│      I see you're at Intermediate level with focus on upper body.  │
│      Let's crush those goals together!"                            │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘
```

### 4.2 Connection Code Generation

```typescript
// Generate 6-character alphanumeric code (excluding confusing chars)
function generateConnectionCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'  // Exclude I, O, 0, 1
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
}
```

### 4.3 Alternative Linking Methods

| Method | Pros | Cons |
|--------|------|------|
| **Code Entry (Primary)** | Simple, secure, works across devices | Requires manual entry |
| **Deep Link** | One-tap connection | Complex setup, platform differences |
| **QR Code** | Visual, easy to scan | Requires camera access, display space |
| **Email Matching** | Automatic | Privacy concerns, requires same email |

**Recommendation:** Start with Code Entry as primary method. Add deep linking in future for better UX.

---

## 5. Data Sync Strategy

### 5.1 Sync Direction

```
REPPIT ────────────────────► PRIMMO
(Source of Truth)          (Consumer)

Workout history      ──►    Claude context
Exercise PRs         ──►    Coaching insights
Profile data         ──►    Personalization
Exercise ratings     ──►    Level-aware tips
```

**Note:** PRIMMO does not write back to REPPIT. This keeps REPPIT as the single source of truth for workout data.

### 5.2 What Syncs

| Data Type | Sync Frequency | Direction | Notes |
|-----------|----------------|-----------|-------|
| Profile (age, weight, height, sex) | On connection + daily | REPPIT -> PRIMMO | Used for strength calculations |
| Exercise Ratings (levels) | On connection + hourly | REPPIT -> PRIMMO | For level-aware coaching |
| Workout Sessions (last 30 days) | On connection + hourly | REPPIT -> PRIMMO | For context in conversations |
| PRs per exercise | Computed from workouts | REPPIT -> PRIMMO | Calculated from workout history |
| Conversations | Never | PRIMMO only | Privacy - stays in PRIMMO |

### 5.3 Sync Implementation

```typescript
// PRIMMO Service: Fetch REPPIT data for connected user
async function fetchREPPITContext(primmoUserId: string): Promise<REPPITContext | null> {
  // 1. Check if user has active connection
  const { data: connection } = await supabase
    .from('user_connections')
    .select('reppit_user_id')
    .eq('primmo_user_id', primmoUserId)
    .eq('connection_status', 'active')
    .single()

  if (!connection) return null

  // 2. Fetch REPPIT profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('user_id', connection.reppit_user_id)
    .limit(1)
    .single()

  // 3. Fetch recent workouts (last 30 days)
  const thirtyDaysAgo = new Date()
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

  const { data: workouts } = await supabase
    .from('workout_sessions')
    .select('*')
    .eq('profile_id', profile.id)
    .gte('date', thirtyDaysAgo.toISOString().split('T')[0])
    .order('date', { ascending: false })

  // 4. Calculate PRs from workout history
  const prs = calculatePRsFromWorkouts(workouts)

  // 5. Return formatted context
  return {
    profile: {
      name: profile.name,
      weight: profile.weight,
      height: profile.height,
      sex: profile.sex,
      goal: GOAL_NAMES[profile.goal] || profile.goal,
      activityLevel: profile.activity_level,
      exerciseRatings: profile.exercise_ratings
    },
    recentWorkouts: formatWorkoutsForContext(workouts),
    personalRecords: prs,
    overallLevel: calculateOverallLevel(profile.exercise_ratings),
    lastWorkoutDate: workouts?.[0]?.date
  }
}
```

### 5.4 Caching Strategy

```
┌─────────────────────────────────────────────────────────┐
│                   CACHING LAYERS                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  L1: In-Memory Cache (per conversation)                  │
│      - TTL: 5 minutes                                    │
│      - Holds: REPPIT context for active conversations    │
│                                                          │
│  L2: Supabase Edge Function Cache                        │
│      - TTL: 15 minutes                                   │
│      - Reduces DB queries for same user                  │
│                                                          │
│  L3: Materialized View (optional, for heavy users)       │
│      - Refresh: Hourly                                   │
│      - Pre-computed: PRs, overall level, weekly stats    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 6. API Endpoints & Services

### 6.1 PRIMMO Backend Services

```typescript
// src/api/services/reppitIntegration.ts

interface REPPITIntegrationService {
  // Connection Management
  generateConnectionCode(primmoUserId: string): Promise<{ code: string; expiresAt: Date }>
  validateConnectionCode(code: string, reppitUserId: string): Promise<{ success: boolean; error?: string }>
  revokeConnection(primmoUserId: string): Promise<void>
  getConnectionStatus(primmoUserId: string): Promise<'connected' | 'pending' | 'not_connected'>

  // Data Fetching
  fetchREPPITContext(primmoUserId: string): Promise<REPPITContext | null>
  fetchLatestWorkouts(primmoUserId: string, limit?: number): Promise<WorkoutSummary[]>
  fetchExercisePR(primmoUserId: string, exerciseName: string): Promise<PRRecord | null>
  fetchOverallStats(primmoUserId: string): Promise<OverallStats | null>

  // For standalone PRIMMO users
  saveManualPR(primmoUserId: string, exercise: string, weight: number): Promise<void>
  saveBodyMeasurement(primmoUserId: string, measurement: BodyMeasurement): Promise<void>
}
```

### 6.2 API Endpoints

```
POST   /api/primmo/connection/generate    - Generate connection code
POST   /api/primmo/connection/validate    - Validate and activate connection (called from REPPIT)
DELETE /api/primmo/connection             - Revoke connection
GET    /api/primmo/connection/status      - Check connection status

GET    /api/primmo/context                - Get full REPPIT context for Claude
GET    /api/primmo/workouts               - Get recent workouts
GET    /api/primmo/pr/:exercise           - Get PR for specific exercise
GET    /api/primmo/stats                  - Get overall stats

POST   /api/primmo/webhook/twilio         - Twilio incoming message handler
POST   /api/primmo/checkin/schedule       - Schedule proactive check-in
```

### 6.3 REPPIT App Changes

New settings page section:

```typescript
// REPPIT: src/app/settings/PrimmoConnection.tsx

interface PrimmoConnectionProps {
  userId: string
}

function PrimmoConnection({ userId }: PrimmoConnectionProps) {
  const [connectionStatus, setConnectionStatus] = useState<'not_connected' | 'connected'>()
  const [code, setCode] = useState('')

  const handleConnect = async () => {
    const result = await validatePrimmoCode(code, userId)
    if (result.success) {
      setConnectionStatus('connected')
      toast.success('Connected to PRIMMO! Your AI coach can now access your workout data.')
    } else {
      toast.error(result.error || 'Invalid or expired code')
    }
  }

  const handleDisconnect = async () => {
    await revokeConnection(userId)
    setConnectionStatus('not_connected')
    toast.success('Disconnected from PRIMMO')
  }

  return (
    <div className="p-4">
      <h3 className="font-bold">PRIMMO AI Coach</h3>
      {connectionStatus === 'connected' ? (
        <>
          <p className="text-green-600">Connected</p>
          <button onClick={handleDisconnect}>Disconnect</button>
        </>
      ) : (
        <>
          <p>Enter the code from your WhatsApp conversation with PRIMMO:</p>
          <input
            value={code}
            onChange={e => setCode(e.target.value.toUpperCase())}
            maxLength={6}
            placeholder="ABC123"
          />
          <button onClick={handleConnect}>Connect</button>
        </>
      )}
    </div>
  )
}
```

---

## 7. System Prompt Enhancement

### 7.1 Dynamic System Prompt Structure

```typescript
function buildSystemPrompt(primmoUserId: string, reppitContext: REPPITContext | null): string {
  const basePrompt = `
You are PRIMMO, a dedicated AI strength and fitness coach. You communicate via WhatsApp and provide personalized, practical, science-based coaching.

COMMUNICATION STYLE:
- Direct and actionable
- Use data when available
- Motivational but not preachy
- Acknowledge struggles honestly
- Remind of long-term vision when motivation is low

CAPABILITIES:
1. Training advice and workout programming
2. Nutrition guidance (affordable and practical)
3. Progress tracking and analysis
4. Motivational support during difficult times
5. Recovery and rest recommendations
`

  if (!reppitContext) {
    // Standalone user prompt
    return basePrompt + `

USER STATUS: Standalone (not connected to REPPIT app)

You are working with limited data. You can:
- Ask the user about their workouts and progress
- Track information they share in conversation
- Suggest they download REPPIT for automatic tracking
- Store PRs and body measurements they report

When the user shares workout data, acknowledge it and provide feedback.
`
  }

  // Connected user prompt with full REPPIT context
  return basePrompt + `

USER STATUS: Connected to REPPIT app

USER PROFILE:
- Name: ${reppitContext.profile.name}
- Weight: ${reppitContext.profile.weight} kg
- Height: ${reppitContext.profile.height} cm
- Sex: ${reppitContext.profile.sex || 'Not specified'}
- Goal: ${reppitContext.profile.goal || 'Not specified'}
- Activity Level: ${reppitContext.profile.activityLevel || 'Not specified'}
- Overall Strength Level: ${reppitContext.overallLevel || 'Not rated yet'}

EXERCISE RATINGS (from REPPIT):
${formatExerciseRatings(reppitContext.profile.exerciseRatings)}

PERSONAL RECORDS:
${formatPRs(reppitContext.personalRecords)}

RECENT WORKOUT HISTORY (Last 30 days):
${formatWorkoutHistory(reppitContext.recentWorkouts)}

LAST WORKOUT: ${reppitContext.lastWorkoutDate || 'No recent workouts'}

COACHING GUIDELINES:
1. Reference their actual workout data when giving advice
2. Notice patterns (e.g., "You've been crushing leg day but skipping arms")
3. Celebrate PRs and level-ups they've achieved in REPPIT
4. Use their strength levels to calibrate advice complexity
5. Track days since last workout for rest/motivation prompts
6. Reference specific exercises and weights from their history
`
}
```

### 7.2 Context Injection Example

```typescript
// Before calling Claude API
async function handleIncomingMessage(whatsappPhone: string, message: string) {
  // 1. Get or create PRIMMO user
  const primmoUser = await getOrCreatePrimmoUser(whatsappPhone)

  // 2. Fetch REPPIT context if connected
  const reppitContext = await fetchREPPITContext(primmoUser.id)

  // 3. Get conversation history (last 10 messages)
  const conversationHistory = await getConversationHistory(primmoUser.id, 10)

  // 4. Build system prompt
  const systemPrompt = buildSystemPrompt(primmoUser.id, reppitContext)

  // 5. Call Claude API
  const response = await claude.messages.create({
    model: 'claude-3-haiku-20240307',  // or sonnet for better quality
    max_tokens: 1024,
    system: systemPrompt,
    messages: [
      ...conversationHistory.map(msg => ({
        role: msg.role as 'user' | 'assistant',
        content: msg.content
      })),
      { role: 'user', content: message }
    ]
  })

  // 6. Save response to conversation history
  await saveConversation(primmoUser.id, 'assistant', response.content[0].text)

  // 7. Send via Twilio
  await sendWhatsAppMessage(whatsappPhone, response.content[0].text)
}
```

---

## 8. Data Privacy & Security

### 8.1 Privacy Considerations

| Concern | Mitigation |
|---------|------------|
| **WhatsApp number exposure** | Stored encrypted, never exposed via REPPIT |
| **REPPIT data access scope** | Connection is explicit opt-in with clear data scope |
| **Conversation privacy** | Conversations stored separately, not synced to REPPIT |
| **Revocation** | User can disconnect anytime from either app |
| **Data retention** | Conversation history pruned after 90 days |

### 8.2 Security Implementation

```sql
-- Encrypt WhatsApp phone numbers at rest
-- Use pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Function to encrypt phone number
CREATE OR REPLACE FUNCTION encrypt_phone(phone TEXT, key TEXT)
RETURNS BYTEA AS $$
  SELECT pgp_sym_encrypt(phone, key)
$$ LANGUAGE SQL;

-- Function to decrypt phone number
CREATE OR REPLACE FUNCTION decrypt_phone(encrypted BYTEA, key TEXT)
RETURNS TEXT AS $$
  SELECT pgp_sym_decrypt(encrypted, key)
$$ LANGUAGE SQL;
```

---

## 9. Migration Path

### 9.1 Implementation Phases

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Standalone PRIMMO** | Weeks 1-8 | Full PRIMMO without REPPIT integration |
| **Phase 2: Schema Extension** | Week 9 | Add connection tables, test RLS |
| **Phase 3: Linking Flow** | Week 10 | Code generation, REPPIT settings UI |
| **Phase 4: Data Sync** | Week 11 | Context fetching, prompt integration |
| **Phase 5: Testing** | Week 12 | End-to-end testing, security audit |

### 9.2 Backward Compatibility

- REPPIT continues to work without PRIMMO
- Existing REPPIT users can choose to never connect
- PRIMMO standalone users get full experience without REPPIT
- Connection is purely additive enhancement

---

## 10. Future Enhancements

### 10.1 Potential Future Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Bi-directional sync** | PRIMMO can create workouts in REPPIT | Medium |
| **Push notifications** | PRIMMO triggers REPPIT notifications | Low |
| **Voice transcription** | Convert voice notes to workout logs | High |
| **Shared goal setting** | Goals sync between both apps | Medium |
| **Multi-profile support** | PRIMMO can coach for different REPPIT profiles | Low |

### 10.2 Integration Extensibility

The architecture supports future integrations:
- Apple Health / Google Fit (via REPPIT)
- Wearable data (heart rate, sleep)
- Nutrition apps (MyFitnessPal, etc.)
- Calendar integration for workout scheduling

---

## 11. Critical Files Reference

### 11.1 REPPIT Files (Source)

| File | Purpose |
|------|---------|
| [types.ts](../../strength_profile_tracker/src/lib/supabase/types.ts) | REPPIT's database types |
| [types/index.ts](../../strength_profile_tracker/src/types/index.ts) | Core types (Exercise, Level, Profile) |
| [workouts.ts](../../strength_profile_tracker/src/lib/storage/workouts.ts) | Workout storage patterns |
| [profiles.ts](../../strength_profile_tracker/src/lib/storage/profiles.ts) | Profile management |
| [strength.ts](../../strength_profile_tracker/src/lib/calculations/strength.ts) | Exercise definitions |

### 11.2 PRIMMO Files to Create

| File | Purpose |
|------|---------|
| `src/api/services/reppitIntegration.ts` | Core integration service |
| `src/api/handlers/connection.ts` | Connection code endpoints |
| `src/lib/promptBuilder.ts` | Dynamic system prompt construction |
| `supabase/migrations/primmo_tables.sql` | New table definitions |

### 11.3 REPPIT Files to Modify

| File | Purpose |
|------|---------|
| `src/app/settings/page.tsx` | Add PRIMMO connection section |
| `src/lib/supabase/types.ts` | Add connection table types |

---

## 12. Appendix: REPPIT Data Types Reference

### Exercise Types (from REPPIT)

```typescript
type Exercise =
  // Chest
  | 'benchPress' | 'inclineBench' | 'dumbbellPress' | 'cableFly'
  // Back
  | 'deadlift' | 'barbellRow' | 'latPulldown' | 'pullUps' | 'cableRow'
  // Shoulders
  | 'shoulderPressBarbell' | 'shoulderPressMachine' | 'shoulderPressDumbbell'
  | 'sideLateralDumbbell' | 'sideLateralCable' | 'frontRaise'
  // Legs
  | 'squat' | 'legPress' | 'romanianDeadlift' | 'legCurl' | 'legExtension' | 'calfRaise'
  // Arms
  | 'bicepCurlBarbell' | 'bicepCurlDumbbell' | 'tricepPushdown' | 'skullCrushers'

type Level = 'beginner' | 'novice' | 'intermediate' | 'advanced'
type BodyPart = 'chest' | 'back' | 'shoulders' | 'legs' | 'arms' | 'core'
type Sex = 'male' | 'female'
type ActivityLevel = 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'
type Goal = 'lose' | 'maintain' | 'gain'
```

### Profile Structure (from REPPIT)

```typescript
interface Profile {
  id: string
  name: string                  // max 50 characters
  age: number                   // 13-100
  height: number                // 100-250 cm
  weight: number                // 30-300 kg
  sex?: Sex
  dailySteps?: number           // 0-50000
  activityLevel?: ActivityLevel
  goal?: Goal
  exerciseRatings: Partial<Record<Exercise, Level>>
  createdAt: string
  updatedAt: string
}
```

### Workout Session Structure (from REPPIT)

```typescript
interface WorkoutSet {
  weight: number | null  // kg
  reps: number | null
}

interface WorkoutSession {
  id: string
  date: string           // YYYY-MM-DD
  exerciseId: Exercise
  profileId: string
  sets: WorkoutSet[]     // Always 3 sets
}
```

---

## 13. Scheduling & Proactive Outreach

### 13.1 Scheduling Architecture

Based on [n8n + Vapi workflow templates](https://n8n.io/workflows/3427-automate-call-scheduling-with-voice-ai-receptionist-using-vapi-google-calendar-and-airtable/):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SCHEDULING SYSTEM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    PROACTIVE TRIGGERS                                │   │
│  │                                                                      │   │
│  │   n8n Cron Workflows:                                               │   │
│  │   • Morning motivation (8am user timezone)                          │   │
│  │   • Workout reminder (based on user's split schedule)               │   │
│  │   • Weekly progress summary (Sunday evening)                        │   │
│  │   • Rest day reminder (after 3 consecutive training days)           │   │
│  │   • Check-in if no workout logged (3+ days)                         │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    OUTBOUND CHANNELS                                 │   │
│  │                                                                      │   │
│  │   WhatsApp (Twilio):                                                │   │
│  │   • Template messages for reminders                                 │   │
│  │   • Rich text with formatting                                       │   │
│  │   • Instant delivery                                                 │   │
│  │                                                                      │   │
│  │   Voice Call (Vapi.ai):                                             │   │
│  │   • Weekly check-in calls (scheduled)                               │   │
│  │   • Progress review calls                                           │   │
│  │   • Triggered by n8n workflow                                       │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 13.2 Scheduled Call Schema

```sql
-- Scheduled outbound calls
CREATE TABLE scheduled_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,
  call_type TEXT CHECK (call_type IN (
    'weekly_checkin', 'progress_review', 'motivation', 'custom'
  )) NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 5,
  vapi_call_id TEXT,  -- Vapi call reference
  status TEXT CHECK (status IN (
    'scheduled', 'in_progress', 'completed', 'failed', 'cancelled', 'no_answer'
  )) DEFAULT 'scheduled',
  call_summary TEXT,  -- AI-generated summary after call
  user_sentiment TEXT,  -- positive, neutral, negative
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_scheduled_calls_pending ON scheduled_calls(scheduled_at)
  WHERE status = 'scheduled';
```

### 13.3 n8n Workflow: Outbound Call Scheduler

Based on [Vapi outbound call automation](https://n8n.io/workflows/6577-automate-outbound-voice-calls-with-vapi-from-form-submissions/):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 WEEKLY CHECK-IN CALL WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. CRON TRIGGER                                                            │
│     └── Every Sunday at 6pm (user's timezone)                               │
│                                                                              │
│  2. FETCH USERS FOR CALLS                                                   │
│     └── Supabase: Get users with weekly_call_enabled = true                 │
│                                                                              │
│  3. CHECK LAST CALL STATUS                                                  │
│     └── Skip if called within 6 days                                        │
│                                                                              │
│  4. BUILD CALL CONTEXT                                                      │
│     └── Fetch REPPIT data (workouts, PRs, progress)                        │
│     └── Calculate: workouts this week, PRs hit, consistency %              │
│                                                                              │
│  5. INITIATE VAPI OUTBOUND CALL                                            │
│     └── POST to Vapi /call/phone                                            │
│     └── Include: user phone, assistant ID, context variables               │
│                                                                              │
│  6. LOG CALL ATTEMPT                                                        │
│     └── Insert into scheduled_calls with status='in_progress'              │
│                                                                              │
│  7. WEBHOOK: CALL COMPLETED                                                 │
│     └── Update call status, save transcript summary                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 13.4 Vapi Outbound Call Configuration

```typescript
// n8n HTTP Request to Vapi
const outboundCallPayload = {
  phoneNumberId: process.env.VAPI_PHONE_NUMBER_ID,
  customer: {
    number: userPhone,  // E.164 format
    name: userName
  },
  assistantId: process.env.VAPI_ASSISTANT_ID,
  assistantOverrides: {
    firstMessage: `Hey ${userName}! This is PRIMMO, your AI fitness coach.
      I'm calling for your weekly check-in. How's the training going?`,
    model: {
      messages: [
        {
          role: 'system',
          content: buildWeeklyCallPrompt(userContext)
        }
      ]
    }
  }
}

function buildWeeklyCallPrompt(context: UserContext): string {
  return `
You are PRIMMO making a weekly check-in call to ${context.name}.

THIS WEEK'S STATS:
- Workouts completed: ${context.workoutsThisWeek}
- New PRs: ${context.prsThisWeek.join(', ') || 'None yet'}
- Consistency: ${context.consistencyPercent}%

RECENT ACHIEVEMENTS:
${context.recentAchievements.join('\n')}

CALL OBJECTIVES:
1. Celebrate their wins (PRs, consistency)
2. Ask about any struggles or challenges
3. Preview next week's focus
4. End with motivation for the week ahead

Keep the call under 5 minutes. Be warm, encouraging, and specific about their data.
`
}
```

### 13.5 User Scheduling Preferences

```sql
-- Add to primmo_user_profile table
ALTER TABLE primmo_user_profile ADD COLUMN
  weekly_call_enabled BOOLEAN DEFAULT false;
ALTER TABLE primmo_user_profile ADD COLUMN
  preferred_call_day TEXT CHECK (preferred_call_day IN (
    'sunday', 'monday', 'saturday'
  )) DEFAULT 'sunday';
ALTER TABLE primmo_user_profile ADD COLUMN
  preferred_call_time TIME DEFAULT '18:00';
ALTER TABLE primmo_user_profile ADD COLUMN
  morning_motivation_enabled BOOLEAN DEFAULT true;
ALTER TABLE primmo_user_profile ADD COLUMN
  workout_reminders_enabled BOOLEAN DEFAULT true;
```

### 13.6 Scheduling Resources

- [n8n Vapi Voice Receptionist Template](https://n8n.io/workflows/3427-automate-call-scheduling-with-voice-ai-receptionist-using-vapi-google-calendar-and-airtable/)
- [n8n Outbound Calls from Forms](https://n8n.io/workflows/6577-automate-outbound-voice-calls-with-vapi-from-form-submissions/)
- [n8n AI Cold Calling System](https://n8n.io/workflows/4940-automated-ai-cold-calling-system-with-vapiai-airtable-and-smart-follow-ups/)
- [Vapi + Cal.com Appointment Booking](https://n8n.io/workflows/6895-book-appointments-with-voice-using-vapi-and-calcom/)

---

**Document Version:** 2.0
**Created:** 2025-12-21
**Updated:** 2025-12-21
**Author:** PRIMMO Design Team