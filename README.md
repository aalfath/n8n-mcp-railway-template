# n8n-MCP on Railway

Railway template for [n8n-MCP](https://github.com/czlonkowski/n8n-mcp), an MCP server that lets Claude, ChatGPT, Cursor and other AI assistants look up n8n's nodes, validate workflows, and (with an n8n API key) build, edit, test and debug workflows on your n8n instance.

## What it deploys

One service, **n8n-MCP**, built from this repo's `Dockerfile`:

- n8n-MCP **2.102.0**, the official image pinned by digest: `ghcr.io/czlonkowski/n8n-mcp:2.102.0@sha256:48e0f38c4e7622ee029c61c66660b5d75f12d869fe8311c6711073af0d0cd4aa`.
- HTTP mode on port 3000 behind a Railway domain, MCP endpoint `/mcp`, health check `/health` and restart on failure, all set in the Railway template (this repo has no `railway.json`).
- A Railway volume at `/data` for the SQLite database. It holds the node documentation of the current release and the workflow snapshots that n8n-MCP saves before every change it makes, which `n8n_workflow_versions` uses to roll back.

`railway/railway-start.sh` refuses to start without `AUTH_TOKEN`. On the first start it copies the release's database to the volume. After a version bump it installs the new release's database, copies your workflow snapshots into it, and keeps the previous file in `/data/backup`.

## Variables

| Variable | Default in the template | Description |
|---|---|---|
| `AUTH_TOKEN` | `${{secret(48)}}` (generated) | Bearer token every MCP client must send. Read it from the service's variables |
| `N8N_API_URL` | empty, optional | Your n8n instance URL, for example `https://n8n.example.com`. Enables the workflow management tools |
| `N8N_API_KEY` | empty, optional | An API key from n8n (Settings → n8n API). Needed together with `N8N_API_URL` |
| `PORT` | `3000` | Port the server listens on |

Without `N8N_API_URL` and `N8N_API_KEY`, the documentation and validation tools still work. Add both later in the service's variables to turn on workflow management. Other upstream settings (`DISABLED_TOOLS`, `DISABLED_TOOL_OPERATIONS`, `WEBHOOK_SECURITY_MODE`, `N8N_MCP_TELEMETRY_DISABLED=true` to opt out of n8n-MCP's anonymous usage statistics) are in the upstream [`.env.example`](https://github.com/czlonkowski/n8n-mcp/blob/main/.env.example).

## Connecting a client

The MCP endpoint is `https://YOUR-DOMAIN.up.railway.app/mcp`, with the header `Authorization: Bearer YOUR-AUTH-TOKEN`.

Claude Code:

```sh
claude mcp add --transport http n8n-mcp https://YOUR-DOMAIN.up.railway.app/mcp --header "Authorization: Bearer YOUR-AUTH-TOKEN"
```

Clients that only speak stdio (Claude Desktop):

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://YOUR-DOMAIN.up.railway.app/mcp", "--header", "Authorization: Bearer YOUR-AUTH-TOKEN"]
    }
  }
}
```

## Updates

Projects deployed from the template build from this repo's `main` branch. When a new version is merged to `main`, Railway shows those projects an "update available" notice, and each owner chooses when to apply it. The workflow snapshots stay on the volume. Every version is listed in [CHANGELOG.md](CHANGELOG.md), with breaking changes first.

n8n-MCP is MIT-licensed, by Romuald Czlonkowski. This repo only wraps the official image.
