# .scrubpack V1 — Draft Contract

Status: DESIGN / NOT IMPLEMENTED.

A scrubpack is a versioned container for multiple **declarative** level
artifacts plus pack metadata. It contains no executable code.

Required concepts:

- schema_version
- pack_id
- content_version association
- created_at
- level IDs / entries
- deterministic ordering
- per-level schema validation
- whole-pack SHA-256 published by the manifest
- optional preview/metadata entries only when explicitly supported

Exact binary/container encoding remains an implementation decision. V1 must
include inspect/unpack tooling and safe rejection of unsupported versions.
