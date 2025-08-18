#!/usr/bin/env node

/**
 * Generate Roblox Lua SDK from server API contracts
 * This dynamically reads Zod schemas and creates type-safe API wrappers
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { introspectObjectSchema, generateLuaValidation, convertEndpointPath } from './schema-introspection.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverDir = path.resolve(__dirname, '..');
const robloxDir = path.resolve(__dirname, '../../roblox');

/**
 * Generate parameter validation based on field info
 */
function generateParameterValidation(paramName, fieldInfo) {
  switch (fieldInfo.type) {
    case 'string':
      return `\tvalidateString(${paramName}, "${paramName}")\n`;
    case 'number':
      return `\tvalidateNumber(${paramName}, "${paramName}")\n`;
    case 'boolean':
      return `\tvalidateBoolean(${paramName}, "${paramName}")\n`;
    case 'object':
      return `\tassert(type(${paramName}) == "table", "${paramName} must be a table")\n`;
    case 'enum':
      return `\tvalidateEnumGrade(${paramName}, "${paramName}")\n`; // Simplified for now
    default:
      return `\t-- TODO: Add validation for ${paramName} (${fieldInfo.type})\n`;
  }
}

/**
 * Generate SDK module for a contract group
 */
async function generateSDKModule(moduleName, contracts) {
  let sdkCode = `-- Auto-generated ${moduleName} SDK - DO NOT EDIT MANUALLY\n`;
  sdkCode += `-- Generated at: ${new Date().toISOString()}\n\n`;
  sdkCode += `local Http = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Http"))\n\n`;
  sdkCode += `local ${moduleName} = {}\n\n`;

  // Generate validation functions for all unique schemas
  const generatedValidators = new Set();
  
  // Process each endpoint in the contract
  for (const [endpointName, contract] of Object.entries(contracts)) {
    const { name, endpoint, method, requestSchema, querySchema, pathParams, responseSchema, description } = contract;
    
    // Extract parameters from schemas
    const params = [];
    const paramValidations = [];
    
    // Path parameters
    if (pathParams) {
      const pathInfo = introspectObjectSchema(pathParams);
      if (pathInfo && pathInfo.fields) {
        for (const [fieldName, fieldInfo] of Object.entries(pathInfo.fields)) {
          params.push(fieldName);
          paramValidations.push(generateParameterValidation(fieldName, fieldInfo));
        }
      }
    }
    
    // Query parameters
    if (querySchema) {
      const queryInfo = introspectObjectSchema(querySchema);
      if (queryInfo && queryInfo.fields) {
        for (const [fieldName, fieldInfo] of Object.entries(queryInfo.fields)) {
          if (!params.includes(fieldName)) {
            params.push(fieldName);
            paramValidations.push(generateParameterValidation(fieldName, fieldInfo));
          }
        }
      }
    }
    
    // Request body parameters - for complex objects, use object parameters
    if (requestSchema) {
      const requestInfo = introspectObjectSchema(requestSchema);
      if (requestInfo && requestInfo.fields) {
        // For nested objects like { user: {...}, payload: {...} }, pass them as separate parameters
        for (const [fieldName, fieldInfo] of Object.entries(requestInfo.fields)) {
          if (!params.includes(fieldName)) {
            params.push(fieldName);
            paramValidations.push(generateParameterValidation(fieldName, fieldInfo));
          }
        }
      }
    }
    
    sdkCode += `-- ${description || name}\n`;
    sdkCode += `function ${moduleName}.${name}(${params.join(', ')})\n`;
    
    // Add parameter validation
    for (const validation of paramValidations) {
      sdkCode += validation;
    }
    
    // Build request configuration
    sdkCode += '\n\tlocal config = {\n';
    
    // Handle endpoint with path parameters
    if (endpoint.includes('{') && endpoint.includes('}')) {
      let luaEndpoint = endpoint;
      for (const param of params) {
        if (luaEndpoint.includes(`{${param}}`)) {
          luaEndpoint = luaEndpoint.replace(`{${param}}`, `" .. tostring(${param}) .. "`);
        }
      }
      luaEndpoint = `"${luaEndpoint}"`.replace(/ .. ""$/, '').replace(/^"" .. /, '');
      sdkCode += `\t\turl = ${luaEndpoint},\n`;
    } else {
      sdkCode += `\t\turl = "${endpoint}",\n`;
    }
    
    // Determine which parameters go where based on method and schemas
    const pathParamNames = pathParams ? Object.keys(introspectObjectSchema(pathParams)?.fields || {}) : [];
    const queryParamNames = querySchema ? Object.keys(introspectObjectSchema(querySchema)?.fields || {}) : [];
    const requestBodyParamNames = requestSchema ? Object.keys(introspectObjectSchema(requestSchema)?.fields || {}) : [];
    
    // Handle query parameters (GET requests)
    if (queryParamNames.length > 0) {
      sdkCode += '\t\tparams = {\n';
      for (const param of queryParamNames) {
        sdkCode += `\t\t\t${param} = tostring(${param}),\n`;
      }
      sdkCode += '\t\t},\n';
    }
    
    // Handle request body (POST requests)
    if (method === 'POST' && requestBodyParamNames.length > 0) {
      sdkCode += '\t\tjson = {\n';
      for (const param of requestBodyParamNames) {
        sdkCode += `\t\t\t${param} = ${param},\n`;
      }
      sdkCode += '\t\t},\n';
    }
    
    sdkCode += '\t}\n\n';
    
    // Make HTTP request
    const httpMethod = method.toLowerCase();
    sdkCode += `\tlocal response = Http.${httpMethod}(config.url, config)\n\n`;
    
    // Error handling
    sdkCode += '\tif not response.success then\n';
    sdkCode += `\t\terror("Failed to ${name}: " .. tostring(response.body))\n`;
    sdkCode += '\tend\n\n';
    
    sdkCode += '\treturn response.json()\n';
    sdkCode += 'end\n\n';
  }
  
  sdkCode += `return ${moduleName}\n`;
  
  // Clean up duplicate validation functions
  sdkCode = removeDuplicateValidations(sdkCode);
  
  return sdkCode;
}

