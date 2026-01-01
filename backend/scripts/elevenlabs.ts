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
