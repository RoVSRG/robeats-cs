#!/usr/bin/env node
/**
 * SDK Code Generation Script
 * Fetches the running server's OpenAPI spec and emits Lua modules grouped by tag.
 */
import {
  fetchOpenApiSpec,
  groupEndpointsByTags,
  extractParameters,
  extractResponseSchema,
  SchemaObject,
  GroupedEndpoint,
  EndpointGroups,
} from "./openapi.js";
import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";

interface GenerateOptions {
  serverUrl: string;
  outDir: string;
}

async function main() {
  const opts: GenerateOptions = {
    serverUrl: process.env.SDK_SERVER_URL || "http://localhost:3000",
    outDir: process.env.SDK_OUT_DIR || "../game/shared/_sdk_bin",
  };

  const spec = await fetchOpenApiSpec(opts.serverUrl);
  const groups = groupEndpointsByTags(spec);

  ensureDir(opts.outDir);
  // index module
  writeFileSync(
    join(opts.outDir, "init.lua"),
    buildIndexModule(groups),
    "utf8"
  );
  // per-tag modules
  Object.entries(groups).forEach(([moduleName, endpoints]) => {
    writeFileSync(
      join(opts.outDir, `${moduleName}.lua`),
      buildLuaModule(moduleName, endpoints),
      "utf8"
    );
  });
  console.log(
    `✨ Generated ${Object.keys(groups).length} Lua modules in ${opts.outDir}`
  );
}

function ensureDir(path: string) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true });
}

main().catch((e) => {
  console.error("Generation failed:", e);
  process.exit(1);
});

/* -------------------------------------------------------------------------- */
/*  Code Generation Helpers                                                   */
/* -------------------------------------------------------------------------- */

// Basic sanitization for Lua identifiers
function ident(name: string) {
  return name.replace(/[^A-Za-z0-9_]/g, "_");
}

// Convert JSON schema types to Luau primitive type strings
function schemaToLuauType(schema: SchemaObject, nameHint = "Anon"): string {
  if (!schema) return "any"; // fallback

  // anyOf (union)
  const anyOf: SchemaObject[] | undefined = (schema as any).anyOf;
  if (anyOf && anyOf.length) {
    return anyOf.map((s, i) => schemaToLuauType(s, nameHint + i)).join(" | ");
  }

  if (schema.enum) {
    // literal union (string|number enumerations)
    return schema.enum
      .map((v) =>
        typeof v === "string" ? JSON.stringify(v) : (v as number).toString()
      )
      .join(" | ");
  }

  switch (schema.type) {
    case "string":
      return "string";
    case "integer":
    case "number":
      return "number";
    case "boolean":
      return "boolean";
    case "array":
      if (schema.items)
        return `{ ${schemaToLuauType(schema.items, nameHint + "Item")} }`;
      return "{ any }";
    case "object":
      if (schema.properties) {
        return `{
${Object.entries(schema.properties)
  .map(
    ([k, v]) =>
      `  ${ident(k)}: ${schemaToLuauType(v, ident(k))}${
        isRequired(schema, k) ? "" : "?"
      }`
  )
  .join(";\n")}
}`;
      }
      return "{ [string]: any }";
    default:
      return "any";
  }
}

function isRequired(schema: SchemaObject, key: string) {
  return !!schema.required?.includes(key);
}

