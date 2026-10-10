
extends CharacterBody2D

enum State {
	WALKING,
	JUMPING,
	FOLLOWING,
	READING,
	IDLE,
	SLEEP,
	ROLLING
}

@export var string_ball_scene: PackedScene

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

var string_ball: Node2D
var balance_time: float = 0.0
var rolling_duration: float = 0.0


func _ready() -> void:
	rng.randomize()
	add_to_group("fun_spider")
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dragging:
		return

	if state == State.ROLLING:
		rolling_logic(delta)
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
			
		State.ROLLING:
			play_animation("roll")


func choose_state() -> void:
	var choice: float = rng.randf()

	if choice < 0.15:
		state = State.JUMPING
		grounded = false
		velocity.y = rng.randf_range(-1920.0, -840.0)
		velocity.x = rng.randf_range(-300.0, 300.0)
		state_timer = 30
	elif choice < 0.23:
		state = State.FOLLOWING
		state_timer = rng.randi_range(300, 1000)
	elif choice < 0.50:
		state = State.WALKING
		state_timer = rng.randi_range(300, 1000)
	elif choice < 0.65:
		state = State.READING
		state_timer = rng.randi_range(200, 700)
	elif choice < 0.85:
		state = State.IDLE
		state_timer = rng.randi_range(60, 300)
	else:
		state = State.SLEEP
		state_timer = rng.randi_range(400, 1000)

	# Occasionally roll instead of performing the selected behavior.
	if rng.randf() < 0.3:
		begin_rolling()


func begin_rolling() -> void:
	if string_ball_scene == null:
		push_warning("Assign string_ball_scene in the Inspector.")
		state = State.IDLE
		state_timer = 120
		return

	var new_ball := string_ball_scene.instantiate() as Node2D

	if new_ball == null:
		push_warning("StringBall scene root must inherit Node2D.")
		state = State.IDLE
		state_timer = 120
		return

	get_tree().current_scene.add_child(new_ball)
	string_ball = new_ball

	var ball_collision := string_ball.get_node_or_null(
		"TouchArea/CollisionShape2D"
	) as CollisionShape2D

	if ball_collision == null or not (ball_collision.shape is RectangleShape2D):
		push_warning("StringBall needs TouchArea/CollisionShape2D with RectangleShape2D.")
		string_ball.queue_free()
		string_ball = null
		state = State.IDLE
		state_timer = 120
		return

	var ball_shape := ball_collision.shape as RectangleShape2D
	var ball_half_height: float = ball_shape.size.y * absf(ball_collision.global_scale.y) / 2.0

	string_ball.global_position = Vector2(
		global_position.x,
		get_viewport_rect().size.y - ball_half_height
	)

	# Place the spider above the ball's collision shape.
	var ball_top := ball_collision.to_global(
		Vector2(0.0, -ball_shape.size.y / 2.0)
	)

	global_position = Vector2(
		ball_top.x,
		ball_top.y - get_sprite_size().y / 2.0
	)

	velocity = Vector2.ZERO
	grounded = true
	state = State.ROLLING
	rolling_duration = rng.randf_range(3.0, 7.0)
	balance_time = 0.0
	sprite.rotation = 0.0
	play_animation("roll")


func rolling_logic(delta: float) -> void:
	if not is_instance_valid(string_ball):
		finish_rolling()
		return

	balance_time += delta

	# Rock the sprite back and forth around its center.
	sprite.rotation = sin(balance_time * TAU * 2.5) * deg_to_rad(12.0)

	rolling_duration -= delta

	if rolling_duration <= 0.0:
		finish_rolling()


func finish_rolling() -> void:
	sprite.rotation = 0.0
	string_ball = null
	state = State.IDLE
	state_timer = rng.randi_range(60, 180)
	play_animation("idle")


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
