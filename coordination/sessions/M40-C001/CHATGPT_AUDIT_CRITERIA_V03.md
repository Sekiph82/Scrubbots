# M40-C001 V03 — Canonical App Persistence Final Criteria

Authority:
- CHATGPT_AUDIT_V02.md frozen F-M40-V02-001..009
- post-M37 V03 progression contract
- post-M39 V03 canonical economy contracts
- M33/M34 settings services
- M35 production catalog

M40 remains CRITICAL/STATEFUL.

## A. One canonical app-state/persistence authority

Production startup must own one canonical in-memory graph for:
- audio settings;
- haptics settings;
- progression;
- EconomyServices;
- SaveService.

Recommended architecture: a small AppState/PersistenceBootstrap autoload or equivalent app-level composition root.

ProductionGameplayHost must consume that shared graph rather than silently creating a second progression/economy/settings authority.

Tests/debug may inject isolated graphs/paths.

## B. Canonical production save path

Production default must use one explicit user:// canonical path.
Disk persistence must not depend on an external caller remembering to fill an empty export property.

Test suites must use injected temp paths or explicitly disabled persistence.

## C. Load-result handling

Application bootstrap must inspect SaveService.load() result.

- future/unsupported schema => explicit blocked/unsupported state; do not continue gameplay on fresh defaults;
- valid primary/backup/default path => continue according to documented policy;
- no silent ignore of {ok:false}.

## D. Progression frontier -> gameplay identity

After load:
- current campaign level comes from canonical LevelProgressionService;
- gameplay level identity/content must correspond to that frontier through LevelCatalog/canonical content mapping;
- do not use an independent stale exported progression_level for rewards/2x.

If the catalog lacks content for the loaded frontier, fail safely as CONTENT_MISSING/NOT_AVAILABLE rather than running a different level under the new level number.

Debug/test override seams must be explicit and non-shipping.

## E. Raw schema version validation before migration

Before migrate():
- schema field/type valid;
- raw version is exact integer;
- future version rejected/handled;
- malformed 0.5, "0", NaN/INF etc fail closed.

Migration dispatch may never use int() coercion to convert malformed version input into a valid older version.

## F. Strict settings state

Canonical haptics snapshot must be a Dictionary with enabled: bool.
Malformed/scalar/wrong-type haptics state invalidates candidate and triggers backup/recovery policy.

Refactor HapticsSettingsService import to return success/failure or validate explicitly before calling.

Audio values remain finite 0..1.

## G. Single settings persistence authority

After canonical app-state bootstrap exists:
- production must not independently load/save audio_settings.cfg and haptics_settings.cfg as competing authorities;
- legacy side files may be read only through an explicit one-time migration path when no canonical save exists;
- M41 Settings UI must mutate canonical in-memory settings and request canonical save.

## H. Durable mutation save boundaries

Define non-per-frame save coordination for:
- terminal progression events;
- purchases/spends/claims/unlocks/exchange;
- Daily/Gift/Collection durable mutations;
- settings changes;
- app background/quit.

A durable meta mutation must not depend on later reaching gameplay terminal to persist.

Use a dirty/coalesced coordinator if needed; avoid excessive per-frame writes.

## I. Safe write/recovery regression

Retain accepted V02 properties:
- validated temp;
- valid-primary-only backup rotation;
- last-known-good recoverability;
- rename/replace path;
- future schema overwrite protection;
- every I/O result checked.

Add fault tests around any new app-level coordinator.

## J. Nested canonical full-save validation

After M39 V03:
full SaveService candidate tests must reject malformed nested:
- Reward applied tx IDs;
- Gift queue/applied structures;
- fifth booster key;
- invalid Heart anchor/2x sentinel;
- inconsistent Collection claimed metadata;
- Daily timestamp/date state.

SaveService may delegate to nested import APIs only after those APIs are proven fail-closed.

## K. Schema completeness inventory

Re-enumerate all durable post-M39 V03 state and document persisted vs transient.

Attempt-only +1 Slot capacity must remain transient unless owner later explicitly requires mid-attempt restoration.

Do not invent active_robot_id closed-world validation until an owner-approved robot roster/selection authority exists.
Reject malformed/empty robot IDs only to the extent current canonical service can prove.

## L. Direct integration tests

Required:
- boot actual canonical app-state composition with default production save path redirected to a test path;
- fresh profile -> mutate -> background/flush -> relaunch;
- Daily claim -> relaunch without gameplay terminal;
- purchase/booster inventory mutation -> relaunch without terminal;
- settings change -> relaunch;
- progression WON -> relaunch and load correct next frontier/content or explicit content-missing state;
- future schema causes app-level block;
- 0.5 schema version rejected before migration;
- scalar/malformed haptics falls back to valid backup;
- corrupt primary + valid backup;
- faulted replace/rotation;
- post-M39 malformed nested fixtures.

Regression:
- M33 settings/audio
- M34 haptics
- M35 catalog
- M37 V03
- M38 V02
- M39 V03
- root suite
- git diff --check

Handoff:
`AWAITING_AUDIT / M40-C001 V03 / FULL_SURFACE_REAUDIT_REQUIRED`
