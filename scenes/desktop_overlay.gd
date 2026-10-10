
extends Control

@onready var spider: CharacterBody2D = $FUNSpider



func _ready() -> void:
	var window := get_window()
	window.transparent = true
	window.borderless = true
	window.always_on_top = true
	window.mouse_passthrough = false

	var screen_count: int = DisplayServer.get_screen_count()
	if screen_count == 0:
		return

	var min_x: int = 2147483647
	var min_y: int = 2147483647
	var max_x: int = -2147483648
	var max_y: int = -2147483648

	for screen in range(screen_count):
		var screen_position: Vector2i = DisplayServer.screen_get_position(screen)
		var screen_size: Vector2i = DisplayServer.screen_get_size(screen)

		min_x = mini(min_x, screen_position.x)
		min_y = mini(min_y, screen_position.y)
		max_x = maxi(max_x, screen_position.x + screen_size.x)
		max_y = maxi(max_y, screen_position.y + screen_size.y)

	window.position = Vector2i(min_x, min_y)
	window.size = Vector2i(max_x - min_x, max_y - min_y)

	await get_tree().process_frame

	var primary_screen: int = DisplayServer.get_primary_screen()
	var primary_position: Vector2i = DisplayServer.screen_get_position(primary_screen)
	var primary_size: Vector2i = DisplayServer.screen_get_size(primary_screen)
	
	spider.position = Vector2(
		primary_position.x - window.position.x + primary_size.x / 2.0,
		primary_position.y - window.position.y + primary_size.y / 2.0
	)


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
