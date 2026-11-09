# Privacy and Data Inventory (SB-M58-001..006)

Status: **DRAFT for owner/legal review.** Nothing here has been submitted to Google Play,
App Store Connect or IARC. The owner submits; the factory never does (CLAUDE.md §0D.5).

Covers: third-party components (001), data the game stores or sends (002), collection
hygiene (003), privacy disclosures (004, policy text in `docs/PRIVACY_POLICY_DRAFT.md`),
store declarations (005) and the age-rating questionnaire (006). Section 7 covers the
child-directed review (007), analytics / ads consent (008/009, Settings -> PRIVACY),
notification privacy (010), account / cloud data and display names (011/012), receipt
retention (013) and localization / accessibility of the privacy screens (014).

Guard: `tests/m58_privacy_inventory.gd` (CI validate) fails when a game script or scene uses
a network / native-permission API, writes a new `user://` path, or the Android/iOS export
gains a permission or privacy key that this file does not list. Update this file in the same
commit.

State: current = `main` as of 2026-11-06 (app version from `data/config/app_version.json`).
Planned = the owner decisions of 2026-10-22 that are not integrated yet (AdMob, Play
Billing/StoreKit, Play Games/Game Center/iCloud).

## 1. Third-party components (SB-M58-001)

### Shipped in the game build

| Component | Where | Version | License | What it does | Data |
|---|---|---|---|---|---|
| Godot Engine | engine + export templates | 4.7.2 stable | MIT (plus its bundled third-party libraries, e.g. FreeType, mbedTLS, libogg/Vorbis/Theora, zlib, all permissive; full list in `Engine.get_copyright_info()`) | runtime | Collects nothing by itself. No engine telemetry. |
| Game Feel Flow | `addons/game_feel_flow` | 1.0.0 | MIT (`addons/game_feel_flow/LICENSE`) | presentation effects (autoload `GameFeelFlow`) | none, no I/O beyond its own resources |
| Saltmire Spark | `addons/saltmire_spark` | 1.0.0 | MIT (`addons/saltmire_spark/LICENSE.txt`) | particle/spark effects (autoload `Spark`) | none |
| ScrubbotsNotify (own code, SB-M43-171/172) | `addons/scrubbots_notify` (Android export plugin) + `native/` (Android plugin Java, iOS GDExtension Objective-C) | 1.0.0 | own code | schedules / cancels ONE local reminder (Android AlarmManager + notification, iOS UNUserNotificationCenter) and asks the iOS notification permission. Only in builds made with the workflow input `local_notifications` (default off, `docs/RELEASE_BUILDS.md`). | none: no network, no identifiers; the reminder text and time stay on the device |

Content assets (not code): canonical SFX generated with ElevenLabs (`assets/audio/sfx/README.md`),
music selected by the owner (`coordination/OWNER_M33_MUSIC_SELECTION_DECISION_V03.md`), owner
opening video (`assets/brand/opening/PROVENANCE.md`), owner/generated UI art
(`ASSET_GENERATION_MANIFEST.json`). No fonts are bundled (Godot default font). These carry no
code and send nothing; their commercial-use licences are a provenance matter for SB-M59-010.

MIT attribution: MIT requires the copyright notice to travel with the binary. Settings >
CREDITS (SB-M59-010, `scripts/ui/credits_screen.gd`) shows the Godot licence, the engine's
third-party notices and both addon LICENSE files verbatim; the export presets ship those files
(`include_filter`). See `docs/RELEASE_BUILDS.md`.

### Not shipped (development only)

| Component | Where | License | Why it is not in a build |
|---|---|---|---|
| Godot AI (MCP editor plugin) | `addons/godot_ai` | MIT | Owner-local only: untracked in git, so CI exports (which build from a clean checkout) never contain it. It has its own editor telemetry and a WebSocket to a local MCP server; none of that runs in the game. `tests/m58_privacy_inventory.gd` fails if the committed `project.godot` ever references it. Both export presets also exclude `addons/godot_ai/*` (SB-M59-010). A local export from the owner's Desktop checkout would still reference it (local `project.godot` adds its autoload): do not ship local exports. |
| Python / stdlib tools | `tools/`, `level_factory/`, `content_pipeline/` | own code | excluded from every export (`.github/android/family_first10_export_exclusions.txt`) |
| GitHub Actions (pinned actions) | `.github/workflows` | MIT/Apache | CI only |

