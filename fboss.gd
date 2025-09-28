extends CharacterBody2D

# Boss Properties
var health: int = 400
var max_health: int = 400
var speed: float = 150.0
var detection_range: float = 600.0
var attack_range: float = 500.0
var attack_damage: int = 20

# AI States
var player: CharacterBody2D
var is_attacking: bool = false
var attack_cooldown: float = 1.5
var last_attack_time: float = 0.0

# Floating Movement
var float_direction: int = 1  # 1 for right, -1 for left
var float_boundaries: Vector2 = Vector2(200, 800)  # min and max X positions
var initial_position: Vector2

func _ready() -> void:
	# Store initial position for boundary calculations
	initial_position = global_position
	# Find the player
	player = _find_player()
	# Initialize timing to allow immediate first attack
	last_attack_time = -attack_cooldown
	print("Floating Boss activated! Health: ", health, " Position: ", global_position)

func _find_player() -> CharacterBody2D:
	# Try to find player by name first (most reliable)
	for node in get_tree().current_scene.get_children():
		if node.name == "Player" and node is CharacterBody2D:
			print("Fboss found player by name: ", node.name)
			return node
	
	# Try to find player by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		print("Fboss found player by group: ", players[0].name)
		return players[0]
	
	# Search for CharacterBody2D with health system
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node != self and node.has_method('take_damage'):
			# More flexible check - just needs take_damage method
			print("Fboss found potential player: ", node.name)
			return node
		# Check nested nodes
		var found = _find_character_recursive(node)
		if found:
			return found
	
	print("Fboss: No player found!")
	return null

func _find_character_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child != self and child.has_method('take_damage'):
			# More flexible check - just needs take_damage method
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
	
	# No gravity for floating boss - maintain Y position
	velocity.y = 0
	
	# Handle floating movement (left and right only)
	_handle_floating_movement(delta)
	
	# Check for ally projectiles hitting this boss
	_check_for_ally_projectiles()
	
	# AI behavior
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		print("Fboss distance to player: ", distance_to_player, " (attack range: ", attack_range, ")")
		
		# Attack if player is in range
		if distance_to_player <= attack_range:
			print("Player in range! Can attack: ", _can_attack())
			if _can_attack():
				_fire_bullet_at_player()
	else:
		print("Fboss: No player found or invalid player reference")
	
	move_and_slide()

func _handle_floating_movement(delta: float) -> void:
	# Calculate movement boundaries based on initial position
	var left_boundary = initial_position.x - float_boundaries.x
	var right_boundary = initial_position.x + float_boundaries.y
	
	# Move horizontally
	velocity.x = float_direction * speed
	
	# Check boundaries and reverse direction
	if global_position.x <= left_boundary and float_direction == -1:
		float_direction = 1
		print("Floating Boss: Changed direction to right")
	elif global_position.x >= right_boundary and float_direction == 1:
		float_direction = -1
		print("Floating Boss: Changed direction to left")

func _can_attack() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return current_time - last_attack_time >= attack_cooldown

func _fire_bullet_at_player() -> void:
	if not player or not is_instance_valid(player):
		return
	
	last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# Create simple RigidBody2D fireball projectile
	var fireball: RigidBody2D = RigidBody2D.new()
	var sprite: ColorRect = ColorRect.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	
	# Setup visual appearance - orange fireball
	sprite.size = Vector2(12, 12)
	sprite.color = Color(1.0, 0.4, 0.0)  # Orange color
	fireball.add_child(sprite)
	
	# Setup collision
	shape.radius = 6.0
	collision.shape = shape
	fireball.add_child(collision)
	
	# Add to scene
	get_parent().add_child(fireball)
	fireball.global_position = global_position
	
	# Calculate direction and apply velocity
	var direction = (player.global_position - global_position).normalized()
	var fireball_speed = 300.0
	fireball.linear_velocity = direction * fireball_speed
	
	# Add metadata for damage system
	fireball.set_meta("bullet_type", "enemy")
	fireball.set_meta("damage", attack_damage)
	
	# Auto-destroy after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(func(): if is_instance_valid(fireball): fireball.queue_free())
	
	print("Floating Boss fired RigidBody2D fireball at player!")

func take_damage(damage: int) -> void:
	health -= damage
	print("Floating Boss health: ", health, "/", max_health)
	
	# Send Kai to the shadowrealm when fboss health drops below 50
	if health < 50:
		print("FBOSS HEALTH BELOW 50! Triggering Kai shadowrealm! Current health: ", health)
		_send_kai_to_shadowrealm()
	
	# Debug: Check health threshold
	if health <= 0:
		print("Floating Boss health reached 0 or below - triggering death!")
		die()
	elif health <= 4:  # 1% of 400
		print("Floating Boss critical health: ", health, " HP remaining!")

