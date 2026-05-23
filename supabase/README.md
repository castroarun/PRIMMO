# PRIMMO Supabase Setup Guide

## Quick Start

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
supanase password: Aifosrun7@2026
2. Note down your:
   - **Project URL**: https://bvawrjlgynthxltddhnf.supabase.co
   - **Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2YXdyamxneW50aHhsdGRkaG5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMDM0OTYsImV4cCI6MjA4MjU3OTQ5Nn0.kl8Ux51mbROqg1CNg4wUdD72WMDTjGezsXRB4QM7LTg
   - **Service Role Key**: For n8n backend (full access) eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2YXdyamxneW50aHhsdGRkaG5mIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzAwMzQ5NiwiZXhwIjoyMDgyNTc5NDk2fQ.zZbgZkaE1EGgLhSzRZBFI5ZlTuyijmbkkpMb-PIwbF4
   - **API Key**: sb_publishable_PWloyK5xE5JFn1gxfQgIlw_w8lQcE8x

### 2. Enable Extensions

Run the first migration to enable required extensions:

```sql
-- Run in Supabase SQL Editor
-- migrations/00001_enable_extensions.sql
```

### 3. Run Migrations

Execute each migration file in order in the Supabase SQL Editor:

1. `00001_enable_extensions.sql` - pgvector, pgcrypto, pg_trgm
2. `00002_knowledge_hub.sql` - FAQ tables & indexes
3. `00003_users.sql` - User management tables
4. `00004_conversations.sql` - Chat history & check-ins
5. `00005_claude_queries.sql` - Claude API logging
6. `00006_functions.sql` - Tier 1-3 helper functions
7. `00007_rls_policies.sql` - Row Level Security

### 4. Verify Installation

Run this query to verify all tables exist:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected tables:
- `claude_queries`
- `conversations`
- `faq_entries`
- `knowledge_embeddings`
- `primmo_user_profile`
- `primmo_users`
- `proactive_checkins`
- `user_connections`

### 5. Test Functions

```sql
-- Test keyword matching
SELECT * FROM match_keywords('how many reps');

-- Test BMR calculation
SELECT calculate_bmr(75, 175, 30, 'male');

-- Test TDEE calculation
SELECT calculate_tdee(1700, 'moderate');

-- Test protein range
SELECT * FROM calculate_protein_range(75);
```

## Schema Overview

### Knowledge Hub (Tier 1 & 2)

| Table | Purpose |
|-------|---------|
| `faq_entries` | FAQ questions, keywords, responses |
| `knowledge_embeddings` | Vector embeddings for semantic search |

### Users

| Table | Purpose |
|-------|---------|
| `primmo_users` | Core user identity (WhatsApp) |
| `primmo_user_profile` | Body stats, goals |
| `user_connections` | REPPIT integration |

### Conversations

| Table | Purpose |
|-------|---------|
| `conversations` | Chat history for Claude context |
| `proactive_checkins` | Scheduled messages |

### Analytics

| Table/View | Purpose |
|------------|---------|
| `claude_queries` | Claude API call logs |
| `claude_digest` | Unreviewed queries view |
| `faq_candidates` | Questions to add to FAQ |
| `daily_cost_summary` | Cost tracking view |

## Key Functions

| Function | Tier | Purpose |
|----------|------|---------|
| `match_keywords(text)` | 1 | Keyword-based FAQ matching |
| `match_knowledge(vector, threshold, count)` | 2 | Semantic similarity search |
| `detect_calculation_type(text)` | 3 | Identify calculation requests |
| `get_calculated_response(user_id, type)` | 3 | Generate BMR/TDEE/protein |
| `process_response_template(text, user_id)` | - | Replace {variables} in responses |
| `get_claude_digest(hours)` | - | Get unreviewed Claude queries |

## n8n Configuration

Use the **Service Role Key** in n8n for full database access:

```
SUPABASE_URL=https://[project-id].supabase.co
SUPABASE_SERVICE_KEY=eyJ...
```

## Security Notes

1. **Service Role Key** bypasses RLS - only use in backend (n8n)
2. **Anon Key** respects RLS - safe for client-side
3. Admin email is hardcoded in RLS - update `00007_rls_policies.sql` if needed
4. Phone numbers are stored but consider encryption for production
