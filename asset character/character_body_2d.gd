extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
@onready var anim = $AnimatedSprite2D

var jump_count = 0 
var max_jump = 2 
	
func _physics_process(delta: float) -> void:
	# 1. Reset Lompatan & Gravitasi
	if is_on_floor():
		jump_count = 0 # RESET DI SINI (Kapanpun menyentuh lantai)
		if velocity.x != 0:
			anim.play("Run")
		else:
			anim.play("default")
	else:
		velocity += get_gravity() * delta
		anim.play("Jump")

	# 2. Input Gerakan (A/D)
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 3. Logika Lompat (Hanya satu blok input)
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jump:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	move_and_slide()