### Planned (owner decisions 2026-10-22, not integrated, stated from public docs, unverified)

| Component | Task | What it will collect (per the vendor's public docs) |
|---|---|---|
| Google Mobile Ads SDK (AdMob), Android + iOS | SB-M57-001..011 | Device/advertising identifiers (AAID / IDFA when allowed), IP address (coarse location), app interactions, diagnostics (crash/performance), ad-performance data. Shared with Google for advertising and fraud prevention. Needs consent (UMP / GDPR, US states) and, on iOS, ATT before IDFA. |
| Google User Messaging Platform (UMP) | SB-M58-009 | Consent string stored on device; device info for consent geography. |
| Google Play Billing Library | SB-M57-012..016 | Purchase history (product id, order id, purchase token, time) processed by Google; the game would keep only what entitlement needs (SB-M58-013). |
| Apple StoreKit | SB-M57-012..016 | Transactions processed by Apple; the game sees transaction ids/receipts. |
| Google Play Games Services (Saved Games, later Friends) | SB-M43-153..160, SB-M61 | Play Games player id, gamer profile (display name/avatar), save blobs in Google Drive app data. |
| Apple Game Center + iCloud | SB-M43-153..160, SB-M61 | Game Center player id/alias; save data in the user's iCloud. |
| Analytics provider | SB-M56 later / SB-M58-008 | Undecided. Events are already privacy-minimised (`docs/ANALYTICS_TAXONOMY_V1.md`); a provider adds its own identifiers. |

## 2. Data the game stores or sends (SB-M58-002)

**Nothing leaves the device in the current build.** No account, no login, no identifiers,
no ads, no purchases, no analytics provider, no crash reporter. The only network code
(remote content, below) is disabled by config.

### Network

| Code | State | What it would send |
|---|---|---|
| `scripts/content_runtime/https_content_transport.gd` (HTTPS GET, created by `scripts/content_runtime/remote_content_manager.gd`, started in `scripts/app/main.gd`) | **disabled**: `data/config/remote_content_runtime_v1.json` has `"enabled": false` and empty URLs, so no transport is created and no request is made | When enabled: anonymous HTTPS GET of the content manifest and level packs. No credential, cookie, id or query string; the server would see the IP address and Godot's default User-Agent. Enabling it also needs `permissions/internet` in the Android preset (and an update here). |

### Native permission calls

| Code | Purpose |
|---|---|
| `scripts/economy/notification_permission.gd` | `OS.request_permission("android.permission.POST_NOTIFICATIONS")`, only after the player turns reminders ON and taps Allow in the explainer (SB-M43-146). Never on boot. iOS: the same explainer calls the native `ScrubbotsNotify.request_authorization()` (UNUserNotificationCenter alert + sound, SB-M43-171). |
| `scripts/economy/local_notifications.gd` | `Engine.get_singleton("ScrubbotsNotify")` (Android plugin) / `ClassDB.instantiate("ScrubbotsNotify")` (iOS GDExtension): schedules one local reminder when the app goes to the background (reminders ON + permission granted only), cancels it on every open (SB-M43-172). No push server, nothing sent. |

### Files on the device (`user://`, app-private storage)

| Path | Written by | Contents | Leaves device? |
|---|---|---|---|
| `user://scrubbots_save.dat` (+ temp/backup siblings) | `scripts/save/save_service.gd` via `scripts/app/app_state.gd` | settings (volumes, haptics, Reduced Effects, color symbols), level progression, economy (wallet, hearts, boosters, collection cards/packs, daily/orders, events, records, the weekly Ranks count with its week start, gift/streak, notification preferences and quiet hours, permission ask/decline timestamps, the time of the one scheduled local reminder, FTUE flags, the No Ads entitlement flag; once a store provider exists, applied purchase tokens as `store:<token>` reward transaction ids so a purchase is never granted twice). In-game pack "receipts" are internal reward transactions, not store purchases. Timestamps are device clock values used for timers. No name, email, device id or location. | No |
| `user://analytics_v1.json` | `scripts/app/analytics_service.gd` | `version`, `consent` (default false; set only by the Settings -> PRIVACY switch, section 7.2), first consented local day, retention markers sent. No events are stored (NullSink). | No |
| `user://audio_settings.cfg` | `scripts/audio/audio_settings_service.gd` | legacy M33 volume file, read once for migration into the save | No |
| `user://haptics_settings.cfg` | `scripts/haptics/haptics_settings_service.gd` | haptics on/off (standalone service default path) | No |
| `user://__scratch_haptics.cfg` | `scripts/save/save_service.gd` | scratch path for validating a candidate save's haptics block (not written during validation) | No |
| `user://content/` | `scripts/content_runtime/remote_content_manager.gd` | remote level pack cache; empty while remote content is disabled | No |
| `user://debug_m33_m41_playtest_save.dat` | `scripts/debug/m33_audio_playtest.gd` | isolated save of a debug playtest scene (developer F6 only, not reachable from the game UI) | No |
| `user://real_play_%d_%d.save` | `scripts/gameplay/solver/real_play_driver.gd` | throw-away save of the developer real-play driver (tests/tools) | No |
| `user://` (directory root) | `scripts/tools/level_importer.gd`, `scripts/tools/production_art_level_builder.gd` | developer import tools (editor/CLI only) | No |

The game save is in app-private storage; Android auto-backup and iOS device backups may copy
it to the user's own Google/iCloud backup (OS behaviour, not the game's).

