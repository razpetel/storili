# ElevenLabs API Agent Configuration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a TypeScript-based CLI for deploying ElevenLabs conversational AI agents via their API.

**Architecture:** Agent configurations are TypeScript files in `backend/agents/`. A deploy script reads the config, calls ElevenLabs API to create/update agents, and tracks deployed agent IDs in `.agents.json`. The existing Cloudflare Worker uses these agent IDs to generate conversation tokens.

**Tech Stack:** TypeScript, Node.js (tsx runner), ElevenLabs Conversational AI API, Cloudflare Workers

---

## Task 1: Add tsx dependency and agent scripts to package.json

**Files:**
- Modify: `backend/package.json`

**Step 1: Update package.json with new scripts and dependency**

```json
{
  "name": "storili-token-worker",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "deploy:prod": "wrangler deploy --env production",
    "agent:deploy": "tsx scripts/deploy-agent.ts deploy",
    "agent:status": "tsx scripts/deploy-agent.ts status",
    "agent:delete": "tsx scripts/deploy-agent.ts delete"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20241205.0",
    "tsx": "^4.7.0",
    "typescript": "^5.0.0",
    "wrangler": "^3.0.0"
  }
}
```

**Step 2: Install dependencies**

Run: `cd backend && npm install`
Expected: `added 1 package` (tsx)

**Step 3: Commit**

```bash
git add backend/package.json backend/package-lock.json
git commit -m "chore: add tsx and agent management scripts"
```

---

## Task 2: Create TypeScript types for agent configuration

**Files:**
- Create: `backend/agents/types.ts`

**Step 1: Create the types file**

```typescript
// backend/agents/types.ts

/**
 * ElevenLabs Conversational AI Agent Configuration
 *
 * These types match the ElevenLabs API schema for creating/updating agents.
 * See: https://elevenlabs.io/docs/agents-platform/api-reference/agents/create
 */

export interface AgentConfig {
  name: string;
  conversation_config: ConversationConfig;
  workflow: Workflow;
  client_tools?: ClientTool[];
}

export interface ConversationConfig {
  agent: AgentSettings;
  tts?: TTSSettings;
  turn?: TurnSettings;
}

export interface AgentSettings {
  first_message: string;
  language: string;
  prompt: PromptSettings;
}

export interface PromptSettings {
  prompt: string;
  llm: 'claude-3-5-sonnet' | 'gpt-4o' | 'gpt-4o-mini' | 'gemini-1.5-pro';
  temperature?: number;
  max_tokens?: number;
}

export interface TTSSettings {
  voice_id: string;
  model_id?: string;
  stability?: number;
  similarity_boost?: number;
}

export interface TurnSettings {
  turn_timeout?: number;
  silence_end_call_timeout?: number;
}

export interface Workflow {
  nodes: Record<string, WorkflowNode>;
  edges: Record<string, WorkflowEdge[]>;
}

export interface WorkflowNode {
  type: 'start' | 'agent' | 'end';
}

export interface WorkflowEdge {
  target: string;
  condition?: string;
}

export interface ClientTool {
  name: string;
  description: string;
  parameters: Record<string, ToolParameter>;
  wait_for_response: boolean;
}

export interface ToolParameter {
  type: 'string' | 'number' | 'boolean' | 'array';
  items?: { type: string };
  description: string;
  required: boolean;
}

/**
 * Registry entry for tracking deployed agents
 */
export interface AgentRegistryEntry {
  agentId: string;
  deployedAt: string;
  configHash: string;
}

export interface AgentRegistry {
  [storyId: string]: AgentRegistryEntry;
}
```

**Step 2: Verify TypeScript compiles**

Run: `cd backend && npx tsc agents/types.ts --noEmit --esModuleInterop`
Expected: No output (success)

**Step 3: Commit**

```bash
git add backend/agents/types.ts
git commit -m "feat: add TypeScript types for ElevenLabs agent config"
```

---

## Task 3: Create ElevenLabs API client

**Files:**
- Create: `backend/scripts/elevenlabs.ts`

**Step 1: Create the API client**

```typescript
// backend/scripts/elevenlabs.ts

import type { AgentConfig } from '../agents/types';

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
      const error = await response.json().catch(() => ({ detail: response.statusText }));
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
      const error = await response.json().catch(() => ({ detail: response.statusText }));
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
      const error = await response.json().catch(() => ({ detail: response.statusText }));
      throw new Error(`Failed to delete agent: ${JSON.stringify(error)}`);
    }
  }

  async getAgent(agentId: string): Promise<AgentConfig & { agent_id: string }> {
    const response = await fetch(`${BASE_URL}/convai/agents/${agentId}`, {
      headers: {
        'xi-api-key': this.apiKey,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: response.statusText }));
      throw new Error(`Failed to get agent: ${JSON.stringify(error)}`);
    }

    return response.json();
  }

  async listAgents(): Promise<Array<{ agent_id: string; name: string }>> {
    const response = await fetch(`${BASE_URL}/convai/agents`, {
      headers: {
        'xi-api-key': this.apiKey,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: response.statusText }));
      throw new Error(`Failed to list agents: ${JSON.stringify(error)}`);
    }

    const data = await response.json();
    return data.agents || [];
  }
}
```

