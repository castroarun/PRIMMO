# PRIMMO Response Tiering System

**Version:** 1.0
**Date:** 2025-12-21
**Purpose:** Minimize Claude API costs while maintaining response quality

---

## 1. The Problem

Hitting Claude API for every message is:
- **Expensive**: ~$0.01-0.05 per conversation turn
- **Slow**: 1-3 second latency per request
- **Wasteful**: Many questions have identical answers

**Example Wasteful Calls:**
- "How many reps should I do?" - Same answer for everyone
- "What's a good protein intake?" - Formula-based, not AI-needed
- "How many sets per exercise?" - Static knowledge

---

## 2. Tiered Response Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INCOMING MESSAGE                                  │
│                         │                                            │
│                         ▼                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              TIER 1: EXACT MATCH (0ms, $0)                   │   │
│  │  • Keyword/regex patterns                                    │   │
│  │  • FAQ database lookup                                       │   │
│  │  • Command handling (/help, /stats, /pr)                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                         │                                            │
│                    Not Found                                         │
│                         ▼                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │           TIER 2: SEMANTIC MATCH (~100ms, $0)                │   │
│  │  • Embedding similarity search                               │   │
│  │  • Knowledge base with threshold (>0.85 similarity)         │   │
│  │  • Personalization via template variables                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                         │                                            │
│                 Low Confidence                                       │
│                         ▼                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │         TIER 3: FORMULA/CALCULATION (~10ms, $0)              │   │
│  │  • BMR/TDEE calculations                                     │   │
│  │  • Strength standards lookup                                 │   │
│  │  • Macro calculations                                        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                         │                                            │
│                  Not Applicable                                      │
│                         ▼                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │           TIER 4: CLAUDE API (~2s, $0.01-0.05)               │   │
│  │  • Complex coaching questions                                │   │
│  │  • Personalized advice                                       │   │
│  │  • Motivational support                                      │   │
│  │  • Multi-turn conversations                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tier 1: Exact Match System

### 3.1 FAQ Database Schema

```sql
CREATE TABLE faq_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,  -- 'training', 'nutrition', 'recovery', 'general'
  keywords TEXT[] NOT NULL,  -- Array of trigger keywords
  patterns TEXT[],  -- Regex patterns for matching
  question_variants TEXT[],  -- Different ways to ask same question
  response_template TEXT NOT NULL,  -- May include {variables}
  requires_profile BOOLEAN DEFAULT FALSE,  -- Needs user data?
  priority INTEGER DEFAULT 0,  -- Higher = checked first
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_faq_keywords ON faq_responses USING GIN(keywords);
CREATE INDEX idx_faq_category ON faq_responses(category);
```

### 3.2 Sample FAQ Entries

