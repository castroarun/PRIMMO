-- ============================================
-- PRIMMO Database Migration 00005
-- Claude Query Logging (Alert System)
-- ============================================

-- Log all Claude API calls for review and FAQ conversion
CREATE TABLE claude_queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User context
  user_id UUID REFERENCES primmo_users(id) ON DELETE SET NULL,
  user_phone TEXT,                     -- For quick reference

  -- Query details
  user_message TEXT NOT NULL,          -- What they asked
  claude_response TEXT,                -- What Claude said

  -- Conversation context
  conversation_context JSONB,          -- Recent messages for context

  -- Cost tracking
  model_used TEXT CHECK (model_used IN ('haiku', 'sonnet', 'opus')),
  tokens_in INT,
  tokens_out INT,
  cost_usd DECIMAL(10,6),
  latency_ms INT,

  -- Review workflow
  reviewed BOOLEAN DEFAULT false,      -- Admin has seen it
  added_to_faq BOOLEAN DEFAULT false,  -- Added to knowledge hub
  review_notes TEXT,                   -- Admin notes

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- Indexes for query review
CREATE INDEX idx_claude_unreviewed ON claude_queries(created_at DESC)
  WHERE reviewed = false;
CREATE INDEX idx_claude_user ON claude_queries(user_id);
CREATE INDEX idx_claude_created ON claude_queries(created_at DESC);
CREATE INDEX idx_claude_cost ON claude_queries(cost_usd DESC);

-- Index for message similarity (finding repeated questions)
CREATE INDEX idx_claude_message_trgm ON claude_queries
  USING GIN(user_message gin_trgm_ops);

-- View: Unreviewed queries for daily digest
CREATE VIEW claude_digest AS
SELECT
  id,
  user_message,
  claude_response,
  model_used,
  cost_usd,
  created_at,
  user_phone
FROM claude_queries
WHERE reviewed = false
ORDER BY created_at DESC;

-- View: FAQ Candidates (questions asked 2+ times)
CREATE VIEW faq_candidates AS
SELECT
  user_message,
  COUNT(*) as times_asked,
  MAX(claude_response) as sample_response,
  SUM(cost_usd) as total_cost,
  ARRAY_AGG(DISTINCT model_used) as models_used,
  MIN(created_at) as first_asked,
  MAX(created_at) as last_asked
FROM claude_queries
WHERE added_to_faq = false
GROUP BY user_message
HAVING COUNT(*) >= 2
ORDER BY times_asked DESC, total_cost DESC;

-- View: Daily cost summary
CREATE VIEW daily_cost_summary AS
SELECT
  DATE(created_at) as date,
  COUNT(*) as query_count,
  COUNT(DISTINCT user_id) as unique_users,
  SUM(tokens_in) as total_tokens_in,
  SUM(tokens_out) as total_tokens_out,
  SUM(cost_usd) as total_cost,
  AVG(latency_ms) as avg_latency_ms
FROM claude_queries
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Function to get unreviewed Claude queries for digest
CREATE OR REPLACE FUNCTION get_claude_digest(
  since_hours INT DEFAULT 24
)
RETURNS TABLE (
  id UUID,
  user_message TEXT,
  claude_response TEXT,
  model_used TEXT,
  cost_usd DECIMAL,
  created_at TIMESTAMPTZ,
  user_phone TEXT
)
LANGUAGE sql
STABLE
AS $$
  SELECT id, user_message, claude_response, model_used, cost_usd, created_at, user_phone
  FROM claude_queries
  WHERE reviewed = false
    AND created_at > now() - (since_hours || ' hours')::INTERVAL
  ORDER BY created_at DESC;
$$;

-- Function to mark query as reviewed
CREATE OR REPLACE FUNCTION mark_query_reviewed(
  query_id UUID,
  notes TEXT DEFAULT NULL,
  add_to_faq BOOLEAN DEFAULT false
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE claude_queries
  SET
    reviewed = true,
    reviewed_at = now(),
    review_notes = notes,
    added_to_faq = add_to_faq
  WHERE id = query_id;

  RETURN FOUND;
END;
$$;

COMMENT ON TABLE claude_queries IS 'Log of all Tier 4 (Claude API) queries for review and FAQ conversion';
COMMENT ON VIEW faq_candidates IS 'Questions asked multiple times - good candidates for FAQ entries';
