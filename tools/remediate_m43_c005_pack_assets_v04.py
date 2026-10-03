#!/usr/bin/env python3
"""Compose the six scoped V04 M43-C005 pack-frame corrections.

The approved pack frames remain the base artwork. Built-in imagegen supplied
localized transparent foil overlays; the shared transparent card-back sprite
supplies every card. Cards are alpha-occluded by the rendered irregular lip
overlay, then that foil lip is composited in front.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "assets/ui/candidates/m43_c005/pack_opening"
REFS = ROOT / "coordination/sessions/M43-C005-C002/references"
CARD = REFS / "collection_card_back_sprite.png"
SIZE = (1024, 1536)

CFG = {
    "standard": {
        "seal_width": 458, "seal_strip_width": 520, "seal_top": 502,
        "aperture_y_offset": 9,
        "lip_width": 660, "lip_height": 60, "lip_center_y": 573,
        "card_top": 528,
        "emergence": [(405, 403, -11), (512, 389, 0), (619, 403, 11)],
    },
    "premium": {
        "seal_width": 484, "seal_strip_width": 520, "seal_top": 340,
        "aperture_y_offset": 4,
        "lip_width": 660, "lip_height": 60, "lip_center_y": 534,
        "card_top": 489,
        "emergence": [(278, 365, -20), (395, 359, -10), (512, 353, 0),
                       (629, 359, 10), (746, 365, 20)],
    },
}


def visible_crop(image: Image.Image, threshold: int = 32) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda p: 255 if p > threshold else 0)
    box = alpha.getbbox()
    if box is None:
        raise ValueError("overlay is fully transparent")
    return rgba.crop(box)


def seal_overlay(pack: str) -> Image.Image:
    path = REFS / f"{pack}_first_tear_overlay_v04.png"
    seal = visible_crop(Image.open(path), 32)
    cfg = CFG[pack]
    # The isolated generated split is kept compact on Standard, leaving the
    # outer crimp visibly intact. Premium's source split is narrower, so its
    # strip is enlarged slightly to reach the same 20-25% rendered aperture.
    height = round(seal.height * cfg["seal_strip_width"] / seal.width)
    seal = seal.resize((cfg["seal_strip_width"], height), Image.Resampling.LANCZOS)
    if seal.width > cfg["seal_width"]:
        left = (seal.width - cfg["seal_width"]) // 2
        seal = seal.crop((left, 0, left + cfg["seal_width"], seal.height))
    return seal


def lip_overlay(pack: str) -> tuple[Image.Image, list[int]]:
    cfg = CFG[pack]
    lip = visible_crop(Image.open(REFS / f"{pack}_front_foil_lip_v04.png"), 32)
    lip = lip.resize((cfg["lip_width"], cfg["lip_height"]), Image.Resampling.LANCZOS)
    alpha = lip.getchannel("A")
    top_by_x: list[int] = []
    for x in range(lip.width):
        ys = [y for y in range(lip.height) if alpha.getpixel((x, y)) > 100]
        top_by_x.append(min(ys) if ys else lip.height)
    return lip, top_by_x


def place_lip(base: Image.Image, pack: str, lip: Image.Image, top_by_x: list[int]) -> tuple[Image.Image, int, int]:
    cfg = CFG[pack]
    left = (SIZE[0] - lip.width) // 2
    center_y = top_by_x[lip.width // 2]
    top = cfg["lip_center_y"] - center_y
    base.alpha_composite(lip, (left, top))
    return base, left, top


def card_layer(sprite: Image.Image, center_x: int, top_y: int, degrees: int) -> Image.Image:
    card = sprite.resize((170, 266), Image.Resampling.LANCZOS)
    rotated = card.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(rotated, (round(center_x - rotated.width / 2),
                                    round(top_y + 133 - rotated.height / 2)))
    return layer


def hide_under_irregular_lip(layer: Image.Image, lip_left: int, lip_top: int,
                             lip: Image.Image, top_by_x: list[int]) -> None:
    alpha = layer.getchannel("A")
    pix = alpha.load()
    for x in range(SIZE[0]):
        lx = x - lip_left
        edge_y = lip_top + top_by_x[lx] if 0 <= lx < lip.width else SIZE[1]
        for y in range(max(0, edge_y), SIZE[1]):
            pix[x, y] = 0
    layer.putalpha(alpha)


def remove_connected_black_backdrop(image: Image.Image) -> Image.Image:
    """Soften the flattened near-black backdrop while preserving enclosed art shadows."""
    rgba = image.convert("RGBA")
    rgb = rgba.convert("RGB")
    draw = ImageDraw.Draw(rgb)
    marker = (255, 0, 255)
    source_pixels = rgba.load()
    rgb_pixels = rgb.load()
    seeds = [(49, 200), (974, 200), (49, 800), (974, 800), (512, 1486), (512, 49)]
    for seed in seeds:
        r, g, b, alpha = source_pixels[seed]
        if alpha > 120 and max(r, g, b) < 40 and rgb_pixels[seed] != marker:
              ImageDraw.floodfill(rgb, seed, marker, thresh=88)
    marker_image = Image.new("RGB", rgba.size, marker)
    marker_mask = ImageChops.difference(rgb, marker_image).convert("L")
    marker_mask = marker_mask.point(lambda p: 255 if p == 0 else 0)
    bands = rgba.convert("RGB").split()
    brightness = ImageChops.lighter(ImageChops.lighter(bands[0], bands[1]), bands[2])
    # Feather dim connected glow into transparency instead of leaving a hard,
    # jagged silhouette where a binary floodfill meets the pack's light spill.
    feather = brightness.point(lambda p: round(0.30 * (
        max(0, min(1, (p - 6) / 52)) ** 2
        * (3 - 2 * max(0, min(1, (p - 6) / 52))) * 255
    )))
    original_alpha = rgba.getchannel("A")
    softened_alpha = ImageChops.multiply(original_alpha, feather)
    rgba.putalpha(Image.composite(softened_alpha, original_alpha, marker_mask))
    return rgba


def create_first_tear(pack: str) -> None:
    base = Image.open(PACKS / pack / "frame_01_closed.png").convert("RGBA")
    cfg = CFG[pack]
    overlay = seal_overlay(pack)
    left = (SIZE[0] - overlay.width) // 2
    base.alpha_composite(overlay, (left, cfg["seal_top"]))
    base.save(PACKS / pack / "frame_04_first_tear.png")


def create_card_frames(pack: str) -> None:
    cfg = CFG[pack]
    sprite = Image.open(CARD).convert("RGBA")
    lip, top_by_x = lip_overlay(pack)
    lip_left = (SIZE[0] - lip.width) // 2
    lip_top = cfg["lip_center_y"] - top_by_x[lip.width // 2]

    # The existing fully-open background already contains one partial center
    # edge. The replacement card aligns over it, preserving the accepted pack
    # opening art while exposing a single, shared card back.
    base06_path = PACKS / pack / "frame_06_card_edge.png"
    base06_source = Image.open(REFS / f"{pack}_frame_06_base_v04.png").convert("RGBA")
    base06 = base06_source.copy()
    one = card_layer(sprite, 512, cfg["card_top"], 0)
    hide_under_irregular_lip(one, lip_left, lip_top, lip, top_by_x)
    base06.alpha_composite(one)
    base06.alpha_composite(lip, (lip_left, lip_top))
    base06 = remove_connected_black_backdrop(base06)
    base06.save(base06_path)

    base08 = base06_source.copy()
    cards = cfg["emergence"]
    ordered = sorted(cards, key=lambda item: abs(item[0] - 512), reverse=True)
    layers = []
    for x, y, angle in ordered:
        layer = card_layer(sprite, x, y, angle)
        hide_under_irregular_lip(layer, lip_left, lip_top, lip, top_by_x)
        layers.append(layer)
    for layer in layers:
        base08.alpha_composite(layer)
    base08.alpha_composite(lip, (lip_left, lip_top))
    base08 = remove_connected_black_backdrop(base08)
    out = PACKS / pack / "frame_08_cards_emerge.png"
    base08.save(out)
    print(f"{pack}: lip center y={cfg['lip_center_y']}; Frame 06 visible exposure ~17%; Frame 08 cards={len(cards)}")


def rebuild_contact_sheet(pack: str) -> None:
    session = ROOT / "coordination/sessions/M43-C005-C002"
    tile_w, tile_h, gap, margin = 280, 420, 22, 24
    sheet = Image.new("RGBA", (2 * margin + 3 * tile_w + 2 * gap,
                                2 * margin + 3 * tile_h + 2 * gap),
                      (15, 23, 42, 255))
    for index in range(9):
        filename = sorted((PACKS / pack).glob("frame_*.png"))[index]
        art = Image.open(filename).convert("RGBA").resize((tile_w, tile_h), Image.Resampling.LANCZOS)
        x = margin + (index % 3) * (tile_w + gap)
        y = margin + (index // 3) * (tile_h + gap)
        sheet.alpha_composite(art, (x, y))
    suffix = "STANDARD" if pack == "standard" else "PREMIUM"
    sheet.save(session / f"{suffix}_CONTACT_SHEET_V03.png")


def main() -> None:
    for pack in ("standard", "premium"):
        create_first_tear(pack)
        create_card_frames(pack)
        rebuild_contact_sheet(pack)
    print("Composed only Standard/Premium frames 04, 06 and 08.")


if __name__ == "__main__":
    main()
