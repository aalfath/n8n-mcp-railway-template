# Changelog

Every version of this Railway template. Breaking changes are listed first in each entry.

## 2.102.0 (2026-11-16)

- First release: n8n-MCP 2.102.0, official image `ghcr.io/czlonkowski/n8n-mcp:2.102.0` pinned by digest `sha256:48e0f38c4e7622ee029c61c66660b5d75f12d869fe8311c6711073af0d0cd4aa`.
- The SQLite database lives on a Railway volume at `/data`, so workflow rollback snapshots survive redeploys. On a version bump the start script installs the new release's node documentation and carries the snapshots over, keeping one backup in `/data/backup`.
- `AUTH_TOKEN` is generated at deploy time. `N8N_API_URL` and `N8N_API_KEY` are optional.
