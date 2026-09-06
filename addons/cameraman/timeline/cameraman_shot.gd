@tool
class_name CameramanShot
extends Node

@export var camera: NodePath
@export_range(0.0, 1.0) var weight: float = 0.0
@export var active: bool = true
