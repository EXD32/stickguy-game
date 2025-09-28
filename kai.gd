extends CharacterBody2D

# Companion Properties
var health: int = 150
var max_health: int = 150
var speed: float = 250.0  # Increased from 180 to 250
var follow_distance: float = 80.0
var attack_range: float = 250.0
var attack_damage: int = 30
var has_infinite_hp: bool = true

# AI States
var player: CharacterBody2D
var current_target: CharacterBody2D = null
var is_attacking: bool = false
var attack_cooldown: float = 1.0
var last_attack_time: float = 0.0

# Movement
const JUMP_VELOCITY = -350.0
var follow_offset: Vector2 = Vector2(-60, 0)  # Start behind player (left side)
var preferred_side: int = -1  # -1 for left, 1 for right

func _ready() -> void:
	# Add Kai to a group for easy identification
	add_to_group("kai")
	
	# Find the player
	player = _find_player()
	# Initialize timing to allow immediate first attack
	last_attack_time = -attack_cooldown
	print("Kai companion activated! Ready to help!")

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
	
	# Check fboss health to determine if Kai should lose infinite HP
	_check_fboss_health()
	
	# Try to find player if we don't have one
	if not player or not is_instance_valid(player):
		player = _find_player()
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Find nearest enemy/boss to attack
	current_target = _find_nearest_enemy()
	
	# AI behavior priority: Attack > Follow Player
	if current_target and is_instance_valid(current_target):
		var distance_to_target = global_position.distance_to(current_target.global_position)
		
		# Attack if target is in range
		if distance_to_target <= attack_range and _can_attack():
			_attack_target()
		else:
			# Move towards target if it's not too far from player
			_move_towards_target(delta)
	elif player and is_instance_valid(player):
		# Follow player when no enemies nearby
		_follow_player(delta)
	
	move_and_slide()

func _find_nearest_enemy() -> CharacterBody2D:
	var nearest_enemy: CharacterBody2D = null
	var nearest_distance: float = INF
	
	# Search for enemies and bosses in the scene
	for node in get_tree().current_scene.get_children():
		if node != self and node != player and node is CharacterBody2D:
			# Check if it's an enemy (has take_damage but different health range than player)
			if node.has_method('take_damage'):
				# Identify bosses by high health or specific health ranges
				var is_boss = false
				if node.has_method('get') and node.get('health') != null:
					var enemy_health = node.get('health')
					# Consider entities with 150+ health as bosses/enemies
					if enemy_health >= 150:
						is_boss = true
				
				if is_boss:
					var distance = global_position.distance_to(node.global_position)
					if distance < nearest_distance:
						nearest_distance = distance
						nearest_enemy = node
	
	return nearest_enemy

func _can_attack() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return current_time - last_attack_time >= attack_cooldown

func _attack_target() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# Create blue energy projectile
	var projectile: RigidBody2D = RigidBody2D.new()
	var sprite: ColorRect = ColorRect.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	
	# Setup projectile appearance - blue color for ally
	sprite.size = Vector2(6, 6)
	sprite.color = Color.CYAN
	projectile.add_child(sprite)
	
	# Setup collision
	shape.radius = 3.0
	collision.shape = shape
	projectile.add_child(collision)
	
	# Add to scene
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -10)
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	var projectile_speed = 400.0
	
	# Set projectile velocity
	projectile.linear_velocity = direction * projectile_speed
	
	# Add metadata to identify as ally projectile
	projectile.set_meta("projectile_type", "ally")
	projectile.set_meta("damage", attack_damage)
	
	# Remove projectile after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(projectile): projectile.queue_free())
	
	print("Kai fired energy projectile at enemy!")

