# Content Pipeline Architecture

## Control plane vs runtime

Offline control plane:

- package accepted levels
- build/version manifest
- hash
- upload
- staging verify
- promote
- rollback/disable/schedule

Shipping runtime:

- fetch manifest over HTTPS
- compare versions
- download missing packs
- verify integrity/schema
- install to \`user://\`
- preserve last-known-good content
- expose verified level data to catalog/loader

The runtime never contains publisher credentials, Factory code or control
plane mutation capability.

## Environments

STAGING and PRODUCTION are separate logical environments. Production changes
are explicit promotions of already-verified artifacts.

## Provider

Storage/CDN provider is behind an adapter. Cloudflare R2/CDN is the preferred
candidate from prior planning, subject to explicit validation/owner approval.
