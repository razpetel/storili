# ElevenLabs API-First Agent Configuration

> Infrastructure-as-code approach for managing Storili's conversational AI agents.

## Overview

Storili agents are configured via TypeScript files and deployed to ElevenLabs using their API. This enables version control, code review for prompt changes, and reproducible deployments.

**Key decisions:**
- Agent configs live in `backend/agents/` alongside the Cloudflare Worker
- One TypeScript file per story (no premature modularization)
- Deploy script handles create/update automatically
- Agent IDs tracked in committed `.agents.json` for visibility

## Directory Structure

```
backend/
├── src/
│   └── worker.ts              # Token endpoint (Cloudflare Edge)
├── scripts/
│   ├── deploy-agent.ts        # CLI: deploy agents to ElevenLabs
│   └── elevenlabs.ts          # ElevenLabs API client
├── agents/
│   ├── types.ts               # TypeScript types for agent config
│   └── three-little-pigs.ts   # Complete agent configuration
├── .agents.json               # Deployed agent registry (COMMITTED)
├── package.json
└── wrangler.toml
```

## Agent Configuration Schema

Each story has a single TypeScript file with the complete agent configuration:

```typescript
// backend/agents/three-little-pigs.ts
import { AgentConfig } from './types';

export const config: AgentConfig = {
  name: 'Storili - Three Little Pigs',

  conversation_config: {
    agent: {
      first_message: "Hello! I'm Capy, your story friend! Ready for an adventure with three little pigs?",
      language: 'en',
      prompt: {
        prompt: SYSTEM_PROMPT,
        llm: 'claude-3-5-sonnet',
        temperature: 0.7,
        max_tokens: 150,
      },
    },
    tts: {
      voice_id: 'b8gbDO0ybjX1VA89pBdX',  // Expressive storytelling voice (tuned 2026-01-01)
      model_id: 'eleven_turbo_v2',        // Required for English agents (not v2_5)
      stability: 0.5,
      similarity_boost: 0.65,
      style: 0.8,                         // High expressiveness
      speed: 0.85,                        // 15% slower for clarity
    },
    turn: {
      turn_timeout: 15,              // Kids need time to think
      silence_end_call_timeout: 60,  // Don't hang up too fast
    },
  },

  // Required by ElevenLabs API
  workflow: {
    nodes: {
      start: { type: 'start' },
    },
    edges: {},
  },

  // Client tools executed on device
  client_tools: [
    {
      name: 'change_scene',
      description: 'Transition to a new scene. Call when moving between story locations.',
      parameters: {
        scene_name: {
          type: 'string',
          description: 'Scene identifier: cottage, straw_house, stick_house, brick_house, celebration',
          required: true,
        },
      },
      wait_for_response: false,
    },
    {
      name: 'suggest_actions',
      description: 'Offer 3 action choices after asking a question. Always provide exactly 3 options.',
      parameters: {
        actions: {
          type: 'array',
          items: { type: 'string' },
          description: 'Exactly 3 short action phrases with emoji prefix',
          required: true,
        },
      },
      wait_for_response: false,
    },
    {
      name: 'generate_image',
      description: 'Generate illustration for current scene. Call after change_scene.',
      parameters: {
        prompt: {
          type: 'string',
          description: 'Detailed image prompt including scene, characters, and current action',
          required: true,
        },
      },
      wait_for_response: false,
    },
    {
      name: 'session_end',
      description: 'End the story session. Call when story concludes or child says goodbye.',
      parameters: {
        summary: {
          type: 'string',
          description: 'Personalized summary of child\'s journey for resume context',
          required: true,
        },
      },
      wait_for_response: false,
    },
  ],
};

const SYSTEM_PROMPT = `You are Capy, a friendly capybara who guides children (ages 3-5) through interactive fairy tales.

## Your Personality
- Warm, patient, and encouraging (preschool teacher energy)
- Celebrate every choice: "What a great idea!"
- Use simple words, short sentences, lots of repetition
- Sound effects and expressive delivery: "The wolf went WHOOOOSH!"
- Favorite phrases: "Can you help?", "Oh no!", "Look!", "Don't worry!"

## Dynamic Variables
- {{child_name}} - Use naturally if provided, never ask directly
- {{resume_summary}} - If provided, you're continuing a previous session

## The Story: Three Little Pigs

### Scene 1: Cottage (Start)
Mother Pig sends three little pigs to build their own houses.
- Introduce the three pigs (make them silly and distinct)
- Explain they need to build houses
- Ask child which pig to follow first
- CALL: suggest_actions with 3 pig choices
- CALL: change_scene when child chooses