**Step 2: Verify TypeScript compiles**

Run: `cd backend && npx tsc scripts/elevenlabs.ts --noEmit --esModuleInterop --module nodenext --moduleResolution nodenext`
Expected: No output (success)

**Step 3: Commit**

```bash
git add backend/scripts/elevenlabs.ts
git commit -m "feat: add ElevenLabs API client for agent management"
```

---

## Task 4: Create deploy script

**Files:**
- Create: `backend/scripts/deploy-agent.ts`

**Step 1: Create the deploy script**

```typescript
// backend/scripts/deploy-agent.ts

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { createHash } from 'crypto';
import * as readline from 'readline';
import { ElevenLabsAPI } from './elevenlabs';
import type { AgentRegistry } from '../agents/types';

const AGENTS_FILE = '.agents.json';

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

  // Dynamic import of the agent config
  const module = await import(`../agents/${storyId}.js`);
  const config = module.config;

  if (!config) {
    console.error(`Error: No 'config' export found in ${configPath}`);
    process.exit(1);
  }

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
    const err = error as Error;
    console.error(`Error deploying agent: ${err.message}`);
    process.exit(1);
  }

  // Update registry
  registry[storyId] = {
    agentId,
    deployedAt: new Date().toISOString(),
    configHash,
  };
  saveRegistry(registry);

  // Print Cloudflare secret command
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

  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error('Error: ELEVENLABS_API_KEY environment variable not set');
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

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  const answer = await new Promise<string>(resolve => {
    rl.question('> ', resolve);
  });
  rl.close();

  if (answer !== 'delete') {
    console.log('Cancelled.');
    return;
  }

  const api = new ElevenLabsAPI(apiKey);

  try {
    await api.deleteAgent(agentId);
  } catch (error) {
    const err = error as Error;
    console.error(`Error deleting agent: ${err.message}`);
    process.exit(1);
  }

  delete registry[storyId];
  saveRegistry(registry);

  console.log(`✓ Deleted ${storyId} (${agentId})`);
}

function loadRegistry(): AgentRegistry {
  if (!existsSync(AGENTS_FILE)) return {};
  try {
    return JSON.parse(readFileSync(AGENTS_FILE, 'utf-8'));
  } catch {
    return {};
  }
}

function saveRegistry(registry: AgentRegistry) {
  writeFileSync(AGENTS_FILE, JSON.stringify(registry, null, 2) + '\n');
}

function hash(content: string): string {
  return createHash('sha256').update(content).digest('hex');
}

main().catch(err => {
  console.error('Unexpected error:', err);
  process.exit(1);
});
```

**Step 2: Verify TypeScript compiles**

Run: `cd backend && npx tsc scripts/deploy-agent.ts --noEmit --esModuleInterop --module nodenext --moduleResolution nodenext --skipLibCheck`
Expected: No output (success)

**Step 3: Verify help command works**

Run: `cd backend && npx tsx scripts/deploy-agent.ts`
Expected: Shows help text with usage instructions

**Step 4: Commit**

```bash
git add backend/scripts/deploy-agent.ts
git commit -m "feat: add agent deploy CLI script"
```

---

## Task 5: Create Three Little Pigs agent configuration

**Files:**
- Create: `backend/agents/three-little-pigs.ts`

**Step 1: Create the agent configuration**

```typescript
// backend/agents/three-little-pigs.ts

import type { AgentConfig } from './types';

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
      voice_id: 'pNInz6obpgDQGcFmaJgB',  // "Adam" - warm, friendly
      model_id: 'eleven_turbo_v2_5',
      stability: 0.7,
      similarity_boost: 0.8,
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
          description: "Personalized summary of child's journey for resume context",
          required: true,
        },
      },
      wait_for_response: false,
    },
  ],
};
```

**Step 2: Verify TypeScript compiles**

Run: `cd backend && npx tsc agents/three-little-pigs.ts --noEmit --esModuleInterop --module nodenext --moduleResolution nodenext`
Expected: No output (success)

**Step 3: Commit**

```bash
git add backend/agents/three-little-pigs.ts
git commit -m "feat: add Three Little Pigs agent configuration"
```

