# Cameraman — design

Cameraman is a procedural camera system for Godot 4.4+ (GDScript addon at `addons/cameraman/`).
It separates *shot descriptions* (many `CameramanCamera` nodes) from the *one rendering camera*
(a `Camera3D`/`Camera2D` driven by a `CameramanBrain`). Every frame the brain selects the live
shot(s), evaluates them, blends between them when a transition is in progress, and writes the
result to the real camera.

All script classes are `class_name`d with the `Cameraman` prefix. Nothing in this addon is named
after or references any other camera library.

## 1. Data types (`addons/cameraman/core/`)

### `CameramanCameraState` (RefCounted)
```
lens: CameramanLens                  # duplicated, never shared
reference_up: Vector3                # unit, from brain
reference_look_at: Vector3           # NO_POINT (Vector3(INF,INF,INF)) if none
raw_position: Vector3
raw_orientation: Quaternion
position_correction: Vector3 = ZERO  # noise / deoccluder / confiner / impulse
orientation_correction: Quaternion = IDENTITY
rotation_damping_bypass: Quaternion = IDENTITY
shot_quality: float = 1.0
blend_hint: int (CameramanCore.BlendHint flags)
custom_blendables: Array[Dictionary] # [{"object": Object, "weight": float}] capped at 8

func has_look_at() -> bool
func get_final_position() -> Vector3            # raw + correction
func get_final_orientation() -> Quaternion      # raw * correction (normalized)
func get_corrected_look_at() -> Vector3
func add_custom_blendable(obj: Object, weight: float)
static func lerp(a, b, t: float) -> CameramanCameraState
static func create_default(up := Vector3.UP) -> CameramanCameraState
```
`lerp` rules:
- `lens` = `CameramanLens.lerp(a.lens, b.lens, t)` (fov lerped in *focal length space* so blends look linear;
  ortho size, near/far, dutch linear; mode override taken from b if t > 0.5 else a).
- `reference_up` = slerp (normalize).
- Position: if both have look_at and hint has `SPHERICAL_POSITION` → slerp the offset vectors around the
  lerped look_at (magnitude lerped); `CYLINDRICAL_POSITION` → same but the up-axis component is lerped
  linearly; otherwise linear lerp of raw positions. Corrections are lerped linearly.
- `reference_look_at`: if `SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER` and both have look_at → project both
  targets into each camera's screen space, lerp the screen point, and reproject at lerped distance;
  else linear lerp. If only one has look_at, take that one.
- Orientation: if both have look_at and hint lacks `IGNORE_TARGET` → orientation is computed so that the
  lerped look_at stays at the lerped screen position of the target (compute each camera's look_at screen
  offset, lerp, then aim), then slerp the residual roll; else plain slerp.
- `shot_quality` lerp; `blend_hint` = a.blend_hint | b.blend_hint; custom_blendables merged with weights
  scaled by (1-t)/t.

### `CameramanLens` (Resource)
```
enum Mode { NONE, PERSPECTIVE, ORTHOGRAPHIC, FRUSTUM }   # FRUSTUM = Godot Camera3D.PROJECTION_FRUSTUM
fov_degrees: float = 60 (vertical)      # Godot fov is vertical when keep_aspect = KEEP_HEIGHT; brain sets that
orthographic_size: float = 10           # half-height in world units (Camera3D.size is full height → size = 2*this)
near: float = 0.05
far: float = 4000
dutch_degrees: float = 0
mode_override: Mode = NONE
focus_distance: float = 10              # applied to CameraAttributesPractical/Physical dof if enabled by an extension
frustum_offset: Vector2 = ZERO          # FRUSTUM mode lens shift
static presets: 12mm..200mm mapped to vertical fov for a 24mm-tall gate (fov = 2*atan(12/f))
func lerp(other, t) -> CameramanLens
func is_orthographic() -> bool
```

