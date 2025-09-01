extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main/world.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
