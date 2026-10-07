# CP07/M18 — SCRUBBOTS R2 LIVE READ-ENDPOINT BINDING — AUDIT CRITERIA V01

- [ ] Canonical provider is Cloudflare R2 bucket `scrubbots-content-prod`.
- [ ] Family Test read root is `https://pub-dd36dd94999d4beaad95d6409ad0167e.r2.dev`.
- [ ] Exact manifest/pack keys came from the canonical Factory publisher, not a game-side invented prefix.
- [ ] No R2/API/S3 write credential appears in Git, config, log, APK path or test fixture.
- [ ] manifest_url is exact HTTPS public manifest URL.
- [ ] object_base_url + manifest object_key resolves exact pack URLs.
- [ ] Existing HTTPS-only/no-redirect/no-credential URL gate retained.
- [ ] Manifest strict parser PASS.
- [ ] Every referenced pack byte length + SHA PASS.
- [ ] Safe ZIP/scrubpack/LevelData/supply/metadata validation PASS.
- [ ] First refresh downloads only missing packs.
- [ ] Second refresh is idempotent / no redundant download.
- [ ] Offline relaunch exposes LKG.
- [ ] Broken successor retains LKG.
- [ ] Builtin Levels 1–10 unchanged.
- [ ] No executable remote payload path.
- [ ] enabled=true only when valid game version + live publication contract exist; otherwise final enablement truthfully deferred to Family APK.
- [ ] CP04/CP05/CP05-R01/family fixture/M53/root regressions PASS.
- [ ] diff --check clean.
- [ ] Builder log exists and ends AWAITING_GPT_CP07_R2_LIVE_BINDING_AUDIT.

PASS closes the ScrubBots-side R2 read binding and opens the Android Family APK gate.
