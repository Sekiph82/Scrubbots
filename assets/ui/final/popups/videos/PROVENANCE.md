# Results Scrubby videos: provenance (SB-VIDEO-001 / SB-VIDEO-002)

Owner Flow videos (Google Flow, Veo 3.1 Lite), Scrubby on a flat magenta (~#F00DE9)
chroma background (green is ruled out by the green sprout). Trimmed before import at
frame 184: 720x1280, 24 fps, 185 frames, first frame = last frame. The trimmed MP4
masters stay in the owner checkout (`flow_videos/`, not committed) and are read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos` (ffmpeg libtheora,
numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.
The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is frame 0 keyed to
transparent with the same key at build time.

## WIN

- master `result_scrubby_win_master.mp4` sha256 `a3f80015edeb8da3c79545a202eb407782941d8c227be305dcf415fcb5b7e996` (185 frames)
- crop x=87 y=278 w=560 h=864
- `result_scrubby_win.ogv` sha256 `eeacf4ee41f5933ac91cf36e936449fcd06f7c08d4fffd20669af697cb9f8d46` (3363281 bytes)
- `result_scrubby_win_still.png` sha256 `3a849f03c1dd5ff26f3675426801429d59d93b87f3c2094b8f9266b27a4ff097` (224420 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i result_scrubby_win_master.mp4 -map 0:v:0 -an -vf crop=560:864:87:278 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 result_scrubby_win.ogv`

## LOSE

- master `result_scrubby_lose_master.mp4` sha256 `936c8e3f08cc44c9cc1de45b14b91c944f17c521298e6e6cb58e72077397780a` (185 frames)
- crop x=126 y=304 w=512 h=624
- `result_scrubby_lose.ogv` sha256 `695181897c64cba1b2fd37a87c3b5fa747a5bcb327624de977de4a6b8778fe72` (2060313 bytes)
- `result_scrubby_lose_still.png` sha256 `5ec8e2cd5b383c66bea48ffad0a3c4de8b319fdb5fb060598fa6cf28a7648610` (224011 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i result_scrubby_lose_master.mp4 -map 0:v:0 -an -vf crop=512:624:126:304 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 result_scrubby_lose.ogv`