### `CameramanCore` (RefCounted, static)
```
enum Stage { BODY, AIM, NOISE, FINALIZE }
enum BlendHint { SPHERICAL_POSITION=1, CYLINDRICAL_POSITION=2, SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER=4,
                 INHERIT_POSITION=8, IGNORE_TARGET=16, FREEZE_WHEN_BLENDING_OUT=32 }
const NO_POINT := Vector3(INF, INF, INF)
static var solo_camera: CameramanVirtualCameraBase     # forced live in every brain
static var uniform_delta_time_override: float = -1     # for deterministic tests / offline rendering
static var current_time_override: float = -1
static var get_blend_override: Callable                # (from, to, default_def: CameramanBlendDefinition, owner) -> CameramanBlendDefinition
static var get_custom_blender: Callable                # (from, to) -> CameramanBlender or null
static var registry: CameramanRegistry                 # lazily created
static var events: CameramanEventBus                   # lazily created
static var impulse_manager: CameramanImpulseManager    # lazily created
static func delta_time(raw: float) -> float
static func current_time() -> float
static func is_live(cam) -> bool                       # live in any active brain
static func find_potential_target_brain(cam) -> CameramanBrain
```
`CameramanEventBus` (RefCounted) signals: `camera_activated(params: CameramanActivationEvent)`,
`camera_deactivated(mixer, cam)`, `blend_created(params: CameramanBlendEvent)`, `blend_finished(mixer, cam)`,
`camera_updated(brain)`. `CameramanActivationEvent` (RefCounted): `origin, outgoing, incoming, is_cut, world_up, delta_time`.
`CameramanBlendEvent`: `origin, blend` (mutable — handlers may replace `blend.curve/duration`).

`CameramanRegistry` (RefCounted): all enabled `CameramanVirtualCameraBase` in the tree, sorted by priority
descending then activation sequence descending. `add/remove(cam)`, `mark_activated(cam)`, `get_cameras()`,
`get_top_camera(channel_mask: int, brain) -> cam`, per-frame update guard `update_camera(cam, world_up, dt, frame)`
(prevents evaluating a camera twice in one frame; supports round-robin standby scheduling).

### `CameramanBlendDefinition` (Resource)
`enum Style { CUT, EASE_IN_OUT, EASE_IN, EASE_OUT, HARD_IN, HARD_OUT, LINEAR, CUSTOM }`, `style`, `time: float`,
`custom_curve: Curve`. `blend_time()` = 0 for CUT. `get_curve() -> Curve` builds the shape (cached).

### `CameramanBlenderSettings` (Resource)
`custom_blends: Array[CameramanCustomBlend]` where `CameramanCustomBlend` (Resource) = `from_name: String,
to_name: String, definition: CameramanBlendDefinition`. Name `"**ANY CAMERA**"` is the wildcard.
`get_blend_for(from_name, to_name, default) -> CameramanBlendDefinition`: exact/exact beats exact/any beats
any/exact beats any/any; first match within the same specificity wins.

### `CameramanBlend` (RefCounted)
`cam_a, cam_b` (shot sources), `curve: Curve`, `duration: float`, `time_in_blend: float`,
`custom_blender: CameramanBlender` (RefCounted with `blend(state_a, state_b, t) -> CameramanCameraState`, default = `CameramanCameraState.lerp`).
`blend_weight()`, `is_complete()`, `is_valid()`, `uses(cam)`, `update_state(world_up, dt)` (updates both cams
unless frozen), `get_state()`, `description()`. `CameramanNestedBlendSource` (RefCounted) wraps a `CameramanBlend`
and exposes the shot-source duck-type so blends can chain when interrupted.
`CameramanFrozenSource` snapshots a camera's state for `FREEZE_WHEN_BLENDING_OUT`.

**Shot-source duck type** (implemented by `CameramanVirtualCameraBase`, `CameramanNestedBlendSource`,
`CameramanFrozenSource`): `get_camera_name() -> String`, `get_description() -> String`,
`get_state() -> CameramanCameraState`, `is_valid() -> bool`, `get_parent_mixer()`,
`update_state(world_up: Vector3, delta: float)`, `on_camera_activated(evt)`.

## 2. Virtual cameras (`addons/cameraman/cameras/`)

