# M43-C005-C006 — OWNER REVIEW HARNESS AUDIT CRITERIA V02

Canonical task: **SB-M43-064**  
Scope: rebaseline existing Godot owner-review harness to technically-audited V03.

## Production immutability

- [ ] StandardPackCeremony unchanged from V03 audited SHA.
- [ ] StandardPackModel unchanged.
- [ ] RevealSequencer unchanged.
- [ ] all 9 V03 shipping Standard PNGs unchanged.
- [ ] all 9 V03 clean candidate PNGs unchanged.
- [ ] root TASKS.md untouched by Claude.
- [ ] project.godot untouched by Claude.
- [ ] scenes/app/main.tscn untouched by Claude.
- [ ] no SB-M43-065/Premium work.

Any production change in this harness pass is FAIL.

## Harness reuse

- [ ] existing owner-review scene still loads directly with F6.
- [ ] real StandardPackCeremony is instantiated.
- [ ] real ModalStack is used.
- [ ] controller does not auto-tap.
- [ ] controller contains no frame/timing/state-machine copy.
- [ ] controller/scene remain byte-identical unless a real V03 incompatibility is documented.

## V03 baseline proof

- [ ] stale V02 ceremony hash pin is replaced with the V03 audited hash.
- [ ] StandardPackModel / RevealSequencer pins remain current.
- [ ] all 9 shipping Standard frame SHA-256 values equal V03 manifest `sha256_after`.
- [ ] all 9 V03 candidate frame SHA-256 values equal shipping.
- [ ] 01..04 remain historical-byte-identical.
- [ ] 05..09 differ from historical dirty assets.
- [ ] all 9 manifest rows report clean=true.

## Live behavior

- [ ] default = mixed NEW / DUPLICATE / NEW.
- [ ] initial ceremony waits in IDLE.
- [ ] no automatic Tap 1 or Tap 2.
- [ ] R restarts to IDLE.
- [ ] E toggles FULL/Reduced and restarts.
- [ ] 1/2/3 select mixed/all-new/repeat.
- [ ] harness has no authority mutation.
- [ ] test-driven FULL run reaches exact frame history 01..09.
- [ ] configured FULL 01..08 holds remain >=0.18 s.
- [ ] harness contains no copied FULL hold constants.

## Owner instructions

- [ ] OWNER_REVIEW_INSTRUCTIONS_V02.md exists.
- [ ] exact Windows project path included.
- [ ] exact review scene path included.
- [ ] F6 steps explicit.
- [ ] two owner clicks explicit.
- [ ] R / E / 1 / 2 / 3 explained.
- [ ] instructions say this is current V03 shipping ceremony.
- [ ] instructions tell owner to judge all 9 distinct beats.
- [ ] instructions tell owner to look for any remaining rectangular matte.
- [ ] V03 timing is stated.
- [ ] F5 not required.
- [ ] no-save/no-economy/no-Collection mutation stated.

## Manual F6 proof

- [ ] F6 launches.
- [ ] initial pack waits.
- [ ] FULL opening visually presents 01..09.
- [ ] no rectangular matte observed.
- [ ] old 05/07/09 black-box defect absent.
- [ ] old 06/08 dark-wash defect absent.
- [ ] three-card hold/destinations work.
- [ ] Click 2 routing works.
- [ ] R/E/1/2/3 work.
- [ ] no runtime/script errors.

## Validation

- [ ] owner-review harness smoke PASS.
- [ ] SB-M43-064 V03 focused suite PASS.
- [ ] V03 alpha validator PASS on shipping frames.
- [ ] RevealSequencer suite PASS.
- [ ] git diff --check clean.
- [ ] CLAUDE_LOG_V02.md exists with exact commands/results and production immutability proof.
- [ ] Desktop sync occurred before work and owner-local files were preserved.

## Closure

Harness audit PASS does **not** close SB-M43-064.

On PASS:
- actor becomes OWNER;
- owner runs F6 and reviews current V03 live;
- only explicit OWNER VISUAL PASS closes SB-M43-064 and unlocks SB-M43-065.
