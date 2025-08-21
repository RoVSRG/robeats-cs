import fs from "fs";
import path from "path";
import {
  fetchOpenApiSpec,
  generateOperationId,
  OpenApiSpec,
  Operation,
} from "./openapi";
import { Typewriter } from "./typewriter";

// Output location for generated Lua modules
const OUTPUT_DIR = path.resolve("..", "game", "shared", "_sdk_bin");

interface ExtendedOperation extends Operation {
  path: string;
  method: Operation["method"];
  summary?: string;
  description?: string;
  _pathParams: string[];
  _queryParams: string[];
  _hasBody: boolean;
}

function aggregateByTag(spec: OpenApiSpec) {
  const out: Record<string, ExtendedOperation[]> = {};
  for (const [p, methods] of Object.entries(spec.paths || {})) {
    for (const [method, op] of Object.entries(methods)) {
      if (!op) continue;
      const tags = op.tags && op.tags.length ? op.tags : ["Default"];
      for (const raw of tags) {
        const tag = raw.replace(/[^A-Za-z0-9_]/g, "");
        const params = (op as Operation).parameters || [];
        const pathParams = params
          .filter((x: any) => x.in === "path")
          .map((x: any) => x.name);
        const queryParams = params
          .filter((x: any) => x.in === "query")
          .map((x: any) => x.name);
        const hasBody = !!(op as any).requestBody?.content?.[
          "application/json"
        ];
        (out[tag] ||= []).push({
          ...(op as Operation),
          path: p,
          method: method as any,
          _pathParams: pathParams,
          _queryParams: queryParams,
          _hasBody: hasBody,
        });
      }
    }
  }
  return out;
}

function ensureDir() {
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function writeModule(tag: string, content: string) {
  fs.writeFileSync(path.join(OUTPUT_DIR, `${tag}.lua`), content, "utf8");
}

function writeInit(tags: string[]) {
  const tw = new Typewriter();
  tw.line("-- MINIMAL AUTO-GENERATED SDK index");
  tw.line("local SDK = {}");
  tags.sort().forEach((t) => tw.line(`SDK.${t} = require(script.${t})`));
  tw.line("return SDK");
  fs.writeFileSync(path.join(OUTPUT_DIR, "init.lua"), tw.toString(), "utf8");
}

function emitModule(tag: string, ops: ExtendedOperation[]) {
  const tw = new Typewriter();
  tw.line("-- MINIMAL AUTO-GENERATED MODULE");
  tw.line("local Http = require(game.ServerScriptService.Utils.Http)");
  tw.line(`local ${tag} = {}`);
  tw.blank();
  for (const op of ops) {
    const convertType = (type: string) => {
      switch (type) {
        case "string":
          return "string";
        case "integer":
          return "number";
        case "boolean":
          return "boolean";
        default:
          return "any";
      }
    };

    const getParameter = (name: string) => {
      return convertType(
        op.parameters?.find((p) => p.name === name)?.schema?.type || "any"
      );
    };

    const fn = op.operationId!;
    tw.line(`-- ${op.summary || op.description || fn}`);

    const args: string[] = [];

    for (const q of op._queryParams) {
      args.push(q + ": " + getParameter(q));
    }

    for (const p of op._pathParams) {
      args.push(p + ": " + getParameter(p));
    }

    if (op._hasBody) {
      args.push("_internal_key_payload");
    }

    console.log(args.concat(", "));

    tw.block(
      `function ${tag}.${fn}(${args.join(", ")})`,
      () => {
        tw.line("config = config or {}");
        tw.line(`local path = "${op.path}"`);
        for (const p of op._pathParams) {
          tw.line(`path = string.gsub(path, '{${p}}', tostring(${p}))`);
        }
        if (op._queryParams.length) {
          tw.line("local query = {}");
          for (const q of op._queryParams) {
            tw.line(
              `if config['${q}'] ~= nil then query['${q}'] = tostring(${q}) end`
            );
          }
        } else {
          tw.line("local query = nil");
        }
        if (op._hasBody) {
          tw.line("local body = _internal_key_payload");
        } else {
          tw.line("local body = nil");
        }
        tw.line("local httpConfig = {}");
        tw.line("if query then httpConfig.params = query end");
        tw.line("if body ~= nil then httpConfig.json = body end");
        tw.line(
          `local res = Http.${op.method.toLowerCase()}(path, httpConfig)`
        );
        tw.line("return res.json()");
      },
      "end"
    );
    tw.blank();
  }
  tw.line(`return ${tag}`);
  return tw.toString();
}

async function main() {
  let spec: OpenApiSpec;
  try {
    spec = await fetchOpenApiSpec();
  } catch (e) {
    const localFile = process.env.SDK_SPEC_FILE;
    if (!localFile || !fs.existsSync(localFile)) throw e;
    console.log(`⚠️  Using offline spec file: ${localFile}`);
    spec = JSON.parse(fs.readFileSync(localFile, "utf8"));
  }
  ensureDir();
  const grouped = aggregateByTag(spec);
  const tags: string[] = [];
  for (const [tag, ops] of Object.entries(grouped)) {
    for (const op of ops)
      op.operationId = generateOperationId(op.method, op.path);
    const mod = emitModule(tag, ops as ExtendedOperation[]);
    writeModule(tag, mod);
    tags.push(tag);
    console.log(`Generated minimal module: ${tag}`);
  }
  writeInit(tags);
  console.log(`✅ Minimal SDK modules: ${tags.join(", ")}`);
}

main().catch((err) => {
  console.error("SDK generation failed", err);
  process.exitCode = 1;
});
