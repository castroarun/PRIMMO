# n8n Setup on Railway

## Quick Start (5 minutes)

### Step 1: Deploy n8n on Railway

1. Go to [Railway](https://railway.app)
2. Click "New Project" → "Deploy a Template"
3. Search for "n8n" and select the official template
4. Click "Deploy Now"

Railway will:
- Create a PostgreSQL database for n8n
- Deploy n8n with persistent storage
- Generate a public URL

### Step 2: Initial Configuration

1. Once deployed, click your n8n service
2. Go to "Settings" → "Generate Domain"
3. Your n8n URL will be: `https://primmo-n8n.up.railway.app` (or similar) n8n-production-ec59.up.railway.app

### Step 3: Set Environment Variables

In Railway, add these variables to your n8n service:

```env
# Basic Auth (Required)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password-here

# Webhook URL (Required for Twilio)
WEBHOOK_URL=https://your-n8n-url.up.railway.app

# Supabase Connection
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Claude API
ANTHROPIC_API_KEY=sk-ant-...

# Twilio (Add after PRIM-16)
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1...

# Admin Settings
ADMIN_WHATSAPP=+65xxxxxxxx
ADMIN_EMAIL=arun.castromin@gmail.com
```

### Step 4: Access n8n

1. Open your n8n URL
2. Login with your basic auth credentials
3. You're ready to create workflows!

## Cost Estimate

| Usage | Railway Cost |
|-------|--------------|
| Light (< 500 executions/month) | ~$5/month |
| Moderate (500-2000 executions) | ~$7/month |
| Heavy (2000+ executions) | ~$10/month |

Railway charges based on:
- CPU/RAM usage
- PostgreSQL storage
- Network egress

## Workflow Import

After setup, import the workflow templates from `./workflows/`:

1. Open n8n
2. Click "Workflows" → "Import from File"
3. Import each JSON file:
   - `01_whatsapp_handler.json`
   - `02_daily_digest.json`
   - `03_proactive_checkins.json`

## Testing Your Setup

### Test 1: Basic Webhook

1. Create a new workflow with a Webhook node
2. Set method to POST
3. Copy the webhook URL
4. Test with curl:

```bash
curl -X POST https://your-n8n.up.railway.app/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello PRIMMO"}'
```

### Test 2: Supabase Connection

1. Add a Supabase node to a workflow
2. Create credentials with your service key
3. Test reading from `faq_entries` table

### Test 3: Claude API

1. Add an HTTP Request node
2. POST to `https://api.anthropic.com/v1/messages`
3. Add headers: `x-api-key`, `anthropic-version`
4. Test with a simple prompt

## Troubleshooting

### n8n won't start
- Check Railway logs for errors
- Ensure PostgreSQL is running
- Verify environment variables

### Webhooks not receiving
- Confirm Railway domain is generated
- Check WEBHOOK_URL matches your domain
- Ensure workflow is active

### Supabase connection fails
- Verify service key (not anon key)
- Check URL format (no trailing slash)
- Test RLS policies

## Backup & Restore

Railway persists n8n workflows in PostgreSQL. To backup:

1. Export workflows as JSON files
2. Store in this repo's `workflows/` folder
3. Version control your workflows

## Next Steps

After Railway setup is complete:
1. ✅ n8n deployed and accessible
2. ✅ Environment variables configured
3. ✅ Basic webhook test passing
4. → Proceed to PRIM-15 (FAQ Population)
5. → Proceed to PRIM-16 (Twilio Setup)
