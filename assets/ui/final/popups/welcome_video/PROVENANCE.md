# Welcome back Scrubby video: provenance (SB-VIDEO-008)

Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby jumps, waves both hands, hugs himself,
waves and ends near the start pose, on a magenta chroma background that drifts from ~#FA05F8
to ~#E337CA (min(R,B)-G >= 140). 720x1280, 24 fps, 190 frames. The MP4 master stays in the
owner checkout (`flow_videos/`, not committed) and is read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos welcome_back` (ffmpeg libtheora,
numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.
The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is the LAST frame keyed to
transparent with the same key at build time.

## WELCOME_BACK

- master `welcome_back_master.mp4` sha256 `f93b53f020f87c6af596e01cb98467b1c7ff5e32a955901fe9bcd3c4f376057c` (190 frames)
- crop x=95 y=359 w=576 h=672
- `welcome_back_scrubby.ogv` sha256 `a06897d8e59e58403ed15d95ab56c982408b0fc2d8b360453c5bfa32cb311634` (2641207 bytes)
- `welcome_back_scrubby_still.png` sha256 `25517312cc971cdcae3b3df571d89068c4dd234ee286abe94c0efbe39eb135c6` (241861 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i welcome_back_master.mp4 -map 0:v:0 -an -vf crop=576:672:95:359 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 welcome_back_scrubby.ogv`
