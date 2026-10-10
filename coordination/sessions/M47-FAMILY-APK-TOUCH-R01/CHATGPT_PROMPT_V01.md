# M47-FAMILY-APK-TOUCH-R01 — Claude MASTER PROMPT V01
Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`; engine **Godot 4.7.2**.
Implementer **CLAUDE CODE**; `TASKS.md` lifecycle and independent audit: **ChatGPT only**.
Read `OWNER_DEVICE_FEEDBACK_V01.md` and `CHATGPT_AUDIT_CRITERIA_V01.md`.

## Priority, owner requirement
The wife has installed and opened the real offline-first10 Android Family APK, but cannot reliably place a Supply color batch by a simple tap. The owner describes it as if the batch must be held and pushed toward the five-slot row. **Fix the symptom; do NOT reinterpret the desired input as a drag-and-drop mechanic.**

**Contract:** One deliberate **stationary finger tap** on any eligible Supply **front row (row 0)** cell MUST select that batch once and immediately pass it via the existing `ProductionInputController.activate_front()` -> `FiveSlotBatchEngine.select_front_batch()` transaction to the **rightmost EMPTY** five-slot execution position (six only if legitimately active). No hold, swipe, drag, repeated click, narrow positioning, tap on destination, or extra confirmation. Correctly refresh display and scheduler once. Preview rows 1/2 are not selectable. Preserve FIFO and all existing rejection laws.

## G0 — Read and preserve
1. Read `CLAUDE.md` FIRST; then root `TASKS.md`, `coordination/AUDIT_POLICY.md`, this cycle, M29 input/geometry decisions, M47 export hygiene and prior M47 APK audit.
2. Persistent checkout `C:\Users\sekip\Desktop\ScrubBots`: record HEAD, origin/main, main/upstream, ahead/behind, `git status --short`, dirty owner files, untracked count, stashes/worktrees, `project.godot` SHA-256. Fetch and non-destructively FF/synchronize to latest `origin/main` when safe. Preserve ALL owner-local content. Never run `checkout/restore/reset/clean` on Desktop, even as a convenience. If safe sync is impossible stop `BLOCKED_DESKTOP_SYNC`.
3. Implementation and Godot tests **only in a bounded TEMP worktree**, absolute `git -C` and `godot --path`. On Windows Git Bash set `MSYS_NO_PATHCONV=1` before `/...` sparse patterns. No unnecessary multi-GB copies/Android tooling installation on owner disk. No force-push.
4. Claude MUST NOT edit root `TASKS.md` or write audit verdicts.

## G1 — Trace the real Android shipping path
Review, at minimum:
- `scripts/ui/batch_supply_panel.gd`: front `PanelContainer`, `HitArea` with `top_level=true`, `_size_hit()`, 200 ms touch/synthesized-mouse de-dup, and `_begin_gesture` + `_release_gesture`.
- `scripts/ui/color_batch_tile.gd`, `scripts/ui/gameplay_screen.gd`, `scripts/ui/gameplay_shell_geometry.gd`, `scripts/ui/production_input_controller.gd`, `scripts/gameplay/runtime/production_gameplay_host.gd`, `scripts/gameplay/slots/five_slot_batch_engine.gd`, `project.godot`, and real M29 input tests.
- Inspect whether an invisible Control/overlay intercepts input, the top-level `HitArea` moves/overlaps/extends incorrectly, touch down and up are delivered to different Controls, mouse synthesis replaces or duplicates touch, `_pending_col` is stranded, layout/hitboxes mismatch the visually painted colored tile, the screen/host isn't sized on phone, or placement is rejected by real gates.
- Use narrowly scoped diagnostic **test-only** counters for raw touch/mouse press/release, GUI-target node, hit rectangles vs visible front rectangles, dedup, emitted front signal, `activation_result(column,ok,error)`, supply snapshot and resulting slot occupancy. No personal data, unbounded frame logs or production spam.
- Establish reproducible **before-fix failing test** using the REAL gameplay scene/panel event route, not just manually invoking `activate_front()`. A direct API call may be a control comparison but is not proof of Android touch.

## G2 — Minimal targeted fix
- Repair the proved root cause in existing presentation/hit/input plumbing. Prefer robust **single-tap touch-up activation** on the correct front visual target; ensure press/release pairing does not require movement, remains within the same intended column even with nested front PanelContainer/HitArea, and cannot double-trigger through synthesized mouse. A touch with movement should not be necessary to arm/release the transaction.
- Match interactive hit region to the **actual painted front batch**, in global coordinates after safe-area/reference scaling; make front target finger-friendly within existing cell/gap geometry, without adjacent-column overlaps, preview-row activation or owner-master visual edits. Check z-order and `mouse_filter` ownership.
- Avoid bypassing the production `ProductionInputController` and M23/M24 transaction. Preserve atomicity, paused/modal/terminal safety and front-only FIFO.
- Do NOT change accepted shell master art, static geometry provenance, M31 effects, gameplay rules/solver, slot capacity, Economy/ads, R2, Level Factory, M55 leak tests or test thresholds. Android input support must not break desktop mouse behavior.
- Allowed code only in relevant gameplay screen/supply presentation/production input routing files and tightly relevant touch-regression tests. A runtime `project.godot` touch emulation change requires demonstrated necessity and separate non-destructive Desktop reconciliation; prefer avoiding it.
- Do not create a drag-only fallback to masquerade as a fix.

## G3 — Required adversarial runtime tests
Reproduce and then prove:
1. Real scene through `res://scenes/app/main.tscn` → Home PLAY → ProductionGameplayHost → GameplayScreen. Dispatch a true stationary touch **press/release at the visible center** of each enabled front on **3-, 4- and 5-column** masters; require exactly 1 accepted activation and 1 consumed front batch, with placement in rightmost empty slot. Repeat immediately in successive taps; no lost first tap or extra consume.
2. Test touch AND mouse-emulated-from-touch configurations. Single physical tap always 1 transaction, never 0 or 2. Check touch index 0/1, fast/slow taps, release without motion, release jitter within bounds, press outside/release inside, release outside, cross-column interactions and multi-touch safety. Match expected policy (no accidental transfer on off-target release).
3. Check hit geometry and event ownership against the **visible colored row-0 cell rect** across viewport sizes, Android-like 720x1280, 1080x2400, 1440x3200, with nonzero safe-area insets. Include all 5/6 slot shell variants. Real screen coordinates must be used; testing `get_front_hit_rect` alone is insufficient.
4. Verify preview row 1/2 touches and taps in supply gaps never consume; exhausted fronts do not consume; all-full, paused, modal and terminal taps do not consume; genuine rejection reason is distinguishable from lost touch events; no bypass on pause. Ensure target is rightmost EMPTY rather than user-picked slot.
5. Desktop mouse single click still works, and double activation via touch + emulated mouse is impossible. A held finger or drag **is not needed**.
6. Relevant existing M29/M28/M39/M40/M42/M43/Family/regression suites, plus root `tests/run_tests.gd` ALL PASS. `git diff --check` clean. Do not conceal unrelated M55 race; report it separately without touching its leak thresholds.
7. If direct Android emulator/device is not available, label these synthetic/desktop checks honestly. A simulated touch does NOT substitute for wife's real-device acceptance.

