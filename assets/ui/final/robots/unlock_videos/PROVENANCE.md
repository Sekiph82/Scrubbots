# Robot unlock signature videos: provenance (SB-VIDEO-010)

Owner Flow videos (Google Flow, Veo 3.1 Lite, Frames to Video from the
`flow_start_frame_robot_<id>_<key>_1080x1920.png` start frames, prompts in
`flow_videos/ROBOT_VIDEO_PROMPTS.md`): each roster robot powers on and does its signature move,
720x1280, 24 fps, 190 frames. Background per robot (ROBOT_KEY): magenta drifting from ~#F802FA
towards ~#DE2BCD (scrubby ends ~#C843B1), flat green ~#01FD04 (bubbles, polly), or blue drifting
from ~#0003F8 to ~#0F1FAB (clippy). The MP4 masters stay in the owner checkout (`flow_videos/`, not
committed) and are read-only.

Built by `python tools/build_result_scrubby_videos.py flow_videos robots` (ffmpeg libtheora, numpy,
Pillow). Crop = 5:6 box (the Robot Unlock hero aspect) around every pixel that is foreground in
>= 5 % of the frames (robot, tool swings, recurring bubbles / water / sparkles) + 16 px, clamped to
the frame (shifted to keep the robot body inside), then scaled to 480x576 (lanczos); short
full-frame bursts (sparkle rain, speed lines) the crop cuts fade out over 6 % of each side.
The .ogv keeps the background colour (keyed at runtime by
`scripts/ui/feel/chroma_key_{magenta,green,blue}.gdshader`, edge fade 0.06); the still is the
LAST frame used, keyed to transparent with the same key at build time (the hold pose).

## SCRUBBY

