# SB-EV02-001 Spec: Events V02 source and asset audit

## Job

- Task: `SB-EV02-001`
- Source revision: `origin/main` at `39d65814ab7be53290692c7ab616a732f1499fdf` (branch `main`)
- Isolated worktree: `C:\Users\sekip\.codex\worktrees\scrubbots-events-v02\ScrubBots`
- Scope: read-only audit and a durable evidence report. Do not implement event runtime behavior in this job.

## Binding source documents

Read the complete owner plan, all 24 event definitions, structured catalog, reference intake, and Codex execution brief:

- `docs/SCRUBBOTS_24_EVENTS_OWNER_PLAN_2026-11-13.md`
- `data/config/events_v02_catalog.json`
- `docs/SCRUBBOTS_EVENTS_VISUAL_REFERENCE_INTAKE_2026-11-13.md`
- `docs/SCRUBBOTS_EVENTS_CODEX_EXECUTION_BRIEF_2026-11-13.md`

The master plan controls event identity/rules; the catalog is specification-only (`runtime_enabled: false`, 24 types, 3 tutorial steps, 3–5 active). Events unlock at L30. The optional ChatGPT ZIP is explicitly nonblocking. Keep existing normal pixel-art cleaning as the only gameplay.

## Audit surfaces

Inspect and report the existing behavior and precise deltas for:

1. `scripts/economy/event_service.gd`, `data/config/events_v1.json`, snapshots/import, progress signals, expiry, and reward claims.
2. `scripts/ui/components/ui_event_card.gd`, `scripts/ui/profile/profile_screens.gd`, navigation/deep-link/action gates, and the existing Events UI tests.
3. `scripts/gameplay/runtime/production_gameplay_host.gd`, `scripts/economy/terminal_reward_receipt.gd`, `scripts/economy/player_records.gd`, first-clear transaction, booster-use state, and exact gameplay-authoritative metrics.
4. RewardGrantService/economy snapshot and migration seams, approved reward keys, and any event reward assumptions.
5. `data/config/feature_unlocks_v1.json` and all current L30 guards. Do not change other unlock levels.
6. Existing owner-approved robot sources, rejected legacy art and hashes. Enumerate the canonical robot PNG sources by repository path and SHA-256. Record whether the V02 outputs exist; do not call the legacy images final.
7. Existing import/test tooling and any relevant platform/screenshot constraints.

## Deliverable

Write `docs/SCRUBBOTS_EVENTS_V02_SOURCE_AUDIT_2026-11-13.md` with:

- source revision and clean-worktree provenance;
- subsystem-by-subsystem current behavior, exact gaps and file/line evidence;
- a 24-row event ID/metric/rule compliance inventory against the V02 catalog (no omitted, merged, renamed or replacement types);
- receipt/metric availability and missing authoritative fields;
- L30 gate coverage already present and the still-unverified entry points;
- reward transaction and persistence behavior, with production-payout gate clearly stated;
- canonical robot image paths and SHA-256 values; hashes for the three specified legacy/reference images; explicit status of the optional ZIP;
- inventory/status of the requested V02 hero, icon, shared-background/decoration, and master output paths;
- recommended dependency order across `SB-EV02-002..014`, separating implementation proposals/TBDs from owner-approved values.

Do not create another tracker, modify V1 configuration to stage payouts, modify gameplay/solver rules, enable reward claims, or claim unrun tests/screenshots. Update only the canonical `TASKS.md` EV02-001 row as allowed by the current owner/factory instructions; preserve all task history.

## Acceptance and evidence

- Audit report is present and references the exact source revision.
- Catalog is verified to contain exactly 24 unique stable IDs, 24 expected hero/icon paths, three tutorial definitions each, and exact participant/threshold rules; any TBD field remains labeled a proposal/TBD.
- The current service/UI/receipt/reward/unlock behavior is supported by source references rather than inference.
- Robot reference hashes are generated from checked-out bytes, and paths include only canonical source PNGs (not `.import` files, legacy draft art, or generated identity substitutes).
- V02 final assets are reported by actual existence, dimensions/hash when present, and never inferred from plan paths.
- `git diff --check` passes. No code test is needed for this documentation-only audit; if any suite is run, report its exact command and result.
- Final diff contains only the audit deliverable, necessary factory evidence and narrowly scoped root `TASKS.md` status update.
