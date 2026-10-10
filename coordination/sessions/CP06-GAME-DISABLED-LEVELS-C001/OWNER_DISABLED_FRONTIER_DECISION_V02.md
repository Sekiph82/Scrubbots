# OWNER DECISION V02 — CP06 Disabled Frontier: OPTION B (SKIP)
Date: 2026-10-10
Owner decision in conversation: "B sikki daha mantikli." This expressly selects **B, explicit non-rewarding skip** instead of A hold or C in-place replacement.

## Authorized product outcome
If and ONLY if a verified, ACTIVE, versioned remote manifest explicitly lists the player's remote frontier level ID in `disabled_levels`, gameplay does not load that level. It is skipped and the player continues at the next legitimate numbered level. The old catalog order, original level IDs, packs and SHA identities remain stable. Example: owned frontier Level 12 disabled -> next Level 13, **not** "Level 13 displayed as Level 12".

The skip is **neither a win nor a loss**. It must never manufacture a first-clear, trigger a Results/WON ceremony, grant Scrub Bucks, Hearts, Bot Parts, cards, boosters, paid entitlements, streak rewards, achievements or Daily task progress. Conservatively leave the pre-existing win streak **unchanged** on a skip: neither increment nor reset. This is a safety-preserving operational default of the owner-selected non-rewarding B behavior; do not add a streak reward/event. If existing code cannot preserve this without a new business rule, stop with precise owner question.

## Forward-only history, re-enable and persistence
- Create a distinct versioned **skipped-level ledger** separate from completed first-clears, recording at least canonical numeric order, exact level ID, active manifest content_version and cryptographic manifest identity. Save/migration serialization must preserve existing V1 saves and all unrelated settings/economy. Only one versioned authority in the existing LevelProgressionService/SaveService; do not create a parallel mutable campaign tracker.
- Accepted shipping progression history uses `completed ∪ skipped == 1..current_level-1`, with **exactly disjoint sets**, valid integer order, sorted uniqueness, no forged first-clears, validated skip provenance and strict future-schema rejection. Legacy V1 saves migrate to empty skipped ledger; preserve original first-clears/current frontier. Save failures never advance the persisted frontier and must roll back skip state; retry safe/idempotent on relaunch.
- If an already skipped level is re-enabled later, **do not rewind the existing player's frontier**, do not silently convert it to a win, never double-grant and never introduce Level Select. The skipped provenance remains visible in audit/history. New players and players still before it can play it normally when it is enabled. Replaying skipped levels is a separate future owner decision.
- Skipping multiple consecutive disabled remote levels is deterministic, bounded, one number at a time, never beyond the verified declared catalog. Missing, unverifiable, incompatible, failed network / cache content is **not** a valid reason to skip. Built-in Levels 1–10 cannot be disabled/skipped by remote manifest. Nonempty `schedules` remain an unsupported separate CP06 gate.

## UX transparency without new economy
A succinct nonrewarding message may state the actual skipped level number and that play continues at the next valid level. Never show a victory, compensation reward, forced ad, level-select grid or mislabeled level. Preserve disabled IDs in the canonical catalog order rather than removing entries and shifting numbering.

## Owner execution policy
Claude works solely in `C:\Users\sekip\Desktop\ScrubBots`; **ZERO TEMP files/folders/worktrees/copies of any size** on the owner's PC. Preserve owner-dirty files, owner untracked and stashes. No new APK/IPA, cloud R2 publication or LF code. Tests that write `user://` outside Desktop are prohibited until separately authorized; report blocked validation rather than silently executing. No unapproved GitHub Actions run is implicit in choosing product option B.

This decision authorizes the **B gameplay design** and preparation of the code and test changes, not claiming successful QA before real evidence. ChatGPT alone edits root TASKS.md and independent audits.
