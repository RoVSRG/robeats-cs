import fs from "fs";
import path from "path";
import Handlebars from "handlebars";

Handlebars.registerHelper("capitalize", function (str: string) {
  if (typeof str !== "string") return "";
  return str.charAt(0).toUpperCase() + str.slice(1);
});

const OUTPUT_DIR = path.resolve("..", "game", "shared", "_sdk_bin");

import {
  fetchOpenApiSpec,
  generateOperationId,
  OpenApiSpec,
  OperationObject,
  SchemaObject,
} from "./openapi";

const templatesDir = path.resolve(".", "templates");
const templates: Record<string, Handlebars.TemplateDelegate> = {};
fs.readdirSync(templatesDir).forEach((file) => {
  if (!file.endsWith(".hbs")) return;
  const filePath = path.join(templatesDir, file);
  const templateContent = fs.readFileSync(filePath, "utf-8");
  templates[file] = Handlebars.compile(templateContent, { noEscape: true });
});

/* -------------------------------------------------------------------------- */
/*  Handlebars Helpers                                                        */
/* -------------------------------------------------------------------------- */

Handlebars.registerHelper("json", (ctx) => JSON.stringify(ctx, null, 2));
Handlebars.registerHelper("eq", function (a, b) {
  return a === b;
});
Handlebars.registerHelper("keys", function (obj) {
  return Object.keys(obj || {});
});
Handlebars.registerHelper("brace", function (name: string) {
  return `{${name}}`;
});

function getLuaTypeString(schema: SchemaObject | undefined): string {
  if (!schema) return "any";
  const { type, enum: en, items } = schema;
  if (en && en.length) {
    // Represent enums as string union comment
    const union = en
      .map((v) => (typeof v === "string" ? `"${v}"` : v))
      .join(" | ");
    return `string -- enum: ${union}`;
  }
  switch (type) {
    case "integer":
    case "number":
      return "number";
    case "string":
      return "string";
    case "boolean":
      return "boolean";
    case "array":
      return `{ ${getLuaTypeString(items)} }`;
    case "object":
      return "{ [string]: any }"; // refine later
    default:
      return "any";
  }
}

interface ExtendedOperation extends OperationObject {
  path: string;
  method: OperationObject["method"];
  _luaDoc?: {
    queryParams: { name: string; type: string; required: boolean }[];
    pathParams: { name: string; type: string; required: boolean }[];
  };
  _responseTypeDecl?: string;
  _configTypeDecl?: string;
  _configTypeName?: string;
  _configParams?: {
    name: string;
    luaType: string;
    required: boolean;
    from: string;
  }[];
  _omitConfig?: boolean;
  _responseTypeName?: string; // alias actually used in signature
  _bodyValidation?: string; // lua code snippet for body validation
}

function getLuaFunction(
  tag: string,
  id: string,
  operation: ExtendedOperation
): string {
  const t = templates["function.hbs"];
  return t({ tag, id, operation });
}

function aggregateByTag(spec: OpenApiSpec) {
  const paths = spec.paths || {};
  const aggregated: Record<string, ExtendedOperation[]> = {};
  for (const [p, methods] of Object.entries(paths)) {
    for (const [method, op] of Object.entries(methods)) {
      if (!op) continue;
      const tags = op.tags && op.tags.length ? op.tags : ["Default"];
      for (const rawTag of tags) {
        const tag = sanitizeTag(rawTag);
        (aggregated[tag] ||= []).push({
          ...(op as OperationObject),
          path: p,
          method: method as any,
        });
      }
    }
  }
  return aggregated;
}

function sanitizeTag(tag: string) {
  return tag.replace(/[^A-Za-z0-9_]/g, "");
}

