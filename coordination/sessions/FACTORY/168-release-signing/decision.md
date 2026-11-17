# 168-release-signing decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner: set up store packages, report only owner-only steps.

- Commits 45985582 (aab_release mode, release-only guard, docs), be9f9e07 (Android build template installed by unzip; the editor flag hung headless), 4abb5b20 (per-ref concurrency group, cancel-in-progress false).
- Upload keystore (PKCS12 RSA 4096, alias scrubbots-upload) in GitHub Secrets ANDROID_RELEASE_KEYSTORE_*; owner backup at C:/Users/sekip/Documents/ScrubBots-signing/ (outside the repo). No secret in repo or CI log (reviewer checked run 44105591683).
- Proof: CI run 44105591683 built a signed AAB b98 (targetSdk 36, not debuggable, cert SHA-256 matches the keystore).
- Blocker for upload: AAB ~396 MB > Play 200 MB base module -> job 176 (size).
- iOS: existing release mode does App Store export; needs owner Apple Distribution cert, App ID, profile, Team ID (owner steps in build.md).
