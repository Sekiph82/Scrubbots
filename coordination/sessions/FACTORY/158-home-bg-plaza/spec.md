# 158-home-bg-plaza (SB-HOME-BG-2026-11-16)

Owner 2026-11-16 (chat): use the new calm plaza image (blue sky, clouds, trees, pink tile floor) as the
Home background, because the current backgrounds distract. Show "WHISPERING PARK / AREA 1" as native
text instead of baked into the art. (The gameplay screen follows later as a separate job; not here.)

Owner image: factory/jobs/158-home-bg-plaza/owner_home_background_plaza.png (941x1672 RGB, owner-approved
by this instruction).

## Acceptance
1. New file `assets/ui/final/home/background/home_background_plaza.png` (byte-copy of the owner image).
   The old `home_background.png` stays byte-identical in the repo, retired (not loaded by Home).
2. HOME_ASSET_MANIFEST.json: new APPROVED entry (owner 2026-11-16, sha256, 941x1672) bound to the Home
   WorldBackground; old HOME-121 entry retired the same way HOME-120 was. `data/config/home_worlds_v1.json`
   world_01 points at the new slug with canvas 941x1672; drop or update baked_title / baked_sign_rect;
   keep Scrubby's feet on the tile floor.
3. The SB-POLISH-009 Scrubby still/video set has the OLD background baked into every frame, so it must
   no longer cover the new background. Home falls back to the non-video Scrubby (existing animation
   frames / pose). Scrubby still visible and standing on the floor.
4. Native area label: existing keys HOME_AREA_TITLE + HOME_AREA_NUMBER (TR "FISILTILI PARK" / "BÖLGE %d"),
   area number from the current world. Native Label(s) in the sky area under the top HUD, centred,
   readable on the blue sky (outline/shadow, project fonts / HomeStyle), shrink-to-fit on narrow screens,
   does not overlap HUD, profile card, Scrubby, PLAY or the side shortcuts on the required viewport matrix.
5. Other users of the old Home background path (e.g. standard_pack_ceremony.gd HOME_BG) switch to the new file.
6. Tests that pin the old file/slug updated to the new truth (not deleted); exact PASS lines.
   Run the affected Home / asset-gate / texture-budget suites; CI list guards updated if counts change.
7. One local GPU capture of Home (EN and TR) at a phone viewport for the owner, saved in the job folder.
   Never boot main.tscn without a save override.

## Must not change
Gameplay, economy, other Home art/layout beyond what the label needs. No new image generation.
