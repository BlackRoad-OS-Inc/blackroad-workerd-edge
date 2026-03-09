using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [
    ( name = "stripe",   worker = .stripeWorker ),
    ( name = "router",   worker = .routerWorker ),
    ( name = "gateway",  worker = .gatewayWorker ),
    ( name = "internet", network = (
        allow = ["public", "private", "local"],
        tlsOptions = ( trustBrowserCas = true )
    ) ),
  ],

  sockets = [
    ( name = "stripe-http",  address = "*:8081", http = (), service = "stripe" ),
    ( name = "router-http",  address = "*:8082", http = (), service = "router" ),
    ( name = "gateway-http", address = "*:8083", http = (), service = "gateway" ),
  ]
);

const stripeWorker :Workerd.Worker = (
  modules = [
    ( name = "worker", esModule = embed "workers/stripe.js" ),
  ],
  compatibilityDate = "2024-12-01",
  globalOutbound = "internet",
  bindings = [
    ( name = "STRIPE_SECRET_KEY",     fromEnvironment = "STRIPE_SECRET_KEY" ),
    ( name = "STRIPE_WEBHOOK_SECRET", fromEnvironment = "STRIPE_WEBHOOK_SECRET" ),
    ( name = "ALLOWED_ORIGIN",        fromEnvironment = "ALLOWED_ORIGIN" ),
  ],
);

const routerWorker :Workerd.Worker = (
  modules = [
    ( name = "worker", esModule = embed "workers/router.js" ),
  ],
  compatibilityDate = "2024-12-01",
  globalOutbound = "internet",
  bindings = [
    ( name = "STRIPE_SERVICE",  service = "stripe" ),
    ( name = "GATEWAY_SERVICE", service = "gateway" ),
  ],
);

const gatewayWorker :Workerd.Worker = (
  modules = [
    ( name = "worker", esModule = embed "workers/gateway.js" ),
  ],
  compatibilityDate = "2024-12-01",
  compatibilityFlags = ["nodejs_compat"],
  globalOutbound = "internet",
  bindings = [
    ( name = "ANTHROPIC_API_KEY", fromEnvironment = "ANTHROPIC_API_KEY" ),
    ( name = "OPENAI_API_KEY",    fromEnvironment = "OPENAI_API_KEY" ),
  ],
);
