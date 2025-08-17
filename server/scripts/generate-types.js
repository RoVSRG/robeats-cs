#!/usr/bin/env node

/**
 * Generate TypeScript types and Lua schemas from server API routes
 * This ensures API contracts are synchronized between server and Roblox client
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverDir = path.resolve(__dirname, '..');
const robloxDir = path.resolve(__dirname, '../../roblox');

// API Schema definitions based on server routes
const schemas = {
  // Player routes
  PlayerJoinRequest: {
    userId: 'number',
    name: 'string',
  },
  
  PlayerProfile: {
    userId: 'number', 
    name: 'string',
    rating: 'number',
    accuracy: 'number',
    playCount: 'number',
    rank: 'number | null',
  },

  PlayerTopResponse: {
    players: 'PlayerProfile[]',
  },

  PlayerResponse: {
    profile: 'PlayerProfile',
  },

  // Score routes
  ScoreSubmissionRequest: {
    user: {
      userId: 'number',
      name: 'string',
    },
    payload: {
      hash: 'string',
      rate: 'number',
      score: 'number', 
      accuracy: 'number',
      combo: 'number',
      maxCombo: 'number',
      marvelous: 'number',
      perfect: 'number',
      great: 'number', 
      good: 'number',
      bad: 'number',
      miss: 'number',
      grade: "'F' | 'D' | 'C' | 'B' | 'A' | 'S' | 'SS'",
      rating: 'number',
      mean: 'number',
    },
  },

  ScoreEntry: {
    playerId: 'string',
    name: 'string',
    score: 'number',
    accuracy: 'number',
    grade: 'string',
    rating: 'number',
    rank: 'number',
  },

  LeaderboardRequest: {
    hash: 'string',
    userId: 'string',
  },

  LeaderboardResponse: {
    best: 'ScoreEntry | null',
    leaderboard: 'ScoreEntry[]',
  },

  UserBestScoresResponse: {
    scores: 'ScoreEntry[]',
  },

  // Common response wrapper
  ApiResponse: {
    success: 'boolean',
    data: 'any',
    error: 'string | undefined',
  },
};

// Generate TypeScript definitions
function generateTypeScript() {
  let output = `// Auto-generated API types - DO NOT EDIT MANUALLY\n// Generated at: ${new Date().toISOString()}\n\n`;
  
  Object.entries(schemas).forEach(([name, schema]) => {
    output += `export interface ${name} {\n`;
    Object.entries(schema).forEach(([key, type]) => {
      if (typeof type === 'object') {
        output += `  ${key}: {\n`;
        Object.entries(type).forEach(([subKey, subType]) => {
          output += `    ${subKey}: ${subType};\n`;
        });
        output += `  };\n`;
      } else {
        output += `  ${key}: ${type};\n`;
      }
    });
    output += `}\n\n`;
  });

  // Add API endpoint types
  output += `// API Endpoints\n`;
  output += `export interface ApiEndpoints {\n`;
  output += `  '/players/join': { request: PlayerJoinRequest; response: void };\n`;
  output += `  '/players/top': { request: void; response: PlayerTopResponse };\n`;
  output += `  '/players': { request: { userId: string }; response: PlayerResponse };\n`;
  output += `  '/scores': { request: ScoreSubmissionRequest; response: PlayerResponse };\n`;
  output += `  '/scores/leaderboard': { request: LeaderboardRequest; response: LeaderboardResponse };\n`;
  output += `  '/scores/user/best': { request: { userId: string }; response: UserBestScoresResponse };\n`;
  output += `}\n\n`;

  return output;
}

// Generate Lua types for Roblox
function generateLua() {
  let output = `-- Auto-generated API types - DO NOT EDIT MANUALLY\n-- Generated at: ${new Date().toISOString()}\n\n`;
  
  output += `local ApiTypes = {}\n\n`;
  
  // Add validation functions
  output += `-- Validation helpers\n`;
  output += `local function validateNumber(value, name)\n`;
  output += `\tassert(type(value) == "number", name .. " must be a number")\n`;
  output += `\treturn value\n`;
  output += `end\n\n`;
  
  output += `local function validateString(value, name)\n`;
  output += `\tassert(type(value) == "string", name .. " must be a string")\n`;
  output += `\treturn value\n`;
  output += `end\n\n`;

  output += `local function validateGrade(value)\n`;
  output += `\tlocal validGrades = {F=true, D=true, C=true, B=true, A=true, S=true, SS=true}\n`;
  output += `\tassert(validGrades[value], "Invalid grade: " .. tostring(value))\n`;
  output += `\treturn value\n`;
  output += `end\n\n`;

  // Generate schema builders
  output += `-- Schema builders\n`;
  output += `function ApiTypes.createPlayerJoinRequest(userId, name)\n`;
  output += `\treturn {\n`;
  output += `\t\tuserId = validateNumber(userId, "userId"),\n`;
  output += `\t\tname = validateString(name, "name")\n`;
  output += `\t}\n`;
  output += `end\n\n`;

  output += `function ApiTypes.createScoreSubmission(user, payload)\n`;
  output += `\treturn {\n`;
  output += `\t\tuser = {\n`;
  output += `\t\t\tuserId = validateNumber(user.userId, "user.userId"),\n`;
  output += `\t\t\tname = validateString(user.name, "user.name")\n`;
  output += `\t\t},\n`;
  output += `\t\tpayload = {\n`;
  output += `\t\t\thash = validateString(payload.hash, "payload.hash"),\n`;
  output += `\t\t\trate = validateNumber(payload.rate, "payload.rate"),\n`;
  output += `\t\t\tscore = validateNumber(payload.score, "payload.score"),\n`;
  output += `\t\t\taccuracy = validateNumber(payload.accuracy, "payload.accuracy"),\n`;
  output += `\t\t\tcombo = validateNumber(payload.combo, "payload.combo"),\n`;
  output += `\t\t\tmaxCombo = validateNumber(payload.maxCombo, "payload.maxCombo"),\n`;
  output += `\t\t\tmarvelous = validateNumber(payload.marvelous, "payload.marvelous"),\n`;
  output += `\t\t\tperfect = validateNumber(payload.perfect, "payload.perfect"),\n`;
  output += `\t\t\tgreat = validateNumber(payload.great, "payload.great"),\n`;
  output += `\t\t\tgood = validateNumber(payload.good, "payload.good"),\n`;
  output += `\t\t\tbad = validateNumber(payload.bad, "payload.bad"),\n`;
  output += `\t\t\tmiss = validateNumber(payload.miss, "payload.miss"),\n`;
  output += `\t\t\tgrade = validateGrade(payload.grade),\n`;
  output += `\t\t\trating = validateNumber(payload.rating, "payload.rating"),\n`;
  output += `\t\t\tmean = validateNumber(payload.mean, "payload.mean")\n`;
  output += `\t\t}\n`;
  output += `\t}\n`;
  output += `end\n\n`;

  // Add API endpoints
  output += `-- API Endpoints\n`;
  output += `ApiTypes.ENDPOINTS = {\n`;
  output += `\tPLAYERS_JOIN = "/players/join",\n`;
  output += `\tPLAYERS_TOP = "/players/top",\n`;
  output += `\tPLAYERS = "/players",\n`;
  output += `\tSCORES = "/scores",\n`;
  output += `\tSCORES_LEADERBOARD = "/scores/leaderboard",\n`;
  output += `\tSCORES_USER_BEST = "/scores/user/best"\n`;
  output += `}\n\n`;

  output += `return ApiTypes\n`;
  
  return output;
}

// Write files
function writeFiles() {
  // TypeScript types for server
  const tsOutput = generateTypeScript();
  const tsPath = path.join(serverDir, 'src', 'types', 'api.generated.ts');
  
  // Ensure directory exists
  fs.mkdirSync(path.dirname(tsPath), { recursive: true });
  fs.writeFileSync(tsPath, tsOutput);
  console.log(`✅ Generated TypeScript types: ${tsPath}`);

  // Lua types for Roblox
  const luaOutput = generateLua();
  const luaPath = path.join(robloxDir, 'src', 'shared', 'ApiTypes.generated.lua');
  
  // Ensure directory exists
  fs.mkdirSync(path.dirname(luaPath), { recursive: true });
  fs.writeFileSync(luaPath, luaOutput);
  console.log(`✅ Generated Lua types: ${luaPath}`);

  console.log('\n🎉 API contract generation complete!');
  console.log('📝 Remember to update these files when API routes change.');
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  writeFiles();
}