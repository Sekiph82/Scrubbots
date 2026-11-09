# Review round 1 - 132-release-gates-audit

Ran: m60_release_gates PASS 6/6 (001/003/004 PASS, 005/006 FAIL as reported); m43_c001b_won_results_visual PASS 11/11. Import churn reverted in the worktree.

## Checked OK
- Manifest: no status field changed anywhere in the diff. Only production_scene / evidence / live_data / gap / recorded_by and insufficient_sb registry_ids. No OWNER_ACCEPTED claims. Ranks gap text correctly says the two-table RANKS (SB-M43-131..133, still READY/open in TASKS) is not built; 005 FAIL reason is accurate.
- Registry: home.scrub_bucks_plus -> popup:scrub_bucks and new ids/routes backed by m60 route walk (all 27 routes land).
- TASKS: rows OWNER, SB-M43-170 left [ ], 002/005/006 left open, only 001/003/004 checked with evidence; no owner acceptance claimed. Owner-only gates BLOCKED, nothing submitted.

## Must-fix
1. assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json: for profile, achievements, events_main (3 entries, plus event_detail if touched) the recorded_by line "factory 075 (Claude): master approved by Claude under owner-delegated authority 2026-10-31, not owner visual review" was overwritten with the generic factory 132 text. Those entries keep status MASTER_OWNER_APPROVED, so the provenance that the approval was Claude-delegated, not owner, is now lost from the manifest (only the TASKS note keeps it). Restore the 075 provenance wording (append the factory 132 fact note after it rather than replacing it). The generated RELEASE_GATES.* may embed this; rerun --write if it does.

## Design concern (coupling to --write)
Real: job 133-worlds-table is in flight and will change world_unlock_transition (live/gap/maybe status) in the same manifest, and other jobs touch manifest statuses. Each such change turns m60 red in CI until someone runs --write and commits docs/RELEASE_GATES.*. Acceptable only with mitigation (non-blocking, recommended): compare only gate verdicts + counts (PASS/FAIL/BLOCKED per gate, OPEN/CLOSED, not-accepted / MASTER_REQUIRED / not-built / not-live id lists) against the committed JSON, and let narrative/evidence text differ; or make the stale check print a one-line "run --write" hint and only fail when a gate verdict changes. Since 133 will legitimately flip world_unlock_transition from not-live to live, whoever merges second must rerun --write; note this in the 133 job.

## Non-blocking
- Suite takes ~2-3 min locally (10 app boots + L1..L3 play); fine for the CI list.

VERDICT: CHANGES
