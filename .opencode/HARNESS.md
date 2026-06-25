# HARNESS.md — OpenChamber

Harness global: `~/.config/opencode/`
Versión: 1.0.0 | Creado: 2026-06-24

---

## Comandos del proyecto

| Tipo | Comando | Notas |
|---|---|---|
| Test | `bun run type-check` | TypeScript type checking (all workspaces) |
| Lint | `bun run lint` | ESLint (all workspaces) |
| Verify | `bun run type-check && bun run lint` | Validación completa |
| Start | `bun run dev` | Web HMR dev flow |
| Start | `bun run electron:dev` | Desktop Electron dev |
| Start | `bun run vscode:dev` | VS Code extension dev |
| Build | `bun run build` | Build all workspaces |

## Documento SSOT del proyecto

Archivo principal: `AGENTS.md`

## Skills locales del proyecto

| Skill | Ruta |
|---|---|
| clack-cli-patterns | `.agents/skills/clack-cli-patterns/SKILL.md` |
| drag-to-reorder | `.agents/skills/drag-to-reorder/SKILL.md` |
| locale-ui-patterns | `.agents/skills/locale-ui-patterns/SKILL.md` |
| settings-ui-patterns | `.agents/skills/settings-ui-patterns/SKILL.md` |
| theme-system | `.agents/skills/theme-system/SKILL.md` |
| ui-api-decoupling | `.agents/skills/ui-api-decoupling/SKILL.md` |

## Stack

- Runtime/tooling: Bun 1.3.14, Node >=22
- UI: React 19, TypeScript 5.9, Vite 7, Tailwind v4
- State: Zustand 5
- UI primitives: Base UI, Radix UI, HeroUI
- Server: Express 5
- Desktop: Electron 41
- VS Code: extension + webview
- Monorepo: packages/web, packages/ui, packages/electron, packages/vscode

## Convenciones

- Idioma: español (todas las respuestas del agente deben ser en español)
- React: function components + hooks
- TypeScript: evitar `any`, blind casts
- Styling: Tailwind v4, typografia via `packages/ui/src/lib/typography.ts`
- Toasts: usar wrapper de `@/components/ui`, no importar `sonner` directamente
- Sin nuevos deps sin aprobación

## Archivos críticos

- `packages/electron/main.mjs` — Electron main process
- `packages/web/server/index.js` — Web server entry

## Harness activo

- [x] Agentes SDD globales disponibles
- [x] HARNESS.md completado
- [ ] TDD (test runner configurado)
- [x] Post-edit verification activa
