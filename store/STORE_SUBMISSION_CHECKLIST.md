# ScrubBots store submission checklist

Everything for the Google Play Console and App Store Connect pages, where each answer or file
lives, and which steps need the owner. Nothing here has been uploaded to any store.

Owner steps are marked **[OWNER]**: they need the owner's login, a legal agreement, or tax/bank
data. Claude does every other step once the owner has signed in (CLAUDE.md §0D.5). A public
production release also needs the owner (§0D.5); internal testing and TestFlight do not.

## Files in this folder

| What | Where |
|---|---|
| Listing texts EN | `store/listing/en.md` |
| Listing texts TR | `store/listing/tr.md` |
| Data safety, IARC, App Privacy, age rating answers | `store/DATA_SAFETY_AND_RATINGS.md` |
| Privacy policy (TR + EN, GitHub Pages) | `docs/privacy/index.html` -> `https://sekiph82.github.io/Scrubbots/privacy/` |
| Play icon 512x512 | `store/graphics/google_play_icon_512.png` |
| App Store icon 1024x1024 (opaque) | `store/graphics/app_store_icon_1024.png` |
| Play feature graphic 1024x500 | `store/graphics/google_play_feature_graphic_1024x500.png` |
| Play phone screenshots 1080x2160 | `store/screenshots/google_play/{en,tr}/` |
| App Store 6.9" screenshots 1290x2796 | `store/screenshots/app_store_6.9in/{en,tr}/` |
| App Store 6.5" screenshots 1242x2688 | `store/screenshots/app_store_6.5in/{en,tr}/` |

Each screenshot folder has the same five real-game screens, in upload order: `1_home`,
`2_collection`, `3_robots`, `4_gameplay` (level 15 mid-level), `5_win`. They were captured from
the real app (`tests/tools/store_screens_capture.gd`, GPU, throw-away save). To redo them:
`godot --path . -s res://tests/tools/store_screens_capture.gd -- --out <abs dir> --size 1080x2160 --lang en`
(not `--headless`; one size and language per run). Graphics: `python store/tools/make_graphics.py`.
Check limits and sizes: `python store/tools/check_listing.py`.

The `store/` folder holds a `.gdignore`, so Godot never imports it and it can't reach an APK,
AAB or IPA. The Android export template also lists `store/*` in `exclude_filter`.

Play's 1080x2160 is the tallest size it accepts (the long side may be at most twice the short
side), so 1080x2340 captures would be rejected.

## Before either console

1. **[OWNER]** Pick the public support e-mail. Claude then replaces `sekiphayit1982@gmail.com` in
   `docs/privacy/index.html` (both languages).
2. Merge this branch to `main`, then enable GitHub Pages: source "Deploy from a branch", `main`,
   `/docs`. Claude can do this with `gh api` (the repo is public and Pages is free). Then check that
   `https://sekiph82.github.io/Scrubbots/privacy/` loads.
3. Job 168 builds: a signed release AAB (upload key) and an App Store-signed IPA.
4. Job 170 integration: products created from its product table, real AdMob app/unit IDs, UMP
   and ATT messages. **[OWNER]** AdMob account sign-in, AdMob payments profile (tax/bank), and the
   UMP consent message published in the AdMob Privacy & messaging tab.
5. The in-game Settings > Privacy text still says "this version shows no ads" and "A link to the
   full privacy policy will be added before release" (`PRIVACY_ADS`, `PRIVACY_POLICY_LINK` in
   `scripts/ui/ui_text.gd` / `ui_text_tr.gd`). Update it to the ads truth and this policy URL in
   the job that ships the ads (job 170 or a follow-up), before the first public release.

## Google Play Console

Account and app
- [ ] **[OWNER]** Sign in; accept the Developer Distribution Agreement; finish identity
      verification if Play still asks for it.
- [ ] **[OWNER]** Payments profile: merchant account, tax info and bank account (needed for paid
      in-app products).
- [ ] Create app: name from `listing/en.md` "App name", default language **English (United
      States) en-US**, Game, Free. Declarations: Developer Program Policies, US export laws.
      **[OWNER]** ticks these declarations (legal acceptance).

Store presence > Main store listing (en-US), then add translation **Turkish tr-TR**
- [ ] App name: "App name" block
- [ ] Short description: "Google Play short description" block
- [ ] Full description: "Full description" block
- [ ] App icon: `graphics/google_play_icon_512.png`
- [ ] Feature graphic: `graphics/google_play_feature_graphic_1024x500.png` (same for both languages)
- [ ] Phone screenshots: `screenshots/google_play/en/` (en-US) and `.../tr/` (tr-TR), 5 each
- [ ] 7" / 10" tablet screenshots: optional, skip (the game is portrait phone-first)
- [ ] Video: none

