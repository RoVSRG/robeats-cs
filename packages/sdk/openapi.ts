/**
 * OpenAPI Specification Processing Utilities
 * Simplified, typed helpers to fetch, inspect, and transform an OpenAPI spec
 * for Lua SDK generation.
 */

/* -------------------------------------------------------------------------- */
/*  Core OpenAPI-ish Type Definitions (minimal subset we actually consume)    */
/* -------------------------------------------------------------------------- */

// NOTE: These are intentionally partial – only fields we use are modeled.
// Extend incrementally as new needs arise.

export interface SchemaObject {
  type?: string;
  enum?: (string | number)[];
  properties?: Record<string, SchemaObject>;
  required?: string[];
  minimum?: number;
  maximum?: number;
  minLength?: number;
  maxLength?: number;
  pattern?: string;
  items?: SchemaObject; // arrays (not used yet but handy)
}

export interface ParameterObject {
  name: string;
  in: "path" | "query" | "header" | "cookie";
  required?: boolean;
  description?: string;
  schema?: SchemaObject;
}

export interface RequestBodyObject {
  required?: boolean;
  content?: {
    "application/json"?: { schema?: SchemaObject };
    [contentType: string]: { schema?: SchemaObject } | undefined;
  };
}

export interface ResponseObject {
  description?: string;
  content?: {
    "application/json"?: { schema?: SchemaObject };
    [contentType: string]: { schema?: SchemaObject } | undefined;
  };
}

export interface OperationObject {
  operationId?: string;
  description?: string;
  tags?: string[];
  parameters?: ParameterObject[];
  requestBody?: RequestBodyObject;
  responses?: Record<string, ResponseObject>;
}

export type PathItemObject = Partial<
  Record<
    "get" | "post" | "put" | "patch" | "delete" | "options" | "head",
    OperationObject
  >
> & { [extension: string]: any };

export interface OpenApiSpec {
  openapi?: string; // v3
  swagger?: string; // v2
  paths?: Record<string, PathItemObject>;
  // Additional fields ignored for now
}

/* -------------------------------------------------------------------------- */
/*  Derived Internal Types                                                    */
/* -------------------------------------------------------------------------- */

export interface GroupedEndpoint {
  path: string;
  method: HttpMethod;
  description: string;
  operation: OperationObject; // guaranteed to have operationId post-processing
}

export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export interface EndpointGroups {
  [moduleName: string]: GroupedEndpoint[];
}

export interface ExtractedParameterInfo {
  name: string;
  type: string;
  required: boolean;
  description?: string;
  schema?: SchemaObject;
  isBodyParam?: boolean;
}

export interface ExtractedParametersResult {
  path: ExtractedParameterInfo[];
  query: ExtractedParameterInfo[];
  body: null | { schema: SchemaObject; required: boolean };
  allParams: ExtractedParameterInfo[]; // union for validation generation
}

export interface ResponseSchemaInfo {
  schema: SchemaObject;
  description?: string;
}

/**
 * Fetch OpenAPI specification from a running server
 * @param {string} serverUrl - Base URL of the server (e.g., 'http://localhost:3000')
 * @returns {Promise<Object>} OpenAPI specification object
 */
export async function fetchOpenApiSpec(
  serverUrl = "http://localhost:3000"
): Promise<OpenApiSpec> {
  const swaggerUrl = `${serverUrl}/docs/json`;

  try {
    console.log(`🌐 Fetching OpenAPI spec from: ${swaggerUrl}`);

    const response = await fetch(swaggerUrl);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const spec: OpenApiSpec = await response.json();

    if (!spec.openapi && !spec.swagger) {
      throw new Error(
        "Invalid OpenAPI specification: missing openapi/swagger field"
      );
    }

    console.log(
      `✅ Successfully fetched OpenAPI ${
        spec.openapi || spec.swagger
      } specification`
    );
    console.log(`📋 Found ${Object.keys(spec.paths || {}).length} paths`);

    return spec;
  } catch (error) {
    if (error.code === "ECONNREFUSED" || error.cause?.code === "ECONNREFUSED") {
      throw new Error(
        `❌ Cannot connect to server at ${serverUrl}\n` +
          `💡 Make sure the server is running with: npm run dev`
      );
    }
    throw new Error(`❌ Failed to fetch OpenAPI spec: ${error.message}`);
  }
}

/**
 * Group OpenAPI endpoints by tags to create SDK modules
 * @param {Object} openApiSpec - OpenAPI specification
 * @returns {Object} Grouped endpoints by module name
 */
