# Preview — Remote-host relay (design)

Status: design only, no implementation.
Owner: TBD.
Audience: contributors planning the next phase of the embedded preview feature.

## Problem

The current preview implementation terminates inside the OpenChamber server process and forwards requests to a **loopback** target. It works for local topologies but not when OpenChamber runs remotely and the dev server is on the user's local machine. This document outlines the architecture for a relay agent that enables the remote case without weakening the existing SSRF gate.

## Non-goals

- Replacing the existing loopback proxy
- Acting as a generic public ingress for arbitrary local services
- Providing a hosted relay service

## Architecture

Three components:
1. **Local agent** on the user's laptop — outbound WebSocket to OpenChamber, proxies HTTP/WS to local dev servers
2. **Remote OpenChamber server** — agent registry, frame dispatch, same browser-facing API
3. **Browser (UI layer)** — almost no change, same preview pane

## Security model

- Server-side SSRF: loopback allowlist enforced on the agent
- Cross-user target access: cookie + path scope unchanged
- Agent impersonation: `agentSecret` per agent, revocable from Settings
- No inbound ports on user's machine

## Implementation milestones

1. Agent registry + enrollment endpoints
2. Standalone agent with ping/pong
3. HTTP-only proxying
4. WebSocket proxying (HMR)
5. Failure-mode polish
6. Documentation + tutorial
