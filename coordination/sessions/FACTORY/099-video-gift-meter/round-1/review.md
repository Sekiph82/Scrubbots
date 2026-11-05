# Review round 1 - 099-video-gift-meter (SB-VIDEO-006)

## Checks
- git diff --check origin/main...HEAD: clean.
- tests/sb_video_006_gift_meter_video.gd: PASS (6/6 cases, 0 fail). The 2 engine "Cannot open file missing.ogv" lines come from the injected broken stream.
- tests/m43_master_c005_meta_ceremonies.gd: PASS (32/32). The leak warnings at exit are the usual ones. project.godot restored (git checkout: 0 paths updated).

## Review
- Decoder lifetime: one VideoStreamPlayer, freed on `finished` (stop + queue_free). Closing mid-video frees it with the popup. The `finish` lambda captures only `box`, which lives as long as the popup, and its null/queued checks make a double call a no-op. A start failure frees the box immediately, so no decoder is left on that path. The tests assert the finish, close and failure paths directly.
- Economy: the diff changes presentation in `meta_ceremonies.gd` only. The `hero.set_meta("video")` tag is skipped under Reduced. Rewards, claim and routing are untouched.
- Hero resize happens only after `play()` has actually started. Reduced and failure keep the original size. The test asserts the original texture, alpha and size on both fallback paths.
- Shader: the key m = G - max(R,B) leaves yellow, white, cyan and pink alone. Despill and the soft alpha ramp are sane, and the UV edge fade hides crop cuts. The magenta shader is untouched (a new sibling file).
- Evidence stills (gift_10_video, gift_1000_held, viewed): no green fringe and no hard crop edges. The rays read yellow-white, the crate is clean and the layout fits.
- Tests are meaningful: they check the stream identity per milestone, the shader and mouse filter, the hero texture path, `is_instance_valid` after close, and the real broken-stream fallback.

## Must-fix
None.

## Notes (non-blocking)
- `gift_video` loads both streams at script load. This is harmless, since only the resource handle is loaded and decoding starts on play.
- The 6.9 MB of ogv assets is accepted per the spec.

VERDICT: PASS
