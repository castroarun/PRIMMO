> @architect Review the requirements and propose implementation approaches for the fitness tracking PWA

I've reviewed requirements.md. Here are 3 implementation approaches:

**Option A: Full Supabase Stack**
- Supabase Auth + Database + Edge Functions
- Pros: Single provider, built-in RLS, real-time sync
- Cons: Vendor lock-in, limited edge function runtime

**Option B: Next.js API Routes + Supabase DB**
- Next.js handles auth middleware and API logic
- Supabase for data persistence only
- Pros: More control, easier testing, familiar patterns
- Cons: More code to maintain

**Option C: Hybrid with Local-First** (Recommended)
- IndexedDB for offline, Supabase for sync
- Pros: Works offline, fast UI, PWA-ready
- Cons: Sync complexity, conflict resolution needed

My recommendation: Option C — users need offline access at the gym.

Which approach should I proceed with?

> Go with Option C. Keep sync simple.

Great choice. Before I create the PRD, I need a few design decisions:

**Decision 1: Sync Strategy**
- A) Last-write-wins (simple, may lose data on conflicts)
- B) Server-wins (cloud is source of truth)
- C) Manual conflict resolution (user chooses)

**Decision 2: State Management**
- A) Zustand (lightweight, simple API)
- B) Redux Toolkit (robust, more boilerplate)
- C) React Query + Context (server-state focused)

**Decision 3: Strength Calculation**
- A) Wilks Score (powerlifting standard)
- B) Custom formula (weight × reps × exercise multiplier)
- C) Percentile-based (compared to population data)

> 1A, 2A, 3B - keep it simple, we can always add complexity later

Proceeding with:
- Sync: Last-write-wins with timestamps
- State: Zustand + IndexedDB persistence
- Strength: Custom formula (configurable multipliers)

Creating PRD now...

✓ Database schema designed (profiles, exercises, workouts, personal_records)
✓ Component hierarchy mapped (12 components across 4 features)
✓ State management defined (3 stores: userStore, workoutStore, syncStore)
✓ API structure planned (8 endpoints, all idempotent for offline retry)

Generating artifacts:
- docs/APP_PRD.md — Full PRD with 24 tasks
- docs/mockups/dashboard.html — Main screen mockup
- docs/mockups/exercise-detail.html — Exercise history view
- docs/workflow.drawio — Data flow diagram

Creating Jira task for review...

📋 Created: SPT-12 "Review PRD: Strength Profile Tracker"
   Status: In Review | Assignee: @arun
   Attachments: APP_PRD.md, 2 mockups, workflow.drawio

Ready for your review. Run `/checkprd` after adding feedback.
