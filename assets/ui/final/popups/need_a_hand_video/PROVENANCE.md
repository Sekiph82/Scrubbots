# Need a Hand Scrubby video: provenance (SB-POLISH-011B)

Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby with a cyan "?" thinks, gets an idea,
gives a thumbs-up, waves to help and returns to the start pose with the "?", on a magenta
chroma background that drifts from ~#FA02FA to ~#E637CB (min(R,B)-G >= 140). 720x1280, 24 fps, 190 frames; frames
0-181 are used (the last 8 frames dim the eyes and fade the "?" out, so the hold pose is frame
181). The MP4 master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos need_a_hand` (ffmpeg libtheora,
numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.
The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is the LAST frame keyed to
transparent with the same key at build time.

## NEED_A_HAND

- master `need_a_hand_master.mp4` sha256 `dc3f1c1fc135f7ee110ea55a4d37a9bc6a52e02be8ede7b7a5f9e6f892c409ba` (182 frames used)
- crop x=78 y=487 w=576 h=512
- `need_a_hand_scrubby.ogv` sha256 `e65e5f110ed5358ba8e536df7dffea37c5894007b435220feb789bcff9c6f616` (1553099 bytes)
- `need_a_hand_scrubby_still.png` sha256 `ae1ade689b144ad67ac8f0157d18b27ea67ebd8d1f13dac19acbab4029a993af` (218439 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i need_a_hand_master.mp4 -map 0:v:0 -an -frames:v 182 -vf crop=576:512:78:487 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 need_a_hand_scrubby.ogv`
