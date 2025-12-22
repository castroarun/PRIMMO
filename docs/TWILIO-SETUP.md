# Twilio Setup Guide for PRIMMO

## Overview

PRIMMO uses Twilio for two channels:
1. **WhatsApp Business API** - Text messaging
2. **Voice (Programmable Voice)** - Phone calls via Vapi.ai

---

## Cost Breakdown

### Per-Interaction Costs

| Channel | Cost per Interaction | Details |
|---------|---------------------|---------|
| **WhatsApp** | $0.03 - $0.10 | 5-10 messages per conversation |
| **Voice Call** | $0.35 - $0.70 | 5-10 minute call |

**Voice is 5-10x more expensive than WhatsApp per conversation.**

### WhatsApp Pricing (India)

| Message Type | Cost | When Used |
|--------------|------|-----------|
| User-initiated (Service) | $0.005/msg | User messages you within 24hr window |
| Business-initiated (Utility) | $0.0099/msg | Notifications, reminders |
| Business-initiated (Marketing) | $0.0572/msg | Promotional content |
| Business-initiated (Authentication) | $0.0311/msg | OTPs, verification |

**24-Hour Window Rule:**
- When user messages you, a 24-hour window opens
- Within this window: $0.005/msg (cheap!)
- Outside window: Must use pre-approved templates ($0.01-0.06/msg)

### Voice Pricing

| Component | Provider | Cost |
|-----------|----------|------|
| Twilio Phone Number (India) | Twilio | $1/month |
| Inbound Calls | Twilio | $0.013/min |
| Outbound Calls (India) | Twilio | $0.020/min |
| Speech-to-Text (STT) | Vapi (Deepgram) | $0.010/min |
| Text-to-Speech (TTS) | Vapi (ElevenLabs) | $0.030/min |
| Vapi Platform | Vapi | $0.010/min |
| **Total Voice Cost** | | **$0.07/min** |

### Monthly Cost Projections

#### Scenario: 100 Active Users

| Usage Pattern | WhatsApp | Voice | Total |
|---------------|----------|-------|-------|
| **Light** (5 msgs/day, 1 call/month) | $75 | $35 | $110 |
| **Medium** (15 msgs/day, 2 calls/month) | $225 | $70 | $295 |
| **Heavy** (30 msgs/day, 4 calls/month) | $450 | $140 | $590 |

#### Scenario: 1,000 Active Users

| Usage Pattern | WhatsApp | Voice | Total |
|---------------|----------|-------|-------|
| **Light** | $750 | $350 | $1,100 |
| **Medium** | $2,250 | $700 | $2,950 |
| **Heavy** | $4,500 | $1,400 | $5,900 |

---

## WhatsApp Setup

### Step 1: Create Twilio Account

