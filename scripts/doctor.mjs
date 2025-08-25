#!/usr/bin/env node
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { createHash } from "node:crypto";

const CHECKS = [];
const results = [];
const log = (m) => console.log(`\x1b[35m[doctor]\x1b[0m ${m}`);
function add(name, fn) {
  CHECKS.push({ name, fn });
}
function run(cmd) {
  try {
    return execSync(cmd, { stdio: "pipe" }).toString().trim();
  } catch {
    return null;
  }
}
function record(name, ok, info) {
  results.push({ name, ok, info });
}

add("Node version >=18", () => {
  const major = +process.versions.node.split(".")[0];
  return { ok: major >= 18, info: process.versions.node };
});
add("Git present", () => {
  const v = run("git --version");
  return { ok: !!v, info: v || "missing" };
});
add("Submodules initialized", () => {
  if (!existsSync(".git")) return { ok: true, info: "not a git repo" };
  const status = run("git submodule status") || "";
  return {
    ok: !status.includes("-"),
    info: status.split("\n").length + " entries",
  };
});
add("Backend env file", () => {
  return {
    ok:
      existsSync("packages/backend/.env") ||
      existsSync("packages/backend/.env.local"),
    info: "env present?",
  };
});
add("Root env local", () => {
  return { ok: existsSync(".env.local"), info: ".env.local present" };
});
add("Docker available", () => {
  const v = run("docker --version");
  return { ok: !!v, info: v || "missing" };
});
add("Prisma schema", () => {
  return {
    ok: existsSync("packages/backend/prisma/schema.prisma"),
    info: "schema present",
  };
});
add("Prisma migrate status", () => {
  if (!existsSync("packages/backend/prisma/schema.prisma"))
    return { ok: true, info: "no backend" };
  const out = run("npx --yes prisma migrate status");
  if (!out) return { ok: false, info: "prisma CLI failed" };
  const drift = /Drift detected|different/.test(out);
  return { ok: !drift, info: drift ? "drift or mismatch" : "ok" };
});
add("Rojo binary (planned local)", () => {
  return {
    ok: existsSync("tools/bin/rojo") || existsSync("tools/bin/rojo.exe"),
    info: "local rojo",
  };
});
add("Lune binary (planned local)", () => {
  return {
    ok: existsSync("tools/bin/lune") || existsSync("tools/bin/lune.exe"),
    info: "local lune",
  };
});
add("Nx installed", () => {
  try {
    const pkg = JSON.parse(readFileSync("package.json", "utf8"));
    return {
      ok: !!(pkg.devDependencies?.nx || pkg.dependencies?.nx),
      info: pkg.devDependencies?.nx || pkg.dependencies?.nx || "missing",
    };
  } catch {
    return { ok: false, info: "could not read package.json" };
  }
});
add("Songs submodule populated", () => {
  if (!existsSync("songs")) return { ok: false, info: "songs folder missing" };
  const gitMeta = existsSync("songs/.git");
  return { ok: gitMeta, info: gitMeta ? "submodule OK" : "not a submodule?" };
});

for (const c of CHECKS) {
  try {
    const r = c.fn();
    record(c.name, r.ok, r.info);
  } catch (e) {
    record(c.name, false, e.message);
  }
}

const okCount = results.filter((r) => r.ok).length;
const failCount = results.length - okCount;
log(`Completed ${results.length} checks. PASS=${okCount} FAIL=${failCount}`);
for (const r of results) {
  const status = r.ok ? "\x1b[32mOK\x1b[0m" : "\x1b[31mFAIL\x1b[0m";
  console.log(`${status} - ${r.name} (${r.info})`);
}
if (failCount > 0) process.exitCode = 1;
