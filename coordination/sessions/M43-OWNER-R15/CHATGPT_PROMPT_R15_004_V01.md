# M43-C015R — SB-M43-R15-004 — REWARDED ADS HOME ICON VISUAL REMEDIATION V01

Status: READY FOR CLAUDE
Date: 2026-10-06
Repository: Sekiph82/Scrubbots
Owner-local checkout: C:\Users\sekip\Desktop\ScrubBots
Canonical tracker: root TASKS.md — READ ONLY FOR CLAUDE

## OWNER DECISION

The Rewarded Ads functionality is technically accepted, but the current small green native REWARDED ADS button on Home is **OWNER REJECTED** visually.

The owner has supplied one exact text-free PNG master for the Rewarded Ads Home icon. It shows:
- Scrubby in the approved white/blue/sprout visual language;
- a blue video/play panel;
- Scrub Bucks;
- Hearts;
- gift/reward cues;
- NO coins;
- NO baked REWARDED ADS text.

The attached PNG is the visual source of truth.

Expected SHA-256 of the exact owner master:
`e25529bdab27e66856bc1d41eb9c7ab54c6d635dc006a6e526cdf8e5dfea378f`

**Do not redraw, regenerate, repaint, stylize, substitute, or AI-edit this owner master.**

If the attached image is unavailable or its SHA does not match, STOP and report. Do not invent a replacement.

## 0. FIRST ACTION — OWNER-LOCAL NON-DESTRUCTIVE SYNC

Work directly in:
`C:\Users\sekip\Desktop\ScrubBots`

Before implementation:
1. inspect `git status --short`, current branch, local HEAD, `origin/main`, ahead/behind;
2. fetch `origin/main`;
3. preserve all owner-local work, especially `project.godot`, `scenes/app/main.tscn`, `addons/`, `.mcp.json`, editor/plugin settings and unrelated untracked files;
4. synchronize non-destructively with current `origin/main`;
5. no `reset --hard`, no `git clean`, no force checkout, no owner-file overwrite;
6. root `TASKS.md` is read-only.

If local integration is unsafe or genuinely conflicted, STOP and report exact files.

## 1. PRESENTATION CONTRACT

Replace only the current green Home Rewarded Ads CTA presentation.

Do NOT change:
- Rewarded Ads five-slot daily logic;
- slot 1 free CLAIM;
- slots 2-5 rewarded-video authority;
- provider behavior;
- deterministic transaction ids;
- popup destination;
- Daily login behavior;
- Daily Scrub Orders;
- Shop / Collection / Tasks / Daily primary panels;
- Home navigation authority.

The Rewarded Ads Home entry remains an **auxiliary destination associated with DAILY**, not a fifth equal primary panel.

## 2. MAKE IT SPEAK THE SAME HOME VISUAL LANGUAGE

Inspect exactly how the four approved Home shortcut items are built and bound:
- SHOP
- COLLECTION
- TASKS
- DAILY

Use their existing production system rather than inventing a new one:
- `UiShortcutButton`
- `HomeStyle.style_light_panel`
- canonical cyan/blue glass panel
- same label-band grammar
- same font treatment / outline
- same icon TextureRect behavior
- same hover / pressed / disabled language
- same Home art lifecycle / binder / manifest rules
- same safe-area / responsive conventions.

Current canonical four shortcut assets:
- `assets/ui/final/home/shortcuts/icon_shortcut_shop.png`
- `assets/ui/final/home/shortcuts/icon_shortcut_collection.png`
- `assets/ui/final/home/shortcuts/icon_shortcut_tasks.png`
- `assets/ui/final/home/shortcuts/icon_shortcut_daily.png`

The Rewarded Ads visual must look like it belongs to this exact family, not like a green gameplay CTA pasted under DAILY.

## 3. OWNER MASTER ASSET INTAKE

Copy the exact attached PNG byte-for-byte into the approved Home shortcut asset family, preferably:

`assets/ui/final/home/shortcuts/icon_shortcut_rewarded_ads.png`

Do not alter pixels if no crop/padding normalization is required.

If runtime presentation needs transparent margin normalization, do NOT destructively edit the approved source. Instead:
- keep the owner source master byte-exact;
- use layout/icon-box scaling/positioning in Godot;
- only create a derived runtime asset if absolutely required by the existing Home asset lifecycle, and document why. Prefer no derivative.

