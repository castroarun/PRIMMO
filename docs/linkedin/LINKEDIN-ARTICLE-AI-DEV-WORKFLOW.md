# LinkedIn Article: Clarity, Not Clutter

---

## Article Metadata
- **Type:** Long-form LinkedIn Article
- **Target Audience:** Developers, Tech Leads exploring AI-assisted development
- **Goal:** Share learnings from a structured AI development workflow

---

# Clarity, Not Clutter: Why AI-Assisted Development Needs Structure

*AI can write code fast. Structure makes it write code right.*

---

## The Retrospective That Changed Everything

During a previous project NoteApp's retrospective—examining what worked, what didn't, and where friction lived—it became clear: **the workflow itself needed to evolve.**

The 9 steps were solid. But the handoffs between phases were fuzzy. Context got lost between sessions. Human review became a bottleneck not because of capacity, but because of unclear deliverables.

These learnings shaped a clearer, more structured approach.

---
**Context:** This article is part of a [4-part series](SERIES_INTRO_URL) on building with AI. The [previous post](DEV_WORKFLOW_POST_URL) introduced the 9-step workflow—this one shows how it evolved.

---

### Lesson 1: Context Must Be Explicit

1. **A designer thinks differently than an architect.** An architect thinks differently than a QA engineer.

2. **Every phase needs to produce an artifact that the next phase can consume.** No artifact, no handoff. This eliminates:
   - "I thought we discussed X"
   - "What's the current status?"
   - Repeated context-setting at the start of each session

These are welcome candidates for Agentization!

#### The Solution: Specialized Agents

Creating specialized agents—each with phase-specific instructions, access to relevant context, and defined output formats—packages what we'd otherwise do ad-hoc: bending our words and prompts to coax specific outcomes from AI. That improvisation is now codified into a reusable box.

**@designer (Requirements Analyst)**

Before any design work begins, this agent conducts deep research:
- Performs fitment study to validate project scope and feasibility
- Identifies best practices and common patterns for the project type
- Researches similar projects and existing implementations
- Asks methodical questions to capture complete requirements

**Output:** A structured requirements document covering project type, purpose, target users, design system preferences, page structure, and components needed.

**@architect (System Designer)**

With requirements captured, the architect takes over with a two-phase approach:

*Phase 1: Discovery* — Reviews requirements, proposes 2-3 implementation approaches, presents trade-offs, and waits for human approval before proceeding.

*Phase 2: PRD Creation* — Creates detailed Product Requirements Document, generates visual workflow diagrams, creates HTML mockups, and submits everything for human review.

The architect is guided by these design principles:
- **Rule of Three** — Don't abstract until the third occurrence; premature abstraction creates unnecessary complexity
- **Separation of Concerns** — Keep data, logic, and presentation distinct; each component does one thing
- **SOLID Principles** — Single responsibility, open/closed, interface segregation guide component design

**Output:** APP_PRD.md with database schemas, API structures, component hierarchies, state management strategy, and task breakdown with complexity estimates. Plus workflow diagrams and HTML mockups.

**@qa (Test Plan Creator)**

Test cases come BEFORE development. The QA agent reads the approved PRD and generates comprehensive test cases:
- Positive tests (happy path)
- Negative tests (error handling)
- Boundary tests (edge values)

**Output:** TEST-PLAN.csv with specific steps, expected behavior, test data, and priority levels. P0 tests define the smoke test suite.

**Why test before code?** It validates understanding. Forces clarity on requirements. Catches gaps before any code is written.

*[INSERT: architect-terminal.png - Terminal showing @architect proposing implementation approaches]*

---

### Lesson 2: Human Gates and the Review Loop

The problem wasn't human review—it was where review happened.

When reviews live inside the same chat thread as development, context gets lost. Sessions end. New sessions start. "Where were we?" becomes the first question. The reviewer scrolls through documents, asking "which file?" repeatedly.

#### The Solution: Independent Review Gates

Take reviews **out of the clutter** and make them independent.

The review itself moves to an external system—Jira—with all artifacts attached, versioned, and traceable, adding **structure** to the review. This creates:
- **Continuity** — Pick up exactly where you left off
- **Clarity** — One place for feedback, one source of truth
- **Independence** — Reviews don't block development chat

This handshake is powered by a single MCP integration that bridges Claude Code and Jira.

When @architect completes a PRD:
1. Creates a Jira task: "Review PRD: [Feature]"
2. Attaches PRD document, workflow diagram, and mockups
3. Assigns to the reviewer

The review process:
- Add comments describing changes needed
- Keep status as "In Review"
- Run `/checkprd` command

The architect reads feedback, revises the PRD, and resubmits. This loop continues until approval.

When approved:
- Move Jira task to "Done"
- Architect automatically creates Epic, Stories, and Tasks
- Development begins with full traceability

*[INSERT: jira-prd-review.png - Jira task with PRD attached and review comments]*

---

### Lesson 3: Supporting Tools

Beyond agents and reviews, purpose-built commands handle specific workflow tasks:

- **`/jirastatus`** — Shows sprint progress, task status, and blockers in table format
- **`/project status`** — Displays current phase, next actions, and overall progress
- **`/newproject`** — Scaffolds project with AI-aware folder structure and instructions
- **`/deploy`** — Runs build checks, deploys to production, captures deployment URL
- **MCP Integrations** — Jira for task management, GitHub for version control, Supabase for data

Together, they stitch the workflow into a tightly-knit system—smooth passthrough from one phase to the next.

*[INSERT: jirastatus-output.png - Terminal showing /jirastatus table output]*

---

## The Evolved Workflow: A TOGAF-Inspired Model

These learnings crystallized into a cyclical phased workflow inspired by TOGAF's Architecture Development Method, adapted for AI-assisted development.

![Image: TOGAF-styled development workflow]
*[INSERT: dev-workflow-cycle.drawio - The circular workflow diagram]*

---

## The Phases

| Phase | Purpose | Agent/Command | Deliverable |
|-------|---------|---------------|-------------|
| **Prelim** | Learnings from previous project | - | RETROSPECTIVE.md |
| **A** | Project setup | /newproject | Folder structure, instructions |
| **B** | Requirements | @designer | requirements.md, mockups/*.html |
| **C** | Architecture | @architect | Tech decisions, architecture diagrams |
| **D** | PRD & Design | @architect | APP_PRD.md |
| **E** | Review Gate | /checkprd | Approved PRD |
| **F** | Test Planning | @qa | TEST-PLAN.csv |
| **G** | Build | Claude Code | Working code, unit tests |
| **H** | Deploy | /deploy | Production URL, WALKTHROUGH.md |
| **I** | Manual Test | Human | Test results |
| **Epilog** | Learnings to next project | - | RETROSPECTIVE.md |

The cycle is circular—Epilog feeds into Prelim of the next project. Human gates exist at Phase E (PRD approval before build) and Phase I (manual testing before release).

---

## Key Takeaways

1. **Start with retrospectives.** You can't improve what you don't examine.
2. **Define phase boundaries.** Even rough ones beat none.
3. **Create explicit deliverables.** Documents, not discussions.
4. **Build specialized agents.** One size doesn't fit all.
5. **Take reviews outside.** Reserve human attention for decisions, not clutter.

The insight isn't that AI needs freedom. It's that **AI needs guardrails to be truly useful.**

This is a hands-on workflow architecture refined through real projects, solving real friction.

---

*What's your experience with structured AI development? I'd love to hear what's working for you.*