// Build a T validator expression string from schema
function schemaToT(schema: SchemaObject, depth = 0): string {
  if (!schema) return "t.any";
  const anyOf: SchemaObject[] | undefined = (schema as any).anyOf;
  if (anyOf && anyOf.length) {
    return `t.union(${anyOf.map((s) => schemaToT(s, depth + 1)).join(", ")})`;
  }
  if (schema.enum) {
    const lits = schema.enum
      .map((v) => (typeof v === "string" ? JSON.stringify(v) : v))
      .join(", ");
    return `t.literal(${lits})`;
  }
  switch (schema.type) {
    case "string":
      // pattern / length checks: we'll wrap custom checker
      if (
        schema.pattern ||
        schema.minLength != null ||
        schema.maxLength != null
      ) {
        const parts: string[] = ["t.string"]; // base check executed first
        if (schema.minLength != null) {
          parts.push(
            `function(v) if #v < ${schema.minLength} then return false, \"minLength ${schema.minLength}\" end; return true end`
          );
        }
        if (schema.maxLength != null) {
          parts.push(
            `function(v) if #v > ${schema.maxLength} then return false, \"maxLength ${schema.maxLength}\" end; return true end`
          );
        }
        if (schema.pattern) {
          const luaPattern = schema.pattern.replace(/%/g, "%%");
          parts.push(
            `function(v) if not string.match(v, ${JSON.stringify(
              luaPattern
            )}) then return false, \"pattern mismatch\" end; return true end`
          );
        }
        return parts.length === 1
          ? parts[0]
          : `t.intersection(${parts.join(", ")})`;
      }
      return "t.string";
    case "integer":
      return "t.number"; // integer enforcement separately in fn
    case "number":
      return "t.number";
    case "boolean":
      return "t.boolean";
    case "array":
      if (schema.items) return `t.array(${schemaToT(schema.items, depth + 1)})`;
      return "t.array(t.any)";
    case "object":
      if (schema.properties) {
        const fields = Object.entries(schema.properties).map(([k, v]) => {
          const req = isRequired(schema, k);
          const inner = schemaToT(v, depth + 1);
          return `${k} = ${req ? inner : `t.optional(${inner})`}`;
        });
        return `t.strictInterface({ ${fields.join(", ")} })`;
      }
      return "t.table";
    default:
      return "t.any";
  }
}

// Build module index
function buildIndexModule(groups: EndpointGroups): string {
  const tw = new TypeChunks();
  tw.line("-- Auto-generated SDK index");
  tw.line("local SDK = {  }");
  Object.keys(groups)
    .sort()
    .forEach((name) => tw.line(`SDK.${name} = require(script.${name})`));
  tw.line("return SDK");
  return tw.toString();
}

// Helper tiny writer
class TypeChunks {
  private buf: string[] = [];
  line(s = "") {
    this.buf.push(s);
  }
  toString() {
    return this.buf.join("\n");
  }
}

