# LinkedIn Article: Clarity and Not Clutter - Why AI-Assisted Development Needs a Workflow

---

## Article Metadata
- **Type:** Long-form LinkedIn Article
- **Target Audience:** Developers, Tech Leads, Engineering Managers exploring AI-assisted development
- **Follows:** 4-part LinkedIn content series on the Note App project
- **Goal:** Introduce the TOGAF-inspired AI Development Workflow

---

# Clarity and Not Clutter: Why AI-Assisted Development Needs a Workflow

*Building with AI isn't magic—it's methodology.*

---

## The Uncomfortable Truth About "Vibe Coding"

We've all seen the demos. "Build an app in 10 minutes with AI!" The cursor flies, code appears, and something works. It's exciting. It's seductive. And for anything beyond a weekend project, it's a trap.

I learned this the hard way.

After building a note-taking app with AI assistance—a journey I shared in my recent 4-part series—I sat down for what developers rarely do: a proper retrospective. Not a quick "what went wrong" meeting, but a deep, honest examination of where time actually went, where friction lived, and what nearly derailed the project.

The results surprised me.

![Image: Screenshot of messy Slack threads and scattered documentation]
*[INSERT: Screenshot showing typical "vibe coding" chaos - multiple tabs, scattered notes]*

---

## What the Retrospective Revealed

### Problem #1: Context Amnesia

Every new conversation with AI started from zero. I'd explain the project structure, the tech stack, the conventions—again and again. Each session burned 15-20 minutes of context-setting before real work could begin.

**The hidden cost:** Not just time, but consistency. Different sessions produced different architectural decisions. Code quality fluctuated. The codebase became a geological record of varying AI moods.

### Problem #2: The Review Bottleneck

Human review became the single point of failure. PRDs needed approval. Architecture decisions needed sign-off. Test plans required validation. Each handoff created:
- Waiting time (hours to days)
- Context switching (reviewer had to load the project state)
- Communication overhead (Slack threads, meetings, clarifications)

The AI could generate in seconds what took days to approve.

### Problem #3: No Definition of "Done"

When is a feature complete? When is a PRD approved? When is architecture finalized? Without clear phase boundaries, work flowed in all directions. Features crept. Scope expanded. "Almost done" became a permanent state.

### Problem #4: Tool Sprawl

Requirements in Google Docs. Tasks in Slack threads. Architecture in someone's head. Code in GitHub. Status in... nowhere systematic. The AI assistant couldn't see the full picture because there was no full picture to see.

---

## The Insight: AI Needs Guardrails, Not Freedom

Here's the counterintuitive truth: **AI-assisted development becomes more powerful with more structure, not less.**

The traditional argument for process was human coordination—making sure people don't step on each other. But AI doesn't have that problem. It doesn't get tired, doesn't have ego, doesn't need vacation time.

