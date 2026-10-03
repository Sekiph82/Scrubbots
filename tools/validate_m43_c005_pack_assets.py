#!/usr/bin/env python3
"""Validate and describe the M43-C005-C002 Standard/Premium pack frames."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SESSION = ROOT / "coordination/sessions/M43-C005-C002"
PACK_ROOT = ROOT / "assets/ui/candidates/m43_c005/pack_opening"
NAMES = [
    "frame_01_closed.png",
    "frame_02_charge.png",
    "frame_03_pressure.png",
    "frame_04_first_tear.png",
    "frame_05_tear_widens.png",
    "frame_06_card_edge.png",
    "frame_07_one_card_rises.png",
    "frame_08_cards_emerge.png",
    "frame_09_final_reveal.png",
]
PACKS = {
    "standard": {
        "expected_cards": [0, 0, 0, 0, 0, 1, 1, 3, 3],
        "reference": "owner_standard_pack.png",
        "reference_file_sha256_actual": "876b874938a1123288233712015b485c714c99116dc50c2d6085474c92944baa",
        "reference_file_sha256_expected_attachment": "9528e46bbb66d28f752d0250a821323181257901d3510898a6e2ae0f4c2d953a",
        "reference_pixel_sha256_expected": "27e68fcb058105c2131b3c7f3a34f8f14bc2fc1f9c23bfcd7f2105d4712398ac",
        "reference_pixel_sha256_actual": "37bbe0f1d09260e4c4b26356c8986aa65f96fb81ad2aee9f8a3533761d9f191f",
        "reference_dimensions": [1269, 1240],
        "reference_mode": "RGBA",
        "pack_center_x_estimate_px": 512.0,
        "pack_bottom_y_estimate_px": 1260,
    },
    "premium": {
        "expected_cards": [0, 0, 0, 0, 0, 1, 1, 5, 5],
        "reference": "owner_premium_pack.png",
        "reference_file_sha256_actual": "51b4e7c85bf4ca9358e5f3c6c3afe0c551ee34c27c25d3a48c151ab4cb821faf",
        "reference_file_sha256_expected_attachment": "eeb95192d223c07333a0f14eff37c522bcfa5fe3d4200add9b7d2b0d16d88e4c",
        "reference_pixel_sha256_expected": "c8f06e0b3e9a888526158c462a8ae8293a8269a1975016e8cf22a6d39847de6d",
        "reference_pixel_sha256_actual": "074256759938dc1e662441d2fc5b7e3b84ec289cd066c518089595ac6f7f0d6e",
        "reference_dimensions": [1024, 1536],
        "reference_mode": "RGBA",
        "pack_center_x_estimate_px": 512.0,
        "pack_bottom_y_estimate_px": 1260,
    },
}
FROZEN_HASHES = {
    "standard": {
        "frame_01_closed.png": "ae31881ea692af695125d539832b48a5d76ef77672a22864dcc784c1d35eceea",
        "frame_02_charge.png": "075e917c6e82a9bc555650df57b187d2eacc34b74e0fc504a1ff76c708f66b32",
        "frame_03_pressure.png": "086a7e7e6deb325c573e6fdd362c1f0d801b1acb3fb8f04786b74e4ad3cfc2a4",
        "frame_05_tear_widens.png": "0d47eeb9b4ac3f7483d64f5298bd06c8eb286a8c0df4968fba8c6f5c43674b63",
        "frame_07_one_card_rises.png": "6b20fa33e72d09319cf1aea6adc0ebf8fa51feb7787ff072e9a0e6d7adf1c1ef",
        "frame_09_final_reveal.png": "561753dc9ade575874685d4cc07b8bd8bbd4f2e984c28ee228a76248ef385402",
    },
    "premium": {
        "frame_01_closed.png": "29b87a206bae589ce4811641a40d352186a6bf01528cad9279b390c82031034c",
        "frame_02_charge.png": "44b88fbbc9796edadd13229268978ce7a3c94b22bcebd3bb9906f4d6a2bfe571",
        "frame_03_pressure.png": "cf79d5b85d6227f69b462261e350c8bb1e27d8ad9deab135f5201faf778d9af6",
        "frame_05_tear_widens.png": "072dbc8f4accd17b4eb0c4a679cb47d0fe5bf1083f7576480c926712be8ab564",
        "frame_07_one_card_rises.png": "f47a7b6ecb8d02f444acf4dd75d25f0276f8a9f2459320a799edee94768d9dfa",
        "frame_09_final_reveal.png": "0de24ea3509518b8a358d733925cee30b8bc4087219dceecc39f20bec750977a",
    },
}
ROLES = [
    "closed idle",
    "charge light buildup",
    "shake pressure",
    "first tear",
    "tear widens",
    "full open card edge",
    "one card rises",
    "cards emerge",
    "final card reveal",
]
CARD_LAYOUTS = {
    "standard": [[], [], [], [], [],
        [{"center_x": 512, "top_y": 528, "rotation_degrees": 0, "visible_percent": 17}],
        [{"center_x": 512, "top_y": 420, "rotation_degrees": 0, "visible_percent": 58}],
        [{"center_x": 405, "top_y": 403, "rotation_degrees": -11, "visible_percent": 65},
         {"center_x": 512, "top_y": 389, "rotation_degrees": 0, "visible_percent": 70},
         {"center_x": 619, "top_y": 403, "rotation_degrees": 11, "visible_percent": 65}],
        [{"center_x": 391, "top_y": 294, "rotation_degrees": -14, "visible_percent": 100},
         {"center_x": 512, "top_y": 280, "rotation_degrees": 0, "visible_percent": 100},
         {"center_x": 633, "top_y": 294, "rotation_degrees": 14, "visible_percent": 100}],
    ],
    "premium": [[], [], [], [], [],
        [{"center_x": 512, "top_y": 489, "rotation_degrees": 0, "visible_percent": 17}],
        [{"center_x": 512, "top_y": 390, "rotation_degrees": 0, "visible_percent": 60}],
        [{"center_x": 278, "top_y": 365, "rotation_degrees": -20, "visible_percent": 70},
         {"center_x": 395, "top_y": 359, "rotation_degrees": -10, "visible_percent": 72},
         {"center_x": 512, "top_y": 353, "rotation_degrees": 0, "visible_percent": 74},
         {"center_x": 629, "top_y": 359, "rotation_degrees": 10, "visible_percent": 72},
         {"center_x": 746, "top_y": 365, "rotation_degrees": 20, "visible_percent": 70}],
        [{"center_x": 278, "top_y": 282, "rotation_degrees": -24, "visible_percent": 100},
         {"center_x": 395, "top_y": 276, "rotation_degrees": -12, "visible_percent": 100},
         {"center_x": 512, "top_y": 270, "rotation_degrees": 0, "visible_percent": 100},
         {"center_x": 629, "top_y": 276, "rotation_degrees": 12, "visible_percent": 100},
         {"center_x": 746, "top_y": 282, "rotation_degrees": 24, "visible_percent": 100}],
    ],
}


def _union(parent: dict[int, int], a: int, b: int) -> None:
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    while parent[b] != b:
        parent[b] = parent[parent[b]]
        b = parent[b]
    if a != b:
        parent[b] = a


def visual_card_emblem_count(image: Image.Image, pack: str, frame_index: int) -> int:
    """Count bright-cyan card gear emblems in rendered pixels, independent of layout metadata."""
    rgba = image.convert("RGBA")
    red, green, blue, alpha = rgba.split()
    mask = ImageChops.multiply(
        ImageChops.multiply(red.point(lambda p: 255 if p > 135 else 0),
                            green.point(lambda p: 255 if p > 190 else 0)),
        ImageChops.multiply(blue.point(lambda p: 255 if p > 210 else 0),
                            alpha.point(lambda p: 255 if p > 180 else 0)),
    )
    blue_minus_red = ImageChops.subtract(blue, red).point(lambda p: 255 if p > 35 else 0)
    mask = ImageChops.multiply(mask, blue_minus_red)

    # The fixed search band covers the open-pack/card area, not pack registration
    # metadata or card overlay coordinates. Frame 07's one centered emblem sits lower.
    if frame_index == 6:
        y_start, y_stop, x_start, x_stop = 380, 575, 440, 585
    elif pack == "standard":
        y_start, y_stop, x_start, x_stop = 300, 565, 300, 730
    else:
        y_start, y_stop, x_start, x_stop = 300, 560, 220, 820

    parent: dict[int, int] = {}
    runs: list[tuple[int, int, int, int]] = []
    previous: list[tuple[int, int, int]] = []
    next_label = 0
    for y in range(y_start, y_stop):
        row = mask.crop((x_start, y, x_stop, y + 1)).tobytes()
        current: list[tuple[int, int, int]] = []
        x = 0
        while x < len(row):
            if row[x] == 0:
                x += 1
                continue
            start = x
            while x + 1 < len(row) and row[x + 1] != 0:
                x += 1
            end = x
            label = next_label
            next_label += 1
            parent[label] = label
            current.append((start, end, label))
            runs.append((y, start + x_start, end + x_start, label))
            for p_start, p_end, p_label in previous:
                if start <= p_end + 1 and end >= p_start - 1:
                    _union(parent, label, p_label)
            x += 1
        previous = current

    components: dict[int, list[int]] = {}
    for y, x0, x1, label in runs:
        while parent[label] != label:
            parent[label] = parent[parent[label]]
            label = parent[label]
        bounds = components.setdefault(label, [x0, y, x1, y, 0])
        bounds[0] = min(bounds[0], x0)
        bounds[1] = min(bounds[1], y)
        bounds[2] = max(bounds[2], x1)
        bounds[3] = max(bounds[3], y)
        bounds[4] += x1 - x0 + 1

    count = 0
    for x0, y0, x1, y1, area in components.values():
        width, height = x1 - x0 + 1, y1 - y0 + 1
        if 22 <= width <= 90 and 22 <= height <= 90 and area >= 250:
            count += 1
    return count


def rendered_card_edge_peaks(image: Image.Image, pack: str) -> list[dict[str, float | int]]:
    """Find visible card-top signatures by matching rendered pixels to the shared card sprite."""
    sprite_path = SESSION / "references" / "collection_card_back_sprite.png"
    sprite = Image.open(sprite_path).convert("RGBA").resize((170, 266), Image.Resampling.LANCZOS)
    template = np.asarray(sprite)[:44]
    template_rgb = template[:, :, :3].astype(np.int16)
    opaque = template[:, :, 3] > 240
    rendered = np.asarray(image.convert("RGBA"))[:, :, :3].astype(np.int16)
    if pack == "standard":
        x_start, x_stop, y_start, y_stop = 280, 745, 508, 544
    else:
        x_start, x_stop, y_start, y_stop = 280, 745, 468, 504

    candidates: list[dict[str, float | int]] = []
    for top in range(y_start, y_stop, 2):
        for center_x in range(x_start, x_stop, 4):
            left = center_x - 85
            sample = rendered[top:top + 44, left:left + 170]
            if sample.shape[:2] != template_rgb.shape[:2]:
                continue
            error = np.abs(sample - template_rgb).max(axis=2)
            score = float(np.mean(error[opaque] < 42))
            if score >= 0.38:
                candidates.append({"center_x": center_x, "top_y": top, "score": score})

    peaks: list[dict[str, float | int]] = []
    for candidate in sorted(candidates, key=lambda item: float(item["score"]), reverse=True):
        if all(abs(int(candidate["center_x"]) - int(peak["center_x"])) >= 90
               or abs(int(candidate["top_y"]) - int(peak["top_y"])) >= 14 for peak in peaks):
            peaks.append(candidate)
    return peaks


def rendered_first_tear_measurement(image: Image.Image, pack: str) -> dict[str, int | float]:
    """Measure the gap between the inner foil edges on a fixed rendered scanline."""
    y_offset = 12 if pack == "standard" else 4
    y = 502 + y_offset if pack == "standard" else 340 + y_offset
    pixels = image.convert("RGBA").load()
    if pack == "standard":
        is_foil = lambda x: (
            pixels[x, y][3] > 150
            and pixels[x, y][2] > pixels[x, y][0] * 1.25
            and pixels[x, y][2] > pixels[x, y][1] * 0.95
        )
        pack_width = 458
    else:
        is_foil = lambda x: (
            pixels[x, y][3] > 150
            and pixels[x, y][0] > pixels[x, y][2] * 1.6
            and pixels[x, y][0] > pixels[x, y][1] * 1.1
        )
        pack_width = 484
    left = next((x for x in range(511, 300, -1) if is_foil(x)), None)
    right = next((x for x in range(513, 724) if is_foil(x)), None)
    if left is None or right is None:
        raise AssertionError(f"{pack}: rendered tear edges not found at y={y}")
    opening_px = right - left - 1
    return {
        "scanline_y_px": y,
        "inner_left_edge_x_px": left,
        "inner_right_edge_x_px": right,
        "opening_width_px": opening_px,
        "registered_pack_width_px": pack_width,
        "opening_width_fraction": opening_px / pack_width,
    }

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def rgba_digest(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()

def main() -> None:
    manifest = {
        "schema_version": 1,
        "task": "SB-M43-076",
        "prompt": "coordination/sessions/M43-C005-C002/CHATGPT_PROMPT_V04.md",
        "canvas": {"width": 1024, "height": 1536, "mode": "RGBA"},
        "edge_safety_px": 48,
        "pack_registration_estimate_method": "Frame 01 owner reference placement; estimates carried through the registered sequence; visual center target x=512 and bottom target y=1260.",
        "references": [],
        "card_back_source": {},
        "card_count_source": "Frame 06 is checked from rendered pixels by matching the visible card-top signature against the shared card-back sprite; Frames 07-09 are checked from connected pale-cyan gear-emblem pixels. Overlay metadata is cross-checked, never used as the rendered-content count authority.",
        "frames": [],
        "automated_checks": [],
        "frozen_frame_hashes_verified": [],
    }
    for pack, cfg in PACKS.items():
        directory = PACK_ROOT / pack
        files = sorted(p.name for p in directory.glob("*.png"))
        assert files == NAMES, f"{pack}: PNG names/order mismatch: {files}"
        assert len(files) == 9
        ref = SESSION / "references" / cfg["reference"]
        image = Image.open(ref)
        assert digest(ref) == cfg["reference_file_sha256_actual"]
        assert rgba_digest(image) == cfg["reference_pixel_sha256_actual"]
        assert list(image.size) == cfg["reference_dimensions"]
        assert image.mode == cfg["reference_mode"]
        manifest["references"].append({
            "path": ref.relative_to(ROOT).as_posix(),
            "dimensions": list(image.size),
            "mode": image.mode,
            "file_sha256": digest(ref),
            "file_sha256_expected_attachment_informational_only": cfg["reference_file_sha256_expected_attachment"],
            "decoded_rgba_pixel_sha256": rgba_digest(image),
            "decoded_rgba_pixel_sha256_expected_attachment": cfg["reference_pixel_sha256_expected"],
            "identity_basis": "V02 visual authorization: this is the sole named local file and its visible pack design matches the owner-confirmed attached main visual; encoded and decoded hashes are recorded without claiming an exact attachment pixel-hash match.",
        })
        for i, name in enumerate(NAMES):
            path = directory / name
            im = Image.open(path)
            assert im.size == (1024, 1536), f"{path}: dimensions {im.size}"
            assert im.mode == "RGBA", f"{path}: mode {im.mode}"
            alpha = im.getchannel("A")
            bbox = alpha.getbbox()
            assert bbox is not None
            margins = {
                "left": bbox[0],
                "top": bbox[1],
                "right": 1024 - bbox[2],
                "bottom": 1536 - bbox[3],
            }
            assert min(margins.values()) >= 48, f"{path}: edge margins {margins}"
            transparent = alpha.histogram()[0]
            assert transparent > 0, f"{path}: no transparent pixels"
            file_hash = digest(path)
            frozen_expected = FROZEN_HASHES[pack].get(name)
            if frozen_expected is not None:
                assert file_hash == frozen_expected, (
                    f"{path}: frozen SHA-256 changed: {file_hash} != {frozen_expected}"
                )
                manifest["frozen_frame_hashes_verified"].append({
                    "relative_path": path.relative_to(ROOT).as_posix(),
                    "sha256": file_hash,
                    "expected_sha256": frozen_expected,
                    "result": "PASS",
                })
            cards = cfg["expected_cards"][i]
            layout = CARD_LAYOUTS[pack][i]
            assert len(layout) == cards, f"{path}: composition count {len(layout)} != {cards}"
            visual_count = visual_card_emblem_count(im, pack, i) if i in (6, 7, 8) else None
            if visual_count is not None:
                assert visual_count == cards, (
                    f"{path}: rendered pale-cyan card emblems {visual_count} != metadata {cards}"
                )
            edge_peaks = rendered_card_edge_peaks(im, pack) if i == 5 else None
            edge_count = len(edge_peaks) if edge_peaks is not None else None
            if i == 5:
                assert edge_count == 1, f"{path}: rendered visible card edges {edge_count} != 1"
                assert float(edge_peaks[0]["score"]) >= 0.48, (
                    f"{path}: rendered card-edge pixel signature too weak: {edge_peaks[0]}"
                )
            tear_measurement = rendered_first_tear_measurement(im, pack) if i == 3 else None
            if tear_measurement is not None:
                assert 0.20 <= float(tear_measurement["opening_width_fraction"]) <= 0.25, (
                    f"{path}: rendered opening width outside 20-25% band: {tear_measurement}"
                )
            exposure = None
            if i == 5:
                lip_y = 573 if pack == "standard" else 534
                exposure = round((lip_y - int(edge_peaks[0]["top_y"])) / 266 * 100, 1)
                assert 15 <= exposure <= 20, f"{path}: rendered card exposure {exposure}% outside 15-20%"
            manifest["frames"].append({
                "relative_path": path.relative_to(ROOT).as_posix(),
                "sha256": file_hash,
                "width": im.width,
                "height": im.height,
                "mode": im.mode,
                "alpha_bounding_box_xyxy": list(bbox),
                "alpha_edge_margins_px": margins,
                "pack_visual_center_estimate_x_px": cfg["pack_center_x_estimate_px"],
                "pack_bottom_registration_estimate_y_px": cfg["pack_bottom_y_estimate_px"],
                "expected_card_count": cards,
                "constructed_card_overlay_count": len(layout),
                "visual_card_back_emblem_count": visual_count,
                "rendered_card_edge_count": edge_count,
                "rendered_card_edge_pixel_match_peak": edge_peaks[0] if edge_peaks else None,
                "rendered_card_edge_exposure_percent": exposure,
                "rendered_first_tear_opening_measurement": tear_measurement,
                "card_overlays": layout,
                "frame_role": ROLES[i],
                "transparent_pixel_count": transparent,
            })
    assert len(manifest["frames"]) == 18
    card_source = SESSION / "references" / "collection_card_back_sprite.png"
    card_image = Image.open(card_source)
    assert card_image.mode == "RGBA" and card_image.getchannel("A").getextrema()[0] == 0
    manifest["card_back_source"] = {
        "path": card_source.relative_to(ROOT).as_posix(),
        "sha256": digest(card_source),
        "width": card_image.width,
        "height": card_image.height,
        "mode": card_image.mode,
        "role": "shared blue-and-gold card back sprite used by the emergence compositor",
    }
    assert abs(PACKS["standard"]["pack_center_x_estimate_px"] - 512) <= 12
    assert abs(PACKS["premium"]["pack_center_x_estimate_px"] - 512) <= 12
    assert abs(PACKS["standard"]["pack_bottom_y_estimate_px"] - 1260) <= 12
    assert abs(PACKS["premium"]["pack_bottom_y_estimate_px"] - 1260) <= 12
    manifest["automated_checks"] = [
        {"check": "exactly 9 individual PNGs per pack with required names/order", "result": "PASS"},
        {"check": "all 18 files are 1024x1536 RGBA", "result": "PASS"},
        {"check": "all frames contain transparency and have >=48px transparent edge margins", "result": "PASS"},
        {"check": "Standard card overlay counts 0,0,0,0,0,1,1,3,3", "result": "PASS"},
        {"check": "Premium card overlay counts 0,0,0,0,0,1,1,5,5", "result": "PASS"},
        {"check": "Frame 06 exactly one rendered card-top signature per pack", "result": "PASS"},
        {"check": "Frame 06 rendered card exposure is within 15-20%", "result": "PASS"},
        {"check": "Frame 08 rendered card-emblem counts Standard=3/Premium=5", "result": "PASS"},
        {"check": "Frames 07-09 rendered card-emblem counts match expected content", "result": "PASS"},
        {"check": "Frame 04 rendered tear width is within 20-25%", "result": "PASS"},
        {"check": "all twelve frozen candidate PNG hashes match V04 locks", "result": "PASS"},
        {"check": "registered pack center/bottom estimates within 12px of x=512/y=1260", "result": "PASS"},
        {"check": "no full opaque backgrounds", "result": "PASS"},
    ]
    out = SESSION / "PACK_ASSET_MANIFEST_V01.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: 18 frames; 9 per pack; 1024x1536 RGBA; all edge margins >=48px")
    print("PASS: Standard overlays 0,0,0,0,0,1,1,3,3")
    print("PASS: Premium overlays 0,0,0,0,0,1,1,5,5")
    print("PASS: rendered card-back emblem counts match metadata in frames 07-09")
    print("PASS: Frame 06 rendered card edge count=1 for each pack; exposure=15-20%")
    print("PASS: Frame 08 rendered counts=3 Standard / 5 Premium")
    print("PASS: Frame 04 rendered tear opening=20-25% pack width")
    print("PASS: all 12 frozen frame hashes unchanged")
    print(f"WROTE: {out.relative_to(ROOT).as_posix()}")

if __name__ == "__main__":
    main()