export function groupEndpointsByTags(openApiSpec: OpenApiSpec): EndpointGroups {
  const groups: EndpointGroups = {};

  if (!openApiSpec.paths) {
    console.warn("⚠️  No paths found in OpenAPI specification");
    return groups;
  }

  Object.entries(openApiSpec.paths).forEach(([path, pathItem]) => {
    if (!pathItem) return;
    (["get", "post", "put", "patch", "delete"] as const).forEach((m) => {
      const op = pathItem[m];
      if (!op) return;
      const moduleName = deriveModuleName(path, op);
      groups[moduleName] ||= [];
      groups[moduleName].push({
        path,
        method: m.toUpperCase() as HttpMethod,
        description: op.description || "",
        operation: {
          ...op,
          operationId: op.operationId || generateOperationId(m, path),
        },
      });
    });
  });

  console.log(
    `📂 Grouped endpoints into modules:`,
    Object.keys(groups).join(", ")
  );
  return groups;
}

/**
 * Generate operation ID from method and path if not provided
 * @param {string} method - HTTP method
 * @param {string} path - API path
 * @returns {string} Generated operation ID
 */
function generateOperationId(method: string, path: string): string {
  // Convert /players/join -> playersJoin, /scores/{id} -> scoresById
  const cleanPath = path
    .split("/")
    .filter(Boolean)
    .map((segment) => {
      // Replace path parameters with 'By' + parameter name
      if (segment.startsWith("{") && segment.endsWith("}")) {
        const paramName = segment.slice(1, -1);
        return "By" + capitalize(paramName);
      }
      return segment;
    })
    .map((segment, index) => (index === 0 ? segment : capitalize(segment)))
    .join("");

  return method.toLowerCase() + capitalize(cleanPath);
}

/**
 * Extract parameters from OpenAPI operation
 * @param {Object} operation - OpenAPI operation object
 * @returns {Object} Categorized parameters
 */
export function extractParameters(
  operation: OperationObject
): ExtractedParametersResult {
  const result: ExtractedParametersResult = {
    path: [],
    query: [],
    body: null,
    allParams: [],
  };

  // Extract path and query parameters
  if (operation.parameters) {
    operation.parameters.forEach((param) => {
      const info: ExtractedParameterInfo = {
        name: param.name,
        type: param.schema?.type || "string",
        required: !!param.required,
        description: param.description,
        schema: param.schema,
      };
      if (param.in === "path") {
        result.path.push(info);
        result.allParams.push(info);
      } else if (param.in === "query") {
        result.query.push(info);
        result.allParams.push(info);
      }
    });
  }

  // Extract request body parameters
  if (operation.requestBody?.content?.["application/json"]?.schema) {
    const bodySchema =
      operation.requestBody.content["application/json"]!.schema!;
    result.body = {
      schema: bodySchema,
      required: operation.requestBody.required || false,
    };

    // If body has properties, add them to allParams for validation generation
    if (bodySchema.properties) {
      Object.entries(bodySchema.properties).forEach(
        ([propName, propSchema]) => {
          const s = propSchema as SchemaObject;
          result.allParams.push({
            name: propName,
            type: s.type || "unknown",
            required: bodySchema.required?.includes(propName) || false,
            schema: s,
            isBodyParam: true,
          });
        }
      );
    }
  }

  return result;
}

/**
 * Generate Lua validation code from OpenAPI schema
 * @param {string} paramName - Parameter name
 * @param {Object} schema - OpenAPI schema
 * @returns {string} Lua validation code
 */
