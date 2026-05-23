-- ============================================
-- PRIMMO Database Migration 00006
-- Helper Functions (Tier 1-3 Response System)
-- ============================================

-- ============================================
-- TIER 1: Keyword Matching
-- ============================================

-- Search FAQ by keywords (exact match)
CREATE OR REPLACE FUNCTION match_keywords(
  search_text TEXT
)
RETURNS TABLE (
  faq_id UUID,
  question TEXT,
  response_whatsapp TEXT,
  response_voice TEXT,
  variables TEXT[],
  requires_profile BOOLEAN,
  match_score INT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  search_words TEXT[];
BEGIN
  -- Split search text into lowercase words
  search_words := string_to_array(lower(search_text), ' ');

  RETURN QUERY
  SELECT
    f.id,
    f.question,
    f.response_whatsapp,
    f.response_voice,
    f.variables,
    f.requires_profile,
    (
      SELECT COUNT(*)::INT
      FROM unnest(f.keywords) k
      WHERE lower(k) = ANY(search_words)
    ) as match_score
  FROM faq_entries f
  WHERE f.active = true
    AND EXISTS (
      SELECT 1 FROM unnest(f.keywords) k
      WHERE lower(k) = ANY(search_words)
    )
  ORDER BY match_score DESC, f.priority DESC
  LIMIT 1;
END;
$$;

-- ============================================
-- TIER 2: Semantic Search (Vector Similarity)
-- ============================================

-- Search by embedding similarity
CREATE OR REPLACE FUNCTION match_knowledge(
  query_embedding VECTOR(384),
  match_threshold FLOAT DEFAULT 0.75,
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  faq_id UUID,
  question TEXT,
  response_whatsapp TEXT,
  response_voice TEXT,
  variables TEXT[],
  requires_profile BOOLEAN,
  similarity FLOAT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.question,
    f.response_whatsapp,
    f.response_voice,
    f.variables,
    f.requires_profile,
    1 - (ke.embedding <=> query_embedding) AS similarity
  FROM knowledge_embeddings ke
  JOIN faq_entries f ON f.id = ke.faq_id
  WHERE f.active = true
    AND 1 - (ke.embedding <=> query_embedding) > match_threshold
  ORDER BY ke.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- ============================================
-- TIER 3: Calculated Responses (BMR, TDEE, etc.)
-- ============================================

-- Detect if message is asking for a calculation
CREATE OR REPLACE FUNCTION detect_calculation_type(
  message TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  msg_lower TEXT := lower(message);
BEGIN
  -- BMR detection
  IF msg_lower ~ '(bmr|basal metabolic|base.*metabol)' THEN
    RETURN 'bmr';
  END IF;

  -- TDEE detection
  IF msg_lower ~ '(tdee|total.*daily.*energy|maintenance.*calories|how many calories.*(need|burn|eat))' THEN
    RETURN 'tdee';
  END IF;

  -- Protein detection
  IF msg_lower ~ '(protein.*(need|should|eat|intake)|how much protein|grams.*protein)' THEN
    RETURN 'protein';
  END IF;

  -- Macro split detection
  IF msg_lower ~ '(macro|macronutrient|carb.*protein.*fat|split)' THEN
    RETURN 'macros';
  END IF;

  -- Water intake detection
  IF msg_lower ~ '(water.*(need|should|drink)|hydration|how much.*water)' THEN
    RETURN 'water';
  END IF;

  RETURN NULL;
END;
$$;

-- Calculate BMR using Mifflin-St Jeor equation
CREATE OR REPLACE FUNCTION calculate_bmr(
  weight_kg DECIMAL,
  height_cm DECIMAL,
  age INT,
  sex TEXT
)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF sex = 'male' THEN
    RETURN ROUND(10 * weight_kg + 6.25 * height_cm - 5 * age + 5);
  ELSE
    RETURN ROUND(10 * weight_kg + 6.25 * height_cm - 5 * age - 161);
  END IF;
END;
$$;

-- Calculate TDEE from BMR and activity level
CREATE OR REPLACE FUNCTION calculate_tdee(
  bmr INT,
  activity_level TEXT
)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  multiplier DECIMAL;
BEGIN
  CASE activity_level
    WHEN 'sedentary' THEN multiplier := 1.2;
    WHEN 'light' THEN multiplier := 1.375;
    WHEN 'moderate' THEN multiplier := 1.55;
    WHEN 'active' THEN multiplier := 1.725;
    WHEN 'very_active' THEN multiplier := 1.9;
    ELSE multiplier := 1.55; -- Default to moderate
  END CASE;

  RETURN ROUND(bmr * multiplier);
END;
$$;

-- Calculate protein range (1.6-2.2g per kg)
CREATE OR REPLACE FUNCTION calculate_protein_range(
  weight_kg DECIMAL
)
RETURNS TABLE (
  protein_min INT,
  protein_max INT,
  protein_optimal INT
)
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    ROUND(weight_kg * 1.6)::INT as protein_min,
    ROUND(weight_kg * 2.2)::INT as protein_max,
    ROUND(weight_kg * 1.8)::INT as protein_optimal;
$$;

-- Get calculated response for a user
CREATE OR REPLACE FUNCTION get_calculated_response(
  p_user_id UUID,
  calc_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  profile RECORD;
  result JSONB;
  user_bmr INT;
  user_tdee INT;
  protein RECORD;
BEGIN
  -- Get user profile
  SELECT * INTO profile
  FROM primmo_user_profile
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'error', 'no_profile',
      'message', 'Please set up your profile first with your weight, height, age, and sex.'
    );
  END IF;

  -- Check required fields
  IF profile.weight_kg IS NULL OR profile.height_cm IS NULL
     OR profile.age IS NULL OR profile.sex IS NULL THEN
    RETURN jsonb_build_object(
      'error', 'incomplete_profile',
      'message', 'Your profile is incomplete. I need your weight, height, age, and sex to calculate this.'
    );
  END IF;

  -- Calculate based on type
  CASE calc_type
    WHEN 'bmr' THEN
      user_bmr := calculate_bmr(profile.weight_kg, profile.height_cm, profile.age, profile.sex);
      result := jsonb_build_object(
        'type', 'bmr',
        'value', user_bmr,
        'unit', 'calories/day',
        'response', format('Your BMR (Basal Metabolic Rate) is approximately **%s calories/day**. This is what your body burns at complete rest.', user_bmr)
      );

    WHEN 'tdee' THEN
      user_bmr := calculate_bmr(profile.weight_kg, profile.height_cm, profile.age, profile.sex);
      user_tdee := calculate_tdee(user_bmr, COALESCE(profile.activity_level, 'moderate'));
      result := jsonb_build_object(
        'type', 'tdee',
        'bmr', user_bmr,
        'tdee', user_tdee,
        'activity_level', profile.activity_level,
        'response', format('Your TDEE (Total Daily Energy Expenditure) is approximately **%s calories/day** based on %s activity level.

To **lose weight**: Eat around %s calories
To **maintain**: Eat around %s calories
To **gain weight**: Eat around %s calories',
          user_tdee,
          profile.activity_level,
          user_tdee - 500,
          user_tdee,
          user_tdee + 300
        )
      );

    WHEN 'protein' THEN
      SELECT * INTO protein FROM calculate_protein_range(profile.weight_kg);
      result := jsonb_build_object(
        'type', 'protein',
        'min', protein.protein_min,
        'max', protein.protein_max,
        'optimal', protein.protein_optimal,
        'response', format('Based on your weight of %skg, your daily protein target is:

Minimum: **%sg** (1.6g/kg)
Optimal: **%sg** (1.8g/kg)
Maximum: **%sg** (2.2g/kg)

For muscle building, aim for at least %sg per day.',
          profile.weight_kg,
          protein.protein_min,
          protein.protein_optimal,
          protein.protein_max,
          protein.protein_optimal
        )
      );

    WHEN 'water' THEN
      result := jsonb_build_object(
        'type', 'water',
        'liters', ROUND(profile.weight_kg * 0.033, 1),
        'response', format('Based on your weight, you should drink approximately **%s liters** of water per day. Add an extra 500ml for each hour of exercise.',
          ROUND(profile.weight_kg * 0.033, 1)
        )
      );

    ELSE
      result := jsonb_build_object(
        'error', 'unknown_calculation',
        'message', 'I don''t recognize that calculation type.'
      );
  END CASE;

  RETURN result;
END;
$$;

-- ============================================
-- Response Template Processing
-- ============================================

-- Process template variables in response text
CREATE OR REPLACE FUNCTION process_response_template(
  template TEXT,
  p_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  profile RECORD;
  protein RECORD;
  result TEXT := template;
  user_bmr INT;
  user_tdee INT;
BEGIN
  -- Get user profile
  SELECT * INTO profile
  FROM primmo_user_profile
  WHERE user_id = p_user_id;

  -- Replace basic variables
  IF FOUND THEN
    result := REPLACE(result, '{weight}', COALESCE(profile.weight_kg::TEXT, '[weight not set]'));
    result := REPLACE(result, '{height}', COALESCE(profile.height_cm::TEXT, '[height not set]'));
    result := REPLACE(result, '{age}', COALESCE(profile.age::TEXT, '[age not set]'));
    result := REPLACE(result, '{goal}', COALESCE(profile.goal, '[goal not set]'));

    -- Calculate derived values if profile is complete
    IF profile.weight_kg IS NOT NULL AND profile.height_cm IS NOT NULL
       AND profile.age IS NOT NULL AND profile.sex IS NOT NULL THEN

      user_bmr := calculate_bmr(profile.weight_kg, profile.height_cm, profile.age, profile.sex);
      user_tdee := calculate_tdee(user_bmr, COALESCE(profile.activity_level, 'moderate'));
      SELECT * INTO protein FROM calculate_protein_range(profile.weight_kg);

      result := REPLACE(result, '{bmr}', user_bmr::TEXT);
      result := REPLACE(result, '{tdee}', user_tdee::TEXT);
      result := REPLACE(result, '{protein_min}', protein.protein_min::TEXT);
      result := REPLACE(result, '{protein_max}', protein.protein_max::TEXT);
      result := REPLACE(result, '{protein_optimal}', protein.protein_optimal::TEXT);
    END IF;
  END IF;

  RETURN result;
END;
$$;

-- Increment FAQ usage count
CREATE OR REPLACE FUNCTION increment_faq_usage(
  p_faq_id UUID
)
RETURNS VOID
LANGUAGE sql
AS $$
  UPDATE faq_entries
  SET usage_count = usage_count + 1
  WHERE id = p_faq_id;
$$;

COMMENT ON FUNCTION match_keywords IS 'Tier 1: Exact keyword matching for FAQ responses';
COMMENT ON FUNCTION match_knowledge IS 'Tier 2: Semantic vector similarity search';
COMMENT ON FUNCTION detect_calculation_type IS 'Tier 3: Detect if message requires a calculation';
COMMENT ON FUNCTION get_calculated_response IS 'Tier 3: Generate calculated response (BMR, TDEE, protein)';