### `CameramanVirtualCameraBase` (Node3D, abstract)
```
@export var priority_enabled := false
@export var priority: int = 0
@export var output_channel: int = 1          # bit flags; brain.channel_mask must intersect
@export_enum StandbyUpdate { NEVER, ALWAYS, ROUND_ROBIN } = ROUND_ROBIN
@export var blend_hint: int (flags)
var previous_state_is_valid: bool
var follow_target_attachment := 1.0; var look_at_target_attachment := 1.0
signal activated(evt); signal deactivated(evt)

func get_follow() -> Node3D / set_follow ; func get_look_at() -> Node3D / set_look_at   # virtual, resolve up parent chain: if unset, inherit from parent manager camera
func get_follow_target_as_group() -> CameramanTargetGroup ; look_at equivalent
func get_state() -> CameramanCameraState
func update_state(world_up, dt)              # registry-guarded, calls internal_update_state
func internal_update_state(world_up, dt)     # abstract
func on_transition_from_camera(from, world_up, dt)   # forwards to components/extensions; handles INHERIT_POSITION
func on_target_object_warped(target: Node3D, position_delta: Vector3)
func force_camera_position(pos: Vector3, rot: Quaternion)
func get_max_damp_time() -> float
func prioritize()                            # priority = max live priority + 1 (in its brain), enables priority
func is_live() -> bool
func add_extension(ext)/remove_extension(ext); func get_extensions() -> Array
func invoke_post_pipeline_stage_callback(stage, state, dt)  # extensions in order
```
Registers with `CameramanCore.registry` in `_enter_tree`/`_exit_tree` and on `visibility`/`process_mode` changes
(a disabled camera = `visible == false` or not in tree; documented). Extensions are child nodes of type
`CameramanExtension`, cached and refreshed via `child_entered_tree`/`child_exiting_tree`.

### `CameramanCamera` (CameramanVirtualCameraBase)
```
@export var tracking_target: Node3D
@export var use_separate_look_at := false ; @export var look_at_target: Node3D
@export var lens: CameramanLens
func get_component(stage) -> CameramanComponent
```
Pipeline components are child nodes of type `CameramanComponent`; one per stage (last wins, warn on duplicates).
`internal_update_state`:
1. state = default; lens = lens.duplicate(); raw pos/orientation = own global transform; reference_up.
2. reference_look_at = look_at target position (group → centroid; if look_at is a CameramanVirtualCameraBase → its final position).
3. extensions `pre_pipeline_mutate_camera_state(cam, state, dt)`.
4. components `pre_pipeline_mutate_camera_state(state, dt)` in stage order.
5. For stage in BODY, AIM, NOISE: component.mutate_camera_state(state, dt) then `invoke_post_pipeline_stage_callback(stage, state, dt)`; a BODY component with `body_applies_after_aim()` runs after AIM (then its post-stage callback).
6. `invoke_post_pipeline_stage_callback(FINALIZE, state, dt)`.
7. Write `raw_position/raw_orientation` back to own global transform (so the node follows the shot and a camera with no components is just its transform). Set previous_state_is_valid.

### `CameramanComponent` (Node, abstract)
`stage() -> Stage` (abstract), `is_valid() -> bool`, `body_applies_after_aim() -> bool = false`,
`pre_pipeline_mutate_camera_state(state, dt)`, `mutate_camera_state(state, dt)` (abstract),
`on_transition_from_camera(from, world_up, dt) -> bool`, `on_target_object_warped(target, delta)`,
`force_camera_position(pos, rot)`, `get_max_damp_time() -> float`, `get_input_axes() -> Array[CameramanAxisDescriptor]`.
Helpers: `vcam`, `follow_target`, `look_at_target`, `follow_target_position/rotation`, `look_at_target_position`,
`follow_target_as_group`, `vcam_state`. Damping helper in `CameramanDamper` (static): `damp(initial: float, damp_time: float, dt: float) -> float` — exponential decay reaching ~99.9% at `damp_time` (`initial * (1 - exp(-k*dt/damp_time))`, k = ln(1000)), vector overload; dt < 0 means "no damping".

### `CameramanExtension` (Node, abstract)
Attaches to parent `CameramanVirtualCameraBase`. Virtuals: `pre_pipeline_mutate_camera_state(cam, state, dt)`,
`post_pipeline_stage_callback(cam, stage, state, dt)` (abstract), `on_transition_from_camera(cam, from, world_up, dt) -> bool`,
`on_target_object_warped(cam, target, delta)`, `force_camera_position(cam, pos, rot)`, `get_max_damp_time()`.
Per-camera extra state dict for extensions used under manager cameras: `get_extra_state(cam) -> Dictionary`.

### `CameramanTargetGroup` (Node3D)
`members: Array[CameramanTargetGroupMember]` (Resource: target: Node3D, weight, radius) with `@export` array,
`position_mode {GROUP_CENTER, GROUP_AVERAGE}`, `rotation_mode {MANUAL, GROUP_AVERAGE}`, `update_method`.
Exposes `get_sphere() -> [center, radius]`, `get_bounding_box() -> AABB`, `get_view_space_bounding_box(view_xform: Transform3D) -> AABB`,
`is_empty()`. The node's own transform is set to the group center each update.

