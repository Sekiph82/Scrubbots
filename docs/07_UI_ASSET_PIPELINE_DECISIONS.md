# 07 — UI & Visual Asset Pipeline Decisions

These owner-approved decisions supplement `docs/05_TECH_DECISIONS.md` and the canonical `docs/MASTER_UI_SYSTEM.md`.

## UI-ADR-001: Responsive 1:2 design baseline

**Decision**: Use 1080×2160 portrait as the primary reference viewport with Godot `canvas_items` stretch and `expand` aspect behavior.

**Reason**: SCRUBBOTS must make the gameplay board visually dominant on modern tall iPhone and Android screens instead of preserving a 16:9 letterboxed composition.

**Consequences**: Layout must be container/anchor driven, safe-area aware and tested at 1080×2160, 1170×2532, 1290×2796, 1080×2400 and 1440×3200. Gameplay logic remains resolution-independent.

**Status**: Owner-approved.

## UI-ADR-002: Native Godot UI plus generated decorative art

**Decision**: Production screens are composed from reusable Godot Controls. AI-generated full-screen mockups are visual references only. Generated art is restricted mainly to illustration-heavy elements such as characters, booster icons, rewards, difficulty emblems, decorative props and branded icon families.

**Reason**: Responsive UI must resize/reflow without regenerating images. Text, counters, panels, slots and progress states must remain dynamic.

**Consequences**: Use native Theme/StyleBox/PanelContainer/NinePatchRect/TextureRect/Button/container primitives. Do not ship a screenshot as the interactive UI.

**Status**: Owner-approved.

## UI-ADR-003: ChatGPT-primary image generation with Magnific fallback

**Decision**: ChatGPT image generation is the primary development-time image-generation workflow for SCRUBBOTS UI/character assets. Magnific MCP remains an approved fallback/alternate provider. Higgsfield is not a project dependency.

**Reason**: The owner prefers to create and iterate production visuals directly in the ChatGPT design workflow while retaining Magnific as a viable alternate path.

**Consequences**: `ASSET_GENERATION_MANIFEST.json` uses `chatgpt_image_generation` as its primary provider and `magnific` as fallback. No shipping build may require either provider, API credentials or generation credits at runtime.

**Status**: Owner-approved 2026-09-18.

## UI-ADR-004: Owner Desktop reference intake

**Decision**: `C:\\Users\\sekip\\Desktop\\ScrubBots Gorselleri` is an owner-confirmed SCRUBBOTS visual-reference source. Files are copied, never moved, into `assets/art/references/_owner_inbox/` through the repository intake helper.

**Reason**: Prior visual work must guide production art direction and should not remain invisible to development sessions.

**Consequences**: Desktop originals remain untouched. Inbox files are references until inventoried/classified and explicitly promoted. Generated derivatives never overwrite source references.

**Status**: Owner-approved.

## UI-ADR-005: Board-renderer preservation

**Decision**: Responsive UI work must keep the existing single-Image/ImageTexture `BoardRenderer` architecture. UI layout may size/position the renderer but may not replace it with one Node/Control per logical cell.

**Reason**: ADR-011 is already tested and performance-oriented.

**Consequences**: Board sizing is a presentation concern; board data/rendering architecture remains unchanged.

**Status**: Owner-approved.

## UI-ADR-006: Generated-asset lifecycle and Home inventory

**Decision**: Generated visual work has three separate layers: owner references, raw generated candidates and approved production assets. The canonical paths are `assets/art/references/`, `assets/ui/generated/` and `assets/ui/final/`. Home-screen asset requirements are tracked in `assets/ui/HOME_ASSET_MANIFEST.json`.

**Reason**: Raw candidates, approved art and immutable owner references must not become mixed or silently overwrite each other.

**Consequences**: Generated candidates are never production-final by default. Only approved assets are promoted to `assets/ui/final/`. Dynamic text, counters, timers and state remain native/live Godot UI and are not baked into images.

**Status**: Owner-approved 2026-09-18.

## UI-ADR-007: Booster texture import limit and memory budget

**Decision**: Every texture under `assets/ui/final/boosters/` (icons and `states/`) imports with `process/size_limit=512`, lossless (`compress/mode=0`), mipmaps off. The gameplay-screen booster set has a resident budget of **12 MiB** RGBA8 (measured 9.43 MiB at 512, down from 59.99 MiB at source size). Source PNGs stay untouched; only the `.import` settings change.

**Reason**: The largest booster draw is the 170 px acquisition popup icon (the gameplay row is ~100 px); x2 for hi-dpi gives 340 px, so 512 is the next power of two with headroom for the tablet row. The low-end target is a Galaxy A10 class phone (2 GB RAM, 720x1520). Lossy/VRAM compression is not used because the glow and ring alpha gradients would band.

