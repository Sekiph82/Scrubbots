# ScrubBots: data safety, privacy labels and age ratings

Filled answers for the four console questionnaires. They match `docs/privacy/index.html` and the
build as it will ship with job 170 (Google Play Billing / StoreKit, AdMob rewarded + interstitial
+ banner, Google UMP consent, iOS ATT prompt).

Facts these answers rest on (checked in the code, 2026-11-17):
- No account, no login, no own server. `data/config/remote_content_runtime_v1.json` has an empty
  `object_base_url`, so the game downloads no content.
- Save, settings and purchase records are local files under `user://` only.
- The "Share analytics" switch is off by default and its sink sends nothing in this version
  (`PRIVACY_ANALYTICS_HINT`, `scripts/app/analytics_service.gd`).
- Reminders are local notifications (Android `POST_NOTIFICATIONS`).
- Card packs are earned as rewards only. No shop item sells a pack or any other random item for
  money (`data/config/store_products_v1.json`: five Scrub Bucks packs + `no_ads`).
- Purchases go through Google Play Billing / Apple StoreKit. Data processed only on the device or
  by the platform's own payment system is not "collected" by us for either store.

If job 170 adds a crash reporter, analytics upload or any other SDK, update this file and the
privacy policy before submitting.

## 1. Google Play: Data safety

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (through the Google Mobile Ads SDK) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Do you provide a way for users to request that their data is deleted? | **No**. There is no account and we hold no data; uninstalling deletes the game data. (Not required: the app has no account creation.) |
| Account creation | **My app does not allow users to create an account** |

Data types (all: **Collected = yes, Shared = yes**, processed ephemerally = no,
collection required = **yes**, users can't turn off the SDK, but personalisation follows UMP consent):

| Category | Data type | Purposes |
|---|---|---|
| Location | Approximate location (from IP) | Advertising or marketing; Analytics; Fraud prevention, security and compliance |
| Device or other IDs | Device or other IDs (Advertising ID, app set ID) | Advertising or marketing; Analytics; Fraud prevention, security and compliance |
| App activity | App interactions (ad views and taps) | Advertising or marketing; Analytics |
| App info and performance | Crash logs; Diagnostics | Analytics; Fraud prevention, security and compliance |

Not collected: personal info (name, e-mail, user IDs, address, phone), financial info (purchases
are handled by Google Play), health, messages, photos/videos, audio, files, calendar, contacts,
web browsing, precise location, installed apps, search history.

Also in App content:
- **Advertising ID declaration:** Yes, the app uses an advertising ID. Purposes: Advertising or
  marketing; Analytics; Fraud prevention, security and compliance. (The AdMob plugin adds
  `com.google.android.gms.permission.AD_ID`.)
- **Ads:** Yes, my app contains ads.
- **App access:** All functionality is available without special access.
- **Target audience and content:** ages **13-15, 16-17, 18+**. Do not select any under-13 band:
  that would put the app under the Families policy and its certified-ads-only rules.
  "Could your store listing unintentionally appeal to children?" **No**, it is a general puzzle
  game (the robots are cartoon, but there is no child-directed marketing).
- **Government app / Financial features / Health / News:** No.
- **Privacy policy URL:** see section 5.

## 2. Google Play: IARC content rating questionnaire

Email for IARC certificate: the developer account e-mail (owner). Category: **Game** (Puzzle).

| Question | Answer |
|---|---|
| Violence (any, cartoon or realistic) | No. Robots scrub away pixels; nothing is hurt. |
| Blood / gore | No |
| Fear / horror | No |
| Sexuality / nudity | No |
| Language (profanity, crude humor) | No |
| Controlled substances (drugs, alcohol, tobacco) | No |
| Gambling or simulated gambling | No |
| Does the app contain random items (loot boxes) purchasable with real money or in-game currency bought with real money? | No. Card packs are earned only. |
| Miscellaneous: discriminatory content | No |
| Does the app allow users to interact or exchange content (chat, UGC)? | No |
| Does the app share the user's current physical location with other users? | No |
| Does the app allow users to purchase digital goods? | **Yes** (Scrub Bucks packs, Remove Ads) |
| Is the app a web browser or search engine? | No |
| Does the app contain ads? | **Yes** |

Expected result: PEGI 3, ESRB Everyone, USK 0, "In-App Purchases" interactive element.

## 3. App Store Connect: App Privacy ("nutrition label")

Do you or your third-party partners collect data from this app? **Yes** (Google Mobile Ads SDK).
Privacy policy URL: see section 5.

| Data type | Use | Linked to the user? | Used for tracking? |
|---|---|---|---|
| Identifiers: Device ID (IDFA, only after ATT "Allow") | Third-Party Advertising; Analytics | No | **Yes** |
| Location: Coarse Location | Third-Party Advertising; Analytics | No | No |
| Usage Data: Product Interaction | Third-Party Advertising; Analytics | No | No |
| Usage Data: Advertising Data | Third-Party Advertising; Analytics | No | **Yes** |
| Diagnostics: Crash Data, Performance Data, Other Diagnostic Data | Analytics | No | No |

Not collected: Contact Info, Health & Fitness, Financial Info, Purchases (StoreKit is processed
by Apple), User Content, Browsing/Search History, Sensitive Info, Contacts, Precise Location,
User ID, Other Data.

Required with this label: the `NSUserTrackingUsageDescription` string and the ATT prompt (job 170).
Recheck the rows against Google's current page "Prepare for Apple's App Store data disclosure
requirements" (AdMob help) on submission day, because Google updates its SDK disclosure there.

## 4. App Store Connect: Age rating

| Question | Answer |
|---|---|
| Parental controls | No |
| Age assurance | No |
| Unrestricted web access | No |
| User-generated content | No |
| Messaging and chat | No |
| Advertising | **Yes** |
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Prolonged graphic or sadistic realistic violence | None |
| Profanity or crude humor | None |
| Mature or suggestive themes | None |
| Horror / fear themes | None |
| Medical or treatment information | None |
| Alcohol, tobacco or drug use or references | None |
| Simulated gambling | None |
| Sexual content or nudity / graphic sexual content | None |
| Guns or other weapons | None |
| Contests | None |
| Gambling (real money) | No |
| Loot boxes | No |
| Health or wellness topics | No |

Expected rating: **4+**. Made for Kids: **No** (same reason as the Play target audience).
Recommendation for job 170 / the AdMob console: set the maximum ad content rating to **G** so
the ads match a 4+ / PEGI 3 game.

## 5. Privacy policy URL

`https://sekiph82.github.io/Scrubbots/privacy/` (both languages; `#en` / `#tr` anchors).
It goes live once this branch is on `main` and GitHub Pages is enabled for the repo with
source "Deploy from a branch", branch `main`, folder `/docs` (the repo is public, Pages is free).
`docs/.nojekyll` makes Pages serve the files as they are, without a Jekyll build over `docs/`.
Before submitting, replace `sekiphayit1982@gmail.com` in `docs/privacy/index.html` with the support e-mail
(owner item).
