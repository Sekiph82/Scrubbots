# SCRUBBOTS Content Platform Runtime Implementation Boundary V01

Status: CANONICAL
Date: 2026-09-14

## Purpose

This document prevents the new Content Platform repository from accidentally absorbing shipping-runtime code and prevents the game repository from growing a second publisher/factory implementation.

## Implement in `Sekiph82/ScrubBots-Level-Factory`

- art/semantic/procedural generation;
- deterministic logical compilation/provenance;
- simulation/solver/difficulty analysis;
- QA/review/campaign sequencing;
- Factory Studio/operator UI;
- `.scrubpack` creation;
- remote manifest construction;
- staging/production publisher;
- storage/CDN adapters;
- rollback/disable/scheduling control plane;
- publishing/operations reports.

## Implement in `Sekiph82/Scrubbots`

- runtime RemoteContentManager;
- HTTPS content-manifest fetch;
- runtime pack download;
- runtime SHA/integrity validation;
- runtime schema/LevelData validation before activation;
- `user://` content registry/cache;
- last-known-good preservation;
- offline fallback;
- runtime LevelCatalog exposure;
- application INTERNET permission when remote content actually ships;
- app/content compatibility behavior.

## Implement cross-repo

The following require producer + consumer golden evidence:

- LevelData compatibility snapshots;
- `.scrubpack` schema/parser vectors;
- remote manifest schema/parser vectors;
- minimum-game-version behavior;
- disable/schedule/rollback semantics;
- staging real-download verification;
- end-to-end security/release gate.

## Prohibited shortcuts

- no Python publisher code embedded into the Godot shipping app;
- no GDScript runtime code placed in remote content packages;
- no Factory source imported into game `res://` as a production dependency;
- no runtime mutation of `res://` from downloaded content;
- no duplicated schema truth maintained manually in two repos without golden cross-tests.

## Runtime safety invariant

An unavailable or corrupt remote service must not make builtin/last-known-good playable content unusable.

A failed update never destroys the last known-good content set.
