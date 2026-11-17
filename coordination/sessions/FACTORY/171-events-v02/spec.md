# 171-events-v02 (SB-EV02-002..014)
Owner 2026-11-17 (chat): "Events'i ben kodlayabilirim demissin; kodla."
Authority (read ENTIRELY first): docs/SCRUBBOTS_24_EVENTS_OWNER_PLAN_2026-11-13.md, data/config/events_v02_catalog.json,
docs/SCRUBBOTS_EVENTS_VISUAL_REFERENCE_INTAKE_2026-11-13.md, docs/SCRUBBOTS_EVENTS_CODEX_EXECUTION_BRIEF_2026-11-13.md,
CLAUDE.md "EVENTS V02 MASTER", TASKS rows SB-EV02-002..014, coordination/OWNER_ECONOMY_REWARDS_V01.md.
Art: Codex delivered PNGs to C:/Users/sekip/Desktop/ScrubBots Events PNG/ (READ ONLY): heroes 24, icons 24,
masters 1, backgrounds 5, decorations 2 (spec expects 7), tutorials 172. Owner decision §0D.1: visual approvals given.
## Do (in this order, commit per finished stage on the branch; final squash not required)
1. Intake: copy the art into assets/ui/final/events/... with a manifest (sha256, source path, event id), optimized to a
   sane mobile size (keep the texture budget; no 4K PNGs in the APK). Missing decorations -> use available ones /
   native fallback, list them.
2. EV02-002/004/006/003: event definitions + instance ids from the catalog, 3-5 active rotation with the documented
   fairness, Level 30 unlock everywhere (L29 locked / L30 unlocked, fresh/old saves), eligibility + milestone semantics,
   completion telemetry from the existing win receipt (no gameplay change; events use ONLY the normal pixel-art
   cleaning gameplay), dedupe per instance receipt, save/restart/migration.
3. EV02-005: deterministic transparent virtual rivals/teams exactly as the plan says.
4. EV02-007: rewards only in EXISTING currencies/items via the existing idempotent RewardGrantService; propose the
   reward tables per the plan (owner pre-approved factory recommendations, not new currencies); stacking cap.
5. EV02-008/009/013: native Godot Events page + cards + details per event id, one reusable 3-stage tutorial component
   (72 states) using a REAL board render, EN/TR, safe areas, Reduced Effects; integrate art with fallbacks.
6. EV02-014: tests — policy/milestone matrix for 24 events, L29/L30 gate, DST/time zone/offline clock, rival integrity,
   idempotent economy, 72 tutorials render, no extra gameplay. New suites in CI with exact guards; full CI list locally.
7. GPU captures (EN/TR) of the Events page, 3 details, 3 tutorials for the owner.
## Must not
No new currencies, no fifth booster, no new gameplay mode, no paid services, no live ops server (local deterministic
schedule only), no changes to level data. Ask (build.md) instead of inventing anything the plan leaves open.
