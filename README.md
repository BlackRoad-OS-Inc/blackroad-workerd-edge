# BlackRoad OS — Self-Hosted Edge Runtime

[![CI](https://github.com/BlackRoad-OS-Inc/blackroad-workerd-edge/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS-Inc/blackroad-workerd-edge/actions/workflows/ci.yml)

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
# Clone the repo
git clone https://github.com/BlackRoad-OS-Inc/blackroad-workerd-edge.git
cd blackroad-workerd-edge

# Install workerd globally
npm install -g workerd

# Create a .env file with your secrets (see Environment Variables below)
cp .env.example .env  # then edit with your keys

# Run locally (dev)
npm run dev

# Deploy to Pi
npm run deploy:pi

# Deploy to DigitalOcean droplet
npm run deploy:do
```

## Workers

| Worker | Port | Description | Routes |
|--------|------|-------------|--------|
| `stripe` | 8081 | Stripe billing & checkout | `POST /checkout`, `POST /portal`, `POST /webhook`, `GET /prices`, `GET /health` |
| `router` | 8082 | Subdomain-based edge router | Routes `stripe.*` → stripe worker, `gateway.*` → gateway worker |
| `gateway` | 8083 | AI provider proxy | Proxies to Ollama, Claude, or OpenAI via `?provider=` param |

## Environment Variables

Create a `.env` file in the project root (never commit this):

```bash
# Stripe (required for stripe worker)
STRIPE_SECRET_KEY="sk_live_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
ALLOWED_ORIGIN="https://your-frontend.example.com"

# AI Gateway (optional, for cloud AI providers)
ANTHROPIC_API_KEY="sk-ant-..."
OPENAI_API_KEY="sk-..."
```

These are injected into workers via `fromEnvironment` bindings in `workerd.capnp`.

## Production (systemd)

```bash
# Install as systemd service (requires root)
sudo bash scripts/install.sh

# Check status
npm run status:pi
npm run logs:pi
```

The install script:
1. Installs the `workerd` binary (via npm or direct download)
2. Copies workers and config to `/opt/blackroad-workerd/`
3. Writes secrets from environment to `/opt/blackroad-workerd/.env`
4. Creates a systemd service with `EnvironmentFile` for secret injection
5. Optionally installs Caddy for TLS termination

## Architecture

```
Internet
    │
    ▼
Caddy (auto-TLS via Let's Encrypt)
    │
    ├── stripe.blackroad.io    → workerd:8081 (stripe worker)
    ├── gateway.blackroad.io   → workerd:8083 (AI gateway)
    └── *.internal             → Tailscale mesh
```

### AI Gateway

The gateway worker (`port 8083`) proxies requests to AI backends:

```bash
# Local Ollama (default)
curl http://localhost:8083/api/generate -d '{"model":"llama3","prompt":"hello"}'

# Claude API
curl http://localhost:8083/v1/messages?provider=claude -d '...'

# OpenAI API
curl http://localhost:8083/v1/chat/completions?provider=openai -d '...'
```

The `provider` query parameter is stripped before forwarding to the upstream API.

## CI/CD

- **CI** — validates worker syntax and workerd config on every push and PR
- **Deploy** — SSH-based deploy to Pi and DigitalOcean on push to `main`
- **Auto-Merge** — auto-merges Dependabot PRs after CI passes
- **Dependabot** — weekly dependency updates for npm and GitHub Actions

Required GitHub Secrets for deployment: `PI_HOST`, `PI_USER`, `PI_SSH_KEY`, `DO_HOST`, `DO_USER`, `DO_SSH_KEY`.

## Why workerd?

- **Zero CF billing** — run Workers code on your own infra
- **Same runtime** — identical V8 isolates, same APIs as Cloudflare
- **Local AI** — gateway worker proxies to Ollama on the same machine
- **No cold starts** — persistent process, instant response
- **ARM64 support** — runs on Raspberry Pi 4/5

## License

Proprietary — BlackRoad OS, Inc. All Rights Reserved. See [LICENSE](LICENSE).
