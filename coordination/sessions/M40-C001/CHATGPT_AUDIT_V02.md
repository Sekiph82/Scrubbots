# M40-C001 V02 — ChatGPT Full-Surface Re-Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M40-C001 V02 / FINDING_SET_FROZEN**

Implementation: `6631f3a`
Claude log: `coordination/sessions/M40-C001/CLAUDE_LOG_V02.md`

M40 is critical/stateful. Service-level safe-write improvements are real, but the whole shipping lifecycle is not closure-ready.

## Pass A — implementation/state sweep

### F-M40-V02-001 — canonical SaveService is not wired into the actual app bootstrap
`project.godot` runs:
`res://scenes/app/main.tscn`

That scene uses `scripts/app/main.gd`, which is still a project-foundation/debug screen and does not instantiate `ProductionGameplayHost` or `SaveService`.

Inside `ProductionGameplayHost`, `save_path` defaults to the empty string, so SaveService is disabled unless a caller explicitly injects a path.

The V02 test injects a test save path and therefore proves the host seam, not the actual shipping app bootstrap required by criterion 6.

### F-M40-V02-002 — unsupported/failing load result is ignored by the runtime host
When a save path is supplied, host calls:
`_save.load()`
but discards the returned result.

Therefore a future-schema result `{ok:false, source:"future_schema"}` does not block the host from continuing with fresh in-memory state. SaveService itself later refuses overwrite, but the app can still run against non-authoritative defaults.

The owner/audit contract requires explicit unsupported/fail-closed application behavior.

### F-M40-V02-003 — migration coerces malformed old schema versions before exact validation
`SaveService.migrate()` begins with:
`var v := int(cand.get("version", 0))`

This runs before `validate_candidate()` exact-integer validation.

Example class:
- version `0.5` -> coerces to 0;
- migration runs;
- version is rewritten to current VERSION;
- malformed input can become valid instead of failing closed.

Migration must validate the raw version domain before any coercion/mutation.

### F-M40-V02-004 — persisted progression frontier is not bound back to gameplay identity
Host owns both:
- persisted `LevelProgressionService.current_level()`; and
- a separate exported `progression_level` defaulting to 1 plus independent `level_path`.

After load, SaveService updates the progression service, but host does not synchronize the gameplay level identity/path from that canonical frontier.

Economy terminal rewards, streak processing and current-level 2x checks use the separate `progression_level`, so a loaded frontier can disagree with the level the host thinks it is running.

### F-M40-V02-005 — canonical save is not yet the sole settings persistence authority
Before central SaveService load, host unconditionally calls:
- `AudioSettingsService.load()` from `user://audio_settings.cfg`;
- `HapticsSettingsService.load()` from `user://haptics_settings.cfg`.

Those services also retain independent save APIs.

The central save may overwrite their in-memory values later, but two writable persistence authorities still exist. M40 criterion 6 requires no competing save authority; M41 must consume the canonical M40 persistence seam rather than reactivating the side files.

### F-M40-V02-006 — malformed canonical haptics state does not fail candidate validation
`validate_candidate()` creates a scratch HapticsSettingsService and calls `import_snapshot()`, but that API returns void and converts malformed `enabled` data to the safe default true.

So a corrupt canonical save such as `settings.haptics.enabled="bad"` can validate instead of being rejected/recovered from backup.

Central save validation must validate the persisted bool strictly.

### F-M40-V02-007 — post-M39 durable state is still incomplete
The owner-locked Daily law requires local-date identity plus defensive claim timestamp/highest-seen trusted/system timestamp. M39 V02 does not store those fields, so M40 cannot claim complete Economy V1 persistence yet.

This is an upstream dependency blocker that V03 must revalidate after M39 V03.

## Pass B — evidence/test/policy sweep
False-positive risks:
- `m40_v02_safety.gd` builds `ProductionGameplayHost` directly and injects `save_path`; it does not boot the actual project main scene.
- future-schema service behavior is tested, but host/app reaction to `load().ok == false` is not.
- fractional *current* schema is tested (1.5), but malformed *older* version such as 0.5 is not; that misses the pre-validation migration coercion.
- no test asserts gameplay host level identity equals loaded progression frontier before rewards/2x/economy consumption.
- no canonical-save corruption test uses malformed haptics bool.
- post-M39 Daily timestamp/local-calendar requirements are absent, so round-trip cannot prove them.

