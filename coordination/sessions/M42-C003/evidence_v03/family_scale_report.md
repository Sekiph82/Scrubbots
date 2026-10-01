# M42-C003 V03 family scale report

HOME-026 identity: visor 422x287 px (largest connected near-black component in the upper 60%), character height 1327 px, yaw 5.7 deg.

Scale = HOME texels per source pixel, one uniform value per source family. Basis: median over comparable upright front frames (|yaw| <= 15 deg, height >= 93% of the family max) of sqrt(visor-width ratio x height ratio). Visor width and character height are spec V03 section 5 identity features (priorities 1 and 3); the geometric mean balances them when a family's proportions differ from HOME-026. The V02 dark-envelope 'visor' metric (723 px on HOME, which also counted dark body pixels) is replaced.

| Source family | Scale | Comparable frames | Visor width vs HOME at scale | Height vs HOME at scale | Stored anim px per source px |
|---|---:|---|---|---|---:|
| wave | 3.9189 | [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] | 103.1%, 100.3%, 101.2%, 96.6%, 98.4%, 98.4%, 96.6%, 94.7%, 102.2%, 99.4%, 99.4%, 96.6%, 100.3%, 99.4% | 102.2%, 101.6%, 102.8%, 102.8%, 101.9%, 101.6%, 101.9%, 102.2%, 101.0%, 101.0%, 100.4%, 100.1%, 98.9%, 100.7% | 1.3063 |
| bow | 3.6786 | [1, 11, 12, 13, 14, 15] | 106.3%, 107.2%, 99.4%, 97.6%, 105.5%, 99.4% | 101.2%, 100.4%, 100.6%, 99.2%, 100.1%, 100.4% | 1.2262 |
| turn_look | 4.6954 | [1, 4, 7, 8, 12, 15, 16, 17] | 111.3%, 109.0%, 99.0%, 110.1%, 122.4%, 110.1%, 111.3%, 111.3% | 89.9%, 93.1%, 90.9%, 90.9%, 94.1%, 89.5%, 90.2%, 89.9% | 1.5651 |
| full_turn | 4.0517 | [1, 2, 6, 12, 13, 14] | 100.8%, 98.9%, 85.5%, 99.9%, 103.7%, 101.8% | 100.2%, 100.8%, 98.3%, 100.2%, 100.4%, 100.4% | 1.3506 |

Every stored scale is >= 1 animation pixel per source pixel, so storing at 3 HOME texels per animation pixel keeps all source detail.

## Per-frame identity measurements (source pixels)

| Family | Frame | Visor w | Visor h | Height | Yaw deg |
|---|---:|---:|---:|---:|---:|
| wave | 01 | 111 | 76 | 346 | 8.3 |
| wave | 02 | 108 | 75 | 344 | 10.6 |
| wave | 03 | 109 | 78 | 348 | 8.0 |
| wave | 04 | 104 | 77 | 348 | 9.8 |
| wave | 05 | 106 | 82 | 345 | 11.0 |
| wave | 06 | 106 | 83 | 344 | 10.9 |
| wave | 07 | 104 | 83 | 345 | 11.8 |
| wave | 08 | 102 | 82 | 346 | 12.5 |
| wave | 09 | 110 | 78 | 342 | 9.0 |
| wave | 10 | 107 | 76 | 342 | 8.3 |
| wave | 11 | 107 | 76 | 340 | 7.7 |
| wave | 12 | 104 | 77 | 339 | 8.6 |
| wave | 13 | 108 | 74 | 335 | 9.0 |
| wave | 14 | 107 | 75 | 341 | 9.4 |
| bow | 01 | 122 | 77 | 365 | 10.1 |
| bow | 02 | 119 | 77 | 361 | 15.1 |
| bow | 03 | 122 | 63 | 326 | 8.7 |
| bow | 04 | 125 | 63 | 310 | 10.2 |
| bow | 05 | 120 | 55 | 286 | 11.3 |
| bow | 06 | 110 | 49 | 278 | 11.1 |
| bow | 07 | 109 | 50 | 272 | 10.1 |
| bow | 08 | 117 | 58 | 277 | 16.5 |
| bow | 09 | 119 | 66 | 317 | 18.9 |
| bow | 10 | 119 | 63 | 323 | 10.6 |
| bow | 11 | 123 | 77 | 362 | 9.6 |
| bow | 12 | 114 | 83 | 363 | 14.4 |
| bow | 13 | 112 | 80 | 358 | 12.4 |
| bow | 14 | 121 | 81 | 361 | 9.1 |
| bow | 15 | 114 | 78 | 362 | -4.7 |
| turn_look | 01 | 100 | 51 | 254 | 1.1 |
| turn_look | 02 | 76 | 62 | 260 | 23.6 |
| turn_look | 03 | 43 | 59 | 257 | 41.6 |
| turn_look | 04 | 98 | 65 | 263 | 2.2 |
| turn_look | 05 | 52 | 58 | 258 | 35.2 |
| turn_look | 06 | 70 | 57 | 250 | 26.1 |
| turn_look | 07 | 89 | 54 | 257 | 6.9 |
| turn_look | 08 | 99 | 50 | 257 | 0.4 |
| turn_look | 09 | 68 | 57 | 263 | -26.1 |
| turn_look | 10 | 54 | 58 | 260 | -34.2 |
| turn_look | 11 | 39 | 60 | 268 | -44.9 |
| turn_look | 12 | 110 | 65 | 266 | 3.8 |
| turn_look | 13 | 52 | 61 | 261 | 36.1 |
| turn_look | 14 | 74 | 59 | 256 | 24.9 |
| turn_look | 15 | 99 | 49 | 253 | 1.5 |
| turn_look | 16 | 100 | 49 | 255 | 0.7 |
| turn_look | 17 | 100 | 51 | 254 | 1.1 |
| full_turn | 01 | 105 | 72 | 328 | 9.7 |
| full_turn | 02 | 103 | 74 | 330 | 10.9 |
| full_turn | 03 | 67 | 74 | 333 | 29.3 |
| full_turn | 04 | 60 | 74 | 329 | 32.5 |
| full_turn | 05 | 60 | 76 | 326 | 33.1 |
| full_turn | 06 | 89 | 61 | 322 | -7.9 |
| full_turn | 07 | 79 | 54 | 316 | -11.5 |
| full_turn | 08 | 78 | 56 | 317 | -4.0 |
| full_turn | 09 | 118 | 53 | 315 | 7.4 |
| full_turn | 10 | 78 | 84 | 320 | -22.9 |
| full_turn | 11 | 61 | 78 | 325 | 34.1 |
| full_turn | 12 | 104 | 74 | 328 | -6.6 |
| full_turn | 13 | 108 | 123 | 329 | -3.4 |
| full_turn | 14 | 106 | 72 | 329 | -2.9 |
| full_turn | 15 | 89 | 84 | 342 | 20.3 |
| full_turn | 16 | 103 | 77 | 313 | 10.2 |
| full_turn | 17 | 100 | 74 | 310 | 11.8 |
