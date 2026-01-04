# ElevenLabs Client Tools API - Critical Findings

> **Date:** 2026-01-05
> **Issue:** Agent disconnecting immediately with reason "agent"
> **Root Cause:** Client tools were in wrong API location

## The Problem

The original implementation placed client tools as a top-level `client_tools` array in the agent config:

```typescript
// WRONG - This does NOT work
export const config: AgentConfig = {
  name: 'Storili - Three Little Pigs',
  conversation_config: { ... },
  workflow: { ... },
  client_tools: [  // <-- WRONG LOCATION
    { name: 'change_scene', ... },
  ],
};
```

When deployed, the ElevenLabs API accepted this config but the `tools` array in the agent was **empty**. The agent would try to call tools that didn't exist, causing immediate disconnection with reason `"agent"`.

## The Solution

Client tools must be placed inside `conversation_config.agent.prompt.tools[]` with these requirements:

1. **Location:** `conversation_config.agent.prompt.tools[]`
2. **Type field:** Each tool must have `type: "client"`
3. **Parameters format:** Must use JSON Schema format
4. **Array items:** Must include `description` field

### Correct Format

```typescript
export const config: AgentConfig = {
  name: 'Storili - Three Little Pigs',
  conversation_config: {
    agent: {
      first_message: "Hello!",
      language: 'en',
      prompt: {
        prompt: SYSTEM_PROMPT,
        llm: 'gpt-4o-mini',
        tools: [  // <-- CORRECT LOCATION
          {
            type: 'client',  // <-- REQUIRED
            name: 'change_scene',
            description: 'Transition to a new scene.',
            parameters: {
              type: 'object',  // <-- JSON Schema format
              properties: {
                scene_name: {
                  type: 'string',
                  description: 'Scene identifier',
                },
              },
              required: ['scene_name'],
            },
            expects_response: false,
          },
          {
            type: 'client',
            name: 'suggest_actions',
            description: 'Offer action choices.',
            parameters: {
              type: 'object',
              properties: {
                actions: {
                  type: 'array',
                  items: {
                    type: 'string',
                    description: 'An action phrase'  // <-- REQUIRED for array items
                  },
                  description: 'Action choices',
                },
              },
              required: ['actions'],
            },
            expects_response: false,
          },
        ],
      },
    },
  },
};
```

### API Error Without Item Description

If array items don't have a `description`, the API returns:

```json
{
  "detail": [{
    "type": "value_error",
    "loc": ["body", "conversation_config", "agent", "prompt", "tools", 1, "client", "parameters", "properties", "actions", "array", "items", "string"],
    "msg": "Value error, Must set one of: description, dynamic_variable, is_system_provided, or constant_value"
  }]
}
```

## LLM Model Compatibility

The `glm-45-air-fp8` model caused immediate disconnects even with correct tool configuration. Switching to `gpt-4o-mini` resolved this.

| Model | Status | Notes |
|-------|--------|-------|
| `glm-45-air-fp8` | Fails | Causes immediate disconnect |
| `gpt-4o-mini` | Works | Reliable tool calling |
| `gpt-4o` | Untested | Should work |
| `claude-3-5-sonnet` | Untested | Should work |

## Debugging Tips

1. **Check disconnect reason:** If `details?.reason === "agent"`, the agent itself is crashing
2. **Verify tools deployed:** Query agent via API and check `conversation_config.agent.prompt.tools` is not empty
3. **Test on ElevenLabs platform:** If agent works on web but not in app, the issue is client-side tool registration mismatch

## Files Changed

- `backend/agents/types.ts` - Updated `PromptSettings` to include `tools` and added `ClientToolConfig` interface
- `backend/agents/three-little-pigs.ts` - Moved tools to correct location with proper schema
