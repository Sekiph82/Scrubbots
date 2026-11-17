# 168-release-signing (SB-RELEASE-SIGNING-2026-11-17)
Owner 2026-11-17: prepare store packages; "bunlari sen ayarla, bana sadece senin yapamayacagin seyleri haber ver". Everything free.
Today only debug signing exists (secrets ANDROID_DEBUG_KEYSTORE_*), APK via android-family-first10.yml, IPA via ios-ipa.yml (inspect how it is signed today).
## Android
- Generate a release UPLOAD keystore locally (keytool from the installed JDK/Android SDK), strong random passwords. Store as GitHub repo secrets (gh secret set) ANDROID_RELEASE_KEYSTORE_BASE64 / _PASSWORD / _ALIAS / _KEY_PASSWORD. Never commit it. Put an owner backup copy (keystore + a short README with alias/passwords) in C:/Users/sekip/Documents/ScrubBots-signing/ (outside any repo) and say so in build.md (owner must back it up; Play App Signing will hold the app key, this is the upload key).
- Workflow: add a mode (e.g. aab_release) that exports a signed release .aab (Gradle build, target/compile SDK meeting current Play requirements, versionCode/versionName from the repo's release versioning) as an artifact; keep apk_only/validation_only unchanged. Release build must not include debug-only seams/menus; check the existing release-hygiene suites.
- Verify by actually running the workflow on the branch (dispatch on factory branch is fine) and checking the AAB is produced and signed with the upload key (jarsigner -verify / apksigner of a bundletool-built apk).
## iOS
- Inspect ios-ipa.yml signing. Determine exactly what an App Store / TestFlight upload needs (Apple Distribution certificate, App Store provisioning profile, App Store Connect API key) and which of these already exist as secrets. Prepare the workflow mode (e.g. appstore) gated on those secrets so it fails clearly when missing. List precisely, step by step, what the owner must do in Apple Developer / App Store Connect (free: they already paid) that Claude cannot do without the owner's login, in build.md.
## Must not
No upload to any store, no production release, no spending. No secrets in the repo or logs.
