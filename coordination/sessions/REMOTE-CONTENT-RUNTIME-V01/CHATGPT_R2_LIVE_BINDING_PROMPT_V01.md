# CP07/M18 — SCRUBBOTS R2 LIVE READ-ENDPOINT BINDING — V01

Status: PREPARED / WAITING_FOR_FIRST_FACTORY_R2_PUBLISH
Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:/Users/sekip/Desktop/ScrubBots`

## Provisioned authority

Provider: Cloudflare R2
Bucket: `scrubbots-content-prod`
Family Test public read root:
`https://pub-dd36dd94999d4beaad95d6409ad0167e.r2.dev`

R2 is public-read only from the game. **No write/API credential may be committed, logged, embedded in the APK or added to Godot config.**

## BLOCKING INPUT

Do not execute the live-binding portion until the canonical Level Factory / Pixel Art Factory publisher has completed its first real R2 publish and supplied:
1. exact manifest object key;
2. exact pack object keys referenced by that manifest;
3. manifest SHA/content_version/minimum_game_version;
4. evidence that every referenced object is readable from the public R2 endpoint;
5. confirmation that publisher secrets exist only in the publisher-side secret environment.

Do not invent or rename an object prefix in this repo.

## Safe sync / governance

Before work:
- inspect current branch, status, HEAD, origin/main, ahead/behind and untracked files;
- non-destructively sync owner-local checkout with latest origin/main;
- preserve `project.godot`, `scenes/app/main.tscn`, `addons/`, `.mcp.json` and unrelated owner files;
- no reset --hard, git clean, force checkout/push or destructive overwrite;
- root `TASKS.md` is read-only for Claude.

## Binding contract

After the first real publisher evidence exists:

- Set `manifest_url` to the exact public HTTPS URL for the published manifest.
- Set `object_base_url` so that the existing transport expression
  `object_base_url + "/" + object_key`
  resolves every canonical manifest pack `object_key` to its actual R2 public URL.
- Keep URLs non-secret and HTTPS-only.
- Do not change the existing strict URL gate.
- Do not add headers, tokens, cookies, signed URLs or write authority.
- Do not enable redirects.
- Keep all content under the existing declarative `.scrubpack` validation path.

Do not hard-code assumptions such as `production/` unless the canonical publisher actually emitted those keys.

## Enablement

Do not blindly flip production remote content on before the full live-read contract is valid.

The Family Test build may use `enabled=true` only when:
- the manifest object exists and parses;
- every referenced pack object is publicly readable;
- `application/config/version` is a strict semantic version compatible with the manifest;
- the existing RemoteContentManager tests remain green.

If the current repository still intentionally lacks `application/config/version`, either:
- leave the shipping config disabled and provide a deterministic live-integration harness with an injected valid game version, or
- defer the final `enabled=true` flip to the Android Family APK task.

Do not weaken the existing fail-closed `GAME_VERSION_UNAVAILABLE` behavior.

## Live R2 integration proof

Using only public GETs and the real published objects, prove:

1. manifest URL returns HTTP 200;
2. manifest passes current strict parser;
3. every referenced pack URL resolves from `object_base_url + object_key`;
4. expected byte length and SHA-256 match;
5. pack passes safe ZIP + scrubpack + LevelData + supply + metadata validation;
6. first refresh installs only missing pack(s);
7. second refresh downloads nothing and reports up-to-date;
8. offline relaunch exposes the LKG cached remote level(s);
9. corrupt/unavailable successor does not replace LKG;
10. builtin Levels 1–10 remain unchanged;
11. no executable content path is introduced.

Prefer a dedicated, deterministic live-integration test/harness that can be skipped only when explicitly invoked without network. Never weaken permanent offline suites.

## Regression

Required:
- CP04 suite PASS;
- CP05 suite PASS;
- CP05-R01 PASS;
- remote family fixture PASS;
- M53 exact determinism PASS;
- root tests ALL PASS;
- `git diff --check` clean;
- no new unexplained errors.

## Log

Write:
`coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CP07_R2_LIVE_BINDING_CLAUDE_LOG_V01.md`

Include:
- exact first published manifest URL;
- exact object-base URL;
- content version and public object-key examples;
- no-secret assertion;
- live HTTP/hash/validation results;
- regression results;
- final branch SHA.

Finish:
`AWAITING_GPT_CP07_R2_LIVE_BINDING_AUDIT`
