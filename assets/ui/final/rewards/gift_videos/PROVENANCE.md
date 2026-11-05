# Gift Meter box videos: provenance (SB-VIDEO-006)

Owner Flow videos (Google Flow, Veo 3.1 Lite) on a flat green (#00FF00) chroma background:
the small gift box (normal milestones, 161 frames, trimmed by the owner before the lid fades)
and the big robotic crate (cycle-max milestone, 190 frames), both 720x1280, 24 fps.
The MP4 masters stay in the owner checkout (`flow_videos/`, not committed) and are read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos gift` (ffmpeg libtheora,
numpy, Pillow). Crop = fixed box + sparkle burst above it (the crate crop ends where the lid
debris lands on the right); anything the crop cuts fades out over 6 % of each side. The .ogv
keeps the green (keyed at runtime by
`scripts/ui/feel/chroma_key_green.gdshader`, same edge fade); the still is the LAST frame
keyed to transparent with the same key at build time (the hold pose after playback).

## GIFT_SMALL

- master `gift_box_opening_master.mp4` sha256 `b6d5865144aea00e189cf8aee9e9d8f7ba37ad823d0f2cbddb26beec97a83eef` (161 frames)
- crop x=76 y=112 w=624 h=928
- `gift_small_opening.ogv` sha256 `0f4842e3db53bf50d2fb6a2f29e8b5fb33dcd63eed407691f153849f2078f448` (3172249 bytes)
- `gift_small_opening_still.png` sha256 `53cb0a460b179a148548a0b3c43410db2b808e9f6012e4063c967c548af71c50` (417314 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i gift_box_opening_master.mp4 -map 0:v:0 -an -vf crop=624:928:76:112 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 gift_small_opening.ogv`

## GIFT_BIG

- master `gift_crate_opening_master.mp4` sha256 `9f8aecd18fe82d1f80077b02facacc1b35cf5bd7c50f0bde33778c9e88baac65` (190 frames)
- crop x=106 y=288 w=528 h=800
- `gift_big_opening.ogv` sha256 `7d9a274a246714d5fa2cf6c7e722f719881ae542199e39e4b7d8c8855a0ee965` (3941529 bytes)
- `gift_big_opening_still.png` sha256 `e55ea478855c342f3236752b8eace8f667fa05c84777aba0bbe0e3ebcaa7a34a` (440577 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i gift_crate_opening_master.mp4 -map 0:v:0 -an -vf crop=528:800:106:288 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 gift_big_opening.ogv`
