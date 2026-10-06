# SCRUBBOTS — CP04/M15 + CP05/M16 REMOTE CONTENT RUNTIME MASTER V01

Status: **PREPARED / EXECUTION GATED BY CP03-M14 STRICT CLOSURE**
Date: 2026-10-06
Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Canonical tracker: root `TASKS.md` — **READ ONLY FOR BUILDER**

## PURPOSE

Implement the game-side runtime that lets an already-installed Android SCRUBBOTS build discover, download, verify, cache and play new declarative level packs without installing a new APK.

Target family-test use case:
- builtin APK contains Levels 1–10;
- later production content publishes Levels 11–50;
- the installed game fetches the production manifest;
- downloads only missing verified `.scrubpack` objects;
- validates exact bytes, pack/member schema and gameplay data;
- installs only under `user://content/`;
- exposes verified remote levels to the existing gameplay launch/catalog seams;
- continues to play the last-known-good cached content offline.

Remote content is **data only**. Never download or execute GDScript, scenes, resources, shaders, plugins, native libraries, bytecode, expressions, commands or any executable-capable payload.

This master implements game-runtime requirements:
- `SB-CP04-001..014`
- `SB-CP05-001..012`

Do not recreate these 26 requirements as a second canonical task family in root TASKS.md. Their canonical source IDs remain external references; implementation/evidence lives here.

---

# 0. HARD START GATE

Before ANY implementation:

1. Work directly from owner-local:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Inspect:
   - current branch;
   - `git status --short`;
   - local HEAD;
   - `origin/main`;
   - ahead/behind;
   - stashes/untracked owner work.
3. Non-destructively sync with latest `origin/main`.
4. Preserve:
   - `project.godot`;
   - `scenes/app/main.tscn`;
   - `addons/`;
   - `.mcp.json`;
   - owner/editor/plugin files;
   - unrelated untracked files.
5. No `reset --hard`, no `git clean`, no force checkout, no destructive overwrite.
6. Root `TASKS.md` is read-only.

## External contract gate

Do NOT implement against guessed publisher output.

Before code changes, verify that the canonical Content Platform publisher/staging/production milestone CP03/M14 has a strict final PASS/CLOSED record and inspect the final canonical artifacts/contracts it publishes.

The already-closed contracts that MUST remain authoritative are:
- Remote manifest V1:
  - schema `scrubbots.content.manifest.v1`;
  - `schema_version = 1`;
  - positive monotonic `content_version`;
  - canonical `minimum_game_version`;
  - pack entries with `pack_id`, `pack_version`, provider-neutral `object_key`, exact lowercase SHA-256 and `byte_length`;
  - ordered `levels` array mapping `level_id -> pack_id`.
- `.scrubpack` V1:
  - ZIP;
  - root `pack.json`;
  - schema `scrubbots.scrubpack.manifest.v1`;
  - version 1;
  - only:
    - `pack.json`;
    - `levels/{id}/level.json`;
    - `levels/{id}/supply-plan.json`;
    - `levels/{id}/metadata.json`;
  - exact per-member SHA-256;
  - regular JSON only;
  - no arbitrary paths / traversal / symlinks / executable entries.

If CP03/M14 is not strict PASS/CLOSED, STOP with:
`BLOCKED_BY_CP03_M14_RUNTIME_CONTRACT_GATE`

Do not invent a temporary publisher protocol.

---

# 1. ARCHITECTURE — ONE NARROW RUNTIME

Implement one game-owned runtime composition, preferably under:

`scripts/content_runtime/`

Required responsibilities must be separated so tests can inject fakes:

- `RemoteContentManager`
  - orchestration/state machine only;
- `RemoteContentTransport`
  - provider-neutral manifest/object download interface;
- production HTTPS transport
  - no publisher credentials;
- strict Manifest V1 parser/validator;
- strict Scrubpack V1 inspector/installer;
- local content registry;
- runtime/composite level catalog bridge;
- cache/last-known-good activation layer.

Publisher/Factory Python code must NOT be copied into the shipping game.

No cloud credentials, account IDs, upload tokens or mutation APIs ship in the app.

---

# 2. RUNTIME CONFIGURATION / ENABLEMENT

Create a small versioned runtime config, e.g.:

`data/config/remote_content_runtime_v1.json`

