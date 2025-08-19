/**
 * OpenAPI Schema Introspection Utilities
 * Extracts information from OpenAPI schemas for SDK generation
 */

/**
 * Extract field information from OpenAPI schema
 */
export function introspectOpenApiSchema(schema) {
  if (!schema || typeof schema !== 'object') {
    return null;
  }

  const result = {
    type: schema.type || 'unknown',
    required: schema.required || [],
    fields: {}
  };

  if (schema.properties) {
    for (const [key, fieldSchema] of Object.entries(schema.properties)) {
      result.fields[key] = introspectFieldSchema(fieldSchema, key);
    }
  }

  return result;
}

/**
 * Introspect a single field schema
 */
function introspectFieldSchema(schema, fieldName = 'field') {
  if (!schema || typeof schema !== 'object') {
    return { type: 'unknown', fieldName };
  }

  const fieldInfo = {
    type: schema.type || 'unknown',
    fieldName,
    optional: !schema.required,
    nullable: schema.nullable || false,
  };

  // Handle constraints
  if (schema.minimum !== undefined) fieldInfo.min = schema.minimum;
  if (schema.maximum !== undefined) fieldInfo.max = schema.maximum;
  if (schema.minLength !== undefined) fieldInfo.minLength = schema.minLength;
  if (schema.maxLength !== undefined) fieldInfo.maxLength = schema.maxLength;
  if (schema.pattern) fieldInfo.pattern = schema.pattern;
  if (schema.enum) fieldInfo.values = schema.enum;

  // Handle arrays
  if (schema.type === 'array' && schema.items) {
    fieldInfo.elementType = introspectFieldSchema(schema.items, `${fieldName}[]`);
  }

  // Handle objects
  if (schema.type === 'object' && schema.properties) {
    fieldInfo.fields = {};
    for (const [key, prop] of Object.entries(schema.properties)) {
      fieldInfo.fields[key] = introspectFieldSchema(prop, key);
    }
  }

  return fieldInfo;
}

/**
 * Generate Lua validation code for a field
 */
export function generateLuaValidation(fieldInfo) {
  const { type, fieldName, optional, nullable } = fieldInfo;

  let validation = '';

  // Handle optional/nullable
  if (optional || nullable) {
    validation += `local function validate${capitalize(fieldName)}(value, name)\n`;
    validation += `\tif value == nil then\n\t\treturn nil\n\tend\n`;
  } else {
    validation += `local function validate${capitalize(fieldName)}(value, name)\n`;
  }

  switch (type) {
    case 'string':
      validation += `\tassert(type(value) == "string", name .. " must be a string")\n`;
      if (fieldInfo.minLength) {
        validation += `\tassert(string.len(value) >= ${fieldInfo.minLength}, name .. " must be at least ${fieldInfo.minLength} characters")\n`;
      }
      if (fieldInfo.maxLength) {
        validation += `\tassert(string.len(value) <= ${fieldInfo.maxLength}, name .. " must be at most ${fieldInfo.maxLength} characters")\n`;
      }
      break;

    case 'number':
    case 'integer':
      validation += `\tassert(type(value) == "number", name .. " must be a number")\n`;
      if (fieldInfo.min !== undefined) {
        validation += `\tassert(value >= ${fieldInfo.min}, name .. " must be >= ${fieldInfo.min}")\n`;
      }
      if (fieldInfo.max !== undefined) {
        validation += `\tassert(value <= ${fieldInfo.max}, name .. " must be <= ${fieldInfo.max}")\n`;
      }
      if (type === 'integer') {
        validation += `\tassert(value == math.floor(value), name .. " must be an integer")\n`;
      }
      break;

    case 'boolean':
      validation += `\tassert(type(value) == "boolean", name .. " must be a boolean")\n`;
      break;

    case 'array':
      validation += `\tassert(type(value) == "table", name .. " must be an array")\n`;
      break;

    default:
      validation += `\t-- Unknown type: ${type}\n`;
  }

  validation += `\treturn value\nend\n\n`;

  return validation;
}

/**
 * Convert endpoint path with params to Lua string interpolation
 * e.g., "/scores/{playerId}/{songKey}" -> "/scores/" .. playerId .. "/" .. songKey
 */
export function convertEndpointPath(endpoint, pathParams) {
  if (!pathParams || Object.keys(pathParams).length === 0) {
    return `"${endpoint}"`;
  }

  let luaPath = endpoint;
  for (const param of Object.keys(pathParams)) {
    luaPath = luaPath.replace(`{${param}}`, `" .. tostring(${param}) .. "`);
  }

  // Clean up the string concatenation
  luaPath = `"${luaPath}"`;
  luaPath = luaPath.replace(/^"" .. /, '').replace(/ .. ""$/, '');

  return luaPath;
}

/**
 * Capitalize first letter of a string
 */
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}