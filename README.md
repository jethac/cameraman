# Cameraman

**A composable procedural camera system for Godot 4.**

[Splatterface Games](https://www.splatterfacegames.com/) · [Repository](https://github.com/splatterfacegames/cameraman) · [Product page](https://cameraman.jethachan.net/) · [Live WebGL demo](https://cameraman.jethachan.net/demo/) · [MIT License](LICENSE)

Cameraman lets you build polished 2D and 3D camera behavior from small,
reusable parts. Define virtual cameras, attach the components each shot needs,
and let a brain select, evaluate, and blend them into a real Godot camera.

**Godot 4.4+ · GDScript · MIT licensed**

## Highlights

- **Virtual cameras and brains** — author many shots while one output camera
  follows the highest-priority eligible camera.
- **A staged camera pipeline** — combine body, aim, noise, and finalize behavior
  without building a monolithic camera controller.
- **Smooth transitions** — blend position, orientation, lens settings,
  corrections, and custom blendables with default or shot-specific rules.
- **2D and 3D workflows** — drive `Camera2D` and `Camera3D` outputs using the
  same priority-and-blending model.
- **Tracking and composition** — follow, orbit, frame, look ahead, pan/tilt,
  aim, and keep subjects inside configurable screen regions.
- **Gameplay-ready rigs** — third-person collision handling, deocclusion,
  confiners, target groups, splines, free look, impulses, and camera shake.
- **Camera managers** — build ClearShot, state-driven, sequenced, and mixed
  camera setups from child cameras.
- **Multiple outputs** — use channel masks for split-screen or independent
  camera stacks.
- **Editor tooling** — create common rigs from the Tools menu, inspect custom
  nodes, preview composition zones, and visualize camera frustums.

## Installation

1. Copy [`addons/cameraman`](addons/cameraman) into your project's `addons`
   directory.
2. Open **Project > Project Settings > Plugins**.
3. Enable **Cameraman**.

The included project targets Godot 4.4 and CI runs against Godot 4.4.1.

## Quick start

### Using the editor tools

1. Select a scene root or an existing `Camera3D`.
2. Choose **Project > Tools > Create Brain** to create an output camera and
   `CameramanBrain`. If a `Camera3D` is selected, the brain is attached to it.
3. Select the parent for your virtual camera and choose
   **Project > Tools > Create Camera**.
4. Assign the new `CameramanCamera.tracking_target` to your player or subject.
5. Adjust the generated `CameramanFollow` and
   `CameramanRotationComposer` children, then run the scene.

A minimal scene looks like this:

```text
Level
├── Player
├── Camera3D
│   └── CameramanBrain
└── CameramanCamera
    ├── Follow
    └── RotationComposer
```

The brain discovers eligible virtual cameras, selects by effective priority,
evaluates the winning camera's component pipeline, blends transitions, and
writes the final state to its parent `Camera3D`. Set `camera_path` when the
brain should drive a camera elsewhere in the scene tree.

### Switching shots

Create another `CameramanCamera`, configure a different rig, and give it a
higher `priority` when it should become active. The brain uses its
`default_blend`, or a matching custom blend rule, to transition between the
shots. Disable a camera or lower its priority to return control to another
shot.

Use channel masks when a virtual camera should only be considered by specific
brains—for example, in a split-screen game.

## Building camera behavior

A `CameramanCamera` evaluates child components in a predictable sequence:

1. **BODY** places the camera with follow, orbital, third-person, spline, or
   position-composition behavior.
2. **AIM** orients it with look-at, rotation composition, or pan/tilt behavior.
3. **NOISE** adds procedural motion such as handheld shake.
4. **FINALIZE** gives extensions a final opportunity to constrain or modify
   the result.

Extensions can participate around the pipeline to add concerns such as
confinement, deocclusion, recomposition, group framing, pixel-perfect output,
shot quality, storyboards, and camera attributes.

### Main building blocks

| Area | Included tools |
| --- | --- |
| Output | `CameramanBrain`, `CameramanBrain2D` |
| Virtual cameras | `CameramanCamera`, priorities, channels, lens settings |
| Position | Follow, hard lock, orbital follow, third-person follow, position composer, spline dolly |
| Aim | Hard look-at, rotation composer, pan/tilt, third-person aim |
| Motion | Multi-channel Perlin noise, impulse sources/listeners, input axes |
| Constraints | 2D/3D confiners, obstacle avoidance, deocclusion, pixel perfect |
| Framing | Target groups, group framing, follow zoom, recomposer, lookahead |
| Managers | ClearShot, State Driven, Sequencer, Mixing |
| Sequencing | Weighted shots and deterministic shot sequences |
| Presentation | Storyboard overlays, camera-space views, world-space views |

Every public class is registered with Godot's class database and documented in
its source file. Browse the implementation by area under
[`addons/cameraman`](addons/cameraman).

## Teleports and hard cuts

Damped cameras should be told when a tracked target teleports so they do not
interpolate across the discontinuity:

```gdscript
var previous_position := player.global_position
player.global_position = destination
CameramanCore.notify_target_warped(
    player,
    player.global_position - previous_position
)
```

This rebases registered camera state and requests a cut for brains currently
tracking the target. To force the next transition to cut for another reason,
call `CameramanBrain.cut_next_transition()`.

## Demos

Clone the repository and open `project.godot` to run the demo browser. The
included scenes cover:

- a game-scale third-person level;
- third-person follow and free look;
- a confined 2D platformer camera;
- spline dolly movement;
- ClearShot and state-driven camera selection;
- split-screen channels;
- impulses and camera shake;
- weighted shot sequences.

The demo entry point is [`demo/main_menu.tscn`](demo/main_menu.tscn).

## Performance

The registry caches camera sort order and supports round-robin standby updates.
On a software-rendered CI VM, Godot 4.4.1 headless, over 600 frames with one
live camera blending:

| Virtual cameras | Approximate time per frame |
| ---: | ---: |
| 1 | 83 µs |
| 10 | 500 µs |
| 100 | 0.95 ms |
| 500 | 2.9 ms |

These figures are relative measurements, not a hardware-independent guarantee.
Run the benchmark on your target system with:

```console
godot --headless -s tests/bench/bench_many_cameras.gd -- 500
```

## Development

Import the project before running the test suite:

```console
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit
gdlint addons/cameraman tests demo
```

The repository includes GUT runtime and editor regression tests, focused
confiner and storyboard coverage, headless benchmarks, and GitHub Actions CI.

## Inspiration and provenance

Cameraman was inspired by **Cinemachine 3.1**, but it is a **clean-room
implementation** created by **GPT-6 Astra and Devin using Devin Fusion**. The
agents had no access to Unity's source code; the implementation was developed
independently, so its provenance should be clean.

Cameraman is not affiliated with, endorsed by, or sponsored by Unity
Technologies. Cinemachine and Unity are trademarks of their respective owner.
References to Cinemachine describe inspiration only and do not claim source,
API, or binary compatibility.

## License

Cameraman is available under the [MIT License](LICENSE). Third-party software
included in the repository remains subject to its own license terms.
