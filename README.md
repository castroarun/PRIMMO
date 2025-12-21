# PRIMMO - AI Strength Coach Agent

An agentic AI strength coach that communicates via WhatsApp and Voice calls, providing personalized training, nutrition, and motivational support.

## Features

- **Multi-channel Communication**: WhatsApp (Twilio) + Voice Calls (Vapi.ai)
- **Cost-optimized Responses**: 4-tier system minimizes API costs
  - Tier 1: FAQ matching (Airtable)
  - Tier 2: Semantic search (embeddings)
  - Tier 3: Calculated responses (formulas)
  - Tier 4: Claude API (complex queries)
- **REPPIT Integration**: Optional sync with workout tracking app
- **Proactive Outreach**: Scheduled check-ins and motivation via n8n

## Tech Stack

| Component | Technology |
|-----------|------------|
| LLM Brain | Claude API (Haiku/Sonnet) |
| Database | Supabase (PostgreSQL) |
| WhatsApp | Twilio WhatsApp API |
| Voice | Vapi.ai |
| Orchestration | n8n |
| FAQ Admin | Airtable |

## Documentation

- [Product Requirements (PRD)](docs/APP_PRD.md)
- [REPPIT Integration Design](docs/REPPIT-INTEGRATION-DESIGN.md)
- [Voice + WhatsApp Architecture](docs/UNIFIED-VOICE-WHATSAPP-DESIGN.md)
- [Response Tiering System](docs/RESPONSE-TIERING-DESIGN.md)
- [Project Status](docs/PROJECT-STATUS.md)

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

## Phase Roadmap

| Phase | Features | Timeline |
|-------|----------|----------|
| **Phase 1** | WhatsApp + FAQ + Claude | Weeks 1-10 |
| **Phase 2** | Voice Calls (Vapi.ai) | Weeks 11-16 |
| **Phase 3** | Multi-user + Dashboard | Weeks 17-22 |

## Getting Started

See [docs/PROJECT-STATUS.md](docs/PROJECT-STATUS.md) for current status and next actions.

## License

Private - All rights reserved