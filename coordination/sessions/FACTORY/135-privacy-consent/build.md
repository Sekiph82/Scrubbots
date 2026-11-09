STATUS: READY

# Build: 135-privacy-consent (SB-M58-007..014)

## Summary
Settings now has a PRIVACY button. It sits in the CLOSE row (the same pattern factory 129 uses for CREDITS), so the panel keeps its height. The button opens a `privacy` popup on the app ModalStack. The popup holds:
- one SHARE ANALYTICS switch, default OFF, wired to `AnalyticsService.set_consent` (the only production caller) and saved at once in the analytics state file;
- one no-ads line (no ads SDK exists, so there is no placeholder toggle);
- a short EN/TR privacy summary and a note that the full policy link is added before release (the URL is for the owner to supply).

The docs add `docs/PRIVACY_DATA_INVENTORY.md` §7, a DRAFT for owner/legal review. It covers:
- 007: child-directed analysis and recommendation. No age gate now, with the reason.
- 008: legal basis for analytics consent by region.
- 009: the UMP/ATT plan for when ads ship.
- 010: notification privacy.
- 011/012: account, cloud-save and display-name requirements.
- 013: receipt and tx-id retention. Ledgers are kept for the life of the save and never pruned, because pruning would break idempotency.
- 014: localization and accessibility of the privacy screens.

The policy draft, the analytics taxonomy gate and AGENTS.md are updated to match.

Commits after the rebase onto e83f40ce: 64bf9e3e (UI + tests + CI), 039c874f (docs/tasks), 6551c9ba (release gates), a952d45a (TASKS hashes).

Files changed:
- `scripts/ui/privacy_screen.gd` (new)
- `scripts/ui/settings_panel.gd`: PRIVACY in the ActionRow with CLOSE, `privacy_requested` signal, `_make_row_button`; `_card` / `_make_toggle` made static so the popup reuses them
- `scripts/app/main.gd`: `open_privacy()`
- `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`: `PRIVACY_*` keys
- `scripts/app/analytics_service.gd`: comment only
- `tests/m58_privacy_consent.gd` (new, 7 cases)
- `.github/workflows/android-family-first10.yml`: suite plus an exact 7/7 guard
- `docs/PRIVACY_DATA_INVENTORY.md`, `docs/PRIVACY_POLICY_DRAFT.md`, `docs/ANALYTICS_TAXONOMY_V1.md`, `AGENTS.md`, `TASKS.md`

## Acceptance criteria
1. [x] Consent UI reachable from Settings, Settings still fits 1920 px, Reduced Effects untouched: m58_privacy_consent p02 checks that PrivacyButton is visible, labelled PRIVACY, at least 88 px tall, inside the frame, and that the frame fits inside 1080x1920. The cards keep their order (Haptics / Reduced Effects / Color Symbols / Language), and PRIVACY shares the CLOSE row. m41_settings (4 viewports including 1080x1920) PASS.
2. [x] Analytics ON/OFF, default OFF, wired to set_consent, persists, gates analytics: p01 shows a fresh profile with consent OFF, track() refusing events and no consent file written. p03 shows the switch OFF by default. Turning it ON lets track() queue an event and survives a relaunch with a fresh AppState. Turning it OFF drops the queue, makes track() refuse events and also survives a relaunch. Reopening the popup shows the saved state.
3. [x] Policy summary EN/TR plus a note that the full policy URL is TBD: the popup shows a header, 4 summary lines and the PolicyLink note. p04 checks that every label shows its key's copy in English and Turkish, and that every `PRIVACY_` key has Turkish copy.
4. [x] Ads: no fake toggle: p03 finds exactly one CheckButton (SHARE ANALYTICS) and the AdsNote text line.
5. [x] Child-directed review (007) DRAFT: §7.1 covers COPPA / GDPR-K / Play Families / Apple Kids / loot-box rules. Recommendation: a 13+ target audience, plus a neutral age screen before any ads SDK or analytics provider. It states explicitly that no age gate is implemented and why none is required now.
6. [x] Notification privacy (009/010) doc + test: §7.4. p06 checks:
   - the scheduled reminder carries exactly (app name, fixed copy, seconds);
   - the plan holds only category / key / at;
   - no EN or TR reminder copy has a `%` placeholder;
   - deep links outside the allowlist go to Home.
7. [x] Account / display name (011/012): §7.5 says no accounts exist and Ranks shows only "You". It lists what the planned cloud save will store and the requirements for delete, export, sign-out and recovery, plus display-name rules for any future leaderboard.
8. [x] Receipts (013): §7.6 sets the retention: reward tx ids and pack receipts stay for the life of the save, nothing is pruned, and no store data is kept. p07 checks:
   - 12 committed packs leave 12 receipts;
   - each receipt has only its schema key set, and the largest is 953 bytes (cap 1500);
   - applied tx ids are short strings;
   - after a relaunch a committed tx replays and is never redrawn.