function buildLuaModule(
  moduleName: string,
  endpoints: GroupedEndpoint[]
): string {
  const w = new TypeChunks();
  w.line(`-- Auto-generated module: ${moduleName}`);
  w.line('local HttpService = game:GetService("HttpService")');
  w.line("local M = {  }");
  w.line();

  // collect type/validator declarations
  const typeDecls: string[] = [];
  const validatorDecls: string[] = [];

  function ensureSchemaArtifacts(
    schema: SchemaObject | null | undefined,
    baseName: string
  ) {
    if (!schema) return { typeName: "any", validatorName: "t.any" };
    const typeName = ident(baseName) + "Response"; // unify naming by context; collisions fine overwritten
    const luaType = schemaToLuauType(schema, typeName);
    const validatorExpr = schemaToT(schema);
    typeDecls.push(`export type ${typeName} = ${luaType}`);
    const validatorVar = ident(typeName) + "Validator";
    validatorDecls.push(`local ${validatorVar} = ${validatorExpr}`);
    return { typeName, validatorName: validatorVar };
  }

  endpoints.forEach((ep) => {
    const params = extractParameters(ep.operation);
    const response = extractResponseSchema(ep.operation);
    const { typeName: responseType, validatorName: responseValidator } =
      ensureSchemaArtifacts(
        response?.schema,
        ep.operation.operationId || ep.method + moduleName
      );

    // Build function signature in Luau with typed params
    const fnName = ep.operation.operationId!;
    const paramList: string[] = [];
    const paramDocs: string[] = [];

    params.path.forEach((p) => {
      paramList.push(`${p.name}: ${p.type === "integer" ? "number" : p.type}`);
      paramDocs.push(`-- @param ${p.name} ${p.type}`);
    });
    params.query.forEach((p) => {
      paramList.push(`${p.name}: ${p.type === "integer" ? "number" : p.type}`);
      paramDocs.push(`-- @param ${p.name} (query) ${p.type}`);
    });
    if (params.body) {
      const bodyTypeName = ident(fnName) + "Body";
      // declare body type + validator
      typeDecls.push(
        `export type ${bodyTypeName} = ${schemaToLuauType(
          params.body.schema,
          bodyTypeName
        )}`
      );
      const bodyValidatorVar = bodyTypeName + "Validator";
      validatorDecls.push(
        `local ${bodyValidatorVar} = ${schemaToT(params.body.schema)}`
      );
      paramList.push(`body: ${bodyTypeName}`);
    }

    w.line(ep.description ? `-- ${ep.description}` : "-- (no description)");
    paramDocs.forEach((d) => w.line(d));
    w.line(`-- @returns ${responseType}`);
    w.line(`function M.${fnName}(${paramList.join(", ")})`);

    // validations using validators (body only for now, could add param constraints later)
    if (params.body) {
      const bodyValidatorVar = ident(fnName) + "BodyValidator";
      w.line(`  do`);
      w.line(`    local _ok, _err = ${bodyValidatorVar}(body)`);
      w.line(
        `    if not _ok then error("Body validation failed: " .. tostring(_err)) end`
      );
      w.line(`  end`);
    }

    // path building
    let path = ep.path;
    // replace {param}
    path = path.replace(/\{(.*?)\}/g, (_, p1) => `" .. tostring(${p1}) .. "`);
    w.line(`  local url = "${path}"`);

    // query serialization if query params exist
    if (params.query.length) {
      w.line(`  do`);
      w.line(`    local q = {}`);
      params.query.forEach((qp) => {
        w.line(
          `    if ${qp.name} ~= nil then q[${JSON.stringify(qp.name)}] = ${
            qp.name
          } end`
        );
      });
      w.line(`    local parts = {}`);
      w.line(
        `    for k,v in pairs(q) do parts[#parts+1] = HttpService:UrlEncode(k) .. "=" .. HttpService:UrlEncode(tostring(v)) end`
      );
      w.line(
        `    if #parts > 0 then url = url .. "?" .. table.concat(parts, "&") end`
      );
      w.line(`  end`);
    }

    // body encode
    if (params.body) {
      w.line(`  local bodyJson = HttpService:JSONEncode(body)`);
    }

    // HTTP request (placeholder) - expects only 200
    w.line(
      `  local response, statusCode = M._transport("${ep.method}", url, ${
        params.body ? "bodyJson" : "nil"
      })`
    );
    w.line(
      `  if statusCode ~= 200 then error("Unexpected status " .. tostring(statusCode) .. " for ${fnName}") end`
    );
    if (response) {
      w.line(
        `  local data = response and HttpService:JSONDecode(response) or nil`
      );
      w.line(`  do`);
      w.line(`    local _ok, _err = ${responseValidator}(data)`);
      w.line(
        `    if not _ok then error("Response validation failed: " .. tostring(_err)) end`
      );
      w.line(`  end`);
      w.line(`  return data :: ${responseType}`);
    } else {
      w.line(`  return nil :: any`);
    }
    w.line(`end`);
  });

  // prepend type declarations at top under module header
  const header = new TypeChunks();
  if (typeDecls.length) {
    header.line("-- TYPE DECLARATIONS");
    typeDecls.forEach((t) => header.line(t));
    header.line();
  }
  header.line("local t = require(game.ReplicatedStorage.Libraries.T)");
  if (validatorDecls.length) {
    header.line("-- VALIDATORS (T)");
    validatorDecls.forEach((v) => header.line(v));
    header.line();
  }

  // transport integration (server Http util) fallback error if missing
  w.line();
  w.line(
    "-- Transport: integrates with server Utils.Http if present (expects same interface as Http.lua)"
  );
  w.line(
    "local _httpOk, _Http = pcall(function() return require(game:GetService('ServerScriptService').Utils.Http) end)"
  );
  w.line("M._transport = function(method, url, body)");
  w.line(
    "  if not _httpOk then error('Http utility not available (ServerScriptService.Utils.Http)') end"
  );
  w.line("  local cfg = { url = url, method = method }");
  w.line("  if body then cfg.body = body end");
  w.line("  local res = _Http.request(cfg)");
  w.line("  return res.body, res.status.code");
  w.line("end");
  w.line("return M");

  return [header.toString(), w.toString()].join("\n");
}
