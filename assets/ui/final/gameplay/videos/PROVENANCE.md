# Level Intro Scrubby video: provenance (SB-VIDEO-005)

Owner Flow video (Google Flow, Veo 3.1 Lite), Scrubby's "ready / let's go" move on a
flat magenta (~#F00DE9) chroma background. Trimmed by the owner before import (short
master, frames 0-83): 720x1280, 24 fps, 84 frames (~3.5 s), first frame ~ last frame.
The MP4 master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos level_start` (ffmpeg libtheora,
numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.
The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is frame 0 keyed to
transparent with the same key at build time.

## LEVEL_START

- master `level_start_scrubby_short_master.mp4` sha256 `f6a45f1b1f7da0fc60dfc1ba3f45c56f022f892498889c7a82e3752becc13773` (84 frames)
- crop x=13 y=317 w=624 h=640
- `level_start_scrubby.ogv` sha256 `b578880709281048a66ef69f5d54535fded47a72336dbad2eeb5d5c5ed3f04f5` (1344936 bytes)
- `level_start_scrubby_still.png` sha256 `c7c3c09eddf474e2f543ec39c48a67d89fa4777f5c8f119427fcc88f127964ba` (281141 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i level_start_scrubby_short_master.mp4 -map 0:v:0 -an -vf crop=624:640:13:317 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 level_start_scrubby.ogv`