What AI does need:
- **Clear inputs** (what exactly am I building?)
- **Defined outputs** (how do I know when I'm done?)
- **Persistent context** (what decisions were already made?)
- **Structured handoffs** (what does the next phase need from me?)

This is where enterprise architecture thinking—specifically TOGAF's Architecture Development Method—offers unexpected wisdom.

---

## Enter: The AI Development Workflow

![Image: The complete workflow diagram]
*[INSERT: dev-workflow-cycle.drawio - The TOGAF-inspired circular workflow]*

I formulated a circular workflow inspired by TOGAF's ADM, but adapted for the realities of AI-assisted development. The key innovation: **every phase has explicit deliverables that serve as handshakes to the next phase.**

No deliverable, no progression. Simple as that.

### The Nine Phases (Plus One)

```
Previous Project → Prelim → A → B → C → D → E → F → G → H → I → Next Project
                    ↑                                              ↓
                    └──────────────── (cycle continues) ───────────┘
```

**Prelim: Retrospective**
- *Purpose:* Learn from the previous project
- *Deliverable:* RETROSPECTIVE.md with insights and improvements
- *Why it matters:* This is where "vibe coding" fails—no learning loop

**Phase A: Project Initialization**
- *Purpose:* Set up the project structure with AI-aware tooling
- *Deliverable:* Folder structure, commands, skills, instructions
- *Agent:* `/newproject` command
- *Why it matters:* The AI starts with full context, not a blank slate

**Phase B: Requirements**
- *Purpose:* Capture what we're building and why
- *Deliverable:* requirements.md with user stories
- *Agent:* `@designer`
- *Why it matters:* AI can reference requirements throughout development

**Phase C: Architecture**
- *Purpose:* Make technical decisions before coding
- *Deliverable:* Tech decisions, discovery notes
- *Agent:* `@architect`
- *Why it matters:* Prevents mid-project "let's rewrite this" disasters

**Phase D: PRD & Design**
- *Purpose:* Create detailed specifications
- *Deliverable:* APP_PRD.md, architecture diagrams (.drawio), mockups
- *Agent:* `@architect`
- *Why it matters:* The PRD becomes the AI's instruction manual

**Phase E: Review Loop**
- *Purpose:* Validate before building
- *Deliverable:* Approved PRD, Jira ticket marked Done
- *Agent:* `/checkprd` command
- *Why it matters:* This is the gate—catch problems before they become code

**Phase F: Test Planning**
- *Purpose:* Define acceptance criteria upfront
- *Deliverable:* TEST-PLAN.csv with acceptance criteria
- *Agent:* `@qa`
- *Why it matters:* AI knows what "done" looks like before writing code

**Phase G: Build**
- *Purpose:* Implement the solution
- *Deliverable:* Working code, passing tests
- *Agent:* Claude Code
- *Why it matters:* Building becomes execution, not exploration

**Phase H: Deploy**
- *Purpose:* Ship to production
- *Deliverable:* Production URL, WALKTHROUGH.md
- *Agent:* `/deploy` command
- *Why it matters:* Deployment is documented and repeatable

**Phase I: Manual Testing**
- *Purpose:* Human verification
- *Deliverable:* Test results, bug reports, final DEV-CLOCK
- *Why it matters:* Humans validate; AI didn't hallucinate success

---

## The Game Changer: Specialized Agents

![Image: Agent architecture diagram]
*[INSERT: Diagram showing specialized agents mapped to phases]*

Here's where it gets interesting. Each phase has a well-defined scope, clear inputs, and explicit outputs. That's a perfect agentic candidate. So why not create one? **I built a specialized agent for each phase.**

- `@designer` thinks in user stories and personas
- `@architect` thinks in systems and trade-offs
- `@qa` thinks in edge cases and failure modes

The agents aren't just different prompts. They have:
- Phase-specific instructions
- Access to relevant context
- Defined output formats
- Clear success criteria

This mirrors how real teams work—except the context transfer is instant and complete.

> **In Simple Terms:**
>
> **What's an Agent?** Think of it as a specialized AI assistant with a job description. A `@designer` agent knows it should ask about users, think in journeys, and output user stories. It's not a generic chatbot—it's an AI with a role, boundaries, and expectations. You invoke it, it does its job, it hands off.
>
> **What's a Deliverable?** It's the receipt. The proof of work. When Phase B (Requirements) completes, it doesn't just say "done"—it produces `requirements.md`. That file is the contract between Phase B and Phase C. No file, no handshake, no moving forward. It's accountability baked into the process.

---

## Removing Humans from the Clutter (Not the Loop)

![Image: Jira integration flow]
*[INSERT: Screenshot of Jira board with automated status updates]*

The Jira integration was the final piece. Here's what changed:

**Before:**
- Human creates ticket
- Human assigns ticket
- Human moves ticket through workflow
- Human updates status in standup
- Human marks complete

**After:**
- `/jirastatus` shows current state
- Agents update tickets as work progresses
- Phase transitions auto-update Jira
- Humans review at gates, not in the weeds

The insight: **Humans should make decisions, not push tickets around.**

Review gates (Phase E) remain human-controlled. But the ceremony of ticket management—the moving of cards, the updating of statuses, the commenting of progress—that's noise, not value.

---

## The Deliverable Handshake Pattern

![Image: Deliverable handshake between phases]
*[INSERT: Close-up of workflow showing deliverable boxes between phase circles]*

The core pattern that makes this work:

```
Phase N                    Phase N+1
   │                          │
   └─── DELIVERABLE.md ───────┘
        (explicit artifact)
```

Each deliverable is:
1. **Versioned** (in git)
2. **Structured** (follows a template)
3. **Complete** (contains everything the next phase needs)
4. **Validated** (meets phase exit criteria)

The AI can't proceed without the deliverable. Period.

This eliminates:
- "I thought we agreed on X" (it's in the document)
- "What's the status?" (check the phase deliverable)
- "Who made that decision?" (git blame the artifact)

---

## What This Unlocks

After implementing this workflow:

**Context persistence solved:** The project structure, CLAUDE.md instructions, and phase artifacts give AI complete context in seconds.

**Review bottleneck eliminated:** Humans review at defined gates with complete artifacts, not piecemeal Slack messages.

**Definition of done crystallized:** Each phase has explicit exit criteria. No ambiguity.

**Tool sprawl contained:** Everything lives in the repo. Jira is updated automatically. GitHub is the source of truth.

---

## The Paradox of Process

Here's the strange truth I discovered: **more structure made AI more creative, not less.**

When the AI knows exactly what's expected, it can focus energy on solving the actual problem rather than figuring out what the problem is. When context is persistent, it can build on previous decisions rather than re-debating them.

The workflow isn't bureaucracy. It's scaffolding.

---

## Getting Started

If you're experimenting with AI-assisted development:

1. **Start with retrospectives.** You can't fix what you don't examine.
2. **Define phase boundaries.** Even rough ones beat none.
3. **Create explicit deliverables.** Documents, not discussions.
4. **Build specialized agents.** One size doesn't fit all.
5. **Automate the ceremony.** Reserve human attention for decisions.

The age of "vibe coding" was fun. The age of structured AI development is productive.

---

## This Is a Living Workflow

![Image: Current project using the workflow]
*[INSERT: Screenshot of ongoing project following the workflow]*

I want to be transparent: **this workflow is currently being implemented in my ongoing projects.** It's not a theoretical framework sitting in a drawer—it's being battle-tested in real development right now.

The workflow itself will evolve. Each project that completes the full cycle—from Prelim retrospective back to Prelim retrospective—feeds improvements back into the process. That's the beauty of the circular design: **the arc continues, and each iteration refines the methodology.**

What you're seeing here is the formulation born from the Note App retrospective. The real proof will come from what happens next.

**Coming Soon:** Once the current projects ship and complete their retrospective phases, I'll publish:
- Quantitative metrics (time saved, context-switching reduced)
- Qualitative learnings (what worked, what didn't)
- Workflow refinements (how the phases evolved)
- Agent improvements (which specializations proved most valuable)

Stay tuned for the post-shipment retrospective findings. The best insights come after the dust settles.

---

*What's your experience with AI-assisted development workflows? I'd love to hear what's working (or not) for you.*

---

## Appendix: The Complete Phase-Deliverable Map

| Phase | Name | Agent/Command | Deliverable |
|-------|------|---------------|-------------|
| Prelim | Retrospective | - | RETROSPECTIVE.md |
| A | Project Init | /newproject | Folder structure, instructions |
| B | Requirements | @designer | requirements.md |
| C | Architecture | @architect | Tech decisions, discovery notes |
| D | PRD & Design | @architect | APP_PRD.md, diagrams, mockups |
| E | Review Loop | /checkprd | Approved PRD, Jira: Done |
| F | Test Planning | @qa | TEST-PLAN.csv |
| G | Build | Claude Code | Working code, tests passed |
| H | Deploy | /deploy | Production URL, WALKTHROUGH.md |
| I | Manual Test | Human | Test results, DEV-CLOCK final |

---

**Cross-Phase Tools (Available Throughout):**
- MCP: Jira
- MCP: GitHub
- MCP: Supabase
- /jirastatus
- @walkthrough