```sql
-- Training FAQs
INSERT INTO faq_responses (category, keywords, patterns, question_variants, response_template, requires_profile) VALUES

-- Reps per set
('training',
 ARRAY['reps', 'repetitions', 'how many reps'],
 ARRAY['how many (reps|repetitions)', '\d+ reps enough'],
 ARRAY['How many reps should I do?', 'What rep range is best?', 'Reps per set?'],
 'For muscle growth (hypertrophy): **8-12 reps** per set
For strength: **3-6 reps** with heavier weight
For endurance: **15-20 reps** with lighter weight

Most effective for most people: **8-10 reps** at a weight where the last 2 reps are challenging but form stays solid.',
 FALSE),

-- Sets per exercise
('training',
 ARRAY['sets', 'how many sets'],
 ARRAY['how many sets', 'sets per (exercise|muscle)'],
 ARRAY['How many sets per exercise?', 'Sets per workout?'],
 '**3-4 sets per exercise** is the sweet spot for most people.

Per muscle group per week:
• Beginners: 10-12 sets
• Intermediate: 12-16 sets
• Advanced: 16-20+ sets

Quality > quantity. Better to do 3 good sets than 5 sloppy ones.',
 FALSE),

-- Workouts per week
('training',
 ARRAY['workouts per week', 'how often', 'training frequency', 'days per week'],
 ARRAY['how (often|many days)', 'workout.*(per|a) week'],
 ARRAY['How many workouts per week?', 'How often should I train?'],
 'Depends on your split:

• **Full Body**: 3 days/week (Mon/Wed/Fri)
• **Upper/Lower**: 4 days/week
• **Push/Pull/Legs**: 3-6 days/week
• **Bro Split**: 5 days/week

For most people, **3-4 days** is sustainable and effective. Rest days matter too!',
 FALSE),

-- Rest between sets
('training',
 ARRAY['rest', 'rest time', 'between sets', 'how long rest'],
 ARRAY['(rest|break).*(between|after) sets', 'how long.*(rest|wait)'],
 ARRAY['How long should I rest between sets?', 'Rest time between sets?'],
 '**Rest periods by goal:**

• Strength (heavy compound): **3-5 minutes**
• Hypertrophy: **60-90 seconds**
• Endurance: **30-45 seconds**

Pro tip: Rest longer for big lifts (squat, deadlift, bench) and shorter for isolation exercises.',
 FALSE),

-- Protein intake
('nutrition',
 ARRAY['protein', 'how much protein', 'protein intake', 'protein per day'],
 ARRAY['(how much|daily) protein', 'protein.*(need|intake|eat)'],
 ARRAY['How much protein should I eat?', 'Daily protein intake?'],
 '**Target: 1.6-2.2g protein per kg bodyweight**

{#if profile.weight}
For you at {profile.weight}kg: **{calc:protein_min}-{calc:protein_max}g per day**
{/if}

Spread across 4-5 meals for optimal absorption. Each meal: 25-40g protein.

Good sources: chicken, fish, eggs, Greek yogurt, legumes, tofu.',
 TRUE),

-- Calories
('nutrition',
 ARRAY['calories', 'how many calories', 'calorie intake', 'tdee'],
 ARRAY['(how many|daily) calories', 'calorie.*(need|intake|eat)', 'tdee'],
 ARRAY['How many calories should I eat?', 'What is my TDEE?'],
 '{#if profile.weight && profile.height && profile.age}
Based on your profile:
• **BMR**: {calc:bmr} calories (at rest)
• **TDEE**: {calc:tdee} calories (with activity)

For your goal ({profile.goal}):
• **Daily target**: {calc:target_calories} calories
{else}
To calculate your needs, I need your weight, height, and age. Share these or connect your REPPIT profile!
{/if}',
 TRUE);

-- Sleep and recovery
('recovery',
 ARRAY['sleep', 'how much sleep', 'recovery', 'rest days'],
 ARRAY['(how much|hours of) sleep', 'rest day'],
 ARRAY['How much sleep do I need?', 'Are rest days important?'],
 '**Sleep: 7-9 hours** for optimal recovery and muscle growth.

During sleep:
• Growth hormone peaks
• Muscles repair and grow
• CNS recovers

**Rest days**: Take 1-2 per week minimum. Active recovery (walking, stretching) is better than complete inactivity.',
 FALSE);
```

### 3.3 Matching Logic

```typescript
// src/lib/responseRouter.ts

interface MatchResult {
  tier: 'exact' | 'semantic' | 'calculated' | 'claude'
  response?: string
  confidence: number
  faqId?: string
}

async function findExactMatch(message: string): Promise<MatchResult | null> {
  const normalizedMessage = message.toLowerCase().trim()

  // 1. Check for command patterns first
  if (normalizedMessage.startsWith('/')) {
    return handleCommand(normalizedMessage)
  }

  // 2. Query FAQ database with keyword matching
  const { data: faqs } = await supabase
    .from('faq_responses')
    .select('*')
    .order('priority', { ascending: false })

  for (const faq of faqs) {
    // Check keywords
    const keywordMatch = faq.keywords.some(keyword =>
      normalizedMessage.includes(keyword.toLowerCase())
    )

    // Check regex patterns
    const patternMatch = faq.patterns?.some(pattern =>
      new RegExp(pattern, 'i').test(normalizedMessage)
    )

    if (keywordMatch || patternMatch) {
      // Update usage count
      await supabase
        .from('faq_responses')
        .update({ usage_count: faq.usage_count + 1 })
        .eq('id', faq.id)

      return {
        tier: 'exact',
        response: faq.response_template,
        confidence: 0.95,
        faqId: faq.id
      }
    }
  }

  return null
}
```

