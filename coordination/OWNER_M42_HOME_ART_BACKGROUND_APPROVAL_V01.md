# OWNER M42 HOME ART APPROVAL — BACKGROUND BATCH V01

Status: OWNER APPROVED
Date: 2026-09-25
Scope: M42 Home art review

Owner reviewed the current repository files against the canonical Home reference and approved all four background assets without changes.

Approved selections:

| ID | Slug | Repository path | Git blob SHA |
|---|---|---|---|
| HOME-001 | home_bg_sky | assets/ui/final/home/background/home_bg_sky.png | 5aad601e11f4146afb051ab9769e6dfe81597e19 |
| HOME-002 | home_bg_city_far | assets/ui/final/home/background/home_bg_city_far.png | dfe608a6f2b71b18b0631e22c49e9c06ea660a20 |
| HOME-003 | home_bg_city_mid | assets/ui/final/home/background/home_bg_city_mid.png | 13a4f0e18c6ef01dc89b8a0df1e227d53fe25f67 |
| HOME-004 | home_bg_street_foreground | assets/ui/final/home/background/home_bg_street_foreground.png | 5cf8ff38d2ba244f8a6fd6cb8d0518716db92f9b |

Owner decision: `001 OK / 002 OK / 003 OK / 004 OK`.

These exact repository blobs are approved visually. Production manifest promotion still requires the validator-mandated file SHA-256 pin (`approved_sha256`); that technical pin must be computed from the actual PNG bytes before setting manifest status to `APPROVED`. Do not regenerate or replace these owner-approved blobs while the pin is being recorded.
