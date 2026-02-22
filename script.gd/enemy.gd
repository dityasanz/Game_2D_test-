extends CharacterBody2D

var speed = 25.0
var direction = 1
var is_initialized = false

@onready var ray_cast_2d = $RayCast2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var area_2d = $Area2D

var attack_range = 60.0
var chase_range = 400.0
var current_state = "idle"
var state_timer = 0.0

var flip_cooldown = 0.0
var flip_cooldown_time = 0.5

var player: Node2D = null
var is_chasing = false

# HP system - enemy butuh 2x attack untuk mati
var hp = 2
var max_hp = 2
var is_invulnerable = false
var hit_count = 0

func _ready():
	# Set collision mask ke layer floor (1 = default floor layer)
	ray_cast_2d.collision_mask = 1
	ray_cast_2d.enabled = true
	
	# Hubungkan signal Area2D untuk deteksi player attack
	area_2d.body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(0.1).timeout
	is_initialized = true
	
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		print("ERROR: Player tidak ditemukan!")
	else:
		print("Player ditemukan: ", player.name)

func _on_body_entered(body):
	# Kalau player masuk ke area enemy dan player sedang attack
	if body.is_in_group("player"):
		print(">>> Player masuk area enemy!")
		if body.has_method("is_attacking") and body.is_attacking():
			print(">>> Player attack! Enemy terpengaruh!")
			take_damage()

func _physics_process(delta):
	# Update timer
	if state_timer > 0:
		state_timer -= delta
		if state_timer <= 0:
			current_state = "idle"
			is_invulnerable = false
	
	if flip_cooldown > 0:
		flip_cooldown -= delta
	
	# Cek apakah enemy sudah mati
	if current_state == "dead":
		return
	
	# Jangan bergerak kalau hit/attack
	if current_state == "hit":
		velocity.x = 0
		_play_animation()
		move_and_slide()
		return
	
	if current_state == "attack":
		velocity.x = 0
		_play_animation()
		move_and_slide()
		return
	
	# Reset chase state
	is_chasing = false
	
	# Cek player untuk chase/attack (tidak untuk damage - itu lewat Area2D)
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# CEK ATTACK - Kalau player dekat, enemy attack
		if distance_to_player < attack_range:
			current_state = "attack"
			state_timer = 0.5
			velocity.x = 0
			_play_animation()
			move_and_slide()
			return
		
		# Jika dalam chase range, kejar player
		if distance_to_player < chase_range:
			is_chasing = true
			
			# Arahkan ke player
			var dir_to_player = sign(player.global_position.x - global_position.x)
			if dir_to_player != 0:
				direction = dir_to_player
	
	# Gravitasi
	if not is_on_floor():
		velocity.y += 980 * delta
	
	# Patrol hanya kalau TIDAK chase
	if not is_chasing:
		var must_flip = false
		
		# Cek tembok
		if is_on_wall() and flip_cooldown <= 0:
			must_flip = true
		
		# Cek jurang - raycast menunjuk ke bawah sekarang
		if is_initialized and flip_cooldown <= 0:
			if not ray_cast_2d.is_colliding():
				must_flip = true
		
		if must_flip:
			direction *= -1
			flip_cooldown = flip_cooldown_time
	
	# Sprite dan movement (invert karena sprite default menghadap kanan)
	animated_sprite_2d.flip_h = (direction == 1)
	
	if is_chasing:
		velocity.x = direction * (speed * 1.5)
	else:
		velocity.x = direction * speed
	
	if velocity.x != 0:
		current_state = "walk"
	
	_play_animation()
	move_and_slide()

func _play_animation():
	if current_state == "idle":
		animated_sprite_2d.play("default")
	elif current_state == "hit":
		animated_sprite_2d.play("hit")
	elif current_state == "attack":
		animated_sprite_2d.play("attack")
	elif current_state == "walk":
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("default")

func take_damage():
	# Kalau lagi invulnerable, skip
	if is_invulnerable:
		return
	
	hit_count += 1
	hp -= 1
	print("Enemy hit #", hit_count, "! HP: ", hp, "/", max_hp)
	
	# Mainkan animasi hit
	current_state = "hit"
	state_timer = 0.3
	_play_animation()
	
	if hp <= 0:
		# Langsung mati setelah delay pendek
		await get_tree().create_timer(0.3).timeout
		die()
	else:
		# Enemy masih hidup, kasih waktu invulnerable
		is_invulnerable = true
		print("Enemy hit! Sisa HP: ", hp)

func die():
	print(">>> ENEMY MATI!")
	current_state = "dead"
	velocity.x = 0
	_play_animation()
	
	# Tunggu dulu biar animasi keliatan
	await get_tree().create_timer(0.2).timeout
	
	# Hapus enemy
	queue_free()
	print("Enemy sudah mati dan menghilang!")
