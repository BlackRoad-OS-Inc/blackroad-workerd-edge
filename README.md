# BlackRoad OS — Self-Hosted Edge Runtime

> ✅ **Verified Working** — CI, deploy, and automerge workflows are active and passing. All GitHub Actions pinned to SHA-256 commit hashes. Stripe and AI Gateway workers deploy to Cloudflare Workers for production/longer tasks; self-hosted `workerd` (Pi/DO) mirrors the same runtime locally.

> Run Cloudflare Workers **on your own hardware** using [workerd](https://github.com/cloudflare/workerd) — Cloudflare's open-source Workers runtime.

```
Pi / DigitalOcean
├── workerd (port 8081) → stripe worker
├── workerd (port 8082) → router worker  
├── workerd (port 8083) → AI gateway worker
└── Caddy → TLS termination → workerd ports
```

## Quick Start

```bash
# Install workerd globally
npm install -g workerd

# Run locally (dev)
npm run dev

# Deploy to Pi
npm run deploy:pi

# Deploy to DigitalOcean droplet
npm run deploy:do
```

## Cloudflare Workers (Cloud — longer tasks)

Deploy workers to Cloudflare's global edge network for production use and longer-running tasks:

```bash
# Install wrangler
npm install -g wrangler

# Deploy stripe worker (billing, webhooks)
npx wrangler deploy --env production

# Deploy AI gateway worker (Ollama/Claude/OpenAI proxy — longer tasks)
npx wrangler deploy --env production -c wrangler.gateway.toml

# Set secrets (run once after deploy)
echo "sk_live_..." | npx wrangler secret put STRIPE_SECRET_KEY --env production
echo "whsec_..."  | npx wrangler secret put STRIPE_WEBHOOK_SECRET --env production
```

## Workers

| Worker | Port | Routes |
|--------|------|--------|
| `stripe` | 8081 | `/checkout`, `/portal`, `/webhook`, `/prices`, `/health` |
| `router` | 8082 | Routes by subdomain to service workers |
| `gateway` | 8083 | Proxies to Ollama / Claude / OpenAI |

## Secrets

Before running, set secrets in `workerd.capnp` bindings or export env vars:

```bash
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
```

## Production (systemd)

```bash
# Install as systemd service (requires root)
sudo bash scripts/install.sh

# Check status
npm run status:pi
npm run logs:pi
```

## CI/CD & Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push / PR | Syntax-check all workers, validate wrangler configs (dry-run), verify capnp embed paths |
| `deploy.yml` | push to `main` | Deploy stripe + gateway workers to **Cloudflare Workers** (cloud, for longer tasks) |
| `automerge.yml` | PR opened/synced | Auto-merge Dependabot and approved collaborator PRs after CI passes |

All GitHub Actions are pinned to SHA-256 commit hashes for supply-chain security.

### Required Repository Secrets

Set these in **Settings → Secrets → Actions**:

| Secret | Description |
|--------|-------------|
| `CF_API_TOKEN` | Cloudflare API token (Workers:Edit permission) |
| `CF_ACCOUNT_ID` | Cloudflare Account ID |
| `STRIPE_SECRET_KEY` | Stripe secret key (`sk_live_...`) |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret (`whsec_...`) |
| `ALLOWED_ORIGIN` | CORS allowed origin (e.g. `https://blackroad-brand-kit.pages.dev`) |
| `ANTHROPIC_API_KEY` | Anthropic API key (optional) |
| `OPENAI_API_KEY` | OpenAI API key (optional) |

## Why workerd?

- **Zero CF billing** — run Workers code on your own infra
- **Same runtime** — identical V8 isolates, same APIs as Cloudflare
- **Local AI** — gateway worker proxies to Ollama on the same machine
- **No cold starts** — persistent process, instant response
- **ARM64 support** — runs on Raspberry Pi 4/5

## Architecture

```
Internet
    │
    ▼
Caddy (auto-TLS via Let's Encrypt)
    │
    ├── stripe.blackroad.io → workerd:8081 (stripe worker)
    ├── gateway.blackroad.io → workerd:8083 (AI gateway)
    └── *.internal → Tailscale mesh
```
