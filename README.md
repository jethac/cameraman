# Cameraman

Cameraman is a procedural camera system for Godot 4.

## Install

Copy `addons/cameraman` into a Godot 4.4 project and enable the Cameraman
plugin under **Project > Project Settings > Plugins**.

## Quickstart

1. Add a `Camera3D` and a `CameramanBrain` as its child.
2. Add a `CameramanCamera` beside the output camera.
3. Add `CameramanFollow` and `CameramanRotationComposer` as camera children.
4. Assign a target to the virtual camera and run the scene.

The brain selects enabled virtual cameras by channel and effective priority,
evaluates the component pipeline, blends transitions, and writes the result to
the output camera.

When a tracked target is teleported, call
`CameramanCore.notify_target_warped(target, position_delta)`. This forwards the
warp to registered cameras and cuts each brain's next camera transition.
`CameramanBrain.cut_next_transition()` can request the same one-shot cut
directly.

## Concepts

- **State and pipeline:** BODY, AIM, NOISE, and FINALIZE produce a raw shot plus corrections.
- **Priority and channels:** priority selects a camera; output channels allow split-screen brains.
- **Blending:** blend definitions interpolate lens, position, orientation, corrections, and custom blendables.
- **Managers:** ClearShot, StateDriven, Sequencer, and Mixing cameras compose child virtual cameras.
- **Extensions:** confiners, deocclusion, recomposition, framing, aim, storyboard, and attributes modify state.
- **Impulse:** definitions and sources feed camera or external listeners through the impulse manager.
- **Input axes:** axis resources and controllers provide smoothed, recentering component input.
- **Shot sequences:** animated `CameramanShot.weight` values drive deterministic brain overrides.

## Class reference