function ensureOutputDir() {
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function writeModule(tag: string, body: string) {
  fs.writeFileSync(path.join(OUTPUT_DIR, `${tag}.lua`), body, "utf8");
}

function buildInitLua(tags: string[]) {
  const lines: string[] = [];
  lines.push("-- Auto-generated SDK index");
  lines.push("local SDK = { }");
  for (const t of tags.sort()) {
    lines.push(`SDK.${t} = require(script.${t})`);
  }
  lines.push("return SDK");
  fs.writeFileSync(path.join(OUTPUT_DIR, "init.lua"), lines.join("\n"), "utf8");
}

async function main() {
  const spec = await fetchOpenApiSpec();
  ensureOutputDir();
  const aggregated = aggregateByTag(spec);
  const producedTags: string[] = [];

  for (const [tag, operations] of Object.entries(aggregated)) {
    producedTags.push(tag);
    console.log(`Processing ${operations.length} operations for tag: ${tag}`);
    const fnChunks: string[] = [];
    for (const operation of operations) {
      const opId = generateOperationId(operation.method, operation.path);
      operation.operationId = opId;
      // Attach param meta for docs (not used by template yet except listing)
      const params = operation.parameters || [];
      (operation as any)._luaDoc = {
        queryParams: params
          .filter((p: any) => p.in === "query")
          .map((p: any) => ({
            name: p.name,
            type: getLuaTypeString(p.schema),
            required: !!p.required,
          })),
        pathParams: params
          .filter((p: any) => p.in === "path")
          .map((p: any) => ({
            name: p.name,
            type: getLuaTypeString(p.schema),
            required: !!p.required,
          })),
      };
      // Response type (200) if present
      try {
        const successResp = operation.responses?.["200"] as any;
        const successSchema: SchemaObject | undefined =
          successResp?.content?.["application/json"].schema;
        if (successSchema) {
          const responseAlias = pascalCase(opId) + "Response";
          const { decl, reusedName } = buildOrReuseType(
            responseAlias,
            successSchema
          );
          (operation as any)._responseTypeName = reusedName || responseAlias;
          if (decl) {
            (operation as any)._responseTypeDecl = decl;
          }
        } else {
          (operation as any)._responseTypeName = pascalCase(opId) + "Response";
        }
      } catch {}
      // Build config type from params + body
      const configParams: {
        name: string;
        luaType: string;
        required: boolean;
        from: string;
      }[] = [];
      (operation.parameters || []).forEach((p) => {
        configParams.push({
          name: p.name,
          luaType: getLuaTypeString(p.schema),
          required: !!p.required,
          from: p.in,
        });
      });
      const bodySchema = (operation.requestBody as any)?.content?.[
        "application/json"
      ]?.schema as SchemaObject | undefined;
      if (bodySchema) {
        configParams.push({
          name: "body",
          luaType: getLuaTypeString(bodySchema),
          required: !!(operation.requestBody as any)?.required,
          from: "body",
        });
        (operation as any)._bodyValidation = buildBodyValidation(
          bodySchema,
          !!(operation.requestBody as any)?.required
        );
      }
      if (configParams.length === 0) {
        (operation as any)._omitConfig = true;
      } else {
        const configTypeName = pascalCase(opId) + "Config";
        (operation as any)._configTypeName = configTypeName;
        (operation as any)._configParams = configParams;
        const fields = configParams
          .map(
            (cp) => `  ${cp.name}: ${cp.luaType}${cp.required ? "" : " | nil"},`
          )
          .join("\n");
        (
          operation as any
        )._configTypeDecl = `type ${configTypeName} = {\n${fields}\n}`;
      }
      fnChunks.push(getLuaFunction(tag, opId, operation));
    }
    const moduleContent = templates["route.hbs"]({
      tag,
      routes: fnChunks.join("\n\n"),
    });
    writeModule(tag, moduleContent);
  }

  buildInitLua(producedTags);
  console.log(`✅ Generated SDK modules: ${producedTags.join(", ")}`);
}

main();

/* -------------------------------------------------------------------------- */
/*  Lua Type Generation from JSON Schema (subset)                             */
/* -------------------------------------------------------------------------- */
function buildLuaTypeDecl(name: string, schema: SchemaObject): string {
  function capitalizeLocal(str: string) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
  const visited = new WeakSet();
  function walk(s: SchemaObject | undefined): string {
    if (!s) return "any";
    if (visited.has(s)) return "any";
    if (s.enum) return "string"; // treat enums as string for now
    switch (s.type) {
      case "string":
        return "string";
      case "integer":
      case "number":
        return "number";
      case "boolean":
        return "boolean";
      case "array":
        return `{ ${walk(s.items)} }`;
      case "object": {
        visited.add(s);
        const props = s.properties || {};
        const required = new Set(s.required || []);
        const lines: string[] = ["{"];
        for (const [propName, propSchema] of Object.entries(props)) {
          const safeKey = /^[A-Za-z_][A-Za-z0-9_]*$/.test(propName)
            ? propName
            : `['${propName}']`;
          const luaType = walk(propSchema);
          const optional = required.has(propName)
            ? luaType
            : `${luaType} | nil`;
          lines.push(`  ${safeKey}: ${optional},`);
        }
        lines.push("}");
        return lines.join("\n");
      }
      default:
        return "any";
    }
  }
  return `type ${capitalizeLocal(name)} = ${walk(schema)}`;
}

/* -------------------------------------------------------------------------- */
/*  Type Registry & Helpers for Reuse                                        */
/* -------------------------------------------------------------------------- */
const typeRegistry = new Map<string, string>(); // shapeKey -> alias

function pascalCase(str: string) {
  return str.replace(/(^|[^A-Za-z0-9]+)([A-Za-z0-9])/g, (_, __, c) =>
    c.toUpperCase()
  );
}

function buildOrReuseType(
  alias: string,
  schema: SchemaObject
): { decl: string | null; reusedName?: string } {
  const shapeKey = computeShapeKey(schema);
  const existing = typeRegistry.get(shapeKey);
  if (existing) {
    return { decl: null, reusedName: existing };
  }
  typeRegistry.set(shapeKey, alias);
  const decl = buildLuaTypeDecl(alias, schema);
  return { decl };
}

function computeShapeKey(schema: SchemaObject): string {
  // Simplistic shape hashing (non recursive detail limited to types/properties)
  const obj: any = {};
  obj.type = schema.type;
  if (schema.properties) {
    obj.properties = Object.keys(schema.properties)
      .sort()
      .map((k) => ({ k, t: schema.properties![k].type }));
  }
  if (schema.items) obj.items = computeShapeKey(schema.items);
  return JSON.stringify(obj);
}

/* -------------------------------------------------------------------------- */
/*  Body Validation Generation (shallow)                                      */
/* -------------------------------------------------------------------------- */
function buildBodyValidation(
  schema: SchemaObject,
  requiredBody: boolean
): string {
  if (schema.type !== "object" || !schema.properties) return "";
  const lines: string[] = [];
  const required = new Set(schema.required || []);
  for (const [prop, propSchema] of Object.entries(schema.properties)) {
    const accessor = `body.${prop}`;
    if (required.has(prop)) {
      lines.push(
        `if ${accessor} == nil then error("Missing body field: ${prop}", 2) end`
      );
    }
    if (propSchema.type === "string") {
      lines.push(
        `if ${accessor} ~= nil then assertString(${accessor}, "${prop}") end`
      );
      if ((propSchema as any).minLength != null) {
        lines.push(
          `if ${accessor} ~= nil and #${accessor} < ${
            (propSchema as any).minLength
          } then error("${prop} length < ${
            (propSchema as any).minLength
          }", 2) end`
        );
      }
      if ((propSchema as any).maxLength != null) {
        lines.push(
          `if ${accessor} ~= nil and #${accessor} > ${
            (propSchema as any).maxLength
          } then error("${prop} length > ${
            (propSchema as any).maxLength
          }", 2) end`
        );
      }
      if ((propSchema as any).pattern) {
        lines.push(
          `if ${accessor} ~= nil and not string.match(${accessor}, "${
            (propSchema as any).pattern
          }") then error("${prop} pattern mismatch", 2) end`
        );
      }
    } else if (propSchema.type === "integer" || propSchema.type === "number") {
      lines.push(
        `if ${accessor} ~= nil then assertNumber(${accessor}, "${prop}") end`
      );
      if ((propSchema as any).minimum != null) {
        lines.push(
          `if ${accessor} ~= nil and ${accessor} < ${
            (propSchema as any).minimum
          } then error("${prop} < ${(propSchema as any).minimum}", 2) end`
        );
      }
      if ((propSchema as any).maximum != null) {
        lines.push(
          `if ${accessor} ~= nil and ${accessor} > ${
            (propSchema as any).maximum
          } then error("${prop} > ${(propSchema as any).maximum}", 2) end`
        );
      }
    } else if (propSchema.type === "boolean") {
      lines.push(
        `if ${accessor} ~= nil then assertBoolean(${accessor}, "${prop}") end`
      );
    }
  }
  return lines.join("\n");
}
