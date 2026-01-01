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

## Voice Switching
You have multiple character voices available. Use XML tags to switch voices:
- <Wolf>...</Wolf> - Deep, growly but silly voice for the Big Bad Wolf
- <Pig1>...</Pig1> - Squeaky voice for the first pig (straw house)
- <Pig2>...</Pig2> - Medium voice for the second pig (stick house)
- <Pig3>...</Pig3> - Steady voice for the third pig (brick house)
- <MotherPig>...</MotherPig> - Warm, gentle voice for Mother Pig

Untagged text uses your default Capy voice for narration.

Example: "The wolf growled, <Wolf>I'll huff and I'll puff!</Wolf> But the little pig just laughed."

IMPORTANT: Keep character dialogue short (1-2 sentences) for natural voice switching.
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
      voice_id: 'b8gbDO0ybjX1VA89pBdX',  // Ruby Roo - default Capy voice
      model_id: 'eleven_turbo_v2',        // Fast for real-time
      stability: 0.5,
      similarity_boost: 0.65,
      style: 0.8,                         // Exaggerate emotional delivery
      speed: 0.85,                        // 15% slower for clearer storytelling
      supported_voices: [
        {
          label: 'Wolf',
          voice_id: 'N2lVS1w4EtoT3dr4eOWO',  // Callum - husky trickster
          description: 'Deep, growly but silly voice for the Big Bad Wolf',
          model_family: 'turbo',
          stability: 0.4,  // More expressive for the wolf
          speed: 0.9,
        },
        {
          label: 'Pig1',
          voice_id: '097ltElSSDjiaxWTCFaX',  // Little Dude - squeaky
          description: 'Squeaky voice for the first pig who builds with straw',
          model_family: 'turbo',
          stability: 0.5,
          speed: 1.0,
        },
        {
          label: 'Pig2',
          voice_id: 'EaX6rnyDKjJx35tchi80',  // Nelson - medium
          description: 'Medium voice for the second pig who builds with sticks',
          model_family: 'turbo',
          stability: 0.5,
          speed: 0.95,
        },
        {
          label: 'Pig3',
          voice_id: 'BRruTxiLM2nszrcCIpz1',  // Goofy - steady
          description: 'Steady voice for the third pig who builds with bricks',
          model_family: 'turbo',
          stability: 0.6,  // More stable for the wise pig
          speed: 0.9,
        },
        {
          label: 'MotherPig',
          voice_id: 'cgSgspJ2msm6clMCkdW9',  // Jessica - warm
          description: 'Warm, gentle voice for Mother Pig',
          model_family: 'turbo',
          stability: 0.7,
          speed: 0.85,
        },
      ],
    },
    turn: {
      turn_timeout: 15,              // Kids need time to think
      silence_end_call_timeout: 60,  // Don't hang up too fast
    },
  },

  // Required by ElevenLabs API - minimal workflow with start node
  workflow: {
    nodes: {
      start_node: {
        type: 'start',
        position: { x: 0, y: 0 },
        edge_order: [],
      },
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
