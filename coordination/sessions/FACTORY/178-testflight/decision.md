# 178-testflight decision

APPROVE (2026-11-18). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner: "sen gerisini hallet" (iOS TestFlight + IAPs).

- Commits a6e508f8 (ios-ipa.yml opt-in testflight_upload, release-only, altool upload with the ASC API key secrets, key file transient/never echoed; ITSAppUsesNonExemptEncryption=false; versioning check allows exactly this guarded upload, selftest negatives), 1a8b7c83 (privacy inventory entry).
- CI 44195307315 success: UPLOAD SUCCEEDED; build 0.1.0 (24) VALID, IN_BETA_TESTING in internal group "ScrubBots internal" (account holder invited).
- 6 iOS IAPs: real Shop review screenshot uploaded via the API -> READY_TO_SUBMIT. Nothing submitted for App Review; no public release.
