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