Add a canonical manifest entry:
- id: `HOME-122`
- slug: `icon_shortcut_rewarded_ads`
- group: `shortcuts`
- kind: `ART`
- implementation: `generated_asset`
- provider: `chatgpt_image_generation`
- status: `APPROVED`
- path: final shortcut path above
- approved_sha256: exact owner-master SHA

Update `HomePresentationMap` so the new approved asset is presented through the Rewarded Ads Home icon node.

Do not weaken `HomeArtBinder` integrity checks.

## 4. HOME COMPOSITION

Replace the native green `RewardedAdsButton` body/triangle treatment.

The Home entry should now use the owner-approved icon plus a code-driven label band exactly in the spirit of the four existing shortcuts.

The PNG itself has **no text**.

Render:
`REWARDED ADS`

through code, using the same family as the other shortcut labels:
- white text;
- navy outline;
- same/balanced typography;
- two lines if needed for readability;
- label belongs to the button/panel, not baked into the icon.

### Size / placement

Keep the Rewarded Ads entry visually attached to the DAILY side of Home and preserve the current concept that it is auxiliary.

However, it must no longer look like a tiny green pill.

Use the same visual geometry logic as the four shortcut cards:
- same cyan/light-panel frame language;
- comparable icon-to-card proportion;
- icon may pop above the label band like the other four;
- minimum touch target remains >=88 px;
- no collision with Scrubby, PLAY, Gift Meter, Win Streak rail, Daily panel or screen edge.

Do not move or resize SHOP / COLLECTION / TASKS / DAILY just to make room unless a minimal existing spacing adjustment is necessary. Preserve the owner-accepted four-panel composition.

At the owner's normal runtime `683x1366`, the result should read instantly as:
**“same Home icon family, additional Rewarded Ads auxiliary entry.”**

## 5. ART / BINDER / VALIDATION

Update any manifest validator tests/presentation accounting required by adding HOME-122.

Required:
- manifest validates;
- source-tree strict hash check passes;
- packaged-runtime binding path remains valid;
- the new Rewarded Ads icon binds only when APPROVED and hash-correct;
- no existing approved Home asset hash changes;
- SHOP / COLLECTION / TASKS / DAILY assets remain byte-identical.

Do not replace any of the four existing icons.

## 6. TESTS

Add focused coverage for:
- Rewarded Ads Home node exists;
- exact asset slug/path/manifest state is APPROVED_BOUND;
- new icon is actually presented;
- green native CTA style is no longer the active presentation;
- code-driven label is `REWARDED ADS`;
- Rewarded Ads still emits only the same `rewarded_ads` intent;
- popup still opens unchanged;
- four primary shortcut columns still contain only SHOP/COLLECTION/TASKS/DAILY;
- Home geometry at 683x1366 and existing responsive matrix remains collision-free;
- touch target >=88 px;
- existing M42 Home tests PASS;
- existing R15 Rewarded Ads functional tests PASS;
- root `tests/run_tests.gd` ALL PASS;
- `git diff --check` clean;
- no unexplained `SCRIPT ERROR`.

## 7. OWNER EVIDENCE

Produce fresh final-tree captures:
1. Home at 683x1366 showing the new Rewarded Ads icon in context with all four existing shortcut icons;
2. Home at 1080x2160;
3. Rewarded Ads popup opened by tapping the new icon.

The key owner comparison is not an isolated icon render. It is the **live Home screen with all five visible entries**, proving that Rewarded Ads now speaks the same visual language.

## 8. LOG / PUSH

Write:
`coordination/sessions/M43-OWNER-R15/SB-M43-R15-004_CLAUDE_LOG_V01.md`

Log:
- local sync result;
- source owner image filename + SHA;
- final asset path + SHA;
- manifest/presentation-map changes;
- Home geometry;
- files changed;
- tests;
- evidence paths;
- exact final SHA;
- remaining owner gate.

Push to `main` if permitted. If not, push one branch and report exact branch/SHA/ahead-behind with a clean fast-forward instruction.

Do not edit root TASKS.md.

Finish exactly:

`AWAITING_GPT_SB_M43_R15_004_V01_AUDIT`
