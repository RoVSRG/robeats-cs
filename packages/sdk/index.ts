import { Project, PropertySignature, SourceFile, Symbol, Type } from "ts-morph";

import fs from "fs";
import path from "path";

import { Typewriter } from "./typewriter.js";

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

function exportHttpMethod(method: Symbol) {
  console.log(`Exporting HTTP method: ${method.getName()}`);
}

const HTTP_METHODS = ["get", "post", "put", "delete"];

function exportPath(tw: Typewriter, type: Type) {
  tw.line(type.getText());

  if (type.isObject()) {
    HTTP_METHODS.forEach((httpMethod) => {
      console.log(`Exporting ${httpMethod}`);

      const httpProperty = type.getProperty(httpMethod);

      if (httpProperty) {
        console.log(
          httpProperty.getName(),
          httpProperty.getValueDeclaration()?.getText()
        );
      }
    });
  }

  for (const property of type.getProperties()) {
    const declaration = property.getValueDeclaration();
    const propertyType = property.getTypeAtLocation(declaration!);

    if (propertyType.isObject()) {
    }

    // for (const httpMethod of HTTP_METHODS) {
    // }
  }

  return tw.toString();
}

function getPaths(sf: SourceFile): PropertySignature[] {
  const paths = sf
    .getInterfaces()
    .filter((iface) => iface.getName() === "paths")[0];

  return paths ? paths.getProperties() : [];
}

function setupProject() {
  const project = new Project({
    tsConfigFilePath: "./tsconfig.json",
    skipAddingFilesFromTsConfig: true,
  });

  const sf = project.addSourceFileAtPath(INPUT);
  const paths = getPaths(sf);

  if (paths.length < 1) throw new Error("No 'paths' interface found");

  for (const path of paths) {
    const tw = new Typewriter();

    const methodName = getMethodName(path.getName());
    console.log(`Exporting ${methodName}`);

    const exp = exportPath(tw, path.getType());
  }
}

setupProject();