## 3. Brain (`addons/cameraman/brain/`)

### `CameramanBrain` (Node)
Child of (or `@export camera_path` to) a `Camera3D`. Implements the *mixer* duck-type (`get_camera_name`, `is_live(cam)`, `get_state`).
```
@export var show_debug_text := false ; @export var show_camera_frustum := true
@export var ignore_time_scale := false     # use Engine.time_scale-independent dt
@export var world_up_override: Node3D
@export_flags var channel_mask: int = 0xFFFFFFFF
@export_enum UpdateMethod { PROCESS, PHYSICS, SMART, MANUAL } = SMART
@export_enum BlendUpdateMethod { PROCESS, PHYSICS } = PROCESS
@export var lens_mode_override_enabled := false ; @export var default_lens_mode: CameramanLens.Mode = PERSPECTIVE
@export var default_blend: CameramanBlendDefinition (EASE_IN_OUT, 2.0)
@export var custom_blends: CameramanBlenderSettings
signal camera_cut(brain) ; signal camera_activated(brain, incoming, outgoing)
var active_virtual_camera ; var active_blend: CameramanBlend ; var is_blending: bool
var current_camera_state: CameramanCameraState
func manual_update() ; func is_live(cam) -> bool ; func default_world_up() -> Vector3
func set_camera_override(id: int, priority: int, cam_a, cam_b, weight_b: float, dt: float) -> int   # returns id (allocates if <0)
func release_camera_override(id)
func get_output_camera() -> Camera3D
```
Per frame (in `_process` with `process_priority = 1000`; or `_physics_process`; SMART = each camera picks the clock
its follow target moved on last — tracked by `CameramanUpdateTracker` comparing target transforms across the two clocks):
1. Compute `world_up`, dt (respect overrides).
2. Determine desired shot: override stack (highest priority entry) else `solo_camera` else `registry.get_top_camera(channel_mask, self)`.
3. `CameramanBlendManager.update_root_frame(desired, world_up, dt)`: if desired != current top, look up blend
   definition (`get_blend_override` callable → `custom_blends` → `default_blend`), fire `blend_created`, wrap the
   current active blend into a `CameramanNestedBlendSource` if one is in progress, notify incoming camera
   `on_camera_activated`/`on_transition_from_camera`, emit `camera_activated` / `camera_cut` (+ core events).
4. Update all standby cameras per their `standby_update` (registry), update the live chain, resolve final state,
   push to `Camera3D`: `global_transform = Transform3D(Basis(final_orientation) * dutch, final_position)`, `fov`
   (keep_aspect = KEEP_HEIGHT), `size = 2*ortho`, `near/far`, projection per lens mode override rules, `frustum_offset`.
5. `camera_updated` event; debug overlay (Label in CanvasLayer) if `show_debug_text`.

Split-screen: multiple brains, each with its own `channel_mask`; cameras choose `output_channel`.

`CameramanBrain2D` (Node): same selection/blend logic (shares `CameramanBlendManager`), drives a `Camera2D`:
`global_position = Vector2(final.x, final.y)`, `rotation = dutch + yaw-about-z`, `zoom = viewport_height / (2*ortho_size)`.
Cameras for 2D are ordinary `CameramanCamera` nodes in the XY plane (z = camera distance); documented.
Optional `pixel_perfect := false` rounds position to pixels.

### `CameramanBrainEvents` (Node) / `CameramanCameraEvents` (Node)
Inspector-friendly relays: sit under a brain / a camera and re-emit `camera_activated`, `camera_deactivated`,
`blend_created`, `blend_finished`, `camera_cut` filtered to that owner.

## 4. Position components (BODY) — `addons/cameraman/components/`

All expose `damping` as per-axis `Vector3` seconds unless noted, use `CameramanDamper`, honour `previous_state_is_valid`
(no damping on first frame), and implement `on_target_object_warped` (shift internal previous position by delta) and
`force_camera_position`.

- `CameramanFollow`: `follow_offset: Vector3`, `binding_mode {LOCK_TO_TARGET_ON_ASSIGN, LOCK_TO_TARGET_WITH_WORLD_UP, LOCK_TO_TARGET_NO_ROLL, LOCK_TO_TARGET, WORLD_SPACE, LAZY_FOLLOW}`,
  `position_damping: Vector3`, `rotation_damping: Vector3` (Euler, for target-relative modes), `angular_damping_mode {EULER, QUATERNION}`, `quaternion_damping`.
  Offset is applied in the binding frame; damping applied in that frame too. LAZY_FOLLOW = simple-follow-with-world-up: offset direction follows camera-to-target heading.
