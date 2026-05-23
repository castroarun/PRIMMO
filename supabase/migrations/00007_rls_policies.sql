-- ============================================
-- PRIMMO Database Migration 00007
-- Row Level Security Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE faq_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE primmo_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE primmo_user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE proactive_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE claude_queries ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Service Role Access (n8n Backend)
-- ============================================

-- Create service role policies (full access for n8n)
-- These use the service_role key which bypasses RLS by default
-- But we still add explicit policies for clarity

-- FAQ entries: Service can read all, admin can write
CREATE POLICY "Service read all FAQ entries" ON faq_entries
  FOR SELECT TO service_role USING (true);

CREATE POLICY "Service manage FAQ entries" ON faq_entries
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Knowledge embeddings: Service can read/write all
CREATE POLICY "Service manage embeddings" ON knowledge_embeddings
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Users: Service can manage all
CREATE POLICY "Service manage users" ON primmo_users
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Profiles: Service can manage all
CREATE POLICY "Service manage profiles" ON primmo_user_profile
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Conversations: Service can manage all
CREATE POLICY "Service manage conversations" ON conversations
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Connections: Service can manage all
CREATE POLICY "Service manage connections" ON user_connections
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Check-ins: Service can manage all
CREATE POLICY "Service manage checkins" ON proactive_checkins
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Claude queries: Service can manage all
CREATE POLICY "Service manage claude queries" ON claude_queries
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================
-- Authenticated User Access (Future Admin UI)
-- ============================================

-- FAQ entries: Authenticated users can read active entries
CREATE POLICY "Authenticated read active FAQs" ON faq_entries
  FOR SELECT TO authenticated
  USING (active = true);

-- Knowledge embeddings: Authenticated users can read
CREATE POLICY "Authenticated read embeddings" ON knowledge_embeddings
  FOR SELECT TO authenticated USING (true);

-- Claude queries: Only admins can view/manage
-- (We'll use a custom claim or role for this in Phase 2)
CREATE POLICY "Admin read claude queries" ON claude_queries
  FOR SELECT TO authenticated
  USING (
    auth.jwt() ->> 'role' = 'admin'
    OR auth.jwt() ->> 'email' = 'arun.castromin@gmail.com'
  );

CREATE POLICY "Admin update claude queries" ON claude_queries
  FOR UPDATE TO authenticated
  USING (
    auth.jwt() ->> 'role' = 'admin'
    OR auth.jwt() ->> 'email' = 'arun.castromin@gmail.com'
  );

-- ============================================
-- Anonymous/Public Access (Very Limited)
-- ============================================

-- No public access to any tables by default
-- All API access goes through n8n with service_role

-- ============================================
-- Helper: Grant execute on functions
-- ============================================

-- Allow service role to execute all functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Allow authenticated users to execute read-only functions
GRANT EXECUTE ON FUNCTION match_keywords(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION match_knowledge(VECTOR(384), FLOAT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_bmr(DECIMAL, DECIMAL, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_tdee(INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_protein_range(DECIMAL) TO authenticated;

COMMENT ON POLICY "Service read all FAQ entries" ON faq_entries IS 'n8n backend reads all FAQ entries';
COMMENT ON POLICY "Admin read claude queries" ON claude_queries IS 'Only admin can view Claude API logs';