---

## Task 6: Create empty agents registry file

**Files:**
- Create: `backend/.agents.json`

**Step 1: Create empty registry**

```json
{}
```

**Step 2: Verify status command works with empty registry**

Run: `cd backend && npx tsx scripts/deploy-agent.ts status`
Expected: `No agents deployed yet.`

**Step 3: Commit**

```bash
git add backend/.agents.json
git commit -m "chore: add empty agents registry file"
```

---

## Task 7: Test deploy command (dry run without API key)

**Files:**
- None (verification only)

**Step 1: Verify deploy fails gracefully without API key**

Run: `cd backend && npx tsx scripts/deploy-agent.ts deploy three-little-pigs`
Expected: `Error: ELEVENLABS_API_KEY environment variable not set`

**Step 2: Verify deploy fails gracefully with invalid story ID**

Run: `cd backend && ELEVENLABS_API_KEY=test npx tsx scripts/deploy-agent.ts deploy nonexistent`
Expected: `Error: Agent config not found: ./agents/nonexistent.ts`

**Step 3: No commit needed (verification only)**

---

## Task 8: Create tsconfig for scripts

**Files:**
- Create: `backend/tsconfig.json`

**Step 1: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "outDir": "./dist",
    "rootDir": ".",
    "declaration": true,
    "resolveJsonModule": true
  },
  "include": ["scripts/**/*.ts", "agents/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

**Step 2: Verify TypeScript compiles all files**

Run: `cd backend && npx tsc --noEmit`
Expected: No output (success)

**Step 3: Commit**

```bash
git add backend/tsconfig.json
git commit -m "chore: add tsconfig for agent scripts"
```

---

## Task 9: Final integration test

**Files:**
- None (verification only)

**Step 1: Verify all commands work**

Run:
```bash
cd backend
npx tsx scripts/deploy-agent.ts --help
npx tsx scripts/deploy-agent.ts status
```

Expected:
- Help shows usage instructions
- Status shows "No agents deployed yet."

**Step 2: Create final summary commit**

```bash
git add -A
git commit -m "feat: complete ElevenLabs API agent configuration system

- TypeScript types for agent config schema
- ElevenLabs API client (create, update, delete, list)
- CLI deploy script with hash-based change detection
- Three Little Pigs agent configuration with full prompt
- Agent registry tracking in .agents.json

Usage:
  npm run agent:deploy three-little-pigs
  npm run agent:status
  npm run agent:delete <agent-id>"
```

---

## Post-Implementation: Live Deployment

After the implementation is complete, to actually deploy an agent:

1. Get an ElevenLabs API key from https://elevenlabs.io/
2. Run:
   ```bash
   cd backend
   ELEVENLABS_API_KEY=your_key_here npm run agent:deploy three-little-pigs
   ```
3. Copy the printed wrangler command to set the Cloudflare secret
4. Test in the Flutter app

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Add tsx dependency | package.json |
| 2 | TypeScript types | agents/types.ts |
| 3 | API client | scripts/elevenlabs.ts |
| 4 | Deploy script | scripts/deploy-agent.ts |
| 5 | Agent config | agents/three-little-pigs.ts |
| 6 | Empty registry | .agents.json |
| 7 | Verification | (none) |
| 8 | tsconfig | tsconfig.json |
| 9 | Final test | (none) |

**Total new files:** 5
**Total lines:** ~450

---

## CRITICAL CORRECTION (2026-01-05)

The original implementation placed client tools at the WRONG location. See `docs/research/2026-01-05-elevenlabs-client-tools-fix.md` for full details.

### Summary of Changes

**Wrong (original plan):**
```typescript
export const config: AgentConfig = {
  name: '...',
  conversation_config: { ... },
  client_tools: [ ... ],  // WRONG - top level
};
```

**Correct:**
```typescript
export const config: AgentConfig = {
  name: '...',
  conversation_config: {
    agent: {
      prompt: {
        prompt: '...',
        llm: 'gpt-4o-mini',  // NOT glm-45-air-fp8
        tools: [  // CORRECT - inside prompt
          {
            type: 'client',  // REQUIRED
            name: 'change_scene',
            parameters: {
              type: 'object',  // JSON Schema format
              properties: { ... },
              required: [ ... ],
            },
            expects_response: false,
          },
        ],
      },
    },
  },
};
```

### Key Corrections

1. **Location:** `client_tools` → `conversation_config.agent.prompt.tools`
2. **Type field:** Each tool needs `type: "client"`
3. **Parameters format:** Use JSON Schema (`type: "object"`, `properties`, `required`)
4. **Array items:** Must include `description` field
5. **LLM model:** Use `gpt-4o-mini` instead of experimental models
