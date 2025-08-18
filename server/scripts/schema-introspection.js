/**
 * Zod Schema Introspection Utilities
 * Extracts information from Zod schemas for SDK generation
 */

import { z } from 'zod';

/**
 * Extract field information from a Zod object schema
 */
export function introspectObjectSchema(schema) {
  if (!schema || !schema.def || schema.def.type !== 'object') {
    return null;
  }

  const fields = {};
  let shape;
  
  try {
    // Try to get the shape - it might be a function or already resolved
    shape = typeof schema.def.shape === 'function' ? schema.def.shape() : schema.def.shape;
  } catch (error) {
    return null;
  }

  if (!shape || typeof shape !== 'object') {
    return null;
  }

  for (const [key, fieldSchema] of Object.entries(shape)) {
    fields[key] = introspectFieldSchema(fieldSchema, key);
  }

  return {
    type: 'object',
    fields,
    required: Object.keys(shape).filter(key => !isOptional(shape[key])),
  };
}

/**
 * Introspect a single field schema
 */
function introspectFieldSchema(schema, fieldName = 'field') {
  if (!schema || !schema.def) {
    return { type: 'unknown', fieldName, zodType: 'no-def' };
  }
  
  const def = schema.def;
  const typeName = def.typeName || def.type;
  
  switch (typeName) {
    case 'ZodString':
      return introspectStringSchema(schema, fieldName);
    case 'ZodNumber':
      return introspectNumberSchema(schema, fieldName);
    case 'ZodEnum':
      return introspectEnumSchema(schema, fieldName);
    case 'ZodBoolean':
      return { type: 'boolean', fieldName };
    case 'ZodArray':
      return {
        type: 'array',
        fieldName,
        elementType: introspectFieldSchema(def.type, `${fieldName}[]`),
      };
    case 'ZodObject':
      return {
        type: 'object',
        fieldName,
        fields: introspectObjectSchema(schema)?.fields || {},
      };
    case 'ZodOptional':
      return {
        ...introspectFieldSchema(def.innerType, fieldName),
        optional: true,
      };
    case 'ZodNullable':
      return {
        ...introspectFieldSchema(def.innerType, fieldName),
        nullable: true,
      };
    case 'ZodEffects':
    case 'ZodTransform':
      // Handle transforms (like string().transform(parseInt))
      const baseSchema = def.schema || def.in;
      if (baseSchema) {
        const baseType = introspectFieldSchema(baseSchema, fieldName);
        return {
          ...baseType,
          transform: true,
          transformInfo: 'Custom transform applied',
        };
      }
      return { type: 'unknown', fieldName, zodType: typeName };
    case 'ZodPipe':
      // Handle piped schemas (new Zod v4)
      const inSchema = def.in || schema.in;
      if (inSchema) {
        return introspectFieldSchema(inSchema, fieldName);
      }
      return { type: 'unknown', fieldName, zodType: typeName };
    default:
      // Try to infer from constructor name or properties
      if (schema.constructor.name === 'ZodString') {
        return { type: 'string', fieldName };
      }
      if (schema.constructor.name === 'ZodNumber') {
        return { type: 'number', fieldName };
      }
      if (schema.constructor.name === 'ZodBoolean') {
        return { type: 'boolean', fieldName };
      }
      
      return { type: 'unknown', fieldName, zodType: typeName };
  }
}

/**
 * Introspect string schema constraints
 */
function introspectStringSchema(schema, fieldName) {
  const def = schema._def;
  const constraints = {};
  
  if (def.checks) {
    for (const check of def.checks) {
      switch (check.kind) {
        case 'min':
          constraints.minLength = check.value;
          break;
        case 'max':
          constraints.maxLength = check.value;
          break;
        case 'regex':
          constraints.pattern = check.regex.source;
          break;
        case 'email':
          constraints.format = 'email';
          break;
        case 'url':
          constraints.format = 'url';
          break;
      }
    }
  }

  return {
    type: 'string',
    fieldName,
    constraints,
  };
}

/**
 * Introspect number schema constraints
 */
function introspectNumberSchema(schema, fieldName) {
  const def = schema._def;
  const constraints = {};
  
  if (def.checks) {
    for (const check of def.checks) {
      switch (check.kind) {
        case 'min':
          constraints.min = check.value;
          constraints.minInclusive = check.inclusive !== false;
          break;
        case 'max':
          constraints.max = check.value;
          constraints.maxInclusive = check.inclusive !== false;
          break;
        case 'int':
          constraints.integer = true;
          break;
        case 'multipleOf':
          constraints.multipleOf = check.value;
          break;
      }
    }
  }

  return {
    type: 'number',
    fieldName,
    constraints,
  };
}

/**
 * Introspect enum schema values
 */
function introspectEnumSchema(schema, fieldName) {
  const def = schema._def;
  
  return {
    type: 'enum',
    fieldName,
    values: def.values || [],
  };
}

/**
 * Check if a schema is optional
 */
function isOptional(schema) {
  return schema._def.typeName === 'ZodOptional' || schema.isOptional?.() === true;
}

/**
 * Generate Lua validation code for a field
 */
export function generateLuaValidation(fieldInfo) {
  const { type, fieldName, constraints = {}, optional, nullable } = fieldInfo;
  
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
      if (constraints.minLength) {
        validation += `\tassert(string.len(value) >= ${constraints.minLength}, name .. " must be at least ${constraints.minLength} characters")\n`;
      }
      if (constraints.maxLength) {
        validation += `\tassert(string.len(value) <= ${constraints.maxLength}, name .. " must be at most ${constraints.maxLength} characters")\n`;
      }
      if (constraints.pattern) {
        // Convert JS regex to Lua pattern (basic conversion)
        const luaPattern = constraints.pattern.replace(/\^|\$/g, '');
        validation += `\tassert(string.match(value, "${luaPattern}"), name .. " format is invalid")\n`;
      }
      break;
      
    case 'number':
      validation += `\tassert(type(value) == "number", name .. " must be a number")\n`;
      if (constraints.min !== undefined) {
        const op = constraints.minInclusive !== false ? '>=' : '>';
        validation += `\tassert(value ${op} ${constraints.min}, name .. " must be ${op} ${constraints.min}")\n`;
      }
      if (constraints.max !== undefined) {
        const op = constraints.maxInclusive !== false ? '<=' : '<';
        validation += `\tassert(value ${op} ${constraints.max}, name .. " must be ${op} ${constraints.max}")\n`;
      }
      if (constraints.integer) {
        validation += `\tassert(value == math.floor(value), name .. " must be an integer")\n`;
      }
      break;
      
    case 'boolean':
      validation += `\tassert(type(value) == "boolean", name .. " must be a boolean")\n`;
      break;
      
    case 'enum':
      validation += `\tlocal validValues = {${fieldInfo.values.map(v => `${v}=true`).join(', ')}}\n`;
      validation += `\tassert(validValues[value], name .. " must be one of: ${fieldInfo.values.join(', ')}")\n`;
      break;
      
    case 'array':
      validation += `\tassert(type(value) == "table", name .. " must be an array")\n`;
      validation += `\tfor i, item in ipairs(value) do\n`;
      // Recursively validate array elements (simplified for now)
      validation += `\t\t-- TODO: Add element validation\n`;
      validation += `\tend\n`;
      break;
      
    default:
      validation += `\t-- Unknown type: ${type}\n`;
  }
  
  validation += `\treturn value\nend\n\n`;
  
  return validation;
}

/**
 * Capitalize first letter of a string
 */
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
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