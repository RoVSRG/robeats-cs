/**
 * Luau (Roblox Lua) code generation helpers extracted from the main generator.
 */
import {
  extractParameters,
  buildLuaUrl,
  generateLuaValidation,
  extractResponseSchema,
  EndpointGroups,
  GroupedEndpoint,
  ExtractedParameterInfo,
} from "./openapi.js";
import { Typewriter } from "./typewriter.js";

export function buildIndexModule(groups: EndpointGroups): string {
  const w = new Typewriter();
  w.line("-- Auto-generated SDK index");
  w.line("local SDK = {}");
  w.blank();
  Object.keys(groups).forEach((m) => {
    w.line(`SDK.${m} = require(script.${m})`);
  });
  w.blank();
  w.line("return SDK");
  return w.toString();
}

export function buildLuaModule(
  moduleName: string,
  endpoints: GroupedEndpoint[]
): string {
  const writer = new Typewriter();

  writer.line(`-- Auto-generated module: ${moduleName}`);
  writer.line("local t = require(game.ReplicatedStorage.Libraries.T)");
  writer.line('local HttpService = game:GetService("HttpService")');
  writer.line("local M = {}");
  writer.blank();

  endpoints.forEach((ep) => renderEndpoint(writer, ep));

  writer.blank();
  writer.line("return M");
  return writer.toString();
}

function renderEndpoint(writer: Typewriter, endpoint: GroupedEndpoint) {
  const params = extractParameters(endpoint.operation);
  const funcName =
    endpoint.operation.operationId ||
    sanitizeName(`${endpoint.method}_${endpoint.path}`);

  const luaParams: string[] = [];

  params.path.forEach((p) => luaParams.push(p.name));
  params.query.forEach((p) => luaParams.push(p.name));

  if (params.body) luaParams.push("body");

  writer.line(`-- ${endpoint.description || endpoint.path}`);
  writer.block(
    `function M.${funcName}(${luaParams.join(", ")})`,
    () => {
      params.allParams.forEach((p) => {
        writer.line(generateLuaValidation(p.name, p.schema));
      });
      const urlExpr = buildLuaUrl(
        endpoint.path,
        params.path as ExtractedParameterInfo[]
      );
      if (params.query.length) {
        writer.line("local query = {}");
        params.query.forEach((q) => {
          writer.line(
            `if ${q.name} ~= nil then query["${q.name}"] = ${q.name} end`
          );
        });
        writer.line("local queryStr = HttpService:JSONEncode(query)");
        writer.line(`local url = ${urlExpr} .. '?' .. queryStr`);
      } else {
        writer.line(`local url = ${urlExpr}`);
      }
      if (params.body) {
        writer.line("local bodyJson = HttpService:JSONEncode(body)");
      }
      writer.line(
        "-- TODO: perform actual HTTP request via your networking layer"
      );
      const response = extractResponseSchema(endpoint.operation);
      if (response?.description) {
        writer.line(`-- Expected response: ${response.description}`);
      }
    },
    "end"
  );
  writer.blank();
}

function sanitizeName(s: string) {
  return s.replace(/[^A-Za-z0-9_]/g, "_");
}
