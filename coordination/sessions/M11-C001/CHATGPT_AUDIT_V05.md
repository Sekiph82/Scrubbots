# M11-C001 — ChatGPT Independent Audit V05

Decision: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**

Audited implementation commit:
`bcd4ac50df30df95fb11b87dd111ff865029cb10`

Active prompt:
`coordination/sessions/M11-C001/CHATGPT_PROMPT_V05.md`

Criteria:
`coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V05.md`

Claude evidence:
`coordination/sessions/M11-C001/CLAUDE_LOG_V05.md`

Frozen basis:
`coordination/sessions/M11-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`

Audit policy:
`coordination/AUDIT_POLICY.md`

## Independence / runtime disclosure

Claude reports Godot 4.7.1 and **1835 / 1835 ALL PASS**. This is E1/E2
implementation evidence.

Godot is not available in the ChatGPT audit environment, so the runtime suite
was **not independently rerun**. ChatGPT independently inspected the exact
implementation commit, production source, changed tests and test doubles as E3
source/diff evidence.

No new material production-code defect was found in the V05 implementation.
However, strict-v2 direct-observability/sensitivity requirements are not fully
satisfied by the current adversarial tests, so final closure is not yet allowed.

## Frozen finding review

### F-M11-STRICT-001 — implementation CLOSED, validation incomplete

Production source now:
- stores a detached internal LevelData copy;
- duplicates both packed fields (palette and cells);
- builds BoardState from that internal source;
- returns a detached snapshot from get_level_data();
- preserves the prior session on failed LevelLoader result.

The hostile snapshot test directly covers scalar mutation, packed-array
replacement and in-place packed-array mutation.

**Remaining proof gap:** the V05 prompt explicitly requires a **new
get_level_data snapshot after reset** to still match original source truth.
M11-29 checks a new snapshot before reset, then checks BoardState after reset,
but does not fetch and compare the required post-reset snapshot.

Also strengthen failed-replacement source-truth coverage to compare all LevelData
fields, including version, display_name, difficulty and palette, not only the
current partial subset.

### F-M11-STRICT-002 — implementation CLOSED, sensitivity gap

Production bind_renderer() rejects non-BoardRenderer values before storing or
configuring them and null explicitly unbinds.

The malformed-value rejection checks and fake.configure_calls == 0 are good.

**Remaining proof gap:** the assertion intended to prove that a previously valid
renderer binding survives malformed replacement is not sensitive. The renderer
was already configured before the malformed attempts, so checking
get_cell_size() > 0 after reset can remain green even if the valid binding had
actually been lost and reset never reconfigured it.

Use a real BoardRenderer subclass with configure-call counting. After malformed
replacement attempts, reset must increment the ORIGINAL renderer's configure
count. Null unbind must then prevent a further increment.

### F-M11-STRICT-003 — implementation CLOSED, direct-observability gap

Production _is_valid_size() correctly requires both dimensions finite and
strictly positive, and bind_renderer() returns before storing/configuring on an
invalid size.

V05 directly checks rejection return values for NaN/+INF/-INF/zero/negative.

**Remaining proof gap:** the test claiming that invalid geometry never reached
BoardRenderer.configure is not sensitive:

`get_cell_size() <= 0 or not is_inside_tree()`

A newly-created renderer is not inside the scene tree regardless of whether
configure() was called, so this branch can make the assertion green for the
wrong reason.

Use a real counting renderer spy and prove configure-call count remains
unchanged for every invalid-size case. Cover invalid values in both x and y.
Also prove an invalid-size replacement cannot displace a previously valid
renderer/size.

### F-M11-STRICT-004 — implementation CLOSED

Before configure, production checks is_instance_valid(), clears a stale renderer
and continues headlessly. V05 exercises:
- bind -> load -> free -> reset;
- bind -> free -> valid load.

Both lifecycle operations are reported green. E3 source inspection confirms the
stale binding is explicitly cleared. V06 should additionally prove the session
can bind/configure a fresh renderer after this stale-renderer path, to establish
lifecycle reuse directly.

### F-M11-STRICT-005 — implementation CLOSED, rebind path not directly proven

Production passes `_level_data.palette.duplicate()` and never passes LevelData
to BoardRenderer.

M11-33 proves source palette survives renderer mutation followed by reset.

**Remaining proof gap:** V05 explicitly required isolation across initial
configure, reset/reconfigure **and renderer rebind**. The current test does not
exercise renderer rebind.

V06 must mutate the first renderer's retained palette, rebind a second real spy,
and prove source truth remains original; then mutate the second spy and reset and
prove it again.

## Full post-fix attack-surface result

E3 source inspection found no new M11-owned material implementation defect in:
- lifecycle transition rules;
- failed load atomicity;
- fresh BoardState reset;
- live BoardState exposure;
- detached LevelData source ownership;
- renderer type boundary;
- finite positive size boundary;
- stale renderer handling;
- palette presentation seam;
- rectangular / 59x59 responsibility;
- M12+ scope leakage;
- automatic win/lose/timer/move-limit behavior.

The remaining issues are **validation sensitivity/coverage gaps**, not a newly
expanded frozen production finding set.

Frozen findings remain:
- F-M11-STRICT-001
- F-M11-STRICT-002
- F-M11-STRICT-003
- F-M11-STRICT-004
- F-M11-STRICT-005

No new production finding ID is added.

## Governance

Commit bcd4ac50 changes only:
- gameplay_session.gd;
- tests/run_tests.gd;
- two test support files;
- matching CLAUDE_LOG_V05.md.

Claude did not modify tasks.md, H!veAI, SESSION_INDEX, AUDIT_INDEX, ChatGPT
audit artifacts or strict queue/sequence controllers.

Matching V05 Claude log exists and Claude returned AWAITING_AUDIT without
self-auditing.

## Verdict

**CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**

Do not reopen additional M11 tasks. Keep open:
- SB-M11-003
- SB-M11-005
- SB-M11-009
- SB-M11-012

Canonical progress therefore remains:
- Ecosystem: **265 / 943 = 28.10%**
- Main + UI: **265 / 719 = 36.86%**
- Level Factory: **0 / 112**
- Content Pipeline: **0 / 112**

Next:
`coordination/sessions/M11-C001/CHATGPT_PROMPT_V06.md`

V06 is validation-heavy. Production gameplay source should remain unchanged
unless the strengthened tests expose a real defect.
