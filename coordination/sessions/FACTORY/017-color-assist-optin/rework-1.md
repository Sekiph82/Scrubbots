Owner rework (Şekip, chat 2026-10-22, after seeing the 720x1520 L7 captures, Turkish quoted):
"13'ten 8'e düşmüş ya, bence şu anki boyutun yarısı olsun ama aşağıya yuvarlanmış haliyle. mesela 13 için 6 olsun"

Meaning: glyph size = half of the ORIGINAL (pre-job, glyph_span 0.8) glyph size, rounded DOWN to whole screen pixels.
glyph_px = floor(ppc * 0.8 / 2) = floor(ppc * 0.4). Example L7 @720x1520: old 13.03 px -> 6 px. L7 @1080x2160: 19.55 -> 9.
Keep min_glyph_px 5 gate (owner did not change it), default OFF, migration, everything else as in round 1.
Update shader (span 0.4 + floor to whole pixels in screen space), tests bounds, regenerate the captures (overwrite the *_on files, keep *_before and *_off), and report the measured glyph px table again.
