#!/usr/bin/env node
/**
 * SDK Code Generation Script
 * Fetches the running server's OpenAPI spec and emits Lua modules grouped by tag.
 */
import {
  fetchOpenApiSpec,
  groupEndpointsByTags,
  EndpointGroups,
} from "./openapi.js";
import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { buildIndexModule, buildLuaModule } from "./luau-gen";

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