- key magenta
- master `robot_scrubby_master.mp4` sha256 `50f3ef70fc2735aae6a07e9ca79fcceb9b8923c328712c62fa3e6d5bb1bbb659` (190 frames)
- crop x=0 y=291 w=720 h=864
- `scrubby_unlock.ogv` sha256 `a719719ab2068d3553458375351b16518022f704dfc1f33fc7a0555eba34b990` (880097 bytes)
- `scrubby_unlock_still.png` sha256 `a57a777879fbe8d37f955a65e7055e040154fed88c6675bcf848fa1eec3c7a95` (234962 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_scrubby_master.mp4 -map 0:v:0 -an -vf crop=720:864:0:291,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 scrubby_unlock.ogv`

## MOPPY

- key magenta
- master `robot_moppy_master.mp4` sha256 `8039094a848d7ff3a1ef64fdbbdc02b56a190ee564518b36981328c0a7972512` (190 frames)
- crop x=0 y=342 w=720 h=864
- `moppy_unlock.ogv` sha256 `d051c2e618f1d7d7e7f3d1e611ee31f29d9f9de72f2a0a576c3ea2dc696bf448` (836502 bytes)
- `moppy_unlock_still.png` sha256 `a946c53be773faec4115db0713469805deb92024b752614a4fc3f5c07830654b` (219507 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_moppy_master.mp4 -map 0:v:0 -an -vf crop=720:864:0:342,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 moppy_unlock.ogv`

## BUBBLES

- key green
- master `robot_bubbles_master.mp4` sha256 `b96dc60527469da26eb2ec41bc21761dc262b2ba4c5c4e2ab5313f8bb490b1a2` (190 frames)
- crop x=0 y=228 w=720 h=864
- `bubbles_unlock.ogv` sha256 `e367d39bb82b1ecd14f0ad502f1b100ccb06a1a6d4ea3084a73b243e155c1f07` (1025310 bytes)
- `bubbles_unlock_still.png` sha256 `0bc0327f9ba321624c13a902867f72895a1ddbdad3d6374493fb1385bb7c31d5` (235392 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_bubbles_master.mp4 -map 0:v:0 -an -vf crop=720:864:0:228,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 bubbles_unlock.ogv`

## SPARK

- key magenta
- master `robot_spark_master.mp4` sha256 `c3c058a678ef668bff2535ff1f3a3768219f7c89c480fe3d77bc3de0961e2777` (185 frames used)
- crop x=0 y=208 w=720 h=864
- `spark_unlock.ogv` sha256 `092f590e05d84bb30e8e8b43e200d3c36fafb6a66884bfdd3c599929c49ae467` (1000912 bytes)
- `spark_unlock_still.png` sha256 `964438c2dcb425c23f8291f9cbb07ef6e95f4635adaa1a46aebaa250ab7e5385` (261272 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_spark_master.mp4 -map 0:v:0 -an -frames:v 185 -vf crop=720:864:0:208,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 spark_unlock.ogv`

## SQUEEGEE

- key magenta
- master `robot_squeegee_master.mp4` sha256 `a2f5cc83969c2dff33d9e289666b0ccf39f1bc8814ed2a27fcf9caa9cc100335` (190 frames)
- crop x=14 y=236 w=680 h=816
- `squeegee_unlock.ogv` sha256 `a4dbfcdc5cce0a9308d806e30f50c1475a7367c672946326085f5fc5dad624ff` (723389 bytes)
- `squeegee_unlock_still.png` sha256 `8b09d15fbb79e6f32a7fe253b54b71e1a0b336367c9abd8e2ec76021e3d484eb` (190615 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_squeegee_master.mp4 -map 0:v:0 -an -vf crop=680:816:14:236,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 squeegee_unlock.ogv`

## DUSTY

- key magenta
- master `robot_dusty_master.mp4` sha256 `d6e6fef5fe548383abc8abcbe0a423fb57c4bca4cac36ee1f07b450dc0c1c9a8` (190 frames)
- crop x=40 y=275 w=680 h=816
- `dusty_unlock.ogv` sha256 `9c481d13c4805d3633d569d1b36c2210b8dae7521b7c1672f8534f3d247344de` (791113 bytes)
- `dusty_unlock_still.png` sha256 `7f4d6f06dc6398ca1dff6538d29734d5a46a4b63fce0ab3fb32d551c925418ef` (250875 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_dusty_master.mp4 -map 0:v:0 -an -vf crop=680:816:40:275,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 dusty_unlock.ogv`

## RINSE

- key magenta
- master `robot_rinse_master.mp4` sha256 `30e454b78a8f40451a860ed6d0565866733518a5084b14d8e09bee80921b2864` (190 frames)
- crop x=80 y=382 w=640 h=768
- `rinse_unlock.ogv` sha256 `bf7a618c867a7973f9a12adb37e557a9e4b96007e0f0347fc36b209b396a7c1f` (844508 bytes)
- `rinse_unlock_still.png` sha256 `c1cea65d5bb7997b0d79239bf10ad9faf76ba87f454cd99c08d8f1a229f16f22` (194204 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_rinse_master.mp4 -map 0:v:0 -an -vf crop=640:768:80:382,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 rinse_unlock.ogv`

## POLLY

- key green
- master `robot_polly_master.mp4` sha256 `178389b60090fdc0d002b1f6566ef60b81aeab5351546545fb176f75fa346286` (180 frames used)
- crop x=45 y=260 w=660 h=792
- `polly_unlock.ogv` sha256 `6584174797977c77c31b486d98760438668e99eb6bc58202c16c4ebd1fc43c35` (785935 bytes)
- `polly_unlock_still.png` sha256 `bdbbd85b7a9f2cf8e66878f71895ac9fb6887b065c6c217ed9d9723a6c1e95a5` (273521 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_polly_master.mp4 -map 0:v:0 -an -frames:v 180 -vf crop=660:792:45:260,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 polly_unlock.ogv`

## CLIPPY

- key blue
- master `robot_clippy_master.mp4` sha256 `1c4a43e93729115af4534c41fa17f44cc89c8a2cb68a6b4e78e16f037a8a9b2d` (190 frames)
- crop x=15 y=253 w=700 h=840
- `clippy_unlock.ogv` sha256 `5b0cf166ed072afaf331dd055daf35bd17da0742919d69ad7cf7a946065eac6b` (873760 bytes)
- `clippy_unlock_still.png` sha256 `12793517c73bfdb54afebe291586502c36ea53f2e4cffa6c93f779d47d9efd81` (219832 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_clippy_master.mp4 -map 0:v:0 -an -vf crop=700:840:15:253,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 clippy_unlock.ogv`

## ATLAS

- key magenta
- master `robot_atlas_master.mp4` sha256 `f4ec633bd0ddc8a562f7c17f83c256dcad3dac6ca04ba18f9fb33456a376f4e4` (190 frames)
- crop x=0 y=304 w=720 h=864
- `atlas_unlock.ogv` sha256 `cb09b6b9224ed73f508ea2669074cfaa4a36473c8eebc07cfb780dbeb7661c4f` (1442291 bytes)
- `atlas_unlock_still.png` sha256 `9d3a7bf32e61c293e7e660a543ee3600b2187fef6061dcc3da6b690a59a3f467` (282284 bytes)
- encode: `ffmpeg -hide_banner -loglevel error -y -i robot_atlas_master.mp4 -map 0:v:0 -an -vf crop=720:864:0:304,scale=480:576:flags=lanczos -c:v libtheora -q:v 5 -pix_fmt yuv420p -map_metadata -1 atlas_unlock.ogv`
