# New region unlock Scrubby video: provenance (SB-VIDEO-009)

Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby looks into the distance, points, jumps,
does a fast full spin (the sprout is lost to motion blur for a few frames around 116-136) and
lands in a ready pose with golden sparkles, on a magenta chroma background that drifts from
~#FA05FA to ~#E126D7 (min(R,B)-G >= 170). Generic (not world-specific). 720x1280, 24 fps, 190 frames. The MP4
master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos new_region` (ffmpeg libtheora,
numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.
The .ogv keeps the magenta (keyed at runtime by
`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is the LAST frame keyed to
transparent with the same key at build time.

## NEW_REGION

- master `new_region_master.mp4` sha256 `e236a0639c82e106816b0eac32983d99dc2b5854a818dcd913a9e84f6a0b0590` (190 frames)
- crop x=0 y=295 w=720 h=848
- `new_region_scrubby.ogv` sha256 `7c5e1cfb04471cca261230bfe68db5fbf653049b1c39e80742b0b486ff303a1f` (2493437 bytes)
- `new_region_scrubby_still.png` sha256 `d8d28e9dfa968423511d016cc4db7b983f8c8a683bda333836360ca287570e75` (292322 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i new_region_master.mp4 -map 0:v:0 -an -vf crop=720:848:0:295 -c:v libtheora -q:v 8 -pix_fmt yuv420p -map_metadata -1 new_region_scrubby.ogv`