### Scene 2: Straw House
First pig builds a straw house. Wolf arrives!
- Describe the flimsy straw house
- Wolf knocks, does "I'll huff and puff!"
- House blows down, pig escapes
- Ask child where pig should run
- CALL: change_scene to stick_house

### Scene 3: Stick House
Second pig's stick house. Wolf follows!
- Both pigs are here now
- Wolf huffs and puffs again
- Sticks fly everywhere
- Both pigs run to brick house
- CALL: change_scene to brick_house

### Scene 4: Brick House
Third pig's strong brick house. Final confrontation!
- All three pigs safe inside
- Wolf tries huffing and puffing - doesn't work!
- Wolf tries chimney - falls in pot!
- Wolf runs away, pigs celebrate
- CALL: change_scene to celebration

### Scene 5: Celebration
Happy ending!
- Pigs thank the child for helping
- Capy celebrates their bravery
- CALL: session_end with personalized summary

## Tool Usage Rules
1. ALWAYS call suggest_actions after asking a question
2. ALWAYS call change_scene before describing a new location
3. ALWAYS call generate_image after change_scene
4. Call session_end ONLY when story concludes or child says goodbye

## Handling Off-Topic
- Gently redirect: "That's fun! But look - the wolf is coming!"
- Never break character or mention being AI
- If child is scared, reassure: "Don't worry, the pigs are safe!"

## Voice Notes
- You are the narrator AND all characters
- Wolf: deeper, growly but silly (not scary)
- Pigs: higher pitched, each slightly different
- Always return to warm Capy voice for narration
`;
```

## Dynamic Variables Flow

Dynamic variables (child's name, resume summary) flow from app to agent:

```
┌─────────────┐      ┌─────────────────┐      ┌─────────────┐
│  Flutter    │      │  Cloudflare     │      │  ElevenLabs │
│  App        │─────▶│  Worker         │─────▶│  API        │
└─────────────┘      └─────────────────┘      └─────────────┘

Request:                Request:                  Agent receives:
{                       {                         dynamicVariables: {
  storyId: "...",         agentId: "...",           child_name: "Emma",
  childName: "Emma",      dynamicVariables: {       resume_summary: "..."
  resumeSummary: "..."      child_name: "Emma",   }
}                           resume_summary: "..."
                          }
                        }
```

**Updated worker.ts:**

> **IMPORTANT:** Use `/v1/convai/conversation/token` for Flutter SDK (WebRTC/LiveKit).
> Do NOT use `/get-signed-url` - that's for WebSocket connections only.

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { story_id } = await request.json();

    const agentId = env[`AGENT_ID_${story_id.toUpperCase().replace(/-/g, '_')}`];
    if (!agentId) {
      return Response.json({ error: 'Unknown story' }, { status: 400 });
    }

    // Get conversation token (NOT signed URL) for WebRTC/Flutter SDK
    const elevenLabsResponse = await fetch(
      `https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=${agentId}`,
      { headers: { 'xi-api-key': env.ELEVENLABS_API_KEY } }
    );

    if (!elevenLabsResponse.ok) {
      return Response.json({ error: 'Token generation failed' }, { status: 502 });
    }

    const { token } = await elevenLabsResponse.json();
    return Response.json({ token });
  },
};
```

## Deploy Script

```typescript
// backend/scripts/deploy-agent.ts
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { createHash } from 'crypto';
import { ElevenLabsAPI } from './elevenlabs';

const AGENTS_FILE = '.agents.json';

interface AgentRegistry {
  [storyId: string]: {
    agentId: string;
    deployedAt: string;
    configHash: string;
  };
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'deploy':
      await deploy(args[1]);
      break;
    case 'status':
      status();
      break;
    case 'delete':
      await deleteAgent(args[1]);
      break;
    default:
      showHelp();
  }
}

function showHelp() {
  console.log(`
ElevenLabs Agent Management

Usage:
  npm run agent:deploy <story-id>   Deploy or update an agent
  npm run agent:status              Show deployed agents
  npm run agent:delete <agent-id>   Delete an agent (requires confirmation)

Examples:
  npm run agent:deploy three-little-pigs
  npm run agent:status
  npm run agent:delete abc123xyz

Environment:
  ELEVENLABS_API_KEY    Required for all operations
`);
}

