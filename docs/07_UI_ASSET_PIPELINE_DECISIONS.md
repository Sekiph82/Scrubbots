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
