-- ============================================
-- PRIMMO Database Migration 00003
-- User Management Tables
-- ============================================

-- Core user table (WhatsApp identity)
CREATE TABLE primmo_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  whatsapp_phone TEXT UNIQUE NOT NULL,
  display_name TEXT,
  timezone TEXT DEFAULT 'UTC',
  preferred_channel TEXT DEFAULT 'whatsapp' CHECK (preferred_channel IN ('whatsapp', 'voice')),
  onboarded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Standalone user profiles (not connected to REPPIT)
CREATE TABLE primmo_user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE UNIQUE,

  -- Body stats
  weight_kg DECIMAL(5,2),
  height_cm DECIMAL(5,2),
  age INT CHECK (age > 0 AND age < 150),
  sex TEXT CHECK (sex IN ('male', 'female')),

  -- Goals & preferences
  goal TEXT CHECK (goal IN ('lose', 'maintain', 'gain', 'recomp')),
  activity_level TEXT DEFAULT 'moderate' CHECK (activity_level IN (
    'sedentary', 'light', 'moderate', 'active', 'very_active'
  )),
  workout_split TEXT,

  -- Computed values (cached)
  bmr INT,
  tdee INT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- REPPIT connection (optional integration)
CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primmo_user_id UUID REFERENCES primmo_users(id) ON DELETE CASCADE UNIQUE,
  reppit_user_id UUID,
  connection_code TEXT UNIQUE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'revoked')),
  connected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_users_phone ON primmo_users(whatsapp_phone);
CREATE INDEX idx_users_created ON primmo_users(created_at);
CREATE INDEX idx_profile_user ON primmo_user_profile(user_id);
CREATE INDEX idx_connections_code ON user_connections(connection_code) WHERE status = 'pending';
CREATE INDEX idx_connections_reppit ON user_connections(reppit_user_id) WHERE status = 'active';

-- Update timestamps trigger
CREATE TRIGGER update_primmo_users_updated_at
  BEFORE UPDATE ON primmo_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_primmo_user_profile_updated_at
  BEFORE UPDATE ON primmo_user_profile
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to generate 6-character connection code
CREATE OR REPLACE FUNCTION generate_connection_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude confusing chars
  result TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE primmo_users IS 'Core user identity linked to WhatsApp number';
COMMENT ON TABLE primmo_user_profile IS 'Standalone profile for users not connected to REPPIT';
COMMENT ON TABLE user_connections IS 'Links PRIMMO users to their REPPIT accounts';
