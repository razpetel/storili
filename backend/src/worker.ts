interface Env {
  ELEVENLABS_API_KEY: string;
  ALLOWED_AGENTS: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only allow POST
    if (request.method !== 'POST') {
      return new Response('Method not allowed', {
        status: 405,
        headers: corsHeaders,
      });
    }

    try {
      const body = await request.json() as { agent_id?: string };
      const { agent_id } = body;

      // Validate agent_id
      if (!agent_id || typeof agent_id !== 'string') {
        return new Response(
          JSON.stringify({ error: 'Missing agent_id' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Check allowlist
      const allowedAgents = env.ALLOWED_AGENTS.split(',').map(s => s.trim());
      if (!allowedAgents.includes(agent_id)) {
        return new Response(
          JSON.stringify({ error: 'Invalid agent_id' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Fetch signed URL from ElevenLabs
      const elevenLabsResponse = await fetch(
        `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agent_id}`,
        {
          headers: {
            'xi-api-key': env.ELEVENLABS_API_KEY,
          },
        }
      );

      if (!elevenLabsResponse.ok) {
        console.error(`ElevenLabs API error: ${elevenLabsResponse.status}`);
        return new Response(
          JSON.stringify({ error: 'Token generation failed' }),
          { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const data = await elevenLabsResponse.json() as { signed_url: string };

      return new Response(
        JSON.stringify({ token: data.signed_url }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({ error: 'Internal error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  },
};
