# SB-CP04-001..014 (M15) — REMOTE CONTENT RUNTIME — CLAUDE LOG V01

Prompt: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_MASTER_PROMPT_V01.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Gate: `CHATGPT_CP03_M14_GATE_ACCEPTANCE_V01.md`

Root `TASKS.md` was read only and not edited. Status: implementation claim, awaiting ChatGPT audit. Sync, gate evidence and the final SHA are in the master log.

## Runtime architecture (`scripts/content_runtime/`, game-owned, no Factory/publisher code)

| File | Responsibility |
|---|---|
| `remote_content_manager.gd` | **The one `RemoteContentManager`.** Orchestration and state only: boot (LKG), one refresh transaction, missing-pack diff, install, registry activation, retention, read-only `status()`. |
| `https_content_transport.gd` | Production transport. HTTPS GET only; certificate-validating default TLS; `max_redirects = 0` (a redirect can never downgrade); body capped (manifest 1 MiB, pack = exact `byte_length`); timeout; no credentials. A Node, because `HTTPRequest` must be in the tree. |
| `content_manifest_v1.gd` | Strict mirror of the closed LF `scrubbots.content.manifest.v1` contract: `manifest_parser.py` limits, `manifest_v1.py` fields/grammars and `manifest_validation.py` reference / membership checks. Pure functions. |
| `scrubpack_v1.gd` | Read-only `.scrubpack` V1 inspector. Own ZIP central-directory walk (Godot's `ZIPReader` hides entry metadata); LF `inspection.py` entry rules; LF `payload_validation.py` member contracts; then the **current game validators**. |
| `strict_json.gd` | RFC 8259 reader for untrusted bytes. Godot's `JSON` keeps the last duplicate key and makes every number a float, so this reader is used at the trust boundary instead (details under Security). |
| `composite_level_catalog.gd` | Builtin `LevelCatalog` + the verified active remote set, with the same consumer surface and deep copies. |

**Transport seam.** The production transport is injected by `main.gd`; tests inject `FakeTransport`. Both expose:
- `fetch_manifest() -> {ok, reason, bytes}`
- `fetch_object(object_key, part_path, max_bytes) -> {ok, reason}`

**Config** `data/config/remote_content_runtime_v1.json` holds only non-secret values:
- `enabled: false`, and an empty `manifest_url` / `object_base_url`;
- the supported manifest schema/version (v1) and scrubpack schema/version (v1);
- the timeout and the manifest / pack / cache byte caps.

A malformed config, a non-HTTPS URL, or an empty endpoint means remote is disabled. Builtin play is unaffected.

**Game version.** It is read only from `ProjectSettings["application/config/version"]`, with the strict LF `MAJOR.MINOR.PATCH` grammar. That key is **absent in the repo today**, so production refresh and cached exposure both fail closed with `GAME_VERSION_UNAVAILABLE` / `CACHE_INVALID_CURRENT_GAME_VERSION`. The Family APK task sets it. Tests inject versions.

## Integration (narrow)

**`AppState`:**
- owns `content` (one manager);
- adds `playable_catalog()`, which builds a `CompositeLevelCatalog`;
- `orders_context()` now uses the composite, and its cache is invalidated on `content_changed`.

The content root is `user://content/` for the canonical save. A test save path gets its own isolated sibling directory, so tests never touch the real cache.

**`GameplayLaunchResolver`:** the default catalog is now `app_state.playable_catalog()` (with a fallback for plain test doubles). Explicit-catalog injection is unchanged, and `CONTENT_MISSING` / `CATALOG_INVALID` keep their semantics.

**`main.gd` `_start_remote_content()`:** starts one fire-and-forget refresh per cold launch, only when the config is enabled. Boot never awaits it. On `content_changed`, Home re-reads its launch truth.

**Unchanged:** `LevelCatalog` (`res://` confinement, explicit orders), `LevelLoader`, `ProductionLevelValidator`, `SupplyPlanLoader`, the gameplay host, the save and economy code.

## Security boundaries

**Writes.** Remote bytes are written only under the content root (production `user://content/`). Every recursive delete is confined to that root.

**Pipeline.** Nothing is ever loaded as a `Resource`, imported or executed. The archive is STORED-only, so member bytes are exact slices of the SHA-verified archive. The order is:
1. download to `downloads/<tx>.part` (body capped at the declared `byte_length`);
2. exact length check;
3. whole-pack SHA-256;
4. ZIP structural checks;
5. `pack.json`;
6. per-member SHA-256;
7. member payload contracts;
8. game validators;
9. materialize to `staging/<tx>/`;
10. rename into `packs/<pack_id>/<version>-<sha256>/`;
11. registry commit (CP05 log).

**ZIP checks (`scrubpack_v1.gd read_zip`).** Fail closed on each of these:
- **Container shape:**
  - EOCD must end the file exactly (no comment, no trailing bytes);
  - no multi-disk archive;
  - no ZIP64 marker;
  - 1..4096 entries;
  - the central directory must be contiguous.
- **Entry metadata:**
  - encrypted entries (flag bit 0 / strong-encryption bit 6);
  - any method other than STORED;
  - compressed size different from uncompressed size;
  - members over 1 MiB;
  - a host system other than DOS or Unix;
  - a Unix type other than a regular file (symlinks, devices, …);
  - any exec bit (0o111);
  - the DOS directory or reparse attribute.
- **Local header vs central record:**
  - the local header must match the central name byte for byte;
  - the local method must be STORED and unencrypted;
  - entry data must stay before the central directory;
  - entries must not overlap.
- **Member names:**
  - non-ASCII names;
  - duplicate or casefold-duplicate names;
  - anything outside the exact V1 layout: `pack.json` first, then levels in ASCII order, each as `level.json` / `supply-plan.json` / `metadata.json`. This rejects traversal, absolute, backslash, drive and UNC paths, unknown extensions and directory entries.

**Payloads.**
- **Shared rule (every member and `pack.json`):** strict JSON with the LF payload limits. The LF executable-surface regexes are applied to every key and value; they catch script/expression/resource/command keys, `res://` / `user://`, `load(` / `preload(` / `eval(`, and `.gd/.tscn/.so/...` values.
- **Level / supply / metadata:** closed field sets with exact int and string types, mirroring LF `_valid_level`, `_valid_supply_plan` and `_valid_metadata`.
- **Game authority:**
  - `LevelLoader.load_from_text` (the same `LevelValidator` path the host uses later);
  - TEST rejection;
  - `ProductionLevelValidator`;
  - the square-shell gate (`LevelCatalog.square_shell_error`);
  - `SupplyPlanLoader.build_engine` via the same Godot-JSON parse path as runtime `load_plan`: exact conservation and the cid map.
- **Cross-file identity:**
  - `level.id` = member id;
  - `supplyPlan.levelId` = id;
  - metadata `id`, `width`, `height` = the level's;
  - metadata `columnCount` = the plan's;
  - `packId` / `packVersion` = the manifest pack;
  - the pack's level set = exactly the manifest levels assigned to that pack.

**Strict JSON.**
- **Encoding:** strict UTF-8 (overlong, surrogate and truncated sequences rejected) and an **exact decode round trip**. Godot silently strips a BOM and truncates at NUL; both are rejected and covered by tests.
- **Structure and values:**
  - duplicate keys rejected, even when the values are equal;
  - integers stay integers, and an integer over 18 digits fails closed;
  - non-finite numbers rejected;
  - control characters and lone surrogate escapes rejected.
- **Limits:** depth, item count, string length and byte size are all capped.

**ID grammars** use full-match semantics. PCRE `$` would accept a trailing `\n`; a test proves it is rejected.

**No secrets.** There are no credentials, tokens, account IDs or upload/mutation APIs. Nothing sensitive is logged; the manager prints nothing.

## Manifest policy implemented (prompt §3–§4)

**Compatibility gate** (in this order):
1. strict parse;
2. `minimum_game_version` against the canonical app version;
3. `content_version`:
   - lower → `CONTENT_VERSION_NOT_INCREASED`;
   - equal with different bytes → `MANIFEST_MUTATION`;
   - equal and identical → `UP_TO_DATE`, or a repair when the local set is broken.

**Before download:**
- non-empty `disabled_levels` or `schedules` → `UNSUPPORTED_RUNTIME_SEMANTICS`, LKG retained (CP06);
- a builtin ID collision (casefold) → `BUILTIN_ID_COLLISION`;
- the activated remote sequence must be an exact prefix with the same `level_id` and the same `pack_id`, otherwise `REMOTE_SEQUENCE_NOT_APPEND_ONLY` (reorder, removal or reassignment);
- the cache cap (CP05-007) is checked.

**Remote order** is the manifest `levels` array order, appended after the highest builtin order. It is never derived from file names, numeric suffixes, sorting or pack order. Remote content can never replace builtin Levels 1–10.

**Missing-pack diff** compares the exact 5-field identity (`pack_id`, `pack_version`, `object_key`, `sha256`, `byte_length`) with the active registry, and re-hashes the installed files before reuse. Identical verified packs are never downloaded again.

**Preview.** No preview member is invented. Remote entries have `preview_path = ""` and `preview_exists = true`, so they behave exactly like a builtin entry with no preview: the existing placeholder applies.

## Requirement disposition (canonical text: LF `TASKS.md` §CP04)

| ID | Requirement | Disposition / evidence |
|---|---|---|
| SB-CP04-001 | RemoteContentManager | IMPLEMENTED — `remote_content_manager.gd`; owned by `AppState.content` |
| SB-CP04-002 | Fetch production manifest over HTTPS | IMPLEMENTED — `HttpsContentTransport` (HTTPS-only, no redirects, capped, timeout); c01 |
| SB-CP04-003 | Compare remote/local content versions | IMPLEMENTED — c07, c08 |
| SB-CP04-004 | Missing packs without redundant downloads | IMPLEMENTED — c09, family f05, k15 |
| SB-CP04-005 | Download to `user://content/`, never `res://` | IMPLEMENTED — `.part` → staging → `packs/`; c10, k07 |
| SB-CP04-006 | Verify SHA-256 | IMPLEMENTED — whole-pack + per-member; c11, c13 |
| SB-CP04-007 | Validate pack/schema/level before activation | IMPLEMENTED — c12, c14–c19 |
| SB-CP04-008 | Activate preserving last-known-good | IMPLEMENTED — CP05 log; c08, c23, c24, family f06 |
| SB-CP04-009 | Expose remote levels via narrow interface | IMPLEMENTED — `CompositeLevelCatalog`, resolver, `orders_context`, gameplay host; c21, c25–c27, family f03 |
| SB-CP04-010 | Generator/publisher code out of runtime | IMPLEMENTED — no Python/LF code copied; the runtime mirrors contracts only |
| SB-CP04-011 | INTERNET permission when runtime enabled | **READY_FOR_ANDROID_EXPORT_GATE** — the repo has no tracked Android preset (`export_presets.cfg` is gitignored; any owner-local preset is not visible to this run). Runtime is config-disabled. The Family APK task must create the preset, prove INTERNET permission and set `application/config/version`. No closure is claimed. |
| SB-CP04-012 | Failures never block offline play | IMPLEMENTED — c10, c11, k02–k06, family f04 |
| SB-CP04-013 | App/content version compatibility tests | IMPLEMENTED — c07, k12 |
| SB-CP04-014 | Reject executable remote artifacts | IMPLEMENTED — c12, c15, family f06 |

## Tests

**`tests/cp04_remote_content_runtime.gd` → PASS 28/28 cases** (c01–c28 as named in the prompt's CP04 list), 0 `SCRIPT ERROR`.

- **Expected warning:** c05 feeds `1e999`, so Godot prints one "Exponent too high" warning before the value is rejected as non-finite.
- **Fixtures:**
  - `tests/support/scrubpack_fixture.gd` is a test-only, deterministic canonical STORED ZIP builder (CRC32, Unix 0644, DOS epoch, no extras) plus `FakeTransport`;
  - `tests/fixtures/remote_content/content-manifest-minimal.json` is copied byte-exact from LF.
- **Synthetic levels:** each is a builtin production level and plan, re-identified, plus LF-schema metadata.

**Cross-implementation evidence** (run locally against LF main `16ee1f3`; reproducible with `tests/tools/export_remote_content_fixture.gd`):
- **Game fixture → LF tools:** LF `parse_content_manifest_v1` accepts the game fixture manifest. LF `inspect_scrubpack` returns `VALID` for both fixture packs, and the SHA-256 and lengths match.
- **LF tools → game runtime:** a pack built by LF's own `build_scrubpack`, with a manifest serialized by LF `ContentManifestV1.to_json_bytes`, is accepted by this runtime unchanged: `ACTIVATED`, levels `[family_level_011, family_level_012]`.

READY_FOR_INDEPENDENT_AUDIT — SB-CP04-001..014