| Class | File |
| --- | --- |
| CameramanCore | [core/cameraman_core.gd](addons/cameraman/core/cameraman_core.gd) |
| CameramanCameraState | [core/cameraman_camera_state.gd](addons/cameraman/core/cameraman_camera_state.gd) |
| CameramanLens | [core/cameraman_lens.gd](addons/cameraman/core/cameraman_lens.gd) |
| CameramanBlend | [core/cameraman_blend.gd](addons/cameraman/core/cameraman_blend.gd) |
| CameramanBlendDefinition | [core/cameraman_blend_definition.gd](addons/cameraman/core/cameraman_blend_definition.gd) |
| CameramanTargetGroup | [core/cameraman_target_group.gd](addons/cameraman/core/cameraman_target_group.gd) |
| CameramanVirtualCameraBase | [cameras/cameraman_virtual_camera_base.gd](addons/cameraman/cameras/cameraman_virtual_camera_base.gd) |
| CameramanCamera | [cameras/cameraman_camera.gd](addons/cameraman/cameras/cameraman_camera.gd) |
| CameramanBrain | [brain/cameraman_brain.gd](addons/cameraman/brain/cameraman_brain.gd) |
| CameramanBrain2D | [brain/cameraman_brain_2d.gd](addons/cameraman/brain/cameraman_brain_2d.gd) |
| CameramanCameraManagerBase | [managers/cameraman_camera_manager_base.gd](addons/cameraman/managers/cameraman_camera_manager_base.gd) |
| CameramanClearShot | [managers/cameraman_clear_shot.gd](addons/cameraman/managers/cameraman_clear_shot.gd) |
| CameramanStateDrivenCamera | [managers/cameraman_state_driven_camera.gd](addons/cameraman/managers/cameraman_state_driven_camera.gd) |
| CameramanSequencerCamera | [managers/cameraman_sequencer_camera.gd](addons/cameraman/managers/cameraman_sequencer_camera.gd) |
| CameramanMixingCamera | [managers/cameraman_mixing_camera.gd](addons/cameraman/managers/cameraman_mixing_camera.gd) |
| CameramanShot | [timeline/cameraman_shot.gd](addons/cameraman/timeline/cameraman_shot.gd) |
| CameramanShotSequence | [timeline/cameraman_shot_sequence.gd](addons/cameraman/timeline/cameraman_shot_sequence.gd) |
| CameramanFollow | [components/cameraman_follow.gd](addons/cameraman/components/cameraman_follow.gd) |
| CameramanOrbitalFollow | [components/cameraman_orbital_follow.gd](addons/cameraman/components/cameraman_orbital_follow.gd) |
| CameramanThirdPersonFollow | [components/cameraman_third_person_follow.gd](addons/cameraman/components/cameraman_third_person_follow.gd) |
| CameramanRotationComposer | [components/cameraman_rotation_composer.gd](addons/cameraman/components/cameraman_rotation_composer.gd) |
| CameramanPositionComposer | [components/cameraman_position_composer.gd](addons/cameraman/components/cameraman_position_composer.gd) |
| CameramanBasicMultiChannelPerlin | [components/cameraman_basic_multi_channel_perlin.gd](addons/cameraman/components/cameraman_basic_multi_channel_perlin.gd) |
| CameramanInputAxisController | [input/cameraman_input_axis_controller.gd](addons/cameraman/input/cameraman_input_axis_controller.gd) |
| CameramanImpulseSource | [impulse/cameraman_impulse_source.gd](addons/cameraman/impulse/cameraman_impulse_source.gd) |
| CameramanImpulseListener | [components/cameraman_impulse_listener.gd](addons/cameraman/components/cameraman_impulse_listener.gd) |
| CameramanDeoccluder | [extensions/cameraman_deoccluder.gd](addons/cameraman/extensions/cameraman_deoccluder.gd) |
| CameramanConfiner3D | [extensions/cameraman_confiner_3d.gd](addons/cameraman/extensions/cameraman_confiner_3d.gd) |
| CameramanConfiner2D | [extensions/cameraman_confiner_2d.gd](addons/cameraman/extensions/cameraman_confiner_2d.gd) |
| CameramanGroupFraming | [extensions/cameraman_group_framing.gd](addons/cameraman/extensions/cameraman_group_framing.gd) |
| CameramanRecomposer | [extensions/cameraman_recomposer.gd](addons/cameraman/extensions/cameraman_recomposer.gd) |
| CameramanStoryboard | [extensions/cameraman_storyboard.gd](addons/cameraman/extensions/cameraman_storyboard.gd) |
| CameramanFreeLookModifier | [extensions/cameraman_free_look_modifier.gd](addons/cameraman/extensions/cameraman_free_look_modifier.gd) |
| CameramanThirdPersonAim | [extensions/cameraman_third_person_aim.gd](addons/cameraman/extensions/cameraman_third_person_aim.gd) |
| CameramanCameraAttributes | [extensions/cameraman_camera_attributes.gd](addons/cameraman/extensions/cameraman_camera_attributes.gd) |

`CameramanStoryboard` supports overlay and camera-space CanvasLayer rendering,
as well as a world-space quad positioned at `world_distance` from the output
camera. Set `split_view` below `1.0` to clip the screen-space image to the
left portion of the viewport.

## Performance

Run the headless many-camera benchmark with:

```text
godot --headless -s tests/bench/bench_many_cameras.gd -- 500
```

On Godot 4.4.1 headless on this VM, using 600 frames with one live camera
blending and round-robin standby updates:

| Cameras | Time per frame |
| ---: | ---: |
| 1 | ≈ 83 µs |
| 10 | ≈ 500 µs |
| 100 | ≈ 0.95 ms |
| 500 | ≈ 2.9 ms |

The 500-camera case measured approximately 12 ms per frame before registry
sort-order caching was added.

## Demos

The `demo/` directory contains third-person, free-look, 2D platformer, dolly,
ClearShot, split-screen, impulse, and shot-sequence scenes. The main menu is
`demo/main_menu.tscn`.

## Testing and CI

```text
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit
gdlint addons/cameraman tests demo
```

The repository CI runs the same import, GUT, and lint commands on Godot 4.4.1.
