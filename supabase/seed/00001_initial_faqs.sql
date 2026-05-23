-- ============================================
-- PRIMMO Seed Data: Initial FAQ Entries
-- Run after migrations are complete
-- ============================================

-- Training FAQs
INSERT INTO faq_entries (category, question, keywords, response_whatsapp, response_voice, priority) VALUES

('training', 'How many reps should I do?',
  ARRAY['reps', 'rep', 'repetitions', 'how many'],
  '**Rep ranges by goal:**

💪 Strength: 1-5 reps (heavy weight)
📈 Hypertrophy: 6-12 reps (moderate weight)
🏃 Endurance: 12-20+ reps (lighter weight)

For most people building muscle, stick to 8-12 reps per set.',
  'Rep ranges depend on your goal. For strength, do one to five heavy reps. For muscle building, six to twelve reps is ideal. For endurance, go higher with twelve to twenty reps. Most people should aim for eight to twelve reps per set.',
  100),

('training', 'How many sets per exercise?',
  ARRAY['sets', 'set', 'how many sets'],
  '**Sets per muscle group per week:**

Beginner: 10-12 sets/week
Intermediate: 12-16 sets/week
Advanced: 16-20+ sets/week

Per exercise, 3-4 sets is a good starting point.',
  'For beginners, aim for ten to twelve sets per muscle group per week. Intermediate lifters can do twelve to sixteen sets. Advanced lifters may need up to twenty sets. Per exercise, three to four sets is a good starting point.',
  90),

('training', 'How long should I rest between sets?',
  ARRAY['rest', 'rest time', 'between sets', 'how long'],
  '**Rest times by goal:**

💪 Muscle building: 60-90 seconds
🏋️ Strength: 2-3 minutes
⚡ Heavy compounds: 3-5 minutes

Pro tip: Rest longer for big lifts, shorter for isolations.',
  'Rest times depend on your goal. For muscle building, rest sixty to ninety seconds. For strength, two to three minutes. For heavy compound lifts like squats and deadlifts, take three to five minutes.',
  95),

('training', 'How often should I train?',
  ARRAY['frequency', 'how often', 'times per week', 'days per week'],
  '**Training frequency:**

Beginners: 3-4 days/week
Intermediate: 4-5 days/week
Advanced: 5-6 days/week

Each muscle group should be hit 2x per week for optimal growth.',
  'Beginners should train three to four days per week. Intermediate lifters can go four to five days. Advanced lifters may train five to six days. The key is hitting each muscle group twice per week.',
  85);

-- Nutrition FAQs
INSERT INTO faq_entries (category, question, keywords, response_whatsapp, response_voice, requires_profile, variables, priority) VALUES

('nutrition', 'How much protein should I eat?',
  ARRAY['protein', 'how much protein', 'protein intake', 'grams protein'],
  'Based on your weight of {weight}kg:

🥩 Minimum: {protein_min}g/day (1.6g/kg)
💪 Optimal: {protein_optimal}g/day (1.8g/kg)
🔥 Maximum: {protein_max}g/day (2.2g/kg)

For muscle building, aim for at least {protein_optimal}g daily.',
  'Based on your weight, your protein target is {protein_min} to {protein_max} grams per day. For optimal muscle building, aim for around {protein_optimal} grams.',
  true,
  ARRAY['{weight}', '{protein_min}', '{protein_max}', '{protein_optimal}'],
  100),

('nutrition', 'What are my maintenance calories?',
  ARRAY['maintenance', 'calories', 'tdee', 'how many calories'],
  'Your maintenance calories (TDEE) is approximately **{tdee} calories/day**.

To **lose weight**: ~{tdee - 500} calories
To **maintain**: ~{tdee} calories
To **gain muscle**: ~{tdee + 300} calories',
  'Your maintenance calories are approximately {tdee} per day. To lose weight, eat around {tdee - 500} calories. To gain muscle, eat around {tdee + 300} calories.',
  true,
  ARRAY['{tdee}'],
  95),

('nutrition', 'What should I eat before a workout?',
  ARRAY['pre workout', 'before workout', 'before gym', 'pre-workout meal'],
  '**Pre-workout meal (1-2 hours before):**

🍚 Carbs for energy (30-50g)
🥩 Moderate protein (20-30g)
🥑 Low fat (digests slowly)

Examples: Rice + chicken, oatmeal + protein shake, banana + PB toast.',
  'Eat one to two hours before your workout. Focus on carbs for energy, about thirty to fifty grams. Add moderate protein, around twenty to thirty grams. Keep fat low since it digests slowly. Good options include rice with chicken, oatmeal with protein, or banana with peanut butter toast.',
  false,
  ARRAY[]::TEXT[],
  80),