### Logs

`print` output goes to the OS log (logcat / Xcode console), never to a server:
`[OPENING_METRICS]` (`scripts/app/opening_screen.gd`: outcome, latencies, screen/video size,
OS name, display server) and `HOME_ASSET_DIAG` (`scripts/ui/home/home_screen.gd`: asset load
status). No identifiers or personal data. Analytics validation warnings print only in debug
builds.

### Analytics events

Defined in `docs/ANALYTICS_TAXONOMY_V1.md`: consent OFF by default, NullSink, int/bool/enum
params only, no ids or timestamps. In the current build no event is stored or sent.

| Events | Data (all coarse enums / small ints) |
|---|---|
| `session_start`, `session_end`, `retention_day` | trigger, duration bucket, last level outcome, d1..d30 marker |
| `level_start`, `level_first_action`, `level_end` | level number, attempt / duration / progress buckets, outcome, difficulty class, cadence slot |
| `assist_shown`, `assist_fail_closed`, `assist_dismissed`, `booster_acquire`, `booster_use` | level, booster ids, acquisition path, ok / reason |
| `economy_source`, `economy_sink`, `hearts_empty` | currency, amount bucket, source / sink category, gate place |
| `pack_opened`, `collection_set_complete`, `collection_master_complete`, `robot_unlock`, `robot_equip` | pack kind, new / duplicate count buckets, best rarity, pity flag, dry-streak bucket, set number, campaign level, robot roster order |
| `screen_view`, `shop_open`, `launch_failed` | screen name, Shop entry source, launch refusal reason |
| `ad_offer_shown`, `ad_request`, `ad_result` | placement, product, available / ok, refusal reason, outcome (no tokens or transaction ids) |
| `notify_toggle`, `notification_prompt`, `deep_link_open` | reminder category on / off, explainer step and OS answer, deep link destination |
| `next_cleanup_shown`, `next_cleanup_tap`, `journey_progress` | teaser available / image flags, refusal reason, journey slot / cycle number, first-clear flag |
| `daily_order_done`, `daily_order_claim` | order tier, metric, target number |
| `weekly_event`, `first_try`, `comeback_window`, `catchup_step` | step, milestone number, run depth, Catch-Up offered flag, step number |
| `ranks_view` | table (all-time / weekly), rank band number |

## 3. Permissions (SB-M58-002/003)

### Android (`.github/android/export_presets_family_first10.cfg`)

