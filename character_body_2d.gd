extends CharacterBody2D

# Animation System
@onready var anim = $AnimatedSprite2D
var shoot_speed_scale = 0.5  # slowed down shoot animation

# Health System
var max_health: int = 100
var current_health: int = 100
var is_dead: bool = false
var spawn_position: Vector2


# Movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400
var gravity = 800

# Double Jump System
var jump_count: int = 0
var max_jumps: int = 2
var double_jump_velocity: float = -350.0

func _ready() -> void:
	# Store the starting position as spawn point
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	# Don't process movement if dead
	if is_dead:
		return
	
	# Get input vector for movement
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset jump count when on floor
		jump_count = 0
	
	# Handle jump and double jump
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		jump_count = 1
		print("First jump!")
	elif jump_count == 1 and jump_count < max_jumps and Input.is_action_just_pressed("ui_accept"):
		velocity.y = double_jump_velocity
		jump_count = 2
		print("Double jump!")
	
	# Horizontal movement
	velocity.x = input_vector.x * SPEED
	
	# Check for nearby healing pickups
	_check_for_healing_pickups()
	
	# Check for enemy bullets
	_check_for_enemy_bullets()
	
	move_and_slide()
	
	# --- Animation System ---
	_handle_animations(input_vector)

func _handle_animations(input_vector: Vector2) -> void:
	# --- Shoot animation ---
	if Input.is_action_just_pressed("shoot"):
		anim.speed_scale = shoot_speed_scale
		anim.play("shoot")
		return  # don't override the animation
	
	# --- Basic animations ---
	anim.speed_scale = 1.0  # everything else at normal speed
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
	else:
		if input_vector.x == 0:
			anim.play("idle")
		else:
			anim.play("run")
	
	# Sprite flip
	if input_vector.x != 0:
		anim.flip_h = input_vector.x < 0

func _check_for_healing_pickups() -> void:
	# Find all RigidBody2D nodes that might be pickups (not coins - coins are Area2D)
	for node in get_tree().current_scene.get_children():
		if node is RigidBody2D:
			# Check if it's close enough to collect
			var distance = global_position.distance_to(node.global_position)
			if distance <= 30.0:  # Close enough to collect
				# Check for pickup types based on ColorRect children
				for child in node.get_children():
					if child is ColorRect:
						if child.color == Color.GREEN:
							# Green healing pickup
							_collect_healing_pickup(node)
							return
						elif child.color == Color.RED:
							# Red damage pickup
							_collect_damage_pickup(node)
							return
						elif child.color == Color.PURPLE:
							# Purple random pickup
							_collect_random_pickup(node)
							return
				# Check for special random pickup by metadata
				if node.has_meta("pickup_type") and node.get_meta("pickup_type") == "random":
					_collect_random_pickup(node)
					return

func _collect_healing_pickup(pickup: RigidBody2D) -> void:
	if current_health < max_health:
		var heal_amount = min(20, max_health - current_health)
		heal(heal_amount)
		print("Player healed for ", heal_amount, " HP from pickup!")
	else:
		print("Player already at full health!")
	
	# Remove the pickup
	pickup.queue_free()
	print("Healing pickup collected!")

func _collect_damage_pickup(pickup: RigidBody2D) -> void:
	take_damage(50)
	print("Player took 50 damage from damage pickup!")
	
	# Remove the pickup
	pickup.queue_free()
	print("Damage pickup collected!")

func _collect_random_pickup(pickup: RigidBody2D) -> void:
	# Generate random effect: 50% chance to heal, 50% chance to damage
	var is_healing = randf() < 0.5
	var amount = randi_range(10, 40)  # Random amount between 10-40
	
	if is_healing:
		# Healing effect
		heal(amount)
		print("Random pickup healed player for ", amount, " HP!")
	else:
		# Damage effect
		take_damage(amount)
		print("Random pickup damaged player for ", amount, " HP!")
	
	# Remove the pickup
	pickup.queue_free()
	print("Random pickup collected!")

