extends CharacterBody2D

# Boss Properties
var health: int = 200
var speed: float = 120.0
var detection_range: float = 600.0
var slam_range: float = 120.0
var slam_damage: int = 30

# AI States
var player: CharacterBody2D
var is_chasing: bool = false
var is_slamming: bool = false
var slam_cooldown: float = 2.0
var last_slam_time: float = 0.0
var slam_duration: float = 1.0
var slam_start_time: float = 0.0

# Movement
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	# Find the player
	player = _find_player()
	# Initialize timing to allow immediate first attack
	last_slam_time = -slam_cooldown
	print("Fridge Boss activated!")

func _find_player() -> CharacterBody2D:
	# Try to find player by group first
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Search for CharacterBody2D with health system in the scene
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node != self and node.has_method('take_damage') and node.has_method('get_health_percentage'):
			return node
		# Check nested nodes
		var found = _find_character_recursive(node)
		if found:
			return found
	return null

func _find_character_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child != self and child.has_method('take_damage') and child.has_method('get_health_percentage'):
			return child
		var found = _find_character_recursive(child)
		if found:
			return found
	return null

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	
	# Try to find player if we don't have one
	if not player or not is_instance_valid(player):
		player = _find_player()
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle slam attack
	if is_slamming:
		_handle_slam_attack(delta)
		return
	
	# Check for ally projectiles hitting this boss
	_check_for_ally_projectiles()
	
	# AI behavior
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		print("Distance to player: ", distance_to_player)  # Debug
		
		# Start chasing if player is in detection range
		if distance_to_player <= detection_range:
			is_chasing = true
			print("Fridge is chasing player!")  # Debug
		else:
			is_chasing = false
		
		# Move towards player if chasing
		if is_chasing:
			_move_towards_player(delta)
			
			# Try slam attack if close enough
			if distance_to_player <= slam_range:
				print("In slam range! Can slam: ", _can_slam())  # Debug
				if _can_slam():
					_start_slam_attack()
	
	move_and_slide()

func _move_towards_player(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Calculate direction to player
	var target_pos = player.global_position
	var current_pos = global_position
	var dir_x = target_pos.x - current_pos.x
	
	# Move towards player horizontally
	if abs(dir_x) > 10.0:  # Dead zone to prevent jittering
		if dir_x > 0:
			velocity.x = speed
		else:
			velocity.x = -speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	# Jump if player is above and we're on ground
	if target_pos.y < current_pos.y - 50 and is_on_floor() and abs(dir_x) < 100:
		velocity.y = JUMP_VELOCITY

func _can_slam() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	var can_attack = current_time - last_slam_time >= slam_cooldown
	print("Current time: ", current_time, ", Last slam: ", last_slam_time, ", Can slam: ", can_attack)  # Debug
	return can_attack

func _start_slam_attack() -> void:
	is_slamming = true
	slam_start_time = Time.get_ticks_msec() / 1000.0
	last_slam_time = slam_start_time
	velocity.x = 0  # Stop moving during slam
	print("Fridge Boss is slamming!")

func _handle_slam_attack(_delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var slam_progress = (current_time - slam_start_time) / slam_duration
	
	if slam_progress >= 1.0:
		# Slam attack finished
		is_slamming = false
		_check_slam_damage()
		print("Slam attack complete!")
	else:
		# Visual effect during slam (could add screen shake here)
		velocity.x = 0  # Stay still during slam

func _check_slam_damage() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Check if player is within slam damage range
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= slam_range * 1.2:  # Slightly larger damage radius
		if player.has_method('take_damage'):
			player.take_damage(slam_damage)
			print("Fridge Boss slam hit player for ", slam_damage, " damage!")
	else:
		print("Player avoided the slam attack!")

func take_damage(damage: int) -> void:
	health -= damage
	print("Fridge Boss health: ", health, "/200")
	
	if health <= 0:
		die()

func die() -> void:
	print("Fridge Boss defeated!")
	
	# Drop 3 healing pickups when fridge dies
	_drop_healing_pickups(3)
	
	# Drop 1 special random pickup (heal or damage)
	_drop_random_pickup()
	
	#börtön ajtaját kinyitja
	get_parent().get_node("Börtön").get_node("ColorRect2").queue_free()
	
	queue_free()
func _drop_healing_pickups(count: int) -> void:
	for i in range(count):
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
		healing_pickup.global_position = global_position + Vector2(0, -20)
		
		# Apply spread launch velocity for physics drop
		var launch_x = (i - 1) * 80.0  # Spread pickups horizontally
		var launch_y = -150.0
		healing_pickup.linear_velocity = Vector2(launch_x, launch_y)
		
		print("Fridge dropped healing pickup ", i + 1, " with gravity")
	
	print("Fridge Boss dropped ", count, " healing pickups with gravity!")

# Simplified fridge script - healing pickup detection handled by player

func _drop_random_pickup() -> void:
	# Create random pickup with RigidBody2D for gravity physics
	var random_pickup = RigidBody2D.new()
	var sprite = ColorRect.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Setup visual appearance - purple color
	sprite.size = Vector2(20, 20)
	sprite.color = Color.PURPLE
	random_pickup.add_child(sprite)
	
	# Setup collision for physics
	shape.size = Vector2(20, 20)
	collision.shape = shape
	random_pickup.add_child(collision)
	
	# Add to scene
	get_parent().add_child(random_pickup)
	random_pickup.global_position = global_position + Vector2(0, -30)
	
	# Apply launch velocity for physics drop
	random_pickup.linear_velocity = Vector2(0, -200)
	
	# Add a simple marker to identify it as random pickup
	random_pickup.set_meta("pickup_type", "random")
	
	print("Fridge Boss dropped 1 random pickup with gravity!")

func _check_for_ally_projectiles() -> void:
	# Check for Kai's projectiles
	for node in get_tree().current_scene.get_children():
		if node is RigidBody2D and node.has_meta("projectile_type"):
			if node.get_meta("projectile_type") == "ally":
				# Check if projectile hits this boss
				var distance = global_position.distance_to(node.global_position)
				if distance <= 40.0:  # Hit radius
					# Take damage from ally projectile
					var damage = node.get_meta("damage", 30)
					take_damage(damage)
					print("Fridge Boss hit by Kai's projectile for ", damage, " damage!")
					
					# Remove the projectile
					node.queue_free()
					return
