STATUS: READY

# Build: 169-store-listings (SB-STORE-LISTING-2026-11-17)

## Summary
The branch adds a `store/` folder with everything needed for the Google Play and App Store pages, TR and EN. It also adds a bilingual privacy policy page for GitHub Pages. No gameplay code changed and nothing was uploaded.

Commit `7009b55d` on `factory/169-store-listings` (one commit, not pushed). 44 files:
- `store/listing/en.md`, `store/listing/tr.md`: app name, Play short and full description, App Store subtitle, promotional text, keywords, what's new. In-game names (boosters, Hediye Barı, Kart Takası) match `ui_text*.gd`. Facts were checked against code and data: 200 catalog entries, 10 robots, 135 cards in 15 sets, 4 boosters, five slots, Daily/Tasks/Gift Meter/win streak, 2x speed, color symbols, EN/TR, Scrub Bucks packs + `no_ads` from `store_products_v1.json`. Events, friends and cloud save are not mentioned.
- `docs/privacy/index.html`: privacy policy, EN + TR on one page. It covers local saves only, no account, no own server, the off-by-default local analytics switch, local notifications, Play Billing/StoreKit, and AdMob (ad ID, IDFA only after ATT, IP-derived coarse location, UMP consent). It also covers children, KVKK/GDPR rights and changes. The contact is `[CONTACT-EMAIL]` (owner item).
- `docs/.nojekyll`, so Pages serves `docs/` as-is with no Jekyll build. Resulting URL: `https://sekiph82.github.io/Scrubbots/privacy/`. Pages is not enabled yet (API 404). Enable it after merge with source main `/docs`.
- `store/DATA_SAFETY_AND_RATINGS.md`: Play Data safety, ads ID declaration, target audience, IARC answers, App Privacy label and Apple age rating. Each answer cites the code facts it rests on.
- `store/STORE_SUBMISSION_CHECKLIST.md`: every field of both consoles, which file answers it, and the [OWNER] steps (sign-in, agreements, payments/tax/bank, contact e-mail, DSA trader status, copyright name, closed-test testers, production release).
- `store/graphics/`: `google_play_icon_512.png`, `app_store_icon_1024.png` (opaque) and `google_play_feature_graphic_1024x500.png`. They are composed by `store/tools/make_graphics.py` from approved art only: the plaza background, `app_icon_ios_1024`, `logo_colorful` and `scrubby_master`. No AI generation.
- `store/screenshots/{google_play 1080x2160, app_store_6.9in 1290x2796, app_store_6.5in 1242x2688}/{en,tr}/`: 5 each, 30 in total (about 49 MB of PNG).
  - Screens: Home at L15, Collection album, Robots, L15 mid-level with bots in flight, and the end of the real win animation.
- `tests/tools/store_screens_capture.gd`: GPU capture of the real `main.tscn` with a throw-away save, which is deleted afterwards.
  - The full Level Intro video plays and the tool waits until the overlay frees itself.
  - The level is played with its verified real-play clicks under the human policy at 1/60.
  - It ends with WON and the shipping win video.
- `store/tools/check_listing.py`: checks the character limits, the keyword format, screenshot counts/sizes/RGB and graphic sizes.
- `store/.gdignore`: Godot never imports `store/`, so it can't reach any APK/AAB/IPA on either platform. That covers iOS without touching the inline preset in `ios-ipa.yml`.
- `.github/android/export_presets_family_first10.cfg`: `store/*` added to `exclude_filter` (one-token edit). I did not add `store` to `family_first10_export_exclusions.txt`: `check_release_versioning.py` would then require it in the iOS workflow preset too, and workflows are off-limits for this job.

## Acceptance criteria
1. [x] Texts TR + EN within limits. `python store/tools/check_listing.py`:
   - EN: name 29/30, short 78/80, subtitle 28/30, promo 162/170, keywords 94/100, full 1594/4000, what's new 140/500.
   - TR: 26, 73, 29, 154, 97, 1679, 137.
   - Only shipped features are claimed.
2. [x] Privacy policy TR + EN in `docs/privacy/index.html`, matching the code: `remote_content_runtime_v1.json` has an empty base URL, analytics is local and off by default, and job 170 brings AdMob/UMP/ATT/billing. Pages URL is above; the placeholder e-mail is listed as an owner item.
3. [x] Data safety, IARC, App Privacy label and age rating answers in `store/DATA_SAFETY_AND_RATINGS.md`, consistent with the policy. Card packs are earned only (no product sells them), so there are no loot boxes.
4. [x] Graphics:
   - Icon 512 RGB, feature graphic 1024x500 RGB, App Store icon 1024 RGB.
   - Screenshots: 5 per language per size, all RGB at the exact sizes (checker PASS).
   - Taken from the real game with the GPU tool, after the intro video finished: each run logged `intro video playing=true length=3.50 s`, `intro finished` and `terminal won=true`.
   - Play uses 1080x2160, not 2340, because Play rejects a long side more than twice the short side.
   - The optional caption banners were skipped.
5. [x] `store/STORE_SUBMISSION_CHECKLIST.md` lists every field for both consoles, where each answer or file is, and the owner steps.
- Must-nots: nothing was uploaded; no gameplay or economy code and no workflow was touched; TASKS.md was not edited.

## Validation
- `python store/tools/check_listing.py` -> `STORE LISTING CHECK: PASS` (LOCAL_PASS)
- `python tools/check_release_versioning.py` -> `RELEASE_VERSIONING_CHECK PASS (0 problems)` (export hygiene still holds after the preset edit)
- 6 GPU capture runs of `tests/tools/store_screens_capture.gd` (Godot 4.7.2, rendering driver, not headless), all exit 0 with every shot captured and `terminal won=true`. The first Play-EN run stalled after shot 2 under the 300 s timeout; a rerun completed all 5 shots.
- `git diff --cached --check` clean.
- Not run: Godot suites. No game script, scene or data changed; the only new GDScript is a dev capture tool under `tests/tools/`, and it ran cleanly 6 times.

## Notes for the caller
- Worktree not clean: the one-off `--import` left churn (project.godot reorder, about 540 `.import` files and about 700 `.uid`/`.translation` files). Restoring or deleting it was denied by the permission classifier. It is generated churn only, so delete it together with the worktree.
- Follow-ups (in the checklist):
  - The in-game `PRIVACY_ADS` / `PRIVACY_POLICY_LINK` texts still say "no ads" and "link will be added". Update them in job 170 or a follow-up before public release.
  - The iOS export should use an opaque 1024 icon: the repo's `app_icon_ios_1024.png` has alpha, and `store/graphics/app_store_icon_1024.png` is an opaque one.
  - Set the AdMob max ad content rating to G.

## Log
### Round 1
I wrote the listings, the policy, the questionnaires and the checklist, and composed the graphics. I built the capture tool:
- The first try at 1080x1920 showed a black band, and a greedy click policy lost L15. I switched to 1080x2160 and the level's verified real-play clicks.
- All 30 screenshots were captured and checked visually on a contact sheet.
- I shortened the TR short description and subtitle after the checker flagged them, and aligned the TR names with the game.