---

## 4. Tier 2: Semantic Matching

For questions that don't match exactly but are similar to FAQ entries.

### 4.1 Embedding Storage

```sql
-- Store embeddings for semantic search
CREATE TABLE faq_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  faq_id UUID REFERENCES faq_responses(id) ON DELETE CASCADE,
  text_variant TEXT NOT NULL,  -- The question variant
  embedding vector(1536),  -- OpenAI ada-002 or similar
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create index for similarity search
CREATE INDEX idx_faq_embedding ON faq_embeddings
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### 4.2 Semantic Search Logic

```typescript
// Using a smaller/cheaper embedding model (not Claude)
async function findSemanticMatch(
  message: string,
  threshold: number = 0.85
): Promise<MatchResult | null> {

  // Generate embedding for user message (use OpenAI ada-002 or local model)
  const embedding = await generateEmbedding(message)

  // Search for similar questions
  const { data: matches } = await supabase.rpc('match_faq_embeddings', {
    query_embedding: embedding,
    match_threshold: threshold,
    match_count: 3
  })

  if (matches && matches.length > 0 && matches[0].similarity >= threshold) {
    const faq = await getFaqById(matches[0].faq_id)

    return {
      tier: 'semantic',
      response: faq.response_template,
      confidence: matches[0].similarity,
      faqId: faq.id
    }
  }

  return null
}

// Supabase function for vector similarity search
/*
CREATE OR REPLACE FUNCTION match_faq_embeddings(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  faq_id UUID,
  text_variant TEXT,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    fe.faq_id,
    fe.text_variant,
    1 - (fe.embedding <=> query_embedding) as similarity
  FROM faq_embeddings fe
  WHERE 1 - (fe.embedding <=> query_embedding) > match_threshold
  ORDER BY fe.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
*/
```

---

## 5. Tier 3: Calculated Responses

For responses that are personalized but formula-based (no AI needed).

### 5.1 Calculation Functions

```typescript
// src/lib/calculations/userMetrics.ts

interface UserProfile {
  weight: number  // kg
  height: number  // cm
  age: number
  sex: 'male' | 'female'
  activityLevel: 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'
  goal: 'lose' | 'maintain' | 'gain'
}

// BMR using Mifflin-St Jeor equation
function calculateBMR(profile: UserProfile): number {
  const { weight, height, age, sex } = profile

  if (sex === 'male') {
    return Math.round(10 * weight + 6.25 * height - 5 * age + 5)
  } else {
    return Math.round(10 * weight + 6.25 * height - 5 * age - 161)
  }
}

// TDEE with activity multiplier
function calculateTDEE(profile: UserProfile): number {
  const bmr = calculateBMR(profile)
  const multipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9
  }

  return Math.round(bmr * multipliers[profile.activityLevel])
}

// Target calories based on goal
function calculateTargetCalories(profile: UserProfile): number {
  const tdee = calculateTDEE(profile)
  const adjustments = {
    lose: -500,      // 0.5kg/week loss
    maintain: 0,
    gain: 300        // lean bulk
  }

  return tdee + adjustments[profile.goal]
}

// Protein targets
function calculateProteinRange(weight: number): { min: number; max: number } {
  return {
    min: Math.round(weight * 1.6),
    max: Math.round(weight * 2.2)
  }
}