- `CameramanOrbitalFollow`: `orbit_style {SPHERE, THREE_RING}`; SPHERE: `radius`; THREE_RING: `orbits {top, center, bottom}` each `{height, radius}` + `spline_curvature`;
  `horizontal_axis/vertical_axis/radial_axis: CameramanInputAxis` (horizontal range -180..180 wrap, recentering; vertical -10..45 or 0..1 for three-ring; radial 1..5 scale),
  `target_offset: Vector3`, `binding_mode` (same as Follow minus lazy), `tracker_settings` (position/rotation damping), `recentering_target {AXIS_CENTER, PARENT_HEADING, PARENT_FORWARD, TRACKING_TARGET_FORWARD, LOOK_AT_TARGET_FORWARD}`.
  `get_input_axes()` returns the 3 axes. `get_camera_point() -> Vector3` (local offset on orbit) shared with FreeLookModifier.
- `CameramanThirdPersonFollow`: `damping`, `shoulder_offset: Vector3`, `vertical_arm_length`, `camera_side: float 0..1`, `camera_distance`,
  `avoid_obstacles {enabled, collision_mask, camera_radius, damping_into_collision, damping_from_collision}` (sphere-cast from shoulder pivot to camera). Aim follows target rotation; rig = target → shoulder → arm → camera.
- `CameramanPositionComposer` (`body_applies_after_aim() = true`): `target_offset`, `lookahead {enabled, time, smoothing, ignore_y}`,
  `camera_distance`, `dead_zone_depth`, `damping: Vector3`, `composition: CameramanScreenComposerSettings` (Resource: `screen_position: Vector2 (-0.5..0.5 offsets from center... stored as 0..1 with 0.5 center)`, `dead_zone {enabled, size: Vector2}`, `hard_limits {enabled, size: Vector2, offset: Vector2}`),
  `center_on_activate`, `group_framing_size (auto adjust distance/fov when target is a group, modes NONE/HORIZONTAL/VERTICAL/BOTH)`.
  Works in camera-space using current orientation: compute target's screen position, move camera laterally/vertically so target sits inside dead zone / composer point with damping; hard limits clamp instantly.
- `CameramanHardLockToTarget`: `damping: float` — position = target position.
- `CameramanSplineDolly`: `spline: Path3D`, `camera_position: float`, `position_units {DISTANCE, NORMALIZED, KNOT}`, `spline_offset: Vector3`,
  `camera_rotation {DEFAULT, SPLINE, SPLINE_NO_ROLL, FOLLOW_TARGET, FOLLOW_TARGET_NO_ROLL}`, `damping {position: Vector3, angular: float}`,
  `automatic_dolly {enabled, mode: CameramanSplineAutoDolly (Resource; NEAREST_POINT_TO_TARGET with search settings, FIXED_SPEED)}`.
  Uses `Curve3D.sample_baked_with_rotation`/`get_closest_offset`.

## 5. Rotation components (AIM)

- `CameramanRotationComposer`: `target_offset`, `lookahead`, `damping: Vector2`, `composition: CameramanScreenComposerSettings`, `center_on_activate`.
  Rotates camera so look_at lands in dead zone / composition point with damping; hard limits clamp. Screen-space math shared with PositionComposer in `CameramanComposerMath`.
- `CameramanHardLookAt`: look straight at reference_look_at (with `look_at_offset`), roll aligned to reference_up.
- `CameramanPanTilt`: `reference_frame {PARENT_OBJECT, WORLD, TRACKING_TARGET, LOOK_AT_TARGET}`, `pan_axis: CameramanInputAxis (-180..180 wrap)`, `tilt_axis (-70..70)`, recentering target options; `get_input_axes()`.
- `CameramanRotateWithFollowTarget`: `damping: float` — copy follow target rotation.

## 6. Noise (NOISE)

- `CameramanNoiseProfile` (Resource): `position_noise: Array[CameramanNoiseChannel]`, `orientation_noise: Array[...]` where a channel = `{x, y, z: CameramanNoiseParams}` and params = `{frequency, amplitude, constant: bool}`. Evaluation: sum over channels of `amplitude * perlin1d(time*frequency + seed)`, using `FastNoiseLite` (TYPE_PERLIN) with per-axis seeds; `constant` uses `sin`.
  Ship presets under `addons/cameraman/presets/noise/`: `handheld_normal_mild`, `handheld_normal_strong`, `handheld_normal_extreme`, `handheld_tele_mild/strong`, `handheld_wideangle_mild/strong`, `6d_shake`, `6d_wobble`.
