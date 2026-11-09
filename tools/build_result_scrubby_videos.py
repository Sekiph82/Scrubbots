#!/usr/bin/env python3
"""SB-VIDEO-001/002/005/006/007/008/009/010, SB-POLISH-011B: Results WIN / LOSE, Level Intro Scrubby, Gift Meter box,
Collection set complete badge, Welcome back, New region, Need a Hand Scrubby and robot unlock videos from the owner's Flow masters.

For each master (720x1280, magenta chroma background) this crops every frame to the robot's
bounding box over ALL frames plus a margin, encodes Theora .ogv (magenta kept; the Results
screen keys it with scripts/ui/feel/chroma_key_magenta.gdshader), and writes frame 0 as a
PNG still keyed to transparent with the SAME key as the shader (so the still needs no
shader). Frame 0 equals the last frame, so the still is also the hold pose after playback.
Writes PROVENANCE.md next to the outputs. The masters are read-only input.

The gift set differs: flat GREEN background (keyed by chroma_key_green.gdshader), a fixed crop
per master (box + the sparkle burst above it) with a soft edge fade, and the still is the LAST
frame (the open glowing box the popup holds after playback).

set_complete: magenta like results, but a fixed square crop (badge + star burst) with the same soft
edge fade (chroma_key_magenta.gdshader edge_fade uniform) and the LAST frame (glowing badge) as still.
welcome_back, new_region, need_a_hand: exactly like results (bbox crop, no fade) except the still is the LAST frame.
robots: one video per roster robot on a MAGENTA, GREEN or BLUE background (ROBOT_KEY; blue is keyed by
chroma_key_blue.gdshader); crop = 5:6 box around everything that is foreground in >= 5 % of the frames (robot,
tool swings, recurring bubbles / water / sparkles), soft edge fade for the bursts it cuts, still = LAST frame.

Usage: python tools/build_result_scrubby_videos.py <flow_videos dir> [results|level_start|gift]
  results      result_scrubby_{win,lose}_master.mp4 -> assets/ui/final/popups/videos/ (default)
  level_start  level_start_scrubby_short_master.mp4 -> assets/ui/final/gameplay/videos/
  gift         gift_{box,crate}_opening_master.mp4 -> assets/ui/final/rewards/gift_videos/
  set_complete set_complete_master.mp4 -> assets/ui/final/rewards/set_complete_video/
  welcome_back welcome_back_master.mp4 -> assets/ui/final/popups/welcome_video/
  new_region   new_region_master.mp4 -> assets/ui/final/popups/new_region_video/
  need_a_hand  need_a_hand_master.mp4 -> assets/ui/final/popups/need_a_hand_video/
  robots       robot_<id>_master.mp4 -> assets/ui/final/robots/unlock_videos/<id>_unlock.ogv
"""
import hashlib
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# set -> (output dir, [(section, master file, output stem)], PROVENANCE.md header lines)
SETS = {
    "results": (Path("assets/ui/final/popups/videos"),
                [("win", "result_scrubby_win_master.mp4", "result_scrubby_win"),
                 ("lose", "result_scrubby_lose_master.mp4", "result_scrubby_lose")],
                ["# Results Scrubby videos: provenance (SB-VIDEO-001 / SB-VIDEO-002)", "",
                 "Owner Flow videos (Google Flow, Veo 3.1 Lite), Scrubby on a flat magenta (~#F00DE9)",
                 "chroma background (green is ruled out by the green sprout). Trimmed before import at",
                 "frame 184: 720x1280, 24 fps, 185 frames, first frame = last frame. The trimmed MP4",
                 "masters stay in the owner checkout (`flow_videos/`, not committed) and are read-only.", "",
                 "Built by `python tools/build_result_scrubby_videos.py flow_videos` (ffmpeg libtheora,"]),
    "level_start": (Path("assets/ui/final/gameplay/videos"),
                    [("level_start", "level_start_scrubby_short_master.mp4", "level_start_scrubby")],
                    ["# Level Intro Scrubby video: provenance (SB-VIDEO-005)", "",
                     "Owner Flow video (Google Flow, Veo 3.1 Lite), Scrubby's \"ready / let's go\" move on a",
                     "flat magenta (~#F00DE9) chroma background. Trimmed by the owner before import (short",
                     "master, frames 0-83): 720x1280, 24 fps, 84 frames (~3.5 s), first frame ~ last frame.",
                     "The MP4 master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.", "",
                     "Built by `python tools/build_result_scrubby_videos.py flow_videos level_start` (ffmpeg libtheora,"]),
    "gift": (Path("assets/ui/final/rewards/gift_videos"),
             [("gift_small", "gift_box_opening_master.mp4", "gift_small_opening", (76, 112, 624, 928)),
              ("gift_big", "gift_crate_opening_master.mp4", "gift_big_opening", (106, 288, 528, 800))],
             ["# Gift Meter box videos: provenance (SB-VIDEO-006)", "",
              "Owner Flow videos (Google Flow, Veo 3.1 Lite) on a flat green (#00FF00) chroma background:",
              "the small gift box (normal milestones, 161 frames, trimmed by the owner before the lid fades)",
              "and the big robotic crate (cycle-max milestone, 190 frames), both 720x1280, 24 fps.",
              "The MP4 masters stay in the owner checkout (`flow_videos/`, not committed) and are read-only.", "",
              "Built by `python tools/build_result_scrubby_videos.py flow_videos gift` (ffmpeg libtheora,",
              "numpy, Pillow). Crop = fixed box + sparkle burst above it (the crate crop ends where the lid",
              "debris lands on the right); anything the crop cuts fades out over 6 % of each side. The .ogv",
              "keeps the green (keyed at runtime by",
              "`scripts/ui/feel/chroma_key_green.gdshader`, same edge fade); the still is the LAST frame",
              "keyed to transparent with the same key at build time (the hold pose after playback).", ""]),
    "set_complete": (Path("assets/ui/final/rewards/set_complete_video"),
                     [("set_complete", "set_complete_master.mp4", "set_complete_badge", (48, 402, 624, 624))],
                     ["# Collection set complete badge video: provenance (SB-VIDEO-007)", "",
                      "Owner Flow video (Google Flow, Veo 3.1 Lite): the gold crowned set-complete badge pops,",
                      "flaps its wings, a light sweep crosses it, a star burst rains and it ends glowing, on a",
                      "magenta chroma background that drifts from ~#F802FA to ~#E136C8 (min(R,B)-G >= 140).",
                      "720x1280, 24 fps, 190 frames; frames 0-181 are used (the last 8 frames dissolve the wings and turn",
                      "the gold copper, so the hold pose is frame 181). The MP4 master stays in the owner checkout (`flow_videos/`,",
                      "not committed) and is read-only.", "",
                      "Built by `python tools/build_result_scrubby_videos.py flow_videos set_complete` (ffmpeg",
                      "libtheora, numpy, Pillow). Crop = fixed square around the badge + the star burst (stars fill",
                      "the whole frame, so a bbox would be the full frame); anything the crop cuts fades out over",
                      "6 % of each side. The .ogv keeps the magenta (keyed at runtime by",
                      "`scripts/ui/feel/chroma_key_magenta.gdshader` with edge_fade 0.06); the still is the LAST",
                      "frame keyed to transparent with the same key at build time (the hold pose after playback).", ""]),
    "welcome_back": (Path("assets/ui/final/popups/welcome_video"),
                     [("welcome_back", "welcome_back_master.mp4", "welcome_back_scrubby")],
                     ["# Welcome back Scrubby video: provenance (SB-VIDEO-008)", "",
                      "Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby jumps, waves both hands, hugs himself,",
                      "waves and ends near the start pose, on a magenta chroma background that drifts from ~#FA05F8",
                      "to ~#E337CA (min(R,B)-G >= 140). 720x1280, 24 fps, 190 frames. The MP4 master stays in the",
                      "owner checkout (`flow_videos/`, not committed) and is read-only.", "",
                      "Built by `python tools/build_result_scrubby_videos.py flow_videos welcome_back` (ffmpeg libtheora,"]),
    "new_region": (Path("assets/ui/final/popups/new_region_video"),
                   [("new_region", "new_region_master.mp4", "new_region_scrubby")],
                   ["# New region unlock Scrubby video: provenance (SB-VIDEO-009)", "",
                    "Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby looks into the distance, points, jumps,",
                    "does a fast full spin (the sprout is lost to motion blur for a few frames around 116-136) and",
                    "lands in a ready pose with golden sparkles, on a magenta chroma background that drifts from",
                    "~#FA05FA to ~#E126D7 (min(R,B)-G >= 170). Generic (not world-specific). 720x1280, 24 fps, 190 frames. The MP4",
                    "master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.", "",
                    "Built by `python tools/build_result_scrubby_videos.py flow_videos new_region` (ffmpeg libtheora,"]),
    "need_a_hand": (Path("assets/ui/final/popups/need_a_hand_video"),
                    [("need_a_hand", "need_a_hand_master.mp4", "need_a_hand_scrubby")],
                    ["# Need a Hand Scrubby video: provenance (SB-POLISH-011B)", "",
                     "Owner Flow video (Google Flow, Veo 3.1 Lite): Scrubby with a cyan \"?\" thinks, gets an idea,",
                     "gives a thumbs-up, waves to help and returns to the start pose with the \"?\", on a magenta",
                     "chroma background that drifts from ~#FA02FA to ~#E637CB (min(R,B)-G >= 140). 720x1280, 24 fps, 190 frames; frames",
                     "0-181 are used (the last 8 frames dim the eyes and fade the \"?\" out, so the hold pose is frame",
                     "181). The MP4 master stays in the owner checkout (`flow_videos/`, not committed) and is read-only.", "",
                     "Built by `python tools/build_result_scrubby_videos.py flow_videos need_a_hand` (ffmpeg libtheora,"]),
    "robots": (Path("assets/ui/final/robots/unlock_videos"),
               [(r, f"robot_{r}_master.mp4", f"{r}_unlock") for r in
                ("scrubby", "moppy", "bubbles", "spark", "squeegee", "dusty", "rinse", "polly", "clippy", "atlas")],
               ["# Robot unlock signature videos: provenance (SB-VIDEO-010)", "",
                "Owner Flow videos (Google Flow, Veo 3.1 Lite, Frames to Video from the",
                "`flow_start_frame_robot_<id>_<key>_1080x1920.png` start frames, prompts in",
                "`flow_videos/ROBOT_VIDEO_PROMPTS.md`): each roster robot powers on and does its signature move,",
                "720x1280, 24 fps, 190 frames. Background per robot (ROBOT_KEY): magenta drifting from ~#F802FA",
                "towards ~#DE2BCD (scrubby ends ~#C843B1), flat green ~#01FD04 (bubbles, polly), or blue drifting",
                "from ~#0003F8 to ~#0F1FAB (clippy). The MP4 masters stay in the owner checkout (`flow_videos/`, not",
                "committed) and are read-only.", "",
                "Built by `python tools/build_result_scrubby_videos.py flow_videos robots` (ffmpeg libtheora, numpy,",
                "Pillow). Crop = 5:6 box (the Robot Unlock hero aspect) around every pixel that is foreground in",
                ">= 5 % of the frames (robot, tool swings, recurring bubbles / water / sparkles) + 16 px, clamped to",
                "the frame (shifted to keep the robot body inside), then scaled to 480x576 (lanczos); short",
                "full-frame bursts (sparkle rain, speed lines) the crop cuts fade out over 6 % of each side.",
                "The .ogv keeps the background colour (keyed at runtime by",
                "`scripts/ui/feel/chroma_key_{magenta,green,blue}.gdshader`, edge fade 0.06); the still is the",
                "LAST frame used, keyed to transparent with the same key at build time (the hold pose).", ""]),
}
ROBOT_KEY = {"bubbles": "green", "polly": "green", "clippy": "blue"}   # every other robot: magenta
W, H = 720, 1280
MARGIN = 16
KEY_LO, KEY_HI = 0.15, 0.45   # keep in sync with chroma_key_magenta.gdshader / chroma_key_green.gdshader
TRIM = {"set_complete": 182,  # frames kept: the master's last 8 frames dissolve the wings and turn the gold copper
        "need_a_hand": 182,   # the last 8 frames dim the eyes and fade the "?" out
        "polly": 180,         # the last 10 frames power the face screen down and blur the polisher away
        "spark": 185}         # the last 5 frames swing the brush down and morph its head