func _check_for_enemy_bullets() -> void:
	# Find all RigidBody2D nodes that might be enemy bullets
	for node in get_tree().current_scene.get_children():
		if node is RigidBody2D and node.has_meta("bullet_type"):
			if node.get_meta("bullet_type") == "enemy":
				# Check if bullet is close enough to hit player
				var distance = global_position.distance_to(node.global_position)
				if distance <= 20.0:  # Hit radius
					# Take damage from bullet
					var damage = node.get_meta("damage", 20)  # Default 20 damage
					
					take_damage(damage)
					print("Player hit by fboss bullet for ", damage, " damage!")
					
					# Remove the bullet
					node.queue_free()
					return

# Health System Functions
func take_damage(damage: int) -> void:
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(current_health, 0)
	
	print("Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	
	print("Healed! Health: ", current_health, "/", max_health)

func die() -> void:
	is_dead = true
	print("Player died!")
	
	# Simple death effect - make character fall and disable collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Respawn after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(respawn)

func respawn() -> void:
	is_dead = false
	current_health = max_health
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	# Re-enable collision
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	print("Respawned! Health: ", current_health, "/", max_health)

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

# Mouse attack system
func _input(event: InputEvent) -> void:
	# Left mouse button to attack enemies
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Convert screen coordinates to world coordinates
		var world_mouse_pos = get_global_mouse_position()
		_attack_at_mouse_position(world_mouse_pos)

func _attack_at_mouse_position(mouse_pos: Vector2) -> void:
	# Use the passed mouse position (converted to world coordinates)
	var world_pos = mouse_pos
	
	# Find all enemies in the scene
	var enemies = _find_all_enemies()
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Check if mouse click is within enemy bounds
		if _is_mouse_on_enemy(world_pos, enemy):
			if enemy.has_method('take_damage'):
				enemy.take_damage(20)
				print("Player attacked enemy for 20 damage!")
				# Only attack the first enemy under cursor
				return

func _find_all_enemies() -> Array:
	var enemies = []
	
	# Search current scene for enemies (including regular enemies and bosses)
	for node in get_tree().current_scene.get_children():
		if node != self and node is CharacterBody2D and node.has_method('take_damage'):
			# Include if it's a regular enemy (no get_health_percentage) OR a boss (has high health)
			if not node.has_method('get_health_percentage') or _is_boss(node):
				enemies.append(node)
				print("Found enemy/boss: ", node.name)  # Debug
		# Check nested nodes too
		_find_enemies_recursive(node, enemies)
	
	return enemies

func _is_boss(node: CharacterBody2D) -> bool:
	# Check if this is a boss by looking at health value
	if node.has_method('get_health_percentage'):
		# If it has the health percentage method, it's likely a boss
		return true
	return false

func _find_enemies_recursive(node: Node, enemies: Array) -> void:
	for child in node.get_children():
		if child != self and child is CharacterBody2D and child.has_method('take_damage'):
			# Include if it's a regular enemy OR a boss
			if not child.has_method('get_health_percentage') or _is_boss(child):
				enemies.append(child)
				print("Found enemy/boss: ", child.name)  # Debug
		_find_enemies_recursive(child, enemies)

func _is_mouse_on_enemy(mouse_world_pos: Vector2, enemy: CharacterBody2D) -> bool:
	# Get enemy position
	var enemy_pos = enemy.global_position
	
	# Larger hit area for bosses, smaller for regular enemies
	var hit_radius = 50.0  # Larger radius for easier boss targeting
	if _is_boss(enemy):
		hit_radius = 80.0  # Even larger for bosses
	
	# Check if mouse position is within enemy bounds
	var distance = mouse_world_pos.distance_to(enemy_pos)
	print("Mouse distance to ", enemy.name, ": ", distance, " (hit radius: ", hit_radius, ")")  # Debug
	return distance <= hit_radius

# Animation signal handler
func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "shoot":
		anim.speed_scale = 1.0
		anim.play("idle")


func kai_unlock(body: Node2D) -> void:
	if body == self:
		if get_parent().get_node_or_null("Börtön/AnimatedSprite2D") != null: 
			get_parent().get_node("Börtön/AnimatedSprite2D").reparent(self)
