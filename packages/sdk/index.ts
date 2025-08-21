import {
  Project,
  PropertySignature,
  SourceFile,
  Type,
  Symbol as TSSymbol,
} from "ts-morph";

import fs from "fs";
import path from "path";

import { Typewriter } from "./typewriter.js";

const INPUT = path.resolve("types.d.ts");
const OUTDIR = path.resolve("../game", "shared", "_sdk_bin");
const OUTFILE = path.join(OUTDIR, "init.lua");

import { capitalize } from "./util.js";

function pascalCase(str: string): string {
  if (!str) return str;
  return str[0]!.toUpperCase() + str.slice(1);
}

function getMethodName(method: string, route: string): string {
  route = route.replace(/^['"`]+|['"`]+$/g, "").replace(/^\/+/, "");
  if (!route)
    return method.toLowerCase() === "get" ? "get" : method.toLowerCase();
  const segs = route.split("/").filter(Boolean);
  // Remove first segment for grouping (e.g., 'players', 'scores')
  const [, ...rest] = segs;
  const methodStem =
    method.toLowerCase() === "get" ? "get" : method.toLowerCase();
  if (rest.length === 0) return methodStem; // e.g., Players.get
  const formatted = rest.map((s, idx) => {
    if (s.startsWith("{") && s.endsWith("}"))
      return "By" + capitalize(s.slice(1, -1));
    return idx === 0 ? capitalize(s) : capitalize(s);
  });
  return methodStem + formatted.join("");
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

interface EndpointSpec {
  group: string; // e.g. Players, Scores
  methodName: string; // e.g. GetTop, PostScore
  httpMethod: string; // get/post
  route: string; // raw route '/players/top'
  pathParams: string[]; // ordered by appearance in route
  queryParams: string[]; // as discovered
  pathParamTypes: Record<string, Type>;
  queryParamTypes: Record<string, Type>;
  bodyTypeName?: string; // generated body type alias
  responseTypeName?: string; // generated response 200 type alias
  bodyType?: Type; // ts-morph Type for body (application/json)
  responseType?: Type; // ts-morph Type for 200 response (application/json)
}

const HTTP_METHODS = ["get", "post", "put", "delete"] as const;

function firstSegment(route: string): string {
  route = route.replace(/^["'`]+|["'`]+$/g, "").replace(/^\/+/, "");
  if (!route) return "Root";
  const seg = route.split("/")[0] || "root";
  return capitalize(seg);
}

function extractPathParams(route: string): string[] {
  const params: string[] = [];
  const segs = route.replace(/^["'`]+|["'`]+$/g, "").split("/");
  segs.forEach((s) => {
    const m = s.match(/^\{(.+?)\}$/);
    if (m) params.push(m[1]!);
  });
  return params;
}

function tsTypeToLuau(
  type: Type,
  created: Map<string, string>,
  inline = false
): string {
  // Literal unions (all string literals)
  if (type.isUnion()) {
    const u = type.getUnionTypes();
    const allStringLits = u.every(
      (t) => t.isStringLiteral() || t.isNull() || t.isUndefined()
    );
    if (allStringLits) {
      const lits = u
        .filter((t) => t.isStringLiteral())
        .map((t) => JSON.stringify(String(t.getLiteralValue())));
      const nullable = u.some((t) => t.isNull() || t.isUndefined());
      if (lits.length > 0) return lits.join(" | ") + (nullable ? "?" : "");
    }
  }
  if (type.isStringLiteral() || type.isNumberLiteral()) {
    return typeof type.getLiteralValue() === "number" ? "number" : "string"; // literal collapse
  }
  if (type.isString()) return "string";
  if (type.isNumber()) return "number";
  if (type.isBoolean && type.isBoolean()) return "boolean";
  if (type.isUndefined() || type.getText() === "null") return "nil";

  // Array
  if (type.isArray()) {
    const elem = type.getArrayElementType();
    if (elem) return `{ ${tsTypeToLuau(elem, created)} }`;
    return "{ any }";
  }

  // Union: if nullable union
  if (type.isUnion()) {
    const unionTypes = type.getUnionTypes();
    const nonNull = unionTypes.filter((t) => !t.isNull() && !t.isUndefined());
    if (nonNull.length === 1 && unionTypes.length === 2) {
      return tsTypeToLuau(nonNull[0]!, created);
    }
    // Otherwise fall back to broadest
    const primitives = new Set(
      unionTypes.map((t) =>
        t.isString()
          ? "string"
          : t.isNumber()
          ? "number"
          : t.isBoolean()
          ? "boolean"
          : "any"
      )
    );
    if (primitives.size === 1) return [...primitives][0]!; // same primitive
    return "any";
  }

  if (type.isObject()) {
    const props = type.getProperties();
    if (props.length === 0) return "{ [string]: any }"; // empty object
    const fields: string[] = [];
    props.forEach((p) => {
      const decl = p.getValueDeclaration();
      if (!decl) return;
      const pType = p.getTypeAtLocation(decl);
      const name = p.getName();
      const luau = tsTypeToLuau(pType, created);
      // Optional detection
      const isOptional =
        p.isOptional() ||
        (pType.isUnion() &&
          pType.getUnionTypes().some((u) => u.isUndefined() || u.isNull()));
      fields.push(`${name}: ${luau}${isOptional ? "?" : ""}`);
    });
    return `{ ${fields.join(", ")} }`;
  }

  return "any";
}

function buildEndpointSpecs(pathProp: PropertySignature): EndpointSpec[] {
  const specs: EndpointSpec[] = [];
  const routeName = pathProp.getName();
  const type = pathProp.getType();
  if (!type.isObject()) return specs;
  for (const httpMethod of HTTP_METHODS) {
    const prop = type.getProperty(httpMethod);
    if (!prop) continue;
    const decl = prop.getValueDeclaration();
    if (!decl) continue;
    const opType = prop.getTypeAtLocation(decl);
    if (!opType.isObject()) continue;

    const methodName = getMethodName(httpMethod, routeName);
    const group = firstSegment(routeName);
    const pathParams = extractPathParams(routeName);
    const queryParams: string[] = [];
    const pathParamTypes: Record<string, Type> = {};
    const queryParamTypes: Record<string, Type> = {};

    const paramsSymbol = opType.getProperty("parameters");
    if (paramsSymbol) {
      const paramsDecl = paramsSymbol.getValueDeclaration();
      const paramsType = paramsSymbol.getTypeAtLocation(paramsDecl!);
      if (paramsType.isObject()) {
        // query
        const querySym = paramsType.getProperty("query");
        if (querySym) {
          const qDecl = querySym.getValueDeclaration();
          const qType = querySym.getTypeAtLocation(qDecl!);
          if (qType.isObject()) {
            qType.getProperties().forEach((qp) => {
              queryParams.push(qp.getName());
              const decl = qp.getValueDeclaration();
              if (decl)
                queryParamTypes[qp.getName()] = qp.getTypeAtLocation(decl);
            });
          }
        }
        // path
        const pathSym = paramsType.getProperty("path");
        if (pathSym) {
          const pDecl = pathSym.getValueDeclaration();
          const pType = pathSym.getTypeAtLocation(pDecl!);
          if (pType.isObject()) {
            pType.getProperties().forEach((pp) => {
              const decl = pp.getValueDeclaration();
              if (decl)
                pathParamTypes[pp.getName()] = pp.getTypeAtLocation(decl);
            });
          }
        }
      }
    }

    // Body
    let bodyType: Type | undefined;
    const rbSym = opType.getProperty("requestBody");
    if (rbSym) {
      const rbDecl = rbSym.getValueDeclaration();
      const rbType = rbSym.getTypeAtLocation(rbDecl!);
      if (rbType.isObject()) {
        const contentSym = rbType.getProperty("content");
        if (contentSym) {
          const cDecl = contentSym.getValueDeclaration();
          const cType = contentSym.getTypeAtLocation(cDecl!);
          if (cType.isObject()) {
            // Find first property containing application/json (string literal name)
            for (const prop of cType.getProperties()) {
              const name = prop.getName().replace(/^['"`]+|['"`]+$/g, "");
              if (name.includes("application/json")) {
                const ajDecl = prop.getValueDeclaration();
                bodyType = prop.getTypeAtLocation(ajDecl!);
                break;
              }
            }
          }
        }
      }
    }

    // Responses 200
    let responseType: Type | undefined;
    const responsesSym = opType.getProperty("responses");
    if (responsesSym) {
      const rDecl = responsesSym.getValueDeclaration();
      const rType = responsesSym.getTypeAtLocation(rDecl!);
      if (rType.isObject()) {
        const twoHundredSym = rType.getProperty("200");
        if (twoHundredSym) {
          const thDecl = twoHundredSym.getValueDeclaration();
          const thType = twoHundredSym.getTypeAtLocation(thDecl!);
          if (thType.isObject()) {
            const contentSym = thType.getProperty("content");
            if (contentSym) {
              const cDecl = contentSym.getValueDeclaration();
              const cType = contentSym.getTypeAtLocation(cDecl!);
              if (cType.isObject()) {
                for (const prop of cType.getProperties()) {
                  const name = prop.getName().replace(/^['"`]+|['"`]+$/g, "");
                  if (name.includes("application/json")) {
                    const ajDecl = prop.getValueDeclaration();
                    responseType = prop.getTypeAtLocation(ajDecl!);
                    break;
                  }
                }
              }
            }
          }
        }
      }
    }

    const base: EndpointSpec = {
      group,
      methodName,
      httpMethod,
      route: routeName.replace(/^["'`]+|["'`]+$/g, ""),
      pathParams,
      queryParams,
      pathParamTypes,
      queryParamTypes,
    } as EndpointSpec;
    if (bodyType) (base as any).bodyType = bodyType;
    if (responseType) (base as any).responseType = responseType;
    specs.push(base);
  }
  return specs;
}

function generateLua(endpoints: EndpointSpec[]): string {
  const tw = new Typewriter();
  tw.raw("--!strict");
  tw.blank();
  tw.line("-- Auto-generated SDK. Do not edit manually.");
  tw.line('local HttpService = game:GetService("HttpService")');
  tw.blank();

  // Collect groups
  const groups = new Map<string, EndpointSpec[]>();
  endpoints.forEach((e) => {
    if (!groups.has(e.group)) groups.set(e.group, []);
    groups.get(e.group)!.push(e);
  });

  // Types
  const created = new Map<string, string>();
  let typeCounter = 0;
  endpoints.forEach((e) => {
    const baseName = pascalCase(e.methodName);
    if (e.bodyType && !e.bodyTypeName) {
      e.bodyTypeName = `${baseName}RequestBody`;
      tw.line(`type ${e.bodyTypeName} = ${tsTypeToLuau(e.bodyType, created)}`);
    }
    if (e.responseType && !e.responseTypeName) {
      e.responseTypeName = `${baseName}Response`;
      tw.line(
        `type ${e.responseTypeName} = ${tsTypeToLuau(e.responseType, created)}`
      );
    }
  });
  tw.blank();

  // Real request bridge using ServerScriptService.Utils.Http
  tw.block(
    "local function request(method: string, path: string, query: { [string]: any }?, body: any?)",
    () => {
      tw.line("-- Locates Http module at game.ServerScriptService.Utils.Http");
      tw.line("local SSS = game:GetService('ServerScriptService')");
      tw.line("local Utils = SSS:FindFirstChild('Utils')");
      tw.line(
        "if not Utils then error('Utils folder missing in ServerScriptService') end"
      );
      tw.line("local HttpModule = Utils:FindFirstChild('Http')");
      tw.line(
        "if not HttpModule then error('Http module missing at ServerScriptService/Utils/Http') end"
      );
      tw.line("local Http = require(HttpModule)");
      tw.line("local config = {} :: any");
      tw.line("if query then config.params = query end");
      tw.line("if body ~= nil then config.json = body end");
      tw.line("local lower = string.lower(method)");
      tw.line("local fn = Http[lower]");
      tw.line("if not fn then error('Unsupported method '..method) end");
      tw.line("local resp = fn(path, config)");
      tw.line("local data = nil");
      tw.line(
        "if resp and resp.success and resp.status and resp.status.code == 200 then"
      );
      tw.indent(() => {
        tw.line("if typeof(resp.json) == 'function' then");
        tw.indent(() => {
          tw.line("local ok, parsed = pcall(resp.json)");
          tw.line("if ok then data = parsed end");
        });
        tw.line("end");
      });
      tw.line("end");
      tw.line(
        "return { StatusCode = resp.status and resp.status.code or 0, Body = data }"
      );
    },
    "end"
  );
  tw.blank();

  // Initialize groups
  groups.forEach((_v, g) => tw.line(`local ${g} = {}`));
  tw.blank();

  // Functions
  groups.forEach((eps, g) => {
    eps.forEach((e) => {
      const paramsOrdered = [...e.pathParams, ...e.queryParams];
      if (e.bodyTypeName) paramsOrdered.push("body");
      const paramAnnotations = paramsOrdered
        .map((p) => {
          if (p === "body") return `body: ${e.bodyTypeName}`;
          const t = e.pathParamTypes[p] || e.queryParamTypes[p];
          const luau = t ? tsTypeToLuau(t, new Map()) : "any";
          return `${p}: ${luau}`;
        })
        .join(", ");
      const returnAnnot = e.responseTypeName ? `: ${e.responseTypeName}` : "";
      tw.block(
        `function ${g}.${e.methodName}(${paramAnnotations})${returnAnnot}`,
        () => {
          // Build path with path params
          let pathExpr = `"${e.route}"`;
          e.pathParams.forEach((pp) => {
            // replace {pp} with ".. pp .."
            pathExpr = pathExpr.replace(
              new RegExp(`\\{${pp}\\}`, "g"),
              `" .. tostring(${pp}) .. "`
            );
          });
          // Cleanup doubled quotes
          pathExpr = pathExpr.replace(/"" \+ /g, "").replace(/ \+ ""/g, "");
          if (pathExpr.endsWith(' .. ""'))
            pathExpr = pathExpr.replace(/ \+ ""$/, "");
          tw.line(`local _path = ${pathExpr}`);
          // Query table
          if (e.queryParams.length > 0) {
            tw.line("local _query = {} :: { [string]: any }");
            e.queryParams.forEach((qp) => tw.line(`_query["${qp}"] = ${qp}`));
          } else {
            tw.line("local _query = nil");
          }
          // Body
          if (e.bodyTypeName) {
            tw.line("local _body = body");
          } else {
            tw.line("local _body = nil");
          }
          tw.line(
            `local _res = request("${e.httpMethod.toUpperCase()}", _path, _query, _body)`
          );
          tw.line("if _res.StatusCode ~= 200 then");
          tw.indent(() =>
            tw.line(
              'error("HTTP ' +
                e.httpMethod.toUpperCase() +
                " " +
                e.route +
                ' failed: " .. tostring(_res.StatusCode))'
            )
          );
          tw.line("end");
          if (e.responseTypeName)
            tw.line("return _res.Body :: " + e.responseTypeName);
        },
        "end"
      );
      tw.blank();
    });
  });

  // Export table
  tw.line("return {");
  groups.forEach((_v, g) => tw.line(`  ${g} = ${g},`));
  tw.line("}");
  return tw.toString();
}

function exportHttpMethod() {
  /* retained placeholder for potential future granular export logic */
}

function collectEndpoints(paths: PropertySignature[]): EndpointSpec[] {
  const out: EndpointSpec[] = [];
  paths.forEach((p) => out.push(...buildEndpointSpecs(p)));
  return out;
}

function getPaths(sf: SourceFile): PropertySignature[] {
  const paths = sf
    .getInterfaces()
    .filter((iface) => iface.getName() === "paths")[0];

  return paths ? paths.getProperties() : [];
}

function run() {
  const project = new Project({
    tsConfigFilePath: "./tsconfig.json",
    skipAddingFilesFromTsConfig: true,
  });

  const sf = project.addSourceFileAtPath(INPUT);
  const paths = getPaths(sf);

  if (paths.length < 1) throw new Error("No 'paths' interface found");

  const endpoints = collectEndpoints(paths);
  const lua = generateLua(endpoints);

  fs.mkdirSync(OUTDIR, { recursive: true });
  fs.writeFileSync(OUTFILE, lua, "utf8");
  console.log(`Generated SDK with ${endpoints.length} endpoints -> ${OUTFILE}`);
}

run();