ROBOT_OUT = (480, 576)        # robots: every crop is scaled to this (>= the 400x480 hero box, keeps the APK small)
BLUE_LO, BLUE_HI = 0.30, 0.45 # keep in sync with chroma_key_blue.gdshader (purple armour stays below B - max(R, G) 0.3)
EDGE = 0.06                   # gift / set_complete edge fade (UV fraction per side), keep in sync with the shaders


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


def key(rgb: np.ndarray, edge: float = 0.0) -> np.ndarray:
    """Magenta -> alpha (soft edge) + despill R/B toward G only where R and B both exceed G (x the edge fade)."""
    c = rgb.astype(np.float32) / 255.0
    m = np.minimum(c[..., 0], c[..., 2]) - c[..., 1]
    spill = np.maximum(m, 0.0)
    c[..., 0] -= spill
    c[..., 2] -= spill
    t = np.clip((m - KEY_LO) / (KEY_HI - KEY_LO), 0.0, 1.0)
    a = (1.0 - t * t * (3.0 - 2.0 * t)) * (fade(m.shape, edge) if edge > 0.0 else 1.0)   # 1 - smoothstep, as in the shader
    return (np.dstack([c, a]) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)


def smoothstep(e0: float, e1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def fade(shape: tuple[int, int], edge: float) -> np.ndarray:
    """Soft UV edge fade over `edge` of each side, as in the shaders."""
    h, w = shape
    u = (np.arange(w) + 0.5) / w
    v = (np.arange(h) + 0.5) / h
    return np.outer(smoothstep(0.0, edge, v) * smoothstep(0.0, edge, 1.0 - v),
                    smoothstep(0.0, edge, u) * smoothstep(0.0, edge, 1.0 - u))


def key_green(rgb: np.ndarray) -> np.ndarray:
    """Green -> alpha (soft edge) + despill G toward max(R, B) where G exceeds both, x the edge fade."""
    c = rgb.astype(np.float32) / 255.0
    m = c[..., 1] - np.maximum(c[..., 0], c[..., 2])
    c[..., 1] -= np.maximum(m, 0.0)
    a = (1.0 - smoothstep(KEY_LO, KEY_HI, m)) * fade(m.shape, EDGE)
    return (np.dstack([c, a]) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)


def key_blue(rgb: np.ndarray, edge: float) -> np.ndarray:
    """Blue -> alpha (soft edge) + despill: B clamped to max(R, G) + BLUE_LO (purple stays purple), x the edge fade."""
    c = rgb.astype(np.float32) / 255.0
    m = c[..., 2] - np.maximum(c[..., 0], c[..., 1])
    c[..., 2] -= np.maximum(m - BLUE_LO, 0.0)
    a = (1.0 - smoothstep(BLUE_LO, BLUE_HI, m)) * fade(m.shape, edge)
    return (np.dstack([c, a]) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)


def robot_box(f: np.ndarray, k: str) -> tuple[int, int, int, int]:
    """5:6 box (multiples of 20 x 24) around what is foreground in >= 5 % of the frames + MARGIN, clamped to the
    frame; when that is too big, it is shifted to keep the robot body (foreground in >= 30 % of the frames) inside."""
    fg = np.zeros((H, W), np.int32)
    for c in f:
        c = c.astype(np.int16)
        m = {"magenta": np.minimum(c[..., 0], c[..., 2]) - c[..., 1], "green": c[..., 1] - np.maximum(c[..., 0], c[..., 2]),
             "blue": c[..., 2] - np.maximum(c[..., 0], c[..., 1])}[k]
        fg += m <= 80
    ys, xs = np.where(fg >= 0.05 * len(f))
    x0, x1, y0, y1 = xs.min() - MARGIN, xs.max() + MARGIN, ys.min() - MARGIN, ys.max() + MARGIN
    w = min(W, int(-(-max(x1 - x0 + 1, (y1 - y0 + 1) * 5 / 6) // 20)) * 20)
    h = w * 6 // 5
    bys, bxs = np.where(fg >= 0.3 * len(f))
    x = min(max(0, bxs.max() + MARGIN + 1 - w, min((x0 + x1 + 1 - w) // 2, bxs.min() - MARGIN)), W - w)
    y = min(max(0, bys.max() + MARGIN + 1 - h, min((y0 + y1 + 1 - h) // 2, bys.min() - MARGIN)), H - h)
    return int(x), int(y), int(w), int(h)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main(src: Path, which: str) -> None:
    out, items, header = SETS[which]
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    gift = which == "gift"
    robots = which == "robots"
    edge = EDGE if which in ("set_complete", "robots") else 0.0
    last = which in ("gift", "set_complete", "welcome_back", "new_region", "need_a_hand", "robots")
    for name, master_name, stem, *fixed in items:
        master = src / master_name
        f = frames(master)[:TRIM.get(name)]
        k = ROBOT_KEY.get(name, "magenta")
        x, y, w, h = fixed[0] if fixed else robot_box(f, k) if robots else crop_box(f)
        ogv = out / f"{stem}.ogv"
        still = out / f"{stem}_still.png"
        cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(master), "-map", "0:v:0", "-an",
               *(["-frames:v", str(TRIM[name])] if name in TRIM else []), "-vf", f"crop={w}:{h}:{x}:{y}" + (f",scale={ROBOT_OUT[0]}:{ROBOT_OUT[1]}:flags=lanczos" if robots else ""), "-c:v", "libtheora", "-q:v", "8", "-pix_fmt", "yuv420p",
               "-map_metadata", "-1", str(ogv)]
        subprocess.run(cmd, check=True)
        hold = f[-1 if last else 0, y:y + h, x:x + w]
        if robots:
            hold = np.asarray(Image.fromarray(hold).resize(ROBOT_OUT, Image.LANCZOS))
        keyed = key_green(hold) if gift or k == "green" else key_blue(hold, edge) if k == "blue" else key(hold, edge)
        Image.fromarray(keyed, "RGBA").save(still, optimize=True)
        rows.append((name, master, f.shape[0], (x, y, w, h), ogv, still, cmd))
    lines = header + ([] if gift or edge else [
             "numpy, Pillow). Crop = robot bounding box over all frames + 16 px, sides rounded up to 16.",
             "The .ogv keeps the magenta (keyed at runtime by",
             "`scripts/ui/feel/chroma_key_magenta.gdshader`); the still is " + ("the LAST frame" if last else "frame 0") + " keyed to",
             "transparent with the same key at build time.", ""])
    for name, master, n, (x, y, w, h), ogv, still, cmd in rows:
        lines += [f"## {name.upper()}", ""] + ([f"- key {ROBOT_KEY.get(name, 'magenta')}"] if robots else []) + [
                  f"- master `{master.name}` sha256 `{sha(master)}` ({n} frames{' used' if name in TRIM else ''})",
                  f"- crop x={x} y={y} w={w} h={h}",
                  f"- `{ogv.name}` sha256 `{sha(ogv)}` ({ogv.stat().st_size} bytes)",
                  f"- `{still.name}` sha256 `{sha(still)}` ({still.stat().st_size} bytes)",
                  f"- encode: `{' '.join(Path(c).name if c.endswith('.mp4') or c.endswith('.ogv') else c for c in cmd)}`", ""]
    (out / "PROVENANCE.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    for r in rows:
        print(r[0], "crop", r[3], r[4], r[5])


if __name__ == "__main__":
    main(Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else "results")
