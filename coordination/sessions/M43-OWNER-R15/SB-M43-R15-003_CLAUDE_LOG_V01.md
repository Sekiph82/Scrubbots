# SB-M43-R15-003 — DAILY REWARDS CONTAINMENT REMEDIATION — CLAUDE LOG V01

Prompt: `coordination/sessions/M43-OWNER-R15/CHATGPT_PROMPT_V01.md` §3.
Code commit: `24828bb`. Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit.

## Root cause (owner F5 screenshot, 683×1366)

683×1366 is rendered by the real app on the 1080×2160 logical canvas (stretch canvas_items / expand). The large popup frame is 880 px wide, which leaves a 652 px body inside its patch insets. Two things broke out of it.

**Grid overflow.** The Daily grid needed 3 × 240 px cards plus gaps, about 736 px. Its minimum width forced the popup body wider than the frame, so:
- the day-card grid and the CLAIM / CLOSE buttons spilled past the frame's right border;
- reward text wrapped and clipped inside 180 px columns.

**Floating hero.** The calendar was a `set_hero` overlap, which by design draws above the frame. That put it outside the popup, over the WHISPERING PARK sign.

## Files changed

| File | Change |
|---|---|
| `scripts/ui/daily/daily_screens.gd` | Layout only, in `open_daily` / `_day_card` / `refresh_daily`. |
| `tests/m43_r15_owner_remediation.gd` | Cases d01–d03. |

**Header**
- **Hero:** no hero above the frame. The calendar is a contained 132×132 icon at the top of the content area.
- **Streak:** flame (52) + "Consecutive Login Days: N" form one centred pair, so the flame no longer sits stranded at the far left.

**Day cards**
- **Size:** fixed **210×280**. Three cards and two 8 px gaps make 646 px, which is ≤ the 652 px body, so the grid can never widen the popup.
- **Insets:** chosen so no label touches the card art: 26 px sides, 46 px top (56 px for the Day 5 crown), 30 px bottom.
- **Check:** moved into the card's title row (`[spacer | DAY n | check]`), so it never adds a row. It is shown by alpha only on claimed cards and stays inside the card.
- **State text:** 18 pt, so "CLAIMED TODAY" fits on one line. Rule text and CLAIM / CLOSE sit below the grid.

The fixed size is sized for the longest real state: Day 5 claimed today, with a four-line reward plus the state and the check.

**Unchanged:** consecutive-login count, the D1..D5 repeating cycle and configured rewards, one claim per local day, reset / rollback safety, the claim authority (`claim_daily_login`), the reward celebration popup and the claimed / today / upcoming states.

**Rejected approach:** I tried 200 px cards with 20 px insets. They passed geometry but the text visibly touched the card rims in the rendered frames, so I chose 210 px with 26 px insets.

## Focused tests

`tests/m43_r15_owner_remediation.gd` → **PASS 17/17** (this child: d01–d03).

- **d01:** the Daily popup has no visible hero. Calendar, Flame and Streak sit inside the frame content rect (the FrameBox rect minus its patch insets).
- **d02:** under a stress state (every card shows its check and "CLAIMED TODAY", plus Day 5's four-line reward), at **683×1366** and 720×1280, 1080×1920, 1080×2160, 1170×2532, 1290×2796 and 1536×2048:
  - the frame is on screen;
  - Calendar / Flame / Streak / grid / rule are inside the frame content;
  - every card is exactly 210×280 and inside the frame;
  - every DayLabel / RewardText / State / Check is inside its card's inset content rect, and no label is clipped;
  - CLAIM / CLOSE are inside the frame, and neither they nor the rule overlap the card grid.
- **d03:** the real popup shows D1 `today` with the configured reward. CLAIM gives +100 SB, streak 1 and the reward celebration. The check shows only on the claimed card.

**Tasks / Gift Bar no regression:** `tests/m43_master_c009_daily.gd` **PASS 12/12** and `tests/m39d_daily_collection.gd` **PASS**.

## Evidence

`coordination/sessions/M43-OWNER-R15/evidence/7_daily_rewards_fixed_<size>.png` at 683×1366, 720×1280, 1080×1920, 1080×2160, 1170×2532, 1290×2796 and 1536×2048 (real app root, rendered at the logical canvas, saved at the physical size).

## Remaining owner gates

- Owner visual acceptance of the contained Daily composition.
- Not changed, and outside this child: the separate Daily reward *celebration* popup (`ceremony_daily`) still uses the shared Results-family hero overlap. The owner did not flag it.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-R15-003
