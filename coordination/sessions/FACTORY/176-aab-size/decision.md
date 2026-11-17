# 176-aab-size decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Release AAB was ~396 MB (> Play 200 MB base limit).

- Commits 82ed3b2f, 890011f5, 42306ef8, 92f8248e: assets/ui/final PNGs >= 100 KiB import as lossy WebP q0.8 (boosters, gameplay effects, branding, small files, all level pixel art stay lossless; no source PNG changed; rule tool tools/sb_aab_size_lossy.py); keyed videos re-encoded from owner masters at Theora q5 (Home keyed videos untouched); UI-ADR-009.
- Measured: PCK 347.8 -> 122.7 MB (CI 44121919624), universal debug APK 513.6 -> 178.1 MB. AAB/IPA after are estimates (~173 / ~145 MB) until an aab_release / iOS release run.
- Visual: GPU before/after captures mean diff 0.55-2.18/255; keyed-video sheets clean.
- Suites: 97/98 CI locally (m43_c001a flake fixed by job 175); reviewer reran ui_vis_006, m42_opening, m22_029.
