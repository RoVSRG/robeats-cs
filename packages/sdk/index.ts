import { Project, PropertySignature, Symbol, Type } from "ts-morph";

import fs from "fs";
import path from "path";

const INPUT = path.resolve("types.d.ts");
const OUTDIR = path.resolve("../game", "shared", "_sdk_bin");

import { capitalize } from "./util.js";

function getMethodName(route: string): string {
  // Strip surrounding quotes (property names are string literals in the interface)
  route = route.replace(/^["'`]+|["'`]+$/g, "");

  // Strip leading slashes
  route = route.replace(/^\/+/, "");

  if (!route) return "root";

  const rawParts = route.split("/").filter(Boolean);

  const parts = rawParts.map(formatSegment).filter(Boolean);
  if (parts.length === 0) return "Root";

  return parts.map((p, i) => (i === 0 ? p : "By" + p)).join("");
}

function formatSegment(seg: string, i: number): string {
  // Path parameters like {playerId}
  if (seg.startsWith("{") && seg.endsWith("}")) {
    seg = seg.slice(1, -1);
  }

  // Split on non-alphanumeric just in case (kebab, snake, etc.)
  const words = seg.split(/[^a-zA-Z0-9]+/).filter(Boolean);
  if (words.length === 0) return "";

  return words.map((w) => (i === 0 ? w : capitalize(w))).join("");
}

function exportProperties(properties: PropertySignature[]) {
  for (const property of properties) {
    const methodName = getMethodName(property.getName());
    console.log(methodName);
  }
}

function setupProject() {
  const project = new Project({
    tsConfigFilePath: "./tsconfig.json",
    skipAddingFilesFromTsConfig: true,
  });

  const sf = project.addSourceFileAtPath(INPUT);

  const paths = sf
    .getInterfaces()
    .filter((iface) => iface.getName() === "paths")[0];

  if (!paths) throw new Error("No 'paths' interface found");

  exportProperties(paths.getProperties());
}

setupProject();
