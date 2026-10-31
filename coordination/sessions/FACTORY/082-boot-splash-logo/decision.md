APPROVE

## Why
All three round-1 reviews are PASS with no real problems. The diff is small and matches the spec's intent. `git merge-tree` reports no conflicts. CI apk_only run 41219945108 succeeded, and the APK contains the splash image and project settings.

## Acceptance criteria
1. Boot splash keys in project.godot: met. The `fullsize` key does not exist in Godot 4.7.2, so `stretch_mode=1` replaces it. Code review confirmed this.
2. Headless settings check and frame-0 colour: met. The ac2 script output is in build.md. Frame 0 of the video is near-black, so bg_color is black, which equals OpeningScreen.BACKGROUND.
3. Desktop capture shows the SCRUBBOTS logo: met. Two screenshots are recorded in build.md. I did not open them myself.
4. APK check: met. Run 41219945108 succeeded. The APK holds the splash PNG and its .ctex, and project.binary references boot_splash_image. The Android 12 splash icon is the app icon. iOS was code-reviewed only, which build.md says honestly.
5. `git diff --check` and suites: met. m42_opening passed 9/9, including the new boot_splash_logo case. m44_ftue passed 23/23. The tests reviewer re-ran m42_opening and it passed.
6. Changed-file set: met. It is project.godot, one new derivative PNG with manifest and index provenance, one doc line, one test case and TASKS.md. splash_logo.png and opening_screen.gd are untouched. The derivative PNG deviates from the raw-logo plan, but it was the orchestrator's decision. It is a resize/pad of the approved art only.
