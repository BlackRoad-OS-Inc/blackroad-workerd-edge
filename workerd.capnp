using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [
    ( name = "stripe",   worker = .stripeWorker ),
    ( name = "router",   worker = .routerWorker ),
    ( name = "gateway",  worker = .gatewayWorker ),
  ],

  sockets = [
    ( name = "stripe-http",  address = "*:8081", http = (), service = "stripe" ),
    ( name = "router-http",  address = "*:8082", http = (), service = "router" ),
    ( name = "gateway-http", address = "*:8083", http = (), service = "gateway" ),
  ]
);

# ─── Stripe Worker ────────────────────────────────────────────────────────────
const stripeWorker :Workerd.Worker = (
  serviceWorkerScript = embed "workers/stripe.js",
  compatibilityDate = "2024-12-01",
  compatibilityFlags = ["nodejs_compat"],
  bindings = [
    ( name = "STRIPE_SECRET_KEY",      text = "" ),  # filled via env or secrets file
    ( name = "STRIPE_WEBHOOK_SECRET",  text = "" ),
    ( name = "ALLOWED_ORIGIN",         text = "https://blackroad-brand-kit.pages.dev" ),
    ( name = "ENV",                    text = "production" ),
  ],
);

# ─── Router Worker ────────────────────────────────────────────────────────────
const routerWorker :Workerd.Worker = (
  serviceWorkerScript = embed "workers/router.js",
  compatibilityDate = "2024-12-01",
  compatibilityFlags = ["nodejs_compat"],
  bindings = [
    ( name = "STRIPE_SERVICE", service = "stripe" ),
  ],
);

# ─── Gateway Worker ───────────────────────────────────────────────────────────
const gatewayWorker :Workerd.Worker = (
  serviceWorkerScript = embed "workers/gateway.js",
  compatibilityDate = "2024-12-01",
  compatibilityFlags = ["nodejs_compat"],
);
