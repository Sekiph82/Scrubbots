# Localization (M51)

Launch languages: **English and Turkish** (owner 2026-10-22, SB-M51-005).

## Where copy lives

- `scripts/ui/ui_text.gd` (`UiText`) is the one seam. Every user-facing string is a key;
  `UiText.t(key, args)` asks `TranslationServer` first, then the built-in table of the active
  language (`UiText.locale`), then English.
- `EN` (in `ui_text.gd`) is the English table. `scripts/ui/ui_text_tr.gd` holds `TR` (one entry
  per `EN` key, same `%s` / `%d` placeholders in the same order) and `DATA`.
- Data-file copy (achievement names / descriptions, robot roles / perks, Collection set names)
  stays English in the data files; `UiText.data(key, english)` returns the Turkish `DATA` entry
  when Turkish is active. Keys: `ACH_NAME_<ID>`, `ACH_DESC_<ID>`, `ROBOT_ROLE_<ID>`,
  `ROBOT_PERK_NAME_<ID>`, `ROBOT_PERK_TEXT_<ID>`, `SET_NAME_<N>`.
- No user text in scripts or scenes outside these tables: `tests/m51_localization_readiness.gd`
  case l08 fails on `text = "..."` literals with words, multi-word string literals and
  hand-formatted currency in `scripts/ui`, `scripts/app` and `scenes`.

## Language choice

Saved choice (Settings > LANGUAGE, `settings.effects.language` = `en` / `tr`) > device language
(`OS.get_locale_language()`) > English. The field is written only once the player picks a
language; any other value rejects the save candidate. Picking a language applies it, saves it
and rebuilds the app root (screens take their copy when built).

## Names that are not translated

- Product and character names: ScrubBots, Scrubbot(s), Scrubby, Moppy, Bubbles, Spark,
  Squeegee, Dusty, Rinse, Polly, Clippy, Atlas, ScrubBox, and card names.
- Currency: **Scrub Bucks** is a brand name and stays "Scrub Bucks" in Turkish too; its short
  form stays **SB**. Hearts = Kalp, Bot Parts = Robot Parçası, Level = Bölüm.

## Plurals (SB-M51-008)

`UiText.tn(key, n, args)` uses `key + "_ONE"` when `n == 1` and the language is English
(one / other); otherwise `key`. Turkish has no plural inflection after a number ("1 kart",
"5 kart"), so the TR table has no `_ONE` keys. Plural pairs exist for Hearts, Bot Parts, cards,
card packs, boosters, days, gifts / rewards, pixels and ranks ("1 more level"). Time remaining
uses unit abbreviations (`TIME_DHM`: `1d 2h 3m`, Turkish `1g 2sa 3dk`) and needs no plural.
No player-facing copy counts attempts; a future one goes through `tn`.

## Numbers and prices (SB-M51-007)

- `UiText.num(n)` groups thousands: `1,000` in English, `1.000` in Turkish.
- Real-money prices are never formatted in code. When the store integration lands, the
  platform's localized price string (Google Play `ProductDetails` formatted price, StoreKit
  `displayPrice`) is passed as a `%s` argument. Until then the store rows show the localized
  "store unavailable" copy (`SHOP_STORE_LATER`, `SHOP_UNAVAILABLE`, `SHOP_SOON`).

## Tests

- `tests/m51_localization_readiness.gd`: pseudo-locale, key convention, Settings keyed, surface
  scan, TR table completeness + placeholders (l05), plurals (l06), language choice (l07), static
  guard (l08).
- `tests/m49_touch_targets_text_stress.gd` t04 and `tests/m49_surface_stress.gd` v03 walk every
  surface in the real Turkish table (no clipped / overflowing text, Turkish glyphs present).

The Turkish copy should get an owner read-through on the phone.
