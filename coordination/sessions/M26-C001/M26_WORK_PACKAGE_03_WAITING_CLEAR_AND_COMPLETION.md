# M26 Work Package 03 — WAITING, Authenticated Clear & Completion
Tasks: SB-M26-018..023

Implement event-driven WAITING/wake and post-clear quota finalization.

Required:
- no-target claim attempt produces WAITING and no robot;
- no busy-loop/repeated reservation churn while nothing authoritative changed;
- wake on successful batch placement, authenticated clear/reachability change, and resume;
- add only the minimal M20 post-commit authenticated-clear notification needed by M26;
- notification emitted only after M20 successful CLEARED transaction;
- exact owner/target/color/agent identity;
- no notification on failed/rolled-back/reset transactions;
- if production M26 would otherwise require a fake historical SlotSystem, add a minimal arrival-only M20 bind seam while preserving the old bind/activate path;
- M26 maps authenticated clear to exact scheduler assignment/claim and calls M25.finalize_clear once;
- duplicates/stale notifications fail closed;
- final clear empties the M24 slot without shifting neighbors or mutating M23 supply;
- newly freed slot remains usable for later placement.
