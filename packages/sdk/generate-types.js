#!/usr/bin/env node

/**
 * Generate Roblox Lua SDK from server API OpenAPI specification
 * This dynamically reads OpenAPI schemas and creates type-safe API wrappers
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import Handlebars from "handlebars";
import {
  fetchOpenApiSpec,
  groupEndpointsByTags,
  extractParameters,
  generateLuaValidation,
  buildLuaUrl,
  extractResponseSchema,
} from "./openapi-processor.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const robloxDir = path.resolve(__dirname, "../../packages/game");

// Load and compile Handlebars templates
const templatesDir = path.resolve(__dirname, "templates");
const validationsTemplate = Handlebars.compile(
  fs.readFileSync(path.join(templatesDir, "validations.hbs"), "utf8")
);
const moduleTemplate = Handlebars.compile(
  fs.readFileSync(path.join(templatesDir, "module.hbs"), "utf8")
);

// Register the method template as a partial
const methodTemplateSource = fs.readFileSync(
  path.join(templatesDir, "method.hbs"),
  "utf8"
);
Handlebars.registerPartial("method", methodTemplateSource);

/**
 * Build method data from OpenAPI operation for template rendering
 * @param {string} moduleName - Module name (e.g., 'Players', 'Scores')
 * @param {Object} endpoint - Endpoint info with path, method, operation
 * @returns {Object} Method data for template
 */
function buildMethodDataFromOpenAPI(moduleName, endpoint) {
  const { path, method, operation } = endpoint;
  const parameters = extractParameters(operation);

  // Generate method name from operationId or path
  const methodName = operation.operationId || generateMethodName(method, path);

  // Build parameter list and validation code
  const params = [];
  const validations = [];
  const paramDocs = [];
  const paramSigParts = [];

  // Add all parameters to the method signature
  for (const param of parameters.allParams) {
    if (!params.includes(param.name)) {
      params.push(param.name);
    }

    // Generate validation code for this parameter
    const validation = generateLuaValidation(param.name, param.schema);
    if (validation && !validation.includes("-- No validation")) {
      validations.push(validation);
    }

    // Build param documentation entry
    paramDocs.push({
      name: param.name,
      type: openApiSchemaToLuauType(param.schema),
      description: param.description || undefined,
      required: param.required || false,
    });

    // Build signature part with Luau typing if available
    const luauType = openApiSchemaToLuauType(param.schema);
    if (luauType && luauType !== "any") {
      paramSigParts.push(
        `${param.name}: ${luauType}${param.required ? "" : "?"}`
      );
    } else {
      paramSigParts.push(param.name);
    }
  }

  // Build query parameters object
  const queryParams = {};
  for (const param of parameters.query) {
    queryParams[param.name] = param.name;
  }

  // Build request body object
  const requestBody = {};
  if (parameters.body && parameters.body.schema?.properties) {
    for (const [propName] of Object.entries(
      parameters.body.schema.properties
    )) {
      requestBody[propName] = propName;
    }
  }

  // Build URL with path parameter substitution
  const url = buildLuaUrl(path, parameters.path);

  // Extract response information for documentation
  const responseSchema = extractResponseSchema(operation);
  let returnType = null;
  let returnDescription = null;
  if (responseSchema) {
    returnType = openApiSchemaToLuauType(responseSchema.schema);
    returnDescription = responseSchema.description || undefined;
  }

  return {
    moduleName,
    name: methodName,
    description:
      operation.summary || operation.description || `${method} ${path}`,
    params,
    validations,
    paramDocs,
    signatureParams: paramSigParts.join(", "),
    url,
    queryParams: Object.keys(queryParams).length > 0 ? queryParams : null,
    requestBody: Object.keys(requestBody).length > 0 ? requestBody : null,
    httpMethod: method.toLowerCase(),
    responseInfo: responseSchema
      ? {
          description: responseSchema.description,
          hasSchema: true,
        }
      : null,
    returnType,
    returnDescription,
    returnTypeAnnotation: returnType ? (returnType ? null : null) : null,
  };
}

/**
 * Convert an OpenAPI schema to a Luau type annotation (best-effort)
 * @param {Object} schema
 * @returns {string}
 */