### Audit specification correction
The V02 criteria mentioned rejecting “unknown robot IDs”. The owner has not yet locked the full robot roster/perk IDs; only Scrubby + unlock pacing/cost are locked. Treating every not-yet-known robot ID as invalid would require a roster authority that does not yet exist.

That item is therefore corrected as an **AUDIT SPECIFICATION DEFECT**, not a Claude implementation failure. V03 will require canonical validation only against robot IDs that are actually owner/config-authoritative at that time.

## Sprint coverage ledger

| Task | Production owner / surface | Status | Audit note |
|---|---|---|---|
| SB-M40-001 | SaveService schema/version | **DEFECT** | malformed old version is coerced by migrate() before exact validation |
| SB-M40-002 | Audio/Haptics settings + SaveService | **DEFECT/GAP** | standalone config authorities still load unconditionally; malformed haptics bool is normalized instead of invalidating canonical save |
| SB-M40-003 | LevelProgressionService + ProductionGameplayHost | **DEFECT** | loaded progression frontier is not bound to host progression_level/level_path; real app bootstrap absent |
| SB-M40-004 | WinStreak snapshot through EconomyServices | **PROVEN** | round-trip service state present; no new M40-owned gap found |
| SB-M40-005 | Economy aggregate snapshot | **BLOCKED/DEFECT** | post-M39 state is not closure-ready; Daily owner-required trusted timestamp/local-date state is absent |
| SB-M40-006 | SaveService safe write | **PROVEN** | validated temp + backup protection + rename replacement accepted at service level |
| SB-M40-007 | SaveService missing-save behavior | **PROVEN** | missing save falls to defaults/legacy migration |
| SB-M40-008 | SaveService corruption/future-schema recovery + host consumer | **DEFECT/GAP** | service reports future_schema, but ProductionGameplayHost ignores load result and continues |
| SB-M40-009 | SaveService migration | **DEFECT** | migration coerces version before exact validation |
| SB-M40-010 | Round-trip/bootstrap tests | **DEFECT/GAP** | test injects save_path into a host; shipping main scene does not instantiate/configure canonical SaveService |
| SB-M40-011 | Corrupt-file tests | **PROVEN** | service-level corruption/backup cases are materially covered |
| SB-M40-012 | Old-save defaults | **PROVEN WITH DEPENDENCY** | valid old-version missing-section defaults are present; exact-version migration fix still required |
| SB-M40-013 | Wall-clock defensive persistence | **DEFECT/BLOCKED** | Daily claim timestamp/highest-seen trusted/system timestamp and local-date key are not persisted |

## Interaction sweep
- M39 Daily state incompleteness makes M40 schema completeness impossible until M39 V03 lands.
- ignoring `load()` failure undermines future-schema fail-closed behavior even though SaveService itself correctly returns the error.
- separate `progression_level` means a technically successful load can still feed stale gameplay identity to economy.
- separate audio/haptics config files conflict with the “one canonical save authority” requirement and directly intersects the owner-authorized M41 settings work.

### F-M40-V02-008 — canonical save boundaries do not cover non-terminal durable mutations
The current runtime saves canonical state from terminal WON/LOST only.

No repository production lifecycle currently guarantees a canonical save after:
- Daily/Gift/Collection/exchange claims;
- robot unlocks;
- booster/economy purchases;
- timed/current-level 2x purchases;
- settings mutations;
- app background/quit.

This means a legitimate durable mutation can be lost if the process stops before a gameplay terminal event.

M40 must define an event/dirty save coordinator or explicit authoritative save seam for durable meta-state mutations plus app lifecycle flushes. Per-frame saving is not required or desired.

### F-M40-V02-009 — nested M39 canonical state validation must be re-run as part of full-save validation
The completed M39 sibling sweep found that several nested import contracts still accept noncanonical state, including RewardGrant transaction collections, Gift Meter queue/applied structure, unknown booster keys and noncanonical Heart/2x domains.

Because SaveService delegates semantic validation to those imports, `validate_candidate()` cannot currently certify the whole save as canonical.

This is an upstream-owned dependency, but M40 V03 must include end-to-end malformed full-save fixtures after M39 V03 lands.

Frozen finding set: **F-M40-V02-001..009**.

Verdict string:
`CHANGES_REQUIRED / M40-C001 V02 / F-M40-V02-001..009`
