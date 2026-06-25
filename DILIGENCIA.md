# Diligencia v1.18.1 — Estructura estándar de documentación

Sello de metodología para proyectos OpenCode.

---

## Qué es

Diligencia es una convención de estructura de documentación para proyectos OpenCode.
Define dónde vive cada tipo de archivo, cómo se nombran las variables de ruta, y cómo se organizan los comandos.

## Convención

| Tipo | Ubicación |
|---|---|
| Roadmap | `ROADMAP.md` (raíz) |
| Checklist | `CHECKLIST.md` (raíz) |
| Changelog | `CHANGELOG.md` (raíz) |
| ADRs, sistema, bitácora | `doc/arch/` |
| Guías de usuario | `doc/guias/` (incluye `ESTANDAR-COMANDOS.md`) |
| Mecánicas del juego | `doc/mecanicas/` |
| Variables de ruta | `AGENTS.md` → `Mapeo de rutas` |
| Comandos locales | `.opencode/commands/` |
| Harness | `.opencode/HARNESS.md` (test, lint, skills, stack) |
| Comandos globales | `~/.config/opencode/commands/` |

## Proyectos adaptados

| Proyecto | Fecha | Estado |
|---|---|---|
| OpenChamber | 2026-06-24 | ✅ |
| Diligencia (autor) | 2026-05-31 | ✅ |
| Némesis Detective | 2026-05-08 | ✅ |
| MarketAI | 2026-05-08 | ✅ |
