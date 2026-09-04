# Content Pipeline Vision & Scope

## Product idea

Weekly level delivery should not require a new Google Play build for every
batch. Store-delivered application code and remotely delivered level data are
separate systems.

\`\`\`text
GOOGLE PLAY / APP STORE
    -> engine, gameplay, UI, art/audio code/assets, app systems

SCRUBBOTS CONTENT PLATFORM
    -> declarative levels, pack/manifest metadata, activation/disable/schedule
\`\`\`

Remote content must never be used as a covert code-update channel.

## Weekly production flow

\`\`\`text
LEVEL FACTORY
  generate many candidates
  solve/analyze/validate
  owner accepts 100
        ↓
PUBLISHER
  serialize accepted levels
  build .scrubpack
  compute SHA-256
  build versioned manifest
        ↓
STAGING STORAGE/CDN
  upload
  verify remote bytes/hash
  developer-device QA
        ↓
EXPLICIT PROMOTE
        ↓
PRODUCTION STORAGE/CDN
  versioned manifest
  immutable/versioned pack objects
        ↓ HTTPS
SCRUBBOTS APP
  check manifest
  download missing packs
  verify
  install to user://
  play
\`\`\`

## Pack concept

A typical weekly pack may hold ~100 Level Data entries and associated allowed
metadata/previews. It has a stable pack ID, schema version and hash.

The exact .scrubpack encoding is still an implementation decision; the
contract is versioned, inspectable and contains no executable code.

## Manifest concept

The manifest is the remote content source of truth and includes:

- schema_version
- monotonic content_version
- minimum_game_version compatibility
- pack IDs/locations/hashes
- available level ownership
- disabled_levels
- scheduled activation metadata

The app compares local and remote content state and downloads only missing
verified packs.

## Offline-first

Remote content updates require network. Playing does not.

The app preserves builtin and last-known-good cached content. Network,
server, parse, hash or compatibility failures must not destroy the playable
known-good set.

Runtime content lives under \`user://content/\`.

## Staging and production

No direct blind live publish:

\`\`\`text
build
→ validate
→ upload
→ STAGING manifest
→ real download verification
→ developer/owner approval
→ explicit promotion
→ PRODUCTION manifest
→ production verification
\`\`\`

A future one-button Publish UX may orchestrate these steps only after each
step is independently testable.

## Rollback and disable

Rollback is a new auditable content version that points players back to
known-good content. Do not silently rewrite history.

A bad individual level can be disabled declaratively without withdrawing a
healthy 100-level pack.

## Scheduling

Multiple future weekly packs may be prepared in one session and scheduled
for later activation. Scheduling must use explicit time semantics, maintain
audit history, and never activate incompatible/unverified content.

## Provider

Cloudflare R2 + CDN is the preferred candidate from prior planning because it
fits object storage + HTTPS/CDN needs, but provider choice remains behind an
adapter until cost/security/operations are validated and owner-approved.

Alternatives include Firebase Storage, S3/CloudFront, Supabase Storage and
Backblaze B2.

## Security

- declarative data only
- no .gd/.dex/.so/native/bytecode/plugin/evaluable scripts
- HTTPS
- SHA-256 integrity before activation
- publisher credentials offline only
- no secrets in Git
- no publisher secrets in mobile app
- staging before production
- last-known-good recovery
- current Google Play/App Store policies rechecked before launch

If the threat model later requires authenticity beyond hashes, design signed
manifest/pack verification as a separately audited upgrade.
