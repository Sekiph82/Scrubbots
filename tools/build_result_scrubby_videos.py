#!/usr/bin/env python3
"""SB-VIDEO-001/002: Results WIN / LOSE Scrubby videos from the owner's Flow masters.

For each master (720x1280, magenta chroma background) this crops every frame to the robot's
bounding box over ALL frames plus a margin, encodes Theora .ogv (magenta kept; the Results
screen keys it with scripts/ui/feel/chroma_key_magenta.gdshader), and writes frame 0 as a
PNG still keyed to transparent with the SAME key as the shader (so the still needs no
shader). Frame 0 equals the last frame, so the still is also the hold pose after playback.
Writes PROVENANCE.md next to the outputs. The masters are read-only input.

Usage: python tools/build_result_scrubby_videos.py <dir with result_scrubby_{win,lose}_master.mp4>
"""
import hashlib
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path("assets/ui/final/popups/videos")
W, H = 720, 1280
MARGIN = 16
KEY_LO, KEY_HI = 0.15, 0.45   # keep in sync with chroma_key_magenta.gdshader


def frames(path: Path) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3)


def crop_box(f: np.ndarray) -> tuple[int, int, int, int]:
    """Robot bounding box over all frames + MARGIN, sides rounded up to multiples of 16."""
    c = f.astype(np.int16)
    fg = ((np.minimum(c[..., 0], c[..., 2]) - c[..., 1]) <= 80).any(axis=0)
    ys, xs = np.where(fg)
    box = []
    for lo, hi, size in ((xs.min(), xs.max(), W), (ys.min(), ys.max(), H)):
        n = min(size, -(-(hi - lo + 1 + 2 * MARGIN) // 16) * 16)
        start = min(max(0, (lo + hi + 1 - n) // 2), size - n)
        box += [int(start), int(n)]
    return box[0], box[2], box[1], box[3]   # x, y, w, h


def key(rgb: np.ndarray) -> np.ndarray:
    """Magenta -> alpha (soft edge) + despill R/B toward G only where R and B both exceed G."""
    c = rgb.astype(np.float32) / 255.0
    m = np.minimum(c[..., 0], c[..., 2]) - c[..., 1]
    spill = np.maximum(m, 0.0)
    c[..., 0] -= spill
    c[..., 2] -= spill
    t = np.clip((m - KEY_LO) / (KEY_HI - KEY_LO), 0.0, 1.0)
    a = 1.0 - t * t * (3.0 - 2.0 * t)   # 1 - smoothstep, as in the shader
    return (np.dstack([c, a]) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main(src: Path) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for name in ("win", "lose"):
        master = src / f"result_scrubby_{name}_master.mp4"
        f = frames(master)
        x, y, w, h = crop_box(f)
        ogv = OUT / f"result_scrubby_{name}.ogv"
        still = OUT / f"result_scrubby_{name}_still.png"
        cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(master), "-map", "0:v:0", "-an",
               "-vf", f"crop={w}:{h}:{x}:{y}", "-c:v", "libtheora", "-q:v", "8", "-pix_fmt", "yuv420p",
               "-map_metadata", "-1", str(ogv)]
        subprocess.run(cmd, check=True)
        Image.fromarray(key(f[0, y:y + h, x:x + w]), "RGBA").save(still, optimize=True)
        rows.append((name, master, f.shape[0], (x, y, w, h), ogv, still, cmd))
    lines = ["# Results Scrubby videos: provenance (SB-VIDEO-001 / SB-VIDEO-002)", "",
             "Owner Flow videos (Google Flow, Veo 3.1 Lite), Scrubby on a flat magenta (~#F00DE9)",
             "chroma background (green is ruled out by the green sprout). Trimmed before import at",
             "frame 184: 720x1280, 24 fps, 185 frames, first frame = last frame. The trimmed MP4",
             "masters stay in the owner checkout (`flow_videos/`, not committed) and are read-only.", "",
             "Built by `python tools/build_result_scrubby_videos.py flow_videos` (ffmpeg libtheora,",
             "numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.",
             "The .ogv keeps the magenta (keyed at runtime by",
             "`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is frame 0 keyed to",
             "transparent with the same key at build time.", ""]
    for name, master, n, (x, y, w, h), ogv, still, cmd in rows:
        lines += [f"## {name.upper()}", "",
                  f"- master `{master.name}` sha256 `{sha(master)}` ({n} frames)",
                  f"- crop x={x} y={y} w={w} h={h}",
                  f"- `{ogv.name}` sha256 `{sha(ogv)}` ({ogv.stat().st_size} bytes)",
                  f"- `{still.name}` sha256 `{sha(still)}` ({still.stat().st_size} bytes)",
                  f"- encode: `{' '.join(Path(c).name if c.endswith('.mp4') or c.endswith('.ogv') else c for c in cmd)}`", ""]
    (OUT / "PROVENANCE.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    for r in rows:
        print(r[0], "crop", r[3], r[4], r[5])


if __name__ == "__main__":
    main(Path(sys.argv[1]))
