# Review round 1 - job 126 analytics feature measures

## Checks
- git diff --check origin/main...HEAD: clean
- m56_analytics_taxonomy: PASS 27/27
- m43_personal_ranks x2: PASS 8/8 both runs (flake not reproduced)
- m43_c001a_results_foundation: PASS 11/11
- m43_master_c011_c014: PASS 29/29
- CI guard: android-family-first10.yml lines 59/331-334 say 27/27, matches test output
- m58 inventory: all 10 new events present in PRIVACY_DATA_INVENTORY.md and ANALYTICS_TAXONOMY_V1.md

## Strict points
- continue_from_results wrapper: body unchanged, moved to _continue_from_results; the only signal connection (main.gd:153 continue_requested -> continue_from_results) hits the wrapper, which returns r unchanged; guards and routing live in the inner function. Behaviour identical; the added _track runs after the result is computed. OK.
- Host _meta_terminal: ev_before is built from events.list()/first_try(), which build fresh dicts each call (view()), so there is no aliasing. It is read-only, taken before and used after events.on_progression_terminal; the call order is unchanged. catch-up loop only reads the returned array. OK.
- claim_event_milestone: adds r["milestone"] before _finish (which duplicates r). Additive; failure results carry it too but nobody reads it. Only analytics reads it, on action_committed. OK.
- Analytics are guarded: _track null-checks app_state/analytics; track() is consent-gated and schema-validated, returns false rather than throwing. App_state handlers index r["task_index"]/r["milestone"] only on committed results, where the facade sets them. _track_results_momentum guards momentum ok.
- Params are int/bool/enum only; no ids, PII or timestamps. "metric"/"tier"/"reason" are enums in the taxonomy (m56 PII scan covers every event).
- commit_pack: pity_due read before commit via a pure query; the extra read does not mutate.
- m43_personal_ranks flake: the change adds only analytics.track() in open_ranks, which writes nothing to economy or progression (queue only). The compared snapshot is economy.snapshot() across 30 record_win calls plus the open/close; the track call cannot alter it. Two clean reruns support a pre-existing timing flake. Not caused by this change.

## Findings
None.

## Notes
- The worktree has .import churn from --import (project.godot restored); not part of the branch.
- Weekly/First-Try stay silent in shipped config (no scheduled event), as documented.

VERDICT: PASS
