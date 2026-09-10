# M19-C001 — Owner-Directed Final Closure Materialization

Authority: `coordination/sessions/M19-C001/CHATGPT_AUDIT_V06.md`
Audit verdict: **AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**

Status: **OWNER-DIRECTED CONTRACT EXPANSION — root TASKS.md is the sole live tracker**

This is not another implementation/audit cycle. The owner explicitly requires repository-root `TASKS.md` to be the single live H!veAI/project-status tracker.

Final closure therefore includes all necessary governance reconciliation:

1. root `TASKS.md`: close SB-M19-001..012, set progress to 290/719 = 40.33% main+ui and 290/943 = 30.75% overall, set lastCompletedTaskId M19-C001-V06, and move the current frontier to M20-C001-PREP / READY_FOR_NEXT_TASK / actor CHATGPT;
2. root `TASKS.md`: replace the embedded stale `.hiveai/TASKS.md` authority notice;
3. `AGENTS.md` and `CLAUDE.md`: remove live `.hiveai` authority instructions and point current-state reads/writes only to root `TASKS.md`;
4. `coordination/README.md`, `coordination/AUDIT_POLICY.md`, and `coordination/VERSIONED_LOG_POLICY.md`: remove dashboard/session-index/derived-tracker current-state ownership and make root `TASKS.md` the sole live tracker while preserving independent audit separation;
5. `docs/migration/legacy-task-trackers/README.md`: mark archived tracker files historical/read-only;
6. never recreate `.hiveai/*` as a competing tracker;
7. do not modify gameplay production or tests for this administrative closure.

M19 production remains locked to accepted V05 dispatcher blob `0d1a6b1f6e9a6f1788ceb2078473c87bec8986e3`; V06 evidence remains commit `77d5359c4482a816e3d2e2ca7481ec1fdb7ed8af` with 3273/3273 Godot 4.7.1 checks.

Once these governance/tracker changes are on `origin/main`, this materialization is complete. Do not begin M20 implementation until ChatGPT performs the M20 full attack-surface sweep and publishes the canonical M20-C001 V01 prompt/criteria.
