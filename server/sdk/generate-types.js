#!/usr/bin/env node

/**
 * Generate Roblox Lua SDK from server API contracts
 * This dynamically reads Zod schemas and creates type-safe API wrappers
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Handlebars from 'handlebars';
import {
  introspectObjectSchema,
  generateLuaValidation,
  convertEndpointPath,
} from './schema-introspection.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverDir = path.resolve(__dirname, '..');
const robloxDir = path.resolve(__dirname, '../../roblox');

// Load and compile Handlebars templates
const templatesDir = path.resolve(__dirname, 'templates');
const validationsTemplate = Handlebars.compile(
  fs.readFileSync(path.join(templatesDir, 'validations.hbs'), 'utf8')
);
const moduleTemplate = Handlebars.compile(
  fs.readFileSync(path.join(templatesDir, 'module.hbs'), 'utf8')
);
const methodTemplate = Handlebars.compile(
  fs.readFileSync(path.join(templatesDir, 'method.hbs'), 'utf8')
);

// Register the method template as a partial
const methodTemplateSource = fs.readFileSync(path.join(templatesDir, 'method.hbs'), 'utf8');
Handlebars.registerPartial('method', methodTemplateSource);

/**
 * Generate parameter validation based on field info
 */
function generateParameterValidation(paramName, fieldInfo) {
  switch (fieldInfo.type) {
    case 'string':
      return `validateString(${paramName}, "${paramName}")`;
    case 'number':
      return `validateNumber(${paramName}, "${paramName}")`;
    case 'boolean':
      return `validateBoolean(${paramName}, "${paramName}")`;
    case 'object':
      return `assert(type(${paramName}) == "table", "${paramName} must be a table")`;
    case 'enum':
      return `validateEnumGrade(${paramName}, "${paramName}")`;
    default:
      return `-- TODO: Add validation for ${paramName} (${fieldInfo.type})`;
  }
}

/**
 * Build method data for template rendering
 */
function buildMethodData(moduleName, name, endpoint, method, requestSchema, querySchema, pathParams, description) {
  // Extract parameters from schemas
  const params = [];
  const validations = [];
  const queryParams = {};
  const requestBody = {};

  // Path parameters
  if (pathParams) {
    const pathInfo = introspectObjectSchema(pathParams);
    if (pathInfo && pathInfo.fields) {
      for (const [fieldName, fieldInfo] of Object.entries(pathInfo.fields)) {
        params.push(fieldName);
        validations.push(generateParameterValidation(fieldName, fieldInfo));
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
          validations.push(generateParameterValidation(fieldName, fieldInfo));
        }
        queryParams[fieldName] = fieldName;
      }
    }
  }

  // Request body parameters
  if (requestSchema) {
    const requestInfo = introspectObjectSchema(requestSchema);
    if (requestInfo && requestInfo.fields) {
      for (const [fieldName, fieldInfo] of Object.entries(requestInfo.fields)) {
        if (!params.includes(fieldName)) {
          params.push(fieldName);
          validations.push(generateParameterValidation(fieldName, fieldInfo));
        }
        if (method === 'POST') {
          requestBody[fieldName] = fieldName;
        }
      }
    }
  }

  // Build URL with path parameters
  let url = endpoint;
  if (endpoint.includes('{') && endpoint.includes('}')) {
    for (const param of params) {
      if (url.includes(`{${param}}`)) {
        url = url.replace(`{${param}}`, `" .. tostring(${param}) .. "`);
      }
    }
    url = `"${url}"`.replace(/ .. ""$/, '').replace(/^"" .. /, '');
  } else {
    url = `"${endpoint}"`;
  }

  return {
    moduleName,
    name,
    description: description || name,
    params,
    validations,
    url,
    queryParams: Object.keys(queryParams).length > 0 ? queryParams : null,
    requestBody: Object.keys(requestBody).length > 0 ? requestBody : null,
    httpMethod: method.toLowerCase()
  };
}

/**
 * Generate SDK module for a contract group using Handlebars templates
 */
async function generateSDKModule(moduleName, contracts) {
  const methods = [];

  // Process each endpoint in the contract
  for (const [endpointName, contract] of Object.entries(contracts)) {
    const {
      name,
      endpoint,
      method,
      requestSchema,
      querySchema,
      pathParams,
      responseSchema,
      description,
    } = contract;

    const methodData = buildMethodData(moduleName, name, endpoint, method, requestSchema, querySchema, pathParams, description);
    methods.push(methodData);
  }

  // Generate module using template
  const moduleData = {
    moduleName,
    timestamp: new Date().toISOString(),
    methods
  };

  return moduleTemplate(moduleData);
}

/**
 * Generate validation for complex objects (like score payload)
 */
function generateComplexObjectValidation(objectName, objectInfo) {
  let validation = `local function validate${capitalize(objectName)}(value, name)\n`;
  validation +=
    '\tassert(type(value) == "table", name .. " must be a table")\n\n';
  validation += '\tlocal validated = {}\n';

  for (const [fieldName, fieldInfo] of Object.entries(
    objectInfo.fields || {}
  )) {
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
 * Generate basic validation functions using template
 */
function generateBasicValidations() {
  return validationsTemplate() + '\n\n';
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
    const contractsPath = path.resolve(
      serverDir,
      'dist',
      'contracts',
      'index.js'
    );
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
