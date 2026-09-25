# OWNER M42 OPENING PLAYBACK FREQUENCY DECISION V01

Status: OWNER LOCKED
Date recorded: 2026-09-25
Scope: SB-M42-031 — Opening cinematic playback frequency

## Decision

The ScrubBots opening cinematic plays on app startup / native restart only.

For V1:
- play once per cold/native app launch;
- completing or skipping the cinematic enters the normal Home/bootstrap flow;
- normal internal scene navigation must not replay it;
- Retry must not replay it;
- returning from gameplay/Home/settings or other in-app screens must not replay it;
- app minimize/background -> foreground must not replay it merely because focus resumed;
- a true native app restart/cold launch starts a new launch session and may play it again.

This is launch-session state, not gameplay/save/economy progression truth.

## Closure effect

SB-M42-031 is no longer an unresolved design gate. Claude may implement and test this exact V1 frequency contract during M42.
