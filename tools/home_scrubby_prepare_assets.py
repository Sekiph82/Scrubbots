#!/usr/bin/env python3
"""Deterministically stage, validate, normalize, and report M42-C003 V02 art."""

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


def verify_and_stage(archive: Path, root: Path) -> dict[str, Any]:
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
    out = root / "coordination/sessions/M42-C003/evidence_v02/source_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (root / "coordination/sessions/M42-C003/evidence_v02/source_mapping.json").write_text(json.dumps(mapping, indent=2) + "\n", encoding="utf-8")
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--normalize", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
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
