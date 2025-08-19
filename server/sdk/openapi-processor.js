/**
 * OpenAPI Specification Processing Utilities
 * Handles fetching and processing OpenAPI specs for SDK generation
 */

/**
 * Fetch OpenAPI specification from a running server
 * @param {string} serverUrl - Base URL of the server (e.g., 'http://localhost:3000')
 * @returns {Promise<Object>} OpenAPI specification object
 */
export async function fetchOpenApiSpec(serverUrl = 'http://localhost:3000') {
  const swaggerUrl = `${serverUrl}/documentation/json`;
  
  try {
    console.log(`🌐 Fetching OpenAPI spec from: ${swaggerUrl}`);
    
    const response = await fetch(swaggerUrl);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const spec = await response.json();
    
    if (!spec.openapi && !spec.swagger) {
      throw new Error('Invalid OpenAPI specification: missing openapi/swagger field');
    }
    
    console.log(`✅ Successfully fetched OpenAPI ${spec.openapi || spec.swagger} specification`);
    console.log(`📋 Found ${Object.keys(spec.paths || {}).length} paths`);
    
    return spec;
  } catch (error) {
    if (error.code === 'ECONNREFUSED' || error.cause?.code === 'ECONNREFUSED') {
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
export function groupEndpointsByTags(openApiSpec) {
  const groups = {};
  
  if (!openApiSpec.paths) {
    console.warn('⚠️  No paths found in OpenAPI specification');
    return groups;
  }
  
  for (const [path, pathItem] of Object.entries(openApiSpec.paths)) {
    if (!pathItem || typeof pathItem !== 'object') continue;
    
    // Process each HTTP method for this path
    for (const [method, operation] of Object.entries(pathItem)) {
      if (!operation || typeof operation !== 'object') continue;
      if (!['get', 'post', 'put', 'patch', 'delete'].includes(method.toLowerCase())) continue;
      
      // Use the first tag as the module name, or derive from path
      let moduleName;
      if (operation.tags && operation.tags.length > 0) {
        moduleName = capitalize(operation.tags[0]);
      } else {
        // Derive module name from path (e.g., /players/join -> Players)
        const pathSegments = path.split('/').filter(Boolean);
        moduleName = pathSegments.length > 0 ? capitalize(pathSegments[0]) : 'Default';
      }
      
      if (!groups[moduleName]) {
        groups[moduleName] = [];
      }
      
      groups[moduleName].push({
        path,
        method: method.toUpperCase(),
        operation: {
          ...operation,
          operationId: operation.operationId || generateOperationId(method, path),
        }
      });
    }
  }
  
  console.log(`📂 Grouped endpoints into modules:`, Object.keys(groups).join(', '));
  return groups;
}

/**
 * Generate operation ID from method and path if not provided
 * @param {string} method - HTTP method
 * @param {string} path - API path
 * @returns {string} Generated operation ID
 */
function generateOperationId(method, path) {
  // Convert /players/join -> playersJoin, /scores/{id} -> scoresById
  const cleanPath = path
    .split('/')
    .filter(Boolean)
    .map(segment => {
      // Replace path parameters with 'By' + parameter name
      if (segment.startsWith('{') && segment.endsWith('}')) {
        const paramName = segment.slice(1, -1);
        return 'By' + capitalize(paramName);
      }
      return segment;
    })
    .map((segment, index) => index === 0 ? segment : capitalize(segment))
    .join('');
    
  return method.toLowerCase() + capitalize(cleanPath);
}

/**
 * Extract parameters from OpenAPI operation
 * @param {Object} operation - OpenAPI operation object
 * @returns {Object} Categorized parameters
 */
export function extractParameters(operation) {
  const result = {
    path: [],
    query: [],
    body: null,
    allParams: []
  };
  
  // Extract path and query parameters
  if (operation.parameters) {
    for (const param of operation.parameters) {
      const paramInfo = {
        name: param.name,
        type: param.schema?.type || 'string',
        required: param.required || false,
        description: param.description,
        schema: param.schema
      };
      
      if (param.in === 'path') {
        result.path.push(paramInfo);
        result.allParams.push(paramInfo);
      } else if (param.in === 'query') {
        result.query.push(paramInfo);
        result.allParams.push(paramInfo);
      }
    }
  }
  
  // Extract request body parameters
  if (operation.requestBody?.content?.['application/json']?.schema) {
    const bodySchema = operation.requestBody.content['application/json'].schema;
    result.body = {
      schema: bodySchema,
      required: operation.requestBody.required || false
    };
    
    // If body has properties, add them to allParams for validation generation
    if (bodySchema.properties) {
      for (const [propName, propSchema] of Object.entries(bodySchema.properties)) {
        result.allParams.push({
          name: propName,
          type: propSchema.type || 'unknown',
          required: bodySchema.required?.includes(propName) || false,
          schema: propSchema,
          isBodyParam: true
        });
      }
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
export function generateLuaValidation(paramName, schema) {
  if (!schema) return `-- No validation for ${paramName}`;
  
  const validations = [];
  
  switch (schema.type) {
    case 'string':
      validations.push(`validateString(${paramName}, "${paramName}")`);
      if (schema.minLength) {
        validations.push(`assert(string.len(${paramName}) >= ${schema.minLength}, "${paramName} must be at least ${schema.minLength} characters")`);
      }
      if (schema.maxLength) {
        validations.push(`assert(string.len(${paramName}) <= ${schema.maxLength}, "${paramName} must be at most ${schema.maxLength} characters")`);
      }
      if (schema.pattern) {
        validations.push(`assert(string.match(${paramName}, "${escapePattern(schema.pattern)}"), "${paramName} format is invalid")`);
      }
      break;
      
    case 'integer':
    case 'number':
      validations.push(`validateNumber(${paramName}, "${paramName}")`);
      if (schema.minimum !== undefined) {
        validations.push(`assert(${paramName} >= ${schema.minimum}, "${paramName} must be >= ${schema.minimum}")`);
      }
      if (schema.maximum !== undefined) {
        validations.push(`assert(${paramName} <= ${schema.maximum}, "${paramName} must be <= ${schema.maximum}")`);
      }
      if (schema.type === 'integer') {
        validations.push(`assert(${paramName} == math.floor(${paramName}), "${paramName} must be an integer")`);
      }
      break;
      
    case 'boolean':
      validations.push(`validateBoolean(${paramName}, "${paramName}")`);
      break;
      
    case 'object':
      validations.push(`assert(type(${paramName}) == "table", "${paramName} must be a table")`);
      break;
      
    default:
      // Handle enums (TypeBox unions become enums in OpenAPI)
      if (schema.enum && Array.isArray(schema.enum)) {
        const enumValues = schema.enum.map(v => `"${v}"`).join(', ');
        validations.push(`local validValues = {${schema.enum.map(v => `["${v}"]=true`).join(', ')}}`);
        validations.push(`assert(validValues[${paramName}], "${paramName} must be one of: ${enumValues}")`);
      } else {
        validations.push(`-- TODO: Add validation for ${paramName} (${schema.type || 'unknown'})`);
      }
  }
  
  return validations.length > 0 ? validations.join('\n\t') : `-- No validation needed for ${paramName}`;
}

/**
 * Escape Lua pattern special characters
 * @param {string} pattern - Regular expression pattern
 * @returns {string} Escaped pattern for Lua
 */
function escapePattern(pattern) {
  // Basic conversion from regex to Lua pattern
  // This is a simplified conversion - may need enhancement for complex patterns
  return pattern
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\^/g, '^')
    .replace(/\$/g, '$');
}

/**
 * Build URL with path parameter substitution for Lua
 * @param {string} path - OpenAPI path with {param} syntax
 * @param {Array} pathParams - Path parameters
 * @returns {string} Lua string with parameter interpolation
 */
export function buildLuaUrl(path, pathParams = []) {
  if (!pathParams.length || !path.includes('{')) {
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
    .replace(/^"" \.\. /, '')  // Remove empty string at start
    .replace(/ \.\. ""$/, '')  // Remove empty string at end
    .replace(/" \.\. "/g, ''); // Remove unnecessary string breaks
  
  return luaUrl;
}

/**
 * Capitalize first letter of a string
 * @param {string} str - String to capitalize
 * @returns {string} Capitalized string
 */
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Extract response schema information from OpenAPI operation
 * @param {Object} operation - OpenAPI operation
 * @returns {Object|null} Response schema info
 */
export function extractResponseSchema(operation) {
  if (!operation.responses) return null;
  
  // Look for 200 response first, then any 2xx response
  const successResponse = operation.responses['200'] || 
                         operation.responses['201'] || 
                         Object.values(operation.responses).find(r => r && typeof r === 'object');
  
  if (!successResponse?.content?.['application/json']?.schema) return null;
  
  return {
    schema: successResponse.content['application/json'].schema,
    description: successResponse.description
  };
}