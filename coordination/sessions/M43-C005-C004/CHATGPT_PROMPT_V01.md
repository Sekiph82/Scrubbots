# M43-C005-C004 — BOOSTER-OF-YOUR-CHOICE PRODUCTION ASSET

Status: **READY FOR CLAUDE**  
Date: 2026-10-03  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical parent task: **SB-M43-076**  
Purpose: close the final supporting visual-asset gate for M43-C005.  
Root `TASKS.md`: **READ ONLY — ChatGPT owns it.**

## 0. Sync safely first

Work from the canonical checkout:
`C:\Users\sekip\Desktop\ScrubBots`

Before material work:
1. `git fetch origin main --prune`;
2. compare local `main` with `origin/main`;
3. synchronize non-destructively;
4. preserve every owner-local modification/untracked file;
5. never use destructive reset, clean, checkout-overwrite or force push.

The 135 Collection cards at commit
`f17d28a0b8197cde6f95ec4a6bd155df92e199c5`
are now canonical. **Do not regenerate, crop, slice, revert, recolor or replace them.**

## 1. Read before working

Read:
- `CLAUDE.md`;
- root `TASKS.md` read-only;
- `coordination/AUDIT_POLICY.md`;
- `coordination/sessions/M43-C005-C003/CHATGPT_AUDIT_V01.md`;
- `coordination/sessions/M43-C005-C001/OWNER_VISUAL_DECISION_V02.md`;
- `coordination/sessions/M43-C005-C001/CEREMONY_ASSET_INVENTORY_V01.md`;
- `assets/ui/VISUAL_ASSET_INDEX.md`.

Inspect the four canonical booster assets and record their hashes before any work:
- `assets/ui/final/boosters/extra_slot.png`
- `assets/ui/final/boosters/random.png`
- `assets/ui/final/boosters/selector.png`
- `assets/ui/final/boosters/tornado.png`

## 2. Product meaning lock

Create one production-quality **Booster of Your Choice** reward icon.

It means:

> The player receives the right to choose exactly one of the four existing canonical boosters.

It must **not** mean:
- random booster;
- mystery reward;
- reroll;
- fifth booster type;
- automatic booster execution;
- shop purchase;
- a new economy resource.

There remain exactly **four** canonical boosters. Do not add a booster key to configuration, inventory, save data, services, analytics authority or gameplay logic.

## 3. Visual contract

Use the **actual four canonical booster artworks** as the identity authority. Prefer deterministic composition/reduction from those approved assets so their identities remain exact.

Create a single coherent SCRUBBOTS-family reward emblem in which all four booster identities remain recognizable at mobile size. Use a clear selection/focus motif to communicate “choose one”.

Hard locks:
- **no question mark**;
- no dice, shuffle or other random symbol;
- no baked text;
- no fake fifth icon;
- no redesign/replacement of the four booster artworks;
- transparent background;
- clean silhouette and readable small-size hierarchy;
- no neighboring UI baked into the icon.

Inspect current final reward/icon conventions first and use the repository’s established square master sizing/export convention rather than inventing a conflicting one.

Candidate path:
`assets/ui/candidates/m43_c005/booster_choice/booster_of_choice_v01.png`

Do **not** self-promote it to final before the owner gate.

Intended final path after approval:
`assets/ui/final/rewards/booster_of_choice.png`

## 4. Review evidence

Create:
- `coordination/sessions/M43-C005-C004/OWNER_BOOSTER_CHOICE_REVIEW_V01.md`
- `coordination/sessions/M43-C005-C004/BOOSTER_CHOICE_ASSET_MANIFEST_V01.json`
- `coordination/sessions/M43-C005-C004/CLAUDE_LOG_V01.md`
- review PNG(s) under `coordination/sessions/M43-C005-C004/evidence/`.

Owner-review evidence must show:
1. candidate at native size;
2. candidate reduced to representative small UI sizes;
3. candidate beside the four canonical source boosters;
4. Gift Meter 500/1000 reward-row preview using the candidate instead of the temporary native `?` chip.

The preview is presentation-only. Do not change Gift reward truth or grant behavior.

## 5. Validation

Prove:
- candidate is a valid transparent RGBA production asset;
- no baked text;
- all four canonical booster source files are byte/hash unchanged;
- Collection card files from C003 are unchanged;
- exactly four canonical booster identities still exist;
- no new booster/economy/save key was added;
- no grant, reward, inventory or gameplay authority changed;
- Gift 500/1000 preview remains truthful;
- Reduced Effects changes no reward information;
- `git diff --check` passes.

Run the focused M43 ceremony preview regression and the relevant economy/booster invariants. Run the root suite if the touched surface or repository governance requires it.

## 6. Scope locks

Do not:
- edit root `TASKS.md`;
- modify any of the 135 new Collection cards;
- touch Standard/Premium pack assets;
- begin SB-M43-063..075/077 runtime ceremony implementation;
- implement M43-C005F plugin feel work;
- add a fifth booster;
- change Gift rewards;
- use paid external image APIs.

If a production-quality candidate cannot be made from the approved local assets with available tools, stop and report the blocker instead of shipping a weak placeholder.

## 7. Publish / return

Commit and push only authorized C004 asset/evidence changes to `origin/main`.

Return:
- final commit SHA;
- candidate asset GitHub URL;
- owner-review GitHub URL;
- manifest/log URLs;
- source booster hash preservation proof;
- focused/regression results;
- blockers, if any.

Finish exactly:

`AWAITING_GPT_M43_C005_C004_BOOSTER_CHOICE_ASSET_AUDIT`
