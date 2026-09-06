class_name CameramanDemoMainMenu
extends Control

const DEMOS: Array[String] = [
	"third_person", "free_look", "platformer_2d", "dolly",
	"clear_shot", "split_screen", "impulse", "sequence"
]

func _ready() -> void:
	var title: Label = Label.new()
	title.text = "Cameraman demos"
	add_child(title)
	for demo_name in DEMOS:
		var button: Button = Button.new()
		button.text = demo_name
		button.pressed.connect(_open_demo.bind(demo_name))
		add_child(button)

func _open_demo(demo_name: String) -> void:
	get_tree().change_scene_to_file("res://demo/%s.tscn" % demo_name)
