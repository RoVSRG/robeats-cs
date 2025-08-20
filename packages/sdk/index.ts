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
  _configParams?: { name: string; luaType: string; required: boolean; from: string }[];
  _omitConfig?: boolean;
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
          const typeDecl = buildLuaTypeDecl(`${opId}Response`, successSchema);
          (operation as any)._responseTypeDecl = typeDecl;
        }
      } catch (e) {
        // ignore
      }
      // Build config type from params + body
      const configParams: { name: string; luaType: string; required: boolean; from: string }[] = [];
      (operation.parameters || []).forEach((p) => {
        configParams.push({
          name: p.name,
          luaType: getLuaTypeString(p.schema),
          required: !!p.required,
          from: p.in,
        });
      });
      const bodySchema = (operation.requestBody as any)?.content?.["application/json"]?.schema as SchemaObject | undefined;
      if (bodySchema) {
        configParams.push({
          name: "body",
          luaType: getLuaTypeString(bodySchema),
          required: !!(operation.requestBody as any)?.required,
          from: "body",
        });
      }
      if (configParams.length === 0) {
        (operation as any)._omitConfig = true;
      } else {
        const configTypeName = `${opId}Config`;
        (operation as any)._configTypeName = configTypeName;
        (operation as any)._configParams = configParams;
        const fields = configParams
          .map((cp) => `  ${cp.name}: ${cp.luaType}${cp.required ? "" : "?"},`)
          .join("\n");
        (operation as any)._configTypeDecl = `type ${configTypeName} = {\n${fields}\n}`;
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
          const optional = required.has(propName) ? luaType : `${luaType}?`;
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
