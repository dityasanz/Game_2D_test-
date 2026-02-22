extends CharacterBody2D

# ========================
# CONSTANT
# ========================

const SPEED = 160.0
const ACCEL = 900.0
const FRICTION = 1000.0

const JUMP_VELOCITY = -400.0
const MAX_JUMP = 2

# DASH
const DASH_SPEED = 400.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 3.0

# AFTERIMAGE
const AFTERIMAGE_DISTANCE = 10.0


# ========================
# NODE
# ========================

@onready var anim = $AnimatedSprite2D


# ========================
# VARIABLE
# ========================

var jump_count = 0
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_dashing = false
var dash_direction = 0
var last_afterimage_position = Vector2.ZERO


# ========================
# MAIN
# ========================

func _physics_process(delta):

	# TIMER
	if dash_timer > 0:
		dash_timer -= delta
	else:
		is_dashing = false

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta


	# GRAVITY
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jump_count = 0


	# DASH INPUT
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN
		dash_direction = -1 if anim.flip_h else 1
		last_afterimage_position = global_position
		velocity.y = 0


	# DASH MOVEMENT
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0
		anim.play("Dash")

		if global_position.distance_to(last_afterimage_position) >= AFTERIMAGE_DISTANCE:
			create_afterimage()
			last_afterimage_position = global_position

	else:
		var direction = Input.get_axis("ui_left", "ui_right")

		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
			anim.flip_h = direction < 0

			if is_on_floor():
				anim.play("Run")
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

			if is_on_floor():
				anim.play("Idle")


	# JUMP
	if Input.is_action_just_pressed("ui_accept") and jump_count < MAX_JUMP:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		anim.play("Jump")


	# FALL
	if velocity.y > 0 and not is_on_floor():
		anim.play("Fall")


	move_and_slide()


# ========================
# AFTERIMAGE
# ========================

func create_afterimage():

	var ghost = Sprite2D.new()

	ghost.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	ghost.global_position = global_position
	ghost.flip_h = anim.flip_h
	ghost.scale = anim.scale

	get_parent().add_child(ghost)

	# warna biru celeste
	ghost.modulate = Color(0.4, 0.8, 1.5, 0.7)

	# stretch
	ghost.scale.x *= 1.1

	var tween = create_tween()

	tween.tween_property(ghost, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(ghost, "scale", ghost.scale * 0.8, 0.35)
	tween.tween_callback(ghost.queue_free)