It may contain only non-secret runtime values such as:
- enabled flag;
- HTTPS production manifest URL/base URL when later configured;
- supported manifest schema/version;
- supported scrubpack schema/version;
- conservative download/cache limits.

Rules:
- no credentials;
- no upload endpoint authority;
- HTTPS only;
- empty/unconfigured production endpoint means remote refresh is disabled and builtin gameplay works normally.

## Game version compatibility

Do NOT invent a final store marketing version.

Production compatibility reads the canonical Godot app version only from:
`ProjectSettings["application/config/version"]`.

If that setting is absent or not strict `MAJOR.MINOR.PATCH`, remote activation must fail closed while builtin content remains playable.

Tests may inject explicit current-game versions.

The later Android Family APK task will set the actual family-build application version.

---

# 3. MANIFEST FETCH — CP04-001..004

Implement an injectable transport seam.

Production:
- HTTPS GET only;
- reject plain HTTP;
- bounded response bytes;
- sane timeout;
- no credentials embedded;
- redirects must never downgrade HTTPS;
- transport failure never blocks builtin/cached play.

Manifest validation must mirror the canonical V1 contract sufficiently for runtime trust:
- strict UTF-8;
- root object only;
- exact known fields;
- schema/version identity;
- positive integer content_version;
- canonical minimum_game_version;
- pack IDs/object keys/digests/byte lengths;
- levels and pack references;
- no duplicate logical pack IDs;
- no duplicate/casefold-colliding level IDs;
- reject duplicate JSON keys rather than silently last-wins;
- reject non-finite numbers;
- enforce conservative manifest depth/count/string/byte limits.

Compatibility gate:
- unsupported schema/version => candidate rejected;
- current app version below minimum => candidate rejected;
- candidate content_version <= active content_version => no downgrade/reinstall;
- same version with different manifest bytes/hash => reject as mutation;
- only greater content_version can become a new candidate.

Determine missing packs from the active cache using exact:
- pack_id;
- pack_version;
- object_key;
- sha256;
- byte_length.

Already verified identical packs are not downloaded again.

---

# 4. V1 CAMPAIGN ORDER POLICY — GAME-SIDE LOCK

The remote manifest does not invent order from numeric level IDs.

For SCRUBBOTS V1 runtime:

1. Builtin catalog remains canonical and immutable for its existing orders.
2. Remote playable level order is the **declared order of the manifest `levels` array**.
3. Remote levels append immediately after the highest builtin production catalog order.
4. Never derive order from:
   - filename;
   - numeric suffix;
   - alphabetical sort;
   - pack order.
5. A remote level ID may not collide/casefold-collide with any builtin or other remote level ID.
6. Once remote content has been activated, a successor manifest may preserve the existing remote sequence and append new levels only.
7. A successor that silently reorders/removes/reassigns an already activated remote sequence fails closed and the previous last-known-good stays active.
8. V1 does not allow remote content to replace builtin Levels 1–10.

This is the progression safety rule that allows a family build with builtin 1–10 to receive 11–50 without moving a player's existing frontier.

## Disabled/scheduled content

CP06 owns full runtime disable/scheduling behavior.

Until the corresponding game-runtime CP06 work is accepted:
- a candidate manifest with non-empty `disabled_levels` or non-empty `schedules` must NOT be silently ignored;
- reject activation as unsupported runtime semantics;
- retain/play the previous last-known-good set.

---

# 5. PACK DOWNLOAD / BYTE INTEGRITY — CP04-005..008

All remote writes are under:
`user://content/`

Never write remote bytes into `res://`.

Suggested layout:

`user://content/`
- `registry_v1.json`
- `last_known_good/` or versioned registry pointer
- `versions/<content_version>/...`
- `downloads/*.part`
- `staging/<transaction_id>/...`

Exact implementation may differ if equally safe.

Download transaction:
1. write to a unique `.part` path;
2. cap download size;
3. verify exact expected byte_length;
4. verify whole-pack SHA-256;
5. inspect ZIP safely;
6. validate exact member set/layout;
7. validate `pack.json`;
8. verify every member SHA-256;
9. validate each member as strict declarative JSON;
10. validate cross-file level identity;
11. validate LevelData with current game LevelValidator + ProductionLevelValidator;
12. validate exact supply plan with current `SupplyPlanLoader`;
13. validate metadata identity/dimensions/column contract needed by runtime;
14. only then materialize the approved JSON files into a versioned staging install.

Executable/suspicious content must fail closed.

