
extends Control

@onready var spider: CharacterBody2D = $FUNSpider


func _ready() -> void:
	var window := get_window()
	window.transparent = true
	window.borderless = true
	window.always_on_top = true
	window.mouse_passthrough = false


func _process(_delta: float) -> void:
	if not is_instance_valid(spider):
		return

	var spider_size: Vector2 = spider.get_sprite_size()
	var center: Vector2 = spider.position
	var half_size: Vector2 = spider_size / 2.0

	var spider_area := PackedVector2Array([
		center + Vector2(-half_size.x, -half_size.y),
		center + Vector2(half_size.x, -half_size.y),
		center + Vector2(half_size.x, half_size.y),
		center + Vector2(-half_size.x, half_size.y)
	])

	get_window().mouse_passthrough_polygon = spider_area
