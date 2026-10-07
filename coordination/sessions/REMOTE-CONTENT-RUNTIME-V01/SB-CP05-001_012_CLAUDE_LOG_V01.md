# SB-CP05-001..012 (M16) — OFFLINE CACHE / LAST-KNOWN-GOOD — CLAUDE LOG V01

Prompt: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_MASTER_PROMPT_V01.md` §7, §9
Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit.

## Local layout (content root; production `user://content/`)

| Path | Purpose |
|---|---|
| `registry_v1.json` | the active set = last-known-good (schema `scrubbots.content.registry.v1`, version 1) |
| `registry_v1.prev.json` | the previous LKG registry, kept as rollback evidence |
| `registry_v1.json.tmp` | candidate registry, renamed over the active one at commit |
| `packs/<pack_id>/<pack_version>-<sha256>/levels/<id>/{level,supply-plan,metadata}.json` | content-addressed installed packs (only the approved JSON members) |
| `downloads/<tx>.part` | in-flight download; never read before the length check and full verification |
| `staging/<tx>/pack/` | materialized candidate pack before the rename into `packs/` |

**Registry fields:**
- `schema`, `version`;
- `content_version`;
- `manifest_sha256`: the digest of the exact manifest bytes;
- `minimum_game_version`;
- `validated_game_version`: the app version that validated the set;
- `packs`: the exact 5-field identities;
- `levels`: in manifest order, each with `level_id`, `pack_id`, `difficulty`, `width`, `height` and the SHA-256 of all three files.

Installed paths are derived from the pack identity, never read from the registry, so a registry cannot point outside the root. There is no timestamp in the identity. Parsing is strict: closed fields, exact types and grammars.

## Lifecycle

**Cold boot** (`AppState._init` → `content.boot()`; no network):
1. **Clean interrupted work:** remove `downloads/`, `staging/` and a leftover `.tmp`.
2. **Load the active registry:**
   - **verify the set:**
     - the app version satisfies `minimum_game_version` (it must also be present and canonical);
     - no builtin ID collision;
     - every installed file exists with the registry SHA-256;
     - if the app version differs from `validated_game_version` (app update or downgrade), every level is fully re-validated with the current validators;
   - **any failure:** the remote set is hidden and builtin stays playable. The files are kept.
3. **Prune** pack dirs the active registry does not reference. This runs only when the registry parsed (or none exists); a corrupt registry is never followed by pruning.

**Refresh** (one transaction; the CP04 log covers the checks):
- **Concurrency:** a concurrent call gets `REFRESH_IN_PROGRESS`.
- **Status values:** `disabled`, `idle`, `checking`, `downloading`, `validating`, `updated`, `offline_using_cache` (transport failures) and `failed_using_cache` (all other rejections).
- **On any failure:** the active registry is untouched; this transaction's `.part` and staging are removed; Home keeps builtin + LKG.

**Commit** (`_activate`):
1. The candidate set is fully verified **before** commit (`_verify_set(candidate)`).
2. It is written to `.tmp`, re-read and compared byte-for-value.
3. The current registry is copied to `.prev`.
4. One `DirAccess.rename_absolute(tmp, active)`.
5. The new active set is re-verified; if that ever failed, the `.prev` pointer is restored.
6. Only then are unreferenced packs pruned.

The only known-good set is never deleted before its replacement is verified.

**Cache policy (CP05-007):**
- the installed cache is exactly the active set;
- older or unreferenced packs are pruned after each verified commit and at boot;
- a candidate whose total `byte_length` exceeds `max_cache_bytes` (shipped as 512 MiB) is refused before any download.

## Requirement disposition (canonical text: LF `TASKS.md` §CP05)

| ID | Requirement | Disposition / evidence (`tests/cp05_remote_content_cache.gd` unless noted) |
|---|---|---|
| SB-CP05-001 | Local content registry under `user://` | IMPLEMENTED — k09 |
| SB-CP05-002 | Preserve last-known-good manifest/packs | IMPLEMENTED — k06, k09, k13; CP04 c23/c24 |
| SB-CP05-003 | Boot/play cached content offline | IMPLEMENTED — k02, k10; family f04 |
| SB-CP05-004 | Safe fallback on manifest fetch failure | IMPLEMENTED — k03, k04 |
| SB-CP05-005 | Corrupt/incomplete downloads never replace good cache | IMPLEMENTED — k06, k13; CP04 c10/c11; family f06 |
| SB-CP05-006 | Interrupted-download recovery/cleanup | IMPLEMENTED — k07, k08 |
| SB-CP05-007 | Cache size/retention policy | IMPLEMENTED — k13, k14 (prune + 512 MiB cap) |
| SB-CP05-008 | Builtin levels playable independently | IMPLEMENTED — k01, k05; CP04 c26 |
| SB-CP05-009 | First launch no-network test | IMPLEMENTED — k01 |
| SB-CP05-010 | Upgrade with partial/corrupt cache | IMPLEMENTED — k11 (missing file hidden then repaired; 1.0.0→1.1.0 full re-validation; changed byte hidden) |
| SB-CP05-011 | Downgrade/compatibility behavior | IMPLEMENTED — k12 |
| SB-CP05-012 | Never delete only known-good set before replacement validates | IMPLEMENTED — k13, k06 |

## Tests

**`tests/cp05_remote_content_cache.gd` → PASS 15/15 cases** (k01–k15), 0 `SCRIPT ERROR`. The prompt's CP05 list maps to these cases:

| Prompt item | Cases |
|---|---|
| first launch / no network | k01 |
| valid LKG offline | k02 |
| fetch failure | k03 |
| server error | k04 |
| corrupt registry | k05 |
| corrupt candidate | k06 |
| interrupted download | k07 |
| interrupted staging | k08 |
| atomic activation | k09 |
| relaunch same catalog | k10 |
| partial cache after update | k11 |
| downgrade / minimum version | k12 |
| LKG never deleted first | k13 |
| retention keeps active | k14 |
| idempotent + single-flight | k15 |

**`tests/remote_content_family_fixture.gd` → PASS** (end-to-end; see master log).

READY_FOR_INDEPENDENT_AUDIT — SB-CP05-001..012
