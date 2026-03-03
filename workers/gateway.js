/**
 * BlackRoad OS — Self-Hosted AI Gateway Worker
 * Proxy to Ollama / Claude / OpenAI backends
 */

const BACKENDS = {
  ollama:    'http://127.0.0.1:11434',
  claude:    'https://api.anthropic.com',
  openai:    'https://api.openai.com',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const provider = url.searchParams.get('provider') || 'ollama';
    const backend = BACKENDS[provider];

    if (!backend) {
      return Response.json({ error: `Unknown provider: ${provider}` }, { status: 400 });
    }

    // Build forwarded URL — strip internal 'provider' param before sending upstream
    const forwardParams = new URLSearchParams(url.search);
    forwardParams.delete('provider');
    const queryStr = forwardParams.toString() ? `?${forwardParams.toString()}` : '';
    const targetUrl = `${backend}${url.pathname}${queryStr}`;

    // Copy headers, remove hop-by-hop / internal headers
    const headers = new Headers(request.headers);
    headers.delete('host');

    // Inject auth for cloud providers
    if (provider === 'claude' && env.ANTHROPIC_API_KEY) {
      headers.set('x-api-key', env.ANTHROPIC_API_KEY);
      headers.set('anthropic-version', '2023-06-01');
    } else if (provider === 'openai' && env.OPENAI_API_KEY) {
      headers.set('Authorization', `Bearer ${env.OPENAI_API_KEY}`);
    }

    try {
      const res = await fetch(targetUrl, {
        method: request.method,
        headers,
        body: request.method !== 'GET' ? request.body : undefined,
      });
      return res;
    } catch (err) {
      return Response.json({ error: err.message, backend }, { status: 502 });
    }
  }
};