**Consequences**: New booster art must import at max 512 px and keep the set under 12 MiB; `tests/m22_025_booster_texture_budget.gd` enforces both. The other final-art folders are covered by the per-screen budgets of UI-ADR-008.

**Status**: Factory job 034, 2026-10-22 (SB-M22-025 booster slice).

## UI-ADR-008: Per-screen texture budgets and safe size_limit rule

**Decision**: `tools/m22_026_texture_inventory.py` (stdlib) inventories all 560 PNGs under `assets/ui/final/**`: source size, alpha, resident RGBA8 MiB, `size_limit`, the largest literal draw size found next to every runtime use (`scripts/`, `data/`, `assets/ui/HOME_ASSET_MANIFEST.json`), the action below and the referencing files. `process/size_limit` is set in the `.import` only when the art is referenced, its draw side is known and below 540 px, the source max side is at least 4x the draw side (2x hi-dpi at 1080x2400, 2x tablet headroom), and the cap (next power of two >= 4x draw, never below 256) is smaller than the source. Everything else stays at source size. Lossless (`compress/mode=0`) and mipmaps off stay everywhere. Source PNGs are untouched. `tests/m22_026_texture_budget.gd` enforces the per-screen budgets and the caps.

Files capped in this step:

| file | source | draw side | size_limit | MiB before -> after |
|---|---|---:|---:|---|
| `common/icons/icon_clock.png` | 1254x1254 | 52 (refill popup timer pill) | 256 | 6.00 -> 0.25 |
| `daily/daily_streak_flame.png` | 1536x1024 | 52 (daily streak row) | 256 | 6.00 -> 0.17 |
| `daily/daily_task_check.png` | 1261x1247 | 34 (task check) | 256 | 6.00 -> 0.25 |
| `daily/daily_login_calendar.png` | 1288x1221 | 240 (login popup hero; 132 inline) | 1024 | 6.00 -> 3.79 |
| `popups/failure/heart_large.png` | 1320x1192 | 210 (out-of-lives heart) | 1024 | 6.00 -> 3.61 |

Resident RGBA8 per folder (only the changed folders differ; the boosters were already capped by UI-ADR-007):

| folder | before MiB | after MiB |
|---|---:|---:|
| common | 294.0 | 288.2 |
| daily | 36.0 | 22.2 |
| popups | 210.0 | 207.6 |
| **all 560 PNGs** | 2897.1 (2947.7 at source size) | 2875.2 |

Per-screen resident RGBA8 (the textures each screen loads; a shared texture counts on every screen that loads it) and budgets (measured plus ~10%):

| screen | textures | before MiB | after MiB | budget MiB |
|---|---:|---:|---:|---:|
| Home (25 STATIC presentation entries + 63 Scrubby gesture frames) | 88 | 207.07 | 207.07 | 228 |
| Gameplay (5-col shell, portrait, boosters + states, rail, Scrubbot body, clean FX) | 17 | 50.72 | 50.72 | 56 |
| Results (won/failed hero + emblem, reward icons) | 11 | 65.99 | 65.99 | 73 |
| Shop/Collection (shop and collection header/icon art; catalog card art excluded) | 15 | 69.99 | 69.99 | 77 |

**The reduction is not meaningful.** This step saves 21.9 MiB (0.76% of the library) and leaves all four screen totals unchanged, because none of the five capped files is loaded by those screens (they belong to the Daily and refill popups). The safety rule was not loosened to get a bigger number. Most art has no draw size the inventory can prove from a literal, so it stays at source size.

Untouched files (per-file path and reason: run the inventory, column `action`):
- 181 with no literal runtime reference: unused art, or paths built at runtime (for example the gameplay shells `gameplay_v02_shell_*`).
- 353 with an unknown draw size: all Home art, backgrounds, hero and robot poses, logos, and the collection card art (paths in `data/config/collection_card_catalog_v1.json`).
- 7 drawn at >= 540 px: `common/frames/popup_{large,medium,reward,small,warning}_frame.png`, `popups/failure/fail_header_emblem.png`, `popups/victory/victory_emblem.png`.
- 2 whose source is under 4x the 396 px draw side: `robots/robot_lock_emblem.png`, `robots/robot_unlocked_burst.png`.
- 2 whose 2048 cap would not be below the source: `daily/daily_day5_reward_frame.png`, `rewards/chest_small.png`.
- The 10 boosters stay as UI-ADR-007 set them.

