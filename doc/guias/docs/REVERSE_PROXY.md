# Reverse Proxy Setup

Use this guide when running OpenChamber behind Nginx, Nginx Proxy Manager, Caddy, Cloudflare, or another reverse proxy.

## Before you proxy it

1. Confirm OpenChamber works directly first.
2. Open `http://<server-ip>:3000` or your custom port from the same network.
3. Only add the reverse proxy after the direct connection works.

## What the proxy must support

- WebSockets for live message transport:
  - `/api/event/ws`
  - `/api/global/event/ws`
  - `/api/terminal/ws`
- SSE without buffering:
  - `/api/event`
  - `/api/global/event`
  - `/api/notifications/stream`
  - `/api/openchamber/events`
  - `/api/terminal/:sessionId/stream`
- Large request bodies for attachments and file operations
- Long-lived read timeouts for live streams and terminal sessions

## Rules that matter

- Enable WebSocket proxying.
- Disable buffering on SSE routes.
- Disable gzip on the proxy if OpenChamber is already compressing responses.
- Keep compression enabled in only one layer.
- Forward normal proxy headers such as `Host`, `X-Forwarded-For`, and `X-Forwarded-Proto`.
- Increase body size limits if users upload files.

## Quick checklist

- OpenChamber reachable directly on LAN
- WebSockets enabled in the proxy
- SSE routes have buffering off
- `gzip off` on the proxy host, or proxy compression disabled another way
- `client_max_body_size` large enough for attachments
- `proxy_read_timeout` long enough for streams