- `CameramanBasicMultiChannelPerlin` (component): `noise_profile`, `pivot_offset: Vector3`, `amplitude_gain`, `frequency_gain`. Adds to `position_correction`/`orientation_correction` only; `reseed()`.

## 7. Extensions — `addons/cameraman/extensions/`

- `CameramanDeoccluder`: `collide_against: int (mask)`, `ignore_tag/ignore_groups: Array[StringName]`, `transparent_layers`, `minimum_distance_from_target`,
  `avoid_obstacles {enabled, distance_limit, minimum_occlusion_time, camera_radius, strategy {PULL_CAMERA_FORWARD, PRESERVE_CAMERA_HEIGHT, PRESERVE_CAMERA_DISTANCE}, maximum_effort, smoothing_time, damping, damping_when_occluded}`,
  `shot_quality_evaluation {enabled, optimal_distance, near_limit, far_limit, max_quality_boost}`. Runs at BODY (position) and FINALIZE (quality). Uses `PhysicsDirectSpaceState3D.intersect_ray`/`intersect_shape` from `get_world_3d().direct_space_state`. `is_target_obscured()`, `camera_was_displaced()`.
- `CameramanConfiner3D`: `bounding_volume: CollisionShape3D` (Box/Sphere/Capsule/Cylinder analytic closest-point; ConvexPolygon via planes; Concave fallback via ray from shape center), `slowing_distance`. Clamps final position at BODY.
- `CameramanConfiner2D`: `bounding_shape: Node2D` (CollisionPolygon2D or Polygon2D or CollisionShape2D rect/circle), `damping`, `slowing_distance`, `oversize_window` (when camera view rect > polygon, keep centered — shrink the effective confining region by the half-view size computed from ortho size × aspect). XY plane. `invalidate_bounding_shape_cache()`, `camera_was_displaced()`.
- `CameramanFollowZoom`: `width`, `damping`, `min_fov`, `max_fov` — sets fov so `width` world units fill the frame at the target distance.
- `CameramanGroupFraming`: `framing_mode {HORIZONTAL, VERTICAL, HORIZONTAL_AND_VERTICAL}`, `framing_size`, `center_offset`, `damping`, `size_adjustment {ZOOM_ONLY, DOLLY_ONLY, DOLLY_THEN_ZOOM}`, `lateral_adjustment`, `fov_range: Vector2`, `dolly_range: Vector2`, `ortho_size_range`. Requires target group.
- `CameramanRecomposer`: `apply_after: Stage`, `tilt`, `pan`, `dutch`, `zoom_scale`, `follow_attachment`, `look_at_attachment` (all animatable).
- `CameramanStoryboard`: `show_image`, `image: Texture2D`, `aspect {BEST_FIT, CROP_IMAGE_TO_FIT, STRETCH_TO_FIT}`, `alpha`, `center`, `rotation`, `scale`, `mute_camera`, `split_view`, `render_mode {SCREEN_SPACE_OVERLAY, SCREEN_SPACE_CAMERA, WORLD_SPACE}`, `world_distance` — screen-space modes use a clipped TextureRect on a CanvasLayer (layers 100 and 1 respectively); world-space mode uses an unshaded, alpha-enabled quad sized to the output camera frustum at `world_distance`, visible only while the camera is live. Storyboards maintain one output view per live brain (shared overlay views remain single); `storyboard_render_layers` can override world-quad layers per brain.
- `CameramanFreeLookModifier`: `modifiers: Array[CameramanFreeLookModifierEntry]` (Resource subclasses: TiltModifier, LensModifier, PositionDampingModifier, CompositionModifier, DistanceModifier, NoiseModifier, ScreenPositionModifier) each with `top/bottom` values lerped by the OrbitalFollow vertical axis normalized value (-1..1 around center).
- `CameramanThirdPersonAim`: `aim_collision_mask`, `ignore_groups`, `aim_distance`, `noise_cancellation`, `aim_target_reticle: Control` — recenters look direction on raycast hit; exposes `aim_target`.
- `CameramanImpulseListener`: `channel_mask`, `gain`, `use_2d_distance`, `use_camera_space`, `reaction_settings {amplitude_gain, frequency_gain, duration, secondary_noise: CameramanNoiseProfile}`; adds impulse signal to corrections at NOISE/FINALIZE (`apply_after`).
- `CameramanShotQualityEvaluator`: standalone quality scoring for ClearShot without deoccluding.
- `CameramanCameraAttributes` (post-processing equivalent): `attributes: CameraAttributes` (Practical/Physical) with `weight`, `focus_tracking {NONE, LOOK_AT_TARGET, FOLLOW_TARGET, CAMERA, CUSTOM}` + `focus_offset`; contributes as a custom blendable; the brain's `CameramanAttributesBlender` writes a blended `CameraAttributes` onto `Camera3D.attributes` (dof far/near distance & transition, exposure, auto_exposure) — weighted average of attribute floats.
- `CameramanPixelPerfect`: for 2D brains — rounds final position to pixel grid using viewport size and ortho size.
- `CameramanHardLockRoll`/`CameramanAutoFocus` folded into the above; no separate classes.

