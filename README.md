<div align="center">

# PRIMMO

**Agentic AI strength coach — WhatsApp + voice, 4-tier cost-optimized routing, REPPIT integration**

![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs&logoColor=white) ![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white) ![WhatsApp](https://img.shields.io/badge/WhatsApp-Twilio-25D366?logo=whatsapp&logoColor=white) ![Vapi.ai](https://img.shields.io/badge/Vapi.ai-voice-5A67D8) ![n8n](https://img.shields.io/badge/n8n-orchestration-EA4B71?logo=n8n&logoColor=white) ![Status](https://img.shields.io/badge/Status-Building-f59e0b)

</div>

<!-- LAUNCHPAD:START -->
```json
{
  "stage": "building",
  "progress": 25,
  "complexity": "F",
  "lastUpdated": "2026-04-27",
  "targetDate": null,
  "nextAction": "Phase 2: Voice calls via Vapi.ai",
  "blocker": null,
  "demoUrl": null,
  "techStack": [
    "Next.js",
    "TypeScript",
    "WhatsApp API",
    "Voice AI"
  ],
  "shipped": false,
  "linkedinPosted": false
}
```
<!-- LAUNCHPAD:END -->

<details>
<summary>📚 Table of Contents</summary>

- [Features](#features)
- [Quick Start](#quick-start)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [License](#license)

</details>

## Features

- 4-tier AI router: FAQ → semantic search → formula → Claude API (~90% cost reduction)
- Multi-channel delivery via WhatsApp (Twilio) and voice calls (Vapi.ai)
- Proactive scheduled check-ins and motivational outreach via n8n
- REPPIT integration — coaches on real workout data, not generic advice
- Vector search (RAG) over exercise corpus for semantic retrieval

## Quick Start

<p align="center">
  <img src="https://img.shields.io/badge/Claude_API-Haiku/Sonnet-cc785c?style=for-the-badge&logo=anthropic&logoColor=white" alt="Claude API" />
  <img src="https://img.shields.io/badge/Supabase-Database-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Twilio-WhatsApp-F22F46?style=for-the-badge&logo=twilio&logoColor=white" alt="Twilio" />
  <img src="https://img.shields.io/badge/Vapi.ai-Voice-7C3AED?style=for-the-badge&logoColor=white" alt="Vapi.ai" />
  <img src="https://img.shields.io/badge/n8n-Orchestration-EA4B71?style=for-the-badge&logo=n8n&logoColor=white" alt="n8n" />
  <img src="https://img.shields.io/badge/License-Private-red?style=for-the-badge" alt="License" />
</p>

<h1 align="center">PRIMMO</h1>

<h3 align="center">
  AI Strength Coach Agent. <em>WhatsApp. Voice. Personal.</em>
</h3>

<p align="center">
  An agentic AI strength coach that communicates via WhatsApp and Voice calls.<br />
  Providing personalized training, nutrition, and motivational support.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#roadmap">Roadmap</a>
</p>



---

## Features

- **Multi-channel Communication** — WhatsApp (Twilio) + Voice Calls (Vapi.ai)
- **Cost-optimized Responses** — 4-tier system minimizes API costs
  - Tier 1: FAQ matching (Airtable)
  - Tier 2: Semantic search (embeddings)
  - Tier 3: Calculated responses (formulas)
  - Tier 4: Claude API (complex queries)
- **REPPIT Integration** — Optional sync with workout tracking app
- **Proactive Outreach** — Scheduled check-ins and motivation via n8n

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| [Claude API](https://anthropic.com/) | LLM Brain (Haiku/Sonnet) |
| [Supabase](https://supabase.com/) | PostgreSQL Database |
| [Twilio](https://twilio.com/) | WhatsApp API |
| [Vapi.ai](https://vapi.ai/) | Voice Calls |
| [n8n](https://n8n.io/) | Workflow Orchestration |
| [Airtable](https://airtable.com/) | FAQ Admin |

---

## Documentation

- [Product Requirements (PRD)](docs/APP_PRD.md)
- [REPPIT Integration Design](docs/REPPIT-INTEGRATION-DESIGN.md)
- [Voice + WhatsApp Architecture](docs/UNIFIED-VOICE-WHATSAPP-DESIGN.md)
- [Response Tiering System](docs/RESPONSE-TIERING-DESIGN.md)
- [Project Status](docs/PROJECT-STATUS.md)

---

## Project Structure

```
PRIMMO/
├── docs/                    # Design documents
│   ├── APP_PRD.md          # Product requirements
│   ├── REPPIT-INTEGRATION-DESIGN.md
│   ├── UNIFIED-VOICE-WHATSAPP-DESIGN.md
│   ├── RESPONSE-TIERING-DESIGN.md
│   └── PROJECT-STATUS.md
├── src/                     # Source code (to be created)
│   ├── app/                # Next.js app
│   └── lib/                # Shared libraries
├── supabase/               # Database migrations (to be created)
└── n8n/                    # Workflow exports (to be created)
```

---

## Roadmap

| Phase | Features | Timeline |
|-------|----------|----------|
| **Phase 1** | WhatsApp + FAQ + Claude | Weeks 1-10 |
| **Phase 2** | Voice Calls (Vapi.ai) | Weeks 11-16 |
| **Phase 3** | Multi-user + Dashboard | Weeks 17-22 |

- [x] Product requirements document
- [x] Response tiering design
- [x] Voice + WhatsApp architecture
- [ ] Supabase database schema
- [ ] WhatsApp integration
- [ ] Claude API integration
- [ ] Voice calls (Vapi.ai)
- [ ] Admin dashboard

---

## Getting Started

See [docs/PROJECT-STATUS.md](docs/PROJECT-STATUS.md) for current status and next actions.

---

## License

Private - All rights reserved

---

<p align="center">
  <sub>Built by <a href="https://github.com/castroarun">Arun Castro</a></sub>
</p>

## Tech Stack

| Component | Tech |
|---|---|
| Next.js | — |
| TypeScript | — |
| WhatsApp API | — |
| Voice AI | — |

## Roadmap

- [x] Phase 1: WhatsApp + FAQ tier
- [ ] Phase 2: Voice calls via Vapi.ai
- [ ] Phase 3: Multi-user dashboard
- [ ] Phase 4: Custom voice cloning

## License

Private — part of the Castronix portfolio.

<div align="center">

---

<sub>Part of the <a href="https://castronix.dev">Castronix</a> portfolio · crafted with care · © 2026 Arun Castromin</sub>

</div>