// Strength standards (from REPPIT exercise data)
function getStrengthStandard(
  exerciseId: string,
  weight: number,
  sex: 'male' | 'female'
): Record<string, number> {
  // Use REPPIT's exercise multipliers
  const exercise = getExerciseById(exerciseId)
  const multipliers = sex === 'female'
    ? exercise.femaleMultipliers
    : exercise.multipliers

  return {
    beginner: Math.round(weight * multipliers.beginner),
    novice: Math.round(weight * multipliers.novice),
    intermediate: Math.round(weight * multipliers.intermediate),
    advanced: Math.round(weight * multipliers.advanced)
  }
}
```

### 5.2 Template Variable Replacement

```typescript
// Process template variables in FAQ responses
async function processTemplate(
  template: string,
  primmoUserId: string
): Promise<string> {

  // Get user profile (REPPIT connected or PRIMMO standalone)
  const profile = await getUserProfile(primmoUserId)

  if (!profile) {
    // Remove conditional blocks that require profile
    return template
      .replace(/\{#if profile\.[^}]+\}[\s\S]*?\{\/if\}/g, '')
      .replace(/\{#else\}[\s\S]*?\{\/if\}/g, '')
  }

  // Replace profile variables
  let result = template
    .replace(/\{profile\.weight\}/g, String(profile.weight))
    .replace(/\{profile\.height\}/g, String(profile.height))
    .replace(/\{profile\.age\}/g, String(profile.age))
    .replace(/\{profile\.goal\}/g, profile.goal || 'maintain')

  // Replace calculated values
  const bmr = calculateBMR(profile)
  const tdee = calculateTDEE(profile)
  const targetCalories = calculateTargetCalories(profile)
  const protein = calculateProteinRange(profile.weight)

  result = result
    .replace(/\{calc:bmr\}/g, String(bmr))
    .replace(/\{calc:tdee\}/g, String(tdee))
    .replace(/\{calc:target_calories\}/g, String(targetCalories))
    .replace(/\{calc:protein_min\}/g, String(protein.min))
    .replace(/\{calc:protein_max\}/g, String(protein.max))

  // Process conditionals
  result = result
    .replace(/\{#if profile\.[^}]+\}([\s\S]*?)\{\/if\}/g, '$1')
    .replace(/\{#else\}[\s\S]*?\{\/if\}/g, '')

  return result
}
```

---

## 6. Tier 4: Claude API (Smart Routing)

Only hit Claude for truly complex queries.

### 6.1 Intent Classification

```typescript
// Classify intent to determine if Claude is needed
type Intent =
  | 'faq'           // Static knowledge question
  | 'calculation'   // Needs profile-based calculation
  | 'data_query'    // Querying their workout history
  | 'coaching'      // Personalized advice (needs Claude)
  | 'motivation'    // Emotional support (needs Claude)
  | 'conversation'  // Multi-turn dialogue (needs Claude)
  | 'unknown'       // Can't determine (default to Claude)

function classifyIntent(message: string, conversationHistory: Message[]): Intent {
  const lowered = message.toLowerCase()

  // FAQ patterns
  const faqPatterns = [
    /how (many|much|often|long)/,
    /what (is|are|should)/,
    /^(reps|sets|protein|calories|rest|sleep)/,
    /best (way|time|exercise)/
  ]

  if (faqPatterns.some(p => p.test(lowered))) {
    return 'faq'
  }

  // Calculation patterns
  const calcPatterns = [
    /my (tdee|bmr|calories|macros)/,
    /calculate/,
    /for my (weight|body)/
  ]

  if (calcPatterns.some(p => p.test(lowered))) {
    return 'calculation'
  }

  // Data query patterns
  const dataPatterns = [
    /my (pr|personal record|best|stats)/,
    /last (workout|session)/,
    /how (am i|have i) (doing|progressed)/,
    /show me/
  ]

  if (dataPatterns.some(p => p.test(lowered))) {
    return 'data_query'
  }

  // Coaching/complex patterns
  const coachingPatterns = [
    /should i/,
    /what do you think/,
    /advice/,
    /help me (with|plan|decide)/,
    /i('m| am) (struggling|stuck|confused)/
  ]

  if (coachingPatterns.some(p => p.test(lowered))) {
    return 'coaching'
  }

  // Motivation patterns
  const motivationPatterns = [
    /feeling (down|tired|demotivated|lazy)/,
    /don't (want|feel like)/,
    /struggling to/,
    /can't (find|keep|stay)/,
    /motivat/
  ]

  if (motivationPatterns.some(p => p.test(lowered))) {
    return 'motivation'
  }

  // Check if it's a continuation of conversation
  if (conversationHistory.length > 2) {
    return 'conversation'
  }

  return 'unknown'
}
```

### 6.2 Smart Response Router

```typescript
// src/lib/responseRouter.ts

interface RouterResponse {
  text: string
  tier: 'exact' | 'semantic' | 'calculated' | 'claude'
  latencyMs: number
  cost: number
}

async function routeMessage(
  primmoUserId: string,
  message: string,
  conversationHistory: Message[]
): Promise<RouterResponse> {
  const startTime = Date.now()

  // Step 1: Try exact FAQ match
  const exactMatch = await findExactMatch(message)
  if (exactMatch && exactMatch.confidence > 0.9) {
    const response = await processTemplate(exactMatch.response!, primmoUserId)
    return {
      text: response,
      tier: 'exact',
      latencyMs: Date.now() - startTime,
      cost: 0
    }
  }

  // Step 2: Try semantic match
  const semanticMatch = await findSemanticMatch(message, 0.85)
  if (semanticMatch && semanticMatch.confidence > 0.85) {
    const response = await processTemplate(semanticMatch.response!, primmoUserId)
    return {
      text: response,
      tier: 'semantic',
      latencyMs: Date.now() - startTime,
      cost: 0.0001  // Embedding cost
    }
  }

  // Step 3: Check if it's a data query
  const intent = classifyIntent(message, conversationHistory)
  if (intent === 'data_query') {
    const dataResponse = await handleDataQuery(primmoUserId, message)
    if (dataResponse) {
      return {
        text: dataResponse,
        tier: 'calculated',
        latencyMs: Date.now() - startTime,
        cost: 0
      }
    }
  }

  // Step 4: Fall back to Claude
  const claudeResponse = await callClaudeAPI(primmoUserId, message, conversationHistory)
  return {
    text: claudeResponse.text,
    tier: 'claude',
    latencyMs: Date.now() - startTime,
    cost: claudeResponse.estimatedCost
  }
}
```

---

## 7. Cost Comparison

### 7.1 Estimated Savings

| Scenario | Without Tiering | With Tiering | Savings |
|----------|----------------|--------------|---------|
| 100 messages/day | $1.50-5.00 | $0.30-1.00 | **70-80%** |
| 50% FAQ questions | All hit Claude | 0 Claude calls | **50% of calls** |
| Protein calculation | $0.02 per query | $0 (calculated) | **100%** |

### 7.2 Expected Distribution

Based on typical fitness coaching conversations:

| Tier | % of Messages | Cost per Message | Monthly Cost (1000 msgs) |
|------|---------------|------------------|-------------------------|
| Tier 1 (Exact) | 30% | $0 | $0 |
| Tier 2 (Semantic) | 20% | $0.0001 | $0.02 |
| Tier 3 (Calculated) | 15% | $0 | $0 |
| Tier 4 (Claude) | 35% | $0.02 | $7.00 |
| **Total** | 100% | - | **~$7** |

Without tiering: 1000 × $0.02 = **$20/month**

---

## 8. FAQ Content Strategy

### 8.1 Categories to Pre-populate

| Category | Example Questions | Priority |
|----------|------------------|----------|
| **Training Basics** | Reps, sets, frequency, rest | High |
| **Nutrition** | Protein, calories, macros, meal timing | High |
| **Recovery** | Sleep, rest days, stretching | Medium |
| **Exercise Form** | Bench press tips, squat depth | Medium |
| **Supplements** | Creatine, protein powder, BCAAs | Low |
| **Motivation** | Pre-written motivational snippets | Medium |

### 8.2 Continuous Learning

```sql
-- Track questions that went to Claude
CREATE TABLE uncached_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message TEXT NOT NULL,
  intent TEXT,
  claude_response TEXT,
  response_quality INTEGER,  -- 1-5 user rating
  should_cache BOOLEAN DEFAULT FALSE,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- After N similar uncached questions, consider adding to FAQ
CREATE VIEW faq_candidates AS
SELECT
  message,
  COUNT(*) as occurrences,
  AVG(response_quality) as avg_quality
FROM uncached_questions
WHERE should_cache IS NULL
GROUP BY message
HAVING COUNT(*) >= 3
ORDER BY occurrences DESC;
```

---

## 9. Implementation Checklist

### Phase 1: Basic FAQ System
- [ ] Create `faq_responses` table
- [ ] Populate 20-30 common FAQ entries
- [ ] Implement keyword matching
- [ ] Add template variable processing

### Phase 2: Semantic Search
- [ ] Set up pgvector extension
- [ ] Generate embeddings for FAQ variants
- [ ] Implement similarity search
- [ ] Set confidence threshold (0.85)

### Phase 3: Smart Routing
- [ ] Implement intent classification
- [ ] Build response router
- [ ] Add calculation functions (BMR, TDEE, protein)
- [ ] Connect to REPPIT data for personalization

### Phase 4: Analytics & Learning
- [ ] Track which tier handled each message
- [ ] Monitor cache hit rates
- [ ] Identify FAQ candidates from Claude responses
- [ ] A/B test confidence thresholds

---

## 10. Sample Conversation Flows

### Flow 1: FAQ Hit (No Claude)

```
User: "How many reps should I do?"

[Tier 1: Exact Match Found]
→ Keywords: ["reps"]
→ Pattern: "how many (reps|repetitions)"
→ Confidence: 0.95

Response (instant, $0):
"For muscle growth (hypertrophy): **8-12 reps** per set
For strength: **3-6 reps** with heavier weight
For endurance: **15-20 reps** with lighter weight

Most effective for most people: **8-10 reps** at a weight
where the last 2 reps are challenging but form stays solid."
```

### Flow 2: Calculated Response (No Claude)

```
User: "What's my protein intake?"

[Tier 1: Match Found - requires profile]
[Tier 3: Calculation with REPPIT data]
→ User weight: 75kg
→ Calculation: 75 × 1.6 to 75 × 2.2

Response (instant, $0):
"**Target: 1.6-2.2g protein per kg bodyweight**

For you at 75kg: **120-165g per day**

Spread across 4-5 meals for optimal absorption.
Each meal: 25-40g protein.

Good sources: chicken, fish, eggs, Greek yogurt, legumes, tofu."
```

### Flow 3: Claude Required

```
User: "I've been stuck at 80kg bench for 3 weeks, feeling
frustrated. What should I do differently?"

[Tier 1: No exact match]
[Tier 2: No semantic match (threshold not met)]
[Intent: coaching + motivation]

→ Route to Claude with full context:
  - User's REPPIT bench press history
  - Recent workout frequency
  - Current strength level
  - Conversation history

Response (2s, $0.02):
"I hear you - plateaus are frustrating! Looking at your REPPIT
data, you've been doing bench 2x/week at 80kg for 4 weeks.

Here's what I'd try:
1. **Deload this week** - drop to 70kg, focus on explosive reps
2. **Add pause reps** - 3-second pause at chest
3. **Check your sleep** - plateaus often signal recovery issues

Your last PR was 82.5kg in October. You WILL get past 80kg.
Sometimes the body needs a strategic step back to leap forward."
```

---

**Document Version:** 1.0
**Created:** 2025-12-21