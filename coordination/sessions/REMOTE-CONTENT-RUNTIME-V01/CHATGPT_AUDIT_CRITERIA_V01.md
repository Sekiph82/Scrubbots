# SCRUBBOTS — CP04/M15 + CP05/M16 REMOTE CONTENT RUNTIME — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-06

## Start gate / governance
- [ ] CP03/M14 strict final PASS/CLOSED was verified before implementation.
- [ ] Builder used owner-local C:\Users\sekip\Desktop\ScrubBots and synced non-destructively.
- [ ] Owner-local work preserved.
- [ ] Root TASKS.md untouched by builder.
- [ ] No reset/clean/force overwrite.

## Architecture
- [ ] One game-owned RemoteContentManager orchestration authority.
- [ ] Provider-neutral injected transport seam.
- [ ] Production transport is HTTPS-only and contains no publisher credentials.
- [ ] Publisher/Factory code is not shipped/copied into gameplay runtime.
- [ ] Remote writes are confined to user://content/.
- [ ] Builtin res:// LevelCatalog confinement remains intact.

## Manifest V1
- [ ] Strict schema/version/field validation.
- [ ] Duplicate keys rejected.
- [ ] Non-finite / oversized / deep / excessive input rejected.
- [ ] Pack IDs/object keys/hash/length validated.
- [ ] Level/pack references validated.
- [ ] App minimum version compatibility enforced.
- [ ] Non-increasing content version rejected.
- [ ] Same version with different bytes rejected.
- [ ] Missing-pack diff avoids redundant downloads.
- [ ] Disabled/schedules are not silently ignored before CP06; unsupported candidate preserves LKG.

## Campaign order
- [ ] Builtin levels retain original explicit orders.
- [ ] Remote levels use manifest-declared levels array order, not numeric/alphabetic inference.
- [ ] Remote sequence appends after highest builtin order.
- [ ] Builtin/remote ID collision fails closed.
- [ ] Successor may append while preserving existing remote prefix.
- [ ] Reorder/removal/reassignment of active remote sequence fails closed.
- [ ] Remote content cannot override builtin levels.

## Scrubpack V1 / payload safety
- [ ] Whole pack exact byte_length checked.
- [ ] Whole pack SHA-256 checked.
- [ ] pack.json schema/version/media/identity checked.
- [ ] Exact allowed member set/layout enforced.
- [ ] Member SHA-256 checked.
- [ ] Traversal/absolute/backslash/drive/UNC paths rejected.
- [ ] Duplicate/casefold member collisions rejected.
- [ ] symlink/special/encrypted/executable archive entries rejected.
- [ ] Unsupported/oversized archives rejected.
- [ ] JSON remains declarative data only; no resource/script execution.
- [ ] LevelData validates with current game validators.
- [ ] Supply plan validates with current SupplyPlanLoader and exact level identity.
- [ ] Metadata binds to same exact level.
- [ ] No remote preview member invented for V1.

## Install / LKG
- [ ] .part/staging used before activation.
- [ ] Candidate never mutates active registry until fully validated.
- [ ] Active/LKG set survives interrupted/corrupt replacement.
- [ ] Versioned local registry exists.
- [ ] Cold offline boot uses valid cached LKG.
- [ ] No-network first launch uses builtin content.
- [ ] Bad active cache falls back to builtin safely.
- [ ] Retention never deletes active/only LKG prematurely.
- [ ] Repeated refresh is idempotent.

## Catalog / gameplay integration
- [ ] Composite/runtime catalog exposes immutable builtin + active remote entries.
- [ ] GameplayLaunchResolver resolves 1–10 builtin and 11+ remote fixture correctly.
- [ ] AppState orders_context sees composite playable orders.
- [ ] Missing remote frontier returns CONTENT_MISSING, never mislabeled fallback gameplay.
- [ ] Exact remote LevelData + exact remote supply plan reach production gameplay host.
- [ ] Progression/economy/save truth not mutated by content install.

## Runtime lifecycle
- [ ] Builtin/cached app boot does not wait on network.
- [ ] One bounded background refresh; no per-frame/per-screen polling.
- [ ] Concurrent duplicate refresh prevented.
- [ ] Transport/server/parse/hash errors retain playable builtin/LKG.
- [ ] Read-only runtime status is available for diagnostics.

## Android capability
- [ ] INTERNET permission is proven if an Android preset already exists.
- [ ] If preset does not yet exist, CP04-011 is explicitly recorded READY_FOR_ANDROID_EXPORT_GATE and no fake closure is claimed.
- [ ] No signing secret committed.

## Tests
- [ ] Permanent CP04 focused suite PASS.
- [ ] Permanent CP05 focused suite PASS.
- [ ] Deterministic family fixture proves builtin 1–10 + remote 11–12 + offline relaunch + append 13 + bad successor rollback.
- [ ] No public internet required by automated tests.
- [ ] m35 LevelCatalog PASS.
- [ ] m37 progression PASS.
- [ ] M40 save regression PASS.
- [ ] M52 supply/gameplay regression PASS.
- [ ] M53 content/difficulty regression PASS.
- [ ] M43 order-context regression PASS.
- [ ] Root tests ALL PASS.
- [ ] git diff --check clean.
- [ ] No unexplained SCRIPT ERROR.

## Handoff
- [ ] CP04 log exists.
- [ ] CP05 log exists.
- [ ] master log exists.
- [ ] Exact final SHA/branch state reported.
- [ ] Remaining CDN, CP06 and Android Family APK gates are truthful.
- [ ] Master log ends AWAITING_GPT_REMOTE_CONTENT_RUNTIME_V01_AUDIT.