export function generateLuaValidation(
  paramName: string,
  schema?: SchemaObject
): string {
  if (!schema) return `-- No validation for ${paramName}`;

  const validations: string[] = [];

  switch (schema.type) {
    case "string":
      validations.push(
        `assert(typeof(${paramName}) == "string", "${paramName} must be a string")`
      );
      if (schema.minLength) {
        validations.push(
          `assert(string.len(${paramName}) >= ${schema.minLength}, "${paramName} must be at least ${schema.minLength} characters")`
        );
      }
      if (schema.maxLength) {
        validations.push(
          `assert(string.len(${paramName}) <= ${schema.maxLength}, "${paramName} must be at most ${schema.maxLength} characters")`
        );
      }
      if (schema.pattern) {
        const luaPattern = regexToLuaPattern(schema.pattern);
        validations.push(
          `assert(string.match(${paramName}, "${luaPattern}"), "${paramName} format is invalid")`
        );
      }
      break;

    case "integer":
    case "number":
      validations.push(
        `assert(typeof(${paramName}) == "number", "${paramName} must be a number")`
      );
      validations.push(`validateNumber(${paramName}, "${paramName}")`);
      if (schema.minimum !== undefined) {
        validations.push(
          `assert(${paramName} >= ${schema.minimum}, "${paramName} must be >= ${schema.minimum}")`
        );
      }
      if (schema.maximum !== undefined) {
        validations.push(
          `assert(${paramName} <= ${schema.maximum}, "${paramName} must be <= ${schema.maximum}")`
        );
      }
      if (schema.type === "integer") {
        validations.push(
          `assert(${paramName} == math.floor(${paramName}), "${paramName} must be an integer")`
        );
      }
      break;

    case "boolean":
      validations.push(
        `assert(typeof(${paramName}) == "boolean", "${paramName} must be a boolean")`
      );
      break;

    case "object":
      validations.push(
        `assert(type(${paramName}) == "table", "${paramName} must be a table")`
      );
      break;

    default:
      // Handle enums (TypeBox unions become enums in OpenAPI)
      if (schema.enum && Array.isArray(schema.enum)) {
        const enumValues = schema.enum.map((v) => `"${v}"`).join(", ");
        validations.push(
          `local validValues = {${schema.enum
            .map((v) => `["${v}"]=true`)
            .join(", ")}}`
        );
        validations.push(
          `assert(validValues[${paramName}], "${paramName} must be one of: ${enumValues}")`
        );
      } else {
        validations.push(
          `-- TODO: Add validation for ${paramName} (${
            schema.type || "unknown"
          })`
        );
      }
  }

  return validations.length > 0
    ? validations.join("\n\t")
    : `-- No validation needed for ${paramName}`;
}

/**
 * Escape Lua pattern special characters
 * @param {string} pattern - Regular expression pattern
 * @returns {string} Escaped pattern for Lua
 */
function escapePattern(pattern: string) {
  // Basic conversion from regex to Lua pattern
  // This is a simplified conversion - may need enhancement for complex patterns
  return pattern
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\^/g, "^")
    .replace(/\$/g, "$");
}

/**
 * Convert a JS-style regex (subset) to a Lua pattern (best-effort)
 * Supports \d, \w, \s shorthands and basic anchors.
 */
function regexToLuaPattern(pattern: string) {
  let p = pattern;
  // Remove leading ^ and trailing $ remain as-is (Lua uses same)
  // Translate common escapes
  p = p.replace(/\\d/g, "%d").replace(/\\w/g, "%w").replace(/\\s/g, "%s");
  // Escape any remaining unescaped quotes
  p = p.replace(/"/g, '\\"');
  return p;
}

/**
 * Build URL with path parameter substitution for Lua
 * @param {string} path - OpenAPI path with {param} syntax
 * @param {Array} pathParams - Path parameters
 * @returns {string} Lua string with parameter interpolation
 */
export function buildLuaUrl(
  path: string,
  pathParams: ExtractedParameterInfo[] = []
) {
  if (!pathParams.length || !path.includes("{")) {
    return `"${path}"`;
  }

  let luaUrl = path;

  // Replace each path parameter with Lua string interpolation
  for (const param of pathParams) {
    const placeholder = `{${param.name}}`;
    if (luaUrl.includes(placeholder)) {
      luaUrl = luaUrl.replace(placeholder, `" .. tostring(${param.name}) .. "`);
    }
  }

  // Clean up the string concatenation
  luaUrl = `"${luaUrl}"`
    .replace(/^"" \.\. /, "") // Remove empty string at start
    .replace(/ \.\. ""$/, "") // Remove empty string at end
    .replace(/" \.\. "/g, ""); // Remove unnecessary string breaks

  return luaUrl;
}

/**
 * Capitalize first letter of a string
 * @param {string} str - String to capitalize
 * @returns {string} Capitalized string
 */
function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Extract response schema information from OpenAPI operation
 * @param {Object} operation - OpenAPI operation
 * @returns {Object|null} Response schema info
 */
export function extractResponseSchema(
  operation: OperationObject
): ResponseSchemaInfo | null {
  if (!operation.responses) return null;

  // Look for 200 response first, then any 2xx response
  const successResponse =
    operation.responses["200"] ||
    operation.responses["201"] ||
    Object.values(operation.responses).find((r) => r && typeof r === "object");

  if (!successResponse?.content?.["application/json"]?.schema) return null;

  return {
    schema: successResponse.content["application/json"]!.schema!,
    description: successResponse.description,
  };
}

/* -------------------------------------------------------------------------- */
/*  Small Pure Helpers                                                        */
/* -------------------------------------------------------------------------- */

function deriveModuleName(path: string, operation: OperationObject): string {
  if (operation.tags && operation.tags.length)
    return capitalize(operation.tags[0]);
  const firstSegment = path.split("/").filter(Boolean)[0];
  return firstSegment ? capitalize(firstSegment) : "Default";
}