The 7 PNGs without alpha stay lossless and unchanged (none is a size_limit candidate): `gameplay/master/scrubbots_gameplay_master.png`, `gameplay/profile/bot_parts_bar_frame.png`, `home/background/home_background.png`, `home/background/home_bg_sky.png`, `marketing/store_background.png`, `system/placeholders/content_loading_placeholder.png`, `system/placeholders/level_preview_placeholder.png`.

**Reason**: The low-end target is a Galaxy A10 class phone (2 GB RAM, 720x1520). Only caps that provably keep 4x the drawn resolution are safe without a visual review. Art with an unknown draw size must keep the resolution the 1080x2400 layout may need.

**Consequences**: New art that one of these screens loads must keep that screen under its budget, and a screen that grows needs a new measured budget here. Home alone is about 207 MiB resident, so real savings need the follow-ups.

**Follow-ups (not done)**: runtime draw-size measurement so Home, Results and Shop art can be capped; VRAM compression (ETC2/ASTC) for opaque backgrounds and large art; atlasing small icons; runtime lazy loading and unloading (collection card art stays cached once viewed, up to 135 x 6 MiB).

**Status**: Factory job 037, 2026-10-23 (SB-M22-026 step 1).

### UI-ADR-008 step 2: measured size_limit caps

**Decision**: `tests/tools/m22_026_texture_measure.gd` boots the real `main.tscn` in a SubViewport (throw-away `user://` saves via `boot_save_path_override`, never the real save) at 1080x2400 and at the 1536x2048 tablet, using the `m49` logical size (physical px = logical rect x physical/logical). Scenarios: Home (all 4 Scrubby gestures stepped frame by frame), Gameplay 5-slot, Gameplay 6-slot (+1 Slot via `activate_plus_one_slot`), Results won and failed, Shop, Collection (album, set details 1-3, card detail of every owned card and one not found, Cards Exchange), plus Robots and the Heart (life) popup because they draw robot poses and heart art seen on the other screens. It walks the whole SubViewport subtree and records, per `res://assets/ui/final/` texture (AtlasTexture counted as its atlas file) on a `TextureRect`, `NinePatchRect`, `TextureButton` or `Sprite2D`, the largest on-screen side in physical px. `tools/m22_026_apply_caps.py` (stdlib) applies `size_limit = next_pow2(max(2 x measured max side, 512))`, written only when it is below the source max side and the `.import` has no limit yet. Only the `process/size_limit` line changes; `compress/mode=0`, mipmaps off and the source PNGs stay as they are.

Result: 144 textures observed (141 with a non-zero size), **45 capped** (37 to 512, 8 to 1024). The smallest limit / measured side ratio among them is 2.06 (`home/shortcuts/icon_shortcut_collection.png`, 248 px -> 512). Re-measuring after the re-import gives the same rects (one emblem 1 px smaller from rounding), so no layout depends on the texture size.

Per-screen resident RGBA8 (`tests/m22_026_texture_budget.gd`; a shared texture counts on every screen that loads it):

| screen | step 1 list: before -> after MiB | step 2 list | step 2 list: before -> after MiB | new budget MiB |
|---|---|---|---|---:|
| Home | 207.07 -> 106.02 | 88 textures (unchanged) | 207.07 -> 106.02 | 117 |
| Gameplay | 50.72 -> 50.72 | 19 (+2: `gameplay_v02_shell_5slot_3col`, `gameplay_v02_shell_6slot_3col`, the shells drawn at runtime) | 62.72 -> 62.72 | 69 |
| Results | 65.99 -> 28.41 | 11 (unchanged) | 65.99 -> 28.41 | 32 |
| Shop/Collection | 69.99 -> 20.70 | 19 (+4: `popup_large_frame`, `popup_reward_frame`, `popups/victory/reward_glow`, `robots/bot_parts_icon`) | 94.00 -> 36.98 | 41 |

Gameplay does not drop: its observed art is either already capped (boosters, UI-ADR-007), smaller than the cap (the 256 px profile portrait) or larger on screen than the source (the shells, about 2160 px). The rail, Scrubbot body and clean FX are not drawn by a measured node, so they stay untouched. Gameplay 6-slot swaps the 5-slot shell for the 6-slot one (same 887x1774 size), so its MiB equal 5-slot. The tablet (1536x2048) loads the same textures as the phone, so its per-screen MiB are equal; it only changes measured sides, and the caps use the larger side of the two.

