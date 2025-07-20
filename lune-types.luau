-- Lune type definitions for better LSP support
-- This file helps the Luau LSP understand Lune's built-in modules

export type fs = {
    readFile: (path: string) -> string,
    writeFile: (path: string, contents: string) -> (),
    writeDir: (path: string) -> (),
    isDir: (path: string) -> boolean,
    isFile: (path: string) -> boolean,
}

export type roblox = {
    deserializePlace: (contents: string) -> Instance,
    serializePlace: (dataModel: Instance) -> string,
}

-- You can require these in your Lune scripts like:
-- local fs: fs = require("@lune/fs")
-- local roblox: roblox = require("@lune/roblox")

return {}
