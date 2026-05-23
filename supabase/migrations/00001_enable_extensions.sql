-- ============================================
-- PRIMMO Database Migration 00001
-- Enable Required Extensions
-- ============================================

-- Enable pgvector for semantic search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable pgcrypto for UUID generation and encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enable pg_trgm for fuzzy text matching (optional, useful for Tier 1)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
