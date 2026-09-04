# SCRUBBOTS Content Pipeline

This directory is a separate publishing/control-plane project for **remote
level data**, not a gameplay module.

## Mission

\`\`\`text
Level Factory accepted output
        ↓
validate
        ↓
.scrubpack
        ↓
hash
        ↓
candidate manifest
        ↓
upload
        ↓
STAGING
        ↓
real remote verification
        ↓
explicit promote
        ↓
PRODUCTION
        ↓
SCRUBBOTS RemoteContentManager
        ↓
user:// cache
        ↓
play verified declarative levels
\`\`\`

## Non-negotiable security boundary

Remote content is declarative data only. Never publish/activate GDScript,
native libraries, bytecode, plugins, evaluable expressions or other
executable gameplay code.

Publisher credentials remain offline and never ship in the app.

## Operations

The roadmap covers:

- versioned \`.scrubpack\`
- manifest schema and content versions
- SHA-256 integrity
- staging and production
- explicit promotion
- offline/last-known-good cache
- rollback as a new auditable version
- single-level disable
- scheduled activation
- provider abstraction (Cloudflare R2/CDN is a preferred candidate, not yet
  an irreversible vendor lock)
- policy/security release gate

Canonical task detail is in repository-root \`tasks.md\` using
\`SB-CPxx-xxx\`.
