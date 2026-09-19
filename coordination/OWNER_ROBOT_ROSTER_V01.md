# OWNER_ROBOT_ROSTER_V01 — SCRUBBOTS CLEANING CREW

Status: OWNER-APPROVED
Version: V01
Scope: canonical 10-robot roster, unlock order, meta perks, visual identity, character-asset contract
Branch note: authored on `codex/visual-assets-production` during isolated visual production; integrate to main only after owner-controlled branch integration.

## 1. Canonical roster

SCRUBBOTS V1 uses a 10-robot cleaning crew.

Scrubby is unlocked at game start.

Every subsequent robot costs exactly **250 Bot Parts**.

Cumulative Bot Parts required from game start therefore become:

- Robot 2: 250
- Robot 3: 500
- Robot 4: 750
- Robot 5: 1000
- Robot 6: 1250
- Robot 7: 1500
- Robot 8: 1750
- Robot 9: 2000
- Robot 10: 2250

The existing economy rule that robot perks must never alter puzzle solvability truth remains absolute.

Robot perks may affect meta-economy/convenience only.

They may NEVER modify:
- BoardState legality
- target selection
- routing legality
- solver/deadlock truth
- batch conservation
- reservation/claim uniqueness
- number of target cells
- automatic cleaning legality
- +1 Slot authoritative rules
- Random/Selector/Tornado gameplay truth

## 2. Canonical 10-robot cleaning crew

| # | Robot | Role / personality | Main accent | Canonical perk |
|---:|---|---|---|---|
| 1 | **Scrubby** | The Leader. Friendly, balanced, optimistic face of the franchise. | Teal + cyan + leaf green | **Leader Baseline:** no economy modifier. Scrubby is the neutral reference character. |
| 2 | **Moppy** | Floor-cleaning specialist. Hard-working, slightly clumsy, lovable. Mop-inspired tool silhouette. | Aqua + lime | **Clean Bonus:** +20% first-clear Scrub Bucks. |
| 3 | **Bubbles** | Foam/detergent specialist. Round, energetic, bubbly tank silhouette. | Cyan + lavender | **Gift Sparkle:** +20% Scrub Bucks granted by Gift Bar rewards. |
| 4 | **Spark** | Electrical maintenance / speed specialist. Slim, energetic, coil/antenna motifs. | Electric blue + yellow | **2x Saver:** 20% discount on paid 2x speed products. |
| 5 | **Squeegee** | Glass/surface specialist. Precise, tidy, broad squeegee silhouette. | Sky blue + silver | **Exchange Polish:** +20% Scrub Bucks from Cards Exchange. |
| 6 | **Dusty** | Dust/vacuum specialist. Vacuum backpack/filter-ear silhouette. | Orange + cream | **Booster Saver:** 20% discount on Scrub Bucks booster purchases. |
| 7 | **Rinse** | Water/rinse specialist. Calm, tank/nozzle silhouette. | Deep cyan + white | **Heart Saver:** 20% discount on Scrub Bucks Heart refill costs. |
| 8 | **Polly** | Surface-polishing specialist. Stylish, confident, spinning pad motifs. | Magenta + cyan | **Streak Shine:** +20% Win Streak Scrub Bucks bonus. |
| 9 | **Clippy** | Precision/detail cleaner. Small mechanical claws and micro-tools. | Purple + mint | **Daily Helper:** +20% Scrub Bucks from individual Daily task rewards. |
| 10 | **Atlas** | Heavy-duty endgame cleaner. Large friendly industrial silhouette, premium presence. | Navy + gold + teal | **Master Cleaner:** +20% first-clear Scrub Bucks AND +20% Cards Exchange Scrub Bucks. |

## 3. Percentage rule

All percentage-based robot perks in this roster use **20%**.

Do not silently reduce these values to 5% or 10%.

If future balance testing changes a value, that requires a new owner decision/version.

