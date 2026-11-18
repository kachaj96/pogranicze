# SpriteCook skills (vendored)

Source: https://github.com/SpriteCook/claude-plugin (MIT, see SPRITECOOK_LICENSE)
Commit: 0032d2e27a525db109b9b1749ec6681864d53146 (plugin 0.1.15, skills 2026.10.20)
Copied unchanged except removed `agents/openai.yaml` (other agents' UI metadata).

Why vendored: the SpriteCook plugin cannot be enabled from the Claude mobile app.
The MCP server is connected as a claude.ai custom connector
(https://mcp.spritecook.ai/mcp/claude, OAuth), and these skills are loaded from the repo.
If the full plugin is enabled later, delete the spritecook-* folders here to avoid duplicates.
