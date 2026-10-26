# Difficulty recovery / sequencing proposal V1 (SB-M36-010)

Status: PROPOSAL, recommendation pre-approved. This document changes nothing in `data/config/`, `data/levels/`, the catalog or any script. On 2026-10-26 the owner pre-approved the factory's own findings ("eğer benim verdiğim puanları kural olarak alıyorsa almasın. kendi bulduklarını ben okeyliyorum şimdiden.", orchestrator chat). The recommendation in section 6 is therefore approved. The work it needs is filed as SB-M36-014, and the guard rescale is part of SB-M36-013. Per the same instruction, this analysis uses only the measured v2 data and CLAUDE.md 11. The owner's ratings are not used as a criterion.

Inputs (every number below is copied from these files or computed directly from them):

- `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json`: model v2, the active model for new analysis (SB-M36-012). Its report is `docs/DIFFICULTY_MODEL_V2_CALIBRATION.md`.
- `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json`: model v1. Its report is `docs/DIFFICULTY_PLAYTEST_2026-10.md`.
- `data/config/level_progression_v1.json` `recoveryGuards`, CLAUDE.md 11.1 / 11.5, docs/09 section 10, docs/10 section 13 and docs/11 sections 8 and 11.

## 1. Which guards fail under v2, and why

The guards come from `level_progression_v1.json` and are checked on actual D, never on target D:

| Guard | v1 D (drop) | v2 D (drop) | Minimum | v2 result | Session Load drop (v2) |
|---|---|---|---:|---|---:|
| L3 -> L4 | 54.3 -> 49.5 (4.8) | 38.9 -> 25.0 (13.98) | 15 | fail, 1.0 short | 10.60 |
| L5 -> L6 | 53.2 -> 50.9 (2.3) | 29.4 -> 23.6 (5.80) | 20 | fail, 14.2 short | 1.39 |
| L8 -> L9 | 47.4 -> 50.8 (-3.4) | 28.7 -> 37.1 (-8.45) | 15 | fail, inverted | 0.04 |

The table below splits each v2 drop by component, in D points (weight x (peak value - recovery value) x 100). A positive number means the recovery level is easier on that component.

| Guard | W | C | A | U | B | R | S | Total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| L3 -> L4 | +2.07 | +0.69 | +7.68 | +0.85 | +0.71 | +1.39 | +0.58 | 13.98 |
| L5 -> L6 | +0.34 | +2.41 | +1.30 | +1.11 | +0.74 | -0.21 | +0.09 | 5.80 |
| L8 -> L9 | +0.00 | +1.36 | -5.35 | -1.24 | -1.79 | -0.51 | -0.93 | -8.45 |

- **L3 -> L4 almost passes.** L4 is clearly easier on access (A 0.492 -> 0.108) and smaller (38x38 -> 32x32). This is the only guard that also has a real Session Load drop. It misses the minimum by 1.0 D.
- **In L5 -> L6 the problem is the peak, not the recovery.** L6 has the second-lowest D in the pack (23.6), but L5 scores only 29.4. L5 has the second-highest C (0.701), but its A (0.109) and B (0.057) are low, because the six ensemble policies almost always find reachable work. The solver path puts L5 at 45.0 (`oracleDiagnosticD`), but the oracle trace is not allowed into D. A 20-point drop from 29.4 would need a recovery level at 9.4 D. No shipped level comes close (the minimum is 22.1), and neither does any reasonable EASY board.
- **L8 -> L9 is inverted because L9 measures harder.** L9 has more access scarcity (A 0.408 vs 0.141), more bottleneck pressure (B 0.152 vs 0.033) and deeper unlocks (U 0.530 vs 0.467, locked fraction 0.59 vs 0.45). L8 is ahead only on C (0.631 vs 0.541). On measured data, L9 is a poor recovery after L8. This is a content-placement finding, not a model defect.
- **Session Load cannot separate the levels.** L4..L10 are all 32x32 or 33x33, so their Session Load is 25.0..26.6. Only L3 (38x38, 35.6) stands out. Two of the three guard pairs therefore get no help from load.

The secondary findings from SB-M36-005 no longer appear under v2:

- The boss now ranks 1st (L10 46.7, `isCycleMaximum` true). Under v1 it ranked 3rd.
- The LONG_HIGH_FRICTION run L5..L7 is gone. With the v2 medians (D 31.28, Session Load 25.115), no two consecutive levels are both above the median on D and on Session Load. L5 (29.4) is below the D median.

## 2. The guard minimums and the v2 D scale