Store presence > Store settings
- [ ] App category: **Game > Puzzle**. Tags: Puzzle, Casual, Pixel art (pick the closest offered)
- [ ] Contact details: e-mail **[OWNER]** (same as the privacy policy); website optional
      (`https://github.com/Sekiph82/Scrubbots` or none); phone optional

Policy > App content (answers in `DATA_SAFETY_AND_RATINGS.md`)
- [ ] Privacy policy: Pages URL (section 5)
- [ ] App access: all functionality available without special access
- [ ] Ads: contains ads
- [ ] Content rating: IARC questionnaire (section 2)
- [ ] Target audience and content: 13+ only (section 1)
- [ ] Data safety (section 1)
- [ ] Advertising ID declaration (section 1)
- [ ] Government apps / Financial features / Health: No

Monetize > Products > In-app products
- [ ] Create the five `scrubbucks_*` consumables and `no_ads` from job 170's product table
      (`data/config/store_products_v1.json`; prices from `reference_usd`), titles/descriptions in
      EN + TR. Needs the payments profile first.

Release
- [ ] Internal testing track: upload the AAB from job 168, add testers (owner's Google account),
      roll out. Autonomous.
- [ ] Play App Signing: accept Google-managed app signing key on first upload (the job 168
      keystore is the upload key). **[OWNER]** if the console asks to confirm.
- [ ] Release notes: "What's new" block, EN + TR.
- [ ] New personal developer accounts must run a closed test (at least 12 testers for 14 days)
      before production access. **[OWNER]** recruit testers if the account is personal.
- [ ] Production release: **[OWNER]** decision (§0D.5).

## App Store Connect

Account and app
- [ ] **[OWNER]** Sign in; accept the latest Apple Developer Program License Agreement and the
      **Paid Apps Agreement** (Business > Agreements), with tax forms and bank account. Without the
      Paid Apps Agreement the in-app purchases can't be tested or sold.
- [ ] Bundle ID `com.sekiph82.scrubbots` registered in Certificates, Identifiers & Profiles with
      the In-App Purchase capability (job 168 lists the signing steps).
- [ ] New App: platform iOS, name from "App name" block, primary language **English (U.S.)**,
      bundle ID above, SKU `scrubbots-ios`, full access.

App Information
- [ ] Name, Subtitle: "App name", "App Store subtitle" blocks, EN-US and add **Turkish** localization
- [ ] Category: primary **Games**, subcategory **Puzzle**; secondary **Games > Casual**
- [ ] Content rights: no third-party content requiring rights (all art is the owner's)
- [ ] Age rating questionnaire (section 4 of `DATA_SAFETY_AND_RATINGS.md`)
- [ ] Privacy policy URL: Pages URL (both localizations)

App Privacy
- [ ] Data collection answers (section 3)

Pricing and Availability
- [ ] Price: Free (USD 0). All territories unless the owner wants fewer.
- [ ] **[OWNER]** Trader status for the EU Digital Services Act (trader or non-trader, address
      and phone shown on the EU page if trader).

Version page (1.0)
- [ ] Promotional text, Description, Keywords: blocks from `listing/en.md` / `tr.md`
- [ ] Support URL: required. Use `https://sekiph82.github.io/Scrubbots/privacy/` until a support
      page exists, or a mailto-backed page; marketing URL optional
- [ ] 6.9" screenshots: `screenshots/app_store_6.9in/{en,tr}/`; 6.5" screenshots:
      `screenshots/app_store_6.5in/{en,tr}/` (5 each). iPad: not needed if the build is iPhone only
      (check the IPA's device family in job 168; if it includes iPad, 13" iPad screenshots are
      required).
- [ ] App icon: comes from the IPA. It must be opaque; the repo's `app_icon_ios_1024.png` has
      transparent corners, so the iOS export should use `store/graphics/app_store_icon_1024.png`
      (or an equivalent opaque icon). Job 168 / the iOS export owns that switch.
- [ ] Copyright: "2026 <owner legal name>" **[OWNER]** confirms the name to show
- [ ] Build: select the TestFlight build uploaded by the job 168 workflow
- [ ] In-App Purchases: create the same six products (job 170 table), add them to the version
- [ ] App Review information: contact name, phone, e-mail **[OWNER]**; sign-in not required;
      notes: "No account. Ads via AdMob with UMP + ATT. Purchases: Scrub Bucks packs, Remove Ads."
- [ ] Export compliance: uses only standard encryption (HTTPS) -> exempt;
      `ITSAppUsesNonExemptEncryption = NO` in the Info.plist avoids the question per build
- [ ] Version release: manual
- [ ] TestFlight internal testing: autonomous. Submission for public release: **[OWNER]** (§0D.5).