## G4 — New debug APK in GitHub Actions
- Reuse the existing `.github/workflows/android-family-first10.yml` and export preset. **Build only once once final tests pass**; no gigantic unfiltered export or extra local Android SDK.
- Preserve nine forbidden-tree exclusions (packaged zero), all required runtime paths, approved production assets, no secrets, no INTERNET permission (this remains offline-first10), valid arm64 debug signing and portrait metadata. Run current PCK/APK scans, confirm debug signature/source SHA, output size/hash, GitHub run and APK artifact URL. If current CI tests hit the known M55 quiescence race, report it separately, and do not change M55 thresholds to obtain green.
- New APK is not owner-accepted until the wife installs it and confirms **single stationary taps place batches easily**. Each workflow run creates a different debug signing cert: uninstalling old debug build may remove its local save, so warn owner before replacing.

## G5 — Evidence and handoff
- Write `coordination/sessions/M47-FAMILY-APK-TOUCH-R01/CLAUDE_LOG_V01.md`, detailing observed root cause, failing pre-fix reproduction, exact changed files, tap/touch matrix results, legitimate rejection results, all tests, original and new GitHub Actions run IDs/artifact metadata/hash, Desktop sync and owner-file parity.
- Push normally to `main` with no force, then non-destructively synchronize persistent Desktop to origin/main with 0 ahead/behind while protecting owner state.
- Hand back **AWAITING_AUDIT / OWNER_DEVICE_RETEST_PENDING**, commit SHA and direct GitHub log URL. DO NOT mark M47-004 passed or modify `TASKS.md`.
- If no valid new APK or test proof, stop at precise `BLOCKED` or `CHANGES_REQUIRED` rather than claiming mobile success.
