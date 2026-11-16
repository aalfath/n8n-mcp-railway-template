# n8n-MCP for Railway: the official image, pinned by version and digest.
# Bump the tag and digest together, and add a CHANGELOG.md entry.
FROM ghcr.io/czlonkowski/n8n-mcp:2.102.0@sha256:48e0f38c4e7622ee029c61c66660b5d75f12d869fe8311c6711073af0d0cd4aa

# The upstream entrypoint starts as root only to fix volume ownership, then drops
# to the unprivileged `nodejs` user with su-exec. Railway volumes are owned by root,
# so the container must start as root for that step.
USER root

# Fixed settings for a public HTTP deployment behind Railway's proxy.
ENV MCP_MODE=http \
    NODE_ENV=production \
    IS_DOCKER=true \
    HOST=:: \
    PORT=3000 \
    TRUST_PROXY=1 \
    LOG_LEVEL=info \
    NODE_DB_PATH=/data/nodes.db

COPY railway/ /app/railway/
RUN chmod 0755 /app/railway/railway-start.sh

EXPOSE 3000

ENTRYPOINT ["/app/railway/railway-start.sh"]
CMD ["node", "/app/dist/mcp/index.js"]