## 4. Unlock order

Canonical order is:

1. Scrubby
2. Moppy
3. Bubbles
4. Spark
5. Squeegee
6. Dusty
7. Rinse
8. Polly
9. Clippy
10. Atlas

This order is both progression order and Robot Collection display order unless the owner later changes it.

## 5. Visual family rule

All 10 robots belong to one SCRUBBOTS product family.

Shared DNA:
- friendly compact cleaning robot proportions
- white/cream shell family
- glossy black face display
- expressive cyan digital eyes
- cyan/teal technology language
- toy-like polished 3D casual-mobile rendering
- strong readable silhouette at mobile scale
- eco-cleaning identity
- no photorealism
- no military/combat identity

Each robot MUST still have a clearly different silhouette and tool language.

Scrubby remains the franchise anchor and should never be visually displaced by another robot.

## 6. Per-robot production asset contract

Scrubby already establishes the canonical character-asset family.

For EVERY robot, production requires these nine presentation assets:

1. `<robot>_master.png`
   - canonical full-body/master character artwork

2. `<robot>_gameplay.png`
   - gameplay-selected/support pose

3. `<robot>_portrait.png`
   - reusable head/upper-body portrait

4. `<robot>_home_pose.png`
   - Home / Robot Collection hero pose

5. `<robot>_face_blink_layer.png`
   - aligned blink/expression layer when technically meaningful

6. `<robot>_tool_arm_layer.png`
   - isolated main tool/arm animation layer

7. gameplay profile portrait
   - small gameplay HUD/profile presentation

8. help pose
   - popup/help/support pose

9. victory pose
   - level victory/celebration pose

For Scrubby the existing brush-arm filename remains valid:
`scrubby_brush_arm_layer.png`

For other robots, `tool_arm_layer` is the canonical generic naming rule.

## 7. Canonical asset path convention for Robot 2..10

Character master family:

`assets/ui/final/characters/robots/<robot_slug>/`

Gameplay profile portraits:

`assets/ui/final/gameplay/profile/robots/<robot_slug>_portrait.png`

Help poses:

`assets/ui/final/popups/help/robots/<robot_slug>_help_pose.png`

Victory poses:

`assets/ui/final/popups/victory/robots/<robot_slug>_victory_pose.png`

## 8. Existing Scrubby asset family

Current Scrubby equivalents already in the project:

- `assets/ui/final/characters/scrubby/scrubby_master.png`
- `assets/ui/final/characters/scrubby/scrubby_gameplay.png`
- `assets/ui/final/characters/scrubby/scrubby_portrait.png`
- `assets/ui/final/characters/scrubby/scrubby_home_pose.png`
- `assets/ui/final/characters/scrubby/scrubby_face_blink_layer.png`
- `assets/ui/final/characters/scrubby/scrubby_brush_arm_layer.png`
- `assets/ui/final/gameplay/profile/scrubby_portrait.png`
- `assets/ui/final/popups/help/help_scrubby_pose.png`
- `assets/ui/final/popups/victory/victory_scrubby_pose.png`

Do not regenerate these merely to normalize directory naming.

## 9. Old planning-document precedence

The early planning document contained exploratory robot examples such as Moppy, Bubbles and Spark.

This owner decision now makes the full 10-robot roster above canonical.

The old document's World Map, XP progression, Star Exchange, Star currency, weekly progression, seven-day reward structure and obsolete Pickup-booster ideas remain non-canonical and must not be revived by this roster decision.

## 10. Production handoff

Codex Phase 2 is authorized to generate Robot 2..10 using this owner decision.

Robot generation must:
- preserve each robot's specified role, accent palette and silhouette idea;
- keep all robots recognizably in the same SCRUBBOTS universe;
- generate separate transparent PNG files;
- avoid baked text/numbers/perk percentages;
- not alter any gameplay/economy code;
- not touch `main` during the active Claude M30 sprint.
