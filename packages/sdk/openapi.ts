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

  Object.entries(openApiSpec.paths).forEach(([path, data]) => {
    if (!data) return;

    (["get", "post", "put", "patch", "delete"] as const).forEach((method) => {
      const operation = data[method];
      if (!operation) return;

      const moduleName = deriveModuleName(path, operation);

      groups[moduleName] ||= [];
      groups[moduleName].push({
        path,
        method: method.toUpperCase() as HttpMethod,
        description: operation.description || "",
        operation: {
          ...operation,
          operationId:
            operation.operationId || generateOperationId(method, path),
        },
      });
    });
  });

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
