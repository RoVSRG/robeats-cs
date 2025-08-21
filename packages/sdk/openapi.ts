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

export interface RequestBody {
  required?: boolean;
  content?: {
    "application/json"?: { schema?: SchemaObject };
    [contentType: string]: { schema?: SchemaObject } | undefined;
  };
}

export interface Response {
  description?: string;
  content?: {
    "application/json"?: { schema?: SchemaObject };
    [contentType: string]: { schema?: SchemaObject } | undefined;
  };
}

export interface Operation {
  path: string;
  method: "get" | "post" | "put" | "patch" | "delete" | "options" | "head";
  operationId?: string;
  description?: string;
  tags?: string[];
  parameters?: ParameterObject[];
  requestBody?: RequestBody;
  responses?: Record<string, Response>;
}

export type PathItemObject = Partial<
  Record<
    "get" | "post" | "put" | "patch" | "delete" | "options" | "head",
    Operation
  >
> & { [extension: string]: any };

export interface OpenApiSpec {
  openapi?: string; // v3
  swagger?: string; // v2
  paths?: Record<string, PathItemObject>;
  // Additional fields ignored for now
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
 * Generate operation ID from method and path if not provided
 * @param {string} method - HTTP method
 * @param {string} path - API path
 * @returns {string} Generated operation ID
 */
export function generateOperationId(method: string, path: string): string {
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
 * Capitalize first letter of a string
 * @param {string} str - String to capitalize
 * @returns {string} Capitalized string
 */
function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
