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
