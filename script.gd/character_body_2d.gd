extends CharacterBody2D

const SPEED = 50.0
const JUMP_VELOCITY = -400.0
@onready var anim = $AnimatedSprite2D

var jump_count = 0 
var max_jump = 2 
var is_attacking = false

func _physics_process(delta: float) -> void:
	# 1. Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	# 2. Input Gerakan (A/D) - Tetap jalan terus tanpa interupsi
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 3. Logika Lompat
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jump:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# 4. LOGIKA ANIMASI (Paling Penting)
	if Input.is_action_just_pressed("Ui_attack"):
		is_attacking = true
		anim.play("basic_attack")
		# Reset is_attacking setelah animasi selesai
		await anim.animation_finished
		is_attacking = false
	else:
		# HANYA ganti ke animasi lain jika animasi attack TIDAK sedang berputar
		if anim.animation != "basic_attack" or not anim.is_playing():
			if is_on_floor():
				if velocity.x != 0:
					anim.play("Run")
				else:
					anim.play("default")
			else:
				anim.play("Jump")

	move_and_slide()
