@tool
class_name CameramanStateDrivenCamera
## Camera manager that selects a child from an AnimationTree or AnimationPlayer state.
extends CameramanCameraManagerBase

## NodePath to the AnimationTree whose active state selects a shot.
@export var animation_tree_path: NodePath
## Fallback NodePath to an AnimationPlayer used for state lookup.
@export var animation_player_path: NodePath
## State-to-camera rules evaluated in their configured order.
@export var instructions: Array[CameramanStateDrivenInstruction] = []

var _candidate: CameramanVirtualCameraBase
var _candidate_time: float = 0.0
var _selected_time: float = 0.0
var _live_instruction: CameramanStateDrivenInstruction

## Selects the instruction matching the current animation state and timing rules.
func choose_current_camera(_world_up: Vector3, delta: float) -> CameramanVirtualCameraBase:
	var state_name: String = _get_state_name()
	var instruction: CameramanStateDrivenInstruction = _find_instruction(state_name)
	var desired: CameramanVirtualCameraBase = _resolve_instruction(instruction)
	if desired == null:
		desired = super.choose_current_camera(_world_up, delta)
		instruction = null
	if desired == null:
		return null
	if desired == live_child:
		_selected_time += maxf(delta, 0.0)
		_candidate = desired
		_candidate_time = 0.0
		return desired
	if desired != _candidate:
		_candidate = desired
		_candidate_time = 0.0
	else:
		_candidate_time += maxf(delta, 0.0)
	var activate_after: float = instruction.activate_after if instruction != null else 0.0
	var minimum: float = _live_instruction.min_duration if _live_instruction != null else 0.0
	if live_child == null or (_candidate_time >= activate_after and _selected_time >= minimum):
		_selected_time = 0.0
		_live_instruction = instruction
		return desired
	return live_child

func _get_state_name() -> String:
	var tree: AnimationTree = get_node_or_null(animation_tree_path) as AnimationTree
	if tree != null:
		var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		if playback != null:
			return str(playback.get_current_node())
	var player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer
	return player.current_animation if player != null else ""

func _find_instruction(state_name: String) -> CameramanStateDrivenInstruction:
	var result: CameramanStateDrivenInstruction
	var longest: int = -1
	for instruction in instructions:
		if instruction == null:
			continue
		var name_value: String = str(instruction.state_name)
		if state_name == name_value or state_name.begins_with(name_value + "/"):
			if name_value.length() > longest:
				result = instruction
				longest = name_value.length()
	return result

func _resolve_instruction(instruction: CameramanStateDrivenInstruction) -> CameramanVirtualCameraBase:
	if instruction == null or instruction.camera.is_empty():
		return null
	return get_node_or_null(instruction.camera) as CameramanVirtualCameraBase