9. [x] 014 localized EN/TR, contrast and touch targets: p04, for both EN and TR, checks the frame stays inside 1080x1920, every button / switch is at least 88 px, every font is at least 18 px and every label wraps inside the scroll. INK on the cream card is 10.8:1 and ROYAL_EDGE is 10.2:1 (minimum 4.5).
10. [x] Sole consent caller: p05 scans scripts/ and finds `.set_consent(` only in privacy_screen.gd.
11. [x] m58 inventory still green after the doc updates: m58_privacy_inventory 7/7 (re-run after the doc edits).

## Validation
Godot 4.7.2 headless, all LOCAL_PASS (exit 0, no SCRIPT ERROR / Parse Error, last line PASS):
- tests/m58_privacy_consent.gd: 'M58 privacy consent evidence: PASS (7/7 cases, 0 fail)' (new; run twice)
- m58_privacy_inventory 7/7 (run twice, the second time after the doc edits)
- m41_settings PASS
- m51_localization_readiness 8/8
- m56_analytics_taxonomy 27/27
- m43_172_local_notifications 12/12
- m43_146_notification_permission 8/8
- m43_r15_owner_remediation 18/18
- m42_navigation PASS
- m49_touch_targets_text_stress 5/5
- m50_accessibility_audit 8/8
- m59_app_version 4/4
- m43_master_c005_meta_ceremonies 32/32

Other checks: `git diff --check` is clean. The import churn (project.godot, .import, .uid files) was restored and removed, and `git status --porcelain` is empty.

Not run: m59_credits. It exists only on the unmerged branch factory/129-release-hygiene. No CI run, no phone build.

Merge note: 129 also turns the Settings CLOSE row into an ActionRow with CREDITS, using an identical `_make_row_button`. Merging 129 and 135 will conflict in `settings_panel.gd` and `main.gd` (adjacent lines). To resolve, keep one ActionRow [CREDITS | PRIVACY | CLOSE]; m59_credits checks that CREDITS is index 0. Then re-run m41_settings, m59_credits and m58_privacy_consent to confirm the row still fits.

## Log
### Round 1
- Measured the Settings panel: 1819 px tall at 1080x1920, which leaves no room for a new card. PRIVACY therefore shares the CLOSE row, like 129's CREDITS.
- Implemented the PrivacyScreen popup (Help/Credits popup pattern), the main.gd wiring and the EN/TR keys.
- Wrote the 7-case m58_privacy_consent test and added it to CI with an exact guard.
- Wrote inventory §7 (DRAFT for owner/legal) and updated the policy draft, the taxonomy gate text and AGENTS.md.
- TASKS.md: SB-M58-007..014 checked off; queue rows merged into one DONE row.
- No age gate built: analytics is OFF by default, the sink is NullSink and there are no ads. §7.1 says when one becomes required.
- No receipt pruning: it would break exactly-once.
- No new question for the owner. The 13+ audience decision is due when ads or an analytics provider are about to ship, per §7.1.

### Round 1, rebase (coordinator request)
- Rebased onto origin/main e83f40ce, which now includes 129, 131, 132 and 134.
- Resolved conflicts:
  - `settings_panel.gd`: one ActionRow [CREDITS | PRIVACY | CLOSE] with CREDITS first, using main's `_make_row_button` (accessibility_name + FOCUS_ACCESSIBILITY). Both signals and both getters are kept.
  - `main.gd`: both preloads, both connects, `open_credits` and `open_privacy`.
  - CI suite list: kept every suite and added m58_privacy_consent.
  - `docs/PRIVACY_DATA_INVENTORY.md`: kept 134's save row and my analytics row.
  - UiText tables: merged automatically, all keys kept.
- m60 printed the hint, so I ran it with `-- --write` and committed docs/RELEASE_GATES.* (563 English strings).
- Updated the TASKS hashes to the rebased commits.
- Final hashes:
  - 64bf9e3e (UI + tests)
  - 039c874f (docs/tasks)
  - 6551c9ba (release gates)
  - a952d45a (TASKS hashes)
- Re-run after the rebase, all LOCAL_PASS (exit 0, no SCRIPT ERROR):
  - m58_privacy_consent 7/7
  - m59_credits 3/3
  - m41_settings PASS
  - m50_accessibility_audit 11/11
  - m51_localization_readiness 8/8
  - m60_release_gates 6/6 (also after `--write`)
  - m58_privacy_inventory 7/7
- project.godot is restored and the tree is clean. Not pushed.