func _send_kai_to_shadowrealm() -> void:
	# Prevent multiple calls with a flag
	if get_meta("kai_sent_to_shadowrealm", false):
		return
	set_meta("kai_sent_to_shadowrealm", true)
	
	# Find Kai by multiple methods to ensure we get him
	var kai_node = null
	
	# Method 1: Search by group membership (most reliable)
	var kai_group = get_tree().get_nodes_in_group("kai")
	if kai_group.size() > 0:
		kai_node = kai_group[0]
		print("Found Kai by group membership")
	else:
		# Method 2: Search by name containing 'kai' (case-insensitive)
		for node in get_tree().current_scene.get_children():
			if "kai" in node.name.to_lower():
				kai_node = node
				print("Found Kai by name: ", node.name)
				break
			# Also check nested nodes
			var found_kai = _find_kai_recursive(node)
			if found_kai:
				kai_node = found_kai
				break
	
	# Method 3: Search by companion properties (more specific check)
	if not kai_node:
		for node in get_tree().current_scene.get_children():
			if node is CharacterBody2D and node != self and node.has_method("take_damage"):
				# Check if it has companion-like properties
				if node.has_method("heal") and node.has_method("die_permanently"):
					kai_node = node
					print("Found Kai by companion methods")
					break
	
	if kai_node and is_instance_valid(kai_node):
		print("SENDING KAI TO THE SHADOWREALM! Fboss health: ", health)
		# Use Kai's permanent death method if available
		if kai_node.has_method("die_permanently"):
			kai_node.die_permanently()
		else:
			kai_node.queue_free()  # Fallback to direct removal
	else:
		print("Could not find Kai to send to shadowrealm")

func _find_kai_recursive(node: Node) -> Node:
	# Recursive search for Kai in nested nodes
	for child in node.get_children():
		if "kai" in child.name.to_lower():
			return child
		var found = _find_kai_recursive(child)
		if found:
			return found
	return null

func get_health_percentage() -> float:
	# Add this method for boss detection compatibility
	return float(health) / float(max_health)

func die() -> void:
	print("Floating Boss defeated!")
	
	# Teleport player to tp node before fboss dies
	_teleport_player_to_tp()
	
	# Drop 2 healing pickups when floating boss dies
	_drop_healing_pickups(2)
	
	queue_free()

func _teleport_player_to_tp() -> void:
	# Find the tp node inside fboss
	var tp_node = get_node_or_null("tp")
	if not tp_node:
		print("Warning: No 'tp' node found inside fboss for teleportation")
		return
	
	# Find the player
	var target_player = null
	if player and is_instance_valid(player):
		target_player = player
	else:
		# Try to find player again
		target_player = _find_player()
	
	if target_player and is_instance_valid(target_player):
		# Disable all player movement
		_disable_player_movement(target_player)
		
		# Teleport player to tp position
		target_player.global_position = tp_node.global_position
		print("Player teleported to fboss tp location at: ", tp_node.global_position)
		print("Player movement has been DISABLED after fboss death!")
		
		# Heal player to full HP following teleporter standard
		if target_player.has_method('heal'):
			# Use method calls instead of get() for script variables
			if target_player.has_method('get_health') and target_player.has_method('get_max_health'):
				var current_health = target_player.get_health()
				var max_health = target_player.get_max_health()
				if current_health < max_health:
					var heal_amount = max_health - current_health
					target_player.heal(heal_amount)
					print("Player healed to full HP after fboss teleportation!")
			else:
				# Fallback: try to heal with a reasonable amount
				target_player.heal(100)  # Heal 100 HP as fallback
				print("Player healed (fallback amount) after fboss teleportation!")
	else:
		print("Could not find player for teleportation")

func _disable_player_movement(target_player: CharacterBody2D) -> void:
	# Method 1: Set movement disabled flag if available
	if target_player.has_method('set_movement_disabled'):
		target_player.set_movement_disabled(true)
		print("Player movement disabled via set_movement_disabled method")
	
	# Method 2: Set movement_disabled property directly
	if "movement_disabled" in target_player:
		target_player.movement_disabled = true
		print("Player movement disabled via movement_disabled property")
	
	# Method 3: Stop all velocity
	target_player.velocity = Vector2.ZERO
	
	# Method 4: Set process mode to disabled to stop input processing
	target_player.process_mode = Node.PROCESS_MODE_DISABLED
	print("Player process mode set to DISABLED - no input processing")

func _drop_healing_pickups(count: int) -> void:
	for i in range(count):
		# Create healing pickup with RigidBody2D for gravity physics
		var healing_pickup: RigidBody2D = RigidBody2D.new()
		var sprite: ColorRect = ColorRect.new()
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		
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
		var launch_x = (i - 0.5) * 80.0  # Spread pickups horizontally
		var launch_y = -150.0
		healing_pickup.linear_velocity = Vector2(launch_x, launch_y)
		
		print("Floating Boss dropped healing pickup ", i + 1, " with gravity")
	
	print("Floating Boss dropped ", count, " healing pickups with gravity!")

func _check_for_ally_projectiles() -> void:
	# Check for Kai's projectiles
	for node in get_tree().current_scene.get_children():
		if node is RigidBody2D and node.has_meta("projectile_type"):
			if node.get_meta("projectile_type") == "ally":
				# Check if projectile hits this boss
				var distance = global_position.distance_to(node.global_position)
				if distance <= 35.0:  # Hit radius
					# Take damage from ally projectile
					var damage = node.get_meta("damage", 30)
					take_damage(damage)
					print("Floating Boss hit by Kai's projectile for ", damage, " damage!")
					
					# Remove the projectile
					node.queue_free()
					return
