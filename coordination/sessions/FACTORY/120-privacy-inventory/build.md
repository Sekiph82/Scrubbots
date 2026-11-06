STATUS: READY

# Build: SB-M58-001..006 third-party and data inventory, collection hygiene, privacy disclosures, store declarations, age rating

## Summary
Documentation plus a static guard. No game code changed: the hygiene review found nothing collected beyond need.
- `docs/PRIVACY_DATA_INVENTORY.md`: the third-party components with licences (Godot MIT, Game Feel Flow MIT, Saltmire Spark MIT; Godot AI, which is owner-local and untracked, so never in a build; planned AdMob/UMP/Play Billing/StoreKit/Play Games/Game Center/iCloud, described from vendor docs and marked unverified). It also lists every network and native-permission call site, every `user://` file and what it holds, the logs, the analytics state, the Android and iOS permissions and why each exists, the hygiene review table, and DRAFT store answers. Those answers are Play Data safety and Apple App Privacy, current and planned, plus a DRAFT IARC questionnaire and child-directed notes that link to SB-M58-007.
- `docs/PRIVACY_POLICY_DRAFT.md`: an EN policy draft. Part A covers the current build, Part B the planned ads, purchases and cloud. Placeholders mark owner/legal decisions.
- `tests/m58_privacy_inventory.gd`: a static guard. It scans 328 `.gd`/`.tscn` files under scripts/, scenes/ and addons/ for network or native APIs and `user://` literals. It also checks the Android preset permissions, the iOS preset privacy/capability/entitlement/plist keys and the addon dirs, and requires every hit to be listed in the inventory. The committed `project.godot` must not reference godot_ai. A self-check case proves the patterns fire.
- `.github/workflows/android-family-first10.yml`: `m58_privacy_inventory` is added to CI validate with an exact `PASS (7/7 cases, 0 fail)` guard.
- `TASKS.md`: queue row DONE, and checklist SB-M58-001..006 checked with the caveat "drafts, owner/legal review + store submission pending".

Commits: 3aaf540d (docs + test + CI), c3b18149 (docs/tasks). Not pushed.

## Acceptance criteria
1. [x] Inventory of every third-party component with licence: section 1 of the inventory (LICENSE files read: `addons/game_feel_flow/LICENSE` MIT, `addons/saltmire_spark/LICENSE.txt` MIT, owner-local `addons/godot_ai/LICENSE` MIT).
2. [x] Every piece of data stored or sent, and every permission with its reason: sections 2-3. Nothing leaves the device. Remote content is disabled by `data/config/remote_content_runtime_v1.json` (`enabled: false`, empty URLs). The analytics sink is NullSink with consent OFF. The Android permissions are VIBRATE and POST_NOTIFICATIONS. iOS has no keys.
3. [x] Planned section for AdMob, Billing and cloud: section 1 "Planned", plus the planned columns in 5.1, 5.2 and 6. These are stated as unverified.
4. [x] Remove unnecessary collection: section 4. The hygiene table found no excess collection, so no code change was needed. godot_ai is untracked, CI builds from a clean checkout, and the new test now guards `project.godot`. Two items are flagged for an owner decision: POST_NOTIFICATIONS is requested although nothing is delivered yet (SB-M43-171), and there is no MIT licences/credits screen (SB-M59-010).
5. [x] DRAFT Play Data safety and Apple App Privacy answers for the current and planned builds: sections 5.1 and 5.2, marked DRAFT. Nothing was submitted.
6. [x] DRAFT privacy policy (EN): `docs/PRIVACY_POLICY_DRAFT.md`.
7. [x] DRAFT IARC answers and child-directed considerations: section 6, linked to SB-M58-007. The planned build gets the "In-Game Purchases (Includes Random Items)" descriptor because of the Random Booster and packs bought with SB.
8. [x] Static test fails on an unlisted permission or network use: LOCAL_PASS `M58 privacy inventory evidence: PASS (7/7 cases, 0 fail)`. Negative proof: I removed the backticked `permissions/vibrate` and `user://analytics_v1.json` from the doc and the suite printed `FAIL android permission listed: permissions/vibrate`, `FAIL user:// path listed: user://analytics_v1.json`, `FAIL (7/7 cases, 2 fail)` with exit 1. The doc was then restored.
9. [x] Added to CI validate with the workflow pattern: suite list and exact-summary guard.

## Validation
- `"$GODOT" --headless --path . -s res://tests/m58_privacy_inventory.gd`: exit 0, 0 SCRIPT ERROR/Parse Error lines, last line `M58 privacy inventory evidence: PASS (7/7 cases, 0 fail)`. LOCAL_PASS.
- Mutation run: exit 1 with 2 FAIL lines, as expected.
- `git diff --cached --check`: clean.
- No other suites were run because no game script changed. No CI run and no phone build.
- The worktree's Godot import artifacts (.import, .uid, .translation files and the project.godot rewrite) were restored or removed. `git status --porcelain` is empty.

## Log
### Round 1
I surveyed the export presets (the Android template and the iOS heredoc preset), project.godot, the addons, all network, permission and `user://` usage, the save sections, analytics, the notification permission and the logs. Then I wrote the inventory, the store, IARC and policy drafts, and the static guard plus its CI hook, and updated TASKS.md.

Notes for the owner, not changed:
- Running the guard in the owner Desktop checkout fails on purpose, because the local `project.godot` adds the godot_ai autoload. Do not ship local exports.
- The iOS `PrivacyInfo.xcprivacy` written by Godot is unverified until a release export is inspected.