| Permission | Why | Status |
|---|---|---|
| `permissions/vibrate` | haptic feedback (Settings HAPTICS, default ON; `docs/M34_HAPTICS_DEVICE_VALIDATION.md`) | needed |
| `permissions/post_notifications` | Android 13+ runtime permission, asked contextually when the player opts in to reminders | needed: reminders are delivered by the ScrubbotsNotify plugin (SB-M43-172) in builds with the input `local_notifications`; builds without it still ask but deliver nothing. Not a data-collection permission and not a Data safety item. |

The ScrubbotsNotify AAR adds no permission: `setAndAllowWhileIdle` needs none (no
`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`), and there is no `RECEIVE_BOOT_COMPLETED` (a reboot
drops the reminder; the next app close schedules it again). Its manifest declares `uses-sdk` so the
merger adds no implied legacy permissions, and its receiver is not exported.

No `INTERNET`, location, camera, microphone, contacts, storage, phone-state or account
permission. Godot's export adds no other dangerous permission. Advertising ID permission
(`com.google.android.gms.permission.AD_ID`) arrives with AdMob (planned).

### iOS (`.github/workflows/ios-ipa.yml` preset)

No `privacy/*` usage descriptions, no `capabilities/*`, no extra Info.plist content: the
build asks for no protected resource. Local notifications (ScrubbotsNotify, input
`local_notifications`) need no usage description and no push capability; the OS prompt comes
only after the in-game explainer. Godot 4.3+ writes a `PrivacyInfo.xcprivacy` for the
engine's required-reason APIs (file timestamps, system boot time, disk space, UserDefaults);
**unverified**: confirm it is present in the exported Xcode project before App Store
submission (SB-M58 follow-up for the release build).

Planned iOS additions: `NSUserTrackingUsageDescription` + ATT prompt only if personalised ads
use IDFA (SB-M58-009), SKAdNetwork ids from AdMob, Game Center / iCloud entitlements.

## 4. Collection hygiene review (SB-M58-003)

Checked 2026-11-06 on `main`:

| Check | Result |
|---|---|
| Network calls in game scripts/scenes | only the disabled remote-content transport (above) |
| Device identifiers (`OS.get_unique_id`, model, locale sent anywhere) | none used |
| Free-text analytics params / PII | impossible by schema (`docs/ANALYTICS_TAXONOMY_V1.md`, `pii_scan` case in `tests/m56_analytics_taxonomy.gd`) |
| Unused permissions | none collect data; `post_notifications` delivers reminders only in builds with the `local_notifications` input |
| Editor-only Godot AI plugin in builds | not tracked, not in CI builds; now guarded by the test |
| Dev/test trees in builds | excluded and scanned by the export workflows |
| Debug logs with device info | `OPENING_METRICS` holds OS name and screen size only, local log, used for device validation; kept |

No code change was needed: nothing collects more than gameplay needs.

Needs an owner decision (not changed): the licences screen (SB-M59-010). Open until the
`local_notifications` input is the default: builds without it still ask `post_notifications` but deliver nothing.

## 5. Store declarations, DRAFT (SB-M58-005)

### 5.1 Google Play Data safety

**Current build (no ads, no billing, no analytics provider, remote content off)**

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all user data encrypted in transit? | Not applicable (no data transmitted) |
| Do you provide a way for users to request that their data be deleted? | Not applicable (no data collected; uninstall removes local data) |
| Families / Designed for Families | see SB-M58-007 |

**Planned build (AdMob + Play Billing + Play Games Saved Games), from Google's published SDK
disclosures, verify against the SDK versions actually shipped**

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Device or other IDs (advertising ID, app set ID) | Yes | Yes (AdMob) | Advertising or marketing, Analytics, Fraud prevention | Required by ads (non-personalised ads still use it for fraud/frequency) |
| Approximate location (from IP) | Yes | Yes (AdMob) | Advertising, Fraud prevention | Required by ads |
| App interactions (ad views/taps) | Yes | Yes (AdMob) | Advertising, Analytics | Required by ads |
| Diagnostics (crash logs, performance) | Yes | Yes (AdMob) | Analytics | Required by ads |
| Purchase history | Yes | No (Google processes it as the payment provider) | App functionality | Only when buying |
| Game progress / save data (Play Games Saved Games) | Yes | No | App functionality (cloud save) | Optional (cloud save) |
| Name/user ID (Play Games profile) | Yes | No | App functionality, Account management | Optional |
| Encrypted in transit | Yes (SDKs use TLS) | | | |
| Deletion request path | Needed (SB-M58-011): in-game delete of cloud save + link in policy | | | |

