extends CharacterBody2D

# Enemy Properties
var health: int = 50
var speed: float = 150.0
var detection_range: float = 500.0
var attack_range: float = 400.0

# Floating Movement
var float_amplitude: float = 50.0  # How far up/down it floats
var float_speed: float = 2.0        # Speed of floating motion
var base_position: Vector2
var time_offset: float = 0.0

# Projectile System
var projectile_scene: PackedScene
var fire_rate: float = 1.5          # Seconds between shots
var last_shot_time: float = 0.0
var projectile_speed: float = 150.0

# Player Reference
var player: CharacterBody2D
var is_chasing: bool = false

func _ready() -> void:
	# Store the starting position for floating reference
	base_position = global_position
	# Add some randomness to floating motion
	time_offset = randf() * PI * 2
	
	# Find the player
	player = _find_player()
	
	# Create projectile scene programmatically
	_setup_projectile_scene()

func _find_player() -> CharacterBody2D:
	# Try to find player by group first
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Search for CharacterBody2D in the scene (should be the player)
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node != self and node.has_method('take_damage'):
			return node
		# Check nested nodes
		var found = _find_character_recursive(node)
		if found:
			return found
	return null

func _find_character_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child != self and child.has_method('take_damage'):
			return child
		var found = _find_character_recursive(child)
		if found:
			return found
	return null

func _setup_projectile_scene() -> void:
	# Create a simple projectile scene programmatically
	projectile_scene = PackedScene.new()
	# We'll create projectiles dynamically in the fire_projectile function

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	
	# Try to find player if we don't have one
	if not player or not is_instance_valid(player):
		player = _find_player()
	
	# Update floating motion
	_update_floating_movement(delta)
	
	# Update projectiles manually
	_update_projectiles(delta)
	
	# Check for player and handle AI
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Start chasing if player is in detection range
		if distance_to_player <= detection_range:
			is_chasing = true
		else:
			is_chasing = false
		
		# Move towards player if chasing
		if is_chasing:
			_move_towards_player(delta)
		
		# Fire projectiles if in attack range AND chasing
		if is_chasing and distance_to_player <= attack_range:
			_try_fire_projectile()
	
	move_and_slide()

func _update_projectiles(delta: float) -> void:
	if not has_meta("projectiles"):
		return
	
	var projectiles = get_meta("projectiles")
	var to_remove = []
	
	for projectile in projectiles:
		if not is_instance_valid(projectile) or projectile.get_meta("has_hit", false):
			to_remove.append(projectile)
			continue
		
		# Update projectile lifetime
		var lifetime = projectile.get_meta("lifetime", 0.0)
		lifetime -= delta
		projectile.set_meta("lifetime", lifetime)
		
		if lifetime <= 0:
			to_remove.append(projectile)
			if is_instance_valid(projectile):
				projectile.queue_free()
			continue
		
		# Move projectile
		var dir_x = projectile.get_meta("dir_x", 0.0)
		var dir_y = projectile.get_meta("dir_y", 0.0)
		var projectile_speed_meta = projectile.get_meta("speed", 150.0)
		
		projectile.velocity.x = dir_x * projectile_speed_meta
		projectile.velocity.y = dir_y * projectile_speed_meta
		projectile.move_and_slide()
		
		# Check collision with player
		for i in projectile.get_slide_collision_count():
			var collision = projectile.get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider and collider.has_method('take_damage') and collider == player:
				projectile.set_meta("has_hit", true)
				collider.take_damage(10)
				print('Projectile hit player for 10 damage!')
				to_remove.append(projectile)
				if is_instance_valid(projectile):
					projectile.queue_free()
				break
	
	# Remove finished projectiles from list
	for proj in to_remove:
		projectiles.erase(proj)
		if is_instance_valid(proj):
			proj.queue_free()

func _update_floating_movement(_delta: float) -> void:
	# Create smooth floating motion
	var time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60.0 + time_offset
	var float_offset = sin(time * float_speed) * float_amplitude
	
	# Apply floating motion to base position
	if not is_chasing:
		# Float around the original position when not chasing
		var target_y = base_position.y + float_offset
		velocity.y = (target_y - global_position.y) * 2.0
		velocity.x = cos(time * float_speed * 0.7) * 30.0  # Gentle horizontal drift
	else:
		# Add floating motion even while chasing
		velocity.y += sin(time * float_speed * 1.5) * 20.0

