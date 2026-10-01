#!/usr/bin/env python3
"""Deterministically stage, validate, normalize, and report M42-C003 V02/V03 art."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
import zipfile
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw


ARCHIVE_SHA256 = "f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458"
MANIFEST = Path("coordination/sessions/M42-C003/OWNER_SOURCE_ASSET_MANIFEST_V02.md")
HOME = Path("assets/ui/final/characters/scrubby/scrubby_home_pose.png")
SOURCE_ROOT = Path("assets/ui/generated/characters/home_animation/source_v02")
CANDIDATE_ROOT = Path("assets/ui/generated/characters/home_animation")
FINAL_ROOT = Path("assets/ui/final/characters/scrubby/home_animation")
CANVAS = (1158, 1358)
ROOT = (592.0, 1318.0)
FAMILIES = {
    "wave": ("wave assets", 14),
    "bow": ("bow assets", 15),
    "turn_look": ("turn look assets", 17),
    "full_turn": ("full turn assets", 17),
}
SEQUENCE_SOURCES: dict[str, tuple[str, list[str]]] = {
    "wave": ("wave", [f"wave_{i:02d}.png" for i in [1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2]]),
    "bow": ("bow", [f"bow_{i:02d}.png" for i in [1, 2, 3, 4, 5, 6, 7, 7, 7, 8, 9, 10, 11, 10, 9]]),
    "turn": ("full_turn", [f"full_turn_{i:02d}.png" for i in [17, 2, 1, 2, 1, 16, 17, 16, 15, 15, 15, 15, 16, 17, 16, 17, 17]]),
    "full_turn": ("full_turn", [f"full_turn_{i:02d}.png" for i in range(1, 18)]),
}
ZONES = {
    "K1_COLLECTION": (0, 40, 70, 309),
    "K2_DAILY": (1115, 40, 1158, 309),
    "K3_RIGHT_HELPER": (1059, 829, 1158, 1340),
    "K4_LEFT_HELPER": (0, 999, 126, 1358),
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def manifest_hashes(text: str) -> dict[str, dict[str, str]]:
    current = ""
    output: dict[str, dict[str, str]] = {key: {} for key in FAMILIES}
    aliases = {"wave assets": "wave", "bow assets": "bow", "turn look assets": "turn_look", "turn / look assets": "turn_look", "full turn assets": "full_turn"}
    for line in text.splitlines():
        heading = re.match(r"##\s+(.+?)\s*$", line)
        if heading:
            current = aliases.get(heading.group(1).lower(), "")
            continue
        if not current:
            continue
        row = re.match(r"\|\s*`([^`]+\.png)`\s*\|\s*\d+x\d+\s*\|\s*`([0-9a-f]{64})`\s*\|", line, re.I)
        if row:
            output[current][row.group(1)] = row.group(2).lower()
    return output


def alpha_bbox(image: Image.Image, threshold: int = 128) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").point(lambda p: 255 if p > threshold else 0).getbbox()


def feature_metrics(image: Image.Image) -> dict[str, Any]:
    """Report alpha bounds and robust dark visor bounds used for family scale fitting."""
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha_bbox(image)
    if bbox is None:
        raise ValueError("source has no alpha>128 pixels")
    x0, y0, x1, y1 = bbox
    # Visor is the dark region within the upper central character envelope.
    # A raster threshold measures its bounding envelope without changing source bytes.
    visor_x0 = x0 + int((x1 - x0) * 0.18)
    visor_x1 = x0 + int((x1 - x0) * 0.82)
    visor_y0 = y0 + int((y1 - y0) * 0.12)
    visor_y1 = y0 + int((y1 - y0) * 0.62)
    region = image.crop((visor_x0, visor_y0, visor_x1, visor_y1))
    dark = region.convert("RGB").convert("L").point(lambda p: 255 if p < 42 else 0)
    alpha_mask = region.getchannel("A").point(lambda p: 255 if p > 128 else 0)
    local = ImageChops.multiply(dark, alpha_mask).getbbox()
    visor = (local[0] + visor_x0, local[1] + visor_y0, local[2] + visor_x0, local[3] + visor_y0) if local else None
    return {
        "size": list(image.size),
        "alpha_bbox": list(bbox),
        "opaque_pixels": sum(alpha.histogram()[129:]),
        "visor_bbox_approx": list(visor) if visor else None,
        "visor_width_approx": visor[2] - visor[0] if visor else None,
        "root_estimate": [round((x0 + x1) / 2, 2), round(y1 - 8, 2)],
    }


def verify_and_stage(archive: Path, root: Path, evidence: str = "coordination/sessions/M42-C003/evidence_v02") -> dict[str, Any]:
    manifest = manifest_hashes((root / MANIFEST).read_text(encoding="utf-8"))
    if sum(map(len, manifest.values())) != 63:
        raise ValueError(f"manifest must enumerate 63 hashes; found {sum(map(len, manifest.values()))}")
    archive_hash = sha256(archive.read_bytes())
    if archive_hash != ARCHIVE_SHA256:
        raise ValueError(f"archive hash mismatch: {archive_hash}")
    rows: list[dict[str, Any]] = []
    mapping: dict[str, list[dict[str, str]]] = {}
    with zipfile.ZipFile(archive) as zf:
        for family, (archive_dir, count) in FAMILIES.items():
            expected_names = {f"{family if family != 'turn_look' else 'turn look'}_{i:02d}.png" for i in range(1, count + 1)}
            if set(manifest[family]) != expected_names:
                raise ValueError(f"{family}: manifest filename set mismatch")
            staged_names: list[dict[str, str]] = []
            for i in range(1, count + 1):
                source_name = f"{family if family != 'turn_look' else 'turn look'}_{i:02d}.png"
                arcname = f"Home_Main_Hero_Assets/{archive_dir}/{source_name}"
                raw = zf.read(arcname)
                digest = sha256(raw)
                if digest != manifest[family][source_name]:
                    raise ValueError(f"source hash mismatch: {source_name}: {digest}")
                staged = f"{family}_{i:02d}.png"
                target = root / SOURCE_ROOT / family / staged
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(raw)
                with Image.open(target) as src:
                    metrics = feature_metrics(src)
                rows.append({"family": family, "source_name": source_name, "staged_name": staged, "source_path": str(SOURCE_ROOT / family / staged).replace("\\", "/"), "sha256": digest, **metrics})
                staged_names.append({"archive_name": arcname, "staged_name": staged, "sha256": digest})
            mapping[family] = staged_names
    report = {"archive_path": str(archive), "archive_sha256": archive_hash, "source_frames": len(rows), "frames": rows, "staging_map": mapping}
    out = root / evidence / "source_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (root / evidence / "source_mapping.json").write_text(json.dumps(mapping, indent=2) + "\n", encoding="utf-8")
    return report


def root_estimate(image: Image.Image) -> tuple[float, float]:
    """Estimate planted sole midpoint from opaque pixels around the lower central feet."""
    image = image.convert("RGBA")
    bbox = alpha_bbox(image)
    if bbox is None:
        raise ValueError("empty source image")
    x0, y0, x1, y1 = bbox
    a = image.getchannel("A")
    mid = (x0 + x1) / 2
    left, right = mid - (x1 - x0) * 0.24, mid + (x1 - x0) * 0.24
    last_y = y1 - 1
    for y in range(y1 - 1, y0 + int((y1 - y0) * 0.58), -1):
        count = sum(1 for x in range(max(0, int(left)), min(image.width, int(right))) if a.getpixel((x, y)) > 128)
        if count >= 4:
            last_y = y
            break
    xs = [x for x in range(max(0, int(left)), min(image.width, int(right))) if a.getpixel((x, last_y)) > 128]
    return (sum(xs) / len(xs) if xs else mid, float(last_y))


def zone_counts(image: Image.Image) -> dict[str, int]:
    a = image.getchannel("A")
    result: dict[str, int] = {}
    for name, (x0, y0, x1, y1) in ZONES.items():
        crop = a.crop((x0, y0, min(x1, image.width), min(y1, image.height)))
        result[name] = sum(crop.histogram()[129:])
    return result


def normalize(root: Path, source_report: dict[str, Any]) -> dict[str, Any]:
    home = Image.open(root / HOME).convert("RGBA")
    home_metrics = feature_metrics(home)
    home_visor = home_metrics["visor_width_approx"]
    family_frames: dict[str, list[dict[str, Any]]] = {}
    for row in source_report["frames"]:
        family_frames.setdefault(row["family"], []).append(row)
    output: list[dict[str, Any]] = []
    scales: dict[str, float] = {}
    for family, rows in family_frames.items():
        widths = [r["visor_width_approx"] for r in rows if r["visor_width_approx"]]
        if not widths:
            raise ValueError(f"no measurable visor in {family}")
        # One shared uniform family scale: median visor width fit, constrained to canvas.
        source_scale = home_visor / sorted(widths)[len(widths) // 2]
        retained_bounds: list[tuple[int, int, int, int]] = []
        for row in rows:
            src = Image.open(root / row["source_path"]).convert("RGBA")
            bounds = alpha_bbox(src, 2)
            if bounds is None:
                raise ValueError(f"source has no retained-alpha pixels: {row['source_name']}")
            retained_bounds.append(bounds)
        width_limit = min((CANVAS[0] - 8) / (b[2] - b[0]) for b in retained_bounds)
        height_limit = min((CANVAS[1] - 8) / (b[3] - b[1]) for b in retained_bounds)
        aligned_limits: list[float] = []
        for row in rows:
            src = Image.open(root / row["source_path"]).convert("RGBA")
            rx, ry = root_estimate(src)
            bounds = alpha_bbox(src, 2)
            assert bounds is not None
            x0, y0, x1, y1 = bounds
            if rx > x0:
                aligned_limits.append((ROOT[0] - 1) / (rx - x0))
            if x1 > rx:
                aligned_limits.append((CANVAS[0] - ROOT[0] - 1) / (x1 - rx))
            if ry > y0:
                aligned_limits.append((ROOT[1] - 1) / (ry - y0))
            if y1 > ry:
                aligned_limits.append((CANVAS[1] - ROOT[1] - 1) / (y1 - ry))
        scale = min([source_scale, width_limit, height_limit, *aligned_limits])
        scales[family] = scale

    row_by_name = {(r["family"], r["source_name"]): r for r in source_report["frames"]}
    map_rows: dict[str, list[dict[str, str]]] = {}
    for runtime_family, (source_family, source_names) in SEQUENCE_SOURCES.items():
        map_rows[runtime_family] = []
        for i, source_name in enumerate(source_names, 1):
            row = row_by_name[(source_family, source_name)]
            src = Image.open(root / row["source_path"]).convert("RGBA")
            dst, rx, ry, px, py = render_frame(src, scales[source_family])
            target = root / CANDIDATE_ROOT / runtime_family / f"{runtime_family}_{i:02d}.png"
            target.parent.mkdir(parents=True, exist_ok=True)
            dst.save(target, format="PNG", optimize=False, compress_level=9)
            counts = zone_counts(dst)
            bounds = alpha_bbox(dst)
            output.append({"family": runtime_family, "source_family": source_family, "frame": i, "source": row["source_path"], "source_name": source_name, "source_sha256": row["sha256"], "scale": scales[source_family], "scale_basis": "one median visor-width family fit, constrained by maximum family frame bounds", "source_root_estimate": [round(rx, 3), round(ry, 3)], "registered_root": list(ROOT), "offset": [px, py], "alpha_bbox": list(bounds) if bounds else None, "zone_alpha_gt128": counts, "sha256": sha256(target.read_bytes()), "path": str(target.relative_to(root)).replace("\\", "/")})
            map_rows[runtime_family].append({"production_frame": f"{runtime_family}_{i:02d}.png", "source_family": source_family, "source_name": source_name, "source_sha256": row["sha256"]})

    mapping_path = root / "coordination/sessions/M42-C003/evidence_v02/production_sequence_mapping.json"
    mapping_path.write_text(json.dumps(map_rows, indent=2) + "\n", encoding="utf-8")
    safe_analysis = find_max_safe_scales(root, row_by_name, scales, map_rows, home)
    (root / "coordination/sessions/M42-C003/evidence_v02/safe_scale_analysis.json").write_text(json.dumps(safe_analysis, indent=2) + "\n", encoding="utf-8")
    report = {"home_sha256": sha256((root / HOME).read_bytes()), "home_visor_width_approx": home_visor, "canvas": list(CANVAS), "root": list(ROOT), "family_scales": scales, "frames": output}
    out = root / "coordination/sessions/M42-C003/evidence_v02/normalization_measurements.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def render_frame(src: Image.Image, scale: float) -> tuple[Image.Image, float, float, int, int]:
    # Remove only alpha<=2 fringe speckle; RGB and all retained art are unchanged.
    src = src.convert("RGBA")
    cleaned = src.copy()
    cleaned.putalpha(src.getchannel("A").point(lambda p: 0 if p <= 2 else p))
    rx, ry = root_estimate(src)
    resized = cleaned.resize((max(1, round(src.width * scale)), max(1, round(src.height * scale))), Image.Resampling.LANCZOS)
    px, py = round(ROOT[0] - rx * scale), round(ROOT[1] - ry * scale)
    source_bounds = alpha_bbox(cleaned, 2)
    if source_bounds:
        sx0, sy0, sx1, sy1 = source_bounds
        if px + math.floor(sx0 * scale) < 0 or py + math.floor(sy0 * scale) < 0 or px + math.ceil(sx1 * scale) > CANVAS[0] or py + math.ceil(sy1 * scale) > CANVAS[1]:
            raise ValueError(f"family scale clips opaque/retained pixels at source scale {scale}")
    dst = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    dst.alpha_composite(resized, (px, py))
    return dst, rx, ry, px, py


def find_max_safe_scales(root: Path, rows: dict[tuple[str, str], dict[str, Any]], fit_scales: dict[str, float], maps: dict[str, list[dict[str, str]]], home: Image.Image) -> dict[str, Any]:
    """Find the largest 0.05-step family scale satisfying V02 blocking zones."""
    home_alpha = home.getchannel("A").point(lambda p: 255 if p > 128 else 0)
    home_k4 = home_alpha.crop((0, 999, 126, 1358))
    results: dict[str, Any] = {}
    for runtime_family, entries in maps.items():
        source_family = entries[0]["source_family"]
        fit = fit_scales[source_family]
        strict = ["K1_COLLECTION", "K2_DAILY"]
        if runtime_family != "full_turn":
            strict.append("K3_RIGHT_HELPER")
        chosen = None
        tried: list[dict[str, Any]] = []
        scale = min(fit, round(fit, 2))
        while scale >= 0.5:
            maxima = {z: 0 for z in ZONES}
            bad_k4 = 0
            for entry in entries:
                row = rows[(source_family, entry["source_name"])]
                src = Image.open(root / row["source_path"]).convert("RGBA")
                frame, _, _, _, _ = render_frame(src, scale)
                counts = zone_counts(frame)
                for zone, count in counts.items():
                    maxima[zone] = max(maxima[zone], count)
                if runtime_family != "full_turn":
                    cand_k4 = frame.getchannel("A").point(lambda p: 255 if p > 128 else 0).crop((0, 999, 126, 1358))
                    bad_k4 = max(bad_k4, sum(ImageChops.subtract(cand_k4, home_k4).histogram()[1:]))
            valid = all(maxima[z] == 0 for z in strict)
            if runtime_family != "full_turn":
                valid = valid and bad_k4 == 0
            tried.append({"scale": round(scale, 2), "max_zone_alpha_gt128": maxima, "k4_outside_home_pixel_count": bad_k4, "blocking_zones_pass": valid})
            if valid:
                chosen = round(scale, 2)
                break
            scale = round(scale - 0.05, 2)
        source_widths = [r["visor_width_approx"] for (fam, _), r in rows.items() if fam == source_family and r["visor_width_approx"]]
        median_width = sorted(source_widths)[len(source_widths) // 2]
        safe = chosen if chosen is not None else 0.0
        results[runtime_family] = {
            "source_family": source_family,
            "fit_scale": fit,
            "fit_scale_visor_ratio_to_HOME": round(fit * median_width / home_visor_width(home), 4),
            "max_safe_scale": safe,
            "max_safe_scale_visor_ratio_to_HOME": round(safe * median_width / home_visor_width(home), 4),
            "fit_scale_retained_at_max_safe": round(safe / fit, 4) if fit else 0,
            "constraint_conflict": chosen is None or (fit * median_width / home_visor_width(home)) < 0.85 or safe < fit * 0.85,
            "note": "0.05 scale-step diagnostic. A measured visor width below 85% of HOME-026 or safe scale below 85% of family fit is flagged as visible scale loss; this is an audit aid, not a new owner tolerance.",
            "attempts": tried,
        }
    return {"algorithm": "descending 0.05 family-scale sweep; all selected production source frames; same root registration and alpha threshold", "home_k4_opaque_pixels": sum(home_k4.histogram()[129:]), "families": results}


def home_visor_width(home: Image.Image) -> int:
    width = feature_metrics(home)["visor_width_approx"]
    return int(width)


def transition_strip(root: Path, family: str, candidate_paths: list[Path], dest: Path) -> None:
    home = Image.open(root / HOME).convert("RGBA")
    paths: list[tuple[str, Image.Image]] = [("HOME-026 entry", home)]
    paths.extend((f"{family} {i:02d}", Image.open(path).convert("RGBA")) for i, path in enumerate(candidate_paths, 1))
    paths.append(("HOME-026 exit", home))
    cols, cell_w, cell_h = 4, 230, 286
    sheet = Image.new("RGBA", (cols * cell_w, math.ceil(len(paths) / cols) * cell_h), (56, 64, 78, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (label, frame) in enumerate(paths):
        frame.thumbnail((cell_w - 14, cell_h - 32), Image.Resampling.LANCZOS)
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        sheet.alpha_composite(frame, (x + (cell_w - frame.width) // 2, y + 4))
        draw.text((x + 6, y + cell_h - 20), label, fill="white")
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(dest, quality=95)


def write_measurement_summaries(root: Path, normalized: dict[str, Any]) -> None:
    evidence = root / "coordination/sessions/M42-C003/evidence_v02"
    lines = ["# M42-C003 V02 normalization measurements", "", f"HOME-026 SHA-256: `{normalized['home_sha256']}`", f"Canvas: `{CANVAS[0]}x{CANVAS[1]} RGBA8`", f"Root/soles target: `{ROOT[0]}, {ROOT[1]}`", "", "## Uniform family scales", ""]
    safe = json.loads((evidence / "safe_scale_analysis.json").read_text(encoding="utf-8"))
    lines.append("| Runtime family | Source family | Canvas-contained fit scale | Largest scale passing blocking zones | Retained scale | HOME visor ratio at fit | HOME visor ratio at safe scale | Conflict |")
    lines.append("|---|---|---:|---:|---:|---:|---:|---|")
    for family, row in safe["families"].items():
        lines.append(f"| {family} | {row['source_family']} | {row['fit_scale']:.4f} | {row['max_safe_scale']:.2f} | {row['fit_scale_retained_at_max_safe']:.1%} | {row['fit_scale_visor_ratio_to_HOME']:.1%} | {row['max_safe_scale_visor_ratio_to_HOME']:.1%} | {'YES' if row['constraint_conflict'] else 'no'} |")
    lines += ["", "## Frame measurements", "", "| Family | Frame | Scale | Root target | Alpha bounds | K1 | K2 | K3 | K4 | SHA-256 |", "|---|---:|---:|---|---|---:|---:|---:|---:|---|"]
    for frame in normalized["frames"]:
        z = frame["zone_alpha_gt128"]
        lines.append(f"| {frame['family']} | {frame['frame']:02d} | {frame['scale']:.4f} | `{frame['registered_root']}` | `{frame['alpha_bbox']}` | {z['K1_COLLECTION']} | {z['K2_DAILY']} | {z['K3_RIGHT_HELPER']} | {z['K4_LEFT_HELPER']} | `{frame['sha256']}` |")
    (evidence / "normalization_measurements.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    full = [f for f in normalized["frames"] if f["family"] == "full_turn"]
    overlap = ["# Full Turn K3/K4 overlap report", "", "K1/K2 remain blocking. V02 classifies K3/K4 Full Turn overlaps as measured visual warnings.", "", "| Frame | K3 right helper alpha>128 | K4 left helper alpha>128 |", "|---:|---:|---:|"]
    overlap += [f"| {f['frame']:02d} | {f['zone_alpha_gt128']['K3_RIGHT_HELPER']} | {f['zone_alpha_gt128']['K4_LEFT_HELPER']} |" for f in full]
    (evidence / "full_turn_helper_overlap.md").write_text("\n".join(overlap) + "\n", encoding="utf-8")


def contact_sheet(root: Path, family: str, paths: list[Path], dest: Path) -> None:
    cols = 5
    cell_w, cell_h = 250, 292
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (56, 64, 78, 255))
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        frame = Image.open(path).convert("RGBA")
        frame.thumbnail((cell_w - 12, cell_h - 32), Image.Resampling.LANCZOS)
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        sheet.alpha_composite(frame, (x + (cell_w - frame.width) // 2, y + 6))
        draw.text((x + 6, y + cell_h - 20), f"{family} {i+1:02d}", fill="white")
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(dest, quality=95)


# ---------------------------------------------------------------------------
# V03 (coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md,
# coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V03.md)
#
# One common larger animation canvas + one common pivot for all 63 frames. Each
# source family gets ONE uniform scale matched to HOME-026 identity (true visor
# component width + upright character height); every frame is registered so its
# planted rubber-sole midpoint lands on the common pivot. Frames are stored at
# V03_TEXELS_PER_PIXEL HOME texels per animation pixel (memory), which still keeps
# all source detail because every family scale exceeds it. Runtime maps the pivot
# onto the accepted HOME screen soles point.
# ---------------------------------------------------------------------------
import numpy as np  # noqa: E402  (V03 measurement only)
from scipy import ndimage  # noqa: E402

V03_EVIDENCE = "coordination/sessions/M42-C003/evidence_v03"
V03_CANDIDATES = Path("assets/ui/generated/characters/home_animation/v03")
V03_TEXELS_PER_PIXEL = 3
V03_MARGIN = 16
V03_ROUND = 16
V03_FPS = 12
V03_ALPHA_FLOOR = 2  # alpha <= 2 fringe speckle removed (same rule as V02)
V03_RESAMPLER = "Pillow Image.transform(AFFINE, BICUBIC) on premultiplied RGBa, exact sub-pixel root registration"
# Production sequences (source family, source frame numbers). Turn/Look uses the dedicated
# Turn/Look family per the owner choice of 2026-10-02 (bilateral; see CLAUDE_LOG_V03).
V03_SEQUENCES: dict[str, tuple[str, list[int]]] = {
    "wave": ("wave", [1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2]),
    "bow": ("bow", [1, 2, 3, 4, 5, 6, 7, 7, 7, 8, 9, 10, 11, 1, 1]),
    "turn": ("turn_look", [1, 2, 6, 5, 6, 7, 8, 8, 9, 10, 10, 9, 8, 15, 16, 17, 1]),
    "full_turn": ("full_turn", list(range(1, 18))),
}
V03_COUNTS = {"wave": 14, "bow": 15, "turn": 17, "full_turn": 17}


def v03_source_path(family: str, n: int) -> Path:
    return SOURCE_ROOT / family / f"{family}_{n:02d}.png"


def v03_identity(image: Image.Image) -> dict[str, Any]:
    """Visor = largest connected near-black component in the upper 60% of the character;
    yaw = visor centre offset inside the head silhouette row; height = alpha>128 rows."""
    a = np.asarray(image.convert("RGBA")).astype(np.int32)
    opaque = a[..., 3] > 128
    ys = np.nonzero(opaque)[0]
    y0, y1 = int(ys.min()), int(ys.max())
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    dark = (lum < 45) & opaque
    dark[int(y0 + (y1 - y0) * 0.6):] = False
    lab, n = ndimage.label(dark)
    sizes = ndimage.sum(dark, lab, range(1, n + 1))
    k = int(np.argmax(sizes)) + 1
    vy, vx = np.nonzero(lab == k)
    cy = int(np.median(vy))
    vcx = (int(vx.min()) + int(vx.max())) / 2
    row = opaque[cy]
    left = right = int(vcx)
    while left > 0 and row[left - 1]:
        left -= 1
    while right < row.size - 1 and row[right + 1]:
        right += 1
    head_w = max(1, right - left)
    off = vcx - (left + right) / 2
    yaw = math.degrees(math.asin(max(-1.0, min(1.0, 2 * off / head_w))))
    return {"visor_width": int(vx.max() - vx.min() + 1), "visor_height": int(vy.max() - vy.min() + 1),
            "visor_area": int(sizes[k - 1]), "character_height": y1 - y0 + 1, "yaw_deg": round(yaw, 1)}


def v03_sole_root(image: Image.Image) -> tuple[float, float]:
    """Planted root = midpoint of the dark, unsaturated rubber soles (bristles are bright
    cyan and excluded) within the lowest 8% band; y = lowest rubber pixel row."""
    a = np.asarray(image.convert("RGBA")).astype(np.int32)
    opaque = a[..., 3] > 128
    ys = np.nonzero(opaque)[0]
    y1 = int(ys.max())
    h = y1 - int(ys.min()) + 1
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    sat = a[..., :3].max(-1) - a[..., :3].min(-1)
    rubber = opaque & (lum < 70) & (sat < 45)
    rubber[: int(y1 - 0.25 * h)] = False
    sole_y = int(np.nonzero(rubber)[0].max())
    band = rubber[int(sole_y - 0.08 * h): sole_y + 1]
    bx = np.nonzero(band)[1]
    return (float(bx.min() + bx.max()) / 2.0, float(sole_y))


def v03_family_scales(root: Path, home: Image.Image) -> dict[str, Any]:
    hid = v03_identity(home)
    out: dict[str, Any] = {"home": hid, "families": {}}
    for family, (_, count) in FAMILIES.items():
        rows = []
        for n in range(1, count + 1):
            with Image.open(root / v03_source_path(family, n)) as im:
                m = v03_identity(im)
            rows.append({"frame": n, **m, "visor_ratio_scale": hid["visor_width"] / m["visor_width"],
                         "height_ratio_scale": hid["character_height"] / m["character_height"]})
        max_h = max(r["character_height"] for r in rows)
        comparable = [r for r in rows if abs(r["yaw_deg"]) <= 15 and r["character_height"] >= 0.93 * max_h]
        vals = sorted(math.sqrt(r["visor_ratio_scale"] * r["height_ratio_scale"]) for r in comparable)
        scale = vals[len(vals) // 2]
        out["families"][family] = {
            "scale_home_texels_per_source_px": scale,
            "basis": "median over comparable upright front frames (|yaw|<=15 deg, height>=93% of family max) of sqrt(HOME visor width ratio x HOME height ratio)",
            "comparable_frames": [r["frame"] for r in comparable],
            "visor_width_vs_home_at_scale": [round(r["visor_width"] * scale / hid["visor_width"], 4) for r in comparable],
            "height_vs_home_at_scale": [round(r["character_height"] * scale / hid["character_height"], 4) for r in comparable],
            "frames": rows,
        }
    return out


def v03_render(src: Image.Image, scale_px: float, root_xy: tuple[float, float], pivot: tuple[int, int], canvas: tuple[int, int]) -> Image.Image:
    """Uniform scale about the sole root, root -> pivot, premultiplied bicubic."""
    src = src.convert("RGBA")
    cleaned = src.copy()
    cleaned.putalpha(src.getchannel("A").point(lambda p: 0 if p <= V03_ALPHA_FLOOR else p))
    pre = cleaned.convert("RGBa")
    inv = 1.0 / scale_px
    # output (x, y) samples source ((x - px) / s + rx, (y - py) / s + ry)
    coeffs = (inv, 0.0, root_xy[0] - pivot[0] * inv, 0.0, inv, root_xy[1] - pivot[1] * inv)
    out = pre.transform(canvas, Image.Transform.AFFINE, coeffs, resample=Image.Resampling.BICUBIC, fillcolor=(0, 0, 0, 0))
    out = out.convert("RGBA")
    out.putalpha(out.getchannel("A").point(lambda p: 0 if p <= V03_ALPHA_FLOOR else p))
    return out


def v03_layout(root: Path, scales: dict[str, Any]) -> dict[str, Any]:
    """Common canvas + pivot from the union of all 63 registered production frames."""
    lo = [math.inf, math.inf]
    hi = [-math.inf, -math.inf]
    per: dict[tuple[str, int], dict[str, Any]] = {}
    for family, frames in V03_SEQUENCES.values():
        s_px = scales["families"][family]["scale_home_texels_per_source_px"] / V03_TEXELS_PER_PIXEL
        for n in frames:
            if (family, n) in per:
                continue
            with Image.open(root / v03_source_path(family, n)) as im:
                rx, ry = v03_sole_root(im)
                bb = im.getchannel("A").point(lambda p: 255 if p > V03_ALPHA_FLOOR else 0).getbbox()
            per[(family, n)] = {"root": (rx, ry), "scale_px": s_px}
            lo[0] = min(lo[0], (bb[0] - rx) * s_px)
            lo[1] = min(lo[1], (bb[1] - ry) * s_px)
            hi[0] = max(hi[0], (bb[2] - rx) * s_px)
            hi[1] = max(hi[1], (bb[3] - ry) * s_px)
    px = math.ceil(-lo[0]) + V03_MARGIN
    py = math.ceil(-lo[1]) + V03_MARGIN
    w = px + math.ceil(hi[0]) + V03_MARGIN
    h = py + math.ceil(hi[1]) + V03_MARGIN
    w = -(-w // V03_ROUND) * V03_ROUND
    h = -(-h // V03_ROUND) * V03_ROUND
    return {"canvas": (w, h), "pivot": (px, py), "union_rel_pivot_px": [lo[0], lo[1], hi[0], hi[1]], "per_source": per}


def v03_build(root: Path, out_root: Path) -> dict[str, Any]:
    home = Image.open(root / HOME).convert("RGBA")
    scales = v03_family_scales(root, home)
    layout = v03_layout(root, scales)
    canvas, pivot = layout["canvas"], layout["pivot"]
    home_root = v03_sole_root(home)
    frames: list[dict[str, Any]] = []
    for runtime_family, (family, seq) in V03_SEQUENCES.items():
        if len(seq) != V03_COUNTS[runtime_family]:
            raise ValueError(f"{runtime_family}: {len(seq)} frames != {V03_COUNTS[runtime_family]}")
        for i, n in enumerate(seq, 1):
            meta = layout["per_source"][(family, n)]
            with Image.open(root / v03_source_path(family, n)) as im:
                img = v03_render(im, meta["scale_px"], meta["root"], pivot, canvas)
            target = out_root / runtime_family / f"{runtime_family}_{i:02d}.png"
            target.parent.mkdir(parents=True, exist_ok=True)
            img.save(target, format="PNG", optimize=False, compress_level=9)
            bb = img.getchannel("A").point(lambda p: 255 if p > 128 else 0).getbbox()
            frames.append({"gesture": runtime_family, "frame": i, "source_family": family, "source_frame": n,
                           "source": str(v03_source_path(family, n)).replace("\\", "/"),
                           "source_sha256": sha256((root / v03_source_path(family, n)).read_bytes()),
                           "source_root": [round(meta["root"][0], 2), round(meta["root"][1], 2)],
                           "scale_anim_px_per_source_px": meta["scale_px"], "alpha_bbox_gt128": list(bb) if bb else None,
                           "size": list(img.size), "path": (str(target.relative_to(root)) if target.is_relative_to(root) else str(target)).replace("\\", "/"),
                           "sha256": sha256(target.read_bytes())})
    return {"canvas": list(canvas), "pivot": list(pivot), "home_root_texels": [home_root[0], home_root[1]],
            "home_texels_per_anim_pixel": V03_TEXELS_PER_PIXEL, "margin_px": V03_MARGIN, "round_to": V03_ROUND,
            "resampler": V03_RESAMPLER, "alpha_floor": V03_ALPHA_FLOOR, "fps": V03_FPS,
            "union_rel_pivot_px": [round(v, 3) for v in layout["union_rel_pivot_px"]],
            "family_scales": {f: v["scale_home_texels_per_source_px"] for f, v in scales["families"].items()},
            "scale_report": scales, "frames": frames}


def v03_write_evidence(root: Path, built: dict[str, Any], rerun: dict[str, Any]) -> None:
    ev = root / V03_EVIDENCE
    ev.mkdir(parents=True, exist_ok=True)
    (ev / "normalization_measurements.json").write_text(json.dumps(built, indent=2) + "\n", encoding="utf-8")
    sr = built["scale_report"]
    hid = sr["home"]
    D = built["home_texels_per_anim_pixel"]
    L = ["# M42-C003 V03 family scale report", "",
         f"HOME-026 identity: visor {hid['visor_width']}x{hid['visor_height']} px (largest connected near-black component in the upper 60%), character height {hid['character_height']} px, yaw {hid['yaw_deg']} deg.", "",
         "Scale = HOME texels per source pixel, one uniform value per source family. Basis: median over comparable upright front frames (|yaw| <= 15 deg, height >= 93% of the family max) of sqrt(visor-width ratio x height ratio). Visor width and character height are spec V03 section 5 identity features (priorities 1 and 3); the geometric mean balances them when a family's proportions differ from HOME-026. The V02 dark-envelope 'visor' metric (723 px on HOME, which also counted dark body pixels) is replaced.", "",
         "| Source family | Scale | Comparable frames | Visor width vs HOME at scale | Height vs HOME at scale | Stored anim px per source px |", "|---|---:|---|---|---|---:|"]
    for fam, v in sr["families"].items():
        L.append(f"| {fam} | {v['scale_home_texels_per_source_px']:.4f} | {v['comparable_frames']} | {', '.join(f'{x:.1%}' for x in v['visor_width_vs_home_at_scale'])} | {', '.join(f'{x:.1%}' for x in v['height_vs_home_at_scale'])} | {v['scale_home_texels_per_source_px'] / D:.4f} |")
    L += ["", f"Every stored scale is >= 1 animation pixel per source pixel, so storing at {D} HOME texels per animation pixel keeps all source detail.", "",
          "## Per-frame identity measurements (source pixels)", "", "| Family | Frame | Visor w | Visor h | Height | Yaw deg |", "|---|---:|---:|---:|---:|---:|"]
    for fam, v in sr["families"].items():
        L += [f"| {fam} | {r['frame']:02d} | {r['visor_width']} | {r['visor_height']} | {r['character_height']} | {r['yaw_deg']} |" for r in v["frames"]]
    (ev / "family_scale_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    c, p = built["canvas"], built["pivot"]
    C = ["# M42-C003 V03 common animation canvas + pivot", "",
         f"- Canvas: **{c[0]}x{c[1]}** RGBA8 animation pixels for all 63 frames (= {c[0] * D}x{c[1] * D} HOME texels).",
         f"- Common pivot (planted rubber-sole midpoint): **({p[0]}, {p[1]})** animation px.",
         f"- Storage density: {D} HOME-026 texels per animation pixel; runtime size = canvas x {D} x k (k = screen px per HOME texel of the accepted M42-C002 layout).",
         f"- HOME-026 sole root (same detector): ({built['home_root_texels'][0]}, {built['home_root_texels'][1]}) HOME texels; runtime maps the animation pivot onto that HOME screen point.",
         f"- Union of the 63 registered frames relative to the pivot (anim px): {built['union_rel_pivot_px']}; margin {built['margin_px']} px each side; dimensions rounded up to a multiple of {built['round_to']}.",
         f"- Resampler: {built['resampler']}; alpha <= {built['alpha_floor']} removed before and after.",
         "- Texture memory: 63 x {0}x{1} x 4 B = {2:.1f} MiB uncompressed (a 1:1 HOME-texel canvas would be {3:.0f} MiB).".format(c[0], c[1], 63 * c[0] * c[1] * 4 / 2**20, 63 * c[0] * c[1] * 4 * D * D / 2**20),
         "", "## Sequence mapping", ""]
    for g, (fam, seq) in V03_SEQUENCES.items():
        C.append(f"- {g} ({len(seq)}): {fam} frames {seq}")
    C += ["", "## Frames", "", "| Gesture | Frame | Source | Source root | Alpha>128 bbox | SHA-256 |", "|---|---:|---|---|---|---|"]
    C += [f"| {f['gesture']} | {f['frame']:02d} | {f['source_family']} {f['source_frame']:02d} | {f['source_root']} | {f['alpha_bbox_gt128']} | `{f['sha256']}` |" for f in built["frames"]]
    (ev / "canvas_pivot_report.md").write_text("\n".join(C) + "\n", encoding="utf-8")
    seqmap = {g: [{"production_frame": f"{g}_{i:02d}.png", "source_family": fam, "source_frame": n} for i, n in enumerate(seq, 1)] for g, (fam, seq) in V03_SEQUENCES.items()}
    (ev / "sequence_mapping.json").write_text(json.dumps(seqmap, indent=2) + "\n", encoding="utf-8")
    R = ["# M42-C003 V03 deterministic rerun", "", f"Second independent build into a scratch directory: {rerun['identical']}/{rerun['total']} frames byte-identical.", ""]
    R += [f"- {k}: `{v}`" for k, v in rerun["mismatches"].items()] or ["No mismatches."]
    (ev / "deterministic_rerun.md").write_text("\n".join(R) + "\n", encoding="utf-8")
    for g in V03_SEQUENCES:
        contact_sheet(root, g, [root / f["path"] for f in built["frames"] if f["gesture"] == g], ev / "contact_sheets" / f"{g}.png")


def v03_promote(root: Path, built: dict[str, Any], archive_sha: str) -> None:
    manifest_path = root / "assets/ui/HOME_ASSET_MANIFEST.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    gestures: dict[str, Any] = {}
    for f in built["frames"]:
        dst = root / FINAL_ROOT / f["gesture"] / f"{f['gesture']}_{f['frame']:02d}.png"
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes((root / f["path"]).read_bytes())
        if sha256(dst.read_bytes()) != f["sha256"]:
            raise ValueError(f"promotion copy mismatch: {dst}")
        gestures.setdefault(f["gesture"], {"frames": []})["frames"].append(
            {"path": str(dst.relative_to(root)).replace("\\", "/"), "sha256": f["sha256"],
             "source": f"{f['source_family']}_{f['source_frame']:02d}.png", "source_sha256": f["source_sha256"]})
    manifest.setdefault("animation_sets", {})["home_scrubby_gestures_v03"] = {
        "status": "APPROVED",
        "authority": "coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md + coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V03.md",
        "provenance": "owner archive Home_Main_Hero_Assets.zip (63 owner-approved source frames, no new art), normalized by tools/home_scrubby_prepare_assets.py --v03",
        "source_archive_sha256": archive_sha,
        "idle_texture": str(HOME).replace("\\", "/"),
        "idle_texture_sha256": sha256((root / HOME).read_bytes()),
        "canvas": built["canvas"],
        "pivot": built["pivot"],
        "home_root_texels": built["home_root_texels"],
        "home_texels_per_anim_pixel": built["home_texels_per_anim_pixel"],
        "fps": built["fps"],
        "resampler": built["resampler"],
        "family_scales": built["family_scales"],
        "gestures": gestures,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def v03_main(root: Path, archive: Path, promote: bool) -> None:
    import tempfile
    report = verify_and_stage(archive, root, V03_EVIDENCE)
    built = v03_build(root, root / V03_CANDIDATES)
    with tempfile.TemporaryDirectory() as tmp:
        again = v03_build(root, Path(tmp))
    a = {(f["gesture"], f["frame"]): f["sha256"] for f in built["frames"]}
    b = {(f["gesture"], f["frame"]): f["sha256"] for f in again["frames"]}
    mism = {f"{k[0]}_{k[1]:02d}": f"{a[k]} != {b.get(k)}" for k in a if a[k] != b.get(k)}
    rerun = {"identical": len(a) - len(mism), "total": len(a), "mismatches": mism}
    if mism or len(a) != 63 or again["canvas"] != built["canvas"] or again["pivot"] != built["pivot"]:
        raise ValueError(f"V03 determinism failed: {rerun}")
    v03_write_evidence(root, built, rerun)
    print(f"V03_CANVAS={built['canvas'][0]}x{built['canvas'][1]} PIVOT={built['pivot']}")
    for fam, sc in built["family_scales"].items():
        print(f"V03_FAMILY_SCALE {fam}={sc:.6f}")
    print(f"V03_DETERMINISTIC={rerun['identical']}/{rerun['total']}")
    if promote:
        v03_promote(root, built, report["archive_sha256"])
        print("V03_PROMOTED=63")


def v03_animations(root: Path, frames_dir: Path) -> None:
    """Assemble the evidence tool's 24 fps runtime frame captures into animated WebP."""
    out = root / V03_EVIDENCE / "runtime_captures"
    out.mkdir(parents=True, exist_ok=True)
    for g in V03_SEQUENCES:
        paths = sorted((frames_dir / g).glob("*.png"))
        frames = []
        for p in paths:
            im = Image.open(p).convert("RGB")
            frames.append(im.resize((im.width // 2, im.height // 2), Image.Resampling.LANCZOS))
        frames[0].save(out / f"{g}_runtime_24fps.webp", save_all=True, append_images=frames[1:], duration=round(1000 / 24), loop=0, quality=88, method=6)
        print(f"V03_ANIMATION {g} frames={len(frames)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--normalize", action="store_true")
    parser.add_argument("--v03", action="store_true", help="V03 common-canvas normalization + evidence")
    parser.add_argument("--promote", action="store_true", help="with --v03: copy to final/ and pin in the HOME manifest")
    parser.add_argument("--v03-animate", type=Path, help="assemble runtime frame captures (evidence tool output) into WebP")
    args = parser.parse_args()
    root = args.root.resolve()
    if args.v03_animate:
        v03_animations(root, args.v03_animate.resolve())
        return 0
    if args.archive is None:
        parser.error("--archive is required unless --v03-animate is used")
    if args.v03:
        v03_main(root, args.archive.resolve(), args.promote)
        print("PREPARATION_RESULT=PASS")
        return 0
    report = verify_and_stage(args.archive.resolve(), root)
    print(f"SOURCE_ARCHIVE_SHA256={report['archive_sha256']}")
    print(f"SOURCE_FRAMES_VERIFIED={report['source_frames']}")
    if args.normalize:
        normalized = normalize(root, report)
        for name, scale in normalized["family_scales"].items():
            print(f"FAMILY_SCALE {name}={scale:.6f}")
        for family in ("wave", "bow", "turn", "full_turn"):
            frames = sorted((root / CANDIDATE_ROOT / family).glob("*.png"))
            contact_sheet(root, family, frames, root / "coordination/sessions/M42-C003/evidence_v02/contact_sheets" / f"{family}.png")
            transition_strip(root, family, frames, root / "coordination/sessions/M42-C003/evidence_v02/transition_strips" / f"{family}.png")
        write_measurement_summaries(root, normalized)
    print("PREPARATION_RESULT=PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # command-line diagnostics must be explicit
        print(f"PREPARATION_RESULT=FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
