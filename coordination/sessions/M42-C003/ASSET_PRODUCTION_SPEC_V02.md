# M42-C003 - Home Scrubby Gesture Frames - ASSET PRODUCTION SPEC V02

Date: 2026-10-01
Task: `SB-M42-035`
Authority: `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V02.md`
Supersedes: `ASSET_PRODUCTION_SPEC_V01.md` where conflicting.

HOME-026 is never modified and remains the static fallback/idle authority:
`assets/ui/final/characters/scrubby/scrubby_home_pose.png`
Canvas: 1158 x 1358 RGBA
Pivot / ground contact authority: (592, 1318)
Home runtime scale authority: 1.612

## 1. Owner source archive

Archive name: `Home_Main_Hero_Assets.zip`
Archive SHA-256:
`f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458`

Exact per-file hashes/dimensions:
`coordination/sessions/M42-C003/OWNER_SOURCE_ASSET_MANIFEST_V02.md`

The implementation agent must locate the exact archive locally and verify the archive hash before using it. Do not upload the art to external generation services.

## 2. Production deliverables

| Set | Production frames | Runtime sequence |
|---|---:|---|
| Wave | 14 | HOME-026, wave_01..14, HOME-026 |
| Bow | 15 | HOME-026, bow_01..15, HOME-026 |
| Turn / Look | 17 | HOME-026, turn_01..17, HOME-026 |
| Full Turn | 17 | HOME-026, full_turn_01..17, HOME-026 |

Total production gesture frames: 63.

Production frame count is fixed, but V02 explicitly permits reordering, reusing, reversing, or omitting owner-approved source frames when building the final sequence. No new character painting is allowed.

## 3. Sequence contracts

### Wave

One friendly wave only. The already-raised viewer-right hand performs the motion and eases back toward HOME-026. If the raw final frames lower the hand too far, rebuild the 14-frame production sequence from the clean Wave subset by reusing/reversing approved source frames. Do not carry a low-hand pose into the HOME-026 bookend.

### Bow

Bow-only sequence. Forward bend, brief bottom hold, return. If raw source frames 12-15 introduce a wave-like hand raise, omit them and construct the 15 production frames by returning through clean Bow poses. Both soles remain planted.

### Turn / Look

Required bilateral behavior:

1 center;
2-5 right to about 25-35 degrees;
6-8 center;
9-12 left to about 25-35 degrees;
13-17 center.

Prefer the dedicated Turn / Look source only if normalization preserves HOME-026 scale/identity. Otherwise derive the final 17-frame sequence from approved Full Turn source frames near the front/right and front/left arcs.

### Full Turn

A real in-place 360-degree rotation using approved Full Turn source frames. It is rare but production-authorized.

## 4. Canvas and registration

Every production PNG:

- exactly 1158 x 1358;
- RGBA8, straight alpha, transparent background;
- no matte, number badge, text, sheet residue, or external shadow;
- opaque content stays inside canvas;
- pivot meaning stays identical to HOME-026;
- soles register to y = 1318 +/- 1 texel after technical cleanup where anatomically measurable;
- brush bristles may extend below soles only within the existing HOME relationship, never outside canvas.

### Scaling rule

No per-frame scaling.

Determine one deterministic uniform scale per visual source family, then reuse it for every frame from that family. Do not stretch x/y independently.

The normalization objective is, in priority order:

1. preserve HOME-026 character identity/physical scale, especially visor/head width and limb thickness;
2. preserve ground registration;
3. prevent frame-to-frame scale jitter;
4. satisfy safe-area constraints;
5. minimize HOME-026 entry/exit pop.

Do not blindly scale a source frame by total source-canvas height. Transparent source canvases and generated pose proportions differ.

If the dedicated Turn / Look family cannot satisfy this objective without obvious shrink/grow, use Full Turn art for Turn / Look and therefore the Full Turn family scale.

## 5. Keep-out zones

Legacy V01 zones remain blocking for Wave, Bow, and Turn / Look:

- K1 COLLECTION: x 0..69, y 40..308, alpha >128 count must be 0.
- K2 DAILY: x 1115..1158, y 40..308, alpha >128 count must be 0.
- K3 right helper: x 1059..1158, y 829..1339, alpha >128 count must be 0.
- K4 left helper: x 0..125, y 999..1358 may only occupy the accepted HOME brush footprint.

Full Turn is a new owner-added motion after V01. For Full Turn:

- K1 and K2 remain blocking.
- canvas containment remains blocking.
- K3/K4 are reported per frame and treated as visual-review warnings rather than automatic rejection, because a genuine 360-degree pose can temporarily expose backpack/brush geometry differently. The evidence capture must make any helper overlap obvious.
- do not shrink Full Turn frame-by-frame to game the warning.

## 6. Raw-source staging and final promotion

Exact owner source bytes may be staged under:
`assets/ui/generated/characters/home_animation/source_v02/`

Normalized candidates:
`assets/ui/generated/characters/home_animation/{wave,bow,turn,full_turn}/`

After deterministic checks pass, promotion is authorized to:
`assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn,full_turn}/`

Pin every promoted frame SHA-256 in the existing HOME asset manifest using the repository's current schema.

The game must never load source_v02 or generated candidates.

## 7. Required deterministic tooling

Commit a reproducible preparation/validation tool in the repository. It must:

- verify archive and per-file source hashes;
- clean technical alpha/sheet residue only, never redraw;
- construct the final sequence mappings;
- normalize to 1158x1358;
- use one scale per visual family;
- register the soles/root;
- validate canvas/alpha/K1-K4;
- emit per-frame measurements and SHA-256;
- create contact sheets and transition strips;
- be safe to rerun without changing already deterministic output.

## 8. Runtime behavior

Dedicated `HomeScrubbyHero` presentation component, retaining child `Art_scrubby` naming compatibility.

Idle:
- subtle, feet-anchored, presentation-only micro motion.

Gesture scheduler:
- Wave 35
- Turn / Look 30
- Bow 25
- Full Turn 10
- 6-12 seconds between gestures
- no immediate repeat
- no stacking

Reduced Effects:
- no large gestures;
- static HOME-026 unless a separately approved low-motion blink exists.

Lifecycle:
- no new gesture while Home hidden, modal active, app unfocused, or app paused;
- no catch-up burst after resume.

## 9. Acceptance

Automated:

- exact source hashes;
- exact production counts 14/15/17/17;
- exact canvas size and alpha mode;
- no per-frame scale drift;
- ground/pivot registration report;
- safe-area report;
- frame SHA pins;
- deterministic rerun equality;
- runtime lifecycle/regression tests.

Evidence:

- HOME-026 -> gesture -> HOME-026 transition strip for all 4 gestures;
- 12 fps capture for all 4;
- contact sheet for all 4;
- four required Home viewports;
- Reduced Effects capture;
- 20x Home enter/leave leak report;
- Full Turn K3/K4 overlap report.

Independent ChatGPT audit is the final technical gate for SB-M42-035.
