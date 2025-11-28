# Repository Guidelines

## Project Structure & Module Organization
- Gameplay, engine, and services live under `src/engine` and `src/server`; shared utilities/components in `src/shared`; UI screens in `src/gui`.
- Archived Roblox instance trees that mirror the intended layouts are in `archive_screens/`—treat these as the visual source of truth when porting UI.
- Assets and audio live in `assets/` and `songs/`; Rojo builds output to `dist/`.

## Build, Test, and Development Commands
- `npm run build` — Rojo build to `dist/robeats-cs.rbxl`.
- `npm run serve` — Rojo live-sync while editing.
- `npm run songs:build` — regenerate the song bundle.
- `bash lint.sh` — refresh sourcemap and run `luau-lsp` static analysis (fix or silence warnings you touch).

## Coding Style & Naming Conventions
- Use `React.createElement` directly (no JSX). Shared primitives and theme defaults are in `src/shared/Components/Primitives.lua` and `Theme.lua`; compose them instead of bespoke styling per call site.
- Mirror archive layouts explicitly: add `UIListLayout`, `UIPadding`, and `UICorner` as children where the archive has them; avoid ad-hoc flex helpers.
- Follow Roblox naming: Modules in PascalCase, locals in camelCase, keep `UDim2.fromOffset/fromScale` and `Color3.fromRGB` readable. Prefix unused imports with `_` if needed.

## Testing Guidelines
- There is no automated test suite; rely on `bash lint.sh` and in-Studio/manual validation. Keep any new tests alongside the code with clear names (e.g., `ModuleName.spec.lua`).
- For UI changes, visually compare against `archive_screens/` and capture before/after screenshots when feasible.

## Commit & Pull Request Guidelines
- Use concise, imperative commit messages (e.g., “rewrite main menu with primitives”).
- PRs should describe purpose, key changes, verification steps (commands run, screenshots), and link relevant issues/tasks.
- Avoid large mixed commits; group refactors separately from functional changes when possible.

## Security & Configuration Tips
- In Studio, enable Game Settings → Security → “Allow HTTP Requests” to prevent SDK failures.
- Do not commit secrets or private tokens; generated type dumps (e.g., `roblox.d.luau`) should only come from approved commands.
