# SB-VOID-C001 — ChatGPT Strict Audit V01

Date: 2026-10-08  
Repository: `Sekiph82/Scrubbots`  
Audited implementation: `7d0d148b8609ec04852fdee02f6b8ef37598c616`  
Builder evidence: `coordination/sessions/VOID-CELLS-C001/CLAUDE_LOG_V01.md`

## VERDICT

**PASS / CLOSED**

The owner-approved transparent-artwork -> VOID gameplay contract is implemented on current `main` and is sufficient to open the dependent Level Factory VOID integration gate.

## Contract recovery

Owner decisions applied:

- D1: VOID renders exactly like CLEARED, showing BG01 `#202533`, with no grid/border.
- D2: production artwork requires >= 200 non-VOID cells and >= 25% of W*H.
- board envelope remains 20..59.
- transparent pixels are never filled with a color.

## Data format

PASS.

- Legacy opaque levels remain `version: 1`.
- VOID levels use `LevelData.FORMAT_VERSION_VOID := 2`.
- VOID is encoded as `LevelData.VOID_CELL := -1`.
- V1 with `-1` rejects.
- V2 without VOID rejects, preserving one canonical encoding.
- all-VOID levels reject.

Note: `LevelData.FORMAT_VERSION` intentionally remains `1` for legacy V1 authority while `FORMAT_VERSION_VOID` is the V2 capability constant. This satisfies the owner compatibility requirement more precisely than globally redefining every level as V2.

## Runtime semantics

PASS.

- `BoardState.from_level_data` initializes VOID as CLEARED.
- VOID cannot be reactivated, including Retry/restore.
- ColorCandidateIndex excludes VOID.
- Existing target/access routing consumes the CLEARED/open initial state rather than inventing a VOID shortcut.
- sealed-hole and corridor fixtures prove no teleport behavior.
- live ProductionGameplayHost replay reaches WIN with VOID present.

## Supply / solver / completion

PASS.

- supply color totals ignore VOID;
- grand conservation equals artwork/non-VOID count;
- plans paying for VOID reject;
- ProofState starts VOID as CLEARED_BYTE;
- solver canonical key remains deterministic;
- solver/replay fixtures are SOLVED;
- completion/WIN operates over artwork while supply/slots retain normal authority.

## Difficulty V1

PASS.

- Difficulty V1 measurements use artwork count where the old full-cell count would be wrong;
- peel/access and color-layer calculations are VOID-aware;
- VOID provenance is added only for VOID levels;
- legacy V1 calibration evidence remains byte-identical according to the committed regression;
- no anchor recalibration was fabricated without production evidence.

The separate experimental Difficulty V2 candidate analyzer remains outside this task and is not production authority.

## Import / builder / renderer

PASS.

- ProductionArtLevelBuilder maps alpha 0 to VOID;
- alpha 1..254 rejects;
- opaque artwork stays V1;
- reconstruction renders VOID transparent;
- D1 requires no renderer rewrite because the existing CLEARED transparent path already supplies the correct presentation, and the new test proves equivalence.

The legacy generic importer may still preserve raw import identity before production normalization; the production builder is the authoritative transparent->VOID conversion path for this contract.

## Remote content

PASS.

- Scrubpack runtime accepts validated V2 VOID levels;
- optional `artworkCellCount` / `voidCellCount` metadata is checked against level truth;
- wrong metadata and supply that pays for VOID reject.

## Regression evidence

Builder evidence reports:

- root suite: **5329 / 5329 PASS** before and after;
- new VOID suite: **186 assertions PASS**;
- solver/supply/completion/catalog/difficulty/remote-content focused suites PASS;
- current V1 difficulty calibration corpus unchanged;
- clean-checkout verification PASS.

Repository inspection confirms the implementation and evidence files exist on current `main`.

## Follow-up boundary

The following are intentionally separate:

1. **Level Factory** must now emit/solve/export/publish V2 VOID levels end-to-end.
2. Experimental Difficulty V2 candidate analyzer is not VOID-aware and remains non-production follow-up.

Neither blocks SB-VOID-C001 closure.

## FINAL

**PASS / CLOSED**

Dependent Level Factory gate may now open against exact game commit:

`7d0d148b8609ec04852fdee02f6b8ef37598c616`
