# SB-M43-155 — CLAUDE LOG V01

Child: **SB-M43-155** — "Implement explicit cloud conflict resolution using revision/timestamp/progression/economy safety rules; never silently duplicate currency/rewards."
Parent: M43-C013 — Account / Cloud Save / Cross-Device Recovery
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `8e717a4` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- TASKS M43-C013 rows; M40 save contract (scripts/save/save_service.gd); CLAUDE.md §3.6 (no unauthorized SDK / service)

## Implementation

| File | Change |
|---|---|
| `scripts/save/cloud_save.gd` | **new** provider-neutral envelope, superset/conflict resolution (never merges currencies), restore through M40 validate/migrate/apply |
| `tests/m43_master_c011_c014.gd` | s01–s03 |

Shared C013 implementation (one commit).

## Tests

`tests/m43_master_c011_c014.gd` → **PASS 18/18**. This lane:
s01 no network / platform SDK in the save path.
s02 local-ahead keeps local; remote-ahead taken; equal keeps local; diverged copies (each holding a reward tx the other lacks) → explicit conflict carrying both summaries, never merged; future / malformed remote ignored.
s03 restore of a cloud envelope onto a fresh device: economy + progression byte-identical (Collection card, unlocked Moppy, 2 Tornado, timed 2x, claimed Daily); the restored Daily claim cannot be repeated; a corrupt copy is refused and leaves the device untouched.


## Regression

Shared C010–C014 checkpoint (37 suites + root): m43_master_c010_meta 12/12, m43_master_c011_c014 18/18, m43_master_c009_daily 12/12, m43_master_c008_robots 10/10; closed m42_home, m42_home_composition 9/9, m42_home_v04 18/18, v05 13/13, v06 13/13, v07_safe_area 9/9, m42_navigation, m42_c003_scrubby_animation 18/18; m43_c001a 11/11, c001b 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40; m43_master c005 32/32, c005r 8/8, c005f 10/10, c006 11/11, c007 13/13, c007r 9/9; m43_c005_c008_pack_commit_transaction 27/27; m28_c002_c002_static_shell 16/16; m39a, m39d, m39_v02_atomicity, m39_v03_full_surface, m39_v04_integration, m40_save_system, m40_v03_canonical, m40_v04_bootstrap, m54_collection_set_master_exactly_once, m55_economy_release_regression PASS; root `tests/run_tests.gd` **ALL PASS 5323 checks**; `git diff --check` clean.

**Regression caught and fixed in this lane:** closed `m39e_full_matrix` ("removed economies": the economy snapshot text must contain no `star`) failed once, because the new notification preference key `quiet_start` contains that substring. The keys were renamed `quiet_from` / `quiet_to`, with no rule weakened. After the rename these PASS: m39e_full_matrix, m39_v02_atomicity, m40_save_system, m43_master_c010_meta 12/12 and m43_master_c011_c014 18/18. The root run executed after the rename.


## Runtime evidence

Rendering tool `tests/tools/meta_snapshot.gd` → `META_EVIDENCE CLEAN (0 rejected)` across five viewports; frames under `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-122/`: Profile, Achievements, Events empty, Events with a TEST config (not shipped), Notifications, Welcome Back, Home badges.

## Blockers / gates

None.

## MASTER REMEDIATION V03 — 2026-10-06

Prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_V03.md` · authority: `CHATGPT_MASTER_AUDIT_V01.md`. Baseline `0a7ff02` · remediation code commit `1cbe37f` (handoff: `M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`). The V01 sections above are kept unchanged as history; this section supersedes them where they differ.

**Audit finding.** `resolve()` compared only reward-tx and completed-level sets. It ignored `revision` / `saved_at`, and it called two non-identical saves `equal` when those two sets matched.

**Fix.** `scripts/save/cloud_save.gd` was rewritten. A cloud copy is a WHOLE save and is never field-merged.
- Both envelopes are validated: schema, exact non-negative int `revision` / `saved_at`, string `device`, a `lineage` of at most 64 SHA-256 hex fingerprints, and the M40 `validate_candidate` payload dry-run. A bad remote is `invalid_remote`; a bad local is `invalid_local`.
- Comparison is canonical: integral floats become ints (JSON round trip), dictionary keys are sorted, order-free id sets are sorted, and a SHA-256 fingerprint is taken.
- `equal` is returned **only** on exact canonical payload equality.
- If only presentation data differs (device `settings` or the `meta_ui` acknowledgements), the result is `keep_local / same_authority`, never `equal`.
- If the tx and progression sets are identical but any authoritative economy section differs (wallet, Collection, robots, boosters, Daily, …), the result is `conflict / same_history_economy_differs`. Balances are never treated as newer, because a spend lowers them legitimately.
- A strict descendant wins whole only when all four hold:
  1. its tx and progression sets are supersets;
  2. every append-only history is a superset (robot unlocks, win-streak processed levels, gift tx, claimed set rewards, Master claim, pack receipts); otherwise `history_contradiction`;
  3. its revision is strictly higher and its `saved_at` is not older; otherwise `order_contradiction`;
  4. **ancestry proof**: the other side's exact authority fingerprint appears in its `lineage`; otherwise `no_ancestry_proof`.
- Everything else is `conflict / diverged`. A conflict carries only the two recomputed summaries; the stored summary is never trusted.
- `envelope(..., previous)` records lineage from the last synced copy.

The ancestry rule closes a hole the new tests exposed. Without it, a device that *spent* SB after the fork lost to a remote copy with more history, which silently refunded the spend.

**New / updated tests** (`tests/m43_master_c011_c014.gd`):
- **s02**: updated so the descendant carries lineage; still PASS.
- **s04**:
  - exact equality → `equal`, including a JSON round-tripped copy;
  - local and remote strict descendants → `keep_local` / `take_remote`;
  - same tx + progression but a different wallet (spend −100, credit +500), Collection copy, robot unlock, booster inventory or Daily state → `conflict` in BOTH directions;
  - settings-only difference → `same_authority`.
- **s05**:
  - descendant with a lower revision, equal revision, or older `saved_at` → `order_contradiction`, both directions;
  - same `saved_at` with a higher revision → coherent;
  - remote with more tx but lacking the local robot unlock → `history_contradiction`;
  - tx-only vs progression-only divergence → `diverged`.
- **s06**: 14 malformed / future envelopes rejected on both sides (future schema, future payload version, string / fractional / negative revision, missing / NaN `saved_at`, non-string device, missing / non-hex / oversized lineage, non-object payload, corrupt tx ids, removed economy), plus null / string remotes.
- **s07**:
  - a local spend of 300 SB vs a remote built on the pre-spend state → `no_ancestry_proof` conflict;
  - the decision carries summaries only;
  - an untouched device takes the remote descendant;
  - a copy built on the spent state is a proven descendant in both directions;
  - restore applies the remote copy byte-for-byte: a device's own +777 SB is not merged;
  - the resolver has no credit / debit / grant / merge call.

`tests/m43_master_c011_c014.gd` → **PASS 28/28** (18 V01 cases kept or updated, plus 10 new). Regression: see `M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-155