('nutrition', 'What should I eat after a workout?',
  ARRAY['post workout', 'after workout', 'after gym', 'post-workout meal'],
  '**Post-workout meal (within 2 hours):**

🥩 Protein: 30-40g (for muscle repair)
🍚 Carbs: 50-100g (replenish glycogen)
💧 Water: Rehydrate!

Examples: Protein shake + banana, chicken + rice, Greek yogurt + granola.',
  'After your workout, eat within two hours. Aim for thirty to forty grams of protein for muscle repair and fifty to one hundred grams of carbs to replenish energy. Good options include a protein shake with banana, chicken with rice, or Greek yogurt with granola.',
  false,
  ARRAY[]::TEXT[],
  80);

-- Recovery FAQs
INSERT INTO faq_entries (category, question, keywords, response_whatsapp, response_voice, priority) VALUES

('recovery', 'How much sleep do I need?',
  ARRAY['sleep', 'how much sleep', 'hours sleep'],
  '**Sleep for muscle growth:**

😴 Minimum: 7 hours
💪 Optimal: 8-9 hours
⚡ Athletes: 9-10 hours

Sleep is when your muscles repair and grow. Don''t sacrifice it!',
  'For muscle growth, aim for seven to nine hours of sleep. Athletes may need nine to ten hours. Sleep is when your muscles actually repair and grow, so don''t sacrifice it for extra gym time.',
  90),

('recovery', 'When should I take a deload week?',
  ARRAY['deload', 'rest week', 'recovery week', 'take a break'],
  '**Deload timing:**

📅 Every 4-6 weeks of intense training
⚠️ When strength plateaus for 2+ weeks
😫 When you feel constantly fatigued

During deload: Reduce volume by 40-50%, keep intensity moderate.',
  'Take a deload week every four to six weeks of intense training. Also deload if your strength has plateaued for two or more weeks, or if you feel constantly fatigued. During deload, reduce your training volume by forty to fifty percent.',
  75),

('recovery', 'Should I train when sore?',
  ARRAY['sore', 'doms', 'muscle soreness', 'still sore'],
  '**Training with soreness:**

✅ Light soreness: Train, it often helps
⚠️ Moderate soreness: Train different muscles
❌ Severe soreness: Rest and recover

Light movement and stretching usually helps reduce DOMS faster.',
  'Light soreness is fine to train through, and movement often helps. If you''re moderately sore, train different muscle groups. If severely sore, take a rest day. Light movement and stretching can help reduce soreness faster.',
  70);

-- Motivation FAQs
INSERT INTO faq_entries (category, question, keywords, response_whatsapp, response_voice, priority) VALUES

('motivation', 'I don''t feel like training today',
  ARRAY['unmotivated', 'don''t feel like', 'no motivation', 'skip gym'],
  '💪 I get it, some days are tough. Here''s the truth:

**"The best workout is the one you actually do."**

Even 20 minutes is better than nothing. Just get there - you''ll feel better after.

Your future self will thank you for showing up today.',
  'I understand, some days are really tough. But remember, the best workout is the one you actually do. Even twenty minutes is better than nothing. Just get yourself there, and you''ll feel better afterward. Your future self will thank you for showing up today.',
  100),

('motivation', 'I want to give up',
  ARRAY['give up', 'quit', 'stop training', 'want to stop'],
  '🫂 Hey, I hear you. Fitness is a marathon, not a sprint.

**Remember why you started.** Progress isn''t always visible, but it''s happening.

Take a breath. Take a rest day if you need it. But don''t give up on yourself.

What''s one small thing you can do today?',
  'I hear you. Fitness is a marathon, not a sprint. Remember why you started. Progress isn''t always visible, but it''s happening inside. Take a rest day if you need it, but don''t give up on yourself. What''s one small thing you can do today?',
  100);

-- General FAQs
INSERT INTO faq_entries (category, question, keywords, response_whatsapp, response_voice, priority) VALUES

('general', 'How do I connect my REPPIT account?',
  ARRAY['connect', 'reppit', 'link account', 'sync'],
  '**Connect REPPIT:**

1. Ask me "Connect REPPIT"
2. I''ll give you a 6-digit code
3. Open REPPIT → Settings → PRIMMO
4. Enter the code

Once connected, I can see your workouts and give better advice!',
  'To connect your REPPIT account, ask me to generate a connection code. Then open REPPIT, go to Settings, find PRIMMO, and enter the code. Once connected, I can see your workouts and give you better personalized advice.',
  80),

('general', 'What can you help me with?',
  ARRAY['help', 'what can you do', 'features', 'capabilities'],
  '**I''m PRIMMO, your AI strength coach!** 💪

I can help with:
🏋️ Training advice (reps, sets, exercises)
🥩 Nutrition guidance (protein, calories, meals)
😴 Recovery tips (sleep, deload, rest)
💪 Motivation when you need it

Just message me anytime. I''m always here!',
  'I''m PRIMMO, your AI strength coach! I can help with training advice like reps and sets, nutrition guidance including protein and calories, recovery tips, and motivation when you need it. Just message me anytime.',
  100);

-- Generate embeddings note
COMMENT ON TABLE faq_entries IS 'After inserting FAQs, run the embedding generation script to populate knowledge_embeddings for Tier 2 semantic search.';