The guard minimums (15/20/15) are in lane-target points. Their target drops are 21/40/23 (`targetDrop` in `playtest_v2.json`), so each minimum is 71%, 50% and 65% of the drop the lanes intend. Under v2 the whole shipped pack spans only 24.6 D (22.1..46.7). No fixture in the 27-level calibration corpus scores above 36.5. The HARD lane target is 58, but L5 measures 29.4 (SB-M36-013). The 5 -> 6 minimum of 20 points is 81% of the full pack range. It cannot be reached on the current v2 scale, however the levels are ordered (section 3).

So the failures have two separate causes:

- **Scale (5 -> 6, and part of 3 -> 4):** the minimums assume a lane scale that v2 D does not reach. L5 -> L6 falls in the direction the cadence intends (down 5.8 D, and L6 is the second-easiest level in the pack). It only falls short in absolute size.
- **Content (8 -> 9):** L9 measures harder than L8 on A, B, U, R and S. No scale change fixes an inversion.

## 3. Option A: reorder the 10 shipped levels

Method: an exhaustive search over the v2 D values in `playtest_v2.json`, using the script in the appendix (runtime about 5 s). Orders are ranked first by the number of guards that pass, then by the smallest total shortfall below the minimums.

| Variant | Orders searched | Guards passing (histogram) | Best order (slot 1..10) | Best result |
|---|---:|---|---|---|
| Shipped order | 1 | 0/3 | 1,2,3,4,5,6,7,8,9,10 | drops 13.98 / 5.80 / -8.45, shortfall 38.68 |
| A1: exact cadence (EASY levels only in EASY slots, the MEDIUM pair swappable, HARD and VERY_HARD fixed) | 1440 | 0: 960, 1: 480 | 1,7,8,2,5,4,9,3,6,10 | 1/3: drops 6.62 / 4.41 / 15.36, shortfall 23.97 |
| A2: A1 with L1 pinned at slot 1 (FTUE level) | 240 | 0: 144, 1: 96 | same as A1 | 1/3 |
| A3 (diagnostic only, breaks the cadence): any level in any slot | 3,628,800 | 0: 2,649,120, 1: 911,520, 2: 67,680, 3: 480 | 1,5,3,6,10,4,7,9,2,8 | 3/3, but the boss L10 sits in the HARD slot and L8 is the boss |
| A4 (diagnostic only, breaks the cadence): any slot, L1 at 1, L10 at 10 | 40,320 | 0: 36,048, 1: 4,224, 2: 48 | 1,5,3,6,7,4,8,9,2,10 | 2/3: drops 15.36 / 8.23 / 15.07 |

Why A1 is capped at 1 of 3, shown analytically:

- **5 -> 6:** slot 5 must hold L5 (29.4), and the easiest level is L2 (22.1). The largest possible drop is 7.3, which is below 20. This guard can never pass.
- **3 -> 4 and 8 -> 9:** a 15-point drop needs L3 (38.9) in the peak slot and L2 (22.1, the only level at or below 23.9) in the following recovery slot. With L8 (28.7) as the peak, the largest drop is 6.6. Only one of the two guards can get L2, so they cannot both pass.

The best A1 order passes only 8 -> 9. To do that it moves the largest board L3 (38x38) to slot 8, puts L7 and L8 into early slots, and drops the 3 -> 4 guard to a 6.6 drop. A3 and A4 reach 2 or 3 passes only by putting EASY-declared levels into the HARD or VERY_HARD slots, which breaks CLAUDE.md 11.1. **Under the exact cadence, option A cannot get the shipped pack past more than one guard, and it would move the largest board into a late slot.** Rejected.

## 4. Option B: recovery constraints for future Level Factory generation

These are rules that CampaignBuilder could use when it fills recovery slots 4, 6 and 9 (and next-cycle slot 1) from the accepted pool. All of them are measured on actual v2 D and vectors, never on target D:

1. Recovery D must be at most the peak D minus the guard minimum (`recoveryGuards`). This rule only becomes satisfiable after the lane scale and the guard units are reconciled with the v2 D scale (SB-M36-013).
2. Following the component evidence in section 1: the recovery must not exceed the peak on A or on B (the 8 -> 9 inversion is driven by A and B), and must not exceed it on both B and U (docs/11 section 8 already has this rule).
3. Session Load must be lower than at the peak (docs/11 section 11). On the current 32x32 pack this means a smaller board or fewer ACTIVE cells, for example 24..28 per side for slots 4, 6 and 9.
4. Peaks must be measured with the policy ensemble, not the oracle (L5 shows a gap of 15.6 between the two). Candidates for slots 5 and 10 should be chosen for high A and B under the ensemble, not only for colour count.
5. The novelty and profile rules in docs/10 section 13 and docs/11 section 8 stay as they are.