func _move_towards_target(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Only pursue target if it's not too far from player
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > 300.0:  # Don't stray too far from player
			_follow_player(delta)
			return
	
	# Move towards target
	var target_pos = current_target.global_position
	var current_pos = global_position
	var dir_x = target_pos.x - current_pos.x
	
	# Move horizontally towards target
	if abs(dir_x) > 20.0:
		if dir_x > 0:
			velocity.x = speed * 0.8  # Slightly slower when chasing
		else:
			velocity.x = -speed * 0.8
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	# Jump if target is above and we're on ground
	if target_pos.y < current_pos.y - 50 and is_on_floor() and abs(dir_x) < 100:
		velocity.y = JUMP_VELOCITY

func _follow_player(delta: float) -> void:
	if not player or not is_instance_valid(player):
		print("Kai: No valid player found for following")
		return
	
	# Get player's velocity to determine which side to stay on
	var player_velocity = player.velocity if player.has_method('get') and player.get('velocity') != null else Vector2.ZERO
	
	# Dynamically adjust which side to follow on based on player movement
	if abs(player_velocity.x) > 50:  # Player is moving significantly
		if player_velocity.x > 0:  # Player moving right
			preferred_side = -1  # Stay on left side
		else:  # Player moving left
			preferred_side = 1   # Stay on right side
	
	# Calculate desired follow position
	follow_offset = Vector2(preferred_side * 60, 0)
	var target_pos = player.global_position + follow_offset
	var current_pos = global_position
	var distance_to_follow_pos = current_pos.distance_to(target_pos)
	
	print("Kai follow debug - Distance: ", distance_to_follow_pos, " Side: ", preferred_side)
	
	# Only move if too far from follow position
	if distance_to_follow_pos > follow_distance:
		var dir_x = target_pos.x - current_pos.x
		print("Kai needs to move! Dir X: ", dir_x)
		
		# Move towards follow position
		if abs(dir_x) > 15.0:
			if dir_x > 0:
				velocity.x = speed
				print("Kai moving RIGHT at speed: ", speed)
			else:
				velocity.x = -speed
				print("Kai moving LEFT at speed: ", -speed)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
		
		# Jump if player is above and we're on ground
		if target_pos.y < current_pos.y - 50 and is_on_floor() and abs(dir_x) < 80:
			velocity.y = JUMP_VELOCITY
			print("Kai jumping to follow player")
	else:
		# Stay still when close enough to follow position
		velocity.x = move_toward(velocity.x, 0, speed * 0.5)  # Gentle stop
		print("Kai close enough to player, staying still")

func take_damage(damage: int) -> void:
	# Kai has infinite HP until fboss reaches 1% health
	if has_infinite_hp:
		print("Kai shrugs off ", damage, " damage! (Infinite HP active)")
		return
	
	# Normal damage when infinite HP is disabled
	health -= damage
	print("Kai health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func heal(amount: int) -> void:
	# Heal Kai by specified amount
	health += amount
	health = min(health, max_health)  # Don't exceed max health
	print("Kai healed for ", amount, " HP! Health: ", health, "/", max_health)

func die() -> void:
	print("Kai has fallen! But will respawn to help again...")
	
	# Respawn after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(respawn)
	
	# Hide Kai temporarily
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func respawn() -> void:
	health = max_health
	visible = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# Respawn near player if possible
	if player and is_instance_valid(player):
		global_position = player.global_position + Vector2(80, 0)
	
	print("Kai has respawned! Ready to fight again!")

func _check_fboss_health() -> void:
	# Find fboss in the scene
	var fboss = _find_fboss()
	if fboss and is_instance_valid(fboss):
		# Check if fboss has health method
		if fboss.has_method('get') and fboss.get('health') != null:
			var fboss_health = fboss.get('health')
			var fboss_max_health = fboss.get('max_health')
			
			if fboss_max_health != null:
				# Calculate health percentage
				var health_percentage = float(fboss_health) / float(fboss_max_health)
				
				# If fboss reaches 1% health (0.01), Kai loses infinite HP and dies
				if health_percentage <= 0.01 and has_infinite_hp:
					has_infinite_hp = false
					print("Fboss critical! Kai's infinite HP disabled!")
					# Kai dies when fboss reaches 1% health
					die()

func _find_fboss() -> CharacterBody2D:
	# Search for fboss in the scene (400 HP floating boss)
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node != self and node != player:
			if node.has_method('get') and node.get('max_health') == 400:
				return node
		# Check nested nodes
		var found = _find_fboss_recursive(node)
		if found:
			return found
	return null

func _find_fboss_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child != self and child != player:
			if child.has_method('get') and child.get('max_health') == 400:
				return child
		var found = _find_fboss_recursive(child)
		if found:
			return found
	return null