Reject at minimum:
- undeclared ZIP member;
- path traversal;
- absolute/backslash/drive/UNC path;
- duplicate/casefold-colliding member;
- symlink/special/executable metadata;
- encrypted ZIP;
- unsupported schema/version;
- unsupported extension;
- oversized archive/member;
- bad whole-pack hash;
- bad member hash;
- level/supply/metadata identity mismatch;
- invalid LevelData;
- invalid production dimensions/class;
- invalid supply plan/conservation;
- any executable-looking payload surface prohibited by the canonical content boundary.

No member is loaded as a Godot Resource or executed.

---

# 6. PREVIEW POLICY

Current `.scrubpack` V1 contains LevelData + supply plan + metadata, not a preview image.

Do not invent a remote preview member.

For remote catalog entries in this V1 runtime:
- preview path may be empty;
- existing placeholder/fallback behavior remains;
- absence of a preview must not block gameplay.

If the pack format later gains a versioned preview contract, that is a separate schema evolution.

---

# 7. LOCAL REGISTRY + LAST-KNOWN-GOOD — CP05

Implement a versioned local content registry under `user://content/`.

Registry must include enough immutable evidence to reconstruct/validate the active set:
- schema/version;
- active content_version;
- canonical manifest digest;
- exact installed pack identities/hashes/lengths;
- ordered remote level IDs;
- installed paths;
- activation timestamp only if injected/needed, never for identity;
- compatibility version if needed.

Rules:
- write candidate registry to temp/staging first;
- activate with an atomic/replace-safe boundary;
- never delete the only known-good set before replacement is fully validated;
- interrupted install leaves active registry untouched;
- partial/corrupt candidate is cleaned/quarantined without harming LKG;
- keep at least current LKG plus the candidate transaction until commit completes;
- cache retention may prune older inactive versions only after active/LKG safety is proven.

Cold boot:
1. builtin content is always available independently;
2. validate active cached registry/set;
3. if valid, expose cached remote levels immediately/offline;
4. remote network refresh happens separately;
5. fetch/server/hash/parse failure keeps cached LKG;
6. corrupt registry/cache fails back to builtin content rather than blocking app startup.

First-ever launch with no network:
- builtin 1–10 playable;
- no crash;
- no fake remote success.

---

# 8. CATALOG / GAMEPLAY BRIDGE — CP04-009

Do not weaken the existing builtin `LevelCatalog` `res://` confinement.

Prefer a separate remote/runtime catalog plus a composite read model.

Required behavior:
- builtin `LevelCatalog` still validates `res://data/levels/catalog/production_catalog_v1.json` exactly as today;
- remote catalog reads only paths issued by the validated active registry under `user://content/`;
- composite view returns immutable/deep-copy entries;
- builtin and remote IDs cannot collide;
- remote orders are assigned by the V1 campaign-order policy above;
- `GameplayLaunchResolver` resolves frontier 1–10 to builtin and 11+ to active remote when available;
- `AppState.orders_context()` sees the composite playable order set;
- remote content cannot mutate progression/economy/save truth;
- if frontier points to remote content not present/valid, return truthful `CONTENT_MISSING`, never run another level under the wrong number.

The production gameplay host must continue to load the exact resolved LevelData + exact resolved supply plan.

---

# 9. RUNTIME REFRESH LIFECYCLE

Remote content is optional to application boot.

Recommended behavior:
- boot app/home from builtin + cached LKG first;
- start one remote refresh when runtime is configured/enabled;
- prevent concurrent duplicate refresh transactions;
- expose read-only status such as:
  - disabled;
  - idle;
  - checking;
  - downloading;
  - validating;
  - updated;
  - offline_using_cache;
  - failed_using_cache;
- no modal spam is required for V1;
- failure is diagnostic, not fatal to builtin/cached play.

Do not refresh per frame or on every screen transition.

---

# 10. ANDROID / INTERNET CAPABILITY

CP04 requires the Android family build eventually to have network permission.

Do not silently produce/distribute the APK in this task.

If an Android export preset already exists, validate/configure the Godot 4.7.2 INTERNET permission correctly and keep signing secrets out of Git.

If no Android preset exists yet:
- implement/test the runtime;
- record CP04-011 as `READY_FOR_ANDROID_EXPORT_GATE`;
- the later Family APK task must create the preset and prove INTERNET permission before CP04 final release closure.

