# ROADMAP — OpenChamber

---

## Ahora (Now)

| ID | Item | Prioridad | Estado | Depende de |
|----|------|-----------|--------|------------|
| R01 | Linux desktop app | P1 | 🔴 Pendiente | — |
| R02 | Mobile app con remote instance y laptop connectivity | P2 | 🔴 Pendiente | — |
| R08 | Tray: tooltip con datos vivos (memoria, uptime, puerto) | P1 | ✅ Completado | R00 |
| R09 | Tray: "Buscar actualizaciones" → git pull upstream + bun install | P2 | 🔴 Pendiente | R00 |
| R10 | Tray: health balloon via /health cada 60s | P2 | ✅ Completado | R00 |
| R11 | Tray: submenú "Datos" con Memoria, Puerto, Versión, Uptime | P3 | 🔴 Pendiente | R08 |
| R12 | Tray: auto-update de Chamber (git fetch upstream + tag compare) | P3 | 🔴 Pendiente | R09 |

## Completado — Diligencia Tray

| ID | Item | Instancia |
|----|------|-----------|
| R00 | Tray app funcional (icono, menú, start/stop/restart, watchdog) | 2026-06-26 |

## Siguiente (Next)

| ID | Item | Prioridad | Estado | Depende de |
|----|------|-----------|--------|------------|
| R03 | Más built-in tunneling options | P2 | 🔴 Pendiente | — |
| R04 | Kanban board para multi-agent management | P2 | 🔴 Pendiente | — |
| R05 | Custom OpenCode plugins/tools built-in catalog | P3 | 🔴 Pendiente | — |

## Futuro (Later)

| ID | Item | Prioridad | Estado | Depende de |
|----|------|-----------|--------|------------|
| R06 | Linear integration | P3 | 🔴 Pendiente | — |
| R07 | Built-in browser para running dev apps con agent integration | P3 | 🔴 Pendiente | — |

## Completado

| Item | Instancia |
|------|-----------|
| UI runtimes (web/desktop/VS Code) | v1.0.0 |
| Multi-agent runs con worktrees | v1.x |
| Cloudflare tunnel (quick, managed-remote, managed-local) | v1.x |
| SSH remote access | v1.x |
| Skills catalog | v1.x |