Rules 2..5 are usable now as soft generator preferences. Rule 1, the hard guard, depends on SB-M36-013. Until then, the shipped data shows (section 3) that the minimum of 20 is unreachable for any HARD peak the v2 scale currently produces.

## 5. Option C: keep the shipped order, rescale the guards with the lanes

Most of the failure comes from the scale, and the guard minimums and the lane scale (20/40/58/76) were never calibrated jointly with v2 D. Under option C:

- the shipped First 10 order stays unchanged;
- RECOVERY anomalies stay reported as diagnostic, as they already are under v2 (docs/11 section 13, gate item 5 partly met);
- `level_progression_v1.json` and its `recoveryGuards` stay byte-identical (CLAUDE.md 11.3);
- the guard minimums are rescaled in the versioned `level_progression_v2.json` of SB-M36-013, keeping the v1 ratio of minimum to target drop (15/21, 20/40, 15/23). The guards and the lanes are both in lane-target points, so they have to move together.

## 6. Recommendation (approved by the owner pre-approval of 2026-10-26)

**Option C together with option B.** Concretely:

1. Do not reorder the shipped First 10. Option A is capped at 1 of 3 guards under the exact cadence (section 3).
2. SB-M36-013 builds `data/config/level_progression_v2.json`. It rescales the lanes to the measured v2 D scale and rescales `recoveryGuards` with the ratio rule from section 5. v1 stays untouched.
3. SB-M36-014 adds the option B rules 2..4 as per-pair recovery checks on actual v2 vectors: recovery not above the peak on A or B, not above it on both B and U, and Session Load below the peak. They are reported next to the scalar guards in the `tools/difficulty_playtest.gd` recovery output. The same rules are recorded as CampaignBuilder recovery-slot constraints in docs/10 section 13.
4. The L8 -> L9 inversion is a content finding. If L8 or L9 is ever replaced, the replacement goes through the step 3 checks. No catalog change is made now.

Reasons, all from measured data:

- Two of the three failures (5 -> 6 fully, 3 -> 4 by 1.0 D) are scale effects. The recoveries fall in the right direction, but the minimums are in lane points that v2 never reaches.
- A scalar guard alone cannot tell scale from content. The component checks (step 3) catch the 8 -> 9 kind of inversion, where the recovery is harder on A and B, on any scale.
- Option A cannot meet the guards within the exact cadence of CLAUDE.md 11.1.

## Appendix: permutation script

Run it with `python recovery_perms.py coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json`. It is not committed as a tool; it reproduces the section 3 table.

```python
import json, sys, itertools
d = json.load(open(sys.argv[1]))
L = {l["order"]: l for l in d["levels"]}
D = {k: v["challengeScore"] for k, v in L.items()}
SL = {k: v["sessionLoad"] for k, v in L.items()}
GUARDS = [(3, 4, 15.0), (5, 6, 20.0), (8, 9, 15.0)]
EASY_SLOTS = [1, 2, 4, 6, 7, 9]

def evaluate(seq):  # seq[slot-1] = level number placed in that slot
    drops = [D[seq[a-1]] - D[seq[b-1]] for a, b, _ in GUARDS]
    passes = sum(dr >= m for dr, (_, _, m) in zip(drops, GUARDS))
    short = sum(max(0.0, m - dr) for dr, (_, _, m) in zip(drops, GUARDS))
    return passes, short, drops

def search(name, seqs):
    best, n, hist = None, 0, {}
    for s in seqs:
        n += 1
        p, sh, dr = evaluate(s)
        hist[p] = hist.get(p, 0) + 1
        key = (-p, sh)
        if best is None or key < best[0]:
            best = (key, s, dr)
    (_, sh), s, dr = best
    print(name, n, dict(sorted(hist.items())), list(s), -best[0][0], round(sh, 2),
          [round(x, 2) for x in dr], D[s[9]] == max(D.values()))

def class_preserving(pin_l1):
    easy = [2, 4, 6, 7, 9] if pin_l1 else [1, 2, 4, 6, 7, 9]
    slots = EASY_SLOTS[1:] if pin_l1 else EASY_SLOTS
    for ep in itertools.permutations(easy):
        for mp in itertools.permutations([3, 8]):
            seq = [0] * 10
            if pin_l1: seq[0] = 1
            for sl, lv in zip(slots, ep): seq[sl-1] = lv
            seq[2], seq[7], seq[4], seq[9] = mp[0], mp[1], 5, 10
            yield seq

print("shipped", evaluate(list(range(1, 11))))
search("A1", class_preserving(False))
search("A2", class_preserving(True))
search("A3", itertools.permutations(range(1, 11)))
search("A4", (s for s in itertools.permutations(range(1, 11)) if s[0] == 1 and s[9] == 10))
```
