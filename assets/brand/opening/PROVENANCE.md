# Opening cinematic — provenance

## Owner source (SB-M42-026)

| Field | Value |
|---|---|
| Canonical path | `assets/brand/opening/final_15_seconds_opening_video.mp4` |
| Local owner source | `assets/brand/opening/final 15 seconds opening video.mp4` (untracked owner file, left untouched) |
| Preservation | byte copy (`cp -p`), `cmp` identical; source never modified |
| SHA-256 | `c044841d4aad1bc97c3d2bd144468c44f514bc2e288a970ae0a6aa14191f4388` |
| Size | 25,234,301 bytes |
| Container | MP4 (mov,mp4,m4a,3gp,3g2,mj2), duration 15.022993 s |
| Video | H.264 High, 1280x720 (landscape 16:9), yuv420p, 30/1 fps, 15.000000 s, ~13.3 Mb/s |
| Audio | AAC LC, 44,100 Hz, stereo, 15.022993 s, ~128 kb/s |

Metadata recorded with `ffprobe` (ffmpeg 9.0.1-full_build-www.gyan.dev).

The MP4 is the preserved master only. Godot runtime playback uses the Ogg Theora/Vorbis
derivative (SB-M42-027), never H.264/MP4.

## Runtime derivative (SB-M42-027)

| Field | Value |
|---|---|
| Path | `assets/brand/opening/scrubbots_opening_720p30.ogv` |
| SHA-256 | `3ec6e1347bbb1d8ced2709f3383b06ae6dbfba017e0a6d23a0fb991ec78ee89a` |
| Size | 16,038,188 bytes |
| Container | Ogg, duration 15.022993 s |
| Video | Theora, 1280x720, yuv420p, 30/1 fps, 15.000000 s; 450 packets = 441 coded frames + 9 zero-length duplicate-frame packets (static frames), last pts 14.966667 s |
| Audio | Vorbis, 44,100 Hz, stereo, 15.022993 s |
| Tool | ffmpeg 9.0.1-full_build-www.gyan.dev (libtheora, libvorbis) |

Exact command (run in `assets/brand/opening/`):

```bash
ffmpeg -hide_banner -loglevel error -y -i final_15_seconds_opening_video.mp4 -map 0:v:0 -map 0:a:0 -vf "scale=1280:720:flags=lanczos,fps=30" -c:v libtheora -q:v 8 -pix_fmt yuv420p -c:a libvorbis -q:a 5 -ar 44100 -ac 2 -map_metadata -1 scrubbots_opening_720p30.ogv
```

The MP4 master is read-only input (SHA-256 unchanged after conversion).

A pre-existing untracked `scrubbots_opening_720p30.ogv` (SHA-256
`78d76cf9c39f50f0f11ace7b765a651a8eb25071bb1f3f44b25d1b24705aecf6`, 9,366,635 bytes,
Theora/Vorbis 1280x720 30 fps, unknown command) was not deleted: it was moved unchanged to
the local untracked folder `assets/brand/opening/_preexisting_untracked/` so this
reproducible encode could take the canonical path.
