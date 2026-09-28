# M43-C002-C001 — POPUP / MODAL / PAUSE MATRIX V01

Date: 2026-09-28
Implementer: Claude
Status: AWAITING_CHATGPT_AUDIT

Focused suite: `tests/m43_c002_c001_popup_modal_pause.gd`, with 23 ledger cases.
Evidence tool: `tests/tools/popup_pause_snapshot.gd`, which writes 18 PNGs to `evidence/`.

## 1. Components

| Piece | File | Role |
|---|---|---|
| `BasePopup` | `scripts/ui/popup/base_popup.gd` | The one reusable popup. It has a scrim, a safe-area root, a promoted-frame `FrameBox` (NinePatch at a uniform scale), a header pill with an optional close button, content, a busy row and a footer. It owns the exactly-once lifecycle, top-only action gating and the pending token. |
| `ModalStack` | `scripts/ui/popup/modal_stack.gd` | The one modal authority, a `CanvasLayer` at layer 64. It handles LIFO order, a single top input owner, Back/Escape consumption, `modal_changed` and `clear`. |
| `Popups` | `scripts/ui/popup/popups.gd` | Pure builders: `pause`, `attempt_confirm`, `confirm`, `reward`, `insufficient_sb`, `network_error`, `busy` and `feedback`. |
| Host wiring | `scripts/gameplay/runtime/production_gameplay_host.gd` | Pause control → `open_pause()`, modal hold (`_on_modal_changed`), `attempt_consequence()`, `exit_to_home()`, and guards on booster, 2x and Pause input. |
| Input gate | `scripts/ui/production_input_controller.gd` | `set_modal_blocked()` rejects supply activations with `"modal"`. |
| App root | `scripts/app/main.gd` | Owns the one stack and injects it into the host. Home is bridged through `set_modal_active("modal_stack")`. `handle_back()` asks the stack first. Pause → Home goes through `nav.go(HOME)`. The stack is cleared when a host is released. |
| Copy | `scripts/ui/ui_text.gd` | 32 new keys. All values are passed in as live arguments. |

## 2. Frame usage (existing promoted art only, bytes untouched)

| Frame | Used by | 9-slice margins (texture px, measured cream interior) |
|---|---|---|
| `popup_medium_frame.png` | Pause, pre-action confirms, generic confirm, insufficient SB | 119 / 169 / 119 / 185 |
| `popup_warning_frame.png` | Post-action (loss) confirms, warning confirm, network error, failure feedback | 119 / 356 / 120 / 220 |
| `popup_reward_frame.png` | Reward/confirmation, success feedback | 128 / 331 / 122 / 216 |
| `popup_small_frame.png` | Busy/loading | 176 / 205 / 176 / 223 |
| `popup_large_frame.png` | Available through `set_frame("large")`; no V1 caller yet | 125 / 133 / 126 / 144 |
| `popup_confirmation_frame.png` | **Not used.** Its baked ✓/✗ discs would read as dead controls next to the live labelled CTAs. | — |

The frame scale is `frame_width / texture_width`. The top and bottom edges, including the star and warning emblems, are therefore never stretched horizontally. The frame width is `min(880, safe width − 80)`, the same 880 reference width as the Results screen. The family styling is the same as Results: royal title pill, green `style_play_button` primary, cream secondary, INK body text.

## 3. Requirement → implementation → proof