/**
 * Generate validation for complex objects (like score payload)
 */
function generateComplexObjectValidation(objectName, objectInfo) {
  let validation = `local function validate${capitalize(objectName)}(value, name)\n`;
  validation += '\tassert(type(value) == "table", name .. " must be a table")\n\n';
  validation += '\tlocal validated = {}\n';
  
  for (const [fieldName, fieldInfo] of Object.entries(objectInfo.fields || {})) {
    const accessor = `value.${fieldName}`;
    const fieldNameStr = `name .. ".${fieldName}"`;
    
    switch (fieldInfo.type) {
      case 'string':
        validation += `\tvalidated.${fieldName} = validateString(${accessor}, ${fieldNameStr})\n`;
        break;
      case 'number':
        validation += `\tvalidated.${fieldName} = validateNumber(${accessor}, ${fieldNameStr})\n`;
        break;
      case 'enum':
        validation += `\tvalidated.${fieldName} = validateEnum${capitalize(fieldName)}(${accessor}, ${fieldNameStr})\n`;
        break;
      case 'boolean':
        validation += `\tvalidated.${fieldName} = validateBoolean(${accessor}, ${fieldNameStr})\n`;
        break;
      default:
        validation += `\tvalidated.${fieldName} = ${accessor} -- TODO: Add validation for ${fieldInfo.type}\n`;
    }
  }
  
  validation += '\treturn validated\n';
  validation += 'end\n\n';
  
  return validation;
}

/**
 * Generate basic validation functions
 */
function generateBasicValidations() {
  return `-- Basic validation functions
local function validateString(value, name)
\tassert(type(value) == "string", name .. " must be a string")
\treturn value
end

local function validateNumber(value, name)
\tassert(type(value) == "number", name .. " must be a number")
\treturn value
end

local function validateBoolean(value, name)
\tassert(type(value) == "boolean", name .. " must be a boolean")
\treturn value
end

local function validateEnumGrade(value, name)
\tlocal validGrades = {F=true, D=true, C=true, B=true, A=true, S=true, SS=true}
\tassert(validGrades[value], name .. " must be a valid grade (F, D, C, B, A, S, SS)")
\treturn value
end

`;
}

