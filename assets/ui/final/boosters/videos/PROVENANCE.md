# Tornado booster video: provenance (SB-TF-06)

Owner Flow video (Google Flow) chosen by the owner for the Tornado booster: a blue tornado on a
black background, born small at the bottom right (the Tornado button), growing and travelling up
to the board centre, then spinning in place. 720x1280, 24 fps, 190 frames, with an AAC track
(dropped). The master stays in the owner's Downloads / the factory job folder (not committed).

Built by `python tools/build_tornado_booster_video.py <master.mp4>` (ffmpeg libtheora, numpy).
Trim: start = first frame whose changed-pixel count exceeds 3x the idle level of frames 1-6
(the tornado starts to grow); end = first frame whose bbox centre and width are within 3 px of
the steady spin (median of the last 100 frames): end of travel, the spinning tail is dropped.
Crop = bounding box of every pixel > 12/255 (above the master's H.264 edge specks) over the kept frames + 16 px, sides rounded up to 16.
Played with additive blending (CanvasItemMaterial BLEND_MODE_ADD), so black adds nothing.

## TORNADO

- master `Blue_tornado_spinning_and_growing_6bafdac1.mp4` sha256 `8819802409023aff02c9a794e4f52ce9a6052a0c1ef28d4d6970aae72a2c6a59`
- trim: source frames 7-38 (32 frames, 1.333 s)
- crop x=91 y=215 w=544 h=1008
- black level: decoded corner pixels max 0/255 over every frame (no crush needed)
- `tornado_additive.ogv` sha256 `2a4630c764db90ca27209ab539d25b06f3a437ce73a6d0c03f9eeea53fec8edd` (149835 bytes), Theora -q:v 5, 24 fps, yuv420p, no audio
- encode (in the master's folder): `ffmpeg -hide_banner -loglevel error -y -i Blue_tornado_spinning_and_growing_6bafdac1.mp4 -map 0:v:0 -an -vf trim=start_frame=7:end_frame=39,setpts=PTS-STARTPTS,crop=544:1008:91:215 -r 24 -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 tornado_additive.ogv`

## Track (cropped-video px: [clip frame, centre x, centre y, diameter])

Per kept frame: bbox of pixels with any channel > 40; centre = bbox centre, diameter = bbox width.
14 evenly spaced keys incl. first (at the button) and last (end of travel); baked into
`scripts/ui/feel/booster_vfx.gd` TORNADO_TRACK.

```
const TORNADO_TRACK := [
	[0, 397.5, 957.0, 83.0],
	[2, 397.5, 956.0, 81.0],
	[5, 399.5, 954.5, 87.0],
	[7, 400.0, 942.0, 104.0],
	[10, 387.5, 896.5, 153.0],
	[12, 375.5, 845.5, 195.0],
	[14, 361.0, 784.5, 236.0],
	[17, 339.0, 677.5, 296.0],
	[19, 324.5, 597.5, 339.0],
	[21, 312.5, 520.0, 381.0],
	[24, 293.5, 400.5, 431.0],
	[26, 287.0, 331.5, 456.0],
	[29, 277.0, 249.0, 484.0],
	[31, 272.5, 217.0, 493.0],
]
```