## 8. Manager cameras — `addons/cameraman/managers/`

`CameramanCameraManagerBase` (CameramanVirtualCameraBase, abstract): children of type `CameramanVirtualCameraBase` are managed;
`default_blend`, `custom_blends`; owns a `CameramanBlendManager`; `choose_current_camera(world_up, dt) ->
CameramanVirtualCameraBase`; `live_child`, `is_live_child(camera)`, and `get_state()` expose the mixer state. Children
are hidden from the brain's registry through the manager parent-mixer relationship.

- `CameramanClearShot`: `activate_after`, `min_duration`, `randomize_choice`; picks the highest `shot_quality` child (ties → priority/order).
- `CameramanStateDrivenCamera`: `animation_tree_path` reads state-machine playback, or `animation_player_path` reads
  `AnimationPlayer.current_animation`; `instructions: Array[CameramanStateDrivenInstruction]` (Resource:
  `state_name: StringName, camera: NodePath, activate_after, min_duration`). Slash-separated parent states are matched
  from most-specific to least-specific, then the highest-priority child is used as fallback.
- `CameramanSequencerCamera`: `instructions: Array[CameramanSequencerInstruction]` (camera, blend, hold), `loop`; restarts on activation.
- `CameramanMixingCamera`: `weights: Array[float]` (max 8, animatable); state = weighted `CameramanCameraState.lerp` chain.

## 9. Input — `addons/cameraman/input/`

- `CameramanInputAxis` (Resource): `value`, `center`, `range: Vector2`, `wrap`, `recentering {enabled, wait, time}`, `restrictions {NONE, RANGE_IS_DRIVEN, NO_RECENTERING, MOMENTARY}`; `clamp_value`, `get_normalized_value`, `reset`, `trigger_recentering`, `cancel_recentering`, `update_recentering(dt, force_cancel, center)`, `track_value_change`.
- `CameramanAxisDescriptor` (RefCounted): `axis: CameramanInputAxis`, `name: String`, `hint {DEFAULT, X, Y}`, `owner: Node`.
- `CameramanInputAxisController` (Node, child of a camera): auto-discovers axes from sibling components (`get_input_axes()`), one `CameramanInputAxisControl` per axis (Resource: `enabled`, `negative_action: StringName`, `positive_action: StringName`, `mouse_axis {NONE, X, Y}` (relative motion), `gain`, `accel_time`, `decel_time`, `cancel_delta_time`, `invert`), `player_device: int = -1`, `suppress_input_while_blending`, `ignore_time_scale`, `scan_recursively`. `synchronize_controllers()`, `get_controller(name)`, `trigger_recentering(name)`. Reads Godot `Input.get_action_strength` / `InputEventMouseMotion` via `_unhandled_input`. Subclassable: override `read_input(control) -> float`.
- `CameramanSimplePlayerController` (sample) uses the same axes.

## 10. Impulse — `addons/cameraman/impulse/`

- `CameramanImpulseDefinition` (Resource): `impulse_channel: int`, `impulse_shape {BUMP, EXPLOSION, RUMBLE, RECOIL, CUSTOM}` (custom `Curve`), `impulse_duration`, `impulse_type {UNIFORM, DISSIPATING, PROPAGATING, LEGACY}`, `dissipation_rate`, `dissipation_distance`, `propagation_speed`, `default_velocity: Vector3`, `amplitude_gain`, `frequency_gain`, `time_envelope`, `spatial_range`, `raw_signal: CameramanNoiseProfile` for LEGACY.
  `create_event(position, velocity) -> CameramanImpulseEvent`.