function openApiSchemaToLuauType(schema) {
  if (!schema) return "any";

  // Enum -> union of string literal types
  if (Array.isArray(schema.enum) && schema.enum.length > 0) {
    const values = schema.enum.map((v) => JSON.stringify(String(v)));
    return values.join(" | ");
  }

  if (schema.oneOf || schema.anyOf || schema.allOf) {
    const list = schema.oneOf || schema.anyOf || schema.allOf || [];
    if (list.length > 0) {
      const parts = list.map((s) => openApiSchemaToLuauType(s));
      if (parts.includes("any")) return "any";
      return dedupe(parts).join(" | ");
    }
  }

  // Nullable flag
  if (schema.nullable) {
    const base = { ...schema };
    delete base.nullable;
    const t = openApiSchemaToLuauType(base);
    return dedupe([t, "nil"]).join(" | ");
  }

  switch (schema.type) {
    case "string":
      if (schema.format === "date-time" || schema.format === "date")
        return "string";
      return "string";
    case "integer":
    case "number":
      return "number";
    case "boolean":
      return "boolean";
    case "array":
      return `{${openApiSchemaToLuauType(schema.items || { type: "any" })}}`;
    case "object":
      if (schema.properties) {
        const fields = Object.entries(schema.properties).map(([k, v]) => {
          // Optional property if not in required list
          const opt =
            Array.isArray(schema.required) && !schema.required.includes(k)
              ? "?"
              : "";
          return `${k}${opt}: ${openApiSchemaToLuauType(v)}`;
        });
        return `{ ${fields.join(", ")} }`;
      }
      return "{ [any]: any }";
    default:
      return "any";
  }
}

function dedupe(arr) {
  const seen = new Set();
  const out = [];
  for (const v of arr) {
    if (!seen.has(v)) {
      seen.add(v);
      out.push(v);
    }
  }
  return out;
}

/**
 * Generate method name from HTTP method and path
 * @param {string} method - HTTP method
 * @param {string} path - API path
 * @returns {string} Generated method name
 */
function generateMethodName(method, path) {
  // Convert patterns like:
  // GET /players -> getPlayers
  // POST /players/join -> joinPlayer
  // GET /scores/leaderboard -> getScoresLeaderboard
  // POST /scores -> submitScore

  const segments = path.split("/").filter(Boolean);

  if (method.toLowerCase() === "post" && segments.length === 2) {
    // POST /players/join -> join
    return segments[1];
  } else if (method.toLowerCase() === "post" && segments.length === 1) {
    // POST /scores -> submit
    return "submit";
  } else if (method.toLowerCase() === "get" && segments.length > 1) {
    // GET /scores/leaderboard -> getLeaderboard
    // GET /players/top -> getTop
    const action = segments.slice(1).map(capitalize).join("");
    return "get" + action;
  } else if (method.toLowerCase() === "get") {
    // GET /players -> get
    return "get";
  }

  // Fallback: method + capitalized segments
  return (
    method.toLowerCase() +
    segments
      .map((s) => {
        // Skip path parameters in method name
        if (s.startsWith("{") && s.endsWith("}")) return "";
        return capitalize(s);
      })
      .join("")
  );
}

/**
 * Generate SDK module from OpenAPI endpoints using Handlebars templates
 * @param {string} moduleName - Module name
 * @param {Array} endpoints - Array of endpoint objects
 * @returns {string} Generated Lua module code
 */
async function generateSDKModuleFromOpenAPI(moduleName, endpoints) {
  const methods = [];
  const typeAliasesMap = new Map();

  // Process each endpoint
  for (const endpoint of endpoints) {
    const methodData = buildMethodDataFromOpenAPI(moduleName, endpoint);

    // Create a type alias for return type if available
    if (methodData.returnType) {
      const baseAlias = capitalize(methodData.name);
      let aliasName = `${baseAlias}Response`;

      // Ensure uniqueness if collisions
      let counter = 2;
      while (
        typeAliasesMap.has(aliasName) &&
        typeAliasesMap.get(aliasName) !== methodData.returnType
      ) {
        aliasName = `${baseAlias}Response${counter++}`;
      }

      typeAliasesMap.set(aliasName, methodData.returnType);
      methodData.returnTypeAlias = aliasName;
    }
    methods.push(methodData);
  }

  // Sort methods by name for consistency
  methods.sort((a, b) => a.name.localeCompare(b.name));

  // Generate module using template
  const moduleData = {
    moduleName,
    timestamp: new Date().toISOString(),
    methods,
    typeAliases: Array.from(typeAliasesMap.entries()).map(
      ([aliasName, definition]) => ({ aliasName, definition })
    ),
  };

  return moduleTemplate(moduleData);
}

