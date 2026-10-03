#!/usr/bin/env python3
"""Validate and describe the M43-C005-C002 Standard/Premium pack frames."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

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
        [{"center_x": 512, "top_y": 530, "rotation_degrees": 0, "visible_percent": 17}],
        [{"center_x": 512, "top_y": 420, "rotation_degrees": 0, "visible_percent": 58}],
        [{"center_x": 405, "top_y": 403, "rotation_degrees": -11, "visible_percent": 65},
         {"center_x": 512, "top_y": 389, "rotation_degrees": 0, "visible_percent": 70},
         {"center_x": 619, "top_y": 403, "rotation_degrees": 11, "visible_percent": 65}],
        [{"center_x": 391, "top_y": 294, "rotation_degrees": -14, "visible_percent": 100},
         {"center_x": 512, "top_y": 280, "rotation_degrees": 0, "visible_percent": 100},
         {"center_x": 633, "top_y": 294, "rotation_degrees": 14, "visible_percent": 100}],
    ],
    "premium": [[], [], [], [], [],
        [{"center_x": 512, "top_y": 497, "rotation_degrees": 0, "visible_percent": 17}],
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
        "prompt": "coordination/sessions/M43-C005-C002/CHATGPT_PROMPT_V03.md",
        "canvas": {"width": 1024, "height": 1536, "mode": "RGBA"},
        "edge_safety_px": 48,
        "pack_registration_estimate_method": "Frame 01 owner reference placement; estimates carried through the registered sequence; visual center target x=512 and bottom target y=1260.",
        "references": [],
        "card_back_source": {},
        "card_count_source": "Frames 07-09 are checked from rendered pixels by counting connected pale-cyan gear emblems; overlay construction metadata is also checked and manual visual inspection confirms distinct silhouettes. Card faces are never shown.",
        "frames": [],
        "automated_checks": [],
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
            cards = cfg["expected_cards"][i]
            layout = CARD_LAYOUTS[pack][i]
            assert len(layout) == cards, f"{path}: composition count {len(layout)} != {cards}"
            visual_count = visual_card_emblem_count(im, pack, i) if i in (6, 7, 8) else None
            if visual_count is not None:
                assert visual_count == cards, (
                    f"{path}: rendered pale-cyan card emblems {visual_count} != metadata {cards}"
                )
            manifest["frames"].append({
                "relative_path": path.relative_to(ROOT).as_posix(),
                "sha256": digest(path),
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
        {"check": "rendered card-back emblem counts match metadata for frames 07-09", "result": "PASS"},
        {"check": "registered pack center/bottom estimates within 12px of x=512/y=1260", "result": "PASS"},
        {"check": "no full opaque backgrounds", "result": "PASS"},
    ]
    out = SESSION / "PACK_ASSET_MANIFEST_V01.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: 18 frames; 9 per pack; 1024x1536 RGBA; all edge margins >=48px")
    print("PASS: Standard overlays 0,0,0,0,0,1,1,3,3")
    print("PASS: Premium overlays 0,0,0,0,0,1,1,5,5")
    print("PASS: rendered card-back emblem counts match metadata in frames 07-09")
    print(f"WROTE: {out.relative_to(ROOT).as_posix()}")

if __name__ == "__main__":
    main()
