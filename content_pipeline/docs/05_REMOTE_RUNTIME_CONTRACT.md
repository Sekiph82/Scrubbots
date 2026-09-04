# Main-Game Remote Content Contract

Status: FUTURE RUNTIME INTEGRATION.

The mobile game eventually gets a narrow \`RemoteContentManager\` that:

- uses HTTPS
- downloads declarative manifest/packs only
- writes only under \`user://content/\`
- verifies hash + schema + Level Data before activation
- preserves last-known-good content
- allows offline play from builtin/cached content
- exposes verified levels through LevelCatalog/LevelLoader seams

It never downloads or evaluates executable gameplay code and never contains
publisher credentials.
