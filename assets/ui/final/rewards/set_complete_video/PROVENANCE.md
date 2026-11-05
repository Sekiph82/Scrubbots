# Collection set complete badge video: provenance (SB-VIDEO-007)

Owner Flow video (Google Flow, Veo 3.1 Lite): the gold crowned set-complete badge pops,
flaps its wings, a light sweep crosses it, a star burst rains and it ends glowing, on a
magenta chroma background that drifts from ~#F802FA to ~#E136C8 (min(R,B)-G >= 140).
720x1280, 24 fps, 190 frames; frames 0-181 are used (the last 8 frames dissolve the wings and turn
the gold copper, so the hold pose is frame 181). The MP4 master stays in the owner checkout (`flow_videos/`,
not committed) and is read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos set_complete` (ffmpeg
libtheora, numpy, Pillow). Crop = fixed square around the badge + the star burst (stars fill
the whole frame, so a bbox would be the full frame); anything the crop cuts fades out over
6 % of each side. The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader` with edge_fade 0.06); the still is the LAST
frame keyed to transparent with the same key at build time (the hold pose after playback).

## SET_COMPLETE

- master `set_complete_master.mp4` sha256 `bc0ccc2025ebdfc17232913ef62a00587d424f1613374ff1944ea06e78bda7d9` (182 frames used)
- crop x=48 y=402 w=624 h=624
- `set_complete_badge.ogv` sha256 `23c1f5247268eed122e74bb6287aa3606dc678f8c07e5b2f3a2ba73f92996ebb` (3565048 bytes)
- `set_complete_badge_still.png` sha256 `6807a3c705f8bfe26720f02471b15d44e93a82fb9e54503be97700f453251023` (385029 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i set_complete_master.mp4 -map 0:v:0 -an -frames:v 182 -vf crop=624:624:48:402 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 set_complete_badge.ogv`
