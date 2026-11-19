#!/usr/bin/env python3
"""SB-TF-06: Tornado booster video from the owner's black-background Flow master.

Trims the idle start (first frame whose changed-pixel count vs the previous frame exceeds 3x
the idle level of frames 1-6: the tornado starts to grow) and ends at end-of-travel (first
frame whose bounding-box centre and width are within 3 px of the steady spin, median of the
last 100 frames). Crop = bounding box of all non-black pixels over the kept frames + 16 px,
sides rounded up to 16 (as tools/build_result_scrubby_videos.py). Encodes Theora, no audio,
then decodes the result and checks the black level (four corners of every frame <= 4/255);
near-black is crushed with lutrgb only when that check fails. Measures the tornado track
(bbox centre + width of pixels brighter than 40 per kept frame, cropped-video px) and writes
PROVENANCE.md plus the TORNADO_TRACK keys for scripts/ui/feel/booster_vfx.gd.

Usage: python tools/build_tornado_booster_video.py <master.mp4>
"""
import hashlib
import subprocess
import sys
from pathlib import Path

import numpy as np

W, H, FPS = 720, 1280, 24
MARGIN = 16
BRIGHT = 40        # tornado pixels (track)
NONBLACK = 12      # crop: any pixel above this in any kept frame (H.264 specks of 9-12 sit at the frame edges)
THEORA_Q = "5"
KEYS = 12          # evenly spaced track keys between first and last
OUT_DIR = Path("assets/ui/final/boosters/videos")
OUT = OUT_DIR / "tornado_additive.ogv"


def frames(path: Path, w: int = W, h: int = H) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, h, w, 3)


def bbox(m: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.nonzero(m)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def measure(f: np.ndarray) -> tuple[float, float, float]:
    """Tornado centre (bbox centre) and diameter (bbox width) of one frame."""
    x0, y0, x1, y1 = bbox(f.max(axis=2) > BRIGHT)
    return (x0 + x1 + 1) / 2.0, (y0 + y1 + 1) / 2.0, float(x1 - x0 + 1)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main(src: Path) -> None:
    f = frames(src)
    moved = [int((np.abs(f[i].astype(np.int16) - f[i - 1]).max(axis=2) > 30).sum()) for i in range(1, len(f))]
    idle = float(np.median(moved[:6]))
    start = next(i + 1 for i, n in enumerate(moved) if i >= 6 and n > 3 * idle)
    steady = np.median([measure(f[i]) for i in range(len(f) - 100, len(f))], axis=0)
    end = next(i for i in range(start, len(f)) if np.abs(np.array(measure(f[i])) - steady).max() <= 3.0)
    kept = f[start:end + 1]
    x0, y0, x1, y1 = bbox((kept.max(axis=3) > NONBLACK).any(axis=0))
    box = []
    for lo, hi, size in ((x0, x1, W), (y0, y1, H)):
        n = min(size, -(-(hi - lo + 1 + 2 * MARGIN) // 16) * 16)
        s = min(max(0, (lo + hi + 1 - n) // 2), size - n)
        box += [int(s), int(n)]
    x, w, y, h = box
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    vf = f"trim=start_frame={start}:end_frame={end + 1},setpts=PTS-STARTPTS,crop={w}:{h}:{x}:{y}"
    for crush in ("", ",lutrgb=r='if(lt(val,12),0,val)':g='if(lt(val,12),0,val)':b='if(lt(val,12),0,val)'"):
        cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src.name, "-map", "0:v:0", "-an",
               "-vf", vf + crush, "-r", str(FPS), "-c:v", "libtheora", "-q:v", THEORA_Q, "-pix_fmt", "yuv420p",
               "-map_metadata", "-1", str(OUT.resolve())]
        subprocess.run(cmd, cwd=src.parent, check=True)
        dec = frames(OUT, w, h)
        corners = int(np.max([dec[:, 0, 0], dec[:, 0, -1], dec[:, -1, 0], dec[:, -1, -1]]))
        if corners <= 4:
            break
    assert corners <= 4, f"black level {corners}/255 after crush"
    track = [(i, *measure(k)) for i, k in enumerate(kept)]
    picks = sorted({round(j * (len(kept) - 1) / (KEYS + 1)) for j in range(KEYS + 2)})
    keys = [(i, round(cx - x, 1), round(cy - y, 1), d) for i, cx, cy, d in (track[p] for p in picks)]
    const = "const TORNADO_TRACK := [\n" + "".join(f"\t[{i}, {cx}, {cy}, {d}],\n" for i, cx, cy, d in keys) + "]"
    cmd_text = " ".join(c if " " not in c and "(" not in c else f'"{c}"' for c in cmd).replace(str(OUT.resolve()), OUT.name)
    lines = [
        "# Tornado booster video: provenance (SB-TF-06)", "",
        "Owner Flow video (Google Flow) chosen by the owner for the Tornado booster: a blue tornado on a",
        "black background, born small at the bottom right (the Tornado button), growing and travelling up",
        f"to the board centre, then spinning in place. 720x1280, 24 fps, {len(f)} frames, with an AAC track",
        "(dropped). The master stays in the owner's Downloads / the factory job folder (not committed).", "",
        "Built by `python tools/build_tornado_booster_video.py <master.mp4>` (ffmpeg libtheora, numpy).",
        f"Trim: start = first frame whose changed-pixel count exceeds 3x the idle level of frames 1-6",
        "(the tornado starts to grow); end = first frame whose bbox centre and width are within 3 px of",
        "the steady spin (median of the last 100 frames): end of travel, the spinning tail is dropped.",
        "Crop = bounding box of every pixel > 12/255 (above the master's H.264 edge specks) over the kept frames + 16 px, sides rounded up to 16.",
        "Played with additive blending (CanvasItemMaterial BLEND_MODE_ADD), so black adds nothing.", "",
        "## TORNADO",
        "",
        f"- master `{src.name}` sha256 `{sha(src)}`",
        f"- trim: source frames {start}-{end} ({len(kept)} frames, {len(kept) / FPS:.3f} s)",
        f"- crop x={x} y={y} w={w} h={h}",
        f"- black level: decoded corner pixels max {corners}/255 over every frame"
        + (" (near-black crushed by lutrgb)" if crush else " (no crush needed)"),
        f"- `{OUT.name}` sha256 `{sha(OUT)}` ({OUT.stat().st_size} bytes), Theora -q:v {THEORA_Q}, 24 fps, yuv420p, no audio",
        f"- encode (in the master's folder): `{cmd_text}`", "",
        "## Track (cropped-video px: [clip frame, centre x, centre y, diameter])", "",
        "Per kept frame: bbox of pixels with any channel > 40; centre = bbox centre, diameter = bbox width.",
        f"{len(keys)} evenly spaced keys incl. first (at the button) and last (end of travel); baked into",
        "`scripts/ui/feel/booster_vfx.gd` TORNADO_TRACK.", "", "```", const, "```", "",
    ]
    (OUT_DIR / "PROVENANCE.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(const)
    print(f"{OUT} {OUT.stat().st_size} bytes {w}x{h} frames {start}-{end} corners {corners}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
