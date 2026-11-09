#!/usr/bin/env python3
"""WCAG 2.3.1 general-flash count for videos or rendered frame sequences (SB-M50-018).

A pixel makes a transition when its relative luminance moves >= 0.10 away from its last
extreme in the opposite direction while the darker of the two is < 0.80 (WCAG "general flash"
definition). A frame is a screen transition when >= AREA of some 10-degree visual field
transitions in the same direction on it. The field is FIELD_W x FIELD_H frame widths: a ~6.8 cm
wide phone held at 30 cm puts a 10-degree field (~5.2 x 3.9 cm) over ~0.78 x 0.59 of the screen
width (the same fraction is used for a video's own frame, which is never larger on screen, so
this is the conservative reading). A flash is two opposing screen transitions; the result is
the most flashes in any 1 s window (rule: <= 3).

Inputs: video files (decoded with ffmpeg) or directories of PNG frames named in play order
(--fps gives their rate). Run: python tools/flash_audit.py [--selftest] [--fps 60] PATH...
"""
import argparse
import glob
import os
import subprocess
import sys

import numpy as np

STEP = 0.10      # WCAG: a change of >= 10% of the maximum relative luminance
DARK = 0.80      # ... where the darker image is below 0.80
AREA = 0.25      # share of the field that must change together
MAX_FLASHES = 3  # per any 1 s window
WIDTH = 96       # analysis width (px); height keeps the aspect
FIELD_W = 0.78   # 10-degree field, in frame widths
FIELD_H = 0.59


def luminance(rgb):
    """sRGB uint8 (..., 3) -> WCAG relative luminance."""
    c = rgb.astype(np.float32) / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def video_frames(path):
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                            "stream=width,height,r_frame_rate", "-of", "csv=p=0", path],
                           capture_output=True, text=True, check=True).stdout.strip().split(",")
    w, h = int(probe[0]), int(probe[1])
    num, den = probe[2].split("/")
    fps = float(num) / float(den)
    oh = max(2, int(round(h * WIDTH / w / 2)) * 2)
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-vf", "scale=%d:%d" % (WIDTH, oh),
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, oh, WIDTH, 3), fps


def png_frames(folder):
    from PIL import Image
    files = sorted(glob.glob(os.path.join(folder, "*.png")))
    out = []
    for f in files:
        im = Image.open(f).convert("RGB")
        out.append(np.asarray(im.resize((WIDTH, max(2, round(im.height * WIDTH / im.width))))))
    return np.stack(out)


def field_share(mask):
    """Largest share of any FIELD_W x FIELD_H window (clamped to the frame) that `mask` covers."""
    h, w = mask.shape
    fw, fh = max(1, min(w, round(FIELD_W * w))), max(1, min(h, round(FIELD_H * w)))
    ii = np.pad(mask.astype(np.int32).cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    s = ii[fh:, fw:] - ii[:-fh, fw:] - ii[fh:, :-fw] + ii[:-fh, :-fw]
    return float(s.max()) / (fw * fh)


def flash_count(lum, fps):
    """lum: (T, H, W) relative luminance. -> (max flashes in any 1 s, transition times, peak share)."""
    t_n, h, w = lum.shape
    px = lum.reshape(t_n, -1)
    ext = px[0].copy()                  # last extreme per pixel
    trend = np.zeros(px.shape[1], np.int8)   # +1 rising, -1 falling, 0 none yet
    times = []
    peak = 0.0
    for t in range(1, t_n):
        cur = px[t]
        up = (cur - ext >= STEP) & (np.minimum(cur, ext) < DARK) & (trend != 1)
        down = (ext - cur >= STEP) & (np.minimum(cur, ext) < DARK) & (trend != -1)
        # follow the extreme in the current direction
        ext = np.where(up | down, cur, ext)
        trend = np.where(up, 1, np.where(down, -1, trend)).astype(np.int8)
        ext = np.where((trend == 1) & (cur > ext), cur, ext)
        ext = np.where((trend == -1) & (cur < ext), cur, ext)
        for d, m in ((1, up), (-1, down)):
            share = field_share(m.reshape(h, w))
            peak = max(peak, share)
            if share >= AREA:
                if not times or times[-1][1] != d:
                    times.append((t / fps, d))
    best = 0
    for i, (t0, _d) in enumerate(times):
        n = sum(1 for tt, _ in times[i:] if tt - t0 < 1.0)
        best = max(best, n // 2)
    return best, times, peak


def selftest():
    fps = 60.0
    def run(seq):
        return flash_count(np.array(seq, np.float32)[:, None, None] * np.ones((1, 4, 4), np.float32), fps)[0]
    still = [0.2] * 60
    assert run(still) == 0
    blink4 = ([0.0] * 7 + [0.5] * 8) * 4   # 4 bright pulses in 1 s = 7 opposing changes
    assert run(blink4) == 3, run(blink4)
    blink5 = ([0.0] * 6 + [0.5] * 6) * 5   # 9 opposing changes in 1 s
    assert run(blink5) == 4, run(blink5)
    slow = ([0.0] * 30 + [0.5] * 30) * 2   # 1 cycle per second
    assert run(slow) == 1, run(slow)
    small = ([0.0] * 7 + [0.04] * 8) * 4   # below the 10% step
    assert run(small) == 0
    bright = ([0.85] * 7 + [1.0] * 8) * 4  # darker image >= 0.80: not a flash
    assert run(bright) == 0
    fade = list(np.linspace(0.0, 1.0, 30)) + list(np.linspace(1.0, 0.0, 30))   # one smooth up + down
    assert run(fade) == 1, run(fade)
    part = np.zeros((60, 40, 40), np.float32)
    part[:, :4, :4] = np.array(blink5)[:, None, None]   # 16 px of a 31x24 px field: under AREA
    assert flash_count(part, fps)[0] == 0
    part[:, :20, :20] = np.array(blink5)[:, None, None]   # 400 of 744 px of one field
    assert flash_count(part, fps)[0] == 4
    print("flash_audit selftest: PASS")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--fps", type=float, default=60.0, help="frame rate of PNG frame folders")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        selftest()
    worst = 0
    for p in a.paths:
        if os.path.isdir(p):
            rgb, fps = png_frames(p), a.fps
        else:
            rgb, fps = video_frames(p)
        n, times, peak = flash_count(luminance(rgb), fps)
        worst = max(worst, n)
        print("%s: %d frames @ %.0f fps, peak %.0f%% of a field changing at once, %d field transitions, max %d flashes / 1 s -> %s" % (
            os.path.basename(p.rstrip("/\\")), rgb.shape[0], fps, peak * 100, len(times), n, "PASS" if n <= MAX_FLASHES else "FAIL"))
    if a.paths:
        print("flash audit: %s (worst %d flashes / 1 s, limit %d)" % ("PASS" if worst <= MAX_FLASHES else "FAIL", worst, MAX_FLASHES))
    return 0 if worst <= MAX_FLASHES else 1


if __name__ == "__main__":
    sys.exit(main())
