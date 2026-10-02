# MAINT-HOME-EXPORT-ASSET-GATE-C001 — OWNER / CHATGPT PRODUCTION DECISION V01

Date: 2026-10-02
Scope: Home approved-art binding in exported builds
Status: **AUTHORIZED / REQUIRED BEFORE M43 RESUME**

## Observed defect

In exported builds the Home manifest gate currently hashes raw source PNG paths with:

`FileAccess.get_sha256("res://<final>.png")`

Godot export packages may omit the source PNG and contain only the imported resource plus remap. The hash call then returns an empty string, invalidates the entire HOME manifest, and `HomeArtBinder` binds no approved Home art or HomeScrubbyHero animation frames.

This is a release-blocking integration defect, not an art-approval defect.

## Trust model

The approved SHA-256 remains the **source provenance/build gate**. It is not required to be a runtime anti-tamper hash of imported `.ctex` bytes.

There are two explicit validation modes:

### 1. SOURCE_TREE_STRICT

Used in editor/source-tree validation, tests, and immediately before export.

For every approved ART asset and every approved animation frame:

- manifest pin must be present and valid;
- raw source PNG must exist;
- raw source PNG SHA-256 must exactly match the approved pin.

Any mismatch blocks validation exactly as today.

### 2. PACKAGED_RUNTIME

Used only by exported game runtime.

For every approved ART asset / animation frame:

- all normal manifest/schema/status/final-path rules still apply;
- the 64-char approved source pin remains mandatory metadata;
- runtime does **not** call `FileAccess.get_sha256()` on source PNG bytes that are not packaged;
- the Godot resource path must resolve through the export remap using `ResourceLoader`;
- the texture must load successfully before it can bind.

The packaged runtime therefore trusts the manifest produced by the strict build gate plus the exported resource package. Platform/package signing remains the release integrity boundary.

## Forbidden shortcut

Do **not** implement:

"if the source PNG does not exist, silently skip hashing"

as an implicit global rule.

The validator/binder must know which explicit validation mode it is in. A missing raw PNG in strict mode remains a failure.

## Runtime mode selection

Production `HomeArtBinder` should automatically use:

- SOURCE_TREE_STRICT when running from the editor/source development binary;
- PACKAGED_RUNTIME in an exported template.

The implementation must verify the chosen Godot feature/API with a real 4.7.2 Web export rather than assuming it.

Tests must also be able to inject a validation mode explicitly so exported behavior can be simulated deterministically.

## Imported-resource hashing

Do not replace the source pin with a hash of imported `.ctex` as the canonical approval hash. Imported bytes are platform/import-setting/version artifacts and are not the owner-approved source byte identity.

## Build gate

A real export validation pass must run the strict source-tree manifest/hash gate successfully **before** invoking export, then prove the packaged build can bind the same approved resources without raw source PNG access.

No Home asset approval or SHA pin is changed by this maintenance task.