Analytics provider events: add "App interactions -> Analytics" when SB-M58-008 picks one.

### 5.2 Apple App Privacy ("nutrition label")

**Current build:** **Data Not Collected.**

**Planned build (AdMob + StoreKit + Game Center/iCloud), per Google's AdMob iOS disclosure
guidance and Apple's definitions, verify at submission**

| Data type | Linked to user | Used for tracking | Purposes |
|---|---|---|---|
| Identifiers > Device ID (IDFA, only with ATT allow) | No | Yes | Third-Party Advertising |
| Location > Coarse location (IP) | No | Yes | Third-Party Advertising |
| Usage Data > Advertising Data | No | Yes | Third-Party Advertising, Analytics |
| Usage Data > Product Interaction | No | No | Analytics |
| Diagnostics > Crash / Performance data | No | No | Analytics |
| Purchases > Purchase History | Yes | No | App Functionality |
| Identifiers > User ID (Game Center player id) | Yes | No | App Functionality |
| User Content > Other (save data in iCloud) | Not collected by the developer (stays in the user's iCloud) | | |

If ads run non-personalised only and ATT is never shown, "Used for tracking" turns No for the
identifier rows; that is the SB-M58-009 decision.

## 6. Age rating, DRAFT IARC questionnaire (SB-M58-006)

Category: Game. Answers for the current build; changes for the planned build noted.

| Topic | Answer | Note |
|---|---|---|
| Violence | No | Robots clean pixel art; no harm to characters |
| Fear / horror | No | |
| Sexuality / nudity | No | |
| Language (profanity, crude humour) | No | |
| Controlled substances (drugs, alcohol, tobacco) | No | |
| Discrimination / hate | No | |
| Gambling (real or simulated casino) | No | |
| Random items purchasable | **Current: No** (no real money). **Planned: Yes**: Random Booster (350 SB) and card packs bought with ScrubBucks, which become purchasable with real money (SB-M57-012). Expect the "In-Game Purchases (Includes Random Items)" descriptor. | |
| In-app purchases (digital goods) | Current: No. Planned: Yes | |
| Users interact / chat / share content | No (Friends post-launch has no chat; heart gifts only, SB-M61) | re-answer when Friends ships |
| Shares location | No | |
| Shares personal information with third parties | Current: No. Planned: Yes (advertising SDK) | |
| Unrestricted internet / web browser | No | |
| Digital purchases | see above | |
| Ads | Current: No. Planned: Yes (banner, interstitial, opt-in rewarded) | |

Expected outcome: lowest tier in every region (ESRB Everyone, PEGI 3, USK 0, ClassInd L,
Apple 4+), with the interactive-elements notices "In-Game Purchases (Includes Random Items)"
once paid currency ships. Apple's age rating is answered separately in App Store Connect with
the same facts.

### Child-directed considerations (full review: section 7.1)

- Cute robots and bright pixel art may appeal to children; Google Play's target-audience
  question decides whether Families policy applies. If the target audience includes under-13s,
  AdMob must use `tag_for_child_directed_treatment` / under-age-of-consent settings, only
  Families-certified ad SDKs, no personalised ads, and the Data safety answers change.
- Paid random items next to children is the main regulatory risk (several regions restrict
  loot boxes for minors). The owner decides the target audience (13+ vs mixed) in SB-M58-007.
- The current build is safe for any audience: no data collected, no ads, no purchases.

## 7. Child-directed, consent, notifications, accounts, receipts (SB-M58-007..014)

Status: **DRAFT for owner/legal review.** 7.1 and 7.5 are analysis and requirements for
features that do not exist yet; 7.2, 7.3, 7.4, 7.6 and 7.7 describe shipped code, guarded by
`tests/m58_privacy_consent.gd` (CI validate, exact 7/7).

### 7.1 Child-directed review (SB-M58-007)

Facts: bright pixel art and cute robots can appeal to children, so the game must be treated
as mixed audience unless the owner declares a 13+ (or 16+) target audience in Play Console
and App Store Connect. The current build collects nothing, shows no ads and sells nothing,
so no rule below is triggered today.

| Law / policy | Applies when | What it would require |
|---|---|---|
| US COPPA | the game is directed to under-13s, or mixed audience and personal information (an advertising id or other persistent id counts) is collected from a user known or treated as under 13 | verifiable parental consent, or collect nothing: AdMob `tag_for_child_directed_treatment`, no personalised ads, no analytics provider id for those users |
| GDPR Art. 8 / UK Age Appropriate Design Code ("GDPR-K") | consent is the legal basis for processing a child's data in the EU / UK (age of digital consent 13 to 16, by country) | parental consent below that age, or no consent-based processing (no personalised ads, no consent-based analytics); high-privacy defaults |
| Google Play Families policy | the Play Console target audience includes under-13s | Families-certified ad SDKs only, no personalised ads or advertising id for children, Families-compliant Data safety |
| Apple Kids category (guideline 1.3) | only if the game is listed in the Kids category | no third-party analytics or ads outside Apple's limits; parental gate for links and purchases |
| Loot-box rules (Belgium, Netherlands guidance, PEGI / ESRB descriptors) | real-money purchasable random items (Random Booster, card packs once ScrubBucks are sold, SB-M57-012) | "In-Game Purchases (Includes Random Items)" descriptor; some regions restrict sale to minors; odds disclosure |

Recommendation (owner / legal decide; one line under `## Questions for Şekip` in TASKS.md
when the first trigger below is about to ship):

1. Declare a **13+ target audience** in both stores (not Kids, not Families) and keep the
   game safe for younger players anyway (no chat, no user content, no social exposure).
2. Before any ads SDK or analytics provider is enabled, add a **neutral age screen** (year of
   birth, no default, no hint which answer unlocks anything), shown once before the first
   consent prompt. Under 16 or unknown: analytics consent stays OFF and is not offered, ads
   are non-personalised with `tag_for_under_age_of_consent` / child-directed treatment, no
   IDFA / ATT prompt.
3. Real-money random items: block for under-16 answers or show odds, per the owner's region list.

**No age gate is implemented now, and none is required yet**: analytics is OFF by default and
sends nothing (`NullSink`), and there is no ads SDK, purchase or account. The age screen
becomes required with the first of: an ads SDK (SB-M57-001..011), an analytics provider (the
SB-M56-015 gate in `docs/ANALYTICS_TAXONOMY_V1.md`), real-money purchases (SB-M57-012).

### 7.2 Analytics consent (SB-M58-008)

- Screen: Settings -> PRIVACY (`scripts/ui/privacy_screen.gd`, opened by
  `scripts/app/main.gd` `open_privacy()`; the button shares the Settings CLOSE row so the
  panel keeps its height). Its SHARE ANALYTICS switch is the only production caller of
  `AnalyticsService.set_consent` (guarded).
- Default **OFF** (opt-in). Without consent nothing is validated, queued or stored; turning it
  off drops the queue and the local retention markers. The choice is written at once to
  `user://analytics_v1.json` (separate from the game save).
- Legal basis by region, for when a provider exists (draft): EU / EEA / UK consent (ePrivacy:
  an SDK reads / writes device storage), so opt-in; US state laws (CCPA / CPRA and similar)
  allow opt-out, but one global opt-in is simpler and stricter; Türkiye (KVKK) explicit
  consent for non-essential processing fits opt-in. No region detection is needed while the
  default is OFF everywhere.
- Today the switch changes nothing outside the device: the sink is `NullSink`, and the screen
  says "In this version nothing is sent anywhere".

### 7.3 Ads consent (SB-M58-009)

No ads SDK exists, so the PRIVACY screen shows one text line and no switch ("this version
shows no ads, so there is no ad choice to make"); there is no placeholder toggle that does
nothing. When AdMob ships (SB-M57-001..011): Google UMP consent form on first launch where
UMP requires it (EEA / UK / US states), a "privacy options" entry on the PRIVACY screen when
UMP reports it required, the iOS ATT prompt only after the UMP form, and refusing
personalised ads keeps the game fully playable (non-personalised ads; rewarded ads stay
optional). Under-16 or unknown age: 7.1.

### 7.4 Notification privacy (SB-M58-010)

- Reminders are local only (`scripts/economy/local_notifications.gd`, SB-M43-172): no push
  server, no token, nothing sent. The native call carries exactly (title = app name, body =
  one fixed reminder copy, seconds until it fires). No name, level, amount or other value is
  inserted into any reminder copy, English or Turkish; the guard fails on a `%` placeholder.
- Tapping a reminder opens the app's launcher activity; no deep-link payload is attached.
  In-app deep links (`NotificationPolicy.deep_link`) accept only allowlisted destinations;
  anything else lands on Home.
- The OS permission is asked only after the player turns reminders ON and taps Allow in the
  explainer (SB-M43-146). The copy is safe on a lock screen (no personal data).

### 7.5 Account, cloud data and display name (SB-M58-011 / 012)

- **Today there is no account, login, cloud save or server**: nothing to export, delete
  remotely or sign out of; uninstalling deletes everything (the PRIVACY summary says so).
  Ranks is a personal ladder: the player is shown as "You", no name is stored or shown to
  anyone and no other players exist (SB-M43-122), so 012 is not triggered.
- Planned cloud save (SB-M43-153..160: Play Games Saved Games / Game Center + iCloud) stores
  exactly the game save content (settings, progression, economy, collection, FTUE flags) in
  the player's own Google / Apple account, adding no name, email or device id. Requirements
  before it ships: sign-in optional and the game fully playable without it; a "delete cloud
  save" action on the PRIVACY screen (removes the remote snapshot, keeps the local save);
  sign-out keeps the local save; export through the platform (Google Takeout / Apple data
  request); recovery = restore the latest cloud snapshot after sign-in on a new device, with
  a player-visible conflict choice; the policy names the deletion path (Play Data safety
  "deletion request path").
- Display names (012), only if a real leaderboard or Friends ships (SB-M61): platform alias
  (Play Games / Game Center) by default; never a free-text in-game name without a profanity
  filter, a report action and block / hide; no public names for under-16 answers; no chat.

### 7.6 Receipt / transaction id retention (SB-M58-013)

- No store purchase exists: no Google Play / App Store receipt, order id or purchase token is
  stored. The save holds two internal ledgers:
  - `reward.applied`: ids of reward transactions already granted (e.g. `daily_login:<day>`).
    Strings only: no amounts, times or device data.
  - `pack_receipts`: one receipt per opened card pack (schema, tx id, kind, status and the 3
    or 5 card rows; under 1 KB each). No time, device or store data.
- Retention: **kept for the life of the save, never pruned.** They are the exactly-once
  guarantee: dropping an id would let the same reward or pack be granted / drawn again. Growth
  is bounded by content (one entry per level reward, day, task or pack). The guard pins the
  key sets and the per-receipt size and proves a committed tx replays after a relaunch. Least
  data: nothing in either ledger identifies the player, and they never leave the device
  (except inside the planned cloud save, 7.5).
- When real-money purchases ship (SB-M57-012..016): keep only the store transaction id needed
  for idempotent delivery and restore; never payment details, and not the full receipt blob
  after validation.

### 7.7 Localization and accessibility of privacy screens (SB-M58-014)

The PRIVACY popup and its Settings button are fully keyed (`PRIVACY_*` in
`scripts/ui/ui_text.gd`, Turkish in `scripts/ui/ui_text_tr.gd`). The guard checks, in English
and Turkish, that every label shows its key's copy and the popup fits 1080x1920, plus touch
targets >= 88 px, fonts >= the M50 floor (18 px; the popup uses 24 / 30 / 34) and INK /
ROYAL_EDGE text contrast on the cream card >= 4.5:1. The reminder explainer (SB-M43-146) and
the save-blocked message are keyed the same way (`tests/m51_localization_readiness.gd`).
There is no consent error screen: `set_consent` cannot fail visibly (a failed state-file
write keeps the in-memory choice for the session).