async function deploy(storyId: string) {
  if (!storyId) {
    console.error('Error: Missing story ID');
    console.error('Usage: npm run agent:deploy <story-id>');
    process.exit(1);
  }

  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error('Error: ELEVENLABS_API_KEY environment variable not set');
    process.exit(1);
  }

  // Load agent config
  const configPath = `./agents/${storyId}.ts`;
  if (!existsSync(configPath)) {
    console.error(`Error: Agent config not found: ${configPath}`);
    process.exit(1);
  }

  const { config } = await import(`../agents/${storyId}`);
  const configHash = hash(JSON.stringify(config));
  const registry = loadRegistry();
  const existing = registry[storyId];

  // Skip if unchanged
  if (existing?.configHash === configHash) {
    console.log(`✓ ${storyId} unchanged (${existing.agentId})`);
    return;
  }

  const api = new ElevenLabsAPI(apiKey);
  let agentId: string;

  try {
    if (existing?.agentId) {
      await api.updateAgent(existing.agentId, config);
      agentId = existing.agentId;
      console.log(`✓ Updated ${storyId} (${agentId})`);
    } else {
      agentId = await api.createAgent(config);
      console.log(`✓ Created ${storyId} (${agentId})`);
    }
  } catch (error) {
    console.error(`Error deploying agent: ${error.message}`);
    if (error.response?.data) {
      console.error('API response:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }

  // Update registry
  registry[storyId] = {
    agentId,
    deployedAt: new Date().toISOString(),
    configHash,
  };
  saveRegistry(registry);

  // Update Cloudflare secret
  const secretName = `AGENT_ID_${storyId.toUpperCase().replace(/-/g, '_')}`;
  console.log(`\nTo update Cloudflare Worker, run:`);
  console.log(`  echo "${agentId}" | wrangler secret put ${secretName}`);
}

function status() {
  const registry = loadRegistry();
  const entries = Object.entries(registry);

  if (entries.length === 0) {
    console.log('No agents deployed yet.');
    return;
  }

  console.log('Deployed Agents:\n');
  for (const [storyId, info] of entries) {
    console.log(`  ${storyId}`);
    console.log(`    Agent ID:    ${info.agentId}`);
    console.log(`    Deployed:    ${info.deployedAt}`);
    console.log(`    Config hash: ${info.configHash.slice(0, 16)}...`);
    console.log();
  }
}

async function deleteAgent(agentId: string) {
  if (!agentId) {
    console.error('Error: Missing agent ID');
    console.error('Usage: npm run agent:delete <agent-id>');
    process.exit(1);
  }

  // Find story ID for this agent
  const registry = loadRegistry();
  const entry = Object.entries(registry).find(([_, info]) => info.agentId === agentId);

  if (!entry) {
    console.error(`Error: Agent ${agentId} not found in registry`);
    process.exit(1);
  }

  const [storyId] = entry;

  // Require confirmation
  console.log(`\nThis will permanently delete:`);
  console.log(`  Story:    ${storyId}`);
  console.log(`  Agent ID: ${agentId}`);
  console.log(`\nType 'delete' to confirm:`);

  const readline = await import('readline');
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  const answer = await new Promise<string>(resolve => {
    rl.question('> ', resolve);
  });
  rl.close();

  if (answer !== 'delete') {
    console.log('Cancelled.');
    return;
  }

  const api = new ElevenLabsAPI(process.env.ELEVENLABS_API_KEY!);
  await api.deleteAgent(agentId);

  delete registry[storyId];
  saveRegistry(registry);

  console.log(`✓ Deleted ${storyId} (${agentId})`);
}

function loadRegistry(): AgentRegistry {
  if (!existsSync(AGENTS_FILE)) return {};
  return JSON.parse(readFileSync(AGENTS_FILE, 'utf-8'));
}

function saveRegistry(registry: AgentRegistry) {
  writeFileSync(AGENTS_FILE, JSON.stringify(registry, null, 2) + '\n');
}

function hash(content: string): string {
  return createHash('sha256').update(content).digest('hex');
}

main().catch(console.error);
```

## ElevenLabs API Client

```typescript
// backend/scripts/elevenlabs.ts
import { AgentConfig } from '../agents/types';

const BASE_URL = 'https://api.elevenlabs.io/v1';

export class ElevenLabsAPI {
  constructor(private apiKey: string) {}

  async createAgent(config: AgentConfig): Promise<string> {
    const response = await fetch(`${BASE_URL}/convai/agents/create`, {
      method: 'POST',
      headers: {
        'xi-api-key': this.apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(config),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Failed to create agent: ${JSON.stringify(error)}`);
    }

    const data = await response.json();
    return data.agent_id;
  }

  async updateAgent(agentId: string, config: AgentConfig): Promise<void> {
    const response = await fetch(`${BASE_URL}/convai/agents/${agentId}`, {
      method: 'PATCH',
      headers: {
        'xi-api-key': this.apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(config),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Failed to update agent: ${JSON.stringify(error)}`);
    }
  }

  async deleteAgent(agentId: string): Promise<void> {
    const response = await fetch(`${BASE_URL}/convai/agents/${agentId}`, {
      method: 'DELETE',
      headers: {
        'xi-api-key': this.apiKey,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Failed to delete agent: ${JSON.stringify(error)}`);
    }
  }

  async listAgents(): Promise<Array<{ agent_id: string; name: string }>> {
    const response = await fetch(`${BASE_URL}/convai/agents`, {
      headers: {
        'xi-api-key': this.apiKey,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Failed to list agents: ${JSON.stringify(error)}`);
    }

    const data = await response.json();
    return data.agents;
  }
}
```

## TypeScript Types

```typescript
// backend/agents/types.ts
export interface AgentConfig {
  name: string;
  conversation_config: ConversationConfig;
  workflow: Workflow;
  client_tools?: ClientTool[];
}

interface ConversationConfig {
  agent: AgentSettings;
  tts?: TTSSettings;
  turn?: TurnSettings;
}

interface AgentSettings {
  first_message: string;
  language: string;
  prompt: PromptSettings;
}

interface PromptSettings {
  prompt: string;
  llm: 'claude-3-5-sonnet' | 'gpt-4o' | 'gpt-4o-mini' | 'gemini-1.5-pro';
  temperature?: number;
  max_tokens?: number;
}

interface TTSSettings {
  voice_id: string;
  model_id?: string;
  stability?: number;
  similarity_boost?: number;
}

interface TurnSettings {
  turn_timeout?: number;
  silence_end_call_timeout?: number;
}

interface Workflow {
  nodes: Record<string, WorkflowNode>;
  edges: Record<string, WorkflowEdge[]>;
}

interface WorkflowNode {
  type: 'start' | 'agent' | 'end';
}

interface WorkflowEdge {
  target: string;
  condition?: string;
}

interface ClientTool {
  name: string;
  description: string;
  parameters: Record<string, ToolParameter>;
  wait_for_response: boolean;
}

interface ToolParameter {
  type: 'string' | 'number' | 'boolean' | 'array';
  items?: { type: string };
  description: string;
  required: boolean;
}
```

## Package.json Scripts

Add to `backend/package.json`:

```json
{
  "scripts": {
    "agent:deploy": "tsx scripts/deploy-agent.ts deploy",
    "agent:status": "tsx scripts/deploy-agent.ts status",
    "agent:delete": "tsx scripts/deploy-agent.ts delete"
  },
  "devDependencies": {
    "tsx": "^4.7.0"
  }
}
```

## Deployment Workflow

```
1. Edit agent config
   └── backend/agents/three-little-pigs.ts

2. Deploy to ElevenLabs
   └── npm run agent:deploy three-little-pigs
       ├── Creates/updates agent via API
       ├── Saves agent ID to .agents.json
       └── Prints wrangler command for Cloudflare secret

3. Update Cloudflare Worker secret
   └── echo "abc123" | wrangler secret put AGENT_ID_THREE_LITTLE_PIGS

4. Test in app
   └── App requests token → Worker returns token → SDK connects
```

## Error Handling

| Error | User Message | Exit Code |
|-------|--------------|-----------|
| Missing story ID | "Error: Missing story ID" + usage | 1 |
| Missing API key | "Error: ELEVENLABS_API_KEY not set" | 1 |
| Config file not found | "Error: Agent config not found: path" | 1 |
| API error (4xx/5xx) | "Error deploying agent: message" + response body | 1 |
| Delete without confirm | "Cancelled." | 0 |

## Voice Selection

Browse voices at: https://elevenlabs.io/voice-library

Recommended voices for Storili:

| Character | Voice | Voice ID | Notes |
|-----------|-------|----------|-------|
| Capy (narrator) | Adam | `pNInz6obpgDQGcFmaJgB` | Warm, friendly, clear |
| Alternative | Josh | `TxGEqnHWrfWFTfGW9XjX` | Younger, enthusiastic |

Voice IDs are found in the ElevenLabs dashboard under Voice Settings.

## Future Enhancements (Post-MVP)

1. **`agent:test` command** - Simulated conversation via API
2. **CI/CD integration** - Auto-deploy on git push to main
3. **Environment separation** - dev/staging/prod agents
4. **Shared modules** - Extract Capy personality when adding story #2
