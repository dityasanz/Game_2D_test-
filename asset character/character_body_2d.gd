extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 350.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 2.0

@onready var anim = $AnimatedSprite2D
@onready var dash_cooldown_label: Label = get_tree().current_scene.get_node_or_null("DashCooldownUI/DashCooldownLabel")

var jump_count = 0
var max_jump = 2
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1
var is_dashing = false

func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
	else:
		is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	# 1. Reset Lompatan & Gravitasi
	if is_on_floor():
		jump_count = 0 # RESET DI SINI (Kapanpun menyentuh lantai)
		if velocity.x != 0 and not is_dashing:
			anim.play("Run")
		elif not is_dashing:
			anim.play("default")
	else:
		velocity += get_gravity() * delta
		anim.play("Jump")

	# 2. Input Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN
		dash_direction = -1 if anim.flip_h else 1

	# 3. Input Gerakan (A/D)
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
	else:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			$AnimatedSprite2D.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4. Logika Lompat (Hanya satu blok input)
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jump:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	move_and_slide()
	update_dash_cooldown_ui()


func update_dash_cooldown_ui() -> void:
	if dash_cooldown_label == null:
		return

	if dash_cooldown_timer > 0.0:
		dash_cooldown_label.visible = true
		dash_cooldown_label.text = "Dash Cooldown: %.1fs" % dash_cooldown_timer
	else:
		dash_cooldown_label.visible = false