| Req | Implementation | Test case(s) |
|---|---|---|
| A BasePopup: scrim, frame, header/content/footer, close, lifecycle, safe area, live text | `BasePopup` | `base_popup_lifecycle`, `responsive_matrix`, `frames_promoted_unchanged` |
| A No duplicate open or close callback | The `NEW→OPEN→CLOSED` state machine; `push` rejects a repeat or a closed popup | `base_popup_lifecycle` |
| B Exactly one top owns input | `_stack_set_top`. The action guard requires `is_top`. The top scrim covers everything below. | `only_top_input` (real routed taps + positive control) |
| B Background is blocked | CanvasLayer 64 scrim; `modal_changed` → input gate + runtime hold; host booster, 2x and Pause guards | `gameplay_input_blocked` |
| B Deterministic order, restore the next | LIFO `_stack`; `_remove` re-syncs the top | `stack_order` |
| B Back/Escape closes the top first, no leak | `ModalStack._input(ui_cancel)` consumes the event. `main.handle_back()` asks the stack first. A busy or non-dismissible popup still consumes back. | `back_escape_no_leak` |
| B Focus/background never duplicates | The stack ignores OS notifications. Popup actions run only on user input. | `focus_background` |
| B Rapid open/close is deterministic | `open_pause` refuses while any modal is open; the latch plus the `OPEN` guard | `rapid_duplicates` |
| C Generic confirm: context token, confirm once, cancel is harmless | `Popups.confirm`; the closing action emits after close | `generic_confirm` |
| D Reward shows committed data only | `Popups.reward` returns `null` unless `committed == true`. It holds no service reference. | `reward_committed_only` |
| E Pause from the real V02 control | `_wire_controls` → `_on_pause_pressed` → `open_pause` | `pause_from_real_control` (routed tap on the baked box) |
| E Resume resumes only what Pause suspended | `_paused_by_modal` releases only its own user pause | `resume` (a system suspension survives) |
| E Restart before the first action | `attempt_consequence().gameplay_started == false` → "no loss" copy; real `retry()` | `restart_pre_action` |
| E Restart after the first action | Consequence from `WinStreakService.gameplay_started()`, `.streak()` and `HeartService.hearts()`. Real `retry()` → `_on_retry_restored` applies the loss. | `restart_post_action` (preview == applied; 0-Hearts edge) |
| E Home before the first action | `exit_to_home()` → `streak.on_pre_action_exit()` | `home_pre_action` |
| E Home after the first action | `exit_to_home()` → `hearts.consume()` + `streak.on_restart()` + `capacity.begin_new_attempt()` + save | `home_post_action` (cancel is harmless) |
| F Insufficient SB | `Popups.insufficient_sb`: Shop/Cancel hand back a detached `pending` copy and spend nothing | `insufficient_sb_context` |
| F Network/error for rewarded_ad, store, cloud, live_event | `Popups.network_error`: Retry (latched → pending) or Cancel | `network_retry_cancel` |
| F Busy/loading | `begin_pending` / `resolve_pending` token, timeout, stale or late resolves ignored | `busy_blocks_duplicates` |
| F Success/failure feedback | `Popups.feedback(result)` shows caller-committed truth | `network_retry_cancel` (feedback asserts) |
| G Input isolation, sixth slot intact | See B; the stack never touches the shell | `gameplay_input_blocked`, `six_slot_survives` |
| H Responsive 5 sizes, safe area, touch targets | Safe-area root plus width clamp; buttons are at least 88 px | `responsive_matrix` (synthetic insets 96 top / 64 bottom) |
| I.20 No accumulation | Popups are freed on close. The host disconnects from the shared stack on `_exit_tree`. | `no_accumulation` |

## 4. Authority used for Pause consequences (no new flags)

| Question | Authority |
|---|---|
| Has gameplay begun? | `WinStreakService.gameplay_started()`. This is armed by the host's `_on_activation_event` on the first accepted supply activation (M39 V03). The M30 Retry and the M42 back path already use the same flag. |
| Heart consequence | `HeartService.hearts()`. `consume()` fails closed at 0, so no Heart line is shown at 0. |
| Streak consequence | `WinStreakService.streak()`. `on_restart()` resets it only when gameplay had begun. |
| Restart execution | The existing `retry()` → `RetryCoordinator` → `_on_retry_restored`. This is unchanged M30/M39 code. |
| Home execution | `exit_to_home()` mirrors the same law. The owner rules are `OWNER_ECONOMY_REWARDS_V01` §3 and §6: a restart after gameplay has begun counts as a loss; leaving before the first action costs nothing. |

No prices, Heart values, streak mappings, booster rules or 2x rules were changed.

## 5. Evidence (`evidence/`)

| Required | File |
|---|---|
| Pause on Gameplay V02 | `pause_gameplay_v02_1080x2160.png` |
| Restart confirm before the first action | `restart_confirm_pre_action_1080x2160.png` |
| Restart confirm after the first action | `restart_confirm_post_action_1080x2160.png` |
| Home confirm before the first action | `home_confirm_pre_action_1080x2160.png` |
| Home confirm after the first action | `home_confirm_post_action_1080x2160.png` |
| Stacked modals (Pause → Restart confirm → network) | `stacked_modals_1080x2160.png` |
| Generic confirm (warning) | `generic_confirm_warning_1080x2160.png` |
| Reward/confirmation | `reward_confirmation_1080x2160.png` |
| Insufficient SB | `insufficient_sb_1080x2160.png` |
| Network/error | `network_error_1080x2160.png` |
| Busy/loading | `busy_loading_1080x2160.png` |
| Short phone | `pause_short_phone_1080x1920.png`, `home_confirm_post_action_short_phone_1080x1920.png` |
| Tablet | `pause_tablet_1536x2048.png`, `restart_confirm_post_action_tablet_1536x2048.png` |
| Other phones | `pause_phone_1170x2532.png`, `pause_phone_1290x2796.png` |
| +1 Slot six-shell | `pause_six_slot_1080x2160.png` |
