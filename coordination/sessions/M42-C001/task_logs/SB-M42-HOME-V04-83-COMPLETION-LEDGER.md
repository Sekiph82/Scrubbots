# SB-M42 HOME V04 — 83-POINT COMPLETION LEDGER

Source: `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md` (83 items)
Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-REBUILD_V04.md`
Implementer dispositions only — not an audit verdict; owner visual acceptance not claimed.

Rows: 83. Summary: **70 FIXED / 11 PRESERVED_CURRENT / 2 DEFERRED_BY_OWNER_ARCHITECTURE / 0 BLOCKED_WITH_PROOF**

| # | Owner item | Status | Evidence |
|---|---|---|---|
| 1 | Home is rebuilt around one complete world-background image per world, not separate city/portal/platform/helper composition layers. | FIXED | HomeScreen draws ONE WorldBackground (HOME-120) + Scrubby layer; tests/m42_home_v04.gd no_duplicate_world_art |
| 2 | World 01 uses the owner-approved `world_01_whispering_park_1080x2160.png`. | FIXED | HOME-120 promoted byte-identical (sha 8e04eda6…, 1080x2160); world_asset_identity |
| 3 | The World 01 background contains the city, sky, portal, platform, street, props and helper bots as one composition. | FIXED | single approved composition; old component art not drawn (no_duplicate_world_art) |
| 4 | The current sky proportion in the approved World 01 image is accepted and must not be reduced. | FIXED | world top-aligned (offset 0) at 1080x2160 and all taller phones; only the 16:9/tablet fits shift it up to keep the platform above PLAY (top sky then sits behind the HUD) — see log geometry table |
| 5 | `WHISPERING PARK` is baked into World 01 art. | FIXED | baked in HOME-120; no live title node (no_duplicate_world_art) |
| 6 | `AREA 1` is baked into World 01 art. | FIXED | baked in HOME-120; no live area-number node |
| 7 | Godot must not add a second live Whispering Park title over this image. | FIXED | AreaBanner/AreaTitle/AreaNumber removed; test asserts no WHISPERING/AREA label |
| 8 | Godot must not add a second portal/arch over this image. | FIXED | Art_arch/Art_arch_decor nodes removed; HOME-006/007 WORLD_BAKED_RETIRED |
| 9 | Godot must not add HOME-010 or HOME-011 platform art over this image. | FIXED | no Art_platform_* nodes; HOME-010 WORLD_BAKED_RETIRED, HOME-011 OWNER_RETIRED |
| 10 | Godot must not add separate helper-bot art over this image. | FIXED | no helper-bot nodes; HOME-022..024 WORLD_BAKED_RETIRED |
| 11 | Godot must not add the old HOME-001..004 layered sky/city/street art over this image. | FIXED | no Layer_background.* nodes; HOME-001..004 WORLD_BAKED_RETIRED |
| 12 | Godot must not add old environment-prop layers that are already represented in the baked world background. | FIXED | HOME-013..021 WORLD_BAKED_RETIRED, no nodes |
| 13 | Old approved component files/history remain preserved; they are retired from active World 01 Home presentation, not deleted. | FIXED | all 49 old approved PNG blobs unchanged (456 final PNG blobs, 0 mismatches); manifest history untouched |
| 14 | The world background fills the Home world canvas with aspect-correct scaling and no non-uniform stretch. | FIXED | uniform scale covering the canvas (matrix: world_stretched / world_not_covering_canvas never hit); on 3:4 tablet a mirrored continuation fills the narrow side bands |
| 15 | The approved 1080x2160 background is the canonical coordinate space for World 01 Home composition. | FIXED | data/config/home_worlds_v1.json canvas [1080,2160]; world_to_screen() maps canonical coords |
| 16 | Scrubby remains a separate runtime sprite/TextureRect above the baked world background. | FIXED | Layer_characters/Art_scrubby above WorldBackground (scrubby_anchor_contract) |
| 17 | Scrubby is centered on X=540 at canonical 1080x2160. | FIXED | visible-bbox centre X = 540.00 (scrubby_anchor_contract) |
| 18 | Scrubby feet anchor is canonical `(540, 1297)`. | FIXED | visible soles at 1297.00 canonical; on screen within 0.5 px of the mapped anchor at all 7 viewports |
| 19 | Scrubby recommended visual safe box is `x=353..727, y=779..1297`. | FIXED | visible bbox 353..727 x 863..1297 (+5 px brush bristles below the soles line) |
| 20 | Scrubby preserves aspect ratio inside that placement contract. | FIXED | Art_scrubby sized tex_size*k*s (uniform), STRETCH_SCALE on an aspect-exact rect |
| 21 | Scrubby's actual visible feet, not transparent texture padding, must sit on the baked platform. | FIXED | documented HOME-026 soles line y=1318 of 1358 (SCRUBBY_FEET_Y), not the texture bottom |
| 22 | Scrubby must not cover the baked world-name sign. | FIXED | visible rect vs baked_sign_rect: no intersection |
| 23 | Scrubby must not cover or visually erase the baked helper bots. | FIXED | visible rect vs 4 helper_bot_rects: no intersection |
| 24 | Profile card remains horizontally narrow; do not restore the oversized V02 width. | FIXED | ProfileCard 540 px at 1080 (50% width, clamp 460..620) |
| 25 | Profile Scrubby portrait remains large. | FIXED | portrait 195 px (1.3 x frame) |
| 26 | Profile portrait remains in front of the avatar frame with the pop-out effect. | FIXED | portrait drawn after (in front of) the frame, visible top above the ring |
| 27 | Profile portrait bottom must sit against the inner bottom of the avatar frame instead of floating. | FIXED | portrait visible bottom = frame inner bottom (0.83) within 1 px |
| 28 | Frame side/bottom segments must remain visibly readable behind the portrait. | FIXED | visible portrait body < 85% of frame width; frame sides/bottom visible (snapshot) |
| 29 | Profile progression bar must be thicker than the current V03 line. | FIXED | bar 42 px (V03 24) |
| 30 | Bot Parts copy is numeric ratio only, e.g. `1/250`. | FIXED | caption == '0/250' ratio only |
| 31 | Bot Parts ratio is centered inside the progression bar. | FIXED | caption reparented into the bar, centred H+V |
| 32 | Level badge remains separate and visually attached to the same progression row. | FIXED | rank badge + level on the same ProfileLevelRow, overlapping the bar end |
| 33 | No duplicate top-right Settings/menu button returns. | FIXED | no MenuButton; only bottom SettingsButton |
| 34 | Home has exactly **four** shortcut panels. | FIXED | exactly four Shortcut_* panels |
| 35 | Left shortcut column contains only **SHOP** and **COLLECTION**. | FIXED | LeftShortcutColumn = shop, collection |
| 36 | Right shortcut column contains only **TASKS** and **DAILY**. | FIXED | RightShortcutColumn = tasks, daily |
| 37 | WIN STREAK shortcut panel is removed from Home. | FIXED | Shortcut_win_streak absent; HOME-062 OWNER_RETIRED |
| 38 | GIFTS shortcut panel is removed from Home. | FIXED | Shortcut_gift_bar absent; HOME-063 OWNER_RETIRED |
| 39 | NO ADS shortcut panel is removed from Home. | FIXED | Shortcut_no_ads absent; HOME-066 OWNER_RETIRED |
| 40 | CARDS EXCHANGE shortcut panel is removed from Home. | FIXED | Shortcut_cards_exchange absent; HOME-069 OWNER_RETIRED |
| 41 | The four panel backgrounds become smaller/lighter than V03. | FIXED | panels 210x156 (V03 cards up to 226x220) |
| 42 | Panel surfaces should be near-transparent with only enough dark/blue tint, outline or glow for readability. | FIXED | HomeStyle.style_light_panel: bg alpha 0.30, 2 px cyan outline, soft glow |
| 43 | SHOP icon is enlarged relative to its current V03 size. | FIXED | SHOP icon box 1.2 x V03 (drawn > 1.15 x V03) |
| 44 | **TASKS icon stays at its current size.** | FIXED | TASKS icon box = V03 206x164 (drawn size equal) |
| 45 | **DAILY icon stays at its current size.** | FIXED | DAILY icon box = V03 206x164 (drawn size equal) |
| 46 | COLLECTION icon is enlarged relative to its current V03 size. | FIXED | COLLECTION icon box 1.2 x V03 |
| 47 | All four panel containers use the same size/style system even though icon sizes may differ. | FIXED | PANEL_SIZE shared; one style function |
| 48 | Panels receive visible outer-screen margin and may not stick directly to the screen edges. | FIXED | WorldMargin 26 px side margin (test >= 20 px) |
| 49 | The four panels must not cover Scrubby. | FIXED | panel rects vs Scrubby visible rect: no intersection |
| 50 | The four panels must not cover important baked helper bots. | FIXED | _avoid_helper_bots (gap tighten, then inward column shift); matrix asserts no panel/bot overlap at 7 sizes x 2 inset sets |
| 51 | The four panels frame the world composition instead of dominating it. | FIXED | light panels at the edges with icon pop-outs; world stays dominant (snapshots) |
| 52 | PLAY returns to a centered standalone CTA; the V03 `SHOP / PLAY / CARDS EXCHANGE` row is retired. | FIXED | PlayButton centred in HomeActionLayer; ActionRow removed |
| 53 | Current V03 Play size is a good starting point; do not enlarge it back to V02. | FIXED | PLAY 470 x 155 (V03 size, V02 700x196 not restored) |
| 54 | Native white play triangle remains. | FIXED | PlayTriangle native _draw |
| 55 | Live `PLAY/CONTINUE` and frontier-level subtitle remain runtime text. | FIXED | live UiText PLAY + HOME_START_LEVEL / HOME_CONTINUE_LEVEL subtitle |
| 56 | `Level N is coming soon` status must stay compact near Play and must not distort reward-track layout. | FIXED | StatusLabel is a 24 px pill child of PlayButton (never affects the track row) |
| 57 | HOME-078 remains retired from active Play presentation. | FIXED | HOME-078 OWNER_RETIRED; not drawn |
| 58 | Win Streak progression remains represented by the lower reward track, so no separate Win Streak shortcut is needed. | FIXED | track kept; no Win Streak panel |
| 59 | Reward track remains thin. | PRESERVED_CURRENT | V03 thin track (~136 px) kept |
| 60 | Reward track shows the five gift objects. | PRESERVED_CURRENT | TrackGift1..5 HOME-090..094 |
| 61 | Reward values remain only `1 / 5 / 10 / 25 / 100`. | PRESERVED_CURRENT | values 1/5/10/25/100 only |
| 62 | No per-step `+`, no per-step `WIN N`, no repeated per-step Scrub Bucks icons. | PRESERVED_CURRENT | no '+', no WIN copy, no per-step SB icon |
| 63 | HOME-087 remains retired from active per-step reward presentation. | PRESERVED_CURRENT | HOME-087 OWNER_RETIRED |
| 64 | Current/reached/future Win Streak state remains visually understandable. | PRESERVED_CURRENT | current step gold, reached full, future dimmed; progress line |
| 65 | Scrub Bucks and Heart icons are enlarged toward the approved target-HUD visual language. | FIXED | chip icons drawn 98 px (footprint 70 x pop 1.4) |
| 66 | Currency/Heart icons sit in front of their chip panels so the panel appears to extend from behind the icon. | FIXED | icon is a free child of IconSlot, overhanging the chip panel's left end and top/bottom |
| 67 | Add a visible `+` button to the right side of Scrub Bucks. | FIXED | ScrubBucksPlus (88x88) right of the chip |
| 68 | Add a visible `+` button to the right side of Hearts. | FIXED | HeartsPlus (88x88) right of the chip |
| 69 | These `+` buttons emit purchase/open-store intent only; do not invent transactions or prices. | FIXED | signals scrub_bucks_purchase_requested / hearts_purchase_requested; economy snapshot unchanged |
| 70 | Gift Meter keeps the compact live ratio-only form `N/1000`. | PRESERVED_CURRENT | N/1,000 ratio only |
| 71 | Gift Meter emblem/crate may be modestly enlarged for visual balance. | FIXED | emblem/crate 100 -> 112 px |
| 72 | No long `GIFT METER ... NEXT GIFT ...` caption returns. | PRESERVED_CURRENT | no long caption |
| 73 | No obsolete Coin/Star/XP/Event semantics return. | PRESERVED_CURRENT | no Coin/Star/XP/Event copy; manifest validator Economy V1 rules pass |
| 74 | Cards Exchange becomes a Collection-owned flow/entry point, not a Home shortcut. | DEFERRED_BY_OWNER_ARCHITECTURE | Home panel removed; Cards Exchange popup kept as a Collection-owned seam (open_popup('cards_exchange')); Collection flow itself is a later milestone (COLLECTION panel stays future-disabled) |
| 75 | No Ads becomes a Shop-owned flow/entry point, not a Home shortcut. | DEFERRED_BY_OWNER_ARCHITECTURE | Home panel removed; No-Ads entitlement belongs to the future Shop flow; AdBannerSlot exposes set_ad_slot_enabled(false) for it |
| 76 | Gifts are not a Home shortcut; reward granting/claim behavior remains service-driven/automatic according to canonical game rules. | PRESERVED_CURRENT | Gift Meter + GiftMeterService unchanged (claimable badge on the crate; gifts popup seam kept); no new auto-claim rule invented |
| 77 | Removing Home shortcuts must not delete their underlying economy/services/data. | FIXED | services/data untouched (test: gift/exchange/streak services present; m42_home gift_bar_claims + cards_exchange_presentation still pass) |
| 78 | Daily remains the only directly opened economy/reward popup among the four Home panels in this pass; existing modal behavior remains deterministic. | FIXED | DAILY is the only live Home panel; popup behaviour unchanged |
| 79 | When a modal/page such as Daily or Settings opens, Home action UI must hide and must not receive input; V03 modal regression behavior is preserved. | FIXED | HomeActionLayer + HUD (+) hidden while Daily/Settings open; back restores exact Home (daily_modal, settings_modal) |
| 80 | Bottom navigation remains five buttons with HOME selected and current RANKS wording preserved. | PRESERVED_CURRENT | five tabs, HOME selected, RANKS |
| 81 | A dedicated persistent `AdBannerSlot` sits below BottomNav; BottomNav is no longer required to be the screen-bottom element. | FIXED | AdBannerSlot below BottomNav, screen-bottom element; empty AdMount seam |
| 82 | The world background must stop above/behind the UI composition and may not visually leak into the AdBannerSlot; No-Ads entitlement can later collapse the ad slot. | FIXED | world canvas clipped at the ad slot top; collapse test moves the nav to the bottom |
| 83 | Introduce a data-driven World Home background seam for future worlds, but DO NOT invent level ranges yet. World 01 is the current default; future world IDs/backgrounds can be mapped once owner-defined progression ranges exist. | FIXED | home_worlds_v1.json + HomeWorldCatalog (world_01 default only, no level ranges, unknown world -> empty) |
