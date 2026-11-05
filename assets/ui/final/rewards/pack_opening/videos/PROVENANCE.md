# Pack opening videos: provenance (SB-VIDEO-003 / SB-VIDEO-004)

Owner Flow videos (Google Flow, Veo 3.1 Lite), full-screen 9:16 over the blurred, darkened Home
park (the factory-090 ceremony background). Trimmed before import at the brightest frame: the
last frame is the peak flash. 720x1280, 24 fps. The trimmed MP4 masters stay in the owner
checkout (`flow_videos/`, not committed) and are read-only.

Per pack: the Theora .ogv, `_first.png` = frame 0 (the IDLE poster under "Tap to open") and
`_flash.png` = the last frame (held after the video, then crossfaded into the native card reveal).
Played by `scripts/ui/ceremony/standard_pack_ceremony.gd` (Premium inherits it).

## Standard

- master `pack_open_standard_master.mp4` sha256 `41a6c5f51217bbfe0a7462aef4d8f5c5a615c2999d0b7de7139a31f693bb8664` (169 frames)
- `pack_open_standard.ogv` sha256 `a8dc3abe6cc5cc68755247d49691a622b4bbcf7495406b964ce57a040e00f632` (3586413 bytes)
- `pack_open_standard_first.png` sha256 `fa3613f9cbc21b5adfa09e918b3a683325e41a9cbbddb0d662fc949258d764fd`
- `pack_open_standard_flash.png` sha256 `a44cc6cf2e368c2868b3a4ad4b45815112a1073ac58e1b8e172110f3008f70b2`

## Premium

- master `pack_open_premium_master.mp4` sha256 `f2d755371c4d3999a317081dac03f2ac972edae6bac70ab50ad282044a5e3e01` (162 frames)
- `pack_open_premium.ogv` sha256 `02a607de3f4975bf44f9083c79a1c74162d4fad87fd7f69bc356c42f3d6b21e5` (5525594 bytes)
- `pack_open_premium_first.png` sha256 `69b2ba19d83e9e2faf018627b05966540350ab05abbf1d5ca0c68de61174e299`
- `pack_open_premium_flash.png` sha256 `0f75a50695a7e2a84dcd4ed60accba89c50639d034e164322b58f485073885b9`

## Commands (`<p>` = standard / premium)

```
ffmpeg -hide_banner -loglevel error -y -i pack_open_<p>_master.mp4 -map 0:v:0 -an -c:v libtheora -q:v 6 -pix_fmt yuv420p -map_metadata -1 pack_open_<p>.ogv
ffmpeg -hide_banner -loglevel error -y -i pack_open_<p>_master.mp4 -vf "select=eq(n\,0)" -frames:v 1 pack_open_<p>_first.png
ffmpeg -hide_banner -loglevel error -y -sseof -0.1 -i pack_open_<p>_master.mp4 -update 1 pack_open_<p>_flash.png
```