Desktop/headless tests use injected fake transport/local fixtures and must not need the public internet.

---

# 11. SECURITY / RESOURCE LIMITS

Use conservative constants and explicit failure reasons.

At minimum:
- manifest <= 1 MiB;
- JSON member <= 1 MiB unless canonical contract says smaller;
- scrubpack <= 256 MiB;
- <= 4096 ZIP members;
- bounded nesting/collection/string sizes;
- no ZIP64/unsupported archive tricks if not explicitly validated;
- no unbounded memory amplification;
- no path escape from `user://content/`.

Never log:
- secrets;
- tokens;
- raw sensitive device data.

No publisher credentials exist in runtime at all.

---

# 12. TEST PLAN

Create permanent focused suites for CP04 and CP05.

Use injected fake transport and deterministic bytes. No external network dependency.

## CP04 tests

Must cover:
- HTTPS-only;
- valid manifest parse;
- duplicate-key rejection;
- unknown-field rejection;
- non-finite/limit rejection;
- schema/version mismatch;
- app-version too old;
- monotonic content_version;
- same-version/different-bytes rejection;
- exact missing-pack calculation;
- no redundant download;
- byte-length mismatch;
- pack SHA mismatch;
- safe ZIP member contract;
- traversal / absolute / backslash / duplicate / symlink / executable member rejection;
- member SHA mismatch;
- malformed/future pack schema rejection;
- executable-looking JSON rejection;
- LevelData validation;
- ProductionLevelValidator validation;
- SupplyPlanLoader validation;
- pack/level identity mismatch;
- builtin ID collision rejection;
- manifest-declared remote order;
- no numeric-suffix sorting;
- append-only successor acceptance;
- reorder/removal successor rejection;
- unsupported disabled/schedule candidate retains LKG;
- GameplayLaunchResolver resolves builtin then remote correctly;
- frontier missing remote content stays CONTENT_MISSING.

## CP05 tests

Must cover:
- first launch no network => builtin works;
- valid cached LKG offline boot;
- manifest fetch failure => LKG;
- server error => LKG;
- corrupt active registry => builtin fallback;
- corrupt candidate cannot replace LKG;
- interrupted download cleanup;
- interrupted staging cleanup;
- atomic registry activation;
- relaunch reconstructs same remote catalog;
- partial cache after app update;
- app downgrade / minimum version mismatch retains compatible behavior;
- only known-good set never deleted before replacement validates;
- cache retention never removes active/LKG;
- repeated refresh idempotent.

## Existing regression

Run at minimum:
- `tests/m35_level_catalog.gd`;
- `tests/m37_level_progression.gd`;
- M40 save suites;
- M52 supply plan / gameplay suites;
- M53 content/difficulty suites;
- M43 Daily/order-context regression;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained `SCRIPT ERROR`.

---

# 13. END-TO-END FAMILY FIXTURE

Build a local, deterministic test fixture that models:

- builtin Levels 1–10 remain in `res://`;
- remote manifest content_version N contains synthetic valid Level 11–12 pack;
- fake transport downloads it;
- runtime activates it;
- progression frontier 11 resolves remote level 11;
- relaunch offline still resolves 11;
- successor N+1 appends 13;
- only the new/missing pack downloads;
- a malicious/corrupt N+2 fails and N+1 remains active.

This fixture is local test data only; do not invent the owner's real Level 11–50 content.

---

# 14. LOGGING / EXECUTION MODEL

Execute CP04 then CP05 continuously in one master run after the external gate passes.

Write child logs under:
`coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/`

Suggested:
- `SB-CP04-001_014_CLAUDE_LOG_V01.md`
- `SB-CP05-001_012_CLAUDE_LOG_V01.md`
- `REMOTE_CONTENT_RUNTIME_MASTER_CLAUDE_LOG_V01.md`

Each log records:
- starting local/main SHA;
- external contract/gate SHA/evidence;
- files changed;
- exact runtime architecture;
- security boundaries;
- test commands/results;
- fixtures;
- CP04/CP05 requirement disposition;
- remaining Android/CDN/CP06 gates;
- final commit SHA.

Do not edit root `TASKS.md`.

Push to `main` if permitted. Otherwise push one branch and report exact head/ahead-behind with a safe integration instruction.

Finish exactly:

`AWAITING_GPT_REMOTE_CONTENT_RUNTIME_V01_AUDIT`
