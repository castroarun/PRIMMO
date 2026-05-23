-- ============================================
-- PRIMMO Database Migration 00004
-- Conversation & Check-in Tables
-- ============================================

-- Conversation history (for Claude context)
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,

  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  channel TEXT DEFAULT 'whatsapp' CHECK (channel IN ('whatsapp', 'voice')),

  -- Routing metadata (for analytics)
  tier_used TEXT CHECK (tier_used IN ('exact', 'semantic', 'calculated', 'claude')),
  faq_id UUID REFERENCES faq_entries(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ DEFAULT now()
);

-- Proactive check-ins (scheduled messages)
CREATE TABLE proactive_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE,

  checkin_type TEXT NOT NULL CHECK (checkin_type IN (
    'workout_reminder', 'progress_check', 'weekly_summary',
    'motivation', 'rest_day', 'custom'
  )),
  scheduled_at TIMESTAMPTZ NOT NULL,
  sent_at TIMESTAMPTZ,
  message_content TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),

  -- Retry tracking
  retry_count INT DEFAULT 0,
  last_error TEXT,

  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for conversation retrieval
CREATE INDEX idx_conversations_user ON conversations(user_id);
CREATE INDEX idx_conversations_user_created ON conversations(user_id, created_at DESC);
CREATE INDEX idx_conversations_tier ON conversations(tier_used);

-- Indexes for check-in scheduling
CREATE INDEX idx_checkins_scheduled ON proactive_checkins(scheduled_at)
  WHERE status = 'pending';
CREATE INDEX idx_checkins_user ON proactive_checkins(user_id);
CREATE INDEX idx_checkins_status ON proactive_checkins(status);

-- Function to get recent conversation context for a user
CREATE OR REPLACE FUNCTION get_conversation_context(
  p_user_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS TABLE (
  role TEXT,
  content TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
  SELECT role, content, created_at
  FROM conversations
  WHERE user_id = p_user_id
  ORDER BY created_at DESC
  LIMIT p_limit;
$$;

-- View for upcoming check-ins (next 24 hours)
CREATE VIEW upcoming_checkins AS
SELECT
  pc.*,
  pu.whatsapp_phone,
  pu.display_name,
  pu.timezone
FROM proactive_checkins pc
JOIN primmo_users pu ON pu.id = pc.user_id
WHERE pc.status = 'pending'
  AND pc.scheduled_at BETWEEN now() AND now() + INTERVAL '24 hours'
ORDER BY pc.scheduled_at;

COMMENT ON TABLE conversations IS 'Chat history for building Claude context';
COMMENT ON TABLE proactive_checkins IS 'Scheduled outbound messages for motivation & reminders';
