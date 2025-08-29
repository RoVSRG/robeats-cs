#!/usr/bin/env node
import { execSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  copyFileSync,
  writeFileSync,
  chmodSync,
} from "node:fs";
import path from "path";
import { createWriteStream } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import https from "node:https";

/**
 * Phase 0 Setup Script
 * - Validates Node version
 * - Initializes git submodules
 * - Creates tools/bin folder (placeholder for vendored binaries)
 * - Ensures .env files from examples
 * - Light Prisma + Docker checks (non-fatal)
 */

const log = (m) => console.log(`\x1b[36m[setup]\x1b[0m ${m}`);
const warn = (m) => console.warn(`\x1b[33m[warn]\x1b[0m ${m}`);
const fail = (m) => {
  console.error(`\x1b[31m[error]\x1b[0m ${m}`);
  process.exitCode = 1;
};

const MIN_NODE = 18;
(function checkNode() {
  const major = +process.versions.node.split(".")[0];
  if (major < MIN_NODE)
    fail(`Node ${MIN_NODE}+ required. Current: ${process.versions.node}`);
  else log(`Node version OK (${process.versions.node})`);
})();

function run(cmd, cwd = undefined) {
  try {
    return execSync(cmd, { stdio: "pipe", cwd }).toString().trim();
  } catch (e) {
    return undefined;
  }
}

// Git submodules
if (!existsSync(".git")) {
  warn("Not a git clone (no .git directory). Skipping submodule init.");
} else {
  log("Initializing submodules (if any)...");
  run("git submodule update --init --recursive");
  const status = run("git submodule status") || "";
  if (status.includes("-"))
    warn("Some submodules not initialized correctly. Check permissions.");
  else log("Submodules ready.");
}

// tools/bin setup
const toolsDir = "tools/bin";
if (!existsSync(toolsDir)) {
  mkdirSync(toolsDir, { recursive: true });
  log("Created tools/bin directory.");
}
const toolsReadme = "tools/README.md";
if (!existsSync(toolsReadme))
  writeFileSync(
    toolsReadme,
    `# Vendored CLI Tools\n\nAutomatically downloaded by setup script.\n`
  );

// Simple downloader
function download(url, outPath) {
  return new Promise((resolve, reject) => {
    const file = createWriteStream(outPath);
    https
      .get(url, (res) => {
        if (
          res.statusCode &&
          res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.location
        ) {
          // redirect
          file.close();
          return download(res.headers.location, outPath).then(resolve, reject);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        }
        res.pipe(file);
        file.on("finish", () => {
          file.close();
          resolve(outPath);
        });
      })
      .on("error", reject);
  });
}

// Determine platform asset names with fallbacks (zip & raw)
const platform = process.platform;
const arch = process.arch;
const ROJO_VERSION = "7.5.1"; // pin for reproducibility
const LUNE_VERSION = "0.10.1";

function assetCandidates(tool) {
  const a = arch === "arm64" ? "aarch64" : "x86_64";
  if (tool === "rojo") {
    if (platform === "win32")
      return [
        `rojo-${ROJO_VERSION}-windows-x86_64.zip`,
        `rojo-${ROJO_VERSION}-windows-x86_64.exe`,
      ];
    if (platform === "darwin")
      return [
        `rojo-${ROJO_VERSION}-macos-${a}.zip`,
        `rojo-${ROJO_VERSION}-macos-${a}`,
      ];
    return [
      `rojo-${ROJO_VERSION}-linux-x86_64.zip`,
      `rojo-${ROJO_VERSION}-linux-x86_64`,
    ];
  }
  if (tool === "lune") {
    if (platform === "win32")
      return [
        `lune-${LUNE_VERSION}-windows-x86_64.zip`,
        `lune-${LUNE_VERSION}-windows-x86_64.exe`,
      ];
    if (platform === "darwin")
      return [
        `lune-${LUNE_VERSION}-macos-${a}.zip`,
        `lune-${LUNE_VERSION}-macos-${a}`,
      ];
    return [
      `lune-${LUNE_VERSION}-linux-x86_64.zip`,
      `lune-${LUNE_VERSION}-linux-x86_64`,
    ];
  }
  return [];
}

