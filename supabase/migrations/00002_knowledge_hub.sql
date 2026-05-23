-- ============================================
-- PRIMMO Database Migration 00002
-- Knowledge Hub Tables (FAQ System)
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

-- Indexes for fast keyword search
CREATE INDEX idx_faq_keywords ON faq_entries USING GIN(keywords);
CREATE INDEX idx_faq_category ON faq_entries(category);
CREATE INDEX idx_faq_active ON faq_entries(active) WHERE active = true;
CREATE INDEX idx_faq_priority ON faq_entries(priority DESC) WHERE active = true;

-- Index for trigram fuzzy matching on question text
CREATE INDEX idx_faq_question_trgm ON faq_entries USING GIN(question gin_trgm_ops);

-- Index for vector similarity search (IVFFlat)
-- Note: Requires at least 100 rows for optimal performance
-- For small datasets, consider using HNSW instead
CREATE INDEX idx_embedding_vector ON knowledge_embeddings
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_faq_entries_updated_at
  BEFORE UPDATE ON faq_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE faq_entries IS 'Knowledge hub for FAQ responses - Tier 1 & 2 matching';
COMMENT ON TABLE knowledge_embeddings IS 'Vector embeddings for semantic search (Tier 2)';