1. Sign up at [twilio.com](https://www.twilio.com)
2. Complete verification
3. Note your credentials:
   - Account SID: `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Auth Token: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 2: WhatsApp Sandbox (Development)

1. Go to: **Twilio Console → Messaging → Try it out → WhatsApp**
2. Note the sandbox number (e.g., `+14155238886`)
3. Join sandbox by sending: `join <your-sandbox-code>` to the number
4. Configure webhook:
   ```
   When a message comes in:
   URL: https://your-n8n-instance.com/webhook/whatsapp
   Method: HTTP POST
   ```

### Step 3: WhatsApp Business (Production)

1. Go to: **Twilio Console → Messaging → Senders → WhatsApp senders**
2. Click "Register WhatsApp Sender"
3. Requirements:
   - Facebook Business Manager account
   - Verified business
   - Phone number (not currently on WhatsApp)
4. Submit for Meta approval (takes 1-7 days)

### Step 4: Create Message Templates

Templates are required for business-initiated messages outside the 24-hour window.

**Example Templates:**

```
Template Name: workout_reminder
Category: Utility
Content: Hi {{1}}, it's time for your {{2}} workout! Ready to crush it? 💪

Template Name: weekly_checkin
Category: Utility
Content: Hi {{1}}, how did your workouts go this week? Reply with a quick update!

Template Name: progress_update
Category: Utility
Content: Great news {{1}}! You've completed {{2}} workouts this month. Keep it up! 🎉
```

### Webhook Payload (What Twilio Sends)

```json
{
  "SmsMessageSid": "SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "NumMedia": "0",
  "ProfileName": "Arun",
  "SmsSid": "SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "WaId": "919876543210",
  "SmsStatus": "received",
  "Body": "How many reps should I do for bench press?",
  "To": "whatsapp:+14155238886",
  "NumSegments": "1",
  "MessageSid": "SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "AccountSid": "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "From": "whatsapp:+919876543210",
  "ApiVersion": "2010-04-01"
}
```

### Sending WhatsApp Messages (n8n HTTP Request)

```
Method: POST
URL: https://api.twilio.com/2010-04-01/Accounts/{{$credentials.accountSid}}/Messages.json

Authentication: Basic Auth
  Username: Account SID
  Password: Auth Token

Body (Form URL Encoded):
  From: whatsapp:+14155238886
  To: whatsapp:+919876543210
  Body: Your workout response here!
```

---

## Voice Setup (Twilio + Vapi.ai)

### Understanding the Voice Stack

```
Customer Phone Call
       ↓
Twilio (Telephony - receives call)
       ↓
Vapi.ai (Voice AI Platform)
  ├── STT: Converts speech → text (Deepgram)
  ├── AI: Processes with your webhook
  └── TTS: Converts text → speech (ElevenLabs)
       ↓
Customer hears response
```

### Step 1: Buy Twilio Phone Number

1. Go to: **Twilio Console → Phone Numbers → Buy a number**
2. Select country: India (+91)
3. Capabilities: Voice ✓
4. Purchase (~$1/month)

### Step 2: Create Vapi.ai Account

1. Sign up at [vapi.ai](https://vapi.ai)
2. Go to **Settings → Integrations**
3. Add Twilio credentials:
   - Account SID
   - Auth Token
4. Import your Twilio phone number

### Step 3: Create Vapi Assistant

```json
{
  "name": "PRIMMO Strength Coach",
  "model": {
    "provider": "anthropic",
    "model": "claude-3-haiku-20240307",
    "temperature": 0.7,
    "systemPrompt": "You are PRIMMO, an AI strength coach. Be encouraging, knowledgeable, and concise. Keep responses under 3 sentences for voice."
  },
  "voice": {
    "provider": "elevenlabs",
    "voiceId": "pNInz6obpgDQGcFmaJgB"
  },
  "serverUrl": "https://your-n8n-instance.com/webhook/vapi",
  "serverUrlSecret": "your-secret-key"
}
```

### Step 4: Configure Twilio to Use Vapi

1. Go to: **Twilio Console → Phone Numbers → Your Number**
2. Under "Voice & Fax":
   ```
   A CALL COMES IN:
   Webhook: https://api.vapi.ai/twilio/inbound
   Method: POST
   ```

### Vapi Webhook Payload (What Your n8n Receives)

```json
{
  "message": {
    "type": "conversation-update",
    "role": "user",
    "transcript": "How many sets should I do for squats?",
    "call": {
      "id": "call_xxxxxxxxxx",
      "orgId": "org_xxxxxxxxxx",
      "createdAt": "2024-01-15T10:30:00Z",
      "customer": {
        "number": "+919876543210"
      },
      "phoneNumber": {
        "number": "+911234567890"
      }
    }
  }
}
```

### Vapi Webhook Response (What You Return)

```json
{
  "message": "For squats, I recommend 3 to 4 sets. If you're focusing on strength, aim for 4 to 6 reps with heavier weight. For muscle building, go for 8 to 12 reps with moderate weight."
}
```

---

## n8n Integration

### WhatsApp Webhook Workflow

```
[Webhook Trigger: /whatsapp]
       ↓
[Set Node: Extract Data]
  - phone: {{ $json.From.replace('whatsapp:', '') }}
  - message: {{ $json.Body }}
  - name: {{ $json.ProfileName }}
       ↓
[Supabase: Get/Create User]
       ↓
[Switch: Route to Tier]
       ↓
[HTTP Request: Response (FAQ/Claude)]
       ↓
[HTTP Request: Send Twilio WhatsApp]
```

### Vapi Webhook Workflow

```
[Webhook Trigger: /vapi]
       ↓
[Set Node: Extract Data]
  - phone: {{ $json.message.call.customer.number }}
  - message: {{ $json.message.transcript }}
       ↓
[Supabase: Get/Create User]
       ↓
[Switch: Route to Tier]
       ↓
[HTTP Request: Response (FAQ/Claude)]
       ↓
[Respond to Webhook: Return JSON]
  { "message": "{{ $json.response }}" }
```

---

## Environment Variables

```env
# Twilio
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_WHATSAPP_NUMBER=+14155238886
TWILIO_VOICE_NUMBER=+911234567890

# Vapi
VAPI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
VAPI_ASSISTANT_ID=asst_xxxxxxxxxx

# n8n Webhooks
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
WHATSAPP_WEBHOOK_PATH=/webhook/whatsapp
VAPI_WEBHOOK_PATH=/webhook/vapi
```

---

## Testing Checklist

### WhatsApp
- [ ] Sandbox joined successfully
- [ ] Webhook receives messages
- [ ] Can send responses via Twilio API
- [ ] User lookup/creation works
- [ ] 24-hour window handling works

### Voice
- [ ] Twilio number purchased
- [ ] Vapi assistant created
- [ ] Twilio → Vapi forwarding works
- [ ] Webhook receives transcripts
- [ ] Response plays back correctly
- [ ] Call logging works

---

## Troubleshooting

### WhatsApp Issues

| Problem | Solution |
|---------|----------|
| Webhook not receiving | Check URL is publicly accessible, check Twilio error logs |
| Messages not sending | Verify Auth Token, check "From" number format |
| Outside 24-hour window | Use approved template instead of free-form message |

### Voice Issues

| Problem | Solution |
|---------|----------|
| Call drops immediately | Check Twilio → Vapi webhook URL |
| No response heard | Check Vapi server URL, verify webhook returns correct JSON |
| Garbled speech | Check TTS provider settings in Vapi |
| Long response delay | Optimize n8n workflow, use Haiku for faster responses |

---

## Cost Optimization Tips

1. **Encourage user-initiated conversations** - $0.005 vs $0.01-0.06
2. **Use WhatsApp over Voice when possible** - 7-10x cheaper
3. **Batch notifications** - Send one message with multiple updates
4. **Use Tier 1-3 responses** - Avoid Claude API costs for common questions
5. **Keep voice responses short** - Charge is per minute
6. **Use Haiku for voice** - Faster = shorter calls = lower cost
