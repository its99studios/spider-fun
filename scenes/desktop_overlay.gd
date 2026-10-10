extends Control

func _ready() -> void:
	var window := get_window()
	window.transparent = true
	window.borderless = true
	window.always_on_top = true
	window.mouse_passthrough = true

	self_modulate = Color(1, 1, 1, 0)
