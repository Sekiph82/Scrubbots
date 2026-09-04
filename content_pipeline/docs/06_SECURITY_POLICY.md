# Content Security & Policy Boundary

Locked architecture:

- declarative remote content only
- no .gd / native library / bytecode / plugin / executable-expression payloads
- HTTPS only
- hashes verified before activation
- publisher credentials offline only
- secrets excluded from Git and mobile build
- last-known-good fallback
- staging before production
- versioned rollback
- policy re-verification before Google Play / App Store launch

SHA-256 is an integrity mechanism, not necessarily full authenticity. If the
threat model later requires signed manifests/packs, add a separate audited
signing design.
