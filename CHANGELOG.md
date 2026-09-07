# Changelog

All notable changes to Cameraman are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-09-06

### Added

- Confiner3D support for convex and concave camera volumes.
- Storyboard rendering in world-space and camera-space modes.
- A game-scale third-person demo with gameplay, camera managers, bridge and
  courtyard traversal, impulses, and shot sequences.
- Target-warp notification and cut-on-warp APIs through
  `CameramanCore.notify_target_warped()` and
  `CameramanBrain.cut_next_transition()`.
- A many-camera headless benchmark and registry sort-order caching.
- Editor tooling for custom node types, camera frustums, composer overlays,
  and atomic preset undo actions.

### Changed

- Improved third-person obstacle collision handling, target-body exclusion,
  shoulder sliding, minimum target distance, and close-camera presentation.
- Stabilized composition math when targets leave the camera frustum or occupy
  degenerate positions.
- Added corrected-position aiming across rotation, hard-look, pan/tilt, and
  position composition stages.

## [0.1.0]

### Added

- Initial Cameraman addon release for Godot 4.
- Core camera state, lens, blending, damping, registry, event, and target
  group types.
- 2D and 3D virtual cameras with brain-driven priority selection and blending.
- Follow, orbital, third-person, rotation, position, pan/tilt, noise, spline,
  and obstacle-avoidance components.
- Camera managers for ClearShot, State Driven, Sequencer, and Mixing workflows.
- Confiner, impulse, input-axis, storyboard, framing, deocclusion, and
  camera-attribute extensions.
- Editor node registration, demo scenes, automated GUT coverage, and CI
  validation.
