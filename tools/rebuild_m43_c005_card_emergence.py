#!/usr/bin/env python3
"""Rebuild registered M43-C005 card emergence beats from one shared card back."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "assets/ui/candidates/m43_c005/pack_opening"
CARD = ROOT / "coordination/sessions/M43-C005-C002/references/collection_card_back_sprite.png"


def card_layer(sprite: Image.Image, center_x: int, top_y: int, degrees: int,
               canvas: tuple[int, int] = (1024, 1536)) -> Image.Image:
    card = sprite.resize((170, 266), Image.Resampling.LANCZOS)
    # Pillow's positive angle leans the top of a portrait card to screen-left.
    rotated = card.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)
    layer = Image.new("RGBA", canvas, (0, 0, 0, 0))
    left = round(center_x - rotated.width / 2)
    top = round(top_y + 133 - rotated.height / 2)
    layer.alpha_composite(rotated, (left, top))
    return layer


def reveal(base_path: Path, out_path: Path, cards: list[tuple[int, int, int]],
           cut_y: int | None) -> None:
    base = Image.open(base_path).convert("RGBA")
    sprite = Image.open(CARD).convert("RGBA")
    # Outer cards first, then inner cards, and the center card in front.
    ordered = sorted(cards, key=lambda item: abs(item[0] - 512), reverse=True)
    layers = [card_layer(sprite, x, top, angle) for x, top, angle in ordered]
    if cut_y is not None:
        # The card shapes continue below this opening line and are hidden by the
        # front lip, so no card's printed bottom edge is exposed in emergence frames.
        clip = Image.new("L", base.size, 0)
        ImageDraw.Draw(clip).rectangle((0, 0, base.width, cut_y), fill=255)
        for layer in layers:
            layer.putalpha(ImageChops.multiply(layer.getchannel("A"), clip))
    for layer in layers:
        base.alpha_composite(layer)
    base.save(out_path)


def main() -> None:
    standard = PACKS / "standard"
    premium = PACKS / "premium"
    # Start from the registered open-pack beat; it contains one narrow card edge
    # which each replacement card group covers at the exact same aperture.
    reveal(standard / "frame_06_card_edge.png", standard / "frame_07_one_card_rises.png",
           [(512, 420, 0)], 575)
    reveal(standard / "frame_06_card_edge.png", standard / "frame_08_cards_emerge.png",
           [(405, 403, -11), (512, 389, 0), (619, 403, 11)], 575)
    reveal(standard / "frame_06_card_edge.png", standard / "frame_09_final_reveal.png",
           [(391, 294, -14), (512, 280, 0), (633, 294, 14)], None)

    reveal(premium / "frame_06_card_edge.png", premium / "frame_07_one_card_rises.png",
           [(512, 390, 0)], 549)
    reveal(premium / "frame_06_card_edge.png", premium / "frame_08_cards_emerge.png",
           [(278, 365, -20), (395, 359, -10), (512, 353, 0),
            (629, 359, 10), (746, 365, 20)], 549)
    reveal(premium / "frame_06_card_edge.png", premium / "frame_09_final_reveal.png",
           [(278, 282, -24), (395, 276, -12), (512, 270, 0),
            (629, 276, 12), (746, 282, 24)], None)
    print("Rebuilt Standard 07-09 (1/3/3) and Premium 07-09 (1/5/5).")


if __name__ == "__main__":
    main()