/**
 * Generate basic validation functions using template
 */
function generateBasicValidations() {
  // Use real newlines so the generated Lua files don't contain literal \n characters
  return validationsTemplate() + "\n\n";
}

/**
 * Generate main SDK module
 * @param {Array} moduleNames - Array of module names
 * @returns {string} Main SDK module code
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

/**
 * Main SDK generation function
 */
async function generateSDK() {
  try {
    console.log("🚀 Starting OpenAPI-based SDK generation...");

    // Fetch OpenAPI specification from running server
    const serverUrl = process.env.SERVER_URL || "http://localhost:3000";
    let openApiSpec;

    try {
      openApiSpec = await fetchOpenApiSpec(serverUrl);
    } catch (error) {
      console.error(error.message);
      console.log("\\n💡 Troubleshooting:");
      console.log("   1. Start the server: npm run dev");
      console.log("   2. Wait for server to be ready");
      console.log("   3. Run SDK generation: npm run sdk-generate");
      console.log(
        "   4. Or set SERVER_URL env var: SERVER_URL=http://other:port npm run sdk-generate"
      );
      process.exit(1);
    }

    // Create SDK output directory
    const sdkDir = path.join(robloxDir, "shared", "_sdk_bin");
    fs.mkdirSync(sdkDir, { recursive: true });
    console.log(`📁 SDK output directory: ${sdkDir}`);

    // Group endpoints by tags/modules
    const moduleGroups = groupEndpointsByTags(openApiSpec);

    if (Object.keys(moduleGroups).length === 0) {
      console.warn("⚠️  No endpoints found to generate SDK");
      return;
    }

    // Generate SDK modules for each group
    for (const [moduleName, endpoints] of Object.entries(moduleGroups)) {
      console.log(
        `🔧 Generating ${moduleName} module (${endpoints.length} endpoints)...`
      );

      const sdkCode = await generateSDKModuleFromOpenAPI(moduleName, endpoints);
      const moduleCode = generateBasicValidations() + sdkCode;

      const modulePath = path.join(sdkDir, `${moduleName}.lua`);
      fs.writeFileSync(modulePath, moduleCode);
      console.log(`✅ Generated ${moduleName} SDK: ${modulePath}`);

      // Log generated methods for each module
      const methodNames = endpoints.map(
        (e) => e.operation.operationId || generateMethodName(e.method, e.path)
      );
      console.log(`   📋 Methods: ${methodNames.join(", ")}`);
    }

    // Generate main SDK module
    const moduleNames = Object.keys(moduleGroups);
    const mainSDK = generateMainSDK(moduleNames);
    const mainPath = path.join(sdkDir, "init.lua");
    fs.writeFileSync(mainPath, mainSDK);
    console.log(`✅ Generated main SDK: ${mainPath}`);

    console.log("\n🎉 OpenAPI-based SDK generation complete!");
    console.log("\n📚 Generated SDK structure:");
    console.log("   📦 SDK/");
    for (const moduleName of moduleNames) {
      console.log(`   ├── ${moduleName}.lua`);
    }
    console.log("   └── init.lua");

    console.log("\\n📝 Usage example:");
    console.log("   local SDK = require(game.ReplicatedStorage.SDK)");
    if (moduleNames.includes("Players")) {
      console.log('   local profile = SDK.Players.get("12345")');
    }
    if (moduleNames.includes("Scores")) {
      console.log("   local success = SDK.Scores.submit(userInfo, scoreData)");
    }
  } catch (error) {
    console.error("❌ Error generating SDK:", error);
    console.error("Stack trace:", error.stack);
    process.exit(1);
  }
}

/**
 * Capitalize first letter of a string
 * @param {string} str - String to capitalize
 * @returns {string} Capitalized string
 */
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Run if called directly
const currentModuleUrl = import.meta.url;
const scriptPath = fileURLToPath(currentModuleUrl);
const runPath = process.argv[1];

if (scriptPath === runPath) {
  generateSDK();
}

export {
  generateSDK,
  buildMethodDataFromOpenAPI,
  generateSDKModuleFromOpenAPI,
};
