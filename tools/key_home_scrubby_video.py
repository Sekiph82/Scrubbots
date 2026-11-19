"""SB-TF-13: a keyed Home Scrubby gesture video from an owner magenta clip (the owner file is only read).

Same pipeline as the SB-TF-03 wave (factory/jobs/183-tf03-home-profile/make_wave.py): the source is
720x1280, 24 fps, on a magenta background that drifts between frames. Per frame the background
colour is sampled (median of the frame border):
  alpha = smoothstep(D_LO, D_HI, |frame - bg|) inside the Scrubby region, 0 outside;
  out   = frame + (1 - alpha) * (#FF00FF - bg)   (background -> exact magenta, edges keep Scrubby's
          colour blended with exact magenta, which chroma_key_magenta.gdshader keys cleanly).
Frames 0..FRAMES-1 are kept, 2-of-3 temporal vote on the hard mask, libtheora -q:v 8, 24 fps, no
audio. Evidence: <name>_f0.png (keyed frame 0) and <name>_contact.png (frames 0, 25/50/75 %, last,
composited like the runtime shader onto slate + light bands so a magenta fringe or a lost brush
shows), downscaled.
Usage: python -I tools/key_home_scrubby_video.py <src mp4> <out ogv> <evidence dir> <name>
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

FFMPEG = "ffmpeg"
W, H = 720, 1280
FRAMES = 185                     # 0..184, like every keyed Home video
REGION = (100, 380, 660, 1000)   # x0, y0, x1, y1 (video px) Scrubby may occupy
D_LO, D_HI = 60.0, 140.0         # summed |frame - bg| : below = background, above = Scrubby
MAGENTA = np.array([255.0, 0.0, 255.0])


def frames(path):
    p = subprocess.Popen([FFMPEG, "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    while True:
        b = p.stdout.read(W * H * 3)
        if len(b) < W * H * 3:
            break
        yield np.frombuffer(b, np.uint8).reshape(H, W, 3).astype(np.float32)
    p.wait()


def bg_colour(f):
    border = np.concatenate([f[:40].reshape(-1, 3), f[-40:].reshape(-1, 3), f[:, :40].reshape(-1, 3), f[:, -40:].reshape(-1, 3)])
    return np.median(border, 0)


def shader_composite(o):
    """chroma_key_magenta.gdshader formula over slate + light bands (evidence only)."""
    c = o.astype(np.float32) / 255.0
    m = np.minimum(c[..., 0], c[..., 2]) - c[..., 1]
    spill = np.maximum(m, 0.0)[..., None]
    rgb = c.copy()
    rgb[..., 0:1] -= spill
    rgb[..., 2:3] -= spill
    t = np.clip((m - 0.15) / 0.30, 0.0, 1.0)
    alpha = (1.0 - t * t * (3.0 - 2.0 * t))[..., None]
    back = np.zeros_like(rgb)
    back[...] = (0.125, 0.145, 0.2)
    back[np.arange(H) % 160 < 80] = (0.85, 0.88, 0.92)
    return Image.fromarray((np.clip(rgb * alpha + back * (1.0 - alpha), 0, 1) * 255 + 0.5).astype(np.uint8))


def main():
    src, out, ev, name = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4]
    raw = list(frames(src))
    assert len(raw) >= FRAMES, len(raw)
    print(f"source frames {len(raw)}; kept 0..{FRAMES - 1}, last-vs-first mean diff {float(np.abs(raw[FRAMES - 1] - raw[0]).sum(-1).mean()):.2f}")
    raw = raw[:FRAMES]
    region = np.zeros((H, W), bool)
    region[REGION[1]:REGION[3], REGION[0]:REGION[2]] = True
    bgs, alphas, hard = [], [], []
    for f in raw:
        bg = bg_colour(f)
        d = np.abs(f - bg).sum(-1)
        a = np.clip((d - D_LO) / (D_HI - D_LO), 0.0, 1.0)
        a = a * a * (3.0 - 2.0 * a)
        m = (d > D_LO) & region
        lab, n = ndi.label(m)
        if n:   # Scrubby is the big component(s); specks of compression noise drop out
            sizes = ndi.sum(m, lab, range(1, n + 1))
            m = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= max(400, 0.02 * sizes.max())])
        bgs.append(bg)
        alphas.append(a)
        hard.append(m)
    stack = np.stack(hard).astype(np.uint8)
    pad = np.concatenate([stack[:1], stack, stack[-1:]])
    voted = (pad[:-2] + pad[1:-1] + pad[2:]) >= 2
    enc = subprocess.Popen([FFMPEG, "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
                            "-r", "24", "-i", "-", "-c:v", "libtheora", "-q:v", "8", "-an", str(out)], stdin=subprocess.PIPE)
    kept = []
    for i, f in enumerate(raw):
        keep = ndi.binary_dilation(voted[i], iterations=2)
        a = (alphas[i] * keep)[..., None]
        o = np.clip(f + (1.0 - a) * (MAGENTA - bgs[i]), 0, 255)
        o[~keep] = MAGENTA
        o = (o + 0.5).astype(np.uint8)
        enc.stdin.write(o.tobytes())
        kept.append(o)
    enc.stdin.close()
    enc.wait()
    assert enc.returncode == 0
    print(f"bg first {bgs[0].astype(int)} middle {bgs[len(bgs) // 2].astype(int)} last {bgs[-1].astype(int)}")
    Image.fromarray(kept[0]).resize((W // 2, H // 2), Image.LANCZOS).save(ev / f"{name}_f0.png", optimize=True)
    idx = [0, len(kept) // 4, len(kept) // 2, 3 * len(kept) // 4, len(kept) - 1]
    tiles = [shader_composite(kept[i]).crop(REGION).resize((280, 310), Image.LANCZOS) for i in idx]
    sheet = Image.new("RGB", (280 * len(tiles), 310))
    for k, t in enumerate(tiles):
        sheet.paste(t, (k * 280, 0))
    sheet.save(ev / f"{name}_contact.png", optimize=True)
    print("frames kept", len(kept), "contact frames", idx)


if __name__ == "__main__":
    main()