- `CameramanImpulseManager` (RefCounted, static via core): list of `CameramanImpulseEvent` (start time, definition, position, velocity), `get_impulse_at(position, use_2d, channel_mask) -> [pos: Vector3, rot: Quaternion]`, prunes finished, `ignore_time_scale`.
- `CameramanImpulseSource` (Node3D): `definition`, `default_velocity`; `generate_impulse()`, `generate_impulse_with_force(f)`, `generate_impulse_with_velocity(v)`, `generate_impulse_at(pos, velocity)`.
- `CameramanCollisionImpulseSource` (CameramanImpulseSource): hooks parent `RigidBody3D.body_entered` / `Area3D.body_entered` with `collision_mask`, `use_impact_direction`, `scale_impact_with_mass/speed`.
- `CameramanExternalImpulseListener` (Node3D): shakes its own transform (for UI/props).

## 11. Timeline (choreographed shots) — `addons/cameraman/timeline/`

Godot has no clip timeline, so the authored-sequence path is `AnimationPlayer`-driven:
- `CameramanShot` (Node): `camera: NodePath`, exported animatable `weight`, and `active`.
- `CameramanShotSequence` (Node): resolves a brain from `brain_path` or its parent, selects the two highest-weight
  active shots, and maintains one `set_camera_override` handle. `manual_time_step(delta)` seeks child
  `AnimationPlayer` nodes with `seek(time, true)` before evaluating the override; releasing all active shots releases
  the handle. `priority` maps directly to the brain override priority.

## 12. Editor — `addons/cameraman/editor/` (`plugin.cfg`, `cameraman_plugin.gd`)
- Registers custom node types with icons (`icons/*.svg`).
- `Cameraman` menu in the 3D editor toolbar: create presets (Follow Camera, FreeLook, Third Person Aim, 2D Camera, Dolly Camera with Spline, Target Group Camera, ClearShot, State-Driven, Sequencer, Mixing) — adds brain to the current `Camera3D` if missing.
- `Solo` button on `CameramanVirtualCameraBase` inspector (sets `CameramanCore.solo_camera`; editor-only preview).
- Gizmo: frustum for the selected camera when `show_camera_frustum`.
- Game view guides: `CameramanComposerGuides` runtime overlay (CanvasLayer) drawing dead zone / hard limits for the live composer; toggled via `CameramanCore.show_guides` and the brain's `show_debug_text` shows live camera + blend text.

## 13. Update timing & determinism
- Physics-vs-process choice per camera under SMART: `CameramanUpdateTracker` records each follow target's transform at both clocks; whichever clock shows movement most recently wins.
- `ignore_time_scale` → dt = `delta / Engine.time_scale`.
- `CameramanCore.uniform_delta_time_override` / `current_time_override` used by tests for deterministic stepping; tests instantiate the brain and call `manual_update(dt)` with `UpdateMethod.MANUAL`.

## 14. Tests (GUT, `tests/`)
Unit: camera state lerp (linear/spherical/cylindrical/screen-space aim), lens lerp, damper convergence, blend definition curves,
blender settings specificity, input axis wrap/clamp/recentering, noise determinism, impulse envelopes.
Integration (scene-tree, manual update): brain picks highest priority then most-recent; blend chain nesting on interrupt; cut vs blend events;
channel masks with two brains; Follow reaches offset; RotationComposer centers target; PositionComposer dead zone; HardLock/HardLookAt;
OrbitalFollow axes; SplineDolly nearest-point; Deoccluder pulls forward past a wall (StaticBody3D); Confiner3D box clamp; Confiner2D polygon clamp;
GroupFraming fits two targets; ClearShot picks unobstructed child; StateDriven switches on state; Sequencer advances; Mixing weights;
Impulse listener shakes then decays; Shot override beats priority; FreeLookModifier interpolates; storyboard toggles.

## 15. Repo layout
```
project.godot                # demo/test project (name "Cameraman")
addons/cameraman/            # the addon (plugin.cfg, all runtime + editor code, icons, presets)
addons/gut/                  # test framework (vendored)
demo/                        # demo scenes: 3rd person, freelook, 2d platformer, dolly, clearshot, split-screen, impulse, sequence
tests/                       # GUT tests
docs/                        # this file + user manual (docs/manual/*.md)
.github/workflows/ci.yml     # headless godot import + gut + gdlint
```
