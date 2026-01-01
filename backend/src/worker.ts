interface Env {
  ELEVENLABS_API_KEY: string;
  // Agent IDs stored as secrets: AGENT_ID_THREE_LITTLE_PIGS, etc.
  [key: string]: string;
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
      const body = await request.json() as { story_id?: string };
      const { story_id } = body;

      // Validate story_id
      if (!story_id || typeof story_id !== 'string') {
        return new Response(
          JSON.stringify({ error: 'Missing story_id' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Map story_id to agent_id via environment secret
      // e.g., "three-little-pigs" -> env.AGENT_ID_THREE_LITTLE_PIGS
      const secretKey = `AGENT_ID_${story_id.toUpperCase().replace(/-/g, '_')}`;
      const agentId = env[secretKey];

      if (!agentId) {
        return new Response(
          JSON.stringify({ error: 'Unknown story' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Fetch conversation token from ElevenLabs (for WebRTC/Flutter SDK)
      // Note: Use /token endpoint for WebRTC, /get-signed-url for WebSocket
      const elevenLabsResponse = await fetch(
        `https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=${agentId}`,
        {
          headers: {
            'xi-api-key': env.ELEVENLABS_API_KEY,
          },
        }
      );

      if (!elevenLabsResponse.ok) {
        const errorText = await elevenLabsResponse.text();
        console.error(`ElevenLabs API error: ${elevenLabsResponse.status} - ${errorText}`);
        return new Response(
          JSON.stringify({ error: 'Token generation failed' }),
          { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const data = await elevenLabsResponse.json() as { token: string };

      return new Response(
        JSON.stringify({ token: data.token }),
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
