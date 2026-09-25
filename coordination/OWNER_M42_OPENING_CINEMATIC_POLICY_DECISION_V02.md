# OWNER M42 OPENING CINEMATIC POLICY DECISION V02

Status: OWNER LOCKED
Date recorded: 2026-09-25
Scope: SB-M42-030 / SB-M42-031 — opening cinematic skip + playback frequency
Supersedes: `coordination/OWNER_M42_OPENING_PLAYBACK_FREQUENCY_DECISION_V01.md` where wording conflicts with this V02.

## Owner decision

The ScrubBots opening cinematic is **mandatory and not skippable**.

Production V1 rules:

- The opening cinematic plays on **every cold/native app launch**.
- A true native app restart starts a new launch session and the cinematic plays again.
- There is **no Skip button**.
- Tap/click does **not** skip the cinematic.
- Android Back / iOS navigation gestures do **not** skip the cinematic.
- There is no first-launch exception and no delayed skip.
- The only normal path out of the cinematic is successful completion.
- Decode/load/play failure may still use the existing fail-safe path to Home so startup can never be permanently blocked.
- Internal scene navigation, Retry, returning from gameplay/Home/settings, or background/foreground resume do not count as a new app launch and therefore do not replay the cinematic.

The cinematic does not mutate save/game/economy state.

## Closure effect

- SB-M42-030 owner design gate is resolved as **NO SKIP**.
- Existing M42 implementation already exposes no skip control/input, so no remediation/code change is required for SB-M42-030.
- SB-M42-031 remains consistent with the owner rule: once per cold/native launch means the cinematic plays on every actual app launch, not on internal transitions.