func _move_towards_player(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Calculate direction to player using individual components
	var target_pos = player.global_position
	var current_pos = global_position
	var dir_x = target_pos.x - current_pos.x
	var dir_y = target_pos.y - current_pos.y
	var length = sqrt(dir_x * dir_x + dir_y * dir_y)
	
	# Normalize direction
	if length > 0:
		dir_x = dir_x / length
		dir_y = dir_y / length
	
	# Move towards player but maintain floating motion
	velocity.x += dir_x * speed * delta * 3.0
	velocity.y += dir_y * speed * delta * 1.5  # Slower vertical movement
	
	# Apply drag to prevent infinite acceleration
	velocity.x *= 0.8
	velocity.y *= 0.9

func _try_fire_projectile() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_shot_time >= fire_rate:
		_fire_projectile()
		last_shot_time = current_time
		print("Enemy firing automatically! Time: ", current_time)

func _fire_projectile() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Create projectile using CharacterBody2D for reliable collision
	var projectile = CharacterBody2D.new()
	var sprite = ColorRect.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Setup projectile appearance
	sprite.size = Vector2(8, 8)
	sprite.color = Color.RED
	projectile.add_child(sprite)
	
	# Setup projectile collision
	shape.size = Vector2(8, 8)
	collision.shape = shape
	projectile.add_child(collision)
	
	# Calculate direction to player
	var target_pos = player.global_position
	var start_pos = global_position
	var dir_x = target_pos.x - start_pos.x
	var dir_y = target_pos.y - start_pos.y
	var length = sqrt(dir_x * dir_x + dir_y * dir_y)
	
	# Normalize direction
	if length > 0:
		dir_x = dir_x / length
		dir_y = dir_y / length
	else:
		dir_x = 1.0
		dir_y = 0.0
	
	# Add projectile to scene
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	# Store projectile data for tracking
	projectile.set_meta("dir_x", dir_x)
	projectile.set_meta("dir_y", dir_y)
	projectile.set_meta("speed", projectile_speed)
	projectile.set_meta("lifetime", 3.0)
	projectile.set_meta("has_hit", false)
	
	# Add to projectile tracking list
	if not has_meta("projectiles"):
		set_meta("projectiles", [])
	var projectiles = get_meta("projectiles")
	projectiles.append(projectile)
	
	# Set up timer for cleanup
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_remove_projectile.bind(projectile))
	projectile.add_child(timer)
	timer.start()
	
	print("Enemy fired projectile!")

func _remove_projectile(projectile: CharacterBody2D) -> void:
	if is_instance_valid(projectile):
		projectile.queue_free()
	
	# Remove from tracking list
	if has_meta("projectiles"):
		var projectiles = get_meta("projectiles")
		projectiles.erase(projectile)
		print("Removed projectile from tracking list")

func take_damage(damage: int) -> void:
	health -= damage
	print("Enemy health: ", health)
	
	if health <= 0:
		die()

func die() -> void:
	print("Enemy died!")
	
	# Clean up all projectiles when enemy dies
	_cleanup_all_projectiles()
	
	# Drop healing pickup
	_drop_healing_pickup()
	
	queue_free()

func _cleanup_all_projectiles() -> void:
	if not has_meta("projectiles"):
		return
	
	var projectiles = get_meta("projectiles")
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	
	# Clear the projectiles list
	set_meta("projectiles", [])
	print("Cleaned up ", projectiles.size(), " projectiles")

func _drop_healing_pickup() -> void:
	# Create healing pickup with RigidBody2D for gravity physics
	var healing_pickup = RigidBody2D.new()
	var sprite = ColorRect.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Setup visual appearance
	sprite.size = Vector2(15, 15)
	sprite.color = Color.GREEN
	healing_pickup.add_child(sprite)
	
	# Setup collision for physics
	shape.size = Vector2(15, 15)
	collision.shape = shape
	healing_pickup.add_child(collision)
	
	# Add to scene
	get_parent().add_child(healing_pickup)
	healing_pickup.global_position = global_position
	
	# Apply launch velocity for physics drop
	var launch_x = randf_range(-50.0, 50.0)
	var launch_y = randf_range(-100.0, -50.0)
	healing_pickup.linear_velocity = Vector2(launch_x, launch_y)
	
	print("Enemy_3 dropped healing pickup with gravity!")