/**
 * Remove duplicate validation functions
 */
function removeDuplicateValidations(code) {
  const lines = code.split('\n');
  const seenFunctions = new Set();
  const cleanedLines = [];
  let currentFunction = null;
  let functionLines = [];
  
  for (const line of lines) {
    if (line.startsWith('local function validate')) {
      if (currentFunction && seenFunctions.has(currentFunction)) {
        // Skip this duplicate function
        functionLines = [];
        currentFunction = line;
        continue;
      }
      if (currentFunction) {
        cleanedLines.push(...functionLines);
      }
      currentFunction = line;
      functionLines = [line];
      seenFunctions.add(line);
    } else if (line === 'end' && currentFunction) {
      functionLines.push(line);
      cleanedLines.push(...functionLines);
      functionLines = [];
      currentFunction = null;
    } else if (currentFunction) {
      functionLines.push(line);
    } else {
      cleanedLines.push(line);
    }
  }
  
  return cleanedLines.join('\n');
}

/**
 * Capitalize first letter
 */
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Main generation function
 */
async function generateSDK() {
  try {
    console.log('🚀 Starting SDK generation...');
    
    // Import contracts dynamically from compiled JS
    const contractsPath = path.resolve(serverDir, 'dist', 'contracts', 'index.js');
    console.log('📁 Loading contracts from:', contractsPath);
    
    // Convert Windows path to file:// URL for dynamic import
    const contractsUrl = `file:///${contractsPath.replace(/\\/g, '/')}`;
    console.log('📁 Import URL:', contractsUrl);
    
    const { AllContracts } = await import(contractsUrl);
    console.log('✅ Loaded contracts:', Object.keys(AllContracts));
    
    const sdkDir = path.join(robloxDir, 'src', 'shared', 'SDK');
    fs.mkdirSync(sdkDir, { recursive: true });
    
    // Generate SDK modules for each contract group
    for (const [moduleName, contracts] of Object.entries(AllContracts)) {
      const sdkCode = await generateSDKModule(moduleName, contracts);
      const moduleCode = generateBasicValidations() + sdkCode;
      
      const modulePath = path.join(sdkDir, `${moduleName}.lua`);
      fs.writeFileSync(modulePath, moduleCode);
      console.log(`✅ Generated ${moduleName} SDK: ${modulePath}`);
    }
    
    // Generate main SDK module
    const mainSDK = generateMainSDK(Object.keys(AllContracts));
    const mainPath = path.join(sdkDir, 'init.lua');
    fs.writeFileSync(mainPath, mainSDK);
    console.log(`✅ Generated main SDK: ${mainPath}`);
    
    console.log('\\n🎉 Dynamic SDK generation complete!');
    console.log('📝 Usage:');
    console.log('   local SDK = require(game.ReplicatedStorage.SDK)');
    console.log('   local profile = SDK.Players.getProfile(12345)');
    console.log('   SDK.Scores.submit(userInfo, scoreData)');
    
  } catch (error) {
    console.error('❌ Error generating SDK:', error);
    process.exit(1);
  }
}

/**
 * Generate main SDK module
 */
function generateMainSDK(moduleNames) {
  let mainCode = `-- Auto-generated SDK - DO NOT EDIT MANUALLY\n`;
  mainCode += `-- Generated at: ${new Date().toISOString()}\n\n`;
  mainCode += `local SDK = {}\n\n`;
  
  for (const moduleName of moduleNames) {
    mainCode += `SDK.${moduleName} = require(script.${moduleName})\n`;
  }
  
  mainCode += `\nreturn SDK\n`;
  return mainCode;
}

// Run if called directly
const currentModuleUrl = import.meta.url;
const scriptPath = fileURLToPath(currentModuleUrl);
const runPath = process.argv[1];

if (scriptPath === runPath) {
  generateSDK();
}