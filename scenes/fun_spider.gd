
extends CharacterBody2D

enum State {
	WALKING,
	JUMPING,
	FOLLOWING,
	READING,
	IDLE,
	SLEEP
}

@onready var sprite: AnimatedSprite2D = $Sprite

var state: State = State.WALKING
var state_timer: int = 0
var walk_timer: int = 0

var direction: int = 1
var walk_speed: float = 60.0
var gravity: float = 2500.0
var friction: float = 0.97
var throw_strength: float = PI

var rng := RandomNumberGenerator.new()
var grounded: bool = false

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var last_mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dragging:
		return

	var floor_y: float = get_viewport_rect().size.y - get_sprite_size().y / 2.0

	if not grounded or absf(velocity.x) > 6.0:
		apply_spider_physics(delta, floor_y)
		return

	state_timer -= 1

	if state_timer <= 0:
		choose_state()

	match state:
		State.WALKING:
			if rng.randf() < 0.01:
				direction *= -1
			walk_logic(floor_y)

		State.FOLLOWING:
			var mouse_x: float = get_global_mouse_position().x
			if absf(mouse_x - global_position.x) > 20.0:
				direction = 1 if mouse_x > global_position.x else -1
				walk_logic(floor_y)
			else:
				play_animation("idle")

		State.JUMPING:
			play_animation("idle")

		State.READING:
			play_animation("read")

		State.IDLE:
			play_animation("idle")

		State.SLEEP:
			play_animation("sleep")


func choose_state() -> void:
	var choice: float = rng.randf()

	if choice < 0.15:
		state = State.JUMPING
		grounded = false
		velocity.y = rng.randf_range(-2500.0, -840.0)
		velocity.x = rng.randf_range(-300.0, 300.0)
		state_timer = 30
	elif choice < 0.23:
		state = State.FOLLOWING
		state_timer = rng.randi_range(300, 1000)
	elif choice < 0.50:
		state = State.WALKING
		state_timer = rng.randi_range(100, 300)
	elif choice < 0.65:
		state = State.READING
		state_timer = rng.randi_range(200, 400)
	elif choice < 0.85:
		state = State.IDLE
		state_timer = rng.randi_range(60, 150)
	else:
		state = State.SLEEP
		state_timer = rng.randi_range(400, 1000)


func walk_logic(floor_y: float) -> void:
	walk_timer += 1
	play_animation("walk")
	sprite.flip_h = direction < 0
	global_position.x += direction * walk_speed / 60.0

	var half_width: float = get_sprite_size().x / 2.0
	var screen_width: float = get_viewport_rect().size.x

	if global_position.x >= screen_width - half_width:
		direction = -1
		global_position.x = screen_width - half_width
		velocity.x = -absf(velocity.x)
	elif global_position.x <= half_width:
		direction = 1
		global_position.x = half_width
		velocity.x = absf(velocity.x)

	global_position.y = floor_y


func apply_spider_physics(delta: float, floor_y: float) -> void:
	play_animation("pickup")
	velocity.y += gravity * delta
	velocity.x *= pow(friction, delta * 60.0)
	global_position += velocity * delta

	var half_width: float = get_sprite_size().x / 2.0
	var screen_width: float = get_viewport_rect().size.x

	if global_position.x < half_width:
		global_position.x = half_width
		velocity.x *= -0.5
	elif global_position.x > screen_width - half_width:
		global_position.x = screen_width - half_width
		velocity.x *= -0.5

	if global_position.y >= floor_y:
		global_position.y = floor_y
		velocity.y = 0.0
		grounded = true
		if absf(velocity.x) < 30.0:
			velocity.x = 0.0
			state = State.IDLE
			state_timer = 20


func get_sprite_size() -> Vector2:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null or not frames.has_animation(sprite.animation):
		return Vector2.ZERO

	var texture: Texture2D = frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return Vector2.ZERO

	return texture.get_size() * sprite.scale


func play_animation(animation_name: String) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)


func cursor_over_spider() -> bool:
	var mouse_position: Vector2 = get_global_mouse_position()
	var half_size: Vector2 = get_sprite_size() / 2.0
	var local_mouse: Vector2 = to_local(mouse_position)

	return Rect2(-half_size, get_sprite_size()).has_point(local_mouse)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_tree().quit()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_dragging and cursor_over_spider():
				is_dragging = true
				grounded = false
				state = State.IDLE
				velocity = Vector2.ZERO
				drag_offset = get_global_mouse_position() - global_position
				last_mouse_position = get_global_mouse_position()
				play_animation("pickup")
			elif not event.pressed and is_dragging:
				is_dragging = false
				if velocity.x > 0.0:
					direction = 1
				elif velocity.x < 0.0:
					direction = -1

	
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_position: Vector2 = get_global_mouse_position()
		var movement: Vector2 = mouse_position - last_mouse_position

		velocity = movement * 60.0 * throw_strength
		global_position = mouse_position - drag_offset
		last_mouse_position = mouse_position
