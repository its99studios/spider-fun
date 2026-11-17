extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea
@onready var golden_ball_sound: AudioStreamPlayer2D = $GoldenBallSound

var rng := RandomNumberGenerator.new()
var check_timer: float = 1.0
var spider_touching: bool = false


func _ready() -> void:
	if randi_range(1, 112229) == 112229:
		print("GOLDEN BALL! GOLDEN BALL!")
		sprite.play("gold")
		golden_ball_sound.play()
		
	rng.randomize()
	touch_area.body_entered.connect(_on_body_entered)
	touch_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if spider_touching:
		check_timer = 1.0
		return

	check_timer -= delta

	if check_timer > 0.0:
		return

	check_timer = 1.0

	if rng.randf() < 0.016:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("fun_spider"):
		spider_touching = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("fun_spider"):
		spider_touching = false