Whole-tree MiB the measure tool reports (every texture loaded in the SubViewport, including the Home screen that stays resident behind the other screens), before -> after: Home 231.07 -> 130.02, Gameplay 5-slot and 6-slot 188.70 -> 87.65, Results won 206.69 -> 93.38, Results failed 200.70 -> 94.65, Shop 201.97 -> 80.26, Collection 293.97 -> 166.87 (13 viewed card arts at 6 MiB each, not capped), Robots 233.96 -> 82.63, Heart popup 189.84 -> 88.79.

Untouched and why:
- 416 of the 560 PNGs were not observed in any scenario (art drawn by `_draw`/StyleBox code, other screens, unused art). They keep their current limit.
- 3 loaded with size 0 (`gameplay/tutorial/speech_bubble.png`, `tutorial_highlight_ring.png`, `tutorial_pointer.png`): treated as unobserved.
- 85 whose computed limit is not below the source: the 63 Home gesture frames (464x512 source, drawn at 965 px), `home/background/home_background.png`, `characters/scrubby/scrubby_home_pose.png`, `popups/help/help_scrubby_pose.png`, the three popup frames, both gameplay shells, `gameplay/profile/scrubby_portrait.png` and the 13 card arts seen in card detail (540 px, so 2048 > 1536 source).
- 11 already limited keep their value: the 9 observed boosters (512, UI-ADR-007), `common/icons/icon_clock.png` (256) and `popups/failure/heart_large.png` (1024, step 1; the 2x rule would give 512).

**Known limit**: the cap covers the sizes the scenarios show. A texture drawn larger on a screen the tool does not visit (for example a robot portrait in an unlock ceremony) would show at less than 2x there. Add that screen to the tool and re-run the apply step before shipping art on it.

**Status**: Factory job 038, 2026-10-23 (SB-M22-026 step 2). Still open: VRAM compression, atlasing. Card art loading: done in step 3.

### UI-ADR-008 step 3: card art cap and per-visit card texture cache

**Decision**: all 135 collection card arts (`assets/ui/final/collection/cards/set_NN/card_NN.png`, paths from `data/config/collection_card_catalog_v1.json`, every one 1024x1536) import with `process/size_limit=1080`. Only that line changes; `compress/mode=0`, mipmaps off and the source PNGs stay as they are. The card layout is the same rect for every card, so the step 2 measurement of the 13 viewed cards (max side 540 px at 1080x2400, 512 px at 1536x2048; the card detail `CardArt` is the largest draw) applies to all 135.

Why 1080 and not a power of two: the step 2 rule `next_pow2(2 x 540)` gives 2048, above the 1536 source, so it caps nothing; 1024 would be 1.90x the drawn side, below the 2x rule. Godot accepts any integer limit, so the cap is exactly `2 x 540 = 1080`. A card imports at 720x1080 (2.97 MiB instead of 6.00 MiB).

`CollectionScreen` no longer keeps a static `_tex_cache` that held every viewed card art for the rest of the app run. The cache is now per visit: `open_album` stores a `Dictionary` as the album popup's `tex_cache` meta, `_tex(path, cache)` loads into it, and the album passes it to its thumbnails and to `open_set` (a standalone `open_set` gets a throw-away one). The modal stack frees the album when it closes, and the cache with it, so closing the Collection releases the card art. Repeat set-detail opens within one visit skip the decode. Memory within a visit is bounded by the cards viewed since the album opened: at most 135 x 2.97 MiB, only if every set is browsed.

Cost: with the per-visit cache, `tests/m43_master_c007_collection.gd` keeps its 150 ms warm-pass set-detail budget (it passes the album's cache to `open_set`); measured on the dev PC (headless): cold 223-312 ms (first card-art loads), warm 77-80 ms. A first open of a set in a new visit decodes its card arts again; that is a one-off cost on opening a popup, not per frame.

Before -> after resident RGBA8:
- all 135 cards viewed: 810.0 -> 400.45 MiB (with the old static cache they stayed resident for the app run; now only during the Collection visit).
- measure tool Collection scenario whole-tree (13 viewed card arts, album, set details 1-3, Cards Exchange): 166.87 -> 127.43 MiB at both 1080x2400 and 1536x2048. Re-measured card sides are unchanged (540 / 512 px), all other scenarios report the step 2 numbers.

`tests/m22_026_texture_budget.gd` checks every catalog card art imports at max side <= 1080 with alpha, the 135 together <= 440 MiB (400.45 + ~10%), `CollectionScreen` has no static `_tex_cache`, a card loaded through `_tex` stays while the visit cache holds it, and it leaves the ResourceLoader cache (`ResourceLoader.has_cached` false) once that cache and its `TextureRect` are freed.

**Status**: Factory job 040, 2026-10-23 (SB-M22-026 step 3). Still open: VRAM compression, atlasing.
