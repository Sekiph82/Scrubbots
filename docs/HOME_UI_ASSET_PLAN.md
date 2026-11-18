# SCRUBBOTS Home UI Asset Plan

Status: preproduction inventory ready  
Canonical visual reference: `assets/art/references/_owner_inbox/Game Screens/main screen.png`  
Machine-readable inventory: `assets/ui/HOME_ASSET_MANIFEST.json`

## Purpose

This plan converts the approved Home-screen art direction into a production asset contract. It does not mark M42 complete and does not authorize production UI implementation ahead of the canonical gameplay milestone sequence.

## Production split

- **Generated ART**: Scrubby/robots, environment illustration, branded icons, reward objects and illustration-heavy frames.
- **Godot NATIVE**: scalable panels, progress bars, simple icons, state overlays, notification bodies, layout containers and interaction states.
- **LIVE**: all user-facing values, timers, counters, labels and localized copy.
- **FX**: glows, shadows, bubbles, sparkles and pulses, preferably native particles/shaders where practical.
- **FONT**: licensed production typography selected separately.

ChatGPT image generation is primary for new generated ART. Magnific remains an approved fallback.

## Layering contract

Do not ship the Home reference as one flattened interactive screenshot. Split world art into sky, far city, mid city and street foreground so tall/short phones can crop and reposition without distorting the composition. Central world art, characters and UI remain separate layers.

## Text that must not be baked into images

Player name, rank/title, level, Bot Parts progress, Scrub Bucks amount, Heart count/regen timer, area name/number, Gift Meter progress/next milestone, Win Streak values, shortcut labels/counters, PLAY/CONTINUE copy, reward amounts, prices, notification values and bottom-navigation labels remain live Godot text. Stars, Event Points and profile XP are not production balances under Economy V1.

## Naming and lifecycle

Use lowercase snake_case. Add `_normal`, `_pressed`, `_selected`, `_disabled`, `_locked` or `_claimable` only when a separate texture is truly required. Prefer Godot Theme/modulate/shader state changes.

```text
owner reference
→ assets/ui/generated/<category>/ candidate
→ owner review
→ assets/ui/final/<category>/ approved production asset
→ Godot import/bind
→ responsive validation
```

Approved assets are never silently regenerated or overwritten.


## Economy V1 Home migration

Canonical economy decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

The owner reference is art direction, not literal economic semantics. Production substitutions:
- coin icon/amount -> Scrub Bucks banknotes/amount;
- profile XP bar -> Bot Parts next-robot bar;
- top event bar -> Gift Meter (streak-SB-only; 1/5/10/25/100/250/500/1000 (SB-POLISH-002));
- top event timer -> removed/replaced by live next-milestone information;
- Star Exchange -> Cards Exchange;
- star road -> Win Streak SB Reward Track (SB-TF-03 owner 2026-11-18: removed from Home; the streak stays an economy rule).

SB-TF-03 (owner 2026-11-18) Home layout: no bottom navigation (its Settings art is the top-HUD Settings icon), no Shop / Collection tiles (Shop via the HUD (+) popups, Collection in Profile), no win-streak strip, a Bot Parts icon instead of the level on the profile card and PLAY · LEVEL N. The retired art keeps its manifest entries; `scripts/ui/home/home_presentation_map.gd` marks it OWNER_RETIRED.

Do not generate art that reintroduces Star currency or Event Points.
