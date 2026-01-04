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
  llm: 'claude-3-5-sonnet' | 'gpt-4o' | 'gpt-4o-mini' | 'gemini-1.5-pro' | 'gemini-2.5-flash' | 'glm-45-air-fp8';
  temperature?: number;
  max_tokens?: number;
  /**
   * Disable ElevenLabs' default "helpful assistant" personality.
   * Always set to true for Storili - we define our own characters.
   */
  ignore_default_personality?: boolean;
  /**
   * Client tools that can be invoked by the agent.
   */
  tools?: ClientToolConfig[];
}

export interface ClientToolConfig {
  type: 'client';
  name: string;
  description: string;
  parameters?: {
    type: 'object';
    properties: Record<string, {
      type: string;
      description?: string;
      items?: { type: string; description: string };
    }>;
    required?: string[];
  };
  expects_response?: boolean;
}

export interface TTSSettings {
  voice_id: string;
  model_id?: string;
  stability?: number;
  similarity_boost?: number;
  style?: number;
  speed?: number;
  supported_voices?: SupportedVoice[];
}

/**
 * Configuration for a supported voice in multi-voice mode.
 * See: https://elevenlabs.io/docs/agents-platform/customization/voice/multi-voice-support
 */
export interface SupportedVoice {
  /** The voice label used in XML tags, e.g., <Wolf>text</Wolf> */
  label: string;
  /** ElevenLabs voice ID */
  voice_id: string;
  /** Context for when the agent should use this voice */
  description?: string;
  /** Language override for this voice */
  language?: string;
  /** Model family: turbo, flash, or multilingual */
  model_family?: 'turbo' | 'flash' | 'multilingual';
  /** Streaming latency optimization: 0-4 */
  optimize_streaming_latency?: 0 | 1 | 2 | 3 | 4;
  /** Voice stability: 0-1 */
  stability?: number;
  /** Speech speed multiplier */
  speed?: number;
  /** Voice similarity boost: 0-1 */
  similarity_boost?: number;
}

export interface TurnSettings {
  turn_timeout?: number;
  silence_end_call_timeout?: number;
}

export interface Workflow {
  nodes: Record<string, WorkflowNode>;
  edges: Record<string, WorkflowEdge>;
}

export interface WorkflowNode {
  type: 'start' | 'end' | 'override_agent' | 'standalone_agent' | 'tool' | 'phone_number';
  position: { x: number; y: number };
  edge_order: string[];
}

export interface WorkflowEdge {
  source: string;
  target: string;
  forward_condition?: { type: 'unconditional' } | { type: 'llm'; prompt: string };
  backward_condition?: { type: 'unconditional' } | { type: 'llm'; prompt: string };
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