async function extractIfZip(tmpPath, toolName, targetPath) {
  if (!tmpPath.endsWith(".zip")) return false;
  try {
    if (platform === "win32") {
      // Use PowerShell Expand-Archive
      const extractDir = join(tmpdir(), `${toolName}-extract-${Date.now()}`);
      mkdirSync(extractDir, { recursive: true });
      execSync(
        `powershell -NoProfile -Command "Expand-Archive -Path '${tmpPath}' -DestinationPath '${extractDir}' -Force"`
      );
      // Find executable inside
      const exeName = toolName + (platform === "win32" ? ".exe" : "");
      const candidate = join(extractDir, exeName);
      if (existsSync(candidate)) {
        copyFileSync(candidate, targetPath);
        return true;
      }
    } else {
      // Try 'unzip' command
      const extractDir = join(tmpdir(), `${toolName}-extract-${Date.now()}`);
      mkdirSync(extractDir, { recursive: true });
      try {
        execSync(`unzip -o '${tmpPath}' -d '${extractDir}'`);
      } catch {
        return false;
      }
      const exeName = toolName;
      const candidate = join(extractDir, exeName);
      if (existsSync(candidate)) {
        copyFileSync(candidate, targetPath);
        return true;
      }
      // search recursively fallback
      // (lightweight scan)
      const { readdirSync, statSync } = await import("node:fs");
      function find(dir) {
        for (const f of readdirSync(dir)) {
          const p = join(dir, f);
          if (statSync(p).isDirectory()) {
            const r = find(p);
            if (r) return r;
          } else if (f === exeName) return p;
        }
      }
      const found = find(extractDir);
      if (found) {
        copyFileSync(found, targetPath);
        return true;
      }
    }
  } catch (e) {
    warn(`Zip extraction failed for ${toolName}: ${e.message}`);
    return false;
  }
  return false;
}

async function ensureBinary(name, baseUrl) {
  const target = join(toolsDir, name + (platform === "win32" ? ".exe" : ""));
  if (existsSync(target)) {
    log(`${name} already present.`);
    return;
  }
  const candidates = assetCandidates(name);
  for (const asset of candidates) {
    const isZip = asset.endsWith(".zip");
    const url = `${baseUrl}/${asset}`;
    const tmpPath = join(tmpdir(), `${asset}`);
    log(`Attempt ${name}: ${asset}`);
    try {
      await download(url, tmpPath);
      if (isZip) {
        const ok = await extractIfZip(tmpPath, name, target);
        if (!ok) {
          warn(`Extraction failed for ${asset}`);
          continue;
        }
      } else {
        copyFileSync(tmpPath, target);
      }
      if (platform !== "win32") chmodSync(target, 0o755);
      log(`${name} installed from ${asset}`);
      return;
    } catch (e) {
      warn(`${asset} not usable: ${e.message}`);
    }
  }
  warn(
    `All download attempts failed for ${name}. Please manually place binary in tools/bin.`
  );
}

// Wrapper scripts (for consistent invocation via node_modules/.bin like pattern)
function ensureWrapper(cmdName) {
  const wrapperPath = join("tools", `${cmdName}.cmd`);
  if (platform === "win32" && !existsSync(wrapperPath)) {
    // Windows .cmd wrapper
    writeFileSync(wrapperPath, `@echo off\n"%~dp0bin\\${cmdName}.exe" %*`);
  }
  const shPath = join("tools", cmdName);
  if (platform !== "win32" && !existsSync(shPath)) {
    writeFileSync(
      shPath,
      `#!/usr/bin/env sh\nDIR=\"$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\"\n\"$DIR/bin/${cmdName}\" "$@"`
    );
    chmodSync(shPath, 0o755);
  }
}

async function fetchTools() {
  await ensureBinary(
    "rojo",
    `https://github.com/rojo-rbx/rojo/releases/download/v${ROJO_VERSION}`
  );
  await ensureBinary(
    "lune",
    `https://github.com/lune-org/lune/releases/download/v${LUNE_VERSION}`
  );
  ensureWrapper("rojo");
  ensureWrapper("lune");
}

await fetchTools();

// Ensure env files
function ensureEnv(examplePath, targetPath) {
  if (existsSync(examplePath) && !existsSync(targetPath)) {
    copyFileSync(examplePath, targetPath);
    log(`Created ${targetPath} from example.`);
  }
}
ensureEnv(".env.example", ".env.local");
ensureEnv("packages/backend/.env.example", "packages/backend/.env.local");

// Light Docker check
const dockerVersion = run("docker --version");
if (!dockerVersion) warn("Docker not found.");
else log(`Docker detected: ${dockerVersion}`);

// Prisma check (only if backend folder exists)
if (existsSync("packages/backend/prisma/schema.prisma")) {
  const prismaVer = run("npx --yes prisma --version");
  if (prismaVer) log(`Prisma available: ${prismaVer.split("\n")[0]}`);
  else warn("Prisma CLI not available yet (will work after npm install).");
}

log("Installing dependencies...");
run("npm i");

log("Building songs...");
run("npx nx run songs:build");

if (dockerVersion) {
  const BACKEND_DIR = "packages/backend";

  if (existsSync(path.join(BACKEND_DIR, ".env.local"))) {
    log(`Starting Docker.`);
    run("docker-compose --profile dev up -d", BACKEND_DIR);
  } else {
    warn(`Backend .env.local file not found: ${BACKEND_DIR}`);
  }
}

log("Setup phase complete. Vendored tools ready.");
