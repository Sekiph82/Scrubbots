# M23-C001 V02 — Strict Audit Criteria

Cycle: `M23-C001 V02`
Milestone: `M23 — Batch Supply Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Auditor: ChatGPT
Prior audit: `coordination/sessions/M23-C001/CHATGPT_AUDIT_V01.md`
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

## 0. Verdict policy

V02 passes only if every V01 blocking finding is closed in real production code and direct tests. Passing existing tests alone is insufficient.

M24-M27 remain out of scope.

## 1. Governance

- Work only in `Sekiph82/Scrubbots` `main`.
- Safe sync; preserve owner-local work.
- Root `TASKS.md` is read-only for Claude.
- Implementation commit first, `CLAUDE_LOG_V02.md` second.
- No image-generation credits.
- No protected M22 routing/target/reservation/dispatcher/clearing rewrite.

## 2. Exact transaction-instance authenticity

The engine must reject a forged same-class transaction object even when it carries a currently valid open token ID.

Required direct tests:

1. open transaction A and B;
2. construct a fresh `BatchSelectionTransaction` carrying A's live token ID;
3. forged `commit()` returns false and changes no column;
4. forged `cancel()` returns false and changes no column/open-token ownership;
5. same attack using B's ID cannot commit/cancel B;
6. changing fields on A cannot redirect it to B or another column;
7. original A can still commit after failed forge attempts, unless the test deliberately cancels it;
8. double commit/cancel, stale-front, reset-stale and ordinary malformed types remain fail-closed.

Acceptable implementation patterns include exact RefCounted object identity or immutable engine-owned instance ID/nonce. A caller-constructible numeric/string token value alone is not sufficient.

`has_open_transaction()` must not report a forged same-class object as owning another transaction.

## 3. Queue-load trust-boundary validation

`load_columns()` or its replacement must revalidate observable batch values before they enter engine-owned state.

Required:

- String non-empty batch ID;
- globally unique batch ID across live candidate;
- integer color ID >= 0;
- positive integer quota;
- palette-bound color ID when palette size is known;
- no partial mutation on any failure.

Direct adversarial tests must include a real `ColorBatch` object that was made invalid after construction or directly instantiated and field-mutated. `is ColorBatch` alone is not an acceptance proof.

Failure must preserve the prior valid engine snapshot byte-for-byte/logically.

## 4. Atomic candidate metadata / reset truth

The active candidate's initial state must include at least:

- exact columns and batch order;
- seed;
- palette size.

`reset()` must restore all of those values and invalidate every pre-reset transaction.

Prefer an atomic candidate-load/configuration API so queue + metadata cannot temporarily disagree.

If mutable public metadata setters remain, direct tests must mutate them and then prove reset restores the original candidate values. If those setters are removed/restricted, tests must prove no ordinary gameplay seam can rewrite committed candidate metadata behind reset truth.

A failed candidate load must not partially change queue, seed, palette metadata, or outstanding valid state.

## 5. Strict LevelData source validation

Generator input must fail closed for malformed/foreign sources.

Required direct tests:

- null source;
- arbitrary `RefCounted`/foreign object;
- LevelData with zero/invalid palette;
- LevelData with a cell palette ID out of range;
- LevelData whose `cells.size()` does not equal `width * height` / `get_cell_count()`;
- zero/non-positive dimensions where constructible;
- valid rectangular LevelData still succeeds.

For valid input, generated total quota must equal `get_cell_count()` exactly and per-color conservation must remain exact.

Do not add a second color authority.

## 6. 59x59 direct conservation evidence

The 59x59 fixture must directly assert each source color total equals generated quota for that same color, not only grand total 3481.

Keep same-seed determinism and performance sanity evidence.

## 7. Preserve V01 passing behavior

All V01 passing contracts remain required:

- 3/4/5 FIFO columns;
- preview depth 3/4, V1 path depth 3;
- front-only selection;
- hidden contents not leaked by player-facing queries;
- other columns unchanged by one commit;
- deterministic positive integer partitions;
- unique batch IDs;
- Hazard Bot per-color conservation;
- detached snapshots;
- exact queue reset;
- candidate-only generation, no solvability claim.

## 8. Scope boundary

Do not implement:

- Five-Slot Batch Engine placement/lifecycle;
- Batch Target Claim Engine;
- Auto Dispatch Scheduler;
- Solvability/Deadlock Engine;
- UI/scene integration for the production batch panel.

## 9. Required validation

Run at minimum:

- `godot --version`
- full `tests/run_tests.gd`
- M23 V01/V02 dedicated evidence script(s)
- M22 V06, V05, V04, V03 evidence
- M21 real-art smoke
- M21 V10 reservation evidence
- representative M20 lifecycle/queue-free evidence
- `git diff --check`

Report exact check count/failures/exits.

## 10. Required V02 log

`CLAUDE_LOG_V02.md` must include:

- safe-sync start SHA;
- implementation SHA;
- changed-file list;
- mapping from every `F-M23-V01-STRICT-001..005` to code + direct test evidence;
- forged same-class transaction attack results;
- malformed ColorBatch load results;
- reset queue/seed/palette proof;
- malformed LevelData proof;
- 59x59 per-color totals;
- full regression results;
- `root TASKS.md modified = NO`;
- `M24-M27 implementation = NO`;
- `image-generation credits spent = 0`;
- final `AWAITING_AUDIT`.

## 11. Closure

If all criteria pass, ChatGPT may close all M23 tasks and advance the canonical tracker to M24. Otherwise M23 remains open.
