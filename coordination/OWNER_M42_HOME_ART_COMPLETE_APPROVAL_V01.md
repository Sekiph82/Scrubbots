# OWNER M42 HOME ART — COMPLETE VISUAL APPROVAL V01

Status: OWNER APPROVED / 49 OF 49 UNIQUE GENERATION-REQUIRED ART FILES
Date: 2026-09-25
Scope: M42 Home art owner gate

The owner completed visual review of every unique generation-required Home ART file currently declared by `assets/ui/HOME_ASSET_MANIFEST.json`.

Approved unique generation-required IDs (49/49):

`HOME-001, HOME-002, HOME-003, HOME-004, HOME-006, HOME-007, HOME-010, HOME-011, HOME-013, HOME-014, HOME-015, HOME-016, HOME-018, HOME-019, HOME-020, HOME-021, HOME-022, HOME-023, HOME-024, HOME-026, HOME-027, HOME-031, HOME-032, HOME-034, HOME-035, HOME-042, HOME-043, HOME-051, HOME-054, HOME-062, HOME-063, HOME-064, HOME-065, HOME-066, HOME-067, HOME-068, HOME-069, HOME-078, HOME-086, HOME-090, HOME-091, HOME-092, HOME-093, HOME-094, HOME-101, HOME-102, HOME-103, HOME-104, HOME-105`.

Batch evidence:
- `coordination/OWNER_M42_HOME_ART_BACKGROUND_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_CENTRAL_WORLD_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_ENVIRONMENT_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_HELPER_BOTS_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_SCRUBBY_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_TOP_HUD_CURRENCY_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_GIFT_SHORTCUTS_A_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_SHORTCUTS_B_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_PLAY_REWARD_TRACK_APPROVAL_V01.md`
- `coordination/OWNER_M42_HOME_ART_BOTTOM_NAV_APPROVAL_V01.md`

`HOME-087 / win_streak_reward_scrub_bucks_icon` is not an independent visual. It is a declared manifest reuse of the exact same repository file as owner-approved `HOME-042 / icon_currency_scrub_bucks`. Therefore the visual approval of HOME-042 covers HOME-087's reuse of those same bytes; no second visual review is required.

Next technical step is deterministic manifest promotion:
1. verify the current Git blob for every approved path still equals the blob recorded in its owner approval artifact;
2. compute SHA-256 from the actual PNG bytes;
3. set the corresponding manifest ART entries to `APPROVED` and store `approved_sha256`;
4. do not modify, regenerate, recompress, rename or overwrite any approved PNG;
5. run manifest/lifecycle/Home/root regression tests before any tracker closure.

This document clears the visual-selection portion of the Home ART owner gate. It does not by itself close SB-M42-017 final composed Home visual review on a running build.
