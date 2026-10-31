# assets/brand provenance

## akilta-wordmark-light.svg (SB-POLISH-008)

White derivative of the Akilta wordmark for the black Opening background.

- Source: `assets/brand/akilta-wordmark.svg` (SHA-256 `df4eb2cb6f826758aa850d2c4e651ac6bbe923d39ba73b9914aae1306b4f4b67`, LF as stored in git), unchanged.
- Change: the single path fill `#111111` replaced by `#FFFFFF`; geometry identical.
- Command: `sed 's/fill="#111111"/fill="#FFFFFF"/' akilta-wordmark.svg > akilta-wordmark-light.svg`
- Result SHA-256: `31b18744f7a9d65d0133661b1a612d6f77214936391403eb9241ad2d6abf5212` (LF as stored in git)
- Godot import: `svg/scale=0.5` (viewBox 2466.816x779.219 -> 1233x390 texture), enough for the
  wordmark at 60% of a 1080..1440 px wide portrait screen without upscaling.
