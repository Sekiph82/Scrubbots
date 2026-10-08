# Saltmire Spark

**One-call 2D particle bursts for Godot 4.**
Fire hit sparks, pickups, explosions, dust and confetti in a single line —
procedural (no textures), one self-contained autoload, zero dependencies, MIT.

> Part of the Saltmire game-feel family (Juice · Transitions · FX · Trail · Spark).
> The paid **Impact** layer wires the whole family together so a full hit reads
> as one line — https://saltmire.itch.io/saltmire-impact

## Why

Every hit, pickup and explosion wants a little pop of particles. Setting up a
`GPUParticles2D`, a process material, a texture and a one-shot timer for each
one is a chore. Spark does it in a single call, with tuned presets, and cleans
itself up.

```gdscript
# default white spark pop at a point
Spark.burst(global_position)

# a named preset
Spark.burst(enemy.global_position, "hit")

# burst at a node's position
Spark.at(pickup, "pickup")

# kill every live burst right now
Spark.clear()
```

No textures, no scenes to instance — particles are drawn procedurally and each
burst frees itself when its particles die.

## Presets

| Name       | Feel                                  |
|------------|---------------------------------------|
| `spark`    | white/yellow quick pop (default)      |
| `hit`      | tight red-orange impact fan           |
| `explode`  | big fiery radial blast                |
| `pickup`   | soft upward cyan sparkle              |
| `dust`     | low, slow brown puff                  |
| `confetti` | wide multicolor celebration           |

## Install

1. Copy `addons/saltmire_spark/` into your project's `addons/` folder.
2. **Project → Project Settings → Plugins → enable "Saltmire Spark".**
3. That registers the `Spark` autoload. Done.

## Tuning

Pass a dict of overrides for a fully custom burst, or edit `Spark.presets` /
`Spark.base` to change the defaults once:

```gdscript
Spark.burst(pos, {
    "amount": 24,                     # particles in the burst
    "color": Color(1.0, 0.8, 0.2),    # start color
    "color2": Color(1.0, 0.2, 0.1, 0),# end color (fades to this)
    "speed": 320.0,                   # initial px/s
    "lifetime": 0.5,                  # seconds
    "size": 3.0,                      # particle radius (px)
    "size_end": 0.0,                  # radius at end of life (shrinks)
    "gravity": 600.0,                 # downward px/s^2 (negative floats up)
    "damping": 2.0,                   # velocity decay per second
    "spread": TAU,                    # angular spread (TAU = full circle)
    "direction": -PI / 2.0,           # center angle (up)
    "rainbow": true,                  # randomize each particle's hue
})
```

| Option          | Default            | What it does                          |
|-----------------|--------------------|---------------------------------------|
| `amount`        | `14`               | particles per burst                   |
| `color`         | `Color(1,1,1)`     | start color                           |
| `color2`        | `Color(1,1,1,0)`   | color each particle fades to          |
| `speed`         | `220.0`            | initial speed (px/s)                  |
| `lifetime`      | `0.45`             | seconds                               |
| `size`          | `3.0`              | particle radius (px)                  |
| `size_end`      | `0.0`              | radius at end of life                 |
| `gravity`       | `480.0`            | downward accel; negative floats up    |
| `damping`       | `2.0`              | velocity decay per second             |
| `spread`        | `TAU`              | angular spread (radians)              |
| `direction`     | `-PI/2` (up)       | center emission angle                 |
| `rainbow`       | `false`            | randomize each particle's hue         |

## Demo

Open the project and run `demo/demo.tscn` — it cycles every preset plus a
custom burst. Click or press **Space** to skip ahead.

## License

MIT — free for any use, commercial or not. See `LICENSE.txt`.

https://saltmire.itch.io
