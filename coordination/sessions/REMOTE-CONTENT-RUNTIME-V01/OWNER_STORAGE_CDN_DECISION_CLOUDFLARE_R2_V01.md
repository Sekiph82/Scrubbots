# Remote Level Update — Storage/CDN Owner Decision V01

Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`

## OWNER DECISION

**Cloudflare R2 is LOCKED as the canonical storage/CDN provider for ScrubBots Remote Level Update.**

This decision replaces the earlier "preferred candidate / owner approval required" state.

## Boundary

Cloudflare R2 will hold the production/family remote-content distribution objects used by:
- ScrubBots RemoteContentManager read path;
- Level Factory / Pixel Art Factory publisher write path.

The game/APK receives only non-secret HTTPS read endpoints.

Publisher write credentials:
- remain outside Git;
- remain outside the APK;
- remain outside committed configuration;
- are used only by the publisher-side environment.

## Provisioning outputs still to choose

This provider lock does NOT yet hard-code:
- bucket name;
- account ID;
- public hostname;
- r2.dev vs custom-domain read endpoint;
- production object-prefix layout beyond the already versioned manifest/object contract;
- secret credential values.

Those are implementation/provisioning outputs and must be recorded without committing secrets.

## Locked sequence

Cloudflare R2 provisioning/read endpoint
→ Factory publisher binding
→ ScrubBots non-secret manifest/object URL binding
→ end-to-end publish/download/hash/LKG proof
→ Android Family Test APK.

**OWNER LOCK: CLOUDFLARE R2**
